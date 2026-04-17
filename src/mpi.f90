module mpi
    use mpi_c_bindings, only: MPI_HANDLE_KIND
    implicit none

    integer, parameter :: MPI_THREAD_FUNNELED = 1

    integer, parameter :: MPI_INTEGER = -10002
    integer, parameter :: MPI_REAL = -10003
    integer, parameter :: MPI_DOUBLE_PRECISION = -10004
    integer, parameter :: MPI_REAL4 = -10013
    integer, parameter :: MPI_REAL8 = -10014
    integer, parameter :: MPI_CHARACTER = -10003
    integer, parameter :: MPI_LOGICAL = -10005

    integer, parameter :: MPI_COMM_TYPE_SHARED = 1
    integer, parameter :: MPI_PROC_NULL = -1
    integer, parameter :: MPI_SUCCESS = 0

    integer, parameter :: MPI_COMM_WORLD = -1000
    integer, parameter :: MPI_COMM_NULL = -1001
    integer, parameter :: MPI_COMM_SELF = -1003
    real(8), parameter :: MPI_IN_PLACE = -1002
    integer, parameter :: MPI_SUM = -2300
    integer, parameter :: MPI_MAX = -2301
    integer, parameter :: MPI_LOR = -2302
    integer, parameter :: MPI_INFO_NULL = -2000
    integer, parameter :: MPI_STATUS_SIZE = 5
    integer :: MPI_STATUS_IGNORE = 0
    ! NOTE: I've no idea for how to implement this, refer
    ! see section 2.5.4 page 21 of mpi40-report.pdf
    ! this is probably not correct right now
    integer :: MPI_STATUSES_IGNORE(1024)

    ! not used in pot3d.F90
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

    contains

    integer(kind=MPI_HANDLE_KIND) function handle_mpi_op_f2c(op_f) result(c_op)
        use mpi_c_bindings, only: c_mpi_op_f2c, c_mpi_sum, c_mpi_max, c_mpi_lor
        integer, intent(in) :: op_f
        if (op_f == MPI_SUM) then
            c_op = c_mpi_sum
        else if (op_f == MPI_MAX) then
            c_op = c_MPI_MAX
        else if (op_f == MPI_LOR) then
            c_op = c_mpi_lor
        else
            c_op = c_mpi_op_f2c(op_f)  ! For other operations, use the C binding
        end if
    end function

    integer(kind=MPI_HANDLE_KIND) function handle_mpi_comm_f2c(comm_f) result(c_comm)
        use mpi_c_bindings, only: c_mpi_comm_size, c_mpi_comm_f2c, c_mpi_comm_world, c_mpi_comm_self
        integer, intent(in) :: comm_f
        if (comm_f == MPI_COMM_WORLD) then
            c_comm = c_mpi_comm_world
        else if (comm_f == MPI_COMM_SELF) then
            c_comm = c_mpi_comm_self
        else
            c_comm = c_mpi_comm_f2c(comm_f)
        end if
    end function handle_mpi_comm_f2c

    integer(kind=MPI_HANDLE_KIND) function handle_mpi_comm_c2f(comm_c) result(f_comm)
        use mpi_c_bindings, only: c_mpi_comm_c2f, c_mpi_comm_null
        integer(kind=mpi_handle_kind), intent(in) :: comm_c
        if (comm_c == c_mpi_comm_null) then
            f_comm = MPI_COMM_NULL
        else
            f_comm = c_mpi_comm_c2f(comm_c)
        end if
    end function handle_mpi_comm_c2f

    integer(kind=MPI_HANDLE_KIND) function handle_mpi_info_f2c(info_f) result(c_info)
        use mpi_c_bindings, only: c_mpi_info_f2c, c_mpi_info_null
        integer, intent(in) :: info_f
        if (info_f == MPI_INFO_NULL) then
            c_info = c_mpi_info_null
        else
            c_info = c_mpi_info_f2c(info_f)
        end if
    end function handle_mpi_info_f2c

    integer(kind=MPI_HANDLE_KIND) function handle_mpi_datatype_f2c(datatype_f) result(c_datatype)
        use mpi_c_bindings, only: c_mpi_float, c_mpi_double, c_mpi_int, c_mpi_logical, c_mpi_character, c_mpi_real
        integer, intent(in) :: datatype_f
        if (datatype_f == MPI_REAL4) then
            c_datatype = c_mpi_float
        else if (datatype_f == MPI_REAL) then
            c_datatype = c_mpi_real
        else if (datatype_f == MPI_REAL8 .OR. datatype_f == MPI_DOUBLE_PRECISION) then
            c_datatype = c_mpi_double
        else if (datatype_f == MPI_INTEGER) then
            c_datatype = c_mpi_int
        else if (datatype_f == MPI_CHARACTER) then
            c_datatype = c_mpi_character
        else if (datatype_f == MPI_LOGICAL) then
            c_datatype = c_mpi_logical
        end if
    end function

    subroutine MPI_Init_proc(ierr)
        use mpi_c_bindings, only: c_mpi_init
        use iso_c_binding, only : c_int, c_ptr, c_null_ptr
        integer, optional, intent(out) :: ierr
        integer(c_int) :: local_ierr
        integer(c_int) :: argc
        type(c_ptr) :: argv = c_null_ptr
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
        argc = 0
        ! Map Fortran MPI_THREAD_FUNNELED to C MPI_THREAD_FUNNELED if needed
        c_required = int(required, c_int)

        ! Call C MPI_Init_thread directly
        local_ierr = c_mpi_init_thread(argc, argv, required, provided)

        ! Copy output values back to Fortran
        provided = int(c_provided)

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
            ierr = int(local_ierr)
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

        c_comm = handle_mpi_comm_f2c(comm)

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
        use mpi_c_bindings, only: c_mpi_comm_group, c_mpi_group_f2c, c_mpi_group_c2f
        use iso_c_binding, only: c_int, c_ptr
        integer, intent(in) :: comm
        integer, intent(out) :: group
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_comm, c_group
        integer :: local_ierr

        c_comm = handle_mpi_comm_f2c(comm)
        c_group = c_mpi_group_f2c(group)
        local_ierr = c_mpi_comm_group(c_comm, c_group)
        group = c_mpi_group_c2f(c_group)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= 0) then
                print *, "MPI_Comm_Group failed with error code: ", local_ierr
            end if
        end if
    end subroutine MPI_Comm_Group_proc

    subroutine MPI_Group_size_proc(group, size, ierror)
        use mpi_c_bindings, only: c_mpi_group_size, c_mpi_group_f2c
        use iso_c_binding, only: c_int, c_ptr
        integer, intent(in) :: group
        integer, intent(out) :: size
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_group
        integer :: local_ierr

        c_group = c_mpi_group_f2c(group)
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
        use mpi_c_bindings, only: c_mpi_group_free, c_mpi_group_f2c
        use iso_c_binding, only: c_int, c_ptr
        integer, intent(in) :: group
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_group
        integer :: local_ierr

        c_group = c_mpi_group_f2c(group)
        local_ierr = c_mpi_group_free(c_group)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= 0) then
                print *, "MPI_Group_free failed with error code: ", local_ierr
            end if
        end if
    end subroutine MPI_Group_free_proc

    subroutine MPI_Group_range_incl_proc(group, n, ranks, newgroup, ierror)
        use mpi_c_bindings, only: c_mpi_group_range_incl, c_mpi_group_f2c, c_mpi_comm_c2f, c_mpi_group_c2f
        use iso_c_binding, only: c_int, c_ptr
        integer, intent(in) :: group
        integer, intent(in) :: n
        integer, dimension(:,:), intent(in) :: ranks
        integer, intent(out) :: newgroup
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_group, c_newgroup
        integer(c_int) :: local_ierr

        c_group = c_mpi_group_f2c(group)
        local_ierr = c_mpi_group_range_incl(c_group, n, ranks, c_newgroup)
        newgroup = c_mpi_group_c2f(c_newgroup)

        if (present(ierror)) then
            ierror = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Group_incl failed with error code: ", local_ierr
        end if
    end subroutine MPI_Group_range_incl_proc

    subroutine MPI_Comm_create_proc(comm, group, newcomm, ierror)
        use mpi_c_bindings, only: c_mpi_comm_create, c_mpi_comm_f2c, c_mpi_comm_c2f, c_mpi_group_f2c, c_mpi_comm_null
        use iso_c_binding, only: c_int, c_ptr
        integer, intent(in) :: comm
        integer, intent(in) :: group
        integer, intent(out) :: newcomm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_comm, c_group, c_newcomm
        integer(c_int) :: local_ierr

        c_comm = handle_mpi_comm_f2c(comm)
        c_group = c_mpi_group_f2c(group)
        local_ierr = c_mpi_comm_create(c_comm, c_group, c_newcomm)

        newcomm = handle_mpi_comm_c2f(c_newcomm)

        if (present(ierror)) then
            ierror = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Comm_create failed with error code: ", local_ierr
        end if
    end subroutine MPI_Comm_create_proc

    subroutine MPI_Comm_dup_proc(comm, newcomm, ierror)
        use mpi_c_bindings, only: c_mpi_comm_dup, c_mpi_comm_c2f
        integer, intent(in) :: comm
        integer, intent(out) :: newcomm
        integer, optional, intent(out) :: ierror

        integer(kind=MPI_HANDLE_KIND) :: c_new_comm, c_comm
        integer :: local_ierr

        c_comm = handle_mpi_comm_f2c(comm)
        local_ierr = c_mpi_comm_dup(c_comm, c_new_comm)
        newcomm = c_mpi_comm_c2f(c_new_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= 0) then
                print *, "MPI_Comm_dup failed with error code: ", local_ierr
            end if
        end if
    end subroutine MPI_Comm_dup_proc

    subroutine MPI_Comm_free_proc(comm, ierror)
        use mpi_c_bindings, only: c_mpi_comm_free, c_mpi_comm_f2c
        integer, intent(inout) :: comm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_comm
        integer :: local_ierr

        c_comm = handle_mpi_comm_f2c(comm)
        local_ierr = c_mpi_comm_free(c_comm)
        comm = handle_mpi_comm_c2f(c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Comm_free failed with error code: ", local_ierr
            end if
        end if

        comm = MPI_COMM_NULL  ! Set to null after freeing
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

        c_comm = handle_mpi_comm_f2c(comm)

        c_datatype = handle_mpi_datatype_f2c(datatype)
        buffer_ptr = c_loc(buffer)
        local_ierr = c_mpi_bcast(buffer_ptr, count, c_datatype, root, c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Bcast_int failed with error code: ", local_ierr
            end if
        end if
    end subroutine MPI_Bcast_int_scalar

    subroutine MPI_Bcast_real_2D(buffer, count, datatype, root, comm, ierror)
        use mpi_c_bindings, only: c_mpi_bcast, c_mpi_comm_f2c
        use iso_c_binding, only: c_int, c_ptr, c_loc
        real(8), dimension(:, :), target :: buffer
        integer, intent(in) :: count, root
        integer, intent(in) :: datatype
        integer, intent(in) :: comm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_comm, c_datatype
        integer :: local_ierr
        type(c_ptr) :: buffer_ptr

        c_comm = handle_mpi_comm_f2c(comm)

        c_datatype = handle_mpi_datatype_f2c(datatype)
        buffer_ptr = c_loc(buffer)
        local_ierr = c_mpi_bcast(buffer_ptr, count, c_datatype, root, c_comm)

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

        c_comm = handle_mpi_comm_f2c(comm)

        c_sendtype = handle_mpi_datatype_f2c(sendtype)
        c_recvtype = handle_mpi_datatype_f2c(recvtype)
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

        c_comm = handle_mpi_comm_f2c(comm)

        c_sendtype = handle_mpi_datatype_f2c(sendtype)
        c_recvtype = handle_mpi_datatype_f2c(recvtype)
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
        use mpi_c_bindings, only: c_mpi_isend, c_mpi_request_c2f
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
        c_datatype = handle_mpi_datatype_f2c(datatype)

        c_comm = handle_mpi_comm_f2c(comm)

        local_ierr = c_mpi_isend(buf_ptr, count, c_datatype, dest, tag, c_comm, c_request)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Isend_2d failed with error code: ", local_ierr
            end if
        end if

        request = c_mpi_request_c2f(c_request)
    end subroutine

    subroutine MPI_Isend_3d(buf, count, datatype, dest, tag, comm, request, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_isend, c_mpi_request_c2f
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
        c_datatype = handle_mpi_datatype_f2c(datatype)

        c_comm = handle_mpi_comm_f2c(comm)

        local_ierr = c_mpi_isend(buf_ptr, count, c_datatype, dest, tag, c_comm, c_request)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Isend_2d failed with error code: ", local_ierr
            end if
        end if

        request = c_mpi_request_c2f(c_request)
    end subroutine

    subroutine MPI_Irecv_proc(buf, count, datatype, source, tag, comm, request, ierror)
        use iso_c_binding, only: c_int, c_ptr
        use mpi_c_bindings, only: c_mpi_irecv, c_mpi_request_c2f
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

        c_comm = handle_mpi_comm_f2c(comm)

        c_datatype = handle_mpi_datatype_f2c(datatype)
        local_ierr = c_mpi_irecv(buf, count, c_datatype, source, tag, c_comm, c_request)
        request = c_mpi_request_c2f(c_request)

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
        use mpi_c_bindings, only: c_mpi_sendrecv, c_mpi_status_c2f
        real(8), dimension(:,:), target, intent(in) :: sendbuf
        integer, intent(in) :: sendcount, dest, sendtag
        real(8), dimension(:,:), target, intent(out) :: recvbuf
        integer, intent(in) :: recvcount, source, recvtag
        integer, intent(in) :: comm
        integer, intent(in) :: sendtype, recvtype
        integer(kind=MPI_HANDLE_KIND) :: c_comm
        integer, intent(out) :: status(MPI_STATUS_SIZE)
        integer, optional, intent(out) :: ierror
        integer(c_int) :: local_ierr, status_ierr
        integer(kind=MPI_HANDLE_KIND) :: c_sendtype, c_recvtype
        type(c_ptr) :: sendbuf_ptr, recvbuf_ptr, c_status
        integer(c_int), dimension(MPI_STATUS_SIZE), target :: tmp_status

        c_comm = handle_mpi_comm_f2c(comm)

        c_sendtype = handle_mpi_datatype_f2c(sendtype)
        c_recvtype = handle_mpi_datatype_f2c(recvtype)
        sendbuf_ptr = c_loc(sendbuf)
        recvbuf_ptr = c_loc(recvbuf)
        c_status = c_loc(tmp_status)

        local_ierr = c_mpi_sendrecv(sendbuf_ptr, sendcount, c_sendtype, dest, sendtag, &
                                    recvbuf_ptr, recvcount, c_recvtype, source, recvtag, &
                                    c_comm, c_status)

        if (local_ierr == MPI_SUCCESS) then
        !   status_ierr =  c_mpi_status_c2f(c_status, status)
        end if

        if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Sendrecv failed with error code: ", local_ierr
            if (present(ierror)) then
                ierror = local_ierr
            end if
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
        c_datatype = handle_mpi_datatype_f2c(datatype)
        c_op = handle_mpi_op_f2c(op)

        c_comm = handle_mpi_comm_f2c(comm)

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
        c_datatype = handle_mpi_datatype_f2c(datatype)
        c_op = handle_mpi_op_f2c(op)

        c_comm = handle_mpi_comm_f2c(comm)

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
        c_datatype = handle_mpi_datatype_f2c(datatype)
        c_op = handle_mpi_op_f2c(op)

        c_comm = handle_mpi_comm_f2c(comm)
 
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
        use mpi_c_bindings, only: c_mpi_allreduce, c_mpi_comm_f2c
        integer, dimension(:), intent(in), target :: sendbuf
        integer, dimension(:), intent(out), target :: recvbuf
        integer, intent(in) :: count, datatype, op, comm
        integer, intent(out), optional :: ierror
        type(c_ptr) :: sendbuf_ptr, recvbuf_ptr
        integer(kind=MPI_HANDLE_KIND) :: c_datatype, c_op, c_comm
        integer(c_int) :: local_ierr

        sendbuf_ptr = c_loc(sendbuf)
        recvbuf_ptr = c_loc(recvbuf)
        c_datatype = handle_mpi_datatype_f2c(datatype)
        c_op = handle_mpi_op_f2c(op)

        c_comm = handle_mpi_comm_f2c(comm)

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
        use mpi_c_bindings, only: c_mpi_allreduce, c_mpi_comm_f2c
        logical, intent(in), target :: sendbuf
        logical, intent(out), target :: recvbuf
        integer, intent(in) :: count, datatype, op, comm
        integer, intent(out), optional :: ierror
        type(c_ptr) :: sendbuf_ptr, recvbuf_ptr
        integer(kind=MPI_HANDLE_KIND) :: c_datatype, c_op, c_comm
        integer(c_int) :: local_ierr

        sendbuf_ptr = c_loc(sendbuf)
        recvbuf_ptr = c_loc(recvbuf)
        c_datatype = handle_mpi_datatype_f2c(datatype)
        c_op = handle_mpi_op_f2c(op)

        c_comm = handle_mpi_comm_f2c(comm)

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

        c_comm = handle_mpi_comm_f2c(comm)

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

        c_comm = handle_mpi_comm_f2c(comm)
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
        use mpi_c_bindings, only: c_mpi_comm_split_type, c_mpi_comm_c2f
        integer, intent(in) :: comm
        integer, intent(in) :: split_type, key
        integer, intent(in) :: info
        integer, intent(out) :: newcomm
        integer, optional, intent(out) :: ierror
    
        integer(c_int) :: local_ierr
        integer(kind=MPI_HANDLE_KIND) :: c_comm, c_info, c_new_comm

        c_comm = handle_mpi_comm_f2c(comm)
        c_info = handle_mpi_info_f2c(info)

        ! Call the native MPI_Comm_split_type.
        local_ierr = c_mpi_comm_split_type(c_comm, split_type, key, c_info, c_new_comm)

        ! Convert the new communicator C handle back to a Fortran integer handle.
        newcomm = c_mpi_comm_c2f(c_new_comm)
    
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
        use mpi_c_bindings, only: c_mpi_recv, c_mpi_status_c2f
        real(8), dimension(*), intent(inout), target :: buf
        integer, intent(in)  :: count, source, tag, datatype, comm
        integer, intent(out) :: status(MPI_STATUS_SIZE)
        integer, optional, intent(out) :: ierror
    
        integer(c_int) :: local_ierr, status_ierr
        integer(kind=MPI_HANDLE_KIND) :: c_dtype, c_comm
        type(c_ptr) :: c_status
        integer(c_int), dimension(MPI_STATUS_SIZE), target :: tmp_status

        ! Convert Fortran handles to C handles.
        c_dtype = handle_mpi_datatype_f2c(datatype)

        c_comm = handle_mpi_comm_f2c(comm)

        ! Use a local temporary MPI_Status (as an array of c_int)
        c_status = c_loc(tmp_status)

        ! Call the native MPI_Recv.
        local_ierr = c_mpi_recv(c_loc(buf), count, c_dtype, source, tag, c_comm, c_status)

        ! Convert the C MPI_Status to Fortran status.
        if (local_ierr == MPI_SUCCESS) then
          status_ierr =  c_mpi_status_c2f(c_status, status)
        end if

        if (present(ierror)) then
            ierror = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Recv failed with error code: ", local_ierr
        end if
    
    end subroutine MPI_Recv_StatusArray_proc

    subroutine MPI_Recv_StatusIgnore_proc(buf, count, datatype, source, tag, comm, status, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_recv, c_mpi_status_c2f
        real(8), dimension(*), intent(inout), target :: buf
        integer, intent(in)  :: count, source, tag, datatype, comm
        integer, intent(out) :: status
        integer, optional, intent(out) :: ierror
    
        integer(c_int) :: local_ierr, status_ierr
        integer(kind=MPI_HANDLE_KIND) :: c_dtype, c_comm
        type(c_ptr) :: c_status
        integer(c_int), dimension(MPI_STATUS_SIZE), target :: tmp_status

        ! Convert Fortran handles to C handles.
        c_dtype = handle_mpi_datatype_f2c(datatype)

        c_comm = handle_mpi_comm_f2c(comm)

        ! Use a local temporary MPI_Status (as an array of c_int)
        c_status = c_loc(tmp_status)

        ! Call the native MPI_Recv.
        local_ierr = c_mpi_recv(c_loc(buf), count, c_dtype, source, tag, c_comm, c_status)

        ! Convert the C MPI_Status to Fortran status.
        if (local_ierr == MPI_SUCCESS) then
        !   status_ierr =  c_mpi_status_c2f(c_status, status)
        end if

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
        c_sendtype = handle_mpi_datatype_f2c(sendtype)
        c_recvtype = handle_mpi_datatype_f2c(recvtype)
        c_comm = handle_mpi_comm_f2c(comm)

        ! Call C MPI_Gatherv
        local_ierr = c_mpi_gatherv(c_sendbuf, sendcount, c_sendtype, &
                                   c_recvbuf, recvcounts, displs, c_recvtype, &
                                   root, c_comm)

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
        c_sendtype = handle_mpi_datatype_f2c(sendtype)
        c_recvtype = handle_mpi_datatype_f2c(recvtype)
        c_comm = handle_mpi_comm_f2c(comm)

        ! Call C MPI_Gatherv
        local_ierr = c_mpi_gatherv(c_sendbuf, sendcount, c_sendtype, &
                                   c_recvbuf, recvcounts, displs, c_recvtype, &
                                   root, c_comm)

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
        c_sendtype = handle_mpi_datatype_f2c(sendtype)
        c_recvtype = handle_mpi_datatype_f2c(recvtype)
        c_comm = handle_mpi_comm_f2c(comm)

        ! Call C MPI_Gatherv
        local_ierr = c_mpi_gatherv(c_sendbuf, sendcount, c_sendtype, &
                                   c_recvbuf, recvcounts, displs, c_recvtype, &
                                   root, c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Gatherv failed with error code: ", local_ierr
        end if
    end subroutine MPI_Gatherv_character

    subroutine MPI_Wait_proc(request, status, ierror)
        use iso_c_binding, only: c_int, c_ptr, c_loc
        use mpi_c_bindings, only: c_mpi_wait, c_mpi_request_f2c, c_mpi_request_c2f, c_mpi_status_c2f
        integer, intent(inout) :: request
        integer, intent(out) :: status(MPI_STATUS_SIZE)
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_request
        integer(c_int) :: local_ierr, status_ierr
        type(c_ptr) :: c_status
        integer(c_int), dimension(MPI_STATUS_SIZE), target :: tmp_status

        c_request = c_mpi_request_f2c(request)
        c_status = c_loc(tmp_status)

        local_ierr = c_mpi_wait(c_request, c_status)

        request = c_mpi_request_c2f(c_request)

        if (local_ierr == MPI_SUCCESS) then
            status_ierr = c_mpi_status_c2f(c_status, status)
        end if

        if (present(ierror)) then
            ierror = local_ierr
        else if (local_ierr /= MPI_SUCCESS) then
            print *, "MPI_Wait failed with error code: ", local_ierr
        end if
    end subroutine MPI_Wait_proc

    subroutine MPI_Waitall_proc(count, array_of_requests, array_of_statuses, ierror)
        use iso_c_binding, only: c_int, c_ptr
        use mpi_c_bindings, only: c_mpi_waitall, c_mpi_request_f2c, c_mpi_request_c2f, c_mpi_status_c2f, c_mpi_statuses_ignore
        integer, intent(in) :: count
        integer, dimension(count), intent(inout) :: array_of_requests
        integer, dimension(*), intent(out) :: array_of_statuses
        integer, optional, intent(out) :: ierror
        integer :: arr_request_item_kind_4
        integer(kind=MPI_HANDLE_KIND) :: arr_request_item_kind_mpi_handle_kind

        integer(c_int) :: local_ierr, status_ierr
        integer :: i

        ! Allocate temporary arrays for the C representations.
        integer(kind=MPI_HANDLE_KIND), dimension(count) :: c_requests
        type(c_ptr) :: MPI_STATUSES_IGNORE_from_c

        MPI_STATUSES_IGNORE_from_c = c_mpi_statuses_ignore

        ! Convert Fortran requests to C requests.
        do i = 1, count
            arr_request_item_kind_4 = array_of_requests(i)
            c_requests(i) = c_mpi_request_f2c(arr_request_item_kind_4)
        end do

        ! Call the native MPI_Waitall.
        local_ierr = c_mpi_waitall(count, c_requests, MPI_STATUSES_IGNORE_from_c)

        ! Convert the C requests back to Fortran handles.
        do i = 1, count
            arr_request_item_kind_mpi_handle_kind = c_requests(i)
            array_of_requests(i) = c_mpi_request_c2f(arr_request_item_kind_mpi_handle_kind)
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
        c_sendtype = handle_mpi_datatype_f2c(sendtype)
        c_recvtype = handle_mpi_datatype_f2c(recvtype)
        c_comm = handle_mpi_comm_f2c(comm)

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
        c_sendtype = handle_mpi_datatype_f2c(sendtype)
        c_recvtype = handle_mpi_datatype_f2c(recvtype)
        c_comm = handle_mpi_comm_f2c(comm)

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
        use mpi_c_bindings, only: c_mpi_scatter
        real(8), dimension(:), intent(in), target :: sendbuf
        integer, intent(in) :: sendcount
        integer, intent(in) :: sendtype
        real(8), dimension(:), intent(out), target :: recvbuf
        integer, intent(in) :: recvcount
        integer, intent(in) :: recvtype
        integer, intent(in) :: root
        integer, intent(in) :: comm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_sendtype, c_recvtype, c_comm
        type(c_ptr) :: c_sendbuf, c_recvbuf
        integer(c_int) :: local_ierr

        c_sendbuf = c_loc(sendbuf)
        c_recvbuf = c_loc(recvbuf)
        c_sendtype = handle_mpi_datatype_f2c(sendtype)
        c_recvtype = handle_mpi_datatype_f2c(recvtype)
        c_comm = handle_mpi_comm_f2c(comm)

        local_ierr = c_mpi_scatter(c_sendbuf, sendcount, c_sendtype, &
                                   c_recvbuf, recvcount, c_recvtype, &
                                   root, c_comm)

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

        c_datatype = handle_mpi_datatype_f2c(datatype)
        c_comm = handle_mpi_comm_f2c(comm)
        local_ierr = c_mpi_ssend(buf, count, c_datatype, dest, tag, c_comm)
    end subroutine

    subroutine MPI_Cart_create_proc(comm_old, ndims, dims, periods, reorder, comm_cart, ierror)
        use iso_c_binding, only: c_int, c_ptr
        use mpi_c_bindings, only: c_mpi_cart_create, c_mpi_comm_c2f
        integer, intent(in) :: ndims, dims(ndims)
        logical, intent(in) :: periods(ndims), reorder
        integer, intent(in) :: comm_old
        integer, intent(out) :: comm_cart
        integer, optional, intent(out) :: ierror
        integer(c_int) :: ndims_c, reorder_c, dims_c(ndims), periods_c(ndims)
        integer(kind=MPI_HANDLE_KIND) :: c_comm_old
        integer(kind=MPI_HANDLE_KIND) :: c_comm_cart
        integer(c_int) :: local_ierr

        c_comm_old = handle_mpi_comm_f2c(comm_old)

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
        comm_cart = c_mpi_comm_c2f(c_comm_cart)

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

        c_comm = handle_mpi_comm_f2c(comm)

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
        use mpi_c_bindings, only: c_mpi_cart_shift, c_mpi_comm_f2c
        integer, intent(in) :: comm
        integer, intent(in) :: direction, disp
        integer, intent(out) :: rank_source, rank_dest
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_comm
        integer(c_int) :: local_ierr

        c_comm = handle_mpi_comm_f2c(comm)

        local_ierr = c_mpi_cart_shift(c_comm, direction, disp, rank_source, rank_dest)

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
        use mpi_c_bindings, only: c_mpi_cart_sub, c_mpi_comm_c2f
        integer, intent(in) :: comm
        logical, intent(in) :: remain_dims(:)
        integer, intent(out) :: newcomm
        integer, optional, intent(out) :: ierror
        integer, target :: remain_dims_i(size(remain_dims))
        integer(kind=MPI_HANDLE_KIND) :: c_comm, c_newcomm
        integer :: local_ierr
        type(c_ptr) :: remain_dims_i_ptr

        c_comm = handle_mpi_comm_f2c(comm)

        where (remain_dims)
            remain_dims_i = 1
        elsewhere
            remain_dims_i = 0
        end where
        remain_dims_i_ptr = c_loc(remain_dims_i)
        local_ierr = c_mpi_cart_sub(c_comm, remain_dims_i_ptr, c_newcomm)

        newcomm = c_mpi_comm_c2f(c_newcomm)

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

        c_comm = handle_mpi_comm_f2c(comm)
        c_dtype = handle_mpi_datatype_f2c(datatype)
        c_op = handle_mpi_op_f2c(op)

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

        c_comm = handle_mpi_comm_f2c(comm)

        c_dtype = handle_mpi_datatype_f2c(datatype)
        c_op    = handle_mpi_op_f2c(op)

        ! Pass pointer to the actual data
        c_sendbuf = c_loc(sendbuf)
        c_recvbuf = c_loc(recvbuf)

        local_ierr = c_mpi_reduce(c_sendbuf, c_recvbuf, count, c_dtype, c_op, root, c_comm)

        if (present(ierror)) then
            ierror = local_ierr
        else
            if (local_ierr /= MPI_SUCCESS) then
                print *, "MPI_Reduce failed with error code: ", local_ierr
            end if
        end if
    end subroutine MPI_Reduce_scalar_int
end module mpi
