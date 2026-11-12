/*
 * Native values of the MPI constants, indexed by their MPI-5 ABI value.
 *
 * src/mpi.f90 gives every MPI constant its MPI-5 ABI value (MPI 5.0,
 * chapter 21), the same for all MPI implementations. This file is compiled
 * against the native <mpi.h> and tells the Fortran code which value the MPI
 * library actually uses for each of them. It contains no functions, only
 * initialized data, and works with any MPI implementation. It goes away once
 * we link against an MPI-5 ABI library, where the native values are the ABI
 * values. See doc/design.md.
 *
 * Each handle table covers the ABI range of one handle type, and is indexed
 * by the ABI value minus the first value of the range. Entries that
 * src/mpi.f90 has no constant for are left zero, which is never a valid
 * handle. The table sizes must match src/mpi_c_bindings.f90.
 */

#include <stddef.h>
#include <mpi.h>

/* Handles */

MPI_Op c_op_table[32] = {               /* ABI 0x020 .. 0x03f */
    [0x00] = MPI_OP_NULL,
    [0x01] = MPI_SUM,
    [0x02] = MPI_MIN,
    [0x03] = MPI_MAX,
    [0x04] = MPI_PROD,
    [0x08] = MPI_BAND,
    [0x09] = MPI_BOR,
    [0x0a] = MPI_BXOR,
    [0x10] = MPI_LAND,
    [0x11] = MPI_LOR,
    [0x12] = MPI_LXOR,
    [0x18] = MPI_MINLOC,
    [0x19] = MPI_MAXLOC,
    [0x1c] = MPI_REPLACE,
    [0x1d] = MPI_NO_OP,
};

MPI_Comm c_comm_table[3] = {            /* ABI 0x100 .. 0x102 */
    [0x00] = MPI_COMM_NULL,
    [0x01] = MPI_COMM_WORLD,
    [0x02] = MPI_COMM_SELF,
};

MPI_Group c_group_table[2] = {          /* ABI 0x108 .. 0x109 */
    [0x00] = MPI_GROUP_NULL,
    [0x01] = MPI_GROUP_EMPTY,
};

MPI_Info c_info_table[1] = {            /* ABI 0x130 */
    [0x00] = MPI_INFO_NULL,
};

MPI_Request c_request_table[1] = {      /* ABI 0x180 */
    [0x00] = MPI_REQUEST_NULL,
};

MPI_Errhandler c_errhandler_table[4] = {  /* ABI 0x140 .. 0x143 */
    [0x00] = MPI_ERRHANDLER_NULL,
    [0x01] = MPI_ERRORS_ARE_FATAL,
    [0x02] = MPI_ERRORS_ABORT,
    [0x03] = MPI_ERRORS_RETURN,
};

MPI_Datatype c_datatype_table[256] = {  /* ABI 0x200 .. 0x2ff */
    [0x00] = MPI_DATATYPE_NULL,
    [0x09] = MPI_INT,
    [0x10] = MPI_FLOAT,
    [0x14] = MPI_DOUBLE,
    [0x18] = MPI_LOGICAL,
    [0x19] = MPI_INTEGER,
    [0x1a] = MPI_REAL,
    [0x1c] = MPI_DOUBLE_PRECISION,
    [0x1d] = MPI_DOUBLE_COMPLEX,
    [0x1e] = MPI_CHARACTER,
    [0x50] = MPI_INT32_T,
    [0x58] = MPI_INT64_T,
    [0xd2] = MPI_REAL4,
    [0xd9] = MPI_INTEGER8,
    [0xda] = MPI_REAL8,
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

/* Layout of the native MPI_Status, to convert it to the ABI layout of the
 * Fortran status, and the size of a native handle, to check MPI_HANDLE_KIND. */

int c_sizeof_MPI_Status = sizeof(MPI_Status);
int c_offsetof_MPI_SOURCE = offsetof(MPI_Status, MPI_SOURCE);
int c_offsetof_MPI_TAG = offsetof(MPI_Status, MPI_TAG);
int c_offsetof_MPI_ERROR = offsetof(MPI_Status, MPI_ERROR);

int c_sizeof_MPI_Comm = sizeof(MPI_Comm);
