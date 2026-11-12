program reduce_scatter_block_1
    ! MPI_Reduce_scatter_block: each rank gets 2 elements of the sum,
    ! then the same with MPI_IN_PLACE
    use mpi
    implicit none
    integer, parameter :: n = 2
    integer :: ierr, rank, nprocs, k
    integer, allocatable :: sendbuf(:), buf(:)
    integer :: recvbuf(n), expected

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)

    allocate(sendbuf(n*nprocs), buf(n*nprocs))
    do k = 1, n*nprocs
        sendbuf(k) = 100*rank + k
    end do
    recvbuf = 0
    call MPI_Reduce_scatter_block(sendbuf, recvbuf, n, MPI_INTEGER, MPI_SUM, &
        MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Reduce_scatter_block failed"
    ! Element n*rank+k of the sum over all ranks p of 100*p + (n*rank+k)
    do k = 1, n
        expected = 100*nprocs*(nprocs-1)/2 + nprocs*(n*rank + k)
        if (recvbuf(k) /= expected) then
            print *, "rank", rank, ": recvbuf =", recvbuf, ", expected element", k, "=", expected
            error stop "MPI_Reduce_scatter_block: wrong result"
        end if
    end do

    ! MPI_IN_PLACE: the input is the whole buf, the result its first n elements
    buf = sendbuf
    call MPI_Reduce_scatter_block(MPI_IN_PLACE, buf, n, MPI_INTEGER, MPI_SUM, &
        MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Reduce_scatter_block with MPI_IN_PLACE failed"
    if (any(buf(1:n) /= recvbuf)) then
        print *, "rank", rank, ": buf =", buf(1:n), ", expected", recvbuf
        error stop "MPI_Reduce_scatter_block with MPI_IN_PLACE: wrong result"
    end if

    if (rank == 0) print *, "reduce_scatter_block_1: OK"
    call MPI_Finalize(ierr)
end program reduce_scatter_block_1
