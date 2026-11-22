program completion_errors_1
    use mpi
    implicit none
    integer :: ierr, rank, nprocs, left, right, mode, failures

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    call MPI_Comm_set_errhandler(MPI_COMM_WORLD, MPI_ERRORS_RETURN, ierr)
    call MPI_Comm_set_errhandler(MPI_COMM_SELF, MPI_ERRORS_RETURN, ierr)
    failures = 0

    ! A peer transfer is needed: some MPI implementations do not report
    ! truncation for a send to self.
    if (nprocs > 1) then
        left = mod(rank - 1 + nprocs, nprocs)
        right = mod(rank + 1, nprocs)
        do mode = 1, 2
            call check_completion(mode == 2, .false.)
            call check_completion(mode == 2, .true.)
        end do
    end if
    call MPI_Finalize(ierr)
    if (failures /= 0) error stop "completion_errors_1 failed"
    if (rank == 0) print *, "completion_errors_1: OK"

contains

    subroutine check(condition, message)
        logical, intent(in) :: condition
        character(*), intent(in) :: message
        if (.not. condition) then
            print *, "rank", rank, ": ", message
            failures = failures + 1
        end if
    end subroutine check

    subroutine check_completion(test_all, ignore_statuses)
        logical, intent(in) :: test_all, ignore_statuses
        integer, parameter :: sentinel = -777777
        integer, asynchronous :: bad_send(2), bad_recv(1), good_send, good_recv
        integer :: requests(5), original_requests(5), statuses(MPI_STATUS_SIZE, 5)
        integer :: rc, errorclass, item_class, i, count, abort_ierr
        real(8) :: started
        logical :: flag

        bad_send = [rank, rank + 1]
        bad_recv = -1
        good_send = rank + 501
        good_recv = -1
        requests = MPI_REQUEST_NULL
        call MPI_Irecv(bad_recv, 1, MPI_INTEGER, left, 104, MPI_COMM_WORLD, requests(1), ierr)
        if (ierr /= MPI_SUCCESS) error stop "bad Irecv failed"
        call MPI_Irecv(good_recv, 1, MPI_INTEGER, left, 105, MPI_COMM_WORLD, requests(2), ierr)
        if (ierr /= MPI_SUCCESS) error stop "good Irecv failed"
        call MPI_Isend(bad_send, 2, MPI_INTEGER, right, 104, MPI_COMM_WORLD, requests(3), ierr)
        if (ierr /= MPI_SUCCESS) error stop "bad Isend failed"
        call MPI_Isend(good_send, 1, MPI_INTEGER, right, 105, MPI_COMM_WORLD, requests(4), ierr)
        if (ierr /= MPI_SUCCESS) error stop "good Isend failed"
        original_requests = requests
        started = MPI_Wtime()
        do
            statuses = sentinel
            if (test_all) then
                if (ignore_statuses) then
                    call MPI_Testall(5, requests, flag, MPI_STATUSES_IGNORE, ierr)
                else
                    call MPI_Testall(5, requests, flag, statuses, ierr)
                end if
            else
                if (ignore_statuses) then
                    call MPI_Waitall(5, requests, MPI_STATUSES_IGNORE, ierr)
                else
                    call MPI_Waitall(5, requests, statuses, ierr)
                end if
                flag = .true.
            end if
            if (ierr /= MPI_SUCCESS) exit
            if (flag) exit
            if (MPI_Wtime() - started > 10.0d0) then
                call MPI_Abort(MPI_COMM_WORLD, 1, abort_ierr)
                error stop "MPI_Testall timed out"
            end if
        end do

        call MPI_Error_class(ierr, errorclass, rc)
        call check(rc == MPI_SUCCESS, "cannot classify completion error")
        call check(errorclass == MPI_ERR_IN_STATUS, "completion did not report MPI_ERR_IN_STATUS")
        call check(requests(5) == MPI_REQUEST_NULL, "null request changed")
        if (errorclass == MPI_ERR_IN_STATUS .and. .not. ignore_statuses) then
            do i = 1, 5
                if (statuses(MPI_ERROR, i) == sentinel) then
                    call check(.false., "missing per-request error status")
                    cycle
                end if
                call MPI_Error_class(statuses(MPI_ERROR, i), item_class, rc)
                call check(rc == MPI_SUCCESS, "cannot classify per-request error")
                if (rc /= MPI_SUCCESS) cycle
                if (i == 1) then
                    call check(item_class == MPI_ERR_TRUNCATE, "missing truncation status")
                else if (i == 5) then
                    call check(item_class == MPI_SUCCESS, "wrong null-request error")
                else
                    call check(item_class == MPI_SUCCESS .or. item_class == MPI_ERR_PENDING, &
                        "unexpected per-request error")
                end if
                if (item_class == MPI_ERR_PENDING) then
                    call check(requests(i) == original_requests(i), "pending request changed")
                else
                    ! A false Testall can report an error without releasing
                    ! the completed requests; finish any retained handles below.
                    call check(requests(i) == MPI_REQUEST_NULL .or. requests(i) == original_requests(i), &
                        "invalid completed request update")
                end if
                ! Only the error field is meaningful for failed/pending
                ! requests and sends. Check receive metadata only on success.
                if (i == 2 .and. item_class == MPI_SUCCESS) then
                    call check(statuses(MPI_SOURCE, i) == left, "wrong successful receive source")
                    call check(statuses(MPI_TAG, i) == 105, "wrong successful receive tag")
                    call MPI_Get_count(statuses(:, i), MPI_INTEGER, count, rc)
                    call check(rc == MPI_SUCCESS .and. count == 1, "wrong successful receive count")
                end if
            end do
            call check(statuses(MPI_SOURCE, 5) == MPI_ANY_SOURCE, "wrong empty status source")
            call check(statuses(MPI_TAG, 5) == MPI_ANY_TAG, "wrong empty status tag")
        end if
        do i = 1, 5
            if (requests(i) /= MPI_REQUEST_NULL) then
                call MPI_Wait(requests(i), MPI_STATUS_IGNORE, ierr)
                call MPI_Error_class(ierr, item_class, rc)
                call check(rc == MPI_SUCCESS, "cannot classify retained request error")
                call check(item_class == MPI_SUCCESS .or. (i == 1 .and. item_class == MPI_ERR_TRUNCATE), &
                    "unexpected retained request error")
                call check(requests(i) == MPI_REQUEST_NULL, "pending request not released")
            end if
        end do
        call check(good_recv == left + 501, "wrong successful receive payload")
    end subroutine check_completion
end program completion_errors_1
