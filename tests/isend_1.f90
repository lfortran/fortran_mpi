program isend_1
    use mpi
    implicit none

    integer, parameter :: NROWS = 100
    integer, parameter :: NCOLS = 50
    real(8) :: send_buf(NROWS, NCOLS), recv_buf(NROWS, NCOLS)
    integer :: rank, size, ierr
    integer :: dest, source, tag
    integer :: request, recv_request
    integer :: status(MPI_STATUS_SIZE)

    call MPI_INIT(ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_INIT failed"

    call MPI_COMM_RANK(MPI_COMM_WORLD, rank, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_COMM_RANK failed"
    call MPI_COMM_SIZE(MPI_COMM_WORLD, size, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_COMM_SIZE failed"

    ! Send around a ring; on 1 rank, a process sends to itself
    send_buf = real(rank, 8) + 0.1d0
    recv_buf = -1

    dest = mod(rank + 1, size)
    source = mod(rank - 1 + size, size)
    tag = 0

    if (rank == 0) then
        print *, 'Starting non-blocking send example'
    end if

    call MPI_ISEND(send_buf, NROWS*NCOLS, MPI_REAL8, dest, &
                  tag, MPI_COMM_WORLD, request, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_ISEND failed"

    print *, 'Rank ', rank, ' continuing work while sending to ', dest

    call MPI_IRECV(recv_buf, NROWS*NCOLS, MPI_REAL8, source, &
                  tag, MPI_COMM_WORLD, recv_request, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_IRECV failed"

    call MPI_WAIT(request, MPI_STATUS_IGNORE, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_WAIT(send) failed"
    if (request /= MPI_REQUEST_NULL) error stop "MPI_WAIT did not free the send request"
    call MPI_WAIT(recv_request, status, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_WAIT(recv) failed"

    print *, 'Rank ', rank, ' finished work, send completed'

    if (any(recv_buf /= real(source, 8) + 0.1d0)) then
        print *, 'Rank ', rank, ' received ', recv_buf(1, 1), ' expected ', &
                 real(source, 8) + 0.1d0
        error stop "wrong data received"
    end if
    if (status(MPI_SOURCE) /= source .or. status(MPI_TAG) /= tag) &
        error stop "wrong status of the receive"

    call MPI_FINALIZE(ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_FINALIZE failed"

end program isend_1
