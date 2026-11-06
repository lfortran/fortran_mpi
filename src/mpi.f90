module mpi
    use mpi_c_bindings, only: MPI_HANDLE_KIND
    implicit none

    ! Every constant has its MPI-5 ABI value (MPI 5.0, chapter 21; the values
    ! are from https://github.com/mpi-forum/mpi-abi-stubs, mpi.h). These are
    ! the same for all MPI implementations and platforms. The *_f2c and *_c2f
    ! functions below translate them to and from the values of the native
    ! MPI library, from src/mpi_constants.c. See doc/design.md.

    integer, parameter :: MPI_SUCCESS = 0

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

    ! TODO: these are values, not addresses, see doc/design.md
    real(8), parameter :: MPI_IN_PLACE = -1002
    integer :: MPI_STATUS_IGNORE = 0
    integer :: MPI_STATUSES_IGNORE(1024)

    private :: USER_HANDLE_OFFSET
    private :: check_native_mpi, user_handle_c2f
    private :: op_f2c, comm_f2c, comm_c2f, group_f2c, group_c2f, info_f2c
    private :: request_f2c, request_c2f, datatype_f2c
    private :: rank_f2c, rank_c2f, tag_f2c, thread_level_f2c, thread_level_c2f
    private :: split_type_f2c, status_c2f, c_string_to_fortran

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
        module procedure MPI_Allreduce_1D_recv_proc
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
        module procedure MPI_Recv_StatusIgnore_proc    
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
            c_mpi_max_object_name
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
    end subroutine check_native_mpi

    integer function user_handle_c2f(native) result(handle)
        use iso_c_binding, only: c_int
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

    subroutine status_c2f(c_status, status)
        ! Converts a native MPI_Status, viewed as an array of C ints, to the
        ! ABI layout: MPI_SOURCE, MPI_TAG, MPI_ERROR, then the remaining
        ! native integers in order.
        use iso_c_binding, only: c_int
        use mpi_c_bindings, only: c_sizeof_mpi_status, c_offsetof_mpi_source, &
            c_offsetof_mpi_tag, c_offsetof_mpi_error
        integer(c_int), intent(in) :: c_status(MPI_STATUS_SIZE)
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
        use iso_c_binding, only: c_char
        character(kind=c_char), intent(in) :: c_name(*)
        integer, intent(in) :: resultlen
        character(len=*), intent(out) :: name
        integer :: i
        name = ""
        do i = 1, min(resultlen, len(name))
            name(i:i) = c_name(i)
        end do
    end subroutine c_string_to_fortran

    subroutine MPI_Init_proc(ierr)
        use mpi_c_bindings, only: c_mpi_init
        use iso_c_binding, only : c_int, c_ptr, c_null_ptr
        integer, optional, intent(out) :: ierr
        integer(c_int) :: local_ierr
        integer(c_int) :: argc
        type(c_ptr) :: argv = c_null_ptr
        call check_native_mpi()
        argc = 0
        ! Call C MPI_Init directly with argc=0, argv=NULL
        local_ierr = c_mpi_init(argc, argv)

        if (present(ierr)) then
            ierr = int(local_ierr)
        else if (local_ierr /= 0) then
            print *, "MPI_Init failed with error code: ", local_ierr
        end if
    end subroutine MPI_Init_proc

    subroutine MPI_Init_thread_proc(required, provided, ierr)
        use mpi_c_bindings, only: c_mpi_init_thread
        use iso_c_binding, only: c_int, c_ptr, c_null_ptr
        integer, intent(in) :: required
        integer, intent(out) :: provided
        integer, optional, intent(out) :: ierr
        integer(c_int) :: local_ierr
        integer(c_int) :: argc
        type(c_ptr) :: argv = c_null_ptr
        integer(c_int) :: c_required
        integer(c_int) :: c_provided
        call check_native_mpi()
        argc = 0
        c_required = thread_level_f2c(required)
        local_ierr = c_mpi_init_thread(argc, argv, c_required, c_provided)
        provided = thread_level_c2f(c_provided)

        if (present(ierr)) then
            ierr = int(local_ierr)
        else if (local_ierr /= 0) then
            print *, "MPI_Init_thread failed with error code: ", local_ierr
        end if
    end subroutine MPI_Init_thread_proc

    subroutine MPI_Initialized_proc(flag, ierr)
        use mpi_c_bindings, only: c_mpi_initialized
        use iso_c_binding, only: c_int
        logical, intent(out) :: flag
        integer, optional, intent(out) :: ierr
        integer(c_int) :: c_flag
        integer(c_int) :: local_ierr

        local_ierr = c_mpi_initialized(c_flag)
        flag = (c_flag /= 0)

        if (present(ierr)) then
            ierr = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Initialized failed with error code: ", local_ierr
        end if
    end subroutine MPI_Initialized_proc

    subroutine MPI_Finalize_proc(ierr)
        use mpi_c_bindings, only: c_mpi_finalize
        use iso_c_binding, only: c_int
        integer, optional, intent(out) :: ierr
        integer(c_int) :: local_ierr

        !> assigns the status code to integer of kind 'c_int'
        local_ierr = c_mpi_finalize()
        if (present(ierr)) then
            !> we need to cast it to a Fortran integer, hence the use of 'int'
            ierr = int(local_ierr)
        else if (local_ierr /= 0) then
            print *, "MPI_Finalize failed with error code: ", int(local_ierr)
        end if
    end subroutine

    subroutine MPI_Comm_size_proc(comm, size, ierror)
        use mpi_c_bindings, only: c_mpi_comm_size
        use iso_c_binding, only: c_int, c_ptr
        integer, intent(in) :: comm
        integer, intent(out) :: size
        integer, optional, intent(out) :: ierror
        integer :: local_ierr
        integer(kind=MPI_HANDLE_KIND) :: c_comm

        c_comm = comm_f2c(comm)

        local_ierr = c_mpi_comm_size(c_comm, size)
        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Comm_size failed with error code: ", local_ierr
            end if
        end if
    end subroutine

    subroutine MPI_Comm_Group_proc(comm, group, ierror)
        use mpi_c_bindings, only: c_mpi_comm_group
        use iso_c_binding, only: c_int, c_ptr
        integer, intent(in) :: comm
        integer, intent(out) :: group
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_comm, c_group
        integer :: local_ierr

        c_comm = comm_f2c(comm)
        local_ierr = c_mpi_comm_group(c_comm, c_group)
        group = group_c2f(c_group)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= 0) then
                print *, "MPI_Comm_Group failed with error code: ", local_ierr
            end if
        end if
    end subroutine MPI_Comm_Group_proc

    subroutine MPI_Group_size_proc(group, size, ierror)
        use mpi_c_bindings, only: c_mpi_group_size
        use iso_c_binding, only: c_int, c_ptr
        integer, intent(in) :: group
        integer, intent(out) :: size
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_group
        integer :: local_ierr

        c_group = group_f2c(group)
        local_ierr = c_mpi_group_size(c_group, size)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= 0) then
                print *, "MPI_Group_size failed with error code: ", local_ierr
            end if
        end if
    end subroutine MPI_Group_size_proc

    subroutine MPI_Group_free_proc(group, ierror)
        use mpi_c_bindings, only: c_mpi_group_free
        use iso_c_binding, only: c_int, c_ptr
        integer, intent(inout) :: group
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_group
        integer :: local_ierr

        c_group = group_f2c(group)
        local_ierr = c_mpi_group_free(c_group)
        group = group_c2f(c_group)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= 0) then
                print *, "MPI_Group_free failed with error code: ", local_ierr
            end if
        end if
    end subroutine MPI_Group_free_proc

    subroutine MPI_Group_range_incl_proc(group, n, ranks, newgroup, ierror)
        use mpi_c_bindings, only: c_mpi_group_range_incl
        use iso_c_binding, only: c_int, c_ptr
        integer, intent(in) :: group
        integer, intent(in) :: n
        integer, dimension(:,:), intent(in) :: ranks
        integer, intent(out) :: newgroup
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_group, c_newgroup
        integer(c_int) :: local_ierr

        c_group = group_f2c(group)
        local_ierr = c_mpi_group_range_incl(c_group, n, ranks, c_newgroup)
        newgroup = group_c2f(c_newgroup)

        if (present(ierror)) then
            ierror = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Group_incl failed with error code: ", local_ierr
        end if
    end subroutine MPI_Group_range_incl_proc

    subroutine MPI_Comm_create_proc(comm, group, newcomm, ierror)
        use mpi_c_bindings, only: c_mpi_comm_create
        use iso_c_binding, only: c_int, c_ptr
        integer, intent(in) :: comm
        integer, intent(in) :: group
        integer, intent(out) :: newcomm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_comm, c_group, c_newcomm
        integer(c_int) :: local_ierr

        c_comm = comm_f2c(comm)
        c_group = group_f2c(group)
        local_ierr = c_mpi_comm_create(c_comm, c_group, c_newcomm)

        newcomm = comm_c2f(c_newcomm)

        if (present(ierror)) then
            ierror = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Comm_create failed with error code: ", local_ierr
        end if
    end subroutine MPI_Comm_create_proc

    subroutine MPI_Comm_dup_proc(comm, newcomm, ierror)
        use mpi_c_bindings, only: c_mpi_comm_dup
        integer, intent(in) :: comm
        integer, intent(out) :: newcomm
        integer, optional, intent(out) :: ierror

        integer(kind=MPI_HANDLE_KIND) :: c_new_comm, c_comm
        integer :: local_ierr

        c_comm = comm_f2c(comm)
        local_ierr = c_mpi_comm_dup(c_comm, c_new_comm)
        newcomm = comm_c2f(c_new_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= 0) then
                print *, "MPI_Comm_dup failed with error code: ", local_ierr
            end if
        end if
    end subroutine MPI_Comm_dup_proc

    subroutine MPI_Comm_free_proc(comm, ierror)
        use mpi_c_bindings, only: c_mpi_comm_free
        integer, intent(inout) :: comm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_comm
        integer :: local_ierr

        c_comm = comm_f2c(comm)
        local_ierr = c_mpi_comm_free(c_comm)
        comm = comm_c2f(c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Comm_free failed with error code: ", local_ierr
            end if
        end if
    end subroutine MPI_Comm_free_proc

    subroutine MPI_Bcast_int_scalar(buffer, count, datatype, root, comm, ierror)
        use mpi_c_bindings, only: c_mpi_bcast
        use iso_c_binding, only: c_int, c_ptr, c_loc
        integer, target :: buffer
        integer, intent(in) :: count, root
        integer, intent(in) :: datatype
        integer, intent(in) :: comm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_comm, c_datatype
        integer :: local_ierr
        type(c_ptr) :: buffer_ptr

        c_comm = comm_f2c(comm)

        c_datatype = datatype_f2c(datatype)
        buffer_ptr = c_loc(buffer)
        local_ierr = c_mpi_bcast(buffer_ptr, count, c_datatype, rank_f2c(root), c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Bcast_int failed with error code: ", local_ierr
            end if
        end if
    end subroutine MPI_Bcast_int_scalar

    subroutine MPI_Bcast_real_2D(buffer, count, datatype, root, comm, ierror)
        use mpi_c_bindings, only: c_mpi_bcast
        use iso_c_binding, only: c_int, c_ptr, c_loc
        real(8), dimension(:, :), target :: buffer
        integer, intent(in) :: count, root
        integer, intent(in) :: datatype
        integer, intent(in) :: comm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_comm, c_datatype
        integer :: local_ierr
        type(c_ptr) :: buffer_ptr

        c_comm = comm_f2c(comm)

        c_datatype = datatype_f2c(datatype)
        buffer_ptr = c_loc(buffer)
        local_ierr = c_mpi_bcast(buffer_ptr, count, c_datatype, rank_f2c(root), c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Bcast_real failed with error code: ", local_ierr
            end if
        end if
    end subroutine MPI_Bcast_real_2D

    subroutine MPI_Allgather_int(sendbuf, sendcount, sendtype, recvbuf, recvcount, recvtype, comm, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_allgather_int
        integer, dimension(:), intent(in), target :: sendbuf
        integer, dimension(:, :), intent(out), target :: recvbuf
        integer, intent(in) :: sendcount, recvcount
        integer, intent(in) :: sendtype, recvtype
        integer, intent(in) :: comm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_comm
        integer(c_int) :: local_ierr
        integer(kind=MPI_HANDLE_KIND) :: c_sendtype, c_recvtype
        type(c_ptr) :: sendbuf_ptr, recvbuf_ptr

        c_comm = comm_f2c(comm)

        c_sendtype = datatype_f2c(sendtype)
        c_recvtype = datatype_f2c(recvtype)
        sendbuf_ptr = c_loc(sendbuf)
        recvbuf_ptr = c_loc(recvbuf)
        local_ierr = c_mpi_allgather_int(sendbuf_ptr, sendcount, c_sendtype, recvbuf_ptr, recvcount, c_recvtype, c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Allgather_int failed with error code: ", local_ierr
            end if
        end if
    end subroutine

    subroutine MPI_Allgather_real(sendbuf, sendcount, sendtype, recvbuf, recvcount, recvtype, comm, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_allgather_real
        real(8), dimension(:), intent(in), target :: sendbuf
        real(8), dimension(:, :), intent(out), target :: recvbuf
        integer, intent(in) :: sendcount, recvcount
        integer, intent(in) :: sendtype, recvtype
        integer, intent(in) :: comm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_comm
        integer(c_int) :: local_ierr
        integer(kind=MPI_HANDLE_KIND) :: c_sendtype, c_recvtype
        type(c_ptr) :: sendbuf_ptr, recvbuf_ptr

        c_comm = comm_f2c(comm)

        c_sendtype = datatype_f2c(sendtype)
        c_recvtype = datatype_f2c(recvtype)
        sendbuf_ptr = c_loc(sendbuf)
        recvbuf_ptr = c_loc(recvbuf)
        local_ierr = c_mpi_allgather_real(sendbuf_ptr, sendcount, c_sendtype, recvbuf_ptr, recvcount, c_recvtype, c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Allgather_int failed with error code: ", local_ierr
            end if
        end if
    end subroutine

    subroutine MPI_Isend_2d(buf, count, datatype, dest, tag, comm, request, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_isend
        real(8), dimension(:, :), intent(in), target :: buf
        integer, intent(in) :: count, dest, tag
        integer, intent(in) :: datatype
        integer, intent(in) :: comm
        integer, intent(out) :: request
        integer, optional, intent(out) :: ierror
        type(c_ptr) :: buf_ptr
        integer(kind=MPI_HANDLE_KIND) :: c_datatype, c_comm, c_request
        integer(c_int) :: local_ierr

        buf_ptr = c_loc(buf)
        c_datatype = datatype_f2c(datatype)

        c_comm = comm_f2c(comm)

        local_ierr = c_mpi_isend(buf_ptr, count, c_datatype, rank_f2c(dest), tag_f2c(tag), c_comm, c_request)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Isend_2d failed with error code: ", local_ierr
            end if
        end if

        request = request_c2f(c_request)
    end subroutine

    subroutine MPI_Isend_3d(buf, count, datatype, dest, tag, comm, request, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_isend
        real(8), dimension(:, :, :), intent(in), target :: buf
        integer, intent(in) :: count, dest, tag
        integer, intent(in) :: datatype
        integer, intent(in) :: comm
        integer, intent(out) :: request
        integer, optional, intent(out) :: ierror
        type(c_ptr) :: buf_ptr
        integer(kind=MPI_HANDLE_KIND) :: c_datatype, c_comm, c_request
        integer(c_int) :: local_ierr

        buf_ptr = c_loc(buf)
        c_datatype = datatype_f2c(datatype)

        c_comm = comm_f2c(comm)

        local_ierr = c_mpi_isend(buf_ptr, count, c_datatype, rank_f2c(dest), tag_f2c(tag), c_comm, c_request)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Isend_2d failed with error code: ", local_ierr
            end if
        end if

        request = request_c2f(c_request)
    end subroutine

    subroutine MPI_Irecv_proc(buf, count, datatype, source, tag, comm, request, ierror)
        use iso_c_binding, only: c_int, c_ptr
        use mpi_c_bindings, only: c_mpi_irecv
        real(8), dimension(:,:) :: buf
        integer, intent(in) :: count, source, tag
        integer, intent(in) :: datatype
        integer, intent(in) :: comm
        integer, intent(out) :: request
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_comm
        integer(c_int) :: local_ierr
        integer(kind=MPI_HANDLE_KIND) :: c_datatype
        integer(kind=MPI_HANDLE_KIND) :: c_request

        c_comm = comm_f2c(comm)

        c_datatype = datatype_f2c(datatype)
        local_ierr = c_mpi_irecv(buf, count, c_datatype, rank_f2c(source), tag_f2c(tag), c_comm, c_request)
        request = request_c2f(c_request)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Irecv failed with error code: ", local_ierr
            end if
        end if
    end subroutine MPI_Irecv_proc

    subroutine MPI_Sendrecv_proc (sendbuf, sendcount, sendtype, dest, sendtag, &
                        recvbuf, recvcount, recvtype, source, recvtag, comm, status, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_sendrecv
        real(8), dimension(:,:), target, intent(in) :: sendbuf
        integer, intent(in) :: sendcount, dest, sendtag
        real(8), dimension(:,:), target, intent(out) :: recvbuf
        integer, intent(in) :: recvcount, source, recvtag
        integer, intent(in) :: comm
        integer, intent(in) :: sendtype, recvtype
        integer(kind=MPI_HANDLE_KIND) :: c_comm
        integer, intent(out) :: status(MPI_STATUS_SIZE)
        integer, optional, intent(out) :: ierror
        integer(c_int) :: local_ierr
        integer(kind=MPI_HANDLE_KIND) :: c_sendtype, c_recvtype
        type(c_ptr) :: sendbuf_ptr, recvbuf_ptr, c_status
        integer(c_int), dimension(MPI_STATUS_SIZE), target :: tmp_status

        c_comm = comm_f2c(comm)

        c_sendtype = datatype_f2c(sendtype)
        c_recvtype = datatype_f2c(recvtype)
        sendbuf_ptr = c_loc(sendbuf)
        recvbuf_ptr = c_loc(recvbuf)
        c_status = c_loc(tmp_status)

        local_ierr = c_mpi_sendrecv(sendbuf_ptr, sendcount, c_sendtype, rank_f2c(dest), tag_f2c(sendtag), &
                                    recvbuf_ptr, recvcount, c_recvtype, rank_f2c(source), tag_f2c(recvtag), &
                                    c_comm, c_status)

        if (local_ierr == MPI_SUCCESS) then
            call status_c2f(tmp_status, status)
        end if

        if (present(ierror)) then
            ierror = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Sendrecv failed with error code: ", local_ierr
        end if
    end subroutine MPI_Sendrecv_proc

    subroutine MPI_Allreduce_scalar(sendbuf, recvbuf, count, datatype, op, comm, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_allreduce, c_mpi_in_place
        real(8), intent(in), target :: sendbuf
        real(8), intent(out), target :: recvbuf
        integer, intent(in) :: count, datatype, op, comm
        integer, intent(out), optional :: ierror
        type(c_ptr) :: sendbuf_ptr, recvbuf_ptr
        integer(kind=MPI_HANDLE_KIND) :: c_datatype, c_op, c_comm
        integer(c_int) :: local_ierr

        if (sendbuf == MPI_IN_PLACE) then
            sendbuf_ptr = c_mpi_in_place
        else
            sendbuf_ptr = c_loc(sendbuf)
        end if
        recvbuf_ptr = c_loc(recvbuf)
        c_datatype = datatype_f2c(datatype)
        c_op = op_f2c(op)

        c_comm = comm_f2c(comm)

        local_ierr = c_mpi_allreduce(sendbuf_ptr, recvbuf_ptr, count, c_datatype, c_op, c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Allreduce_scalar failed with error code: ", local_ierr
            end if
        end if
    end subroutine

    subroutine MPI_Allreduce_1D_recv_proc(sendbuf, recvbuf, count, datatype, op, comm, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_allreduce, c_mpi_in_place
        real(8), intent(in), target :: sendbuf
        real(8), dimension(:), intent(out), target :: recvbuf
        integer, intent(in) :: count, datatype, op, comm
        integer, intent(out), optional :: ierror
        type(c_ptr) :: sendbuf_ptr, recvbuf_ptr
        integer(kind=MPI_HANDLE_KIND) :: c_datatype, c_op, c_comm
        integer(c_int) :: local_ierr

        if (sendbuf == MPI_IN_PLACE) then
            sendbuf_ptr = c_mpi_in_place
        else
            sendbuf_ptr = c_loc(sendbuf)
        end if

        recvbuf_ptr = c_loc(recvbuf)
        c_datatype = datatype_f2c(datatype)
        c_op = op_f2c(op)

        c_comm = comm_f2c(comm)

        local_ierr = c_mpi_allreduce(sendbuf_ptr, recvbuf_ptr, count, c_datatype, c_op, c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Allreduce_1D_recv_proc failed with error code: ", local_ierr
            end if
        end if
    end subroutine MPI_Allreduce_1D_recv_proc

    subroutine MPI_Allreduce_1D_real_proc(sendbuf, recvbuf, count, datatype, op, comm, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_allreduce
        real(8), dimension(:), intent(in), target :: sendbuf
        real(8), dimension(:), intent(out), target :: recvbuf
        integer, intent(in) :: count, datatype, op, comm
        integer, intent(out), optional :: ierror
        type(c_ptr) :: sendbuf_ptr, recvbuf_ptr
        integer(kind=MPI_HANDLE_KIND) :: c_datatype, c_op, c_comm
        integer(c_int) :: local_ierr

        sendbuf_ptr = c_loc(sendbuf)
        recvbuf_ptr = c_loc(recvbuf)
        c_datatype = datatype_f2c(datatype)
        c_op = op_f2c(op)

        c_comm = comm_f2c(comm)
 
        local_ierr = c_mpi_allreduce(sendbuf_ptr, recvbuf_ptr, count, c_datatype, c_op, c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Allreduce_1D_recv_proc failed with error code: ", local_ierr
            end if
        end if
    end subroutine MPI_Allreduce_1D_real_proc

    subroutine MPI_Allreduce_1D_int_proc(sendbuf, recvbuf, count, datatype, op, comm, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_allreduce
        integer, dimension(:), intent(in), target :: sendbuf
        integer, dimension(:), intent(out), target :: recvbuf
        integer, intent(in) :: count, datatype, op, comm
        integer, intent(out), optional :: ierror
        type(c_ptr) :: sendbuf_ptr, recvbuf_ptr
        integer(kind=MPI_HANDLE_KIND) :: c_datatype, c_op, c_comm
        integer(c_int) :: local_ierr

        sendbuf_ptr = c_loc(sendbuf)
        recvbuf_ptr = c_loc(recvbuf)
        c_datatype = datatype_f2c(datatype)
        c_op = op_f2c(op)

        c_comm = comm_f2c(comm)

        local_ierr = c_mpi_allreduce(sendbuf_ptr, recvbuf_ptr, count, c_datatype, c_op, c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Allreduce_1D_recv_proc failed with error code: ", local_ierr
            end if
        end if
    end subroutine MPI_Allreduce_1D_int_proc

    subroutine MPI_Allreduce_scalar_logical_proc(sendbuf, recvbuf, count, datatype, op, comm, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_allreduce
        logical, intent(in), target :: sendbuf
        logical, intent(out), target :: recvbuf
        integer, intent(in) :: count, datatype, op, comm
        integer, intent(out), optional :: ierror
        type(c_ptr) :: sendbuf_ptr, recvbuf_ptr
        integer(kind=MPI_HANDLE_KIND) :: c_datatype, c_op, c_comm
        integer(c_int) :: local_ierr

        sendbuf_ptr = c_loc(sendbuf)
        recvbuf_ptr = c_loc(recvbuf)
        c_datatype = datatype_f2c(datatype)
        c_op = op_f2c(op)

        c_comm = comm_f2c(comm)

        local_ierr = c_mpi_allreduce(sendbuf_ptr, recvbuf_ptr, count, c_datatype, c_op, c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Allreduce_1D_recv_proc failed with error code: ", local_ierr
            end if
        end if
    end subroutine MPI_Allreduce_scalar_logical_proc

    function MPI_Wtime_proc() result(time)
        use mpi_c_bindings, only: c_mpi_wtime
        real(8) :: time
        time = c_mpi_wtime()
    end function

    subroutine MPI_Barrier_proc(comm, ierror)
        use mpi_c_bindings, only: c_mpi_barrier
        use iso_c_binding, only: c_int, c_ptr
        integer, intent(in) :: comm
        integer, intent(out), optional :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_comm
        integer(c_int) :: local_ierr

        c_comm = comm_f2c(comm)

        local_ierr = c_mpi_barrier(c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Barrier failed with error code: ", local_ierr
            end if
        end if
    end subroutine MPI_Barrier_proc

    subroutine MPI_Comm_rank_proc(comm, rank, ierror)
        use iso_c_binding, only: c_int, c_ptr
        use mpi_c_bindings, only: c_mpi_comm_rank
        integer, intent(in) :: comm
        integer, intent(out) :: rank
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_comm
        integer(c_int) :: local_ierr

        c_comm = comm_f2c(comm)
        local_ierr = c_mpi_comm_rank(c_comm, rank)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Comm_rank failed with error code: ", local_ierr
            end if
        end if
    end subroutine

    subroutine MPI_Comm_split_type_proc(comm, split_type, key, info, newcomm, ierror)
        use iso_c_binding, only: c_int, c_ptr
        use mpi_c_bindings, only: c_mpi_comm_split_type
        integer, intent(in) :: comm
        integer, intent(in) :: split_type, key
        integer, intent(in) :: info
        integer, intent(out) :: newcomm
        integer, optional, intent(out) :: ierror
    
        integer(c_int) :: local_ierr
        integer(kind=MPI_HANDLE_KIND) :: c_comm, c_info, c_new_comm

        c_comm = comm_f2c(comm)
        c_info = info_f2c(info)

        ! Call the native MPI_Comm_split_type.
        local_ierr = c_mpi_comm_split_type(c_comm, split_type_f2c(split_type), key, c_info, c_new_comm)

        ! Convert the new communicator C handle back to a Fortran integer handle.
        newcomm = comm_c2f(c_new_comm)
    
        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= 0) then
                print *, "MPI_Comm_split_type failed with error code: ", local_ierr
            end if
        end if
    end subroutine MPI_Comm_split_type_proc

    subroutine MPI_Recv_StatusArray_proc(buf, count, datatype, source, tag, comm, status, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_recv
        real(8), dimension(*), intent(inout), target :: buf
        integer, intent(in)  :: count, source, tag, datatype, comm
        integer, intent(out) :: status(MPI_STATUS_SIZE)
        integer, optional, intent(out) :: ierror
    
        integer(c_int) :: local_ierr
        integer(kind=MPI_HANDLE_KIND) :: c_dtype, c_comm
        type(c_ptr) :: c_status
        integer(c_int), dimension(MPI_STATUS_SIZE), target :: tmp_status

        ! Convert Fortran handles to C handles.
        c_dtype = datatype_f2c(datatype)

        c_comm = comm_f2c(comm)

        ! Use a local temporary MPI_Status (as an array of c_int)
        c_status = c_loc(tmp_status)

        ! Call the native MPI_Recv.
        local_ierr = c_mpi_recv(c_loc(buf), count, c_dtype, rank_f2c(source), tag_f2c(tag), c_comm, c_status)

        ! Convert the C MPI_Status to Fortran status.
        if (local_ierr == MPI_SUCCESS) then
            call status_c2f(tmp_status, status)
        end if

        if (present(ierror)) then
            ierror = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Recv failed with error code: ", local_ierr
        end if
    
    end subroutine MPI_Recv_StatusArray_proc

    subroutine MPI_Recv_StatusIgnore_proc(buf, count, datatype, source, tag, comm, status, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_recv
        real(8), dimension(*), intent(inout), target :: buf
        integer, intent(in)  :: count, source, tag, datatype, comm
        integer, intent(out) :: status
        integer, optional, intent(out) :: ierror
    
        integer(c_int) :: local_ierr
        integer(kind=MPI_HANDLE_KIND) :: c_dtype, c_comm
        type(c_ptr) :: c_status
        integer(c_int), dimension(MPI_STATUS_SIZE), target :: tmp_status

        ! Convert Fortran handles to C handles.
        c_dtype = datatype_f2c(datatype)

        c_comm = comm_f2c(comm)

        ! Use a local temporary MPI_Status (as an array of c_int)
        c_status = c_loc(tmp_status)

        ! Call the native MPI_Recv.
        local_ierr = c_mpi_recv(c_loc(buf), count, c_dtype, rank_f2c(source), tag_f2c(tag), c_comm, c_status)

        if (present(ierror)) then
            ierror = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Recv failed with error code: ", local_ierr
        end if
    
    end subroutine MPI_Recv_StatusIgnore_proc

    subroutine MPI_Gatherv_int(sendbuf, sendcount, sendtype, recvbuf, recvcounts, &
                               displs, recvtype, root, comm, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_gatherv, c_mpi_in_place
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
        integer(kind=MPI_HANDLE_KIND) :: c_sendtype, c_recvtype, c_comm
        type(c_ptr) :: c_sendbuf, c_recvbuf
        integer(c_int) :: local_ierr

        if (sendbuf(1) == MPI_IN_PLACE) then
            c_sendbuf = c_MPI_IN_PLACE
        else
            c_sendbuf = c_loc(sendbuf)
        end if

        c_recvbuf = c_loc(recvbuf)
        c_sendtype = datatype_f2c(sendtype)
        c_recvtype = datatype_f2c(recvtype)
        c_comm = comm_f2c(comm)

        ! Call C MPI_Gatherv
        local_ierr = c_mpi_gatherv(c_sendbuf, sendcount, c_sendtype, &
                                   c_recvbuf, recvcounts, displs, c_recvtype, &
                                   rank_f2c(root), c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Gatherv failed with error code: ", local_ierr
        end if
    end subroutine MPI_Gatherv_int

    subroutine MPI_Gatherv_real(sendbuf, sendcount, sendtype, recvbuf, recvcounts, &
                                displs, recvtype, root, comm, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_gatherv, c_mpi_in_place
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
        integer(kind=MPI_HANDLE_KIND) :: c_sendtype, c_recvtype, c_comm
        type(c_ptr) :: c_sendbuf, c_recvbuf
        integer(c_int) :: local_ierr

        if (sendbuf(1) == MPI_IN_PLACE) then
            c_sendbuf = c_MPI_IN_PLACE
        else
            c_sendbuf = c_loc(sendbuf)
        end if

        c_recvbuf = c_loc(recvbuf)
        c_sendtype = datatype_f2c(sendtype)
        c_recvtype = datatype_f2c(recvtype)
        c_comm = comm_f2c(comm)

        ! Call C MPI_Gatherv
        local_ierr = c_mpi_gatherv(c_sendbuf, sendcount, c_sendtype, &
                                   c_recvbuf, recvcounts, displs, c_recvtype, &
                                   rank_f2c(root), c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Gatherv failed with error code: ", local_ierr
        end if
    end subroutine MPI_Gatherv_real

    subroutine MPI_Gatherv_character(sendbuf, sendcount, sendtype, recvbuf, recvcounts, &
                                displs, recvtype, root, comm, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_gatherv
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
        integer(kind=MPI_HANDLE_KIND) :: c_sendtype, c_recvtype, c_comm
        type(c_ptr) :: c_sendbuf, c_recvbuf
        integer(c_int) :: local_ierr

        c_sendbuf = c_loc(sendbuf)
        c_recvbuf = c_loc(recvbuf)
        c_sendtype = datatype_f2c(sendtype)
        c_recvtype = datatype_f2c(recvtype)
        c_comm = comm_f2c(comm)

        ! Call C MPI_Gatherv
        local_ierr = c_mpi_gatherv(c_sendbuf, sendcount, c_sendtype, &
                                   c_recvbuf, recvcounts, displs, c_recvtype, &
                                   rank_f2c(root), c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Gatherv failed with error code: ", local_ierr
        end if
    end subroutine MPI_Gatherv_character

    subroutine MPI_Wait_proc(request, status, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_wait
        integer, intent(inout) :: request
        integer, intent(out) :: status(MPI_STATUS_SIZE)
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_request
        integer(c_int) :: local_ierr
        type(c_ptr) :: c_status
        integer(c_int), dimension(MPI_STATUS_SIZE), target :: tmp_status

        c_request = request_f2c(request)
        c_status = c_loc(tmp_status)

        local_ierr = c_mpi_wait(c_request, c_status)

        request = request_c2f(c_request)

        if (local_ierr == MPI_SUCCESS) then
            call status_c2f(tmp_status, status)
        end if

        if (present(ierror)) then
            ierror = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Wait failed with error code: ", local_ierr
        end if
    end subroutine MPI_Wait_proc

    subroutine MPI_Waitall_proc(count, array_of_requests, array_of_statuses, ierror)
        use iso_c_binding, only: c_int, c_ptr
        use mpi_c_bindings, only: c_mpi_waitall, c_mpi_statuses_ignore
        integer, intent(in) :: count
        integer, dimension(count), intent(inout) :: array_of_requests
        integer, dimension(*), intent(out) :: array_of_statuses
        integer, optional, intent(out) :: ierror
        integer :: arr_request_item_kind_4
        integer(kind=MPI_HANDLE_KIND) :: arr_request_item_kind_mpi_handle_kind

        integer(c_int) :: local_ierr
        integer :: i

        ! TODO: array_of_statuses is ignored, see doc/design.md
        ! Allocate temporary arrays for the C representations.
        integer(kind=MPI_HANDLE_KIND), dimension(count) :: c_requests
        type(c_ptr) :: MPI_STATUSES_IGNORE_from_c

        MPI_STATUSES_IGNORE_from_c = c_mpi_statuses_ignore

        ! Convert Fortran requests to C requests.
        do i = 1, count
            arr_request_item_kind_4 = array_of_requests(i)
            c_requests(i) = request_f2c(arr_request_item_kind_4)
        end do

        ! Call the native MPI_Waitall.
        local_ierr = c_mpi_waitall(count, c_requests, MPI_STATUSES_IGNORE_from_c)

        ! Convert the C requests back to Fortran handles.
        do i = 1, count
            arr_request_item_kind_mpi_handle_kind = c_requests(i)
            array_of_requests(i) = request_c2f(arr_request_item_kind_mpi_handle_kind)
        end do

        if (present(ierror)) then
            ierror = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Waitall failed with error code: ", local_ierr
        end if

    end subroutine MPI_Waitall_proc

    subroutine MPI_Allgatherv_int(sendbuf, sendcount, sendtype, recvbuf, recvcounts, &
                                  displs, recvtype, comm, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_allgatherv, c_mpi_in_place
        integer, dimension(:), intent(in), target :: sendbuf
        integer, intent(in) :: sendcount
        integer, intent(in) :: sendtype
        integer, dimension(:), intent(out), target :: recvbuf
        integer, dimension(:), intent(in) :: recvcounts
        integer, dimension(:), intent(in) :: displs
        integer, intent(in) :: recvtype
        integer, intent(in) :: comm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_sendtype, c_recvtype, c_comm
        type(c_ptr) :: c_sendbuf, c_recvbuf
        integer(c_int) :: local_ierr

        ! Handle sendbuf (support MPI_IN_PLACE)
        if (sendbuf(1) == MPI_IN_PLACE) then
            c_sendbuf = c_MPI_IN_PLACE
        else
            c_sendbuf = c_loc(sendbuf)
        end if
        c_recvbuf = c_loc(recvbuf)
        c_sendtype = datatype_f2c(sendtype)
        c_recvtype = datatype_f2c(recvtype)
        c_comm = comm_f2c(comm)

        ! Call C MPI_Allgatherv
        local_ierr = c_mpi_allgatherv(c_sendbuf, sendcount, c_sendtype, &
                                      c_recvbuf, recvcounts, displs, c_recvtype, &
                                      c_comm)

        ! Handle error
        if (present(ierror)) then
            ierror = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Allgatherv failed with error code: ", local_ierr
        end if
        
    end subroutine MPI_Allgatherv_int

    subroutine MPI_Allgatherv_real(sendbuf, sendcount, sendtype, recvbuf, recvcounts, &
                                      displs, recvtype, comm, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_allgatherv, c_mpi_in_place
        real(8), dimension(:), intent(in), target :: sendbuf
        integer, intent(in) :: sendcount
        integer, intent(in) :: sendtype
        real(8), dimension(:), intent(out), target :: recvbuf
        integer, dimension(:), intent(in) :: recvcounts
        integer, dimension(:), intent(in) :: displs
        integer, intent(in) :: recvtype
        integer, intent(in) :: comm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_sendtype, c_recvtype, c_comm
        type(c_ptr) :: c_sendbuf, c_recvbuf
        integer(c_int) :: local_ierr

        if (sendbuf(1) == MPI_IN_PLACE) then
            c_sendbuf = c_MPI_IN_PLACE
        else
            c_sendbuf = c_loc(sendbuf)
        end if

        c_recvbuf = c_loc(recvbuf)
        c_sendtype = datatype_f2c(sendtype)
        c_recvtype = datatype_f2c(recvtype)
        c_comm = comm_f2c(comm)

        ! Call C MPI_Allgatherv
        local_ierr = c_mpi_allgatherv(c_sendbuf, sendcount, c_sendtype, &
                                      c_recvbuf, recvcounts, displs, c_recvtype, &
                                      c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Allgatherv failed with error code: ", local_ierr
        end if

    end subroutine MPI_Allgatherv_real

    subroutine MPI_Scatter_real(sendbuf, sendcount, sendtype, recvbuf, recvcount, &
                                recvtype, root, comm, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_scatter, c_mpi_in_place
        real(8), dimension(*), intent(in), target :: sendbuf
        integer, intent(in) :: sendcount
        integer, intent(in) :: sendtype
        real(8), dimension(*), intent(out), target :: recvbuf
        integer, intent(in) :: recvcount
        integer, intent(in) :: recvtype
        integer, intent(in) :: root
        integer, intent(in) :: comm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_sendtype, c_recvtype, c_comm
        type(c_ptr) :: c_sendbuf, c_recvbuf
        integer(c_int) :: local_ierr

        if (sendbuf(1) == MPI_IN_PLACE) then
            c_sendbuf = c_MPI_IN_PLACE
        else
            c_sendbuf = c_loc(sendbuf)
        end if
        c_recvbuf = c_loc(recvbuf)
        c_sendtype = datatype_f2c(sendtype)
        c_recvtype = datatype_f2c(recvtype)
        c_comm = comm_f2c(comm)

        local_ierr = c_mpi_scatter(c_sendbuf, sendcount, c_sendtype, &
                                   c_recvbuf, recvcount, c_recvtype, &
                                   rank_f2c(root), c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Scatter failed with error code: ", local_ierr
        end if
    end subroutine MPI_Scatter_real

    subroutine MPI_Ssend_proc(buf, count, datatype, dest, tag, comm, ierror)
        use iso_c_binding, only: c_int, c_ptr
        use mpi_c_bindings, only: c_mpi_ssend
        real(8), dimension(*), intent(in) :: buf
        integer, intent(in) :: count, dest, tag
        integer, intent(in) :: datatype
        integer, intent(in) :: comm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_datatype, c_comm
        integer :: local_ierr

        c_datatype = datatype_f2c(datatype)
        c_comm = comm_f2c(comm)
        local_ierr = c_mpi_ssend(buf, count, c_datatype, rank_f2c(dest), tag_f2c(tag), c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Ssend failed with error code: ", local_ierr
        end if
    end subroutine

    subroutine MPI_Cart_create_proc(comm_old, ndims, dims, periods, reorder, comm_cart, ierror)
        use iso_c_binding, only: c_int, c_ptr
        use mpi_c_bindings, only: c_mpi_cart_create
        integer, intent(in) :: ndims, dims(ndims)
        logical, intent(in) :: periods(ndims), reorder
        integer, intent(in) :: comm_old
        integer, intent(out) :: comm_cart
        integer, optional, intent(out) :: ierror
        integer(c_int) :: ndims_c, reorder_c, dims_c(ndims), periods_c(ndims)
        integer(kind=MPI_HANDLE_KIND) :: c_comm_old
        integer(kind=MPI_HANDLE_KIND) :: c_comm_cart
        integer(c_int) :: local_ierr

        c_comm_old = comm_f2c(comm_old)

        ndims_c = ndims
        if (reorder) then
            reorder_c = 1
        else
            reorder_c = 0
        end if
        dims_c = dims
        where (periods)
            periods_c = 1
        elsewhere
            periods_c = 0
        end where
        local_ierr = c_mpi_cart_create(c_comm_old, ndims, dims_c, periods_c, reorder_c, c_comm_cart)
        comm_cart = comm_c2f(c_comm_cart)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Cart_create failed with error code: ", local_ierr
            end if
        end if
    end subroutine

    subroutine MPI_Cart_coords_proc(comm, rank, maxdims, coords, ierror)
        use iso_c_binding, only: c_int, c_ptr
        use mpi_c_bindings, only: c_mpi_cart_coords
        integer, intent(in) :: comm
        integer, intent(in) :: rank, maxdims
        integer, intent(out) :: coords(maxdims)
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_comm
        integer(c_int) :: local_ierr

        c_comm = comm_f2c(comm)

        local_ierr = c_mpi_cart_coords(c_comm, rank, maxdims, coords)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Barrier failed with error code: ", local_ierr
            end if
        end if
    end subroutine

    subroutine MPI_Cart_shift_proc(comm, direction, disp, rank_source, rank_dest, ierror)
        use iso_c_binding, only: c_int, c_ptr
        use mpi_c_bindings, only: c_mpi_cart_shift
        integer, intent(in) :: comm
        integer, intent(in) :: direction, disp
        integer, intent(out) :: rank_source, rank_dest
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_comm
        integer(c_int) :: local_ierr, c_rank_source, c_rank_dest

        c_comm = comm_f2c(comm)

        local_ierr = c_mpi_cart_shift(c_comm, direction, disp, c_rank_source, c_rank_dest)
        rank_source = rank_c2f(c_rank_source)
        rank_dest = rank_c2f(c_rank_dest)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Cart_shift failed with error code: ", local_ierr
            end if
        end if
    end subroutine

    subroutine MPI_Dims_create_proc(nnodes, ndims, dims, ierror)
        use iso_c_binding, only: c_int, c_ptr
        use mpi_c_bindings, only: c_mpi_dims_create
        integer, intent(in) :: nnodes, ndims
        integer, intent(out) :: dims(ndims)
        integer, optional, intent(out) :: ierror
        integer(c_int) :: local_ierr

        local_ierr = c_mpi_dims_create(nnodes, ndims, dims)
        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Dims_create failed with error code: ", local_ierr
            end if
        end if
    end subroutine

    subroutine MPI_Cart_sub_proc (comm, remain_dims, newcomm, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_cart_sub
        integer, intent(in) :: comm
        logical, intent(in) :: remain_dims(:)
        integer, intent(out) :: newcomm
        integer, optional, intent(out) :: ierror
        integer, target :: remain_dims_i(size(remain_dims))
        integer(kind=MPI_HANDLE_KIND) :: c_comm, c_newcomm
        integer :: local_ierr
        type(c_ptr) :: remain_dims_i_ptr

        c_comm = comm_f2c(comm)

        where (remain_dims)
            remain_dims_i = 1
        elsewhere
            remain_dims_i = 0
        end where
        remain_dims_i_ptr = c_loc(remain_dims_i)
        local_ierr = c_mpi_cart_sub(c_comm, remain_dims_i_ptr, c_newcomm)

        newcomm = comm_c2f(c_newcomm)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Cart_sub failed with error code: ", local_ierr
            end if
        end if
    end subroutine

    subroutine MPI_Exscan_scalar_int(sendbuf, recvbuf, count, datatype, op, comm, ierror)
        use mpi_c_bindings, only: c_mpi_exscan
        use iso_c_binding, only: c_int, c_ptr, c_loc
        integer, target, intent(in)  :: sendbuf
        integer, target, intent(out) :: recvbuf
        integer, intent(in)  :: count, datatype, op, comm
        integer, optional, intent(out) :: ierror

        integer(kind=MPI_HANDLE_KIND) :: c_comm, c_dtype, c_op
        type(c_ptr)    :: c_sendbuf, c_recvbuf
        integer(c_int) :: local_ierr

        c_comm = comm_f2c(comm)
        c_dtype = datatype_f2c(datatype)
        c_op = op_f2c(op)

        c_sendbuf = c_loc(sendbuf)
        c_recvbuf = c_loc(recvbuf)

        local_ierr = c_mpi_exscan(c_sendbuf, c_recvbuf, count, c_dtype, c_op, c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Exscan failed with error code: ", local_ierr
        end if
    end subroutine MPI_Exscan_scalar_int

    subroutine MPI_Reduce_scalar_int(sendbuf, recvbuf, count, datatype, op, root, comm, ierror)
        use mpi_c_bindings, only: c_mpi_reduce
        use iso_c_binding, only: c_int, c_ptr, c_loc
        integer, target, intent(in)  :: sendbuf
        integer, target, intent(out) :: recvbuf
        integer, intent(in)  :: count, datatype, op, root, comm
        integer, optional, intent(out) :: ierror

        integer(kind=MPI_HANDLE_KIND)    :: c_comm, c_dtype, c_op
        type(c_ptr)    :: c_sendbuf, c_recvbuf
        integer(c_int) :: local_ierr

        c_comm = comm_f2c(comm)

        c_dtype = datatype_f2c(datatype)
        c_op    = op_f2c(op)

        ! Pass pointer to the actual data
        c_sendbuf = c_loc(sendbuf)
        c_recvbuf = c_loc(recvbuf)

        local_ierr = c_mpi_reduce(c_sendbuf, c_recvbuf, count, c_dtype, c_op, rank_f2c(root), c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Reduce failed with error code: ", local_ierr
            end if
        end if
    end subroutine MPI_Reduce_scalar_int

    subroutine MPI_Comm_get_name_proc(comm, comm_name, resultlen, ierror)
        use iso_c_binding, only: c_int, c_char
        use mpi_c_bindings, only: c_mpi_comm_get_name
        integer, intent(in) :: comm
        character(len=*), intent(out) :: comm_name
        integer, intent(out) :: resultlen
        integer, optional, intent(out) :: ierror
        character(kind=c_char) :: c_name(MPI_MAX_OBJECT_NAME)
        integer(c_int) :: local_ierr

        local_ierr = c_mpi_comm_get_name(comm_f2c(comm), c_name, resultlen)
        call c_string_to_fortran(c_name, resultlen, comm_name)

        if (present(ierror)) then
            ierror = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Comm_get_name failed with error code: ", local_ierr
        end if
    end subroutine MPI_Comm_get_name_proc

    subroutine MPI_Type_get_name_proc(datatype, type_name, resultlen, ierror)
        use iso_c_binding, only: c_int, c_char
        use mpi_c_bindings, only: c_mpi_type_get_name
        integer, intent(in) :: datatype
        character(len=*), intent(out) :: type_name
        integer, intent(out) :: resultlen
        integer, optional, intent(out) :: ierror
        character(kind=c_char) :: c_name(MPI_MAX_OBJECT_NAME)
        integer(c_int) :: local_ierr

        local_ierr = c_mpi_type_get_name(datatype_f2c(datatype), c_name, resultlen)
        call c_string_to_fortran(c_name, resultlen, type_name)

        if (present(ierror)) then
            ierror = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Type_get_name failed with error code: ", local_ierr
        end if
    end subroutine MPI_Type_get_name_proc
end module mpi
