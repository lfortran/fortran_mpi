program waitany_1
    ! MPI_Waitany: receive one message from each neighbor, in either order
    use mpi
    implicit none
    integer :: ierr, rank, nprocs, left, right, i, index
    integer :: recv_requests(2), send_requests(2)
    integer :: status(MPI_STATUS_SIZE)
    integer :: from_left, from_right, to_left, to_right
    logical :: done(2)

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    left = mod(rank - 1 + nprocs, nprocs)
    right = mod(rank + 1, nprocs)

    ! Tag 1 travels to the right, tag 2 to the left
    from_left = -1
    from_right = -1
    to_right = 1000 + rank
    to_left = 2000 + rank
    call MPI_Irecv(from_left, 1, MPI_INTEGER, left, 1, MPI_COMM_WORLD, recv_requests(1), ierr)
    call MPI_Irecv(from_right, 1, MPI_INTEGER, right, 2, MPI_COMM_WORLD, recv_requests(2), ierr)
    call MPI_Isend(to_right, 1, MPI_INTEGER, right, 1, MPI_COMM_WORLD, send_requests(1), ierr)
    call MPI_Isend(to_left, 1, MPI_INTEGER, left, 2, MPI_COMM_WORLD, send_requests(2), ierr)

    done = .false.
    do i = 1, 2
        call MPI_Waitany(2, recv_requests, index, status, ierr)
        if (ierr /= MPI_SUCCESS) error stop "MPI_Waitany failed"
        if (index < 1 .or. index > 2) then
            print *, "rank", rank, ": index =", index
            error stop "MPI_Waitany: index out of range"
        end if
        if (done(index)) error stop "MPI_Waitany: the same index twice"
        done(index) = .true.
        if (recv_requests(index) /= MPI_REQUEST_NULL) error stop "MPI_Waitany: request not freed"
        if (status(MPI_TAG) /= index) error stop "MPI_Waitany: wrong MPI_TAG"
        if (index == 1) then
            if (status(MPI_SOURCE) /= left) error stop "MPI_Waitany: wrong MPI_SOURCE"
            if (from_left /= 1000 + left) error stop "MPI_Waitany: wrong data from the left"
        else
            if (status(MPI_SOURCE) /= right) error stop "MPI_Waitany: wrong MPI_SOURCE"
            if (from_right /= 2000 + right) error stop "MPI_Waitany: wrong data from the right"
        end if
    end do

    ! No active request left
    call MPI_Waitany(2, recv_requests, index, status, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Waitany failed"
    if (index /= MPI_UNDEFINED) then
        print *, "rank", rank, ": index =", index
        error stop "MPI_Waitany: index is not MPI_UNDEFINED"
    end if

    ! The sends, with MPI_STATUS_IGNORE
    do i = 1, 2
        call MPI_Waitany(2, send_requests, index, MPI_STATUS_IGNORE, ierr)
        if (ierr /= MPI_SUCCESS) error stop "MPI_Waitany with MPI_STATUS_IGNORE failed"
        if (index < 1 .or. index > 2) error stop "MPI_Waitany: index out of range"
    end do
    if (any(send_requests /= MPI_REQUEST_NULL)) error stop "MPI_Waitany: requests not freed"

    if (rank == 0) print *, "waitany_1: OK"
    call MPI_Finalize(ierr)
end program waitany_1
