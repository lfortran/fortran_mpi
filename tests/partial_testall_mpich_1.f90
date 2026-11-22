program partial_testall
    use mpi
    implicit none
    integer, parameter :: sentinel = -777777
    integer, asynchronous :: bad_send(2), bad_recv, good_send, good_recv
    integer :: requests(5), original(5), statuses(MPI_STATUS_SIZE, 5)
    integer :: ierr, rc, cls, i, mode, nprocs, count, failures
    logical :: flag
    real(8) :: started

    call MPI_Init(ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    if (nprocs /= 1) error stop "one rank required"
    call MPI_Comm_set_errhandler(MPI_COMM_SELF, MPI_ERRORS_RETURN, ierr)
    call MPI_Comm_set_errhandler(MPI_COMM_WORLD, MPI_ERRORS_RETURN, ierr)
    failures = 0
    do mode = 0, 1
        requests = MPI_REQUEST_NULL
        bad_send = [101, 102]
        bad_recv = -1
        good_send = 501
        good_recv = -1
        call MPI_Irecv(bad_recv, 1, MPI_INTEGER, 0, 104, MPI_COMM_SELF, requests(1), ierr)
        if (ierr /= MPI_SUCCESS) error stop "bad receive setup"
        call MPI_Irecv(good_recv, 1, MPI_INTEGER, 0, 105, MPI_COMM_SELF, requests(2), ierr)
        if (ierr /= MPI_SUCCESS) error stop "pending receive setup"
        call MPI_Isend(bad_send, 2, MPI_INTEGER, 0, 104, MPI_COMM_SELF, requests(3), ierr)
        if (ierr /= MPI_SUCCESS) error stop "send setup"
        original = requests
        started = MPI_Wtime()
        do
            statuses = sentinel
            if (mode == 0) then
                call MPI_Testall(5, requests, flag, statuses, ierr)
            else
                call MPI_Testall(5, requests, flag, MPI_STATUSES_IGNORE, ierr)
            end if
            if (ierr /= MPI_SUCCESS) exit
            if (flag) error stop "unmatched receive completed"
            if (MPI_Wtime() - started > 10.0d0) error stop "partial Testall timed out"
        end do
        call MPI_Error_class(ierr, cls, rc)
        if (rc /= MPI_SUCCESS .or. cls /= MPI_ERR_IN_STATUS) error stop "wrong overall error"
        if (flag) error stop "pending receive should keep flag false"
        print *, "PARTIAL", mode, "flag", flag, "unchanged", all(requests == original)
        if (any(requests /= original)) error stop "request updates differ from MPICH native control"
        if (mode == 0) then
            do i = 1, 5
                if (statuses(MPI_ERROR, i) == sentinel) then
                    print *, "MISSING_ERROR_STATUS", i
                    failures = failures + 1
                    cycle
                end if
                call MPI_Error_class(statuses(MPI_ERROR, i), cls, rc)
                if (rc /= MPI_SUCCESS) error stop "invalid per-request error"
                print *, "PARTIAL_CLASS", i, "truncate", cls == MPI_ERR_TRUNCATE, &
                    "pending", cls == MPI_ERR_PENDING, "success", cls == MPI_SUCCESS
                if (i == 1) then
                    if (cls /= MPI_ERR_TRUNCATE) error stop "missing truncation"
                else if (i == 2) then
                    if (cls /= MPI_ERR_PENDING) error stop "missing pending status"
                else
                    if (cls /= MPI_SUCCESS) error stop "wrong success status"
                end if
            end do
        end if
        call MPI_Send(good_send, 1, MPI_INTEGER, 0, 105, MPI_COMM_SELF, ierr)
        if (ierr /= MPI_SUCCESS) error stop "pending send failed"
        do i = 1, 5
            if (requests(i) == MPI_REQUEST_NULL) cycle
            call MPI_Wait(requests(i), MPI_STATUS_IGNORE, ierr)
            call MPI_Error_class(ierr, cls, rc)
            if (rc /= MPI_SUCCESS) error stop "cannot classify drain"
            if (cls /= MPI_SUCCESS) then
                if (i /= 1 .or. cls /= MPI_ERR_TRUNCATE) error stop "unexpected drain error"
            end if
        end do
        if (any(requests /= MPI_REQUEST_NULL)) error stop "requests not released"
        if (good_recv /= 501) error stop "wrong payload"
    end do
    call MPI_Testall(5, requests, flag, statuses)
    if (.not. flag) error stop "optional ierror success failed"
    if (any(statuses(MPI_SOURCE, :) /= MPI_ANY_SOURCE)) error stop "wrong empty source"
    if (any(statuses(MPI_TAG, :) /= MPI_ANY_TAG)) error stop "wrong empty tag"
    call MPI_Get_count(statuses(:, 1), MPI_INTEGER, count, ierr)
    if (ierr /= MPI_SUCCESS .or. count /= 0) error stop "wrong empty count"
    call MPI_Waitall(5, requests, MPI_STATUSES_IGNORE)
    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop "finalize failed"
    print *, "PARTIAL_RESULT failures", failures
    if (failures /= 0) stop 75
end program partial_testall
