program gather_1
    ! MPI_Gather to the last rank, and with MPI_IN_PLACE at the root
    use mpi
    implicit none
    integer :: ierr, rank, nprocs, root, i
    integer :: sendbuf(2)
    integer, allocatable :: recvbuf(:)
    real(8) :: col(3)
    real(8), allocatable :: a(:,:)

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)

    root = nprocs - 1
    sendbuf = [10*rank + 1, 10*rank + 2]
    allocate(recvbuf(2*nprocs))
    recvbuf = -1
    call MPI_Gather(sendbuf, 2, MPI_INTEGER, recvbuf, 2, MPI_INTEGER, root, &
        MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Gather failed"
    if (rank == root) then
        do i = 0, nprocs - 1
            if (recvbuf(2*i+1) /= 10*i + 1 .or. recvbuf(2*i+2) /= 10*i + 2) then
                print *, "rank", rank, ": wrong data from rank", i, recvbuf(2*i+1:2*i+2)
                error stop "MPI_Gather: wrong result"
            end if
        end do
    else
        if (any(recvbuf /= -1)) error stop "MPI_Gather: recvbuf changed on a non-root rank"
    end if

    ! MPI_IN_PLACE: the root's own contribution is already in place
    allocate(a(3, nprocs))
    a = -1
    col = rank + [0.25d0, 0.5d0, 0.75d0]
    if (rank == 0) then
        a(:, 1) = col
        call MPI_Gather(MPI_IN_PLACE, 3, MPI_DOUBLE_PRECISION, a, 3, MPI_DOUBLE_PRECISION, &
            0, MPI_COMM_WORLD, ierr)
        do i = 1, nprocs
            if (any(a(:, i) /= (i-1) + [0.25d0, 0.5d0, 0.75d0])) then
                print *, "column", i, ":", a(:, i)
                error stop "MPI_Gather with MPI_IN_PLACE: wrong result"
            end if
        end do
    else
        call MPI_Gather(col, 3, MPI_DOUBLE_PRECISION, a, 3, MPI_DOUBLE_PRECISION, &
            0, MPI_COMM_WORLD, ierr)
    end if
    if (ierr /= MPI_SUCCESS) error stop "MPI_Gather with MPI_IN_PLACE failed"

    if (rank == 0) print *, "gather_1: OK"
    call MPI_Finalize(ierr)
end program gather_1
