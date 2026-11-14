program scan_2
    use mpi, only: MPI_Init, MPI_Finalize, MPI_Comm_rank, MPI_Comm_size, &
                   MPI_Scan, MPI_COMM_WORLD, MPI_INTEGER, MPI_SUM, &
                   MPI_MAX, MPI_SUCCESS
    implicit none

    integer :: ierr, rank, nprocs
    integer :: sendval, recvval
    integer :: sendarr(2), recvarr(2)

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)

    ! Inclusive prefix sum: rank r gets 1 + 2 + ... + (r+1)
    sendval = rank + 1
    recvval = -1
    call MPI_Scan(sendval, recvval, 1, MPI_INTEGER, MPI_SUM, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Scan(SUM) failed"
    if (recvval /= (rank + 1) * (rank + 2) / 2) then
        print *, "Rank", rank, ": SUM scan got", recvval
        error stop 1
    end if

    ! Inclusive prefix max of increasing values is the value itself
    recvval = -1
    call MPI_Scan(sendval, recvval, 1, MPI_INTEGER, MPI_MAX, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Scan(MAX) failed"
    if (recvval /= rank + 1) then
        print *, "Rank", rank, ": MAX scan got", recvval
        error stop 2
    end if

    ! Array buffers
    sendarr = [rank + 1, 1]
    recvarr = -1
    call MPI_Scan(sendarr, recvarr, 2, MPI_INTEGER, MPI_SUM, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Scan(array) failed"
    if (recvarr(1) /= (rank + 1) * (rank + 2) / 2 .or. recvarr(2) /= rank + 1) then
        print *, "Rank", rank, ": array scan got", recvarr
        error stop 3
    end if

    if (rank == nprocs - 1) print *, "MPI_Scan test passed, nprocs =", nprocs
    call MPI_Finalize(ierr)
end program scan_2
