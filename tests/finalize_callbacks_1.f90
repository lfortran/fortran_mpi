function fmpi_finalizer_logical_probe() bind(C) result(result)
    use mpi
    use iso_c_binding, only: c_int
    implicit none
    integer(c_int) :: result
    integer, parameter :: operations(3) = [MPI_LAND, MPI_LOR, MPI_LXOR]
    integer :: i, ierr, error_class, class_ierr
    logical :: input(2), output(2), finalized

    call MPI_Finalized(finalized, ierr)
    result = ierr
    if (ierr /= MPI_SUCCESS) return
    if (finalized) then
        result = MPI_ERR_OTHER
        return
    end if
    do i = 1, 3
        input = [.true., .false.]
        output = [.false., .true.]
        call MPI_Allreduce(input, output, 2, MPI_LOGICAL, operations(i), MPI_COMM_SELF, ierr)
        if (ierr == MPI_SUCCESS) then
            if (any(input .neqv. output)) ierr = MPI_ERR_OTHER
        end if
        error_class = MPI_ERR_OTHER
        call MPI_Error_class(ierr, error_class, class_ierr)
        if (class_ierr /= MPI_SUCCESS) ierr = class_ierr
        print *, "FMPI_LOGICAL", i, ierr, error_class
        if (result == MPI_SUCCESS) result = ierr
    end do
end function

program finalize_callbacks_1
    use mpi
    use iso_c_binding, only: c_int
    implicit none
    integer :: ierr, provided
    logical :: finalized
    character(16) :: mode
    interface
        integer(c_int) function fmpi_finalizer_install() bind(C)
            import c_int
        end function
        integer(c_int) function fmpi_finalizer_calls() bind(C)
            import c_int
        end function
        integer(c_int) function fmpi_finalizer_result() bind(C)
            import c_int
        end function
    end interface

    call get_command_argument(1, mode)
    if (mode == "thread") then
        call MPI_Init_thread(MPI_THREAD_FUNNELED, provided, ierr)
        if (ierr /= MPI_SUCCESS) error stop "init_thread"
        if (provided /= MPI_THREAD_SINGLE .and. provided /= MPI_THREAD_FUNNELED .and. &
                provided /= MPI_THREAD_SERIALIZED .and. provided /= MPI_THREAD_MULTIPLE) then
            error stop "invalid provided thread level"
        end if
    else if (mode == "" .or. mode == "init") then
        call MPI_Init(ierr)
        if (ierr /= MPI_SUCCESS) error stop "init"
    else
        error stop "expected init or thread"
    end if
    call MPI_Comm_set_errhandler(MPI_COMM_WORLD, MPI_ERRORS_RETURN, ierr)
    if (ierr /= MPI_SUCCESS) error stop "world error handler"
    call MPI_Comm_set_errhandler(MPI_COMM_SELF, MPI_ERRORS_RETURN, ierr)
    if (ierr /= MPI_SUCCESS) error stop "self error handler"
    if (fmpi_finalizer_install() /= MPI_SUCCESS) error stop "early callback control"

    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop "finalize"
    call MPI_Finalized(finalized, ierr)
    if (ierr /= MPI_SUCCESS .or. .not. finalized) error stop "finalized"
    print *, "FMPI_FINALIZED_OK"
    if (fmpi_finalizer_calls() /= 2) error stop "callback count"
    if (fmpi_finalizer_result() /= MPI_SUCCESS) then
        print *, "FMPI_FINALIZER_REDUCTION_FAILED"
        error stop 1
    end if
    print *, "finalize_callbacks_1: OK"
end program
