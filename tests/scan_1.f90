program scan_1
    ! MPI_Scan: inclusive prefix sum, and an in-place prefix product
    use mpi
    implicit none
    integer :: ierr, rank, nprocs
    integer :: sendbuf(2), recvbuf(2)
    real(8) :: x

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)

    sendbuf = [rank + 1, 2*(rank + 1)]
    recvbuf = 0
    call MPI_Scan(sendbuf, recvbuf, 2, MPI_INTEGER, MPI_SUM, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Scan failed"
    ! 1 + 2 + ... + (rank+1)
    if (recvbuf(1) /= (rank+1)*(rank+2)/2 .or. recvbuf(2) /= (rank+1)*(rank+2)) then
        print *, "rank", rank, ": recvbuf =", recvbuf
        error stop "MPI_Scan: wrong result"
    end if

    x = 2
    call MPI_Scan(MPI_IN_PLACE, x, 1, MPI_DOUBLE_PRECISION, MPI_PROD, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Scan with MPI_IN_PLACE failed"
    if (x /= 2.0d0**(rank+1)) then
        print *, "rank", rank, ": x =", x
        error stop "MPI_Scan with MPI_IN_PLACE: wrong result"
    end if

    if (rank == 0) print *, "scan_1: OK"
    call MPI_Finalize(ierr)
end program scan_1
