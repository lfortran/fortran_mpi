program send_recv_scalar_1
    use mpi
    use iso_c_binding, only: c_float, c_double
    implicit none

    integer :: ierr, rank, nprocs, status(MPI_STATUS_SIZE)
    real(c_float) :: single_value
    real(c_double) :: double_value

    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Init failed'
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Comm_rank failed'
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Comm_size failed'

    if (nprocs < 2) then
        print *, 'Scalar send/receive requires at least two MPI processes'
    else if (rank == 0) then
        single_value = 123.25_c_float
        double_value = 456.125_c_double
        call MPI_Send(single_value, 1, MPI_FLOAT, 1, 17, MPI_COMM_WORLD, ierr)
        if (ierr /= MPI_SUCCESS) error stop 'Scalar real4 send failed'
        call MPI_Send(double_value, 1, MPI_DOUBLE, 1, 18, MPI_COMM_WORLD, ierr)
        if (ierr /= MPI_SUCCESS) error stop 'Scalar real8 send failed'
    else if (rank == 1) then
        call MPI_Recv(single_value, 1, MPI_FLOAT, 0, 17, MPI_COMM_WORLD, status, ierr)
        if (ierr /= MPI_SUCCESS .or. single_value /= 123.25_c_float) &
            error stop 'Scalar real4 receive failed'
        call check_status(status, 0, 17)
        call MPI_Recv(double_value, 1, MPI_DOUBLE, 0, 18, MPI_COMM_WORLD, status, ierr)
        if (ierr /= MPI_SUCCESS .or. double_value /= 456.125_c_double) &
            error stop 'Scalar real8 receive failed'
        call check_status(status, 0, 18)
        print *, 'Scalar real4 and real8 send/receive passed'
    end if

    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Finalize failed'

contains
    subroutine check_status(received_status, source, tag)
        integer, intent(in) :: received_status(MPI_STATUS_SIZE), source, tag
        logical :: correct

        ! Native INTEGER status layouts for Open MPI and MPICH, respectively.
        if (MPI_STATUS_SIZE == 6) then
            correct = received_status(1) == source .and. received_status(2) == tag
        else
            correct = received_status(3) == source .and. received_status(4) == tag
        end if
        if (.not. correct) then
            print *, 'Incorrect source or tag in receive status'
            call MPI_Abort(MPI_COMM_WORLD, 1, ierr)
            error stop 'MPI_Abort returned'
        end if
    end subroutine check_status
end program send_recv_scalar_1
