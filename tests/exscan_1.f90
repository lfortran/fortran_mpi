program exscan_1
    use mpi, only: MPI_Init, MPI_Finalize, MPI_Comm_rank, MPI_Comm_size, &
                   MPI_Exscan, MPI_COMM_WORLD, MPI_INTEGER, MPI_SUM, &
                   MPI_MAX, MPI_SUCCESS
    implicit none

    integer :: ierr, rank, nprocs
    integer :: sendval, recvval, expected

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)

    sendval = rank + 1
    recvval = -1

    call MPI_Exscan(sendval, recvval, 1, MPI_INTEGER, MPI_SUM, &
                    MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) then
        print *, "Rank", rank, ": MPI_Exscan failed with error code", ierr
        error stop 1
    end if

    if (rank == 0) then
        expected = -1
    else
        expected = rank * (rank + 1) / 2
    end if

    if (rank /= 0 .and. recvval /= expected) then
        print *, "Rank", rank, ": recvval =", recvval, "expected", expected
        error stop 2
    end if

    recvval = -1
    call MPI_Exscan(sendval, recvval, 1, MPI_INTEGER, MPI_MAX, &
                    MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) then
        print *, "Rank", rank, ": MPI_Exscan(MAX) failed with error code", ierr
        error stop 3
    end if
    if (rank > 0 .and. recvval /= rank) then
        print *, "Rank", rank, ": MAX Exscan got", recvval, "expected", rank
        error stop 4
    end if

    if (rank == nprocs - 1) then
        print *, "MPI_Exscan test passed (nprocs=", nprocs, ") last rank SUM recvval=", &
                 rank * (rank + 1) / 2, " MAX recvval=", recvval
    end if

    call MPI_Finalize(ierr)
end program exscan_1
