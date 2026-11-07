module mpi
    use mpi_c_bindings, only: MPI_HANDLE_KIND
    use iso_c_binding, only: c_int, c_char, c_ptr, c_loc, c_null_ptr, c_associated
    implicit none

    ! Every constant has its MPI-5 ABI value (MPI 5.0, chapter 21; the values
    ! are from https://github.com/mpi-forum/mpi-abi-stubs, mpi.h). These are
    ! the same for all MPI implementations and platforms. The *_f2c and *_c2f
    ! functions below translate them to and from the values of the native
    ! MPI library, from src/mpi_constants.c. See doc/design.md.

    integer, parameter :: MPI_SUCCESS = 0

    ! Error classes
    integer, parameter :: MPI_ERR_BUFFER                = 1
    integer, parameter :: MPI_ERR_COUNT                 = 2
    integer, parameter :: MPI_ERR_TYPE                  = 3
    integer, parameter :: MPI_ERR_TAG                   = 4
    integer, parameter :: MPI_ERR_COMM                  = 5
    integer, parameter :: MPI_ERR_RANK                  = 6
    integer, parameter :: MPI_ERR_REQUEST               = 7
    integer, parameter :: MPI_ERR_ROOT                  = 8
    integer, parameter :: MPI_ERR_GROUP                 = 9
    integer, parameter :: MPI_ERR_OP                    = 10
    integer, parameter :: MPI_ERR_TOPOLOGY              = 11
    integer, parameter :: MPI_ERR_DIMS                  = 12
    integer, parameter :: MPI_ERR_ARG                   = 13
    integer, parameter :: MPI_ERR_UNKNOWN               = 14
    integer, parameter :: MPI_ERR_TRUNCATE              = 15
    integer, parameter :: MPI_ERR_OTHER                 = 16
    integer, parameter :: MPI_ERR_INTERN                = 17
    integer, parameter :: MPI_ERR_PENDING               = 18
    integer, parameter :: MPI_ERR_IN_STATUS             = 19
    integer, parameter :: MPI_ERR_ACCESS                = 20
    integer, parameter :: MPI_ERR_AMODE                 = 21
    integer, parameter :: MPI_ERR_ASSERT                = 22
    integer, parameter :: MPI_ERR_BAD_FILE              = 23
    integer, parameter :: MPI_ERR_BASE                  = 24
    integer, parameter :: MPI_ERR_CONVERSION            = 25
    integer, parameter :: MPI_ERR_DISP                  = 26
    integer, parameter :: MPI_ERR_DUP_DATAREP           = 27
    integer, parameter :: MPI_ERR_FILE_EXISTS           = 28
    integer, parameter :: MPI_ERR_FILE_IN_USE           = 29
    integer, parameter :: MPI_ERR_FILE                  = 30
    integer, parameter :: MPI_ERR_INFO_KEY              = 31
    integer, parameter :: MPI_ERR_INFO_NOKEY            = 32
    integer, parameter :: MPI_ERR_INFO_VALUE            = 33
    integer, parameter :: MPI_ERR_INFO                  = 34
    integer, parameter :: MPI_ERR_IO                    = 35
    integer, parameter :: MPI_ERR_KEYVAL                = 36
    integer, parameter :: MPI_ERR_LOCKTYPE              = 37
    integer, parameter :: MPI_ERR_NAME                  = 38
    integer, parameter :: MPI_ERR_NO_MEM                = 39
    integer, parameter :: MPI_ERR_NOT_SAME              = 40
    integer, parameter :: MPI_ERR_NO_SPACE              = 41
    integer, parameter :: MPI_ERR_NO_SUCH_FILE          = 42
    integer, parameter :: MPI_ERR_PORT                  = 43
    integer, parameter :: MPI_ERR_QUOTA                 = 44
    integer, parameter :: MPI_ERR_READ_ONLY             = 45
    integer, parameter :: MPI_ERR_RMA_ATTACH            = 46
    integer, parameter :: MPI_ERR_RMA_CONFLICT          = 47
    integer, parameter :: MPI_ERR_RMA_RANGE             = 48
    integer, parameter :: MPI_ERR_RMA_SHARED            = 49
    integer, parameter :: MPI_ERR_RMA_SYNC              = 50
    integer, parameter :: MPI_ERR_SERVICE               = 51
    integer, parameter :: MPI_ERR_SIZE                  = 52
    integer, parameter :: MPI_ERR_SPAWN                 = 53
    integer, parameter :: MPI_ERR_UNSUPPORTED_DATAREP   = 54
    integer, parameter :: MPI_ERR_UNSUPPORTED_OPERATION = 55
    integer, parameter :: MPI_ERR_WIN                   = 56
    integer, parameter :: MPI_ERR_RMA_FLAVOR            = 57
    integer, parameter :: MPI_ERR_PROC_ABORTED          = 58
    integer, parameter :: MPI_ERR_VALUE_TOO_LARGE       = 59
    integer, parameter :: MPI_ERR_SESSION               = 60
    integer, parameter :: MPI_ERR_ERRHANDLER            = 61
    integer, parameter :: MPI_ERR_ABI                   = 62
    integer, parameter :: MPI_ERR_LASTCODE = 16383

    ! Thread levels
    integer, parameter :: MPI_THREAD_SINGLE = 0
    integer, parameter :: MPI_THREAD_FUNNELED = 1024
    integer, parameter :: MPI_THREAD_SERIALIZED = 2048
    integer, parameter :: MPI_THREAD_MULTIPLE = 4096

    ! Wildcards and special ranks
    integer, parameter :: MPI_ANY_SOURCE = -1
    integer, parameter :: MPI_ANY_TAG = -2
    integer, parameter :: MPI_PROC_NULL = -3
    integer, parameter :: MPI_ROOT = -4
    integer, parameter :: MPI_UNDEFINED = -32766

    integer, parameter :: MPI_COMM_TYPE_SHARED = 221

    integer, parameter :: MPI_MAX_OBJECT_NAME = 128
    integer, parameter :: MPI_MAX_ERROR_STRING = 512

    ! Status: MPI_SOURCE, MPI_TAG and MPI_ERROR, then 5 integers that hold
    ! the rest of the native MPI_Status
    integer, parameter :: MPI_STATUS_SIZE = 8
    integer, parameter :: MPI_SOURCE = 1
    integer, parameter :: MPI_TAG = 2
    integer, parameter :: MPI_ERROR = 3

    ! Operations (ABI 0x020 .. 0x03f)
    integer, parameter :: MPI_OP_NULL = 32      ! 0x020
    integer, parameter :: MPI_SUM = 33          ! 0x021
    integer, parameter :: MPI_MIN = 34          ! 0x022
    integer, parameter :: MPI_MAX = 35          ! 0x023
    integer, parameter :: MPI_PROD = 36         ! 0x024
    integer, parameter :: MPI_BAND = 40         ! 0x028
    integer, parameter :: MPI_BOR = 41          ! 0x029
    integer, parameter :: MPI_BXOR = 42         ! 0x02a
    integer, parameter :: MPI_LAND = 48         ! 0x030
    integer, parameter :: MPI_LOR = 49          ! 0x031
    integer, parameter :: MPI_LXOR = 50         ! 0x032
    integer, parameter :: MPI_MINLOC = 56       ! 0x038
    integer, parameter :: MPI_MAXLOC = 57       ! 0x039
    integer, parameter :: MPI_REPLACE = 60      ! 0x03c
    integer, parameter :: MPI_NO_OP = 61        ! 0x03d

    ! Communicators (ABI 0x100 .. 0x102)
    integer, parameter :: MPI_COMM_NULL = 256   ! 0x100
    integer, parameter :: MPI_COMM_WORLD = 257  ! 0x101
    integer, parameter :: MPI_COMM_SELF = 258   ! 0x102

    ! Groups (ABI 0x108 .. 0x109)
    integer, parameter :: MPI_GROUP_NULL = 264  ! 0x108
    integer, parameter :: MPI_GROUP_EMPTY = 265 ! 0x109

    ! Info (ABI 0x130)
    integer, parameter :: MPI_INFO_NULL = 304   ! 0x130

    ! Error handlers (ABI 0x140 .. 0x143)
    integer, parameter :: MPI_ERRHANDLER_NULL = 320  ! 0x140
    integer, parameter :: MPI_ERRORS_ARE_FATAL = 321 ! 0x141
    integer, parameter :: MPI_ERRORS_ABORT = 322     ! 0x142
    integer, parameter :: MPI_ERRORS_RETURN = 323    ! 0x143

    ! Requests (ABI 0x180)
    integer, parameter :: MPI_REQUEST_NULL = 384 ! 0x180

    ! Datatypes (ABI 0x200 .. 0x2ff)
    integer, parameter :: MPI_DATATYPE_NULL = 512    ! 0x200
    integer, parameter :: MPI_INT = 521              ! 0x209
    integer, parameter :: MPI_FLOAT = 528            ! 0x210
    integer, parameter :: MPI_DOUBLE = 532           ! 0x214
    integer, parameter :: MPI_LOGICAL = 536          ! 0x218
    integer, parameter :: MPI_INTEGER = 537          ! 0x219
    integer, parameter :: MPI_REAL = 538             ! 0x21a
    integer, parameter :: MPI_DOUBLE_PRECISION = 540 ! 0x21c
    integer, parameter :: MPI_CHARACTER = 542        ! 0x21e
    integer, parameter :: MPI_REAL4 = 722            ! 0x2d2
    integer, parameter :: MPI_REAL8 = 730            ! 0x2da

    ! Predefined handles are 1 .. 4095 in the ABI. Handles that MPI creates
    ! (communicators, requests, ...) are the native Fortran handle plus this
    ! offset, so that they never collide with a predefined handle.
    integer, parameter :: USER_HANDLE_OFFSET = 4096

    ! MPI_IN_PLACE has a type of its own, so that the generic interfaces
    ! select the in-place specific procedures at compile time.
    type :: mpi_in_place_type
        integer :: unused = 0
    end type mpi_in_place_type
    type(mpi_in_place_type) :: MPI_IN_PLACE

    ! MPI_STATUS_IGNORE and MPI_STATUSES_IGNORE are recognized by their
    ! address, so they must not be copied: is_status_ignore.
    integer, target :: MPI_STATUS_IGNORE(MPI_STATUS_SIZE)
    integer, target :: MPI_STATUSES_IGNORE(MPI_STATUS_SIZE, 1)

    private :: USER_HANDLE_OFFSET
    private :: check_native_mpi, user_handle_c2f
    private :: op_f2c, comm_f2c, comm_c2f, group_f2c, group_c2f, info_f2c
    private :: request_f2c, request_c2f, datatype_f2c
    private :: rank_f2c, rank_c2f, tag_f2c, thread_level_f2c, thread_level_c2f
    private :: split_type_f2c, status_c2f, c_string_to_fortran, set_ierror
    private :: errhandler_f2c, error_class_c2f, is_status_ignore, is_statuses_ignore
    private :: ssend_core, recv_core, isend_core, irecv_core, sendrecv_core
    private :: bcast_core, reduce_core, allreduce_core, exscan_core, allgather_core
    private :: gatherv_core, allgatherv_core, scatter_core
    private :: c_int, c_char, c_ptr, c_loc, c_null_ptr, c_associated

    interface MPI_Init
        module procedure MPI_Init_proc
    end interface MPI_Init

    interface MPI_Init_thread
        module procedure MPI_Init_thread_proc
    end interface MPI_Init_thread

    interface MPI_Finalize
        module procedure MPI_Finalize_proc
    end interface MPI_Finalize

    interface MPI_Initialized
        module procedure MPI_Initialized_proc
    end interface MPI_Initialized

    interface MPI_Comm_size
        module procedure MPI_Comm_size_proc
    end interface MPI_Comm_size

    interface MPI_Comm_Group
        module procedure MPI_Comm_Group_proc
    end interface MPI_Comm_Group

    interface MPI_Comm_create
        module procedure MPI_Comm_create_proc
    end interface MPI_Comm_create

    interface MPI_Group_free
        module procedure MPI_Group_free_proc
    end interface MPI_Group_free

    interface MPI_Group_size
        module procedure MPI_Group_size_proc
    end interface MPI_Group_size

    interface MPI_Group_range_incl
        module procedure MPI_Group_range_incl_proc
    end interface MPI_Group_range_incl


    interface MPI_Comm_dup
        module procedure MPI_Comm_dup_proc
    end interface MPI_Comm_dup

    interface MPi_Comm_free
        module procedure MPI_Comm_free_proc
    end interface MPI_Comm_free

    interface MPI_Bcast
        module procedure MPI_Bcast_int_scalar
        module procedure MPI_Bcast_real_2D
    end interface MPI_Bcast

    interface MPI_Allgather
        module procedure MPI_Allgather_int
        module procedure MPI_Allgather_real
    end interface MPI_Allgather

    interface MPI_Isend
        module procedure MPI_Isend_2d
        module procedure MPI_Isend_3d
    end interface

    interface MPI_IRecv
        module procedure MPI_IRecv_proc
    end interface

    interface MPI_Allreduce
        module procedure MPI_Allreduce_scalar
        module procedure MPI_Allreduce_in_place_real8_scalar
        module procedure MPI_Allreduce_in_place_real8_1D
        module procedure MPI_Allreduce_1D_real_proc
        module procedure MPI_Allreduce_1D_int_proc
        module procedure MPI_Allreduce_scalar_logical_proc
    end interface

    interface MPI_Gatherv
        module procedure MPI_Gatherv_int
        module procedure MPI_Gatherv_real
        module procedure MPI_Gatherv_character
    end interface MPI_Gatherv

    interface MPI_Wtime
        module procedure MPI_Wtime_proc
    end interface

    interface MPI_Barrier
        module procedure MPI_Barrier_proc
    end interface

    interface MPI_Comm_rank
        module procedure MPI_Comm_rank_proc
    end interface

    interface MPI_Comm_split_type
        module procedure MPI_Comm_split_type_proc
    end interface

    interface MPI_Recv
        module procedure MPI_Recv_StatusArray_proc
    end interface

    interface MPI_Sendrecv
        module procedure MPI_Sendrecv_proc
    end interface

    interface MPI_Wait
        module procedure MPI_Wait_proc
    end interface

    interface MPI_Waitall
        module procedure MPI_Waitall_proc
    end interface

    interface MPI_Allgatherv
        module procedure MPI_Allgatherv_int
        module procedure MPI_Allgatherv_real
    end interface MPI_Allgatherv

    interface MPI_Scatter
        module procedure MPI_Scatter_real
    end interface MPI_Scatter

    interface MPI_Ssend
        module procedure MPI_Ssend_proc
    end interface

    interface MPI_Cart_create
        module procedure MPI_Cart_create_proc
    end interface

    interface MPI_Cart_sub
        module procedure MPI_Cart_sub_proc
    end interface

    interface MPI_Cart_shift
        module procedure MPI_Cart_shift_proc
    end interface

    interface MPI_Dims_create
        module procedure MPI_Dims_create_proc
    end interface

    interface MPI_Cart_coords
        module procedure MPI_Cart_coords_proc
    end interface

    interface MPI_Reduce
        module procedure MPI_Reduce_scalar_int
    end interface

    interface MPI_Exscan
        module procedure MPI_Exscan_scalar_int
    end interface MPI_Exscan

    interface MPI_Comm_set_errhandler
        module procedure MPI_Comm_set_errhandler_proc
    end interface MPI_Comm_set_errhandler

    interface MPI_Error_class
        module procedure MPI_Error_class_proc
    end interface MPI_Error_class

    interface MPI_Error_string
        module procedure MPI_Error_string_proc
    end interface MPI_Error_string

    interface MPI_Comm_get_name
        module procedure MPI_Comm_get_name_proc
    end interface MPI_Comm_get_name

    interface MPI_Type_get_name
        module procedure MPI_Type_get_name_proc
    end interface MPI_Type_get_name

    contains

    ! Translation between the ABI values of src/mpi.f90 and the native values
    ! of the MPI library. Every handle, special integer and status passes
    ! through one of these on its way to or from C. Predefined handles are a
    ! lookup in a table of src/mpi_constants.c; other handles go through the
    ! native MPI_*_f2c and MPI_*_c2f, shifted by USER_HANDLE_OFFSET.

    subroutine check_native_mpi()
        ! Checks that this library was compiled for the MPI library it is
        ! linked with. Called before MPI is initialized.
        use mpi_c_bindings, only: c_sizeof_mpi_comm, c_sizeof_mpi_status, &
            c_mpi_max_object_name, c_mpi_max_error_string
        if (c_sizeof_mpi_comm /= MPI_HANDLE_KIND) then
            print *, "fortran_mpi: compiled with MPI_HANDLE_KIND =", MPI_HANDLE_KIND, &
                "but the MPI library's handles have", c_sizeof_mpi_comm, "bytes."
            print *, "With Open MPI, compile src/mpi_c_bindings.f90 with -DOPEN_MPI."
            error stop 1
        end if
        if (c_sizeof_mpi_status > 4*MPI_STATUS_SIZE) then
            print *, "fortran_mpi: the native MPI_Status has", c_sizeof_mpi_status, &
                "bytes, more than MPI_STATUS_SIZE =", MPI_STATUS_SIZE, "integers."
            error stop 1
        end if
        if (c_mpi_max_object_name > MPI_MAX_OBJECT_NAME) then
            print *, "fortran_mpi: the native MPI_MAX_OBJECT_NAME is", &
                c_mpi_max_object_name, "more than", MPI_MAX_OBJECT_NAME
            error stop 1
        end if
        if (c_mpi_max_error_string > MPI_MAX_ERROR_STRING) then
            print *, "fortran_mpi: the native MPI_MAX_ERROR_STRING is", &
                c_mpi_max_error_string, "more than", MPI_MAX_ERROR_STRING
            error stop 1
        end if
    end subroutine check_native_mpi

    integer function user_handle_c2f(native) result(handle)
        integer(c_int), intent(in) :: native
        handle = native + USER_HANDLE_OFFSET
        if (handle > 0 .and. handle < USER_HANDLE_OFFSET) then
            print *, "fortran_mpi: the native Fortran handle", native, &
                "falls into the range of the predefined handles."
            error stop 1
        end if
    end function user_handle_c2f

    integer(kind=MPI_HANDLE_KIND) function op_f2c(op) result(c_op)
        use mpi_c_bindings, only: c_op_table, c_mpi_op_f2c
        integer, intent(in) :: op
        if (op >= MPI_OP_NULL .and. op <= MPI_OP_NULL + ubound(c_op_table, 1)) then
            c_op = c_op_table(op - MPI_OP_NULL)
        else
            c_op = c_mpi_op_f2c(op - USER_HANDLE_OFFSET)
        end if
    end function op_f2c

    integer(kind=MPI_HANDLE_KIND) function comm_f2c(comm) result(c_comm)
        use mpi_c_bindings, only: c_comm_table, c_mpi_comm_f2c
        integer, intent(in) :: comm
        if (comm >= MPI_COMM_NULL .and. comm <= MPI_COMM_NULL + ubound(c_comm_table, 1)) then
            c_comm = c_comm_table(comm - MPI_COMM_NULL)
        else
            c_comm = c_mpi_comm_f2c(comm - USER_HANDLE_OFFSET)
        end if
    end function comm_f2c

    integer function comm_c2f(c_comm) result(comm)
        use mpi_c_bindings, only: c_comm_table, c_mpi_comm_c2f
        integer(kind=MPI_HANDLE_KIND), intent(in) :: c_comm
        integer :: i
        do i = 0, ubound(c_comm_table, 1)
            if (c_comm == c_comm_table(i)) then
                comm = MPI_COMM_NULL + i
                return
            end if
        end do
        comm = user_handle_c2f(c_mpi_comm_c2f(c_comm))
    end function comm_c2f

    integer(kind=MPI_HANDLE_KIND) function group_f2c(group) result(c_group)
        use mpi_c_bindings, only: c_group_table, c_mpi_group_f2c
        integer, intent(in) :: group
        if (group >= MPI_GROUP_NULL .and. group <= MPI_GROUP_NULL + ubound(c_group_table, 1)) then
            c_group = c_group_table(group - MPI_GROUP_NULL)
        else
            c_group = c_mpi_group_f2c(group - USER_HANDLE_OFFSET)
        end if
    end function group_f2c

    integer function group_c2f(c_group) result(group)
        use mpi_c_bindings, only: c_group_table, c_mpi_group_c2f
        integer(kind=MPI_HANDLE_KIND), intent(in) :: c_group
        integer :: i
        do i = 0, ubound(c_group_table, 1)
            if (c_group == c_group_table(i)) then
                group = MPI_GROUP_NULL + i
                return
            end if
        end do
        group = user_handle_c2f(c_mpi_group_c2f(c_group))
    end function group_c2f

    integer(kind=MPI_HANDLE_KIND) function info_f2c(info) result(c_info)
        use mpi_c_bindings, only: c_info_table, c_mpi_info_f2c
        integer, intent(in) :: info
        if (info >= MPI_INFO_NULL .and. info <= MPI_INFO_NULL + ubound(c_info_table, 1)) then
            c_info = c_info_table(info - MPI_INFO_NULL)
        else
            c_info = c_mpi_info_f2c(info - USER_HANDLE_OFFSET)
        end if
    end function info_f2c

    integer(kind=MPI_HANDLE_KIND) function request_f2c(request) result(c_request)
        use mpi_c_bindings, only: c_request_table, c_mpi_request_f2c
        integer, intent(in) :: request
        if (request >= MPI_REQUEST_NULL .and. &
                request <= MPI_REQUEST_NULL + ubound(c_request_table, 1)) then
            c_request = c_request_table(request - MPI_REQUEST_NULL)
        else
            c_request = c_mpi_request_f2c(request - USER_HANDLE_OFFSET)
        end if
    end function request_f2c

    integer function request_c2f(c_request) result(request)
        use mpi_c_bindings, only: c_request_table, c_mpi_request_c2f
        integer(kind=MPI_HANDLE_KIND), intent(in) :: c_request
        integer :: i
        do i = 0, ubound(c_request_table, 1)
            if (c_request == c_request_table(i)) then
                request = MPI_REQUEST_NULL + i
                return
            end if
        end do
        request = user_handle_c2f(c_mpi_request_c2f(c_request))
    end function request_c2f

    integer(kind=MPI_HANDLE_KIND) function datatype_f2c(datatype) result(c_datatype)
        use mpi_c_bindings, only: c_datatype_table, c_mpi_type_f2c
        integer, intent(in) :: datatype
        if (datatype >= MPI_DATATYPE_NULL .and. &
                datatype <= MPI_DATATYPE_NULL + ubound(c_datatype_table, 1)) then
            c_datatype = c_datatype_table(datatype - MPI_DATATYPE_NULL)
        else
            c_datatype = c_mpi_type_f2c(datatype - USER_HANDLE_OFFSET)
        end if
    end function datatype_f2c

    integer(kind=MPI_HANDLE_KIND) function errhandler_f2c(errhandler) result(c_errhandler)
        use mpi_c_bindings, only: c_errhandler_table
        integer, intent(in) :: errhandler
        ! There are no user-defined error handlers yet
        c_errhandler = c_errhandler_table(errhandler - MPI_ERRHANDLER_NULL)
    end function errhandler_f2c

    integer function error_class_c2f(c_class) result(class)
        use mpi_c_bindings, only: c_error_class_table
        integer, intent(in) :: c_class
        integer :: i
        do i = 0, ubound(c_error_class_table, 1)
            if (c_class == c_error_class_table(i)) then
                class = i
                return
            end if
        end do
        class = MPI_ERR_UNKNOWN
    end function error_class_c2f

    ! Ranks and tags are passed unchanged, except for the special values,
    ! which are all negative.

    integer function rank_f2c(rank) result(c_rank)
        use mpi_c_bindings, only: c_mpi_any_source, c_mpi_proc_null, c_mpi_root
        integer, intent(in) :: rank
        if (rank >= 0) then
            c_rank = rank
        else if (rank == MPI_PROC_NULL) then
            c_rank = c_mpi_proc_null
        else if (rank == MPI_ANY_SOURCE) then
            c_rank = c_mpi_any_source
        else if (rank == MPI_ROOT) then
            c_rank = c_mpi_root
        else
            c_rank = rank
        end if
    end function rank_f2c

    integer function rank_c2f(c_rank) result(rank)
        use mpi_c_bindings, only: c_mpi_any_source, c_mpi_proc_null, c_mpi_root, &
            c_mpi_undefined
        integer, intent(in) :: c_rank
        if (c_rank >= 0) then
            rank = c_rank
        else if (c_rank == c_mpi_proc_null) then
            rank = MPI_PROC_NULL
        else if (c_rank == c_mpi_any_source) then
            rank = MPI_ANY_SOURCE
        else if (c_rank == c_mpi_root) then
            rank = MPI_ROOT
        else if (c_rank == c_mpi_undefined) then
            rank = MPI_UNDEFINED
        else
            rank = c_rank
        end if
    end function rank_c2f

    integer function tag_f2c(tag) result(c_tag)
        use mpi_c_bindings, only: c_mpi_any_tag
        integer, intent(in) :: tag
        if (tag == MPI_ANY_TAG) then
            c_tag = c_mpi_any_tag
        else
            c_tag = tag
        end if
    end function tag_f2c

    integer function thread_level_f2c(level) result(c_level)
        use mpi_c_bindings, only: c_mpi_thread_single, c_mpi_thread_funneled, &
            c_mpi_thread_serialized, c_mpi_thread_multiple
        integer, intent(in) :: level
        select case (level)
        case (MPI_THREAD_SINGLE)
            c_level = c_mpi_thread_single
        case (MPI_THREAD_FUNNELED)
            c_level = c_mpi_thread_funneled
        case (MPI_THREAD_SERIALIZED)
            c_level = c_mpi_thread_serialized
        case (MPI_THREAD_MULTIPLE)
            c_level = c_mpi_thread_multiple
        case default
            c_level = level
        end select
    end function thread_level_f2c

    integer function thread_level_c2f(c_level) result(level)
        use mpi_c_bindings, only: c_mpi_thread_single, c_mpi_thread_funneled, &
            c_mpi_thread_serialized, c_mpi_thread_multiple
        integer, intent(in) :: c_level
        if (c_level == c_mpi_thread_single) then
            level = MPI_THREAD_SINGLE
        else if (c_level == c_mpi_thread_funneled) then
            level = MPI_THREAD_FUNNELED
        else if (c_level == c_mpi_thread_serialized) then
            level = MPI_THREAD_SERIALIZED
        else if (c_level == c_mpi_thread_multiple) then
            level = MPI_THREAD_MULTIPLE
        else
            level = c_level
        end if
    end function thread_level_c2f

    integer function split_type_f2c(split_type) result(c_split_type)
        use mpi_c_bindings, only: c_mpi_comm_type_shared, c_mpi_undefined
        integer, intent(in) :: split_type
        if (split_type == MPI_COMM_TYPE_SHARED) then
            c_split_type = c_mpi_comm_type_shared
        else if (split_type == MPI_UNDEFINED) then
            c_split_type = c_mpi_undefined
        else
            c_split_type = split_type
        end if
    end function split_type_f2c

    logical function is_status_ignore(status)
        ! Whether the status argument is MPI_STATUS_IGNORE. The pointers are
        ! compared as variables, which works around an LFortran bug with
        ! c_associated(c_loc(a), c_loc(b)).
        integer, target :: status(MPI_STATUS_SIZE)
        type(c_ptr) :: p, ignore
        p = c_loc(status)
        ignore = c_loc(MPI_STATUS_IGNORE)
        is_status_ignore = c_associated(p, ignore)
    end function is_status_ignore

    logical function is_statuses_ignore(statuses)
        integer, target :: statuses(MPI_STATUS_SIZE, *)
        type(c_ptr) :: p, ignore
        p = c_loc(statuses)
        ignore = c_loc(MPI_STATUSES_IGNORE)
        is_statuses_ignore = c_associated(p, ignore)
    end function is_statuses_ignore

    subroutine status_c2f(c_status, status)
        ! Converts a native MPI_Status, viewed as an array of C ints, to the
        ! ABI layout: MPI_SOURCE, MPI_TAG, MPI_ERROR, then the remaining
        ! native integers in order.
        use mpi_c_bindings, only: c_sizeof_mpi_status, c_offsetof_mpi_source, &
            c_offsetof_mpi_tag, c_offsetof_mpi_error
        integer(c_int), intent(in) :: c_status(*)
        integer, intent(out) :: status(MPI_STATUS_SIZE)
        integer :: i, j, i_source, i_tag, i_error

        i_source = c_offsetof_mpi_source/4 + 1
        i_tag = c_offsetof_mpi_tag/4 + 1
        i_error = c_offsetof_mpi_error/4 + 1
        status = 0
        status(MPI_SOURCE) = rank_c2f(c_status(i_source))
        status(MPI_TAG) = c_status(i_tag)
        status(MPI_ERROR) = c_status(i_error)
        j = MPI_ERROR + 1
        do i = 1, c_sizeof_mpi_status/4
            if (i /= i_source .and. i /= i_tag .and. i /= i_error) then
                status(j) = c_status(i)
                j = j + 1
            end if
        end do
    end subroutine status_c2f

    subroutine c_string_to_fortran(c_name, resultlen, name)
        character(kind=c_char), intent(in) :: c_name(*)
        integer, intent(in) :: resultlen
        character(len=*), intent(out) :: name
        integer :: i
        name = ""
        do i = 1, min(resultlen, len(name))
            name(i:i) = c_name(i)
        end do
    end subroutine c_string_to_fortran

    subroutine set_ierror(c_ierror, name, ierror)
        ! Returns the error code in ierror if it is present, and prints it
        ! otherwise.
        integer(c_int), intent(in) :: c_ierror
        character(len=*), intent(in) :: name
        integer, optional, intent(out) :: ierror
        if (present(ierror)) then
            ierror = c_ierror
        else if (c_ierror /= MPI_SUCCESS) then
            print *, name, " failed with error code: ", c_ierror
        end if
    end subroutine set_ierror

    ! The MPI routines. Each routine that takes a buffer has one core
    ! (*_core), which takes the buffers as C pointers and does all the
    ! translation of handles, ranks, tags and statuses. The specific
    ! procedures for each type and rank of the buffers only pass c_loc of
    ! their buffers to it.

    subroutine MPI_Init_proc(ierr)
        use mpi_c_bindings, only: c_mpi_init
        integer, optional, intent(out) :: ierr
        integer(c_int) :: argc
        type(c_ptr) :: argv
        call check_native_mpi()
        argc = 0
        argv = c_null_ptr
        call set_ierror(c_mpi_init(argc, argv), "MPI_Init", ierr)
    end subroutine MPI_Init_proc

    subroutine MPI_Init_thread_proc(required, provided, ierr)
        use mpi_c_bindings, only: c_mpi_init_thread
        integer, intent(in) :: required
        integer, intent(out) :: provided
        integer, optional, intent(out) :: ierr
        integer(c_int) :: argc, c_provided, local_ierr
        type(c_ptr) :: argv
        call check_native_mpi()
        argc = 0
        argv = c_null_ptr
        local_ierr = c_mpi_init_thread(argc, argv, thread_level_f2c(required), c_provided)
        provided = thread_level_c2f(c_provided)
        call set_ierror(local_ierr, "MPI_Init_thread", ierr)
    end subroutine MPI_Init_thread_proc

    subroutine MPI_Initialized_proc(flag, ierr)
        use mpi_c_bindings, only: c_mpi_initialized
        logical, intent(out) :: flag
        integer, optional, intent(out) :: ierr
        integer(c_int) :: c_flag, local_ierr
        local_ierr = c_mpi_initialized(c_flag)
        flag = (c_flag /= 0)
        call set_ierror(local_ierr, "MPI_Initialized", ierr)
    end subroutine MPI_Initialized_proc

    subroutine MPI_Finalize_proc(ierr)
        use mpi_c_bindings, only: c_mpi_finalize
        integer, optional, intent(out) :: ierr
        call set_ierror(c_mpi_finalize(), "MPI_Finalize", ierr)
    end subroutine MPI_Finalize_proc

    function MPI_Wtime_proc() result(time)
        use mpi_c_bindings, only: c_mpi_wtime
        real(8) :: time
        time = c_mpi_wtime()
    end function MPI_Wtime_proc

    ! Communicators and groups

    subroutine MPI_Comm_size_proc(comm, size, ierror)
        use mpi_c_bindings, only: c_mpi_comm_size
        integer, intent(in) :: comm
        integer, intent(out) :: size
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_comm_size(comm_f2c(comm), size), "MPI_Comm_size", ierror)
    end subroutine MPI_Comm_size_proc

    subroutine MPI_Comm_rank_proc(comm, rank, ierror)
        use mpi_c_bindings, only: c_mpi_comm_rank
        integer, intent(in) :: comm
        integer, intent(out) :: rank
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_comm_rank(comm_f2c(comm), rank), "MPI_Comm_rank", ierror)
    end subroutine MPI_Comm_rank_proc

    subroutine MPI_Comm_Group_proc(comm, group, ierror)
        use mpi_c_bindings, only: c_mpi_comm_group
        integer, intent(in) :: comm
        integer, intent(out) :: group
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_group
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_comm_group(comm_f2c(comm), c_group)
        group = group_c2f(c_group)
        call set_ierror(local_ierr, "MPI_Comm_group", ierror)
    end subroutine MPI_Comm_Group_proc

    subroutine MPI_Group_size_proc(group, size, ierror)
        use mpi_c_bindings, only: c_mpi_group_size
        integer, intent(in) :: group
        integer, intent(out) :: size
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_group_size(group_f2c(group), size), "MPI_Group_size", ierror)
    end subroutine MPI_Group_size_proc

    subroutine MPI_Group_free_proc(group, ierror)
        use mpi_c_bindings, only: c_mpi_group_free
        integer, intent(inout) :: group
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_group
        integer(c_int) :: local_ierr
        c_group = group_f2c(group)
        local_ierr = c_mpi_group_free(c_group)
        group = group_c2f(c_group)
        call set_ierror(local_ierr, "MPI_Group_free", ierror)
    end subroutine MPI_Group_free_proc

    subroutine MPI_Group_range_incl_proc(group, n, ranks, newgroup, ierror)
        use mpi_c_bindings, only: c_mpi_group_range_incl
        integer, intent(in) :: group
        integer, intent(in) :: n
        integer, dimension(:,:), intent(in) :: ranks
        integer, intent(out) :: newgroup
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_newgroup
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_group_range_incl(group_f2c(group), n, ranks, c_newgroup)
        newgroup = group_c2f(c_newgroup)
        call set_ierror(local_ierr, "MPI_Group_range_incl", ierror)
    end subroutine MPI_Group_range_incl_proc

    subroutine MPI_Comm_create_proc(comm, group, newcomm, ierror)
        use mpi_c_bindings, only: c_mpi_comm_create
        integer, intent(in) :: comm
        integer, intent(in) :: group
        integer, intent(out) :: newcomm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_newcomm
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_comm_create(comm_f2c(comm), group_f2c(group), c_newcomm)
        newcomm = comm_c2f(c_newcomm)
        call set_ierror(local_ierr, "MPI_Comm_create", ierror)
    end subroutine MPI_Comm_create_proc

    subroutine MPI_Comm_dup_proc(comm, newcomm, ierror)
        use mpi_c_bindings, only: c_mpi_comm_dup
        integer, intent(in) :: comm
        integer, intent(out) :: newcomm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_newcomm
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_comm_dup(comm_f2c(comm), c_newcomm)
        newcomm = comm_c2f(c_newcomm)
        call set_ierror(local_ierr, "MPI_Comm_dup", ierror)
    end subroutine MPI_Comm_dup_proc

    subroutine MPI_Comm_free_proc(comm, ierror)
        use mpi_c_bindings, only: c_mpi_comm_free
        integer, intent(inout) :: comm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_comm
        integer(c_int) :: local_ierr
        c_comm = comm_f2c(comm)
        local_ierr = c_mpi_comm_free(c_comm)
        comm = comm_c2f(c_comm)
        call set_ierror(local_ierr, "MPI_Comm_free", ierror)
    end subroutine MPI_Comm_free_proc

    subroutine MPI_Comm_split_type_proc(comm, split_type, key, info, newcomm, ierror)
        use mpi_c_bindings, only: c_mpi_comm_split_type
        integer, intent(in) :: comm
        integer, intent(in) :: split_type, key
        integer, intent(in) :: info
        integer, intent(out) :: newcomm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_newcomm
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_comm_split_type(comm_f2c(comm), split_type_f2c(split_type), key, &
            info_f2c(info), c_newcomm)
        newcomm = comm_c2f(c_newcomm)
        call set_ierror(local_ierr, "MPI_Comm_split_type", ierror)
    end subroutine MPI_Comm_split_type_proc

    subroutine MPI_Comm_get_name_proc(comm, comm_name, resultlen, ierror)
        use mpi_c_bindings, only: c_mpi_comm_get_name
        integer, intent(in) :: comm
        character(len=*), intent(out) :: comm_name
        integer, intent(out) :: resultlen
        integer, optional, intent(out) :: ierror
        character(kind=c_char) :: c_name(MPI_MAX_OBJECT_NAME)
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_comm_get_name(comm_f2c(comm), c_name, resultlen)
        call c_string_to_fortran(c_name, resultlen, comm_name)
        call set_ierror(local_ierr, "MPI_Comm_get_name", ierror)
    end subroutine MPI_Comm_get_name_proc

    subroutine MPI_Type_get_name_proc(datatype, type_name, resultlen, ierror)
        use mpi_c_bindings, only: c_mpi_type_get_name
        integer, intent(in) :: datatype
        character(len=*), intent(out) :: type_name
        integer, intent(out) :: resultlen
        integer, optional, intent(out) :: ierror
        character(kind=c_char) :: c_name(MPI_MAX_OBJECT_NAME)
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_type_get_name(datatype_f2c(datatype), c_name, resultlen)
        call c_string_to_fortran(c_name, resultlen, type_name)
        call set_ierror(local_ierr, "MPI_Type_get_name", ierror)
    end subroutine MPI_Type_get_name_proc

    ! Topologies

    subroutine MPI_Cart_create_proc(comm_old, ndims, dims, periods, reorder, comm_cart, ierror)
        use mpi_c_bindings, only: c_mpi_cart_create
        integer, intent(in) :: ndims, dims(ndims)
        logical, intent(in) :: periods(ndims), reorder
        integer, intent(in) :: comm_old
        integer, intent(out) :: comm_cart
        integer, optional, intent(out) :: ierror
        integer(c_int) :: reorder_c, periods_c(ndims), local_ierr
        integer(kind=MPI_HANDLE_KIND) :: c_comm_cart
        reorder_c = merge(1, 0, reorder)
        periods_c = merge(1, 0, periods)
        local_ierr = c_mpi_cart_create(comm_f2c(comm_old), ndims, dims, periods_c, reorder_c, &
            c_comm_cart)
        comm_cart = comm_c2f(c_comm_cart)
        call set_ierror(local_ierr, "MPI_Cart_create", ierror)
    end subroutine MPI_Cart_create_proc

    subroutine MPI_Cart_coords_proc(comm, rank, maxdims, coords, ierror)
        use mpi_c_bindings, only: c_mpi_cart_coords
        integer, intent(in) :: comm
        integer, intent(in) :: rank, maxdims
        integer, intent(out) :: coords(maxdims)
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_cart_coords(comm_f2c(comm), rank, maxdims, coords), &
            "MPI_Cart_coords", ierror)
    end subroutine MPI_Cart_coords_proc

    subroutine MPI_Cart_shift_proc(comm, direction, disp, rank_source, rank_dest, ierror)
        use mpi_c_bindings, only: c_mpi_cart_shift
        integer, intent(in) :: comm
        integer, intent(in) :: direction, disp
        integer, intent(out) :: rank_source, rank_dest
        integer, optional, intent(out) :: ierror
        integer(c_int) :: c_rank_source, c_rank_dest, local_ierr
        local_ierr = c_mpi_cart_shift(comm_f2c(comm), direction, disp, c_rank_source, c_rank_dest)
        rank_source = rank_c2f(c_rank_source)
        rank_dest = rank_c2f(c_rank_dest)
        call set_ierror(local_ierr, "MPI_Cart_shift", ierror)
    end subroutine MPI_Cart_shift_proc

    subroutine MPI_Dims_create_proc(nnodes, ndims, dims, ierror)
        use mpi_c_bindings, only: c_mpi_dims_create
        integer, intent(in) :: nnodes, ndims
        integer, intent(out) :: dims(ndims)
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_dims_create(nnodes, ndims, dims), "MPI_Dims_create", ierror)
    end subroutine MPI_Dims_create_proc

    subroutine MPI_Cart_sub_proc(comm, remain_dims, newcomm, ierror)
        use mpi_c_bindings, only: c_mpi_cart_sub
        integer, intent(in) :: comm
        logical, intent(in) :: remain_dims(:)
        integer, intent(out) :: newcomm
        integer, optional, intent(out) :: ierror
        integer(c_int), target :: remain_dims_c(size(remain_dims))
        integer(kind=MPI_HANDLE_KIND) :: c_newcomm
        integer(c_int) :: local_ierr
        remain_dims_c = merge(1, 0, remain_dims)
        local_ierr = c_mpi_cart_sub(comm_f2c(comm), c_loc(remain_dims_c), c_newcomm)
        newcomm = comm_c2f(c_newcomm)
        call set_ierror(local_ierr, "MPI_Cart_sub", ierror)
    end subroutine MPI_Cart_sub_proc

    ! Synchronization and completion

    subroutine MPI_Barrier_proc(comm, ierror)
        use mpi_c_bindings, only: c_mpi_barrier
        integer, intent(in) :: comm
        integer, intent(out), optional :: ierror
        call set_ierror(c_mpi_barrier(comm_f2c(comm)), "MPI_Barrier", ierror)
    end subroutine MPI_Barrier_proc

    subroutine MPI_Wait_proc(request, status, ierror)
        use mpi_c_bindings, only: c_mpi_wait, c_mpi_status_ignore
        integer, intent(inout) :: request
        integer, target, intent(out) :: status(MPI_STATUS_SIZE)
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_request
        integer(c_int), target :: c_status(MPI_STATUS_SIZE)
        integer(c_int) :: local_ierr
        c_request = request_f2c(request)
        if (is_status_ignore(status)) then
            local_ierr = c_mpi_wait(c_request, c_mpi_status_ignore)
        else
            local_ierr = c_mpi_wait(c_request, c_loc(c_status))
            if (local_ierr == MPI_SUCCESS) call status_c2f(c_status, status)
        end if
        request = request_c2f(c_request)
        call set_ierror(local_ierr, "MPI_Wait", ierror)
    end subroutine MPI_Wait_proc

    subroutine MPI_Waitall_proc(count, array_of_requests, array_of_statuses, ierror)
        use mpi_c_bindings, only: c_mpi_waitall, c_mpi_statuses_ignore, c_sizeof_mpi_status
        integer, intent(in) :: count
        integer, dimension(count), intent(inout) :: array_of_requests
        integer, target, intent(out) :: array_of_statuses(MPI_STATUS_SIZE, *)
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_requests(count)
        ! The native statuses, as C ints; each has c_sizeof_mpi_status bytes
        integer(c_int), allocatable, target :: c_statuses(:)
        integer(c_int) :: local_ierr
        integer :: i, n
        do i = 1, count
            c_requests(i) = request_f2c(array_of_requests(i))
        end do
        if (is_statuses_ignore(array_of_statuses)) then
            local_ierr = c_mpi_waitall(count, c_requests, c_mpi_statuses_ignore)
        else
            n = c_sizeof_mpi_status/4
            allocate(c_statuses(n*max(count, 1)))
            local_ierr = c_mpi_waitall(count, c_requests, c_loc(c_statuses))
            if (local_ierr == MPI_SUCCESS) then
                do i = 1, count
                    call status_c2f(c_statuses((i-1)*n+1:i*n), array_of_statuses(:, i))
                end do
            end if
        end if
        do i = 1, count
            array_of_requests(i) = request_c2f(c_requests(i))
        end do
        call set_ierror(local_ierr, "MPI_Waitall", ierror)
    end subroutine MPI_Waitall_proc

    ! Point-to-point

    subroutine ssend_core(buf, count, datatype, dest, tag, comm, ierror)
        use mpi_c_bindings, only: c_mpi_ssend
        type(c_ptr), intent(in) :: buf
        integer, intent(in) :: count, datatype, dest, tag, comm
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_ssend(buf, count, datatype_f2c(datatype), rank_f2c(dest), &
            tag_f2c(tag), comm_f2c(comm)), "MPI_Ssend", ierror)
    end subroutine ssend_core

    subroutine recv_core(buf, count, datatype, source, tag, comm, status, ierror)
        use mpi_c_bindings, only: c_mpi_recv, c_mpi_status_ignore
        type(c_ptr), intent(in) :: buf
        integer, intent(in) :: count, datatype, source, tag, comm
        integer, target, intent(out) :: status(MPI_STATUS_SIZE)
        integer, optional, intent(out) :: ierror
        integer(c_int), target :: c_status(MPI_STATUS_SIZE)
        integer(c_int) :: local_ierr
        if (is_status_ignore(status)) then
            local_ierr = c_mpi_recv(buf, count, datatype_f2c(datatype), rank_f2c(source), &
                tag_f2c(tag), comm_f2c(comm), c_mpi_status_ignore)
        else
            local_ierr = c_mpi_recv(buf, count, datatype_f2c(datatype), rank_f2c(source), &
                tag_f2c(tag), comm_f2c(comm), c_loc(c_status))
            if (local_ierr == MPI_SUCCESS) call status_c2f(c_status, status)
        end if
        call set_ierror(local_ierr, "MPI_Recv", ierror)
    end subroutine recv_core

    subroutine isend_core(buf, count, datatype, dest, tag, comm, request, ierror)
        use mpi_c_bindings, only: c_mpi_isend
        type(c_ptr), intent(in) :: buf
        integer, intent(in) :: count, datatype, dest, tag, comm
        integer, intent(out) :: request
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_request
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_isend(buf, count, datatype_f2c(datatype), rank_f2c(dest), &
            tag_f2c(tag), comm_f2c(comm), c_request)
        request = request_c2f(c_request)
        call set_ierror(local_ierr, "MPI_Isend", ierror)
    end subroutine isend_core

    subroutine irecv_core(buf, count, datatype, source, tag, comm, request, ierror)
        use mpi_c_bindings, only: c_mpi_irecv
        type(c_ptr), intent(in) :: buf
        integer, intent(in) :: count, datatype, source, tag, comm
        integer, intent(out) :: request
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_request
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_irecv(buf, count, datatype_f2c(datatype), rank_f2c(source), &
            tag_f2c(tag), comm_f2c(comm), c_request)
        request = request_c2f(c_request)
        call set_ierror(local_ierr, "MPI_Irecv", ierror)
    end subroutine irecv_core

    subroutine sendrecv_core(sendbuf, sendcount, sendtype, dest, sendtag, &
            recvbuf, recvcount, recvtype, source, recvtag, comm, status, ierror)
        use mpi_c_bindings, only: c_mpi_sendrecv, c_mpi_status_ignore
        type(c_ptr), intent(in) :: sendbuf, recvbuf
        integer, intent(in) :: sendcount, sendtype, dest, sendtag
        integer, intent(in) :: recvcount, recvtype, source, recvtag, comm
        integer, target, intent(out) :: status(MPI_STATUS_SIZE)
        integer, optional, intent(out) :: ierror
        integer(c_int), target :: c_status(MPI_STATUS_SIZE)
        type(c_ptr) :: c_status_ptr
        integer(c_int) :: local_ierr
        if (is_status_ignore(status)) then
            c_status_ptr = c_mpi_status_ignore
        else
            c_status_ptr = c_loc(c_status)
        end if
        local_ierr = c_mpi_sendrecv(sendbuf, sendcount, datatype_f2c(sendtype), &
            rank_f2c(dest), tag_f2c(sendtag), recvbuf, recvcount, datatype_f2c(recvtype), &
            rank_f2c(source), tag_f2c(recvtag), comm_f2c(comm), c_status_ptr)
        if (local_ierr == MPI_SUCCESS .and. .not. is_status_ignore(status)) then
            call status_c2f(c_status, status)
        end if
        call set_ierror(local_ierr, "MPI_Sendrecv", ierror)
    end subroutine sendrecv_core

    subroutine MPI_Ssend_proc(buf, count, datatype, dest, tag, comm, ierror)
        real(8), dimension(*), intent(in), target :: buf
        integer, intent(in) :: count, dest, tag
        integer, intent(in) :: datatype
        integer, intent(in) :: comm
        integer, optional, intent(out) :: ierror
        call ssend_core(c_loc(buf), count, datatype, dest, tag, comm, ierror)
    end subroutine MPI_Ssend_proc

    subroutine MPI_Recv_StatusArray_proc(buf, count, datatype, source, tag, comm, status, ierror)
        real(8), dimension(*), intent(inout), target :: buf
        integer, intent(in)  :: count, source, tag, datatype, comm
        integer, target, intent(out) :: status(MPI_STATUS_SIZE)
        integer, optional, intent(out) :: ierror
        call recv_core(c_loc(buf), count, datatype, source, tag, comm, status, ierror)
    end subroutine MPI_Recv_StatusArray_proc

    subroutine MPI_Isend_2d(buf, count, datatype, dest, tag, comm, request, ierror)
        real(8), dimension(:, :), intent(in), target :: buf
        integer, intent(in) :: count, dest, tag
        integer, intent(in) :: datatype
        integer, intent(in) :: comm
        integer, intent(out) :: request
        integer, optional, intent(out) :: ierror
        call isend_core(c_loc(buf), count, datatype, dest, tag, comm, request, ierror)
    end subroutine MPI_Isend_2d

    subroutine MPI_Isend_3d(buf, count, datatype, dest, tag, comm, request, ierror)
        real(8), dimension(:, :, :), intent(in), target :: buf
        integer, intent(in) :: count, dest, tag
        integer, intent(in) :: datatype
        integer, intent(in) :: comm
        integer, intent(out) :: request
        integer, optional, intent(out) :: ierror
        call isend_core(c_loc(buf), count, datatype, dest, tag, comm, request, ierror)
    end subroutine MPI_Isend_3d

    subroutine MPI_Irecv_proc(buf, count, datatype, source, tag, comm, request, ierror)
        real(8), dimension(:,:), target :: buf
        integer, intent(in) :: count, source, tag
        integer, intent(in) :: datatype
        integer, intent(in) :: comm
        integer, intent(out) :: request
        integer, optional, intent(out) :: ierror
        call irecv_core(c_loc(buf), count, datatype, source, tag, comm, request, ierror)
    end subroutine MPI_Irecv_proc

    subroutine MPI_Sendrecv_proc(sendbuf, sendcount, sendtype, dest, sendtag, &
            recvbuf, recvcount, recvtype, source, recvtag, comm, status, ierror)
        real(8), dimension(:,:), target, intent(in) :: sendbuf
        integer, intent(in) :: sendcount, dest, sendtag
        real(8), dimension(:,:), target, intent(out) :: recvbuf
        integer, intent(in) :: recvcount, source, recvtag
        integer, intent(in) :: comm
        integer, intent(in) :: sendtype, recvtype
        integer, target, intent(out) :: status(MPI_STATUS_SIZE)
        integer, optional, intent(out) :: ierror
        call sendrecv_core(c_loc(sendbuf), sendcount, sendtype, dest, sendtag, &
            c_loc(recvbuf), recvcount, recvtype, source, recvtag, comm, status, ierror)
    end subroutine MPI_Sendrecv_proc

    ! Collectives

    subroutine bcast_core(buffer, count, datatype, root, comm, ierror)
        use mpi_c_bindings, only: c_mpi_bcast
        type(c_ptr), intent(in) :: buffer
        integer, intent(in) :: count, datatype, root, comm
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_bcast(buffer, count, datatype_f2c(datatype), rank_f2c(root), &
            comm_f2c(comm)), "MPI_Bcast", ierror)
    end subroutine bcast_core

    subroutine reduce_core(sendbuf, recvbuf, count, datatype, op, root, comm, ierror)
        use mpi_c_bindings, only: c_mpi_reduce
        type(c_ptr), intent(in) :: sendbuf, recvbuf
        integer, intent(in) :: count, datatype, op, root, comm
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_reduce(sendbuf, recvbuf, count, datatype_f2c(datatype), &
            op_f2c(op), rank_f2c(root), comm_f2c(comm)), "MPI_Reduce", ierror)
    end subroutine reduce_core

    subroutine allreduce_core(sendbuf, recvbuf, count, datatype, op, comm, ierror)
        use mpi_c_bindings, only: c_mpi_allreduce
        type(c_ptr), intent(in) :: sendbuf, recvbuf
        integer, intent(in) :: count, datatype, op, comm
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_allreduce(sendbuf, recvbuf, count, datatype_f2c(datatype), &
            op_f2c(op), comm_f2c(comm)), "MPI_Allreduce", ierror)
    end subroutine allreduce_core

    subroutine exscan_core(sendbuf, recvbuf, count, datatype, op, comm, ierror)
        use mpi_c_bindings, only: c_mpi_exscan
        type(c_ptr), intent(in) :: sendbuf, recvbuf
        integer, intent(in) :: count, datatype, op, comm
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_exscan(sendbuf, recvbuf, count, datatype_f2c(datatype), &
            op_f2c(op), comm_f2c(comm)), "MPI_Exscan", ierror)
    end subroutine exscan_core

    subroutine allgather_core(sendbuf, sendcount, sendtype, recvbuf, recvcount, recvtype, &
            comm, ierror)
        use mpi_c_bindings, only: c_mpi_allgather
        type(c_ptr), intent(in) :: sendbuf, recvbuf
        integer, intent(in) :: sendcount, sendtype, recvcount, recvtype, comm
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_allgather(sendbuf, sendcount, datatype_f2c(sendtype), &
            recvbuf, recvcount, datatype_f2c(recvtype), comm_f2c(comm)), &
            "MPI_Allgather", ierror)
    end subroutine allgather_core

    subroutine gatherv_core(sendbuf, sendcount, sendtype, recvbuf, recvcounts, displs, &
            recvtype, root, comm, ierror)
        use mpi_c_bindings, only: c_mpi_gatherv
        type(c_ptr), intent(in) :: sendbuf, recvbuf
        integer, intent(in) :: sendcount, sendtype, recvtype, root, comm
        integer, intent(in) :: recvcounts(:), displs(:)
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_gatherv(sendbuf, sendcount, datatype_f2c(sendtype), &
            recvbuf, recvcounts, displs, datatype_f2c(recvtype), rank_f2c(root), &
            comm_f2c(comm)), "MPI_Gatherv", ierror)
    end subroutine gatherv_core

    subroutine allgatherv_core(sendbuf, sendcount, sendtype, recvbuf, recvcounts, displs, &
            recvtype, comm, ierror)
        use mpi_c_bindings, only: c_mpi_allgatherv
        type(c_ptr), intent(in) :: sendbuf, recvbuf
        integer, intent(in) :: sendcount, sendtype, recvtype, comm
        integer, intent(in) :: recvcounts(:), displs(:)
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_allgatherv(sendbuf, sendcount, datatype_f2c(sendtype), &
            recvbuf, recvcounts, displs, datatype_f2c(recvtype), comm_f2c(comm)), &
            "MPI_Allgatherv", ierror)
    end subroutine allgatherv_core

    subroutine scatter_core(sendbuf, sendcount, sendtype, recvbuf, recvcount, recvtype, &
            root, comm, ierror)
        use mpi_c_bindings, only: c_mpi_scatter
        type(c_ptr), intent(in) :: sendbuf, recvbuf
        integer, intent(in) :: sendcount, sendtype, recvcount, recvtype, root, comm
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_scatter(sendbuf, sendcount, datatype_f2c(sendtype), &
            recvbuf, recvcount, datatype_f2c(recvtype), rank_f2c(root), comm_f2c(comm)), &
            "MPI_Scatter", ierror)
    end subroutine scatter_core

    subroutine MPI_Bcast_int_scalar(buffer, count, datatype, root, comm, ierror)
        integer, target :: buffer
        integer, intent(in) :: count, root
        integer, intent(in) :: datatype
        integer, intent(in) :: comm
        integer, optional, intent(out) :: ierror
        call bcast_core(c_loc(buffer), count, datatype, root, comm, ierror)
    end subroutine MPI_Bcast_int_scalar

    subroutine MPI_Bcast_real_2D(buffer, count, datatype, root, comm, ierror)
        real(8), dimension(:, :), target :: buffer
        integer, intent(in) :: count, root
        integer, intent(in) :: datatype
        integer, intent(in) :: comm
        integer, optional, intent(out) :: ierror
        call bcast_core(c_loc(buffer), count, datatype, root, comm, ierror)
    end subroutine MPI_Bcast_real_2D

    subroutine MPI_Reduce_scalar_int(sendbuf, recvbuf, count, datatype, op, root, comm, ierror)
        integer, target, intent(in)  :: sendbuf
        integer, target, intent(out) :: recvbuf
        integer, intent(in)  :: count, datatype, op, root, comm
        integer, optional, intent(out) :: ierror
        call reduce_core(c_loc(sendbuf), c_loc(recvbuf), count, datatype, op, root, comm, ierror)
    end subroutine MPI_Reduce_scalar_int

    subroutine MPI_Allreduce_scalar(sendbuf, recvbuf, count, datatype, op, comm, ierror)
        real(8), intent(in), target :: sendbuf
        real(8), intent(out), target :: recvbuf
        integer, intent(in) :: count, datatype, op, comm
        integer, intent(out), optional :: ierror
        call allreduce_core(c_loc(sendbuf), c_loc(recvbuf), count, datatype, op, comm, ierror)
    end subroutine MPI_Allreduce_scalar

    subroutine MPI_Allreduce_in_place_real8_scalar(sendbuf, recvbuf, count, datatype, op, &
            comm, ierror)
        use mpi_c_bindings, only: c_mpi_in_place
        type(mpi_in_place_type), intent(in) :: sendbuf
        real(8), intent(inout), target :: recvbuf
        integer, intent(in) :: count, datatype, op, comm
        integer, intent(out), optional :: ierror
        call allreduce_core(c_mpi_in_place, c_loc(recvbuf), count, datatype, op, comm, ierror)
    end subroutine MPI_Allreduce_in_place_real8_scalar

    subroutine MPI_Allreduce_in_place_real8_1D(sendbuf, recvbuf, count, datatype, op, &
            comm, ierror)
        use mpi_c_bindings, only: c_mpi_in_place
        type(mpi_in_place_type), intent(in) :: sendbuf
        real(8), dimension(:), intent(inout), target :: recvbuf
        integer, intent(in) :: count, datatype, op, comm
        integer, intent(out), optional :: ierror
        call allreduce_core(c_mpi_in_place, c_loc(recvbuf), count, datatype, op, comm, ierror)
    end subroutine MPI_Allreduce_in_place_real8_1D

    subroutine MPI_Allreduce_1D_real_proc(sendbuf, recvbuf, count, datatype, op, comm, ierror)
        real(8), dimension(:), intent(in), target :: sendbuf
        real(8), dimension(:), intent(out), target :: recvbuf
        integer, intent(in) :: count, datatype, op, comm
        integer, intent(out), optional :: ierror
        call allreduce_core(c_loc(sendbuf), c_loc(recvbuf), count, datatype, op, comm, ierror)
    end subroutine MPI_Allreduce_1D_real_proc

    subroutine MPI_Allreduce_1D_int_proc(sendbuf, recvbuf, count, datatype, op, comm, ierror)
        integer, dimension(:), intent(in), target :: sendbuf
        integer, dimension(:), intent(out), target :: recvbuf
        integer, intent(in) :: count, datatype, op, comm
        integer, intent(out), optional :: ierror
        call allreduce_core(c_loc(sendbuf), c_loc(recvbuf), count, datatype, op, comm, ierror)
    end subroutine MPI_Allreduce_1D_int_proc

    subroutine MPI_Allreduce_scalar_logical_proc(sendbuf, recvbuf, count, datatype, op, comm, ierror)
        logical, intent(in), target :: sendbuf
        logical, intent(out), target :: recvbuf
        integer, intent(in) :: count, datatype, op, comm
        integer, intent(out), optional :: ierror
        call allreduce_core(c_loc(sendbuf), c_loc(recvbuf), count, datatype, op, comm, ierror)
    end subroutine MPI_Allreduce_scalar_logical_proc

    subroutine MPI_Exscan_scalar_int(sendbuf, recvbuf, count, datatype, op, comm, ierror)
        integer, target, intent(in)  :: sendbuf
        integer, target, intent(out) :: recvbuf
        integer, intent(in)  :: count, datatype, op, comm
        integer, optional, intent(out) :: ierror
        call exscan_core(c_loc(sendbuf), c_loc(recvbuf), count, datatype, op, comm, ierror)
    end subroutine MPI_Exscan_scalar_int

    subroutine MPI_Allgather_int(sendbuf, sendcount, sendtype, recvbuf, recvcount, recvtype, comm, ierror)
        integer, dimension(:), intent(in), target :: sendbuf
        integer, dimension(:, :), intent(out), target :: recvbuf
        integer, intent(in) :: sendcount, recvcount
        integer, intent(in) :: sendtype, recvtype
        integer, intent(in) :: comm
        integer, optional, intent(out) :: ierror
        call allgather_core(c_loc(sendbuf), sendcount, sendtype, c_loc(recvbuf), recvcount, &
            recvtype, comm, ierror)
    end subroutine MPI_Allgather_int

    subroutine MPI_Allgather_real(sendbuf, sendcount, sendtype, recvbuf, recvcount, recvtype, comm, ierror)
        real(8), dimension(:), intent(in), target :: sendbuf
        real(8), dimension(:, :), intent(out), target :: recvbuf
        integer, intent(in) :: sendcount, recvcount
        integer, intent(in) :: sendtype, recvtype
        integer, intent(in) :: comm
        integer, optional, intent(out) :: ierror
        call allgather_core(c_loc(sendbuf), sendcount, sendtype, c_loc(recvbuf), recvcount, &
            recvtype, comm, ierror)
    end subroutine MPI_Allgather_real

    subroutine MPI_Gatherv_int(sendbuf, sendcount, sendtype, recvbuf, recvcounts, &
            displs, recvtype, root, comm, ierror)
        integer, dimension(:), intent(in), target :: sendbuf
        integer, intent(in) :: sendcount
        integer, intent(in) :: sendtype
        integer, dimension(:), intent(out), target :: recvbuf
        integer, dimension(:), intent(in) :: recvcounts
        integer, dimension(:), intent(in) :: displs
        integer, intent(in) :: recvtype
        integer, intent(in) :: root
        integer, intent(in) :: comm
        integer, optional, intent(out) :: ierror
        call gatherv_core(c_loc(sendbuf), sendcount, &
            sendtype, c_loc(recvbuf), recvcounts, displs, recvtype, root, comm, ierror)
    end subroutine MPI_Gatherv_int

    subroutine MPI_Gatherv_real(sendbuf, sendcount, sendtype, recvbuf, recvcounts, &
            displs, recvtype, root, comm, ierror)
        real(8), dimension(:), intent(in), target :: sendbuf
        integer, intent(in) :: sendcount
        integer, intent(in) :: sendtype
        real(8), dimension(:), intent(out), target :: recvbuf
        integer, dimension(:), intent(in) :: recvcounts
        integer, dimension(:), intent(in) :: displs
        integer, intent(in) :: recvtype
        integer, intent(in) :: root
        integer, intent(in) :: comm
        integer, optional, intent(out) :: ierror
        call gatherv_core(c_loc(sendbuf), sendcount, &
            sendtype, c_loc(recvbuf), recvcounts, displs, recvtype, root, comm, ierror)
    end subroutine MPI_Gatherv_real

    subroutine MPI_Gatherv_character(sendbuf, sendcount, sendtype, recvbuf, recvcounts, &
            displs, recvtype, root, comm, ierror)
        character(len=*), intent(in), target :: sendbuf(*)
        integer, intent(in) :: sendcount
        integer, intent(in) :: sendtype
        character(len=*), intent(out), target :: recvbuf(*)
        integer, dimension(:), intent(in) :: recvcounts
        integer, dimension(:), intent(in) :: displs
        integer, intent(in) :: recvtype
        integer, intent(in) :: root
        integer, intent(in) :: comm
        integer, optional, intent(out) :: ierror
        call gatherv_core(c_loc(sendbuf), sendcount, sendtype, c_loc(recvbuf), recvcounts, &
            displs, recvtype, root, comm, ierror)
    end subroutine MPI_Gatherv_character

    subroutine MPI_Allgatherv_int(sendbuf, sendcount, sendtype, recvbuf, recvcounts, &
            displs, recvtype, comm, ierror)
        integer, dimension(:), intent(in), target :: sendbuf
        integer, intent(in) :: sendcount
        integer, intent(in) :: sendtype
        integer, dimension(:), intent(out), target :: recvbuf
        integer, dimension(:), intent(in) :: recvcounts
        integer, dimension(:), intent(in) :: displs
        integer, intent(in) :: recvtype
        integer, intent(in) :: comm
        integer, optional, intent(out) :: ierror
        call allgatherv_core(c_loc(sendbuf), &
            sendcount, sendtype, c_loc(recvbuf), recvcounts, displs, recvtype, comm, ierror)
    end subroutine MPI_Allgatherv_int

    subroutine MPI_Allgatherv_real(sendbuf, sendcount, sendtype, recvbuf, recvcounts, &
            displs, recvtype, comm, ierror)
        real(8), dimension(:), intent(in), target :: sendbuf
        integer, intent(in) :: sendcount
        integer, intent(in) :: sendtype
        real(8), dimension(:), intent(out), target :: recvbuf
        integer, dimension(:), intent(in) :: recvcounts
        integer, dimension(:), intent(in) :: displs
        integer, intent(in) :: recvtype
        integer, intent(in) :: comm
        integer, optional, intent(out) :: ierror
        call allgatherv_core(c_loc(sendbuf), &
            sendcount, sendtype, c_loc(recvbuf), recvcounts, displs, recvtype, comm, ierror)
    end subroutine MPI_Allgatherv_real

    subroutine MPI_Scatter_real(sendbuf, sendcount, sendtype, recvbuf, recvcount, &
            recvtype, root, comm, ierror)
        real(8), dimension(*), intent(in), target :: sendbuf
        integer, intent(in) :: sendcount
        integer, intent(in) :: sendtype
        real(8), dimension(*), intent(out), target :: recvbuf
        integer, intent(in) :: recvcount
        integer, intent(in) :: recvtype
        integer, intent(in) :: root
        integer, intent(in) :: comm
        integer, optional, intent(out) :: ierror
        call scatter_core(c_loc(sendbuf), sendcount, &
            sendtype, c_loc(recvbuf), recvcount, recvtype, root, comm, ierror)
    end subroutine MPI_Scatter_real

    ! Errors

    subroutine MPI_Comm_set_errhandler_proc(comm, errhandler, ierror)
        use mpi_c_bindings, only: c_mpi_comm_set_errhandler
        integer, intent(in) :: comm, errhandler
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_comm_set_errhandler(comm_f2c(comm), errhandler_f2c(errhandler)), &
            "MPI_Comm_set_errhandler", ierror)
    end subroutine MPI_Comm_set_errhandler_proc

    subroutine MPI_Error_class_proc(errorcode, errorclass, ierror)
        ! Error codes are native; their classes are translated.
        use mpi_c_bindings, only: c_mpi_error_class
        integer, intent(in) :: errorcode
        integer, intent(out) :: errorclass
        integer, optional, intent(out) :: ierror
        integer(c_int) :: c_class, local_ierr
        local_ierr = c_mpi_error_class(errorcode, c_class)
        errorclass = error_class_c2f(c_class)
        call set_ierror(local_ierr, "MPI_Error_class", ierror)
    end subroutine MPI_Error_class_proc

    subroutine MPI_Error_string_proc(errorcode, string, resultlen, ierror)
        use mpi_c_bindings, only: c_mpi_error_string
        integer, intent(in) :: errorcode
        character(len=*), intent(out) :: string
        integer, intent(out) :: resultlen
        integer, optional, intent(out) :: ierror
        character(kind=c_char) :: c_string(MPI_MAX_ERROR_STRING)
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_error_string(errorcode, c_string, resultlen)
        call c_string_to_fortran(c_string, resultlen, string)
        call set_ierror(local_ierr, "MPI_Error_string", ierror)
    end subroutine MPI_Error_string_proc

end module mpi
