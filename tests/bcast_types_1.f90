program bcast_types_1
    ! MPI_Bcast of integer, real(4), real(8) and logical, scalars and arrays
    ! of rank 1, 2 and 3.
    use mpi
    implicit none
    integer :: ierr, rank, i
    integer :: i0, i1(4), i2(2, 3), i3(2, 2, 2)
    real(4) :: r0, r1(4), r2(2, 3), r3(2, 2, 2)
    real(8) :: d0, d1(4), d2(2, 3), d3(2, 2, 2)
    logical :: l0, l1(4), l2(2, 3), l3(2, 2, 2)

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)

    i0 = 0; i1 = 0; i2 = 0; i3 = 0
    r0 = 0; r1 = 0; r2 = 0; r3 = 0
    d0 = 0; d1 = 0; d2 = 0; d3 = 0
    l0 = .false.; l1 = .false.; l2 = .false.; l3 = .false.
    if (rank == 0) then
        i0 = 7; i1 = [(i, i = 1, 4)]; i2 = reshape([(i, i = 1, 6)], [2, 3])
        i3 = reshape([(i, i = 1, 8)], [2, 2, 2])
        r0 = 7; r1 = i1; r2 = i2; r3 = i3
        d0 = 7; d1 = i1; d2 = i2; d3 = i3
        l0 = .true.; l1 = .true.; l2 = .true.; l3 = .true.
    end if

    call MPI_Bcast(i0, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(i1, 4, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(i2, 6, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(i3, 8, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(r0, 1, MPI_REAL, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(r1, 4, MPI_REAL, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(r2, 6, MPI_REAL, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(r3, 8, MPI_REAL, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(d0, 1, MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(d1, 4, MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(d2, 6, MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(d3, 8, MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(l0, 1, MPI_LOGICAL, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(l1, 4, MPI_LOGICAL, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(l2, 6, MPI_LOGICAL, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(l3, 8, MPI_LOGICAL, 0, MPI_COMM_WORLD, ierr)

    if (i0 /= 7 .or. any(i1 /= [(i, i = 1, 4)])) error stop "integer"
    if (any(i2 /= reshape([(i, i = 1, 6)], [2, 3]))) error stop "integer 2D"
    if (any(i3 /= reshape([(i, i = 1, 8)], [2, 2, 2]))) error stop "integer 3D"
    if (r0 /= 7 .or. any(r1 /= i1) .or. any(r2 /= i2) .or. any(r3 /= i3)) error stop "real(4)"
    if (d0 /= 7 .or. any(d1 /= i1) .or. any(d2 /= i2) .or. any(d3 /= i3)) error stop "real(8)"
    if (.not. (l0 .and. all(l1) .and. all(l2) .and. all(l3))) error stop "logical"
    if (ierr /= MPI_SUCCESS) error stop "ierr"

    call MPI_Finalize(ierr)
end program bcast_types_1
