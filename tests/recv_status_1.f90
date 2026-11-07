program recv_status_1
    ! Rank 0 receives a message from every other rank with MPI_ANY_SOURCE and
    ! MPI_ANY_TAG. The status must name the sender and the tag.
    use mpi
    implicit none
    integer :: ierr, rank, nproc, i, status(MPI_STATUS_SIZE)
    real(8) :: buf(1)
    logical :: seen(0:63)

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nproc, ierr)

    if (rank == 0) then
        seen = .false.
        do i = 1, nproc - 1
            call MPI_Recv(buf, 1, MPI_DOUBLE_PRECISION, MPI_ANY_SOURCE, MPI_ANY_TAG, &
                          MPI_COMM_WORLD, status, ierr)
            if (status(MPI_SOURCE) < 1 .or. status(MPI_SOURCE) >= nproc) then
                print *, "Invalid status(MPI_SOURCE):", status(MPI_SOURCE)
                error stop
            end if
            if (status(MPI_TAG) /= 100 + status(MPI_SOURCE)) then
                print *, "status(MPI_TAG) =", status(MPI_TAG), "from", status(MPI_SOURCE)
                error stop
            end if
            if (int(buf(1)) /= status(MPI_SOURCE) .or. seen(status(MPI_SOURCE))) then
                print *, "Unexpected message", buf(1), "from", status(MPI_SOURCE)
                error stop
            end if
            seen(status(MPI_SOURCE)) = .true.
        end do
    else
        buf(1) = rank
        call MPI_Ssend(buf, 1, MPI_DOUBLE_PRECISION, 0, 100 + rank, MPI_COMM_WORLD, ierr)
    end if

    call MPI_Finalize(ierr)
end program recv_status_1
