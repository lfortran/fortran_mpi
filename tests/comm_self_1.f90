program comm_self_1
    use mpi
    implicit none
    integer :: ierr, rank, size

    call MPI_Init(ierr)

    call MPI_Comm_rank(MPI_COMM_SELF, rank, ierr)
    if (ierr /= MPI_SUCCESS) then
        print *, "MPI_Comm_rank(MPI_COMM_SELF) failed: ", ierr
        error stop 1
    end if
    if (rank /= 0) then
        print *, "Expected rank 0 in MPI_COMM_SELF, got ", rank
        error stop 2
    end if

    call MPI_Comm_size(MPI_COMM_SELF, size, ierr)
    if (ierr /= MPI_SUCCESS) then
        print *, "MPI_Comm_size(MPI_COMM_SELF) failed: ", ierr
        error stop 3
    end if
    if (size /= 1) then
        print *, "Expected size 1 in MPI_COMM_SELF, got ", size
        error stop 4
    end if

    call MPI_Barrier(MPI_COMM_SELF, ierr)
    if (ierr /= MPI_SUCCESS) then
        print *, "MPI_Barrier(MPI_COMM_SELF) failed: ", ierr
        error stop 5
    end if

    print *, "MPI_COMM_SELF test passed"

    call MPI_Finalize(ierr)
end program comm_self_1
