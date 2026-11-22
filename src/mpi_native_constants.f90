module mpi_native_constants
    use iso_c_binding, only: c_int
    implicit none
    private

    integer, parameter :: default_integer_must_match_c_int = 1 / merge(1, 0, &
        kind(0) == c_int .and. storage_size(0) == storage_size(0_c_int))

#if defined(MPI_ABI)
    ! MPI-5 ABI handle serialization and status layout, not native MPI_Fint.
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
#else
    ! Do not export vendor procedures, COMMON sentinels or capability flags.
    include 'mpif.h'
#endif

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
