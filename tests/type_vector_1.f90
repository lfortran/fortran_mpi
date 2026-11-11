program type_vector_1
    ! MPI_Type_vector: send a row of a 4 x 5 matrix, and blocks of two
    use mpi
    implicit none
    integer, parameter :: m = 4, n = 5
    integer :: ierr, rank, nprocs, left, right, k
    integer :: row, blocks
    ! A 4 x 5 matrix, stored by columns: a(i + m*(j-1)) is element (i, j)
    real(8) :: a(m*n), s(m*n), r(4)

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    left = mod(rank - 1 + nprocs, nprocs)
    right = mod(rank + 1, nprocs)

    ! One row: n elements, m apart
    call MPI_Type_vector(n, 1, m, MPI_DOUBLE_PRECISION, row, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Type_vector failed"
    call MPI_Type_commit(row, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Type_commit failed"

    ! Broadcast row 2: it starts at a(2)
    if (rank == 0) then
        a = [(real(k, 8), k = 1, m*n)]
    else
        a = -1
    end if
    call MPI_Bcast(a(2:), 1, row, 0, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Bcast with a vector type failed"
    do k = 1, m*n
        if (rank == 0 .or. mod(k - 1, m) == 1) then
            if (a(k) /= k) then
                print *, "rank", rank, ": a =", a
                error stop "MPI_Bcast with a vector type: wrong row"
            end if
        else
            if (a(k) /= -1) then
                print *, "rank", rank, ": a =", a
                error stop "MPI_Bcast with a vector type: wrote outside the row"
            end if
        end if
    end do

    ! Two blocks of 2 elements, m apart: s(1:2) and s(5:6)
    call MPI_Type_vector(2, 2, m, MPI_DOUBLE_PRECISION, blocks, ierr)
    call MPI_Type_commit(blocks, ierr)
    s = [(100*rank + k, k = 1, m*n)]
    r = -1
    call MPI_Sendrecv(s, 1, blocks, right, 0, r, 4, MPI_DOUBLE_PRECISION, left, 0, &
        MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Sendrecv with a vector type failed"
    if (any(r /= 100*left + [1, 2, 5, 6])) then
        print *, "rank", rank, ": r =", r
        error stop "MPI_Sendrecv with a vector type: wrong result"
    end if

    call MPI_Type_free(row, ierr)
    if (row /= MPI_DATATYPE_NULL) error stop "MPI_Type_free: handle is not MPI_DATATYPE_NULL"
    call MPI_Type_free(blocks, ierr)
    if (blocks /= MPI_DATATYPE_NULL) error stop "MPI_Type_free: handle is not MPI_DATATYPE_NULL"

    if (rank == 0) print *, "type_vector_1: OK"
    call MPI_Finalize(ierr)
end program type_vector_1
