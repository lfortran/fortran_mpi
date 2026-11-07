program allreduce_real4_scalar_1
    use mpi
    use iso_c_binding, only: c_float
    implicit none

    integer :: ierr, rank, nprocs
    real(c_float) :: sendbuf, recvbuf, expected

    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Init failed'
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Comm_rank failed'
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Comm_size failed'

    sendbuf = real(rank+1, c_float)
    expected = real(nprocs*(nprocs+1)/2, c_float)
    call MPI_Allreduce(sendbuf, recvbuf, 1, MPI_REAL4, MPI_SUM, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS .or. recvbuf /= expected) &
        error stop 'Scalar real4 allreduce failed'

    if (rank == 0) print *, 'Scalar real4 allreduce passed'
    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Finalize failed'
end program allreduce_real4_scalar_1
