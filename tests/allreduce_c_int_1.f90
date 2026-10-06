program allreduce_c_int_1
    use mpi
    use iso_c_binding, only: c_int
    implicit none

    integer :: ierr, rank, nprocs
    integer(c_int) :: sendbuf(1), recvbuf(1), expected

    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Init failed'
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Comm_rank failed'
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Comm_size failed'

    sendbuf(1) = int(rank+1, c_int)
    expected = int(nprocs*(nprocs+1)/2, c_int)
    call MPI_Allreduce(sendbuf, recvbuf, 1, MPI_INT, MPI_SUM, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS .or. recvbuf(1) /= expected) &
        error stop 'C integer allreduce failed'

    if (rank == 0) print *, 'MPI_Allreduce with MPI_INT passed'
    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Finalize failed'
end program allreduce_c_int_1
