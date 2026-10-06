program comm_split_1
    use mpi
    implicit none

    integer :: ierr, rank, group, group_size

    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Init failed'
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Comm_rank failed'

    call MPI_Comm_split(MPI_COMM_WORLD, rank, rank, group, ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Comm_split failed'
    call MPI_Comm_size(group, group_size, ierr)
    if (ierr /= MPI_SUCCESS .or. group_size /= 1) &
        error stop 'Incorrect split communicator size'
    call MPI_Comm_free(group, ierr)
    if (ierr /= MPI_SUCCESS .or. group /= MPI_COMM_NULL) &
        error stop 'MPI_Comm_free failed'

    if (rank == 0) print *, 'Communicator splitting passed'
    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Finalize failed'
end program comm_split_1
