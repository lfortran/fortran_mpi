program status_ignore_1
    ! MPI_STATUS_IGNORE must be accepted by MPI_Recv, MPI_Sendrecv and
    ! MPI_Wait, and a real status must still be filled.
    use mpi
    implicit none
    integer :: ierr, rank, nprocs, left, right, req, status(MPI_STATUS_SIZE)
    real(8) :: buf(1), sbuf(1, 1), rbuf(1, 1)

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    left = mod(rank - 1 + nprocs, nprocs)
    right = mod(rank + 1, nprocs)

    ! MPI_Sendrecv around the ring, with and without a status
    sbuf = rank
    call MPI_Sendrecv(sbuf, 1, MPI_REAL8, right, 5, rbuf, 1, MPI_REAL8, left, 5, &
                      MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
    if (ierr /= MPI_SUCCESS .or. rbuf(1, 1) /= left) error stop "MPI_Sendrecv ignore failed"
    call MPI_Sendrecv(sbuf, 1, MPI_REAL8, right, 6, rbuf, 1, MPI_REAL8, left, 6, &
                      MPI_COMM_WORLD, status, ierr)
    if (status(MPI_SOURCE) /= left .or. status(MPI_TAG) /= 6) error stop "MPI_Sendrecv status"

    ! MPI_Recv and MPI_Wait
    if (nprocs > 1) then
        if (rank == 0) then
            buf = 42
            call MPI_Ssend(buf, 1, MPI_REAL8, 1, 7, MPI_COMM_WORLD, ierr)
            call MPI_Isend(sbuf, 1, MPI_REAL8, 1, 8, MPI_COMM_WORLD, req, ierr)
            call MPI_Wait(req, MPI_STATUS_IGNORE, ierr)
            if (ierr /= MPI_SUCCESS .or. req /= MPI_REQUEST_NULL) error stop "MPI_Wait ignore"
        else if (rank == 1) then
            call MPI_Recv(buf, 1, MPI_REAL8, 0, 7, MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
            if (ierr /= MPI_SUCCESS .or. buf(1) /= 42) error stop "MPI_Recv ignore failed"
            call MPI_Irecv(rbuf, 1, MPI_REAL8, 0, 8, MPI_COMM_WORLD, req, ierr)
            call MPI_Wait(req, status, ierr)
            if (status(MPI_SOURCE) /= 0 .or. status(MPI_TAG) /= 8) error stop "MPI_Wait status"
        end if
    end if

    call MPI_Finalize(ierr)
end program status_ignore_1
