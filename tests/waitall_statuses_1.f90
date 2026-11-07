program waitall_statuses_1
    ! MPI_Waitall must fill array_of_statuses: each receive's status names the
    ! sender and the tag.
    use mpi
    implicit none
    integer :: ierr, rank, nprocs, left, right
    integer :: reqs(4), statuses(MPI_STATUS_SIZE, 4)
    real(8) :: sbuf(2, 2), rbuf_left(2, 2), rbuf_right(2, 2)

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    left = mod(rank - 1 + nprocs, nprocs)
    right = mod(rank + 1, nprocs)

    sbuf = rank
    ! The tag says the direction: 1 goes to the right, 2 to the left
    call MPI_Irecv(rbuf_left, 4, MPI_REAL8, left, 1, MPI_COMM_WORLD, reqs(1), ierr)
    call MPI_Irecv(rbuf_right, 4, MPI_REAL8, right, 2, MPI_COMM_WORLD, reqs(2), ierr)
    call MPI_Isend(sbuf, 4, MPI_REAL8, right, 1, MPI_COMM_WORLD, reqs(3), ierr)
    call MPI_Isend(sbuf, 4, MPI_REAL8, left, 2, MPI_COMM_WORLD, reqs(4), ierr)
    call MPI_Waitall(4, reqs, statuses, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Waitall failed"

    if (statuses(MPI_SOURCE, 1) /= left .or. statuses(MPI_TAG, 1) /= 1) then
        print *, "status 1:", statuses(MPI_SOURCE, 1), statuses(MPI_TAG, 1), "expected", left, 1
        error stop
    end if
    if (statuses(MPI_SOURCE, 2) /= right .or. statuses(MPI_TAG, 2) /= 2) then
        print *, "status 2:", statuses(MPI_SOURCE, 2), statuses(MPI_TAG, 2), "expected", right, 2
        error stop
    end if
    if (any(rbuf_left /= left) .or. any(rbuf_right /= right)) error stop "wrong data"
    if (any(reqs /= MPI_REQUEST_NULL)) error stop "requests not set to MPI_REQUEST_NULL"

    call MPI_Finalize(ierr)
end program waitall_statuses_1
