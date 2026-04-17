program initialized_1
    use mpi
    implicit none
    integer :: ierr
    logical :: flag

    call MPI_Initialized(flag, ierr)
    if (ierr /= MPI_SUCCESS) then
        print *, "MPI_Initialized (before init) failed with error code: ", ierr
        error stop 1
    end if
    if (flag) then
        print *, "MPI_Initialized reported TRUE before MPI_Init"
        error stop 2
    end if

    call MPI_Init(ierr)

    call MPI_Initialized(flag, ierr)
    if (ierr /= MPI_SUCCESS) then
        print *, "MPI_Initialized (after init) failed with error code: ", ierr
        error stop 3
    end if
    if (.not. flag) then
        print *, "MPI_Initialized reported FALSE after MPI_Init"
        error stop 4
    end if

    print *, "MPI_Initialized test passed"

    call MPI_Finalize(ierr)
end program initialized_1
