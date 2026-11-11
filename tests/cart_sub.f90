program cart_sub
    use mpi
    implicit none

    ! MPI variables
    integer :: rank, size, ierr, tcheck
    integer :: comm_cart, comm_new
    integer :: dims(2), coords(2)
    integer :: sub_rank, sub_size, sub_coords(1)
    logical :: periods(2), reorder, remain_dims(2)
    integer :: errs

    ! Initialize errors counter
    errs = 0

    ! Initialize dimensions to 0 (MPI_Dims_create will set them optimally)
    dims(1:2) = 0
    
    ! Periodicity settings: 
    ! - First dimension has a cyclic (wrapped-around) topology
    ! - Second dimension is non-periodic (no wrap-around)
    periods(1) = .TRUE.
    periods(2) = .FALSE.
    
    ! Allow MPI to reorder ranks for better performance
    reorder = .TRUE.

    ! Sub-communicator dimensions: 
    ! - First dimension is kept
    ! - Second dimension is removed
    remain_dims(1) = .TRUE.
    remain_dims(2) = .FALSE.

    ! Initialize MPI with thread support
    call MPI_Init_thread(MPI_THREAD_FUNNELED, tcheck, ierr)
    if (ierr /= MPI_SUCCESS) then
        print *, "Error initializing MPI"
        error stop
    end if

    ! Get rank and size in the global communicator
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, size, ierr)

    ! Automatically determine a balanced 2D grid
    call MPI_Dims_create(size, 2, dims, ierr)
    if (ierr /= MPI_SUCCESS) then
        print *, "Error creating dimensions"
        error stop
    end if
    if (dims(1) * dims(2) /= size .or. dims(1) < dims(2)) then
        print *, "MPI_Dims_create(", size, ") gave dims =", dims
        error stop "wrong dims from MPI_Dims_create"
    end if

    ! Create a Cartesian communicator
    call MPI_Cart_create(MPI_COMM_WORLD, 2, dims, periods, reorder, comm_cart, ierr)
    if (ierr /= MPI_SUCCESS) then
        print *, "Error creating Cartesian communicator"
        error stop
    end if

    ! Get new rank in the Cartesian communicator
    call MPI_Comm_rank(comm_cart, rank, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Comm_rank(comm_cart) failed"

    ! Get the Cartesian coordinates of the current rank
    call MPI_Cart_coords(comm_cart, rank, 2, coords, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Cart_coords failed"
    ! Ranks are numbered in row-major order
    if (coords(1) /= rank / dims(2) .or. coords(2) /= mod(rank, dims(2))) then
        print *, "Rank", rank, "has coords", coords, "in a", dims, "grid"
        error stop "wrong coordinates from MPI_Cart_coords"
    end if

    ! Print rank details
    print *, "Global Rank:", rank, "Cartesian Coordinates:", coords

    ! Create a new sub-communicator by removing the second dimension
    call MPI_Cart_sub(comm_cart, remain_dims, comm_new, ierr)
    if (ierr /= MPI_SUCCESS) then
        print *, "Error creating sub-communicator"
        error stop
    end if

    ! Get the size of the new communicator
    call MPI_Comm_size(comm_new, sub_size, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Comm_size(comm_new) failed"
    call MPI_Comm_rank(comm_new, sub_rank, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Comm_rank(comm_new) failed"

    ! Print the new communicator details
    print *, "New communicator rank:", sub_rank, "New communicator size:", sub_size

    ! The sub-communicator is the row of ranks with the same second coordinate
    if (sub_size /= dims(1)) then
        print *, "Rank", rank, ": sub-communicator size", sub_size, "expected", dims(1)
        error stop "wrong size of the MPI_Cart_sub communicator"
    end if
    if (sub_rank /= coords(1)) then
        print *, "Rank", rank, ": sub-communicator rank", sub_rank, "expected", coords(1)
        error stop "wrong rank in the MPI_Cart_sub communicator"
    end if
    call MPI_Cart_coords(comm_new, sub_rank, 1, sub_coords, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Cart_coords(comm_new) failed"
    if (sub_coords(1) /= coords(1)) then
        print *, "Rank", rank, ": sub-communicator coords", sub_coords, "expected", coords(1)
        error stop "wrong coordinates in the MPI_Cart_sub communicator"
    end if

    ! Finalize MPI
    call MPI_Finalize(errs)
    if (errs /= MPI_SUCCESS) then
        print *, "Error finalizing MPI"
        error stop
    end if

end program cart_sub
