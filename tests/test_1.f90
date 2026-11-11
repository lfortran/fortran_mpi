program test_1
    ! MPI_Test and MPI_Testall on a ring: each rank receives from its left
    ! neighbor and sends to its right one (itself with 1 rank)
    use mpi
    implicit none
    integer :: ierr, rank, nprocs, left, right
    integer :: requests(2), request
    integer :: status(MPI_STATUS_SIZE), statuses(MPI_STATUS_SIZE, 2)
    integer :: sendbuf(3), recvbuf(3)
    real(8) :: x, y
    logical :: flag

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    left = mod(rank - 1 + nprocs, nprocs)
    right = mod(rank + 1, nprocs)

    ! MPI_Test until the receive completes
    sendbuf = [rank, 10*rank, 100*rank]
    recvbuf = -1
    call MPI_Irecv(recvbuf, 3, MPI_INTEGER, left, 7, MPI_COMM_WORLD, requests(1), ierr)
    call MPI_Isend(sendbuf, 3, MPI_INTEGER, right, 7, MPI_COMM_WORLD, requests(2), ierr)
    flag = .false.
    do while (.not. flag)
        call MPI_Test(requests(1), flag, status, ierr)
        if (ierr /= MPI_SUCCESS) error stop "MPI_Test failed"
    end do
    if (requests(1) /= MPI_REQUEST_NULL) error stop "MPI_Test: request not freed"
    if (status(MPI_SOURCE) /= left) error stop "MPI_Test: wrong MPI_SOURCE"
    if (status(MPI_TAG) /= 7) error stop "MPI_Test: wrong MPI_TAG"
    if (any(recvbuf /= [left, 10*left, 100*left])) then
        print *, "rank", rank, ": recvbuf =", recvbuf
        error stop "MPI_Test: wrong data"
    end if

    ! MPI_Testall with an already completed (null) request in the array
    flag = .false.
    do while (.not. flag)
        call MPI_Testall(2, requests, flag, statuses, ierr)
        if (ierr /= MPI_SUCCESS) error stop "MPI_Testall failed"
    end do
    if (any(requests /= MPI_REQUEST_NULL)) error stop "MPI_Testall: requests not freed"
    ! The null request gives an empty status
    if (statuses(MPI_SOURCE, 1) /= MPI_ANY_SOURCE) error stop "MPI_Testall: wrong empty status"
    if (statuses(MPI_TAG, 1) /= MPI_ANY_TAG) error stop "MPI_Testall: wrong empty status tag"

    ! MPI_Testall with MPI_STATUSES_IGNORE
    x = rank + 0.5d0
    y = -1
    call MPI_Irecv(y, 1, MPI_DOUBLE_PRECISION, left, 8, MPI_COMM_WORLD, requests(1), ierr)
    call MPI_Isend(x, 1, MPI_DOUBLE_PRECISION, right, 8, MPI_COMM_WORLD, requests(2), ierr)
    flag = .false.
    do while (.not. flag)
        call MPI_Testall(2, requests, flag, MPI_STATUSES_IGNORE, ierr)
        if (ierr /= MPI_SUCCESS) error stop "MPI_Testall with MPI_STATUSES_IGNORE failed"
    end do
    if (any(requests /= MPI_REQUEST_NULL)) error stop "MPI_Testall: requests not freed"
    if (y /= left + 0.5d0) error stop "MPI_Testall: wrong data"

    ! MPI_Test of a null request completes at once, with an empty status
    request = MPI_REQUEST_NULL
    call MPI_Test(request, flag, status, ierr)
    if (.not. flag) error stop "MPI_Test of MPI_REQUEST_NULL: flag is false"
    if (status(MPI_SOURCE) /= MPI_ANY_SOURCE) error stop "MPI_Test: wrong empty status source"
    if (status(MPI_TAG) /= MPI_ANY_TAG) error stop "MPI_Test: wrong empty status tag"
    call MPI_Test(request, flag, MPI_STATUS_IGNORE, ierr)
    if (.not. flag) error stop "MPI_Test with MPI_STATUS_IGNORE: flag is false"

    if (rank == 0) print *, "test_1: OK"
    call MPI_Finalize(ierr)
end program test_1
