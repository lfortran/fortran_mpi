program alltoall_1
    ! MPI_Alltoall with 2 values per rank, then with MPI_IN_PLACE
    use mpi
    implicit none
    integer :: ierr, rank, nprocs, j
    integer, allocatable :: sendbuf(:,:), recvbuf(:,:)
    real(8), allocatable :: buf(:)

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)

    ! Column j goes to rank j-1
    allocate(sendbuf(2, nprocs), recvbuf(2, nprocs))
    do j = 1, nprocs
        sendbuf(:, j) = [100*rank + j - 1, -(100*rank + j - 1)]
    end do
    recvbuf = 0
    call MPI_Alltoall(sendbuf, 2, MPI_INTEGER, recvbuf, 2, MPI_INTEGER, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Alltoall failed"
    ! Column j came from rank j-1
    do j = 1, nprocs
        if (recvbuf(1, j) /= 100*(j-1) + rank .or. recvbuf(2, j) /= -(100*(j-1) + rank)) then
            print *, "rank", rank, ": from rank", j-1, ":", recvbuf(:, j)
            error stop "MPI_Alltoall: wrong result"
        end if
    end do

    allocate(buf(nprocs))
    do j = 1, nprocs
        buf(j) = rank + 0.5d0*(j-1)
    end do
    call MPI_Alltoall(MPI_IN_PLACE, 0, MPI_DATATYPE_NULL, buf, 1, MPI_DOUBLE_PRECISION, &
        MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Alltoall with MPI_IN_PLACE failed"
    do j = 1, nprocs
        if (buf(j) /= (j-1) + 0.5d0*rank) then
            print *, "rank", rank, ": buf =", buf
            error stop "MPI_Alltoall with MPI_IN_PLACE: wrong result"
        end if
    end do

    if (rank == 0) print *, "alltoall_1: OK"
    call MPI_Finalize(ierr)
end program alltoall_1
