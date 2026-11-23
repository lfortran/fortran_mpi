#include "mpi_internal.h"
#include <limits.h>
#include <stdatomic.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

static const int comm_ids[] = {256, 257, 258};
static const int group_ids[] = {264, 265};
static const int request_ids[] = {384};
static const int type_ids[] = {512, 521, 528, 532, 536, 537, 538, 540, 541, 542,
                              592, 600, 722, 729, 730};
static const int op_ids[] = {32, 33, 34, 35, 36, 40, 41, 42, 48, 49, 50, 56, 57, 60, 61};
static const int info_ids[] = {304};
static const int errhandler_ids[] = {320, 321, 322, 323};

struct entry {
    int state; /* 0: free, 1: reserved before creating an MPI object, 2: live */
    int family, token, serialized, use_serializer;
    size_t references;
    fmpi_handle handle;
};

static struct entry *entries;
static size_t capacity;
static int initialized;
static atomic_flag registry_lock = ATOMIC_FLAG_INIT;

static void lock(void)
{
    while (atomic_flag_test_and_set_explicit(&registry_lock, memory_order_acquire)) {}
}

static void unlock(void)
{
    atomic_flag_clear_explicit(&registry_lock, memory_order_release);
}

static int family_error(int family)
{
    switch (family) {
    case FMPI_COMM: return MPI_ERR_COMM;
    case FMPI_GROUP: return MPI_ERR_GROUP;
    case FMPI_REQUEST: return MPI_ERR_REQUEST;
    case FMPI_TYPE: return MPI_ERR_TYPE;
    case FMPI_OP: return MPI_ERR_OP;
    case FMPI_INFO: return MPI_ERR_INFO;
    case FMPI_ERRHANDLER: return MPI_ERR_ARG;
    }
    return MPI_ERR_ARG;
}

static int predefined_count(int family)
{
    const int counts[] = {0, 3, 2, 1, 15, 15, 1, 4};
    return family >= FMPI_COMM && family <= FMPI_ERRHANDLER ? counts[family] : 0;
}

static int predefined(int family, int index, fmpi_handle *handle)
{
    switch (family) {
    case FMPI_COMM: handle->comm = c_comm_table[index]; return comm_ids[index];
    case FMPI_GROUP: handle->group = c_group_table[index]; return group_ids[index];
    case FMPI_REQUEST: handle->request = c_request_table[index]; return request_ids[index];
    case FMPI_TYPE: handle->datatype = c_datatype_table[index]; return type_ids[index];
    case FMPI_OP: handle->op = c_op_table[index]; return op_ids[index];
    case FMPI_INFO: handle->info = c_info_table[index]; return info_ids[index];
    case FMPI_ERRHANDLER: handle->errhandler = c_errhandler_table[index]; return errhandler_ids[index];
    }
    return 0;
}

static int same(int family, fmpi_handle left, fmpi_handle right)
{
    switch (family) {
    case FMPI_COMM: return left.comm == right.comm;
    case FMPI_GROUP: return left.group == right.group;
    case FMPI_REQUEST: return left.request == right.request;
    case FMPI_TYPE: return left.datatype == right.datatype;
    case FMPI_OP: return left.op == right.op;
    case FMPI_INFO: return left.info == right.info;
    case FMPI_ERRHANDLER: return left.errhandler == right.errhandler;
    }
    return 0;
}

static fmpi_handle read_handle(int family, const void *value)
{
    fmpi_handle handle = {0};
    switch (family) {
    case FMPI_COMM: handle.comm = *(const MPI_Comm *)value; break;
    case FMPI_GROUP: handle.group = *(const MPI_Group *)value; break;
    case FMPI_REQUEST: handle.request = *(const MPI_Request *)value; break;
    case FMPI_TYPE: handle.datatype = *(const MPI_Datatype *)value; break;
    case FMPI_OP: handle.op = *(const MPI_Op *)value; break;
    case FMPI_INFO: handle.info = *(const MPI_Info *)value; break;
    case FMPI_ERRHANDLER: handle.errhandler = *(const MPI_Errhandler *)value; break;
    }
    return handle;
}

static void write_handle(int family, fmpi_handle handle, void *out)
{
    switch (family) {
    case FMPI_COMM: *(MPI_Comm *)out = handle.comm; break;
    case FMPI_GROUP: *(MPI_Group *)out = handle.group; break;
    case FMPI_REQUEST: *(MPI_Request *)out = handle.request; break;
    case FMPI_TYPE: *(MPI_Datatype *)out = handle.datatype; break;
    case FMPI_OP: *(MPI_Op *)out = handle.op; break;
    case FMPI_INFO: *(MPI_Info *)out = handle.info; break;
    case FMPI_ERRHANDLER: *(MPI_Errhandler *)out = handle.errhandler; break;
    }
}

static struct entry *find(int family, int token)
{
    for (size_t i = 0; i < capacity; ++i)
        if (entries[i].state && entries[i].family == family && entries[i].token == token)
            return entries + i;
    return NULL;
}

static int known(int family, fmpi_handle handle, int *token)
{
    for (int i = 0; i < predefined_count(family); ++i) {
        fmpi_handle candidate;
        int id = predefined(family, i, &candidate);
        if (same(family, handle, candidate)) {
            *token = id;
            return 1;
        }
    }
    for (size_t i = 0; i < capacity; ++i) {
        if (entries[i].state == 2 && entries[i].family == family &&
                same(family, handle, entries[i].handle)) {
            *token = entries[i].token;
            return 1;
        }
    }
    return 0;
}

static int stored(int family, int token, fmpi_handle *handle)
{
    if (!initialized) return MPI_ERR_OTHER;
    for (int i = 0; i < predefined_count(family); ++i) {
        fmpi_handle candidate;
        if (predefined(family, i, &candidate) == token) {
            *handle = candidate;
            return MPI_SUCCESS;
        }
    }
    struct entry *entry = find(family, token);
    if (!entry || entry->state != 2) return family_error(family);
    *handle = entry->handle;
    return MPI_SUCCESS;
}

static int decode(int family, int token, fmpi_handle *handle)
{
    int rc = stored(family, token, handle);
    if (rc != MPI_SUCCESS) return rc;
    struct entry *entry = find(family, token);
    if (entry && entry->use_serializer) {
        *handle = fmpi_fromint(family, entry->serialized);
        if (!same(family, *handle, entry->handle)) return family_error(family);
    }
    return MPI_SUCCESS;
}

int fortran_mpi_handle_to_c(int family, int token, void *out)
{
    if (!out) return MPI_ERR_ARG;
    fmpi_handle handle;
    lock();
    int rc = decode(family, token, &handle);
    if (rc == MPI_SUCCESS) write_handle(family, handle, out);
    unlock();
    return rc;
}

int fortran_mpi_check_handles(int count, const int *families, const int *tokens)
{
    fmpi_handle handle;
    int rc = MPI_SUCCESS;
    lock();
    for (int i = 0; i < count && rc == MPI_SUCCESS; ++i)
        rc = decode(families[i], tokens[i], &handle);
    unlock();
    return rc;
}

int fortran_mpi_handle_reserve(int family, int *token)
{
    if (!token || !predefined_count(family)) return MPI_ERR_ARG;
    lock();
    if (!initialized) {
        unlock();
        return MPI_ERR_OTHER;
    }
    size_t i = 0;
    while (i < capacity && entries[i].state) ++i;
    if (i == capacity) {
        size_t next = capacity ? capacity * 2 : 16;
        if (next < capacity || next > (size_t)(INT_MAX - 4096) ||
                next > SIZE_MAX / sizeof(*entries)) {
            unlock();
            return MPI_ERR_NO_MEM;
        }
        struct entry *grown = realloc(entries, next * sizeof(*entries));
        if (!grown) {
            unlock();
            return MPI_ERR_NO_MEM;
        }
        entries = grown;
        memset(entries + capacity, 0, (next - capacity) * sizeof(*entries));
        capacity = next;
    }
    int candidate = 4096;
    while (find(family, candidate)) {
        if (candidate == INT_MAX) {
            unlock();
            return MPI_ERR_NO_MEM;
        }
        ++candidate;
    }
    entries[i].state = 1;
    entries[i].family = family;
    entries[i].token = candidate;
    *token = candidate;
    unlock();
    return MPI_SUCCESS;
}

int fortran_mpi_handle_store(int family, const void *value, int *token, int acquired)
{
    if (!value || !token) return MPI_ERR_ARG;
    fmpi_handle handle = read_handle(family, value);
    lock();
    struct entry *entry = find(family, *token);
    if (!entry || entry->state != 1) {
        unlock();
        return MPI_ERR_INTERN;
    }
    int existing;
    if (known(family, handle, &existing)) {
        struct entry *live = find(family, existing);
        /* MPI may return the same reference-counted group or already-complete
         * request for separate creating calls. An import is not a new MPI
         * acquisition and must not extend that object's lifetime. */
        if (live && acquired) {
            if (live->references == SIZE_MAX) {
                unlock();
                return MPI_ERR_NO_MEM;
            }
            ++live->references;
        }
        entry->state = 0;
        *token = existing;
        unlock();
        return MPI_SUCCESS;
    }
    entry->handle = handle;
    entry->references = 1;
    entry->use_serializer = 0;
    if (fmpi_has_serializers) {
        int serialized = fmpi_toint(family, handle);
        /* Never add an offset, reinterpret pointer bits, or decode a token
         * supplied by a caller without first finding its live object. */
        if ((serialized < 0 || serialized >= 4096) &&
                same(family, fmpi_fromint(family, serialized), handle)) {
            entry->serialized = serialized;
            entry->use_serializer = 1;
            struct entry *collision = find(family, serialized);
            if (!collision || collision == entry) entry->token = serialized;
        }
    }
    entry->state = 2;
    *token = entry->token;
    unlock();
    return MPI_SUCCESS;
}

void fortran_mpi_handle_release(int family, int token)
{
    lock();
    struct entry *entry = find(family, token);
    if (entry) entry->state = 0;
    unlock();
}

int fortran_mpi_handle_update(int family, const void *value, int *token)
{
    fmpi_handle handle = read_handle(family, value), old, null_handle;
    lock();
    /* A completion/free may already have destroyed the old native object;
     * compare its stored value without invoking fromint on a freed handle. */
    int rc = stored(family, *token, &old);
    if (rc == MPI_SUCCESS && !same(family, old, handle)) {
        int null_token = predefined(family, 0, &null_handle);
        struct entry *entry = find(family, *token);
        if (same(family, handle, null_handle)) {
            if (entry && --entry->references == 0) entry->state = 0;
            *token = null_token;
        } else if (entry) {
            /* A committing implementation may replace a datatype handle.
             * Keep the live token and update its typed object atomically. */
            entry->handle = handle;
            entry->use_serializer = 0;
        } else {
            rc = family_error(family);
        }
    }
    unlock();
    return rc;
}

int fortran_mpi_discard_created(int family, void *value)
{
    /* Only a just-created object whose registration failed reaches here.
     * No registry lock is held during these MPI calls. */
    switch (family) {
    case FMPI_COMM:
        return *(MPI_Comm *)value == MPI_COMM_NULL ? MPI_SUCCESS : MPI_Comm_free(value);
    case FMPI_GROUP:
        return *(MPI_Group *)value == MPI_GROUP_NULL ? MPI_SUCCESS : MPI_Group_free(value);
    case FMPI_TYPE:
        return *(MPI_Datatype *)value == MPI_DATATYPE_NULL ? MPI_SUCCESS : MPI_Type_free(value);
    case FMPI_REQUEST: {
        MPI_Request *request = value;
        if (*request == MPI_REQUEST_NULL) return MPI_SUCCESS;
        int rc = MPI_Cancel(request);
        int wait_rc = MPI_Wait(request, MPI_STATUS_IGNORE);
        return rc == MPI_SUCCESS ? wait_rc : rc;
    }
    }
    return MPI_ERR_ARG;
}

int fortran_mpi_handles_init(void)
{
#if defined(MPI_ABI)
    if (!fmpi_has_serializers) return MPI_ERR_INTERN;
    for (int family = FMPI_COMM; family <= FMPI_ERRHANDLER; ++family) {
        for (int i = 0; i < predefined_count(family); ++i) {
            fmpi_handle handle;
            int token = predefined(family, i, &handle);
            if (fmpi_toint(family, handle) != token ||
                    !same(family, fmpi_fromint(family, token), handle)) return MPI_ERR_INTERN;
        }
    }
#endif
    lock();
    initialized = 1;
    unlock();
    return MPI_SUCCESS;
}

void fortran_mpi_handles_finalize(void)
{
    lock();
    /* Borrowed/imported MPI objects remain the caller's responsibility. */
    free(entries);
    entries = NULL;
    capacity = 0;
    initialized = 0;
    unlock();
}

int fortran_mpi_comm_to_c(int token, MPI_Comm *out)
{
    return fortran_mpi_handle_to_c(FMPI_COMM, token, out);
}

int fortran_mpi_comm_from_c(MPI_Comm comm, int *out)
{
    if (!out) return MPI_ERR_ARG;
    fmpi_handle handle = {.comm = comm};
    int token;
    lock();
    int ready = initialized;
    int found = ready && known(FMPI_COMM, handle, &token);
    unlock();
    if (!ready) return MPI_ERR_OTHER;
    if (!found) {
        int rc = fortran_mpi_handle_reserve(FMPI_COMM, &token);
        if (rc != MPI_SUCCESS) return rc;
        int reserved = token;
        rc = fortran_mpi_handle_store(FMPI_COMM, &comm, &token, 0);
        if (rc != MPI_SUCCESS) {
            fortran_mpi_handle_release(FMPI_COMM, reserved);
            return rc;
        }
    }
    *out = token;
    return MPI_SUCCESS;
}
