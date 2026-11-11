program test_reduce
    use mpi
    implicit none

    integer :: ierr, rank, size, comm, root
    integer :: sendval, recvval

    comm = MPI_COMM_WORLD

    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Init failed"
    call MPI_Comm_rank(comm, rank, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Comm_rank failed"
    call MPI_Comm_size(comm, size, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Comm_size failed"

    ! Each rank will hold its rank ID in 'sendval'
    sendval = rank

    ! We do a sum over all ranks, to every root in turn
    do root = 0, size - 1
        recvval = -999  ! dummy init

        call MPI_Reduce(sendval, recvval, 1, MPI_INTEGER, MPI_SUM, root, comm, ierr)
        if (ierr /= MPI_SUCCESS) error stop "MPI_Reduce failed"

        if (rank == root) then
            print *, "Root", root, "received sum of ranks = ", recvval
            if (recvval /= size * (size - 1) / 2) then
                print *, "expected", size * (size - 1) / 2
                error stop "wrong sum from MPI_Reduce"
            end if
        end if
    end do

    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Finalize failed"
end program test_reduce
