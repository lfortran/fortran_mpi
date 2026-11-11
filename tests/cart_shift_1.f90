program cart_shift_1
    use mpi
    implicit none

    integer :: ierr, rank, size
    integer :: comm_cart
    integer :: dims(2)
    logical :: periods(2)
    integer :: coords(2)
    integer :: left, right, up, down
    integer :: expected_left, expected_right, expected_up, expected_down

    call MPI_INIT(ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_INIT failed"
    call MPI_COMM_SIZE(MPI_COMM_WORLD, size, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_COMM_SIZE failed"

    dims(1) = 0
    dims(2) = 0
    periods(1) = .true.
    periods(2) = .false.

    call MPI_DIMS_CREATE(size, 2, dims, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_DIMS_CREATE failed"
    ! A balanced grid, in non-increasing order: 1x1, 2x1, 2x2
    if (dims(1) * dims(2) /= size .or. dims(1) < dims(2)) then
        print *, 'Error: MPI_DIMS_CREATE(', size, ') gave dims =', dims
        error stop "wrong dims from MPI_DIMS_CREATE"
    end if
    call MPI_CART_CREATE(MPI_COMM_WORLD, 2, dims, periods, &
                        .true., comm_cart, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_CART_CREATE failed"
    if (comm_cart == MPI_COMM_NULL) error stop "MPI_CART_CREATE returned MPI_COMM_NULL"

    ! The rank may be reordered, so use the rank in comm_cart
    call MPI_COMM_RANK(comm_cart, rank, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_COMM_RANK failed"

    call MPI_CART_COORDS(comm_cart, rank, 2, coords, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_CART_COORDS failed"
    ! Ranks are numbered in row-major order
    if (coords(1) /= rank / dims(2) .or. coords(2) /= mod(rank, dims(2))) then
        print *, 'Error: Rank ', rank, ' has coords ', coords, ' in a ', dims, ' grid'
        error stop "wrong coordinates from MPI_CART_COORDS"
    end if

    call MPI_CART_SHIFT(comm_cart, 0, 1, left, right, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_CART_SHIFT(0) failed"

    call MPI_CART_SHIFT(comm_cart, 1, 1, up, down, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_CART_SHIFT(1) failed"

    ! Dimension 1 is periodic, so there is always a neighbor
    expected_left = mod(coords(1) - 1 + dims(1), dims(1)) * dims(2) + coords(2)
    expected_right = mod(coords(1) + 1, dims(1)) * dims(2) + coords(2)
    ! Dimension 2 is not periodic
    if (coords(2) == 0) then
        expected_up = MPI_PROC_NULL
    else
        expected_up = rank - 1
    end if
    if (coords(2) == dims(2) - 1) then
        expected_down = MPI_PROC_NULL
    else
        expected_down = rank + 1
    end if

    if (left /= expected_left .or. right /= expected_right) then
        print *, 'Error: Rank ', rank, ' at (', coords(1), ',', coords(2), &
                ') has left, right = ', left, right, ' expected ', &
                expected_left, expected_right
        error stop "wrong neighbors in the periodic dimension"
    end if

    if (up /= expected_up .or. down /= expected_down) then
        print *, 'Error: Rank ', rank, ' at (', coords(1), ',', coords(2), &
                ') has up, down = ', up, down, ' expected ', &
                expected_up, expected_down, ' (MPI_PROC_NULL = ', MPI_PROC_NULL, ')'
        error stop "wrong neighbors in the non-periodic dimension"
    end if

    print *, &
          'Rank ', rank, ' at coords (', coords(1), ',', coords(2), &
          ') neighbors: left=', left, ' right=', right, &
          ' up=', up, ' down=', down

    call MPI_FINALIZE(ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_FINALIZE failed"
end program cart_shift_1
