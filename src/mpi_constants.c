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

/* Error classes, indexed by their ABI value. The classes of MPI 4 and
 * later are only there if the library has them. The MPI-5 ABI header
 * (MPI_ABI_VERSION) has them all, as enum values that #ifdef cannot see. */

int c_error_class_table[63] = {
    [0] = MPI_SUCCESS,
    [1] = MPI_ERR_BUFFER,
    [2] = MPI_ERR_COUNT,
    [3] = MPI_ERR_TYPE,
    [4] = MPI_ERR_TAG,
    [5] = MPI_ERR_COMM,
    [6] = MPI_ERR_RANK,
    [7] = MPI_ERR_REQUEST,
    [8] = MPI_ERR_ROOT,
    [9] = MPI_ERR_GROUP,
    [10] = MPI_ERR_OP,
    [11] = MPI_ERR_TOPOLOGY,
    [12] = MPI_ERR_DIMS,
    [13] = MPI_ERR_ARG,
    [14] = MPI_ERR_UNKNOWN,
    [15] = MPI_ERR_TRUNCATE,
    [16] = MPI_ERR_OTHER,
    [17] = MPI_ERR_INTERN,
    [18] = MPI_ERR_PENDING,
    [19] = MPI_ERR_IN_STATUS,
    [20] = MPI_ERR_ACCESS,
    [21] = MPI_ERR_AMODE,
    [22] = MPI_ERR_ASSERT,
    [23] = MPI_ERR_BAD_FILE,
    [24] = MPI_ERR_BASE,
    [25] = MPI_ERR_CONVERSION,
    [26] = MPI_ERR_DISP,
    [27] = MPI_ERR_DUP_DATAREP,
    [28] = MPI_ERR_FILE_EXISTS,
    [29] = MPI_ERR_FILE_IN_USE,
    [30] = MPI_ERR_FILE,
    [31] = MPI_ERR_INFO_KEY,
    [32] = MPI_ERR_INFO_NOKEY,
    [33] = MPI_ERR_INFO_VALUE,
    [34] = MPI_ERR_INFO,
    [35] = MPI_ERR_IO,
    [36] = MPI_ERR_KEYVAL,
    [37] = MPI_ERR_LOCKTYPE,
    [38] = MPI_ERR_NAME,
    [39] = MPI_ERR_NO_MEM,
    [40] = MPI_ERR_NOT_SAME,
    [41] = MPI_ERR_NO_SPACE,
    [42] = MPI_ERR_NO_SUCH_FILE,
    [43] = MPI_ERR_PORT,
    [44] = MPI_ERR_QUOTA,
    [45] = MPI_ERR_READ_ONLY,
    [46] = MPI_ERR_RMA_ATTACH,
    [47] = MPI_ERR_RMA_CONFLICT,
    [48] = MPI_ERR_RMA_RANGE,
    [49] = MPI_ERR_RMA_SHARED,
    [50] = MPI_ERR_RMA_SYNC,
    [51] = MPI_ERR_SERVICE,
    [52] = MPI_ERR_SIZE,
    [53] = MPI_ERR_SPAWN,
    [54] = MPI_ERR_UNSUPPORTED_DATAREP,
    [55] = MPI_ERR_UNSUPPORTED_OPERATION,
    [56] = MPI_ERR_WIN,
    [57] = MPI_ERR_RMA_FLAVOR,
#if defined(MPI_ERR_PROC_ABORTED) || defined(MPI_ABI_VERSION)
    [58] = MPI_ERR_PROC_ABORTED,
#endif
#if defined(MPI_ERR_VALUE_TOO_LARGE) || defined(MPI_ABI_VERSION)
    [59] = MPI_ERR_VALUE_TOO_LARGE,
#endif
#if defined(MPI_ERR_SESSION) || defined(MPI_ABI_VERSION)
    [60] = MPI_ERR_SESSION,
#endif
#if defined(MPI_ERR_ERRHANDLER) || defined(MPI_ABI_VERSION)
    [61] = MPI_ERR_ERRHANDLER,
#endif
#if defined(MPI_ERR_ABI) || defined(MPI_ABI_VERSION)
    [62] = MPI_ERR_ABI,
#endif
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
