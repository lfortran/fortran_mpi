program init_2
    use mpi, only: MPI_Init_thread, MPI_Finalize, MPI_THREAD_SINGLE, &
        MPI_THREAD_FUNNELED, MPI_THREAD_SERIALIZED, MPI_THREAD_MULTIPLE
    implicit none
    
    integer :: provided, ierr
    
    ! Initialize MPI with thread support
    call MPI_Init_thread(MPI_THREAD_FUNNELED, provided, ierr)
    
    if (ierr /= 0) then
        print *, "Error initializing MPI with threads"
        error stop
    end if
    if (provided /= MPI_THREAD_SINGLE .and. provided /= MPI_THREAD_FUNNELED .and. &
        provided /= MPI_THREAD_SERIALIZED .and. provided /= MPI_THREAD_MULTIPLE) then
        print *, "MPI_Init_thread returned an invalid thread level", provided
        error stop
    end if
    print *, "Running MPI with thread support"

    ! Finalize MPI
    call MPI_Finalize(ierr)
end program init_2
