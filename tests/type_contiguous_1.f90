program type_contiguous_1
    ! MPI_Type_contiguous, MPI_Type_commit and MPI_Type_free
    use mpi
    implicit none
    integer :: ierr, rank, nprocs, left, right, i
    integer :: triple, pair
    integer :: buf(6), sendbuf(3), recvbuf(3)
    real(8) :: x(4), y(4)

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    left = mod(rank - 1 + nprocs, nprocs)
    right = mod(rank + 1, nprocs)

    call MPI_Type_contiguous(3, MPI_INTEGER, triple, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Type_contiguous failed"
    call MPI_Type_contiguous(2, MPI_DOUBLE_PRECISION, pair, ierr)
    if (triple == MPI_DATATYPE_NULL .or. pair == MPI_DATATYPE_NULL) &
        error stop "MPI_Type_contiguous returned MPI_DATATYPE_NULL"
    if (triple == pair) error stop "MPI_Type_contiguous: two types with the same handle"
    call MPI_Type_commit(triple, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Type_commit failed"
    call MPI_Type_commit(pair, ierr)

    ! Broadcast 2 triples
    if (rank == 0) then
        buf = [(10*i, i = 1, 6)]
    else
        buf = -1
    end if
    call MPI_Bcast(buf, 2, triple, 0, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Bcast with a contiguous type failed"
    if (any(buf /= [(10*i, i = 1, 6)])) then
        print *, "rank", rank, ": buf =", buf
        error stop "MPI_Bcast with a contiguous type: wrong result"
    end if

    ! Send 1 triple, receive 3 integers: the type signatures match
    sendbuf = [rank, rank + 1, rank + 2]
    recvbuf = -1
    call MPI_Sendrecv(sendbuf, 1, triple, right, 0, recvbuf, 3, MPI_INTEGER, left, 0, &
        MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
    if (any(recvbuf /= [left, left + 1, left + 2])) error stop "MPI_Sendrecv with a contiguous type: wrong result"

    ! Send 4 reals, receive 2 pairs
    x = [rank + 0.5d0, rank + 1.5d0, rank + 2.5d0, rank + 3.5d0]
    y = -1
    call MPI_Sendrecv(x, 4, MPI_DOUBLE_PRECISION, right, 1, y, 2, pair, left, 1, &
        MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
    if (any(y /= [left + 0.5d0, left + 1.5d0, left + 2.5d0, left + 3.5d0])) &
        error stop "MPI_Sendrecv into a contiguous type: wrong result"

    call MPI_Type_free(triple, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Type_free failed"
    if (triple /= MPI_DATATYPE_NULL) error stop "MPI_Type_free: handle is not MPI_DATATYPE_NULL"
    call MPI_Type_free(pair, ierr)
    if (pair /= MPI_DATATYPE_NULL) error stop "MPI_Type_free: handle is not MPI_DATATYPE_NULL"

    if (rank == 0) print *, "type_contiguous_1: OK"
    call MPI_Finalize(ierr)
end program type_contiguous_1
