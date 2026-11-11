program test_mpi_init_rank_size
    use mpi
    implicit none
    integer :: ierr, rank, size

    ! Initialize MPI
    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) then
        print *, "MPI_Init failed with error code: ", ierr
        error stop 1
    end if

    ! Get rank and size
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    if (ierr /= MPI_SUCCESS) then
        print *, "MPI_Comm_rank failed with error code: ", ierr
        error stop 1
    end if

    call MPI_Comm_size(MPI_COMM_WORLD, size, ierr)
    if (ierr /= MPI_SUCCESS) then
        print *, "MPI_Comm_size failed with error code: ", ierr
        error stop 1
    end if

    if (size < 1 .or. rank < 0 .or. rank >= size) then
        print *, "Invalid rank ", rank, " or size ", size
        error stop "MPI_Comm_rank/MPI_Comm_size returned an invalid rank or size"
    end if

    print *, "Hello from rank ", rank, " of ", size

    ! Finalize MPI
    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) then
        print *, "MPI_Finalize failed with error code: ", ierr
        error stop 1
    end if
end program test_mpi_init_rank_size
