program comm_dup_1
    use mpi
    implicit none

    integer :: communicator, new_comm
    integer :: ier, rank, size, new_rank, new_size
    integer :: sent_dup, sent_world, received
    integer :: reqs(2), status(MPI_STATUS_SIZE)
    type :: context_t
        integer :: mpi_communicator
    end type context_t

    type(context_t) :: context

    call MPI_Init(ier)
    if (ier /= MPI_SUCCESS) error stop "MPI_Init failed"

    communicator = MPI_COMM_WORLD
    call MPI_Comm_rank(communicator, rank, ier)
    if (ier /= MPI_SUCCESS) error stop "MPI_Comm_rank failed"
    call MPI_Comm_size(communicator, size, ier)
    if (ier /= MPI_SUCCESS) error stop "MPI_Comm_size failed"

    call MPI_Comm_dup(communicator, context%mpi_communicator, ier)

    if (ier /= MPI_SUCCESS) then
        print *, "Error duplicating communicator"
        error stop
        ! call MPI_Abort(communicator, 1, ier)
    end if

    new_comm = context%mpi_communicator

    print *, 'Process ', rank, ' of ', size, ' has duplicated communicator ', new_comm

    if (new_comm == MPI_COMM_NULL .or. new_comm == MPI_COMM_WORLD) then
        print *, 'Rank', rank, ': MPI_Comm_dup returned', new_comm
        error stop "MPI_Comm_dup did not return a new communicator"
    end if

    ! The duplicate has the same ranks
    call MPI_Comm_rank(new_comm, new_rank, ier)
    if (ier /= MPI_SUCCESS) error stop "MPI_Comm_rank(new_comm) failed"
    call MPI_Comm_size(new_comm, new_size, ier)
    if (ier /= MPI_SUCCESS) error stop "MPI_Comm_size(new_comm) failed"
    if (new_rank /= rank .or. new_size /= size) then
        print *, 'Rank', rank, ': duplicate rank, size =', new_rank, new_size
        error stop "wrong rank or size in the duplicated communicator"
    end if

    ! The duplicate is a separate communication context: rank 0 sends on
    ! MPI_COMM_WORLD first and on the duplicate second, with the same tag;
    ! rank 1 receives on the duplicate first and must get that message.
    if (rank == 0 .and. size > 1) then
        sent_world = 7
        sent_dup = 42
        call MPI_Isend(sent_world, 1, MPI_INTEGER, 1, 99, communicator, reqs(1), ier)
        if (ier /= MPI_SUCCESS) error stop "MPI_Isend on MPI_COMM_WORLD failed"
        call MPI_Isend(sent_dup, 1, MPI_INTEGER, 1, 99, new_comm, reqs(2), ier)
        if (ier /= MPI_SUCCESS) error stop "MPI_Isend on the duplicate failed"
        call MPI_Waitall(2, reqs, MPI_STATUSES_IGNORE, ier)
        if (ier /= MPI_SUCCESS) error stop "MPI_Waitall failed"
        print *, "Process 0 sent message using duplicated communicator"
    else if (rank == 1) then
        received = -1
        call MPI_Recv(received, 1, MPI_INTEGER, 0, 99, new_comm, status, ier)
        if (ier /= MPI_SUCCESS) error stop "MPI_Recv on the duplicate failed"
        print *, 'Process 1 received: ', received, ' using duplicated communicator'
        if (received /= 42) error stop "wrong message received on the duplicate"
        if (status(MPI_SOURCE) /= 0 .or. status(MPI_TAG) /= 99) &
            error stop "wrong status of the receive on the duplicate"
        received = -1
        call MPI_Recv(received, 1, MPI_INTEGER, 0, 99, communicator, MPI_STATUS_IGNORE, ier)
        if (ier /= MPI_SUCCESS) error stop "MPI_Recv on MPI_COMM_WORLD failed"
        if (received /= 7) error stop "wrong message received on MPI_COMM_WORLD"
    end if

    call MPI_Comm_free(new_comm, ier)
    if (ier /= MPI_SUCCESS) error stop "MPI_Comm_free failed"
    if (new_comm /= MPI_COMM_NULL) error stop "MPI_Comm_free did not set MPI_COMM_NULL"

    call MPI_Finalize(ier)
    if (ier /= MPI_SUCCESS) error stop "MPI_Finalize failed"
end program
