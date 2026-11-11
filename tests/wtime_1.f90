program wtime_1
    use, intrinsic:: iso_fortran_env, only: dp=>real64
    use mpi
    implicit none
    integer :: id, Nproc, ierr
    integer(8) :: i
    real(dp) :: wtime, t0, t1

    !>  Initialize MPI.
    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Init failed"

    !>  Get the number of processes.
    call MPI_Comm_size(MPI_COMM_WORLD, Nproc, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Comm_size failed"

    !>  Get the individual process ID.
    call MPI_Comm_rank(MPI_COMM_WORLD, id, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Comm_rank failed"

    wtime = MPI_Wtime()
    !>  Print a message.
    if (id == 0) then
        print *, 'number of processes: ', Nproc
    end if

    !>  Wait until the clock ticks. MPI_Wtime is in seconds, so a tick is
    !>  short, and the clock never goes backwards.
    t0 = MPI_Wtime()
    t1 = t0
    do i = 1, 1000000000_8
        t1 = MPI_Wtime()
        if (t1 /= t0) exit
    end do
    if (t1 < t0) error stop "MPI_Wtime went backwards"
    if (t1 == t0) error stop "MPI_Wtime does not advance"
    if (t1 - t0 > 1.0_dp) then
        print *, 'MPI_Wtime ticked from ', t0, ' to ', t1
        error stop "MPI_Wtime tick longer than a second"
    end if

    wtime = MPI_Wtime() - wtime
    if (id == 0) then
        print *, 'Elapsed wall clock time = ', wtime, ' seconds.'
    end if
    if (wtime < 0 .or. wtime > 60) then
        print *, 'Elapsed wall clock time = ', wtime, ' seconds.'
        error stop "wrong elapsed time from MPI_Wtime"
    end if

    !>  Shut down MPI.
    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Finalize failed"

end program
