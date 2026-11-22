#include <mpi.h>
#include <stdio.h>

_Static_assert(_Generic((MPI_Fint)0, int: 1, default: 0), "MPI_Fint must match C int");

int native_constants(const MPI_Fint *values)
{
    const MPI_Fint expected[] = {
        MPI_ANY_SOURCE, MPI_ANY_TAG, MPI_PROC_NULL, MPI_ROOT, MPI_UNDEFINED,
        MPI_F_STATUS_SIZE, MPI_F_SOURCE + 1, MPI_F_TAG + 1, MPI_F_ERROR + 1,
        MPI_Op_c2f(MPI_OP_NULL), MPI_Op_c2f(MPI_SUM), MPI_Op_c2f(MPI_MIN),
        MPI_Op_c2f(MPI_MAX), MPI_Op_c2f(MPI_PROD), MPI_Op_c2f(MPI_BAND),
        MPI_Op_c2f(MPI_BOR), MPI_Op_c2f(MPI_BXOR), MPI_Op_c2f(MPI_LAND),
        MPI_Op_c2f(MPI_LOR), MPI_Op_c2f(MPI_LXOR), MPI_Op_c2f(MPI_MINLOC),
        MPI_Op_c2f(MPI_MAXLOC), MPI_Op_c2f(MPI_REPLACE), MPI_Op_c2f(MPI_NO_OP),
        MPI_Comm_c2f(MPI_COMM_NULL), MPI_Comm_c2f(MPI_COMM_WORLD), MPI_Comm_c2f(MPI_COMM_SELF),
        MPI_Group_c2f(MPI_GROUP_NULL), MPI_Group_c2f(MPI_GROUP_EMPTY), MPI_Info_c2f(MPI_INFO_NULL),
        MPI_Errhandler_c2f(MPI_ERRHANDLER_NULL), MPI_Errhandler_c2f(MPI_ERRORS_ARE_FATAL),
        MPI_Errhandler_c2f(MPI_ERRORS_ABORT), MPI_Errhandler_c2f(MPI_ERRORS_RETURN),
        MPI_Request_c2f(MPI_REQUEST_NULL), MPI_Type_c2f(MPI_DATATYPE_NULL),
        MPI_Type_c2f(MPI_INT), MPI_Type_c2f(MPI_FLOAT), MPI_Type_c2f(MPI_DOUBLE),
        MPI_Type_c2f(MPI_LOGICAL), MPI_Type_c2f(MPI_INTEGER), MPI_Type_c2f(MPI_REAL),
        MPI_Type_c2f(MPI_DOUBLE_PRECISION), MPI_Type_c2f(MPI_DOUBLE_COMPLEX),
        MPI_Type_c2f(MPI_CHARACTER), MPI_Type_c2f(MPI_INT32_T), MPI_Type_c2f(MPI_INT64_T),
        MPI_Type_c2f(MPI_REAL4), MPI_Type_c2f(MPI_INTEGER8), MPI_Type_c2f(MPI_REAL8)
    };
    for (size_t i = 0; i < sizeof(expected) / sizeof(expected[0]); ++i) {
        if (values[i] != expected[i]) {
            fprintf(stderr, "native constant %zu: Fortran=%d C=%d\n", i + 1, values[i], expected[i]);
            return 1;
        }
    }
    return MPI_SUCCESS;
}

int native_comm(MPI_Fint comm, MPI_Fint *duplicate)
{
    MPI_Comm native = MPI_Comm_f2c(comm), next;
    int comparison, size, expected_size, rank, expected_rank;
    if (MPI_Comm_c2f(native) != comm) return 1;
    if (MPI_Comm_compare(native, MPI_COMM_WORLD, &comparison) != MPI_SUCCESS) return 2;
    if (comparison != MPI_IDENT && comparison != MPI_CONGRUENT) return 3;
    if (MPI_Comm_size(native, &size) != MPI_SUCCESS ||
        MPI_Comm_size(MPI_COMM_WORLD, &expected_size) != MPI_SUCCESS || size != expected_size) return 4;
    if (MPI_Comm_rank(native, &rank) != MPI_SUCCESS ||
        MPI_Comm_rank(MPI_COMM_WORLD, &expected_rank) != MPI_SUCCESS || rank != expected_rank) return 5;
    if (MPI_Comm_dup(native, &next) != MPI_SUCCESS) return 6;
    *duplicate = MPI_Comm_c2f(next);
    return MPI_SUCCESS;
}

int native_group(MPI_Fint group, int expected_size)
{
    MPI_Group native = MPI_Group_f2c(group);
    int size;
    if (MPI_Group_c2f(native) != group) return 1;
    if (MPI_Group_size(native, &size) != MPI_SUCCESS || size != expected_size) return 2;
    return MPI_SUCCESS;
}

int native_type(MPI_Fint datatype, int count, MPI_Fint *created)
{
    MPI_Datatype native = MPI_Type_f2c(datatype), next;
    int size, integer_size;
    if (MPI_Type_c2f(native) != datatype) return 1;
    if (MPI_Type_size(native, &size) != MPI_SUCCESS ||
        MPI_Type_size(MPI_INTEGER, &integer_size) != MPI_SUCCESS || size != count * integer_size) return 2;
    if (MPI_Type_contiguous(3, MPI_INTEGER, &next) != MPI_SUCCESS) return 3;
    if (MPI_Type_commit(&next) != MPI_SUCCESS) return 4;
    *created = MPI_Type_c2f(next);
    return MPI_SUCCESS;
}

static void add_integers(void *input, void *output, int *count, MPI_Datatype *datatype)
{
    const int *in = input;
    int *out = output;
    (void)datatype;
    for (int i = 0; i < *count; ++i) out[i] += in[i];
}

int native_resources(MPI_Fint *info, MPI_Fint *op, int release)
{
    MPI_Info native_info;
    MPI_Op native_op;
    if (release) {
        native_info = MPI_Info_f2c(*info);
        native_op = MPI_Op_f2c(*op);
        if (MPI_Info_free(&native_info) != MPI_SUCCESS) return 1;
        if (MPI_Op_free(&native_op) != MPI_SUCCESS) return 2;
    } else {
        if (MPI_Info_create(&native_info) != MPI_SUCCESS) return 3;
        if (MPI_Op_create(add_integers, 1, &native_op) != MPI_SUCCESS) return 4;
    }
    *info = MPI_Info_c2f(native_info);
    *op = MPI_Op_c2f(native_op);
    return MPI_SUCCESS;
}

int native_request(MPI_Fint *request, int cancel)
{
    MPI_Request native = MPI_Request_f2c(*request);
    int flag;
    if (MPI_Request_c2f(native) != *request) return 1;
    if (MPI_Request_get_status(native, &flag, MPI_STATUS_IGNORE) != MPI_SUCCESS) return 2;
    if (cancel && MPI_Cancel(&native) != MPI_SUCCESS) return 3;
    *request = MPI_Request_c2f(native);
    return MPI_SUCCESS;
}

int native_status(const MPI_Fint *status, int source, int tag, int count, int cancelled)
{
    MPI_Status native;
    int actual, is_cancelled;
    if (MPI_Status_f2c(status, &native) != MPI_SUCCESS) return 1;
    if (MPI_Test_cancelled(&native, &is_cancelled) != MPI_SUCCESS || is_cancelled != cancelled) return 2;
    if (!cancelled) {
        if (native.MPI_SOURCE != source || native.MPI_TAG != tag) return 3;
        if (MPI_Get_count(&native, MPI_INTEGER, &actual) != MPI_SUCCESS || actual != count) return 4;
    }
    /* MPI_ERROR is not defined by successful single-status operations. */
    return MPI_SUCCESS;
}

int native_make_status(MPI_Fint *status)
{
    MPI_Status native;
    int sent[3] = {19, 23, 29}, received[3];
    if (MPI_Sendrecv(sent, 3, MPI_INTEGER, 0, 91, received, 3, MPI_INTEGER,
                     0, 91, MPI_COMM_SELF, &native) != MPI_SUCCESS) return 1;
    native.MPI_ERROR = MPI_SUCCESS;
    return MPI_Status_c2f(&native, status);
}
