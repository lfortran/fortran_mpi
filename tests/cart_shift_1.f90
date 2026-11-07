program cart_shift_1
    use mpi
    implicit none

    integer :: ierr, rank, size
    integer :: comm_cart
    integer :: dims(2)
    logical :: periods(2)
    integer :: coords(2)
    integer :: left, right, up, down

    call MPI_INIT(ierr)
    call MPI_COMM_RANK(MPI_COMM_WORLD, rank, ierr)
    call MPI_COMM_SIZE(MPI_COMM_WORLD, size, ierr)

    dims(1) = 0
    dims(2) = 0
    periods(1) = .true.
    periods(2) = .false.

    call MPI_DIMS_CREATE(size, 2, dims, ierr)
    call MPI_CART_CREATE(MPI_COMM_WORLD, 2, dims, periods, &
                        .true., comm_cart, ierr)

    call MPI_CART_COORDS(comm_cart, rank, 2, coords, ierr)

    call MPI_CART_SHIFT(comm_cart, 0, 1, left, right, ierr)

    call MPI_CART_SHIFT(comm_cart, 1, 1, up, down, ierr)

    if (coords(2) == 0 .and. up /= MPI_PROC_NULL) then
        print *, 'Error: Rank ', rank, ' at (', coords(1), ',', coords(2), &
                ') should have up = MPI_PROC_NULL but got ', up
        error stop
    end if

    if (coords(2) == dims(2)-1 .and. down /= MPI_PROC_NULL) then
        print *, 'Error: Rank ', rank, ' at (', coords(1), ',', coords(2), &
                ') should have down = MPI_PROC_NULL but got ', down
        error stop
    end if

    ! Dimension 1 is periodic, so there is always a neighbor
    if (left == MPI_PROC_NULL .or. right == MPI_PROC_NULL) then
        print *, 'Error: Rank ', rank, ' has no left or right neighbor'
        error stop
    end if

    print *, &
          'Rank ', rank, ' at coords (', coords(1), ',', coords(2), &
          ') neighbors: left=', left, ' right=', right, &
          ' up=', up, ' down=', down

    call MPI_FINALIZE(ierr)
end program cart_shift_1
