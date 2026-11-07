program send_1
    ! MPI_Send of real(8) and real(4) arrays, and to MPI_PROC_NULL.
    use mpi
    implicit none
    integer :: ierr, rank, nprocs, i, status(MPI_STATUS_SIZE)
    real(8) :: a(5)
    real(4) :: b(3)

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)

    a = [(real(i, 8), i = 1, 5)]
    b = [(real(10*i, 4), i = 1, 3)]
    call MPI_Send(a, 5, MPI_REAL8, MPI_PROC_NULL, 1, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Send to MPI_PROC_NULL failed"

    if (nprocs > 1) then
        if (rank == 0) then
            call MPI_Send(a, 5, MPI_REAL8, 1, 1, MPI_COMM_WORLD, ierr)
            call MPI_Send(b, 3, MPI_REAL4, 1, 2, MPI_COMM_WORLD, ierr)
        else if (rank == 1) then
            a = 0
            b = 0
            call MPI_Recv(a, 5, MPI_REAL8, 0, 1, MPI_COMM_WORLD, status, ierr)
            if (any(a /= [(real(i, 8), i = 1, 5)])) error stop "wrong real(8) array"
            if (status(MPI_SOURCE) /= 0 .or. status(MPI_TAG) /= 1) error stop "wrong status"
            call MPI_Recv(b, 3, MPI_REAL4, 0, 2, MPI_COMM_WORLD, MPI_STATUS_IGNORE, ierr)
            if (any(b /= [(real(10*i, 4), i = 1, 3)])) error stop "wrong real(4) array"
        end if
    end if

    call MPI_Finalize(ierr)
end program send_1
