program wait_1
    use mpi, only: MPI_Init, MPI_Finalize, MPI_Comm_rank, MPI_Comm_size, &
                   MPI_Isend, MPI_Irecv, MPI_Wait, &
                   MPI_COMM_WORLD, MPI_DOUBLE_PRECISION, &
                   MPI_STATUS_SIZE, MPI_SUCCESS
    implicit none

    integer, parameter :: lbuf = 100
    integer, parameter :: ntype_real = MPI_DOUBLE_PRECISION
    real(8), dimension(lbuf, 1) :: sbuf, rbuf
    integer :: req_send, req_recv
    integer :: status(MPI_STATUS_SIZE)
    integer :: ierr, myrank, nprocs, iproc_tp, iproc_tm
    integer :: comm_all, tag
    real(8) :: expected
    real(8), parameter :: tol = 1.0e-10_8

    call MPI_Init(ierr)
    comm_all = MPI_COMM_WORLD
    call MPI_Comm_rank(comm_all, myrank, ierr)
    call MPI_Comm_size(comm_all, nprocs, ierr)

    tag = 1
    iproc_tp = mod(myrank + 1, nprocs)
    iproc_tm = mod(myrank - 1 + nprocs, nprocs)

    sbuf = myrank + 0.1_8

    call MPI_Isend(sbuf, lbuf, ntype_real, iproc_tp, tag, &
                   comm_all, req_send, ierr)
    call MPI_Irecv(rbuf, lbuf, ntype_real, iproc_tm, tag, &
                   comm_all, req_recv, ierr)

    call MPI_Wait(req_send, status, ierr)
    if (ierr /= MPI_SUCCESS) then
        write(*,*) 'Rank', myrank, ': MPI_Wait(send) failed with code', ierr
        error stop 1
    end if

    call MPI_Wait(req_recv, status, ierr)
    if (ierr /= MPI_SUCCESS) then
        write(*,*) 'Rank', myrank, ': MPI_Wait(recv) failed with code', ierr
        error stop 2
    end if

    expected = real(iproc_tm, 8) + 0.1_8
    if (any(abs(rbuf - expected) > tol)) then
        write(*,*) 'Rank', myrank, ': rbuf validation failed'
        write(*,*) 'Expected:', expected
        write(*,*) 'Received:', rbuf(1, 1)
        error stop 3
    end if

    if (myrank == 0) then
        write(*,*) 'MPI_Wait test passed, rbuf(1,1) =', rbuf(1, 1), ' (Expected:', expected, ')'
    end if

    call MPI_Finalize(ierr)
end program wait_1
