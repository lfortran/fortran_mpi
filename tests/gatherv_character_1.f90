program gatherv_character_1
    ! MPI_Gatherv of character(len=10) arrays with MPI_CHARACTER: rank r sends
    ! r + 1 strings, and the root receives them all in rank order.
    use mpi
    implicit none

    integer, parameter :: root = 0, slen = 10
    integer :: ierr, rank, nprocs, i, j, k, total
    character(len=slen), allocatable :: sendbuf(:), recvbuf(:)
    character(len=slen) :: expected
    integer, allocatable :: counts(:), displs(:)

    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Init failed"
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Comm_rank failed"
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Comm_size failed"

    ! Rank r sends r + 1 strings "proc<r>_<j>"
    allocate(sendbuf(rank + 1))
    do j = 1, rank + 1
        write(sendbuf(j), '(A,I0,A,I0)') 'proc', rank, '_', j
    end do

    ! The counts and displacements are in characters
    if (rank == root) then
        allocate(counts(nprocs), displs(nprocs))
        total = 0
        do i = 1, nprocs
            counts(i) = i * slen
            displs(i) = total
            total = total + counts(i)
        end do
        allocate(recvbuf(total / slen))
        recvbuf = ''
    else
        ! Only significant at the root
        allocate(counts(1), displs(1), recvbuf(1))
    end if

    call MPI_Gatherv(sendbuf, (rank + 1) * slen, MPI_CHARACTER, &
                     recvbuf, counts, displs, MPI_CHARACTER, &
                     root, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Gatherv failed"

    if (rank == root) then
        if (size(recvbuf) /= nprocs * (nprocs + 1) / 2) error stop "wrong size of recvbuf"
        k = 0
        do i = 0, nprocs - 1
            do j = 1, i + 1
                k = k + 1
                write(expected, '(A,I0,A,I0)') 'proc', i, '_', j
                if (recvbuf(k) /= expected) then
                    print *, "recvbuf(", k, ") = '", recvbuf(k), "', expected '", expected, "'"
                    error stop "MPI_Gatherv gathered wrong strings"
                end if
            end do
        end do
        print *, "MPI_Gatherv with MPI_CHARACTER passed: ", trim(recvbuf(1)), " .. ", &
                 trim(recvbuf(size(recvbuf)))
    end if

    deallocate(sendbuf, recvbuf, counts, displs)
    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Finalize failed"
end program gatherv_character_1
