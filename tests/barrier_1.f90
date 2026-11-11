program barrier_1
    use mpi
    implicit none

    integer :: rank, size, ierr, i

    ! Initialize MPI
    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Init failed"

    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Comm_rank failed"
    call MPI_Comm_size(MPI_COMM_WORLD, size, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Comm_size failed"

    print *, "Process ", rank, " reached before the barrier."

    ! Synchronize all processes at this point, several times in a row
    do i = 1, 3
        call MPI_Barrier(MPI_COMM_WORLD, ierr)
        if (ierr /= MPI_SUCCESS) error stop "MPI_Barrier(MPI_COMM_WORLD) failed"
    end do

    print *, "Process ", rank, " passed the barrier."

    call MPI_Barrier(MPI_COMM_SELF, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Barrier(MPI_COMM_SELF) failed"

    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Finalize failed"

end program
