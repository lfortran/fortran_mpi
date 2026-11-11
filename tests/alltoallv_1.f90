program alltoallv_1
    ! MPI_Alltoallv: rank r sends r+j+1 values to rank j
    use mpi
    implicit none
    integer :: ierr, rank, nprocs, j, k
    integer, allocatable :: sendcounts(:), sdispls(:), recvcounts(:), rdispls(:)
    integer, allocatable :: sendbuf(:), recvbuf(:)

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)

    allocate(sendcounts(nprocs), sdispls(nprocs), recvcounts(nprocs), rdispls(nprocs))
    do j = 1, nprocs
        sendcounts(j) = rank + j
        recvcounts(j) = rank + j
    end do
    sdispls(1) = 0
    rdispls(1) = 0
    do j = 2, nprocs
        sdispls(j) = sdispls(j-1) + sendcounts(j-1)
        ! Leave a gap of one element between the blocks of recvbuf
        rdispls(j) = rdispls(j-1) + recvcounts(j-1) + 1
    end do

    allocate(sendbuf(sum(sendcounts)), recvbuf(rdispls(nprocs) + recvcounts(nprocs)))
    do j = 1, nprocs
        do k = 1, sendcounts(j)
            sendbuf(sdispls(j) + k) = 1000*rank + 10*(j-1) + k
        end do
    end do
    recvbuf = -1
    call MPI_Alltoallv(sendbuf, sendcounts, sdispls, MPI_INTEGER, recvbuf, recvcounts, &
        rdispls, MPI_INTEGER, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Alltoallv failed"
    do j = 1, nprocs
        do k = 1, recvcounts(j)
            if (recvbuf(rdispls(j) + k) /= 1000*(j-1) + 10*rank + k) then
                print *, "rank", rank, ": recvbuf =", recvbuf
                error stop "MPI_Alltoallv: wrong result"
            end if
        end do
        if (j > 1) then
            if (recvbuf(rdispls(j)) /= -1) error stop "MPI_Alltoallv: wrote into a gap"
        end if
    end do

    if (rank == 0) print *, "alltoallv_1: OK"
    call MPI_Finalize(ierr)
end program alltoallv_1
