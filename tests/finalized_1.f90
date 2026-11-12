program finalized_1
    ! MPI_Finalized before MPI_Init, between MPI_Init and MPI_Finalize,
    ! and after MPI_Finalize
    use mpi
    implicit none
    integer :: ierr
    logical :: flag

    flag = .true.
    call MPI_Finalized(flag, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Finalized failed before MPI_Init"
    if (flag) error stop "MPI_Finalized is true before MPI_Init"

    call MPI_Init(ierr)
    flag = .true.
    call MPI_Finalized(flag, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Finalized failed"
    if (flag) error stop "MPI_Finalized is true before MPI_Finalize"
    call MPI_Initialized(flag, ierr)
    if (.not. flag) error stop "MPI_Initialized is false after MPI_Init"

    call MPI_Finalize(ierr)
    flag = .false.
    call MPI_Finalized(flag, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Finalized failed after MPI_Finalize"
    if (.not. flag) error stop "MPI_Finalized is false after MPI_Finalize"
    print *, "finalized_1: OK"
end program finalized_1
