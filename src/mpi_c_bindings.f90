module mpi_c_bindings
    use iso_c_binding, only: c_ptr
    implicit none

#ifdef OPEN_MPI
#define MPI_HANDLE_KIND 8
#else
#define MPI_HANDLE_KIND 4
#endif

    integer, parameter :: mpi_handle_kind = MPI_HANDLE_KIND
    type(c_ptr), bind(C, name="c_MPI_STATUSES_IGNORE") :: c_mpi_statuses_ignore
    type(c_ptr), bind(C, name="c_MPI_IN_PLACE") :: c_mpi_in_place
    integer(kind=MPI_HANDLE_KIND), bind(C, name="c_MPI_INFO_NULL") :: c_mpi_info_null
    integer(kind=MPI_HANDLE_KIND), bind(C, name="c_MPI_DOUBLE") :: c_mpi_double
    integer(kind=MPI_HANDLE_KIND), bind(C, name="c_MPI_FLOAT") :: c_mpi_float
    integer(kind=MPI_HANDLE_KIND), bind(C, name="c_MPI_INT") :: c_mpi_int
    integer(kind=MPI_HANDLE_KIND), bind(C, name="c_MPI_COMM_WORLD") :: c_mpi_comm_world
    integer(kind=MPI_HANDLE_KIND), bind(C, name="c_MPI_SUM") :: c_mpi_sum

    interface

        function c_mpi_comm_f2c(comm_f) bind(C, name="MPI_Comm_f2c")
            use iso_c_binding, only: c_int, c_ptr
            integer(c_int), value :: comm_f
            integer(kind=MPI_HANDLE_KIND) :: c_mpi_comm_f2c
        end function c_mpi_comm_f2c

        function c_mpi_comm_c2f(comm_c) bind(C, name="MPI_Comm_c2f")
            use iso_c_binding, only: c_int, c_ptr
            integer(kind=MPI_HANDLE_KIND), value :: comm_c
            integer(c_int) :: c_mpi_comm_c2f
        end function

        function c_mpi_request_c2f(request) bind(C, name="MPI_Request_c2f")
            use iso_c_binding, only: c_int, c_ptr
            integer(kind=MPI_HANDLE_KIND), value :: request
            integer(c_int) :: c_mpi_request_c2f
        end function

        function c_mpi_request_f2c(request) bind(C, name="MPI_Request_f2c")
            use iso_c_binding, only: c_int, c_ptr
            integer(c_int), value :: request
            integer(kind=MPI_HANDLE_KIND) :: c_mpi_request_f2c
        end function c_mpi_request_f2c

        function c_mpi_status_c2f(c_status, f_status) bind(C, name="MPI_Status_c2f")
            use iso_c_binding, only: c_ptr, c_int
            type(c_ptr) :: c_status
            integer(c_int) :: f_status(*)  ! assumed-size array
            integer(c_int) :: c_mpi_status_c2f
        end function c_mpi_status_c2f

        function c_mpi_op_f2c(op_f) bind(C, name="MPI_Op_f2c")
            use iso_c_binding, only: c_ptr, c_int
            integer(c_int), value :: op_f
            integer(kind=MPI_HANDLE_KIND) :: c_mpi_op_f2c
        end function c_mpi_op_f2c

        function c_mpi_info_f2c(info_f) bind(C, name="MPI_Info_f2c")
            use iso_c_binding, only: c_int, c_ptr
            integer(c_int), value :: info_f
            integer(kind=MPI_HANDLE_KIND) :: c_mpi_info_f2c
        end function c_mpi_info_f2c

        function c_mpi_init(argc, argv) bind(C, name="MPI_Init")
            use iso_c_binding, only : c_int, c_ptr
            !> TODO: is the intent need to be explicitly specified
            !> as 'intent(inout)'? Though, currently LFortran
            !> errors with this
            integer(c_int) :: argc
            type(c_ptr) :: argv
            integer(c_int) :: c_mpi_init
        end function c_mpi_init

        function c_mpi_init_thread(argc, argv, required, provided) bind(C, name="MPI_Init_thread")
            use iso_c_binding, only: c_int, c_ptr
            integer(c_int) :: argc
            type(c_ptr) :: argv
            integer(c_int), value :: required
            integer(c_int), intent(out) :: provided
            integer(c_int) :: c_mpi_init_thread
        end function c_mpi_init_thread

        integer(c_int) function c_mpi_finalize() bind(C, name="MPI_Finalize")
            use iso_c_binding, only : c_int
        end function c_mpi_finalize

        function c_mpi_comm_size(comm, size) bind(C, name="MPI_Comm_size")
            use iso_c_binding, only: c_int, c_ptr
            integer(kind=MPI_HANDLE_KIND), value :: comm
            integer(c_int), intent(out) :: size
            integer(c_int) :: c_mpi_comm_size
        end function c_mpi_comm_size

        function c_mpi_bcast(buffer, count, datatype, root, comm) bind(C, name="MPI_Bcast")
            use iso_c_binding, only : c_ptr, c_int
            type(c_ptr), value :: buffer
            integer(c_int), value :: count
            integer(kind=MPI_HANDLE_KIND), value :: datatype
            integer(c_int), value :: root
            integer(kind=MPI_HANDLE_KIND), value :: comm
            integer(c_int) :: c_mpi_bcast
        end function c_mpi_bcast

        function c_mpi_allgather_int(sendbuf, sendcount, sendtype, recvbuf, &
            recvcount, recvtype, comm) bind(C, name="MPI_Allgather")
            use iso_c_binding, only: c_int, c_ptr
            type(c_ptr), value :: sendbuf
            type(c_ptr), value :: recvbuf
            integer(c_int), value :: sendcount, recvcount
            integer(kind=MPI_HANDLE_KIND), value :: sendtype, recvtype
            integer(kind=MPI_HANDLE_KIND), value :: comm
            integer(c_int) :: c_mpi_allgather_int
        end function

        function c_mpi_allgather_real(sendbuf, sendcount, sendtype, recvbuf, &
            recvcount, recvtype, comm) bind(C, name="MPI_Allgather")
            use iso_c_binding, only: c_int, c_ptr
            type(c_ptr), value :: sendbuf
            type(c_ptr), value :: recvbuf
            integer(c_int), value :: sendcount, recvcount
            integer(kind=MPI_HANDLE_KIND), value :: sendtype, recvtype
            integer(kind=MPI_HANDLE_KIND), value :: comm
            integer(c_int) :: c_mpi_allgather_real
        end function

        function c_mpi_isend(buf, count, datatype, dest, tag, comm, request) bind(C, name="MPI_Isend")
            use iso_c_binding, only: c_int, c_double, c_ptr
            type(c_ptr), value :: buf
            integer(c_int), value :: count, dest, tag
            integer(kind=MPI_HANDLE_KIND), value :: datatype
            integer(kind=MPI_HANDLE_KIND), value :: comm
            integer(kind=MPI_HANDLE_KIND), intent(out) :: request
            integer(c_int) :: c_mpi_isend
        end function

        function c_mpi_irecv(buf, count, datatype, source, tag, comm, request) bind(C, name="MPI_Irecv")
            use iso_c_binding, only: c_int, c_double, c_ptr
            real(c_double), dimension(*), intent(out) :: buf
            integer(c_int), value :: count, source, tag
           integer(kind=MPI_HANDLE_KIND), value :: datatype
           integer(kind=MPI_HANDLE_KIND), value :: comm
           integer(kind=MPI_HANDLE_KIND), intent(out) :: request
            integer(c_int) :: c_mpi_irecv
        end function

        function c_mpi_allreduce(sendbuf, recvbuf, count, datatype, op, comm) &
                                                    bind(C, name="MPI_Allreduce")
            use iso_c_binding, only: c_int, c_double, c_ptr
            type(c_ptr), value :: sendbuf
            type(c_ptr), value :: recvbuf
            integer(c_int), value :: count
            integer(kind=MPI_HANDLE_KIND), value :: datatype, op, comm
            integer(c_int) :: c_mpi_allreduce
        end function

        function c_mpi_wtime() result(time) bind(C, name="MPI_Wtime")
            use iso_c_binding, only: c_double
            real(c_double) :: time
        end function

        function c_mpi_barrier(comm) bind(C, name="MPI_Barrier")
            use iso_c_binding, only: c_ptr, c_int
            integer(kind=MPI_HANDLE_KIND), value :: comm      ! MPI_Comm as pointer
            integer(c_int) :: c_mpi_barrier
        end function c_mpi_barrier

        function c_mpi_comm_rank(comm, rank) bind(C, name="MPI_Comm_rank")
            use iso_c_binding, only: c_int, c_ptr
            integer(kind=MPI_HANDLE_KIND), value :: comm
            integer(c_int), intent(out) :: rank
            integer(c_int) :: c_mpi_comm_rank
        end function c_mpi_comm_rank

        function c_mpi_comm_split_type(c_comm, split_type, key, c_info, new_comm) bind(C, name="MPI_Comm_split_type")
            use iso_c_binding, only: c_ptr, c_int
            integer(kind=MPI_HANDLE_KIND), value :: c_comm
            integer(c_int), value :: split_type
            integer(c_int), value :: key
            integer(kind=MPI_HANDLE_KIND), value :: c_info
            integer(kind=MPI_HANDLE_KIND) :: new_comm
            integer(c_int) :: c_mpi_comm_split_type
        end function c_mpi_comm_split_type

        function c_mpi_recv(buf, count, c_dtype, source, tag, c_comm, status) bind(C, name="MPI_Recv")
            use iso_c_binding, only: c_ptr, c_int, c_double
            type(c_ptr), value :: buf
            integer(c_int), value :: count
            integer(kind=MPI_HANDLE_KIND), value :: c_dtype
            integer(c_int), value :: source
            integer(c_int), value :: tag
            integer(kind=MPI_HANDLE_KIND), value :: c_comm
            type(c_ptr), value :: status
            integer(c_int) :: c_mpi_recv
        end function c_mpi_recv

        function c_mpi_waitall(count, requests, statuses) bind(C, name="MPI_Waitall")
            use iso_c_binding, only: c_int, c_ptr
            integer(c_int), value :: count
            integer(kind=MPI_HANDLE_KIND), dimension(*), intent(inout) :: requests
            type(c_ptr), value :: statuses
            integer(c_int) :: c_mpi_waitall
        end function c_mpi_waitall

        function c_mpi_ssend(buf, count, datatype, dest, tag, comm) bind(C, name="MPI_Ssend")
            use iso_c_binding, only: c_int, c_double, c_ptr
            real(c_double), dimension(*), intent(in) :: buf
            integer(c_int), value :: count, dest, tag
            integer(kind=MPI_HANDLE_KIND), value :: datatype
            integer(kind=MPI_HANDLE_KIND), value :: comm
            integer(c_int) :: c_mpi_ssend
        end function

        function c_mpi_cart_create(comm_old, ndims, dims, periods, reorder, comm_cart) bind(C, name="MPI_Cart_create")
            use iso_c_binding, only: c_int, c_ptr
            integer(kind=MPI_HANDLE_KIND), value :: comm_old
            integer(c_int), value :: ndims, reorder
            integer(c_int), intent(in) :: dims(*), periods(*)
            integer(kind=MPI_HANDLE_KIND), intent(out) :: comm_cart
            integer(c_int) :: c_mpi_cart_create
        end function

        function c_mpi_cart_coords(comm, rank, maxdims, coords) bind(C, name="MPI_Cart_coords")
            use iso_c_binding,  only: c_int, c_ptr
            integer(kind=MPI_HANDLE_KIND), value :: comm
            integer(c_int), value :: rank, maxdims
            integer(c_int), intent(out) :: coords(*)
            integer(c_int) :: c_mpi_cart_coords
        end function

        function c_mpi_cart_shift(comm, direction, disp, rank_source, rank_dest) bind(C, name="MPI_Cart_shift")
            use iso_c_binding, only: c_int, c_ptr
            integer(kind=MPI_HANDLE_KIND), value :: comm
            integer(c_int), value :: direction, disp
            integer(c_int), intent(out) :: rank_source, rank_dest
            integer(c_int) :: c_mpi_cart_shift
        end function

        function c_mpi_dims_create(nnodes, ndims, dims) bind(C, name="MPI_Dims_create")
            use iso_c_binding, only: c_int, c_ptr
            integer(c_int), value :: nnodes, ndims
            integer(c_int), intent(inout) :: dims(*)
            integer(c_int) :: c_mpi_dims_create
        end function

        function c_mpi_cart_sub(comm, remain_dims, newcomm) bind(C, name ="MPI_Cart_sub")
            use iso_c_binding, only: c_int, c_ptr
            integer(kind=MPI_HANDLE_KIND), value :: comm
            type(c_ptr), value :: remain_dims
            integer(kind=MPI_HANDLE_KIND), intent(out) :: newcomm
            integer(c_int) :: c_mpi_cart_sub
        end function

        function c_mpi_reduce(sendbuf, recvbuf, count, c_dtype, c_op, root, c_comm) &
            bind(C, name="MPI_Reduce")
            use iso_c_binding, only: c_ptr, c_int

            type(c_ptr), value :: sendbuf
            type(c_ptr), value :: recvbuf
            integer(c_int), value :: count
            integer(kind=MPI_HANDLE_KIND), value :: c_dtype
            integer(kind=MPI_HANDLE_KIND), value :: c_op
            integer(c_int), value :: root
            integer(kind=MPI_HANDLE_KIND), value :: c_comm
           integer(c_int) :: c_mpi_reduce
        end function c_mpi_reduce

    end interface
end module mpi_c_bindings
