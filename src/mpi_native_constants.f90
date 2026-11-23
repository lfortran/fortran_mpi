module mpi_native_constants
    use iso_c_binding, only: c_int
    implicit none
    private

    integer, parameter :: default_integer_must_match_c_int = 1 / merge(1, 0, &
        kind(0) == c_int .and. storage_size(0) == storage_size(0_c_int))

    ! Binding-owned IDs and status layout, also the MPI-5 ABI predefined IDs.
    integer, parameter :: MPI_ANY_SOURCE = -1
    integer, parameter :: MPI_ANY_TAG = -2
    integer, parameter :: MPI_PROC_NULL = -3
    integer, parameter :: MPI_ROOT = -4
    integer, parameter :: MPI_UNDEFINED = -32766
    integer, parameter :: MPI_STATUS_SIZE = 8
    integer, parameter :: MPI_SOURCE = 1
    integer, parameter :: MPI_TAG = 2
    integer, parameter :: MPI_ERROR = 3
    integer, parameter :: MPI_OP_NULL = 32
    integer, parameter :: MPI_SUM = 33
    integer, parameter :: MPI_MIN = 34
    integer, parameter :: MPI_MAX = 35
    integer, parameter :: MPI_PROD = 36
    integer, parameter :: MPI_BAND = 40
    integer, parameter :: MPI_BOR = 41
    integer, parameter :: MPI_BXOR = 42
    integer, parameter :: MPI_LAND = 48
    integer, parameter :: MPI_LOR = 49
    integer, parameter :: MPI_LXOR = 50
    integer, parameter :: MPI_MINLOC = 56
    integer, parameter :: MPI_MAXLOC = 57
    integer, parameter :: MPI_REPLACE = 60
    integer, parameter :: MPI_NO_OP = 61
    integer, parameter :: MPI_COMM_NULL = 256
    integer, parameter :: MPI_COMM_WORLD = 257
    integer, parameter :: MPI_COMM_SELF = 258
    integer, parameter :: MPI_GROUP_NULL = 264
    integer, parameter :: MPI_GROUP_EMPTY = 265
    integer, parameter :: MPI_INFO_NULL = 304
    integer, parameter :: MPI_ERRHANDLER_NULL = 320
    integer, parameter :: MPI_ERRORS_ARE_FATAL = 321
    integer, parameter :: MPI_ERRORS_ABORT = 322
    integer, parameter :: MPI_ERRORS_RETURN = 323
    integer, parameter :: MPI_REQUEST_NULL = 384
    integer, parameter :: MPI_DATATYPE_NULL = 512
    integer, parameter :: MPI_INT = 521
    integer, parameter :: MPI_FLOAT = 528
    integer, parameter :: MPI_DOUBLE = 532
    integer, parameter :: MPI_LOGICAL = 536
    integer, parameter :: MPI_INTEGER = 537
    integer, parameter :: MPI_REAL = 538
    integer, parameter :: MPI_DOUBLE_PRECISION = 540
    integer, parameter :: MPI_DOUBLE_COMPLEX = 541
    integer, parameter :: MPI_CHARACTER = 542
    integer, parameter :: MPI_INT32_T = 592
    integer, parameter :: MPI_INT64_T = 600
    integer, parameter :: MPI_REAL4 = 722
    integer, parameter :: MPI_INTEGER8 = 729
    integer, parameter :: MPI_REAL8 = 730

#if defined(MPI_ABI)
    ! MPI-5 standard C ABI error classes, not native MPICH error classes.
    integer, parameter :: MPI_SUCCESS = 0
    integer, parameter :: MPI_ERR_BUFFER = 1
    integer, parameter :: MPI_ERR_COUNT = 2
    integer, parameter :: MPI_ERR_TYPE = 3
    integer, parameter :: MPI_ERR_TAG = 4
    integer, parameter :: MPI_ERR_COMM = 5
    integer, parameter :: MPI_ERR_RANK = 6
    integer, parameter :: MPI_ERR_REQUEST = 7
    integer, parameter :: MPI_ERR_ROOT = 8
    integer, parameter :: MPI_ERR_GROUP = 9
    integer, parameter :: MPI_ERR_OP = 10
    integer, parameter :: MPI_ERR_TOPOLOGY = 11
    integer, parameter :: MPI_ERR_DIMS = 12
    integer, parameter :: MPI_ERR_ARG = 13
    integer, parameter :: MPI_ERR_UNKNOWN = 14
    integer, parameter :: MPI_ERR_TRUNCATE = 15
    integer, parameter :: MPI_ERR_OTHER = 16
    integer, parameter :: MPI_ERR_INTERN = 17
    integer, parameter :: MPI_ERR_PENDING = 18
    integer, parameter :: MPI_ERR_IN_STATUS = 19
    integer, parameter :: MPI_ERR_ACCESS = 20
    integer, parameter :: MPI_ERR_AMODE = 21
    integer, parameter :: MPI_ERR_ASSERT = 22
    integer, parameter :: MPI_ERR_BAD_FILE = 23
    integer, parameter :: MPI_ERR_BASE = 24
    integer, parameter :: MPI_ERR_CONVERSION = 25
    integer, parameter :: MPI_ERR_DISP = 26
    integer, parameter :: MPI_ERR_DUP_DATAREP = 27
    integer, parameter :: MPI_ERR_FILE_EXISTS = 28
    integer, parameter :: MPI_ERR_FILE_IN_USE = 29
    integer, parameter :: MPI_ERR_FILE = 30
    integer, parameter :: MPI_ERR_INFO_KEY = 31
    integer, parameter :: MPI_ERR_INFO_NOKEY = 32
    integer, parameter :: MPI_ERR_INFO_VALUE = 33
    integer, parameter :: MPI_ERR_INFO = 34
    integer, parameter :: MPI_ERR_IO = 35
    integer, parameter :: MPI_ERR_KEYVAL = 36
    integer, parameter :: MPI_ERR_LOCKTYPE = 37
    integer, parameter :: MPI_ERR_NAME = 38
    integer, parameter :: MPI_ERR_NO_MEM = 39
    integer, parameter :: MPI_ERR_NOT_SAME = 40
    integer, parameter :: MPI_ERR_NO_SPACE = 41
    integer, parameter :: MPI_ERR_NO_SUCH_FILE = 42
    integer, parameter :: MPI_ERR_PORT = 43
    integer, parameter :: MPI_ERR_QUOTA = 44
    integer, parameter :: MPI_ERR_READ_ONLY = 45
    integer, parameter :: MPI_ERR_RMA_ATTACH = 46
    integer, parameter :: MPI_ERR_RMA_CONFLICT = 47
    integer, parameter :: MPI_ERR_RMA_RANGE = 48
    integer, parameter :: MPI_ERR_RMA_SHARED = 49
    integer, parameter :: MPI_ERR_RMA_SYNC = 50
    integer, parameter :: MPI_ERR_SERVICE = 51
    integer, parameter :: MPI_ERR_SIZE = 52
    integer, parameter :: MPI_ERR_SPAWN = 53
    integer, parameter :: MPI_ERR_UNSUPPORTED_DATAREP = 54
    integer, parameter :: MPI_ERR_UNSUPPORTED_OPERATION = 55
    integer, parameter :: MPI_ERR_WIN = 56
    integer, parameter :: MPI_ERR_RMA_FLAVOR = 57
    integer, parameter :: MPI_ERR_PROC_ABORTED = 58
    integer, parameter :: MPI_ERR_VALUE_TOO_LARGE = 59
    integer, parameter :: MPI_ERR_SESSION = 60
    integer, parameter :: MPI_ERR_ERRHANDLER = 61
    integer, parameter :: MPI_ERR_ABI = 62
    integer, parameter :: MPI_ERR_LASTCODE = 16383

    public :: MPI_ERR_PROC_ABORTED, MPI_ERR_VALUE_TOO_LARGE, MPI_ERR_SESSION, MPI_ERR_ERRHANDLER, MPI_ERR_ABI
#else
    ! Generated by a scalar C-header emitter; no vendor Fortran inputs.
    include 'mpi_c_constants.inc'
    include 'mpi_optional_error_exports.inc'
#endif

    public :: MPI_SUCCESS, MPI_ERR_LASTCODE
    public :: MPI_ERR_BUFFER, MPI_ERR_COUNT, MPI_ERR_TYPE, MPI_ERR_TAG, MPI_ERR_COMM, MPI_ERR_RANK
    public :: MPI_ERR_REQUEST, MPI_ERR_ROOT, MPI_ERR_GROUP, MPI_ERR_OP, MPI_ERR_TOPOLOGY, MPI_ERR_DIMS
    public :: MPI_ERR_ARG, MPI_ERR_UNKNOWN, MPI_ERR_TRUNCATE, MPI_ERR_OTHER, MPI_ERR_INTERN
    public :: MPI_ERR_PENDING, MPI_ERR_IN_STATUS, MPI_ERR_ACCESS, MPI_ERR_AMODE, MPI_ERR_ASSERT
    public :: MPI_ERR_BAD_FILE, MPI_ERR_BASE, MPI_ERR_CONVERSION, MPI_ERR_DISP, MPI_ERR_DUP_DATAREP
    public :: MPI_ERR_FILE_EXISTS, MPI_ERR_FILE_IN_USE, MPI_ERR_FILE, MPI_ERR_INFO_KEY, MPI_ERR_INFO_NOKEY
    public :: MPI_ERR_INFO_VALUE, MPI_ERR_INFO, MPI_ERR_IO, MPI_ERR_KEYVAL, MPI_ERR_LOCKTYPE, MPI_ERR_NAME
    public :: MPI_ERR_NO_MEM, MPI_ERR_NOT_SAME, MPI_ERR_NO_SPACE, MPI_ERR_NO_SUCH_FILE, MPI_ERR_PORT, MPI_ERR_QUOTA
    public :: MPI_ERR_READ_ONLY, MPI_ERR_RMA_ATTACH, MPI_ERR_RMA_CONFLICT, MPI_ERR_RMA_RANGE, MPI_ERR_RMA_SHARED
    public :: MPI_ERR_RMA_SYNC, MPI_ERR_SERVICE, MPI_ERR_SIZE, MPI_ERR_SPAWN
    public :: MPI_ERR_UNSUPPORTED_DATAREP, MPI_ERR_UNSUPPORTED_OPERATION, MPI_ERR_WIN, MPI_ERR_RMA_FLAVOR
    public :: MPI_ANY_SOURCE, MPI_ANY_TAG, MPI_PROC_NULL, MPI_ROOT, MPI_UNDEFINED
    public :: MPI_STATUS_SIZE, MPI_SOURCE, MPI_TAG, MPI_ERROR
    public :: MPI_OP_NULL, MPI_SUM, MPI_MIN, MPI_MAX, MPI_PROD, MPI_BAND, MPI_BOR, MPI_BXOR
    public :: MPI_LAND, MPI_LOR, MPI_LXOR, MPI_MINLOC, MPI_MAXLOC, MPI_REPLACE, MPI_NO_OP
    public :: MPI_COMM_NULL, MPI_COMM_WORLD, MPI_COMM_SELF, MPI_GROUP_NULL, MPI_GROUP_EMPTY
    public :: MPI_INFO_NULL, MPI_ERRHANDLER_NULL, MPI_ERRORS_ARE_FATAL, MPI_ERRORS_ABORT, MPI_ERRORS_RETURN
    public :: MPI_REQUEST_NULL, MPI_DATATYPE_NULL, MPI_INT, MPI_FLOAT, MPI_DOUBLE
    public :: MPI_LOGICAL, MPI_INTEGER, MPI_REAL, MPI_DOUBLE_PRECISION, MPI_DOUBLE_COMPLEX
    public :: MPI_CHARACTER, MPI_INT32_T, MPI_INT64_T, MPI_REAL4, MPI_INTEGER8, MPI_REAL8
end module mpi_native_constants
