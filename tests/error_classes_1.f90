program error_classes_1
    use mpi
    use iso_c_binding, only: c_int, c_char
    implicit none
    integer, parameter :: classes(58) = [MPI_SUCCESS, MPI_ERR_BUFFER, MPI_ERR_COUNT, MPI_ERR_TYPE, &
        MPI_ERR_TAG, MPI_ERR_COMM, MPI_ERR_RANK, MPI_ERR_REQUEST, MPI_ERR_ROOT, MPI_ERR_GROUP, &
        MPI_ERR_OP, MPI_ERR_TOPOLOGY, MPI_ERR_DIMS, MPI_ERR_ARG, MPI_ERR_UNKNOWN, MPI_ERR_TRUNCATE, &
        MPI_ERR_OTHER, MPI_ERR_INTERN, MPI_ERR_PENDING, MPI_ERR_IN_STATUS, MPI_ERR_ACCESS, MPI_ERR_AMODE, &
        MPI_ERR_ASSERT, MPI_ERR_BAD_FILE, MPI_ERR_BASE, MPI_ERR_CONVERSION, MPI_ERR_DISP, MPI_ERR_DUP_DATAREP, &
        MPI_ERR_FILE_EXISTS, MPI_ERR_FILE_IN_USE, MPI_ERR_FILE, MPI_ERR_INFO_KEY, MPI_ERR_INFO_NOKEY, &
        MPI_ERR_INFO_VALUE, MPI_ERR_INFO, MPI_ERR_IO, MPI_ERR_KEYVAL, MPI_ERR_LOCKTYPE, MPI_ERR_NAME, &
        MPI_ERR_NO_MEM, MPI_ERR_NOT_SAME, MPI_ERR_NO_SPACE, MPI_ERR_NO_SUCH_FILE, MPI_ERR_PORT, MPI_ERR_QUOTA, &
        MPI_ERR_READ_ONLY, MPI_ERR_RMA_ATTACH, MPI_ERR_RMA_CONFLICT, MPI_ERR_RMA_RANGE, MPI_ERR_RMA_SHARED, &
        MPI_ERR_RMA_SYNC, MPI_ERR_SERVICE, MPI_ERR_SIZE, MPI_ERR_SPAWN, MPI_ERR_UNSUPPORTED_DATAREP, &
        MPI_ERR_UNSUPPORTED_OPERATION, MPI_ERR_WIN, MPI_ERR_RMA_FLAVOR]
    integer :: native_classes(58), native_lastcode, native_code, provided_code, ierr, value, failures

    interface
        subroutine mpi_error_class_values(values, lastcode) bind(C)
            import c_int
            integer(c_int), intent(out) :: values(58), lastcode
        end subroutine
        integer(c_int) function mpi_error_classes_control() bind(C)
            import c_int
        end function
        integer(c_int) function mpi_error_text_matches(code, text, length) bind(C)
            import c_int, c_char
            integer(c_int), value :: code, length
            character(kind=c_char), intent(in) :: text(*)
        end function
        integer(c_int) function mpi_error_native_root(code) bind(C)
            import c_int
            integer(c_int), intent(out) :: code
        end function
    end interface

    failures = 0
    call mpi_error_class_values(native_classes, native_lastcode)
    if (mpi_error_classes_control() /= 0) error stop "native C error-class control failed"
    ! LASTCODE is a bound, not necessarily a valid class or error code.
    call check(MPI_ERR_LASTCODE == native_lastcode, "MPI_ERR_LASTCODE differs from C")
    call check_classes()

    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Init failed"
    ierr = mpi_error_native_root(native_code)
    if (ierr /= MPI_SUCCESS) error stop "native C invalid-root setup failed"
    call check_root_error(native_code)

    call MPI_Comm_set_errhandler(MPI_COMM_SELF, MPI_ERRORS_RETURN, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Comm_set_errhandler failed"
    value = 1
    call MPI_Bcast(value, 1, MPI_INTEGER, 1, MPI_COMM_SELF, provided_code)
    call check(provided_code /= MPI_SUCCESS, "invalid root succeeded")
    if (provided_code /= MPI_SUCCESS) call check_root_error(provided_code)

    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Finalize failed"
    if (mpi_error_classes_control() /= 0) error stop "native C post-finalize control failed"
    ! Both queries are valid before initialization and after finalization.
    call check_classes()
    print *, "error_classes_1: classes", size(classes), "failures", failures
    if (failures /= 0) stop 1

contains

    subroutine check(condition, message)
        logical, intent(in) :: condition
        character(*), intent(in) :: message
        if (.not. condition) then
            print *, message
            failures = failures + 1
        end if
    end subroutine

    subroutine check_text(code, native_expected)
        integer, intent(in) :: code, native_expected
        integer :: rc, length
        character(MPI_MAX_ERROR_STRING) :: message
        call MPI_Error_string(code, message, length, rc)
        call check(rc == MPI_SUCCESS, "MPI_Error_string failed")
        if (rc == MPI_SUCCESS) then
            call check(mpi_error_text_matches(native_expected, message, length) == 0, &
                "error string or length differs from native C")
        end if
    end subroutine

    subroutine check_classes()
        integer :: i, errorclass, repeated, rc
        do i = 1, size(classes)
            call check(classes(i) == native_classes(i), "public error class differs from native C")
            call MPI_Error_class(classes(i), errorclass, rc)
            call check(rc == MPI_SUCCESS, "constant-as-code classification failed")
            if (rc == MPI_SUCCESS) then
                call check(errorclass == classes(i), "class does not map to itself")
                call MPI_Error_class(errorclass, repeated, rc)
                call check(rc == MPI_SUCCESS, "class-result classification failed")
                if (rc == MPI_SUCCESS) call check(repeated == errorclass, "classification is not idempotent")
                call check_text(errorclass, native_classes(i))
            end if
            call check_text(classes(i), native_classes(i))

            call MPI_Error_class(native_classes(i), errorclass, rc)
            call check(rc == MPI_SUCCESS, "native code classification failed")
            if (rc == MPI_SUCCESS) call check(errorclass == native_classes(i), "native class was changed")
            call check_text(native_classes(i), native_classes(i))
        end do
    end subroutine

    subroutine check_root_error(code)
        integer, intent(in) :: code
        integer :: errorclass, repeated, rc
        call MPI_Error_class(code, errorclass, rc)
        call check(rc == MPI_SUCCESS, "native root code classification failed")
        if (rc == MPI_SUCCESS) then
            call check(errorclass == MPI_ERR_ROOT, "native root code has wrong class")
            call MPI_Error_class(errorclass, repeated, rc)
            call check(rc == MPI_SUCCESS, "root class-result classification failed")
            if (rc == MPI_SUCCESS) call check(repeated == errorclass, "root classification is not idempotent")
            call check_text(errorclass, native_classes(9))
        end if
        call check_text(code, code)
    end subroutine
end program
