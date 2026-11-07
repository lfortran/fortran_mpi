program send_recv_scalar_ignore_1
    use mpi
    use iso_c_binding, only: c_float, c_double
    implicit none

    integer :: ierr, rank, nprocs
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
        call MPI_Send(single_value, 1, MPI_REAL4, 1, 17, MPI_COMM_WORLD, ierr)
        if (ierr /= MPI_SUCCESS) error stop 'Scalar real4 send failed'
        call MPI_Send(double_value, 1, MPI_REAL8, 1, 18, MPI_COMM_WORLD, ierr)
        if (ierr /= MPI_SUCCESS) error stop 'Scalar real8 send failed'
    else if (rank == 1) then
        call MPI_Recv(single_value, 1, MPI_REAL4, 0, 17, MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
        if (ierr /= MPI_SUCCESS .or. single_value /= 123.25_c_float) &
            error stop 'Scalar real4 receive with MPI_STATUS_IGNORE failed'
        call MPI_Recv(double_value, 1, MPI_REAL8, 0, 18, MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
        if (ierr /= MPI_SUCCESS .or. double_value /= 456.125_c_double) &
            error stop 'Scalar real8 receive with MPI_STATUS_IGNORE failed'
        print *, 'Scalar real4 and real8 receives with MPI_STATUS_IGNORE passed'
    end if

    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Finalize failed'
end program send_recv_scalar_ignore_1
