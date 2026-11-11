program scatterv_1
    ! MPI_Scatterv: rank i receives i+1 values; then the same with
    ! MPI_IN_PLACE at the root
    use mpi
    implicit none
    integer :: ierr, rank, nprocs, i, k, total
    integer, allocatable :: sendcounts(:), displs(:)
    real(8), allocatable :: sendbuf(:), recvbuf(:)

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)

    allocate(sendcounts(nprocs), displs(nprocs))
    total = 0
    do i = 1, nprocs
        sendcounts(i) = i
        displs(i) = total
        total = total + i
    end do
    allocate(sendbuf(total))
    sendbuf = -1
    if (rank == 0) then
        do i = 1, nprocs
            do k = 1, sendcounts(i)
                sendbuf(displs(i) + k) = 100*(i-1) + k
            end do
        end do
    end if

    allocate(recvbuf(rank+2))
    recvbuf = -1
    call MPI_Scatterv(sendbuf, sendcounts, displs, MPI_DOUBLE_PRECISION, recvbuf, rank+1, &
        MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Scatterv failed"
    do k = 1, rank + 1
        if (recvbuf(k) /= 100*rank + k) then
            print *, "rank", rank, ": recvbuf =", recvbuf
            error stop "MPI_Scatterv: wrong result"
        end if
    end do
    if (recvbuf(rank+2) /= -1) error stop "MPI_Scatterv: wrote past recvcount"

    ! MPI_IN_PLACE at the root: the root keeps its part in sendbuf
    recvbuf = -1
    if (rank == 0) then
        call MPI_Scatterv(sendbuf, sendcounts, displs, MPI_DOUBLE_PRECISION, MPI_IN_PLACE, &
            1, MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, ierr)
        if (sendbuf(1) /= 1) error stop "MPI_Scatterv with MPI_IN_PLACE: sendbuf changed"
        if (any(recvbuf /= -1)) error stop "MPI_Scatterv with MPI_IN_PLACE: recvbuf changed"
    else
        call MPI_Scatterv(sendbuf, sendcounts, displs, MPI_DOUBLE_PRECISION, recvbuf, &
            rank+1, MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, ierr)
        do k = 1, rank + 1
            if (recvbuf(k) /= 100*rank + k) error stop "MPI_Scatterv with MPI_IN_PLACE: wrong result"
        end do
    end if
    if (ierr /= MPI_SUCCESS) error stop "MPI_Scatterv with MPI_IN_PLACE failed"

    if (rank == 0) print *, "scatterv_1: OK"
    call MPI_Finalize(ierr)
end program scatterv_1
