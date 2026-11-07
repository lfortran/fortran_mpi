program comm_split_undefined_1
    use mpi
    implicit none

    integer :: ierr, rank, color, group, group_size

    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Init failed'
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Comm_rank failed'

    color = MPI_UNDEFINED
    if (rank == 0) color = 0
    call MPI_Comm_split(MPI_COMM_WORLD, color, rank, group, ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Comm_split failed'
    if (rank == 0) then
        call MPI_Comm_size(group, group_size, ierr)
        if (ierr /= MPI_SUCCESS .or. group_size /= 1) &
            error stop 'Incorrect split communicator size'
        call MPI_Comm_free(group, ierr)
        if (ierr /= MPI_SUCCESS) error stop 'MPI_Comm_free failed'
        print *, 'Communicator splitting with MPI_UNDEFINED passed'
    else
        if (group /= MPI_COMM_NULL) error stop 'Excluded rank received a communicator'
    end if

    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Finalize failed'
end program comm_split_undefined_1
