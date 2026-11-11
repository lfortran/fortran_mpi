program test_bcast
    use mpi 
    implicit none

    integer :: ierror, rank, size, comm, root, d
    comm = MPI_COMM_WORLD
    d = 0
    ! Initialize MPI
    call MPI_Init(ierror)
    if (ierror /= MPI_SUCCESS) error stop "MPI_Init failed"

    ! Get our rank and the total number of processes
    call MPI_Comm_rank(comm, rank, ierror)
    if (ierror /= MPI_SUCCESS) error stop "MPI_Comm_rank failed"
    call MPI_Comm_size(comm, size, ierror)
    if (ierror /= MPI_SUCCESS) error stop "MPI_Comm_size failed"

    ! Broadcast an integer from every root in turn
    do root = 0, size - 1
        d = 0
        if (rank == root) then
            d = root + 1
        end if

        call MPI_Bcast(d, 1, MPI_INTEGER, root, comm, ierror)
        if (ierror /= MPI_SUCCESS) then
            print *, "Error in MPI_Bcast:", ierror
            error stop "MPI_Bcast failed"
        end if

        if (d /= root + 1) then
            print *, "Rank=", rank, " received integer=", d, " from root", root, &
                     " expected", root + 1
            error stop "wrong value broadcast"
        end if
    end do

    ! Print result on each rank
    print *, "Rank=", rank, " received integer=", d

    ! Finalize MPI
    call MPI_Finalize(ierror)
    if (ierror /= MPI_SUCCESS) error stop "MPI_Finalize failed"
end program test_bcast
