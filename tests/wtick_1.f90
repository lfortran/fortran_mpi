program wtick_1
    ! MPI_Wtick: the resolution of MPI_Wtime, in seconds
    use mpi
    implicit none
    integer :: ierr, rank
    real(8) :: tick

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)

    tick = MPI_Wtick()
    if (.not. (tick > 0 .and. tick <= 1)) then
        print *, "MPI_Wtick() =", tick
        error stop "MPI_Wtick: not in (0, 1] seconds"
    end if
    if (MPI_Wtick() /= tick) error stop "MPI_Wtick: changed between two calls"

    if (rank == 0) print *, "wtick_1: OK, MPI_Wtick() =", tick
    call MPI_Finalize(ierr)
end program wtick_1
