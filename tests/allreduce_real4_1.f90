program allreduce_real4_1
    ! Single-precision (real(4)) buffers must resolve to specifics of
    ! MPI_Allreduce (including MPI_IN_PLACE), MPI_Bcast, MPI_Isend and
    ! MPI_Irecv, and the data must arrive unchanged.
    use mpi
    implicit none

    integer, parameter :: n = 4, m = 3
    integer :: ierr, rank, nprocs, i, j, dest, src
    integer :: reqs(2)
    real(4) :: x, s, v(m), w(m)
    real(4) :: a(n, m), sbuf(n, m), rbuf(n, m)

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)

    ! Scalar allreduce sum.
    x = real(rank + 1, 4)
    call MPI_Allreduce(x, s, 1, MPI_REAL, MPI_SUM, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Allreduce scalar failed"
    if (abs(s - real(nprocs*(nprocs + 1)/2, 4)) > 1e-6) error stop "wrong scalar allreduce sum"

    ! Array allreduce sum.
    v = [(real(rank*10 + i, 4), i = 1, m)]
    call MPI_Allreduce(v, w, m, MPI_REAL4, MPI_SUM, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Allreduce array failed"
    do i = 1, m
        if (abs(w(i) - real(5*nprocs*(nprocs - 1) + nprocs*i, 4)) > 1e-5) error stop "wrong array allreduce sum"
    end do

    ! In-place scalar and array allreduce sums.
    x = real(rank + 1, 4)
    call MPI_Allreduce(MPI_IN_PLACE, x, 1, MPI_REAL4, MPI_SUM, MPI_COMM_WORLD, ierr)
    if (abs(x - real(nprocs*(nprocs + 1)/2, 4)) > 1e-6) error stop "wrong in-place scalar allreduce sum"
    v = [(real(rank*10 + i, 4), i = 1, m)]
    call MPI_Allreduce(MPI_IN_PLACE, v, m, MPI_REAL4, MPI_SUM, MPI_COMM_WORLD, ierr)
    do i = 1, m
        if (abs(v(i) - real(5*nprocs*(nprocs - 1) + nprocs*i, 4)) > 1e-5) error stop "wrong in-place array allreduce sum"
    end do

    ! Broadcast of a real(4) array.
    if (rank == 0) then
        a = reshape([(0.5*real(i, 4), i = 1, n*m)], [n, m])
    else
        a = -1.0
    end if
    call MPI_Bcast(a, n*m, MPI_REAL4, 0, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Bcast failed"
    do j = 1, m
        do i = 1, n
            if (a(i, j) /= 0.5*real(i + (j - 1)*n, 4)) error stop "wrong broadcast"
        end do
    end do

    ! Nonblocking ring exchange of real(4) arrays (a self-exchange on 1 rank).
    dest = mod(rank + 1, nprocs)
    src = mod(rank - 1 + nprocs, nprocs)
    sbuf = real(100*rank, 4) + a
    rbuf = 0.0
    call MPI_Irecv(rbuf, n*m, MPI_REAL4, src, 7, MPI_COMM_WORLD, reqs(1), ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Irecv failed"
    call MPI_Isend(sbuf, n*m, MPI_REAL4, dest, 7, MPI_COMM_WORLD, reqs(2), ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Isend failed"
    call MPI_Waitall(2, reqs, MPI_STATUSES_IGNORE, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Waitall failed"
    do j = 1, m
        do i = 1, n
            if (rbuf(i, j) /= real(100*src, 4) + a(i, j)) error stop "wrong received data"
        end do
    end do

    if (rank == 0) print *, "allreduce_real4_1: OK"
    call MPI_Finalize(ierr)
end program allreduce_real4_1
