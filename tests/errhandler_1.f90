program errhandler_1
    ! With MPI_ERRORS_RETURN, an erroneous call returns an error code, whose
    ! class is MPI_ERR_ROOT and which has a message.
    use mpi
    implicit none
    integer :: ierr, ierr2, nprocs, buf, errorclass, resultlen
    character(len=MPI_MAX_ERROR_STRING) :: message

    call MPI_Init(ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    call MPI_Comm_set_errhandler(MPI_COMM_WORLD, MPI_ERRORS_RETURN, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Comm_set_errhandler failed"

    buf = 1
    ! The root is out of range
    call MPI_Bcast(buf, 1, MPI_INTEGER, nprocs, MPI_COMM_WORLD, ierr)
    if (ierr == MPI_SUCCESS) error stop "MPI_Bcast with an invalid root succeeded"

    call MPI_Error_class(ierr, errorclass, ierr2)
    if (ierr2 /= MPI_SUCCESS) error stop "MPI_Error_class failed"
    if (errorclass /= MPI_ERR_ROOT) then
        print *, "error class", errorclass, "expected MPI_ERR_ROOT =", MPI_ERR_ROOT
        error stop
    end if
    call MPI_Error_string(errorclass, message, resultlen, ierr)
    if (ierr /= MPI_SUCCESS .or. resultlen <= 0) error stop "MPI_Error_string failed"

    call MPI_Comm_set_errhandler(MPI_COMM_WORLD, MPI_ERRORS_ARE_FATAL, ierr)
    call MPI_Finalize(ierr)
end program errhandler_1
