program allreduce_min_op_01
    use mpi
    implicit none

    integer :: ierr, rank
    integer(kind=MPI_INTEGER_KIND) :: sendbuf(1), recvbuf(1)

    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Init failed'
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Comm_rank failed'

    sendbuf(1) = rank + 10
    call MPI_Allreduce(sendbuf, recvbuf, 1, MPI_INTEGER, MPI_MIN, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS .or. recvbuf(1) /= 10) &
        error stop 'MPI_MIN allreduce failed'

    if (rank == 0) print *, 'MPI_Allreduce with MPI_MIN passed'
    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Finalize failed'
end program allreduce_min_op_01
