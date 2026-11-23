program abort_1
    use mpi
    use iso_c_binding, only: c_int
    implicit none
    integer :: ierr, comm, rank, nprocs
    interface
        integer(c_int) function abort_ready(comm, nprocs, rank) bind(C)
            import c_int
            integer(c_int), value :: comm, nprocs, rank
        end function
        subroutine abort_returned(code) bind(C)
            import c_int
            integer(c_int), value :: code
        end subroutine
    end interface
    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) error stop "abort init"
    call MPI_Comm_dup(MPI_COMM_WORLD, comm, ierr)
    if (ierr /= MPI_SUCCESS) error stop "abort dup"
    call MPI_Comm_rank(comm, rank, ierr)
    if (ierr /= MPI_SUCCESS) error stop "abort rank"
    call MPI_Comm_size(comm, nprocs, ierr)
    if (ierr /= MPI_SUCCESS) error stop "abort size"
    if (abort_ready(comm, nprocs, rank) /= 0) error stop "abort C communicator check"
    call MPI_Barrier(comm, ierr)
    if (ierr /= MPI_SUCCESS) error stop "abort ready barrier"
    if (rank == 0) then
        call MPI_Abort(comm, 73, ierr)
        call abort_returned(ierr)
        error stop "MPI_Abort returned"
    end if
    call MPI_Barrier(comm, ierr)
    error stop "MPI_Abort did not terminate peers"
end program
