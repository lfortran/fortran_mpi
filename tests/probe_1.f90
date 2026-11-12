program probe_1
    ! MPI_Probe, MPI_Iprobe and MPI_Get_count: receive messages whose size
    ! the receiver does not know in advance
    use mpi
    implicit none
    integer :: ierr, rank, nprocs, left, right, count, request, i
    integer :: status(MPI_STATUS_SIZE)
    integer, allocatable :: ibuf(:), irecv(:)
    real(8) :: dbuf(2), drecv(2)
    character(len=3) :: cbuf, crecv
    logical :: flag

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    left = mod(rank - 1 + nprocs, nprocs)
    right = mod(rank + 1, nprocs)

    ! MPI_Probe with wildcards: rank r sends r+3 integers to the right
    allocate(ibuf(rank+3))
    ibuf = [(10*rank + i, i = 1, rank + 3)]
    call MPI_Isend(ibuf, rank+3, MPI_INTEGER, right, 5, MPI_COMM_WORLD, request, ierr)
    call MPI_Probe(MPI_ANY_SOURCE, MPI_ANY_TAG, MPI_COMM_WORLD, status, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Probe failed"
    if (status(MPI_SOURCE) /= left) error stop "MPI_Probe: wrong MPI_SOURCE"
    if (status(MPI_TAG) /= 5) error stop "MPI_Probe: wrong MPI_TAG"
    call MPI_Get_count(status, MPI_INTEGER, count, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Get_count failed"
    if (count /= left + 3) then
        print *, "rank", rank, ": count =", count, ", expected", left + 3
        error stop "MPI_Get_count: wrong count"
    end if
    allocate(irecv(count))
    call MPI_Recv(irecv, count, MPI_INTEGER, status(MPI_SOURCE), status(MPI_TAG), &
        MPI_COMM_WORLD, status, ierr)
    if (any(irecv /= [(10*left + i, i = 1, left + 3)])) error stop "MPI_Probe: wrong data"
    ! MPI_Get_count on the status of MPI_Recv
    call MPI_Get_count(status, MPI_INTEGER, count, ierr)
    if (count /= left + 3) error stop "MPI_Get_count after MPI_Recv: wrong count"
    call MPI_Wait(request, MPI_STATUS_IGNORE, ierr)

    ! Nobody sends with tag 99
    call MPI_Iprobe(MPI_ANY_SOURCE, 99, MPI_COMM_WORLD, flag, status, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Iprobe failed"
    if (flag) error stop "MPI_Iprobe: found a message that was never sent"

    ! MPI_Iprobe until the message is there
    dbuf = [rank + 0.5d0, rank + 0.25d0]
    call MPI_Isend(dbuf, 2, MPI_DOUBLE_PRECISION, right, 6, MPI_COMM_WORLD, request, ierr)
    flag = .false.
    do while (.not. flag)
        call MPI_Iprobe(left, 6, MPI_COMM_WORLD, flag, status, ierr)
        if (ierr /= MPI_SUCCESS) error stop "MPI_Iprobe failed"
    end do
    if (status(MPI_SOURCE) /= left) error stop "MPI_Iprobe: wrong MPI_SOURCE"
    if (status(MPI_TAG) /= 6) error stop "MPI_Iprobe: wrong MPI_TAG"
    call MPI_Get_count(status, MPI_DOUBLE_PRECISION, count, ierr)
    if (count /= 2) error stop "MPI_Get_count: wrong count of MPI_DOUBLE_PRECISION"
    call MPI_Recv(drecv, 2, MPI_DOUBLE_PRECISION, left, 6, MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
    if (any(drecv /= [left + 0.5d0, left + 0.25d0])) error stop "MPI_Iprobe: wrong data"
    call MPI_Wait(request, MPI_STATUS_IGNORE, ierr)

    ! 3 characters are not a whole number of integers: MPI_UNDEFINED
    cbuf = "abc"
    call MPI_Isend(cbuf, 3, MPI_CHARACTER, right, 7, MPI_COMM_WORLD, request, ierr)
    call MPI_Probe(left, 7, MPI_COMM_WORLD, status, ierr)
    call MPI_Get_count(status, MPI_CHARACTER, count, ierr)
    if (count /= 3) error stop "MPI_Get_count: wrong count of MPI_CHARACTER"
    call MPI_Get_count(status, MPI_INTEGER, count, ierr)
    if (count /= MPI_UNDEFINED) then
        print *, "rank", rank, ": count =", count
        error stop "MPI_Get_count: count is not MPI_UNDEFINED"
    end if
    call MPI_Recv(crecv, 3, MPI_CHARACTER, left, 7, MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
    if (crecv /= "abc") error stop "MPI_Probe: wrong characters"
    call MPI_Wait(request, MPI_STATUS_IGNORE, ierr)

    if (rank == 0) print *, "probe_1: OK"
    call MPI_Finalize(ierr)
end program probe_1
