program ssend_example
    use mpi
    implicit none
    
    integer, parameter :: ARRAY_SIZE = 10
    integer :: rank, size, ierr, i
    real(8) :: buffer(10)
    integer :: tag = 100
    integer, dimension(MPI_STATUS_SIZE) :: status
    
    ! allocate(buffer(10))
    ! Initialize MPI environment
    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Init failed"
    
    ! Get rank (process ID) and size (total number of processes)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Comm_rank failed"
    call MPI_Comm_size(MPI_COMM_WORLD, size, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Comm_size failed"
    
    if (size < 2) then
        if (rank == 0) then
            print *, "This example requires at least 2 MPI processes"
        end if
        call MPI_Finalize(ierr)
        stop
    end if
    
    ! Process 0 sends data to process 1
    if (rank == 0) then
        ! Initialize the buffer with some values
        do i = 1, 10
            buffer(i) = i * 10
        end do
        
        print *, "Process 0: Sending data using MPI_Ssend..."
        
        ! Using MPI_Ssend (synchronous send)
        ! This will block until process 1 starts receiving
        call MPI_Ssend(buffer, 10, MPI_REAL8, 1, tag, MPI_COMM_WORLD, ierr)
        if (ierr /= MPI_SUCCESS) error stop "MPI_Ssend failed"
        
        print *, "Process 0: Send completed successfully"
        
    ! Process 1 receives data from process 0
    else if (rank == 1) then
        
        print *, "Process 1: Receiving data..."
        
        ! Clear the buffer
        buffer = 0
        
        ! Receive the message
        call MPI_Recv(buffer, 10, MPI_REAL8, 0, tag, MPI_COMM_WORLD, status, ierr)
        if (ierr /= MPI_SUCCESS) error stop "MPI_Recv failed"
        
        print *, "Process 1: Received data:"
        ! write(*, '(10I5)') buffer
        print *, buffer
        do i = 1, 10
            if (buffer(i) /= i * 10) then
                print *, "buffer(", i, ") =", buffer(i), "expected", i * 10
                error stop "wrong data received from MPI_Ssend"
            end if
        end do
        if (status(MPI_SOURCE) /= 0 .or. status(MPI_TAG) /= tag) &
            error stop "wrong status of the receive"
    end if
    
    ! Finalize MPI environment
    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Finalize failed"
end program ssend_example