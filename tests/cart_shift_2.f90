program cart_shift_2
    ! MPI_Cart_shift must return MPI_PROC_NULL (as seen from Fortran) for
    ! neighbors across a non-periodic boundary, and MPI_PROC_NULL must be
    ! usable as a source/destination in point-to-point calls.
    use mpi
    implicit none

    integer :: ierr, rank, nprocs, comm_cart
    integer :: dims(1), coords(1)
    logical :: periods(1)
    integer :: left, right, reqs(4)
    real(8) :: sbuf(2,2), rbuf_l(2,2), rbuf_r(2,2)

    call MPI_Init(ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)

    dims(1) = nprocs
    periods(1) = .false.
    call MPI_Cart_create(MPI_COMM_WORLD, 1, dims, periods, .false., comm_cart, ierr)
    call MPI_Comm_rank(comm_cart, rank, ierr)
    call MPI_Cart_coords(comm_cart, rank, 1, coords, ierr)
    call MPI_Cart_shift(comm_cart, 0, 1, left, right, ierr)

    if (coords(1) == 0) then
        if (left /= MPI_PROC_NULL) then
            print *, "rank", rank, ": left should be MPI_PROC_NULL =", MPI_PROC_NULL, "got", left
            error stop
        end if
    else if (left /= rank - 1) then
        print *, "rank", rank, ": wrong left neighbor", left
        error stop
    end if
    if (coords(1) == nprocs - 1) then
        if (right /= MPI_PROC_NULL) then
            print *, "rank", rank, ": right should be MPI_PROC_NULL =", MPI_PROC_NULL, "got", right
            error stop
        end if
    else if (right /= rank + 1) then
        print *, "rank", rank, ": wrong right neighbor", right
        error stop
    end if

    ! Halo exchange; communication with MPI_PROC_NULL is a no-op.
    sbuf = rank
    rbuf_l = -1
    rbuf_r = -1
    call MPI_Isend(sbuf, 4, MPI_REAL8, left, 0, comm_cart, reqs(1), ierr)
    call MPI_Isend(sbuf, 4, MPI_REAL8, right, 0, comm_cart, reqs(2), ierr)
    call MPI_Irecv(rbuf_l, 4, MPI_REAL8, left, 0, comm_cart, reqs(3), ierr)
    call MPI_Irecv(rbuf_r, 4, MPI_REAL8, right, 0, comm_cart, reqs(4), ierr)
    call MPI_Waitall(4, reqs, MPI_STATUSES_IGNORE, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Waitall failed"

    if (left == MPI_PROC_NULL) then
        if (any(rbuf_l /= -1)) error stop "rbuf_l modified by MPI_PROC_NULL receive"
    else
        if (any(rbuf_l /= left)) error stop "wrong data from left neighbor"
    end if
    if (right == MPI_PROC_NULL) then
        if (any(rbuf_r /= -1)) error stop "rbuf_r modified by MPI_PROC_NULL receive"
    else
        if (any(rbuf_r /= right)) error stop "wrong data from right neighbor"
    end if

    if (rank == 0) print *, "cart_shift_2 passed"
    call MPI_Finalize(ierr)
end program cart_shift_2
