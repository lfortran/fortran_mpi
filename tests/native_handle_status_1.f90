program native_handle_status_1
    use mpi
    use iso_c_binding, only: c_int
    implicit none
    integer, parameter :: constants(50) = [ &
        MPI_ANY_SOURCE, MPI_ANY_TAG, MPI_PROC_NULL, MPI_ROOT, MPI_UNDEFINED, &
        MPI_STATUS_SIZE, MPI_SOURCE, MPI_TAG, MPI_ERROR, &
        MPI_OP_NULL, MPI_SUM, MPI_MIN, MPI_MAX, MPI_PROD, MPI_BAND, MPI_BOR, MPI_BXOR, &
        MPI_LAND, MPI_LOR, MPI_LXOR, MPI_MINLOC, MPI_MAXLOC, MPI_REPLACE, MPI_NO_OP, &
        MPI_COMM_NULL, MPI_COMM_WORLD, MPI_COMM_SELF, MPI_GROUP_NULL, MPI_GROUP_EMPTY, &
        MPI_INFO_NULL, MPI_ERRHANDLER_NULL, MPI_ERRORS_ARE_FATAL, MPI_ERRORS_ABORT, &
        MPI_ERRORS_RETURN, MPI_REQUEST_NULL, MPI_DATATYPE_NULL, MPI_INT, MPI_FLOAT, &
        MPI_DOUBLE, MPI_LOGICAL, MPI_INTEGER, MPI_REAL, MPI_DOUBLE_PRECISION, &
        MPI_DOUBLE_COMPLEX, MPI_CHARACTER, MPI_INT32_T, MPI_INT64_T, MPI_REAL4, MPI_INTEGER8, MPI_REAL8]
    integer :: world = MPI_COMM_WORLD, datatype = MPI_INTEGER, operation = MPI_SUM
    integer :: requests(3) = MPI_REQUEST_NULL
    integer :: ierr, rank, nprocs, left, right, comm, from_c, comparison, group, derived, count, index
    integer :: info, custom_op, shared, total, guard(MPI_STATUS_SIZE + 2), statuses(MPI_STATUS_SIZE, 3)
    integer, asynchronous :: sent(2), received(2)
    logical :: flag
    interface
        integer(c_int) function native_constants(values) bind(C)
            import c_int
            integer(c_int), intent(in) :: values(*)
        end function
        integer(c_int) function native_comm(comm, duplicate) bind(C)
            import c_int
            integer(c_int), value :: comm
            integer(c_int), intent(out) :: duplicate
        end function
        integer(c_int) function native_group(group, size) bind(C)
            import c_int
            integer(c_int), value :: group, size
        end function
        integer(c_int) function native_type(datatype, size, created) bind(C)
            import c_int
            integer(c_int), value :: datatype, size
            integer(c_int), intent(out) :: created
        end function
        integer(c_int) function native_resources(info, op, release) bind(C)
            import c_int
            integer(c_int), intent(inout) :: info, op
            integer(c_int), value :: release
        end function
        integer(c_int) function native_request(request, cancel) bind(C)
            import c_int
            integer(c_int), intent(inout) :: request
            integer(c_int), value :: cancel
        end function
        integer(c_int) function native_status(status, source, tag, count, cancelled) bind(C)
            import c_int
            integer(c_int), intent(in) :: status(*)
            integer(c_int), value :: source, tag, count, cancelled
        end function
        integer(c_int) function native_make_status(status) bind(C)
            import c_int
            integer(c_int), intent(out) :: status(*)
        end function
    end interface

    ! These initializers and array bounds must remain valid before MPI_Init.
    if (world /= MPI_COMM_WORLD .or. datatype /= MPI_INTEGER .or. operation /= MPI_SUM) error stop
    if (any(requests /= MPI_REQUEST_NULL)) error stop
    call MPI_Init(ierr)
    call check(ierr, "init")
    ! Check integers before attempting f2c: private tokens may be invalid handles.
    call check(native_constants(constants), "native parameter identities")
    call MPI_Comm_rank(world, rank, ierr)
    call check(ierr, "rank")
    call MPI_Comm_size(world, nprocs, ierr)
    call check(ierr, "size")
    left = mod(rank - 1 + nprocs, nprocs)
    right = mod(rank + 1, nprocs)

    call check(native_comm(world, from_c), "C accepts predefined communicator")
    call MPI_Comm_compare(world, from_c, comparison, ierr)
    call check(ierr, "compare C-created communicator")
    if (comparison /= MPI_CONGRUENT) error stop "wrong C-created communicator"
    call MPI_Comm_free(from_c, ierr)
    call check(ierr, "free C-created communicator")
    if (from_c /= MPI_COMM_NULL) error stop "wrong native communicator null"
    call MPI_Comm_dup(world, comm, ierr)
    call check(ierr, "dup")
    call check(native_comm(comm, from_c), "C accepts Fortran-created communicator")
    call MPI_Comm_free(from_c, ierr)
    call check(ierr, "free duplicate from C")
    call MPI_Comm_group(comm, group, ierr)
    call check(ierr, "group")
    call check(native_group(group, nprocs), "C accepts group")
    call MPI_Group_free(group, ierr)
    call check(ierr, "free group")
    if (group /= MPI_GROUP_NULL) error stop "wrong native group null"

    call MPI_Type_contiguous(2, datatype, derived, ierr)
    call check(ierr, "contiguous")
    call MPI_Type_commit(derived, ierr)
    call check(ierr, "commit")
    call check(native_type(derived, 2, from_c), "C accepts datatype")
    call MPI_Type_free(from_c, ierr)
    call check(ierr, "free C-created datatype")
    if (from_c /= MPI_DATATYPE_NULL) error stop "wrong native datatype null"
    info = MPI_INFO_NULL
    custom_op = MPI_OP_NULL
    call check(native_resources(info, custom_op, 0), "C-created info and op")
    call MPI_Comm_split_type(comm, MPI_COMM_TYPE_SHARED, rank, info, shared, ierr)
    call check(ierr, "C info accepted by Fortran")
    call MPI_Comm_free(shared, ierr)
    call check(ierr, "free shared")
    total = rank + 1
    call MPI_Allreduce(MPI_IN_PLACE, total, 1, datatype, custom_op, comm, ierr)
    call check(ierr, "C op and in-place accepted by Fortran")
    if (total /= nprocs * (nprocs + 1) / 2) error stop "wrong custom reduction"
    call check(native_resources(info, custom_op, 1), "free C resources")
    if (info /= MPI_INFO_NULL .or. custom_op /= MPI_OP_NULL) error stop "wrong native resource nulls"

    sent = [rank + 17, rank + 23]
    received = -1
    call MPI_Irecv(received, 1, derived, left, 77, comm, requests(1), ierr)
    call check(ierr, "irecv")
    call check(native_request(requests(1), 0), "C accepts active request")
    call MPI_Isend(sent, 1, derived, right, 77, comm, requests(2), ierr)
    call check(ierr, "isend")
    call MPI_Waitall(3, requests, statuses, ierr)
    call check(ierr, "waitall")
    if (any(requests /= MPI_REQUEST_NULL)) error stop "wrong native request nulls"
    if (any(received /= [left + 17, left + 23])) error stop "wrong payload"
    call check(native_status(statuses(:, 1), left, 77, 2, 0), "C accepts receive status")
    call check(native_status(statuses(:, 3), MPI_ANY_SOURCE, MPI_ANY_TAG, 0, 0), "C accepts empty status")

    guard = -987654
    call check(native_make_status(guard(2:MPI_STATUS_SIZE + 1)), "C-produced status")
    call MPI_Get_count(guard(2:MPI_STATUS_SIZE + 1), datatype, count, ierr)
    call check(ierr, "Fortran accepts C-produced status")
    if (count /= 3 .or. guard(MPI_SOURCE + 1) /= 0 .or. guard(MPI_TAG + 1) /= 91) error stop
    if (guard(1) /= -987654 .or. guard(MPI_STATUS_SIZE + 2) /= -987654) error stop "status overflow"
    call MPI_Sendrecv(sent, 0, datatype, 0, 92, received, 0, datatype, 0, 92, &
        MPI_COMM_SELF, guard(2:MPI_STATUS_SIZE + 1), ierr)
    call check(ierr, "zero-count transfer")
    call check(native_status(guard(2:MPI_STATUS_SIZE + 1), 0, 92, 0, 0), "C accepts zero-count status")
    if (guard(1) /= -987654 .or. guard(MPI_STATUS_SIZE + 2) /= -987654) error stop "status overflow"

    call MPI_Irecv(received, 1, datatype, 0, 93, MPI_COMM_SELF, requests(1), ierr)
    call check(ierr, "unmatched receive")
    call check(native_request(requests(1), 1), "C cancels Fortran request")
    call MPI_Wait(requests(1), statuses(:, 1), ierr)
    call check(ierr, "wait cancelled request")
    call check(native_status(statuses(:, 1), 0, 0, 0, 1), "cancellation survives Fortran status")
    if (requests(1) /= MPI_REQUEST_NULL) error stop "cancelled request not null"

    MPI_STATUS_IGNORE = -801
    MPI_STATUSES_IGNORE = -802
    call MPI_Wait(requests(1), MPI_STATUS_IGNORE, ierr)
    call check(ierr, "ignore single status")
    call MPI_Waitall(3, requests, MPI_STATUSES_IGNORE, ierr)
    call check(ierr, "ignore multiple statuses")
    call MPI_Testall(0, requests, flag, statuses, ierr)
    call check(ierr, "zero requests testall")
    if (.not. flag) error stop "zero requests not complete"
    call MPI_Testall(0, requests, flag, MPI_STATUSES_IGNORE, ierr)
    call check(ierr, "zero requests ignored testall")
    if (.not. flag) error stop
    call MPI_Waitall(0, requests, statuses, ierr)
    call check(ierr, "zero requests waitall")
    call MPI_Waitall(0, requests, MPI_STATUSES_IGNORE, ierr)
    call check(ierr, "zero requests ignored waitall")
    call MPI_Waitany(0, requests, index, statuses(:, 1), ierr)
    call check(ierr, "zero requests waitany")
    if (index /= MPI_UNDEFINED) error stop
    call check(native_status(statuses(:, 1), MPI_ANY_SOURCE, MPI_ANY_TAG, 0, 0), "zero requests empty status")
    if (any(MPI_STATUS_IGNORE /= -801) .or. any(MPI_STATUSES_IGNORE /= -802)) error stop "ignore overwritten"
    call MPI_Type_free(derived, ierr)
    call check(ierr, "free datatype")
    if (derived /= MPI_DATATYPE_NULL) error stop
    call MPI_Comm_free(comm, ierr)
    call check(ierr, "free communicator")
    if (comm /= MPI_COMM_NULL) error stop
    call MPI_Finalize(ierr)
    call check(ierr, "finalize")
    if (rank == 0) print *, "native_handle_status_1: OK"
contains
    subroutine check(rc, operation)
        integer, intent(in) :: rc
        character(*), intent(in) :: operation
        if (rc /= MPI_SUCCESS) then
            print *, operation, ": ", rc
            error stop "native interoperation failed"
        end if
    end subroutine
end program
