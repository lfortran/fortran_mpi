#include "mpi_internal.h"
#include <stddef.h>
#include <string.h>

/* Order and extents match the binding-owned IDs in mpi_handles.c. */
MPI_Op c_op_table[15] = {
    MPI_OP_NULL, MPI_SUM, MPI_MIN, MPI_MAX, MPI_PROD,
    MPI_BAND, MPI_BOR, MPI_BXOR, MPI_LAND, MPI_LOR, MPI_LXOR,
    MPI_MINLOC, MPI_MAXLOC, MPI_REPLACE, MPI_NO_OP,
};

MPI_Comm c_comm_table[3] = {
    MPI_COMM_NULL, MPI_COMM_WORLD, MPI_COMM_SELF,
};

MPI_Group c_group_table[2] = {
    MPI_GROUP_NULL, MPI_GROUP_EMPTY,
};

MPI_Info c_info_table[1] = {
    MPI_INFO_NULL,
};

MPI_Request c_request_table[1] = {
    MPI_REQUEST_NULL,
};

MPI_Errhandler c_errhandler_table[4] = {
    MPI_ERRHANDLER_NULL, MPI_ERRORS_ARE_FATAL, MPI_ERRORS_ABORT, MPI_ERRORS_RETURN,
};

MPI_Datatype c_datatype_table[15] = {
#if defined(MPI_ABI)
    MPI_DATATYPE_NULL, MPI_INT, MPI_FLOAT, MPI_DOUBLE, MPI_LOGICAL, MPI_INTEGER,
    MPI_REAL, MPI_DOUBLE_PRECISION, MPI_DOUBLE_COMPLEX, MPI_CHARACTER,
    MPI_INT32_T, MPI_INT64_T, MPI_REAL4, MPI_INTEGER8, MPI_REAL8,
#else
    /* LOGICAL is filled from the selected compiler's representation at Init. */
    MPI_DATATYPE_NULL, MPI_INT, MPI_FLOAT, MPI_DOUBLE, MPI_DATATYPE_NULL, MPI_INT,
    MPI_FLOAT, MPI_DOUBLE, MPI_C_DOUBLE_COMPLEX, MPI_CHAR,
    MPI_INT32_T, MPI_INT64_T, MPI_FLOAT, MPI_INT64_T, MPI_DOUBLE,
#endif
};

MPI_Op c_logical_op_table[3] = {MPI_LAND, MPI_LOR, MPI_LXOR};

/* Integer constants. These are passed to and returned by MPI as plain
 * integers, so their native values differ between implementations. */

int c_MPI_ANY_SOURCE = MPI_ANY_SOURCE;
int c_MPI_ANY_TAG = MPI_ANY_TAG;
int c_MPI_PROC_NULL = MPI_PROC_NULL;
int c_MPI_ROOT = MPI_ROOT;
int c_MPI_UNDEFINED = MPI_UNDEFINED;

int c_MPI_THREAD_SINGLE = MPI_THREAD_SINGLE;
int c_MPI_THREAD_FUNNELED = MPI_THREAD_FUNNELED;
int c_MPI_THREAD_SERIALIZED = MPI_THREAD_SERIALIZED;
int c_MPI_THREAD_MULTIPLE = MPI_THREAD_MULTIPLE;

int c_MPI_COMM_TYPE_SHARED = MPI_COMM_TYPE_SHARED;

int c_MPI_MAX_OBJECT_NAME = MPI_MAX_OBJECT_NAME;
int c_MPI_MAX_ERROR_STRING = MPI_MAX_ERROR_STRING;
int c_MPI_MAX_PROCESSOR_NAME = MPI_MAX_PROCESSOR_NAME;

int c_MPI_IDENT = MPI_IDENT;
int c_MPI_CONGRUENT = MPI_CONGRUENT;
int c_MPI_SIMILAR = MPI_SIMILAR;
int c_MPI_UNEQUAL = MPI_UNEQUAL;

/* Addresses */

void* c_MPI_IN_PLACE = MPI_IN_PLACE;
MPI_Status* c_MPI_STATUS_IGNORE = MPI_STATUS_IGNORE;
MPI_Status* c_MPI_STATUSES_IGNORE = MPI_STATUSES_IGNORE;

_Static_assert(sizeof(int) == 4, "fortran_mpi requires 32-bit C int");
_Static_assert(sizeof(MPI_Comm) == sizeof(MPI_Op) &&
               sizeof(MPI_Comm) == sizeof(MPI_Group) &&
               sizeof(MPI_Comm) == sizeof(MPI_Info) &&
               sizeof(MPI_Comm) == sizeof(MPI_Request) &&
               sizeof(MPI_Comm) == sizeof(MPI_Errhandler) &&
               sizeof(MPI_Comm) == sizeof(MPI_Datatype),
               "fortran_mpi requires uniform C handle widths");
_Static_assert(_Alignof(MPI_Status) <= _Alignof(max_align_t),
               "MPI_Status alignment must be supported by malloc");

#if defined(MPI_ABI)
/* Only the standard ABI has this specified all-int C status layout. */
_Static_assert(sizeof(MPI_Status) == 8 * sizeof(int) &&
               offsetof(MPI_Status, MPI_SOURCE) == 0 &&
               offsetof(MPI_Status, MPI_TAG) == sizeof(int) &&
               offsetof(MPI_Status, MPI_ERROR) == 2 * sizeof(int),
               "unsupported MPI-5 ABI status layout");
#endif
_Static_assert(sizeof(MPI_Status) <= 8 * sizeof(int),
               "C MPI_Status does not fit the binding's eight-integer status");
_Static_assert(sizeof(((MPI_Status *)0)->MPI_SOURCE) == sizeof(int) &&
               sizeof(((MPI_Status *)0)->MPI_TAG) == sizeof(int) &&
               sizeof(((MPI_Status *)0)->MPI_ERROR) == sizeof(int),
               "unsupported C MPI_Status public fields");

int c_sizeof_int = sizeof(int);
int c_sizeof_MPI_Status = sizeof(MPI_Status);
int c_alignof_MPI_Status = _Alignof(MPI_Status);
int c_sizeof_MPI_Comm = sizeof(MPI_Comm);

static int status_public_byte(size_t i)
{
    const size_t offsets[3] = {offsetof(MPI_Status, MPI_SOURCE),
                              offsetof(MPI_Status, MPI_TAG),
                              offsetof(MPI_Status, MPI_ERROR)};
    for (int field = 0; field < 3; ++field)
        if (i >= offsets[field] && i < offsets[field] + sizeof(int)) return 1;
    return 0;
}

int fortran_mpi_status_to_fortran(const MPI_Status *status, int out[8])
{
    const unsigned char *bytes = (const unsigned char *)status;
    unsigned char *payload = (unsigned char *)(out + 3);
    size_t j = 0;
    memset(out, 0, 8 * sizeof(int));
    out[0] = status->MPI_SOURCE;
    out[1] = status->MPI_TAG;
    out[2] = status->MPI_ERROR;
    for (size_t i = 0; i < sizeof(*status); ++i)
        if (!status_public_byte(i)) payload[j++] = bytes[i];
    return MPI_SUCCESS;
}

int fortran_mpi_status_to_c(const int in[8], MPI_Status *status)
{
    unsigned char *bytes = (unsigned char *)status;
    const unsigned char *payload = (const unsigned char *)(in + 3);
    size_t j = 0;
    for (size_t i = 0; i < sizeof(*status); ++i)
        if (!status_public_byte(i)) bytes[i] = payload[j++];
    status->MPI_SOURCE = in[0];
    status->MPI_TAG = in[1];
    status->MPI_ERROR = in[2];
    return MPI_SUCCESS;
}
