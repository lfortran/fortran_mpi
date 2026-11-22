/*
 * C metadata for the selected runtime. Handle tables are used only to
 * verify the matching Fortran constant headers after initialization, not
 * to translate public integers. Scalar normalization and address sentinels
 * remain binding-owned. There are no MPI function wrappers here.
 */

#include <stddef.h>
#if defined(MPI_ABI)
#include <mpi_abi.h>
#else
#include <mpi.h>
#endif

/* Order and extents match check_predefined_handles and mpi_c_bindings. */
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
    MPI_DATATYPE_NULL, MPI_INT, MPI_FLOAT, MPI_DOUBLE, MPI_LOGICAL, MPI_INTEGER,
    MPI_REAL, MPI_DOUBLE_PRECISION, MPI_DOUBLE_COMPLEX, MPI_CHARACTER,
    MPI_INT32_T, MPI_INT64_T, MPI_REAL4, MPI_INTEGER8, MPI_REAL8,
};

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

#if defined(MPI_ABI_VERSION)
/* Only the standard ABI has this specified all-int C status layout. */
_Static_assert(MPI_F_STATUS_SIZE == 8 && sizeof(MPI_Status) == 8 * sizeof(int) &&
               offsetof(MPI_Status, MPI_SOURCE) == 0 &&
               offsetof(MPI_Status, MPI_TAG) == sizeof(int) &&
               offsetof(MPI_Status, MPI_ERROR) == 2 * sizeof(int),
               "unsupported MPI-5 ABI status layout");
int c_sizeof_MPI_Fint = sizeof(int);
#else
_Static_assert(_Generic((MPI_Fint)0, int: 1, default: 0),
               "fortran_mpi requires MPI_Fint to be C int");
int c_sizeof_MPI_Fint = sizeof(MPI_Fint);
#endif

int c_sizeof_int = sizeof(int);
int c_sizeof_MPI_Status = sizeof(MPI_Status);
int c_alignof_MPI_Status = _Alignof(MPI_Status);
int c_MPI_F_STATUS_SIZE = MPI_F_STATUS_SIZE;
int c_MPI_F_SOURCE = MPI_F_SOURCE;
int c_MPI_F_TAG = MPI_F_TAG;
int c_MPI_F_ERROR = MPI_F_ERROR;
int c_sizeof_MPI_Comm = sizeof(MPI_Comm);
