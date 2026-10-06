program bcast_character_1
    use mpi
    implicit none

    integer :: ierr, rank
    character(len=5) :: text

    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Init failed'
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Comm_rank failed'

    text = 'xxxxx'
    if (rank == 0) text = 'hello'
    call MPI_Bcast(text, len(text), MPI_CHARACTER, 0, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS .or. text /= 'hello') &
        error stop 'Character broadcast failed'

    if (rank == 0) print *, 'Character broadcast passed'
    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Finalize failed'
end program bcast_character_1
