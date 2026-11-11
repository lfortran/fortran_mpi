program test_recv_1  
    use mpi  
    implicit none  

    integer :: ierr, rank, size, comm, tag, i
    real(8), dimension(5) :: buf  
    integer, dimension(MPI_STATUS_SIZE) :: status  

    comm = MPI_COMM_WORLD  
    tag  = 100  

    call MPI_Init(ierr)  
    if (ierr /= MPI_SUCCESS) error stop "MPI_Init failed"
    call MPI_Comm_rank(comm, rank, ierr)  
    if (ierr /= MPI_SUCCESS) error stop "MPI_Comm_rank failed"
    call MPI_Comm_size(comm, size, ierr)  
    if (ierr /= MPI_SUCCESS) error stop "MPI_Comm_size failed"

    if (size < 2) then  
        print *, "This test works best with at least 2 MPI processes."  
    else  
        if (rank == 0) then  
            ! Rank 0: Prepare data and send synchronously.  
            buf = (/ 1.0d0, 2.0d0, 3.0d0, 4.0d0, 5.0d0 /)  
            call MPI_Ssend(buf, 5, MPI_REAL8, 1, tag, comm, ierr)  
            if (ierr /= MPI_SUCCESS) error stop "MPI_Ssend failed"
            print *, "Rank 0 sent data."  
        else if (rank == 1) then  
            ! Rank 1: Receive the data.  
            buf = 0.0d0  ! initialize to zeros  
            call MPI_Recv(buf, 5, MPI_REAL8, 0, tag, comm, status, ierr)  
            if (ierr /= MPI_SUCCESS) error stop "MPI_Recv failed"
            print *, "Rank 1 received data: ", buf  
            if (any(buf /= [(real(i, 8), i = 1, 5)])) error stop "wrong data received"
            if (status(MPI_SOURCE) /= 0 .or. status(MPI_TAG) /= tag) &
                error stop "wrong status of the receive"
        end if  
    end if  

    call MPI_Finalize(ierr)  
    if (ierr /= MPI_SUCCESS) error stop "MPI_Finalize failed"

end program test_recv_1
