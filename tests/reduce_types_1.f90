program reduce_types_1
    ! MPI_Reduce and MPI_Allreduce of integer, real(4), real(8) and logical,
    ! scalars and arrays of rank 1, 2 and 3, with and without MPI_IN_PLACE.
    use mpi
    implicit none
    integer :: ierr, rank, nprocs, n
    integer :: i0, i1(3), i2(2, 2), i3(2, 2, 2), j0, j1(3), j2(2, 2), j3(2, 2, 2)
    real(4) :: r0, r1(3), r2(2, 2), r3(2, 2, 2), s0, s1(3), s2(2, 2), s3(2, 2, 2)
    real(8) :: d0, d1(3), d2(2, 2), d3(2, 2, 2), e0, e1(3), e2(2, 2), e3(2, 2, 2)
    logical :: l0, l1(3), l2(2, 2), l3(2, 2, 2), m0, m1(3), m2(2, 2), m3(2, 2, 2)

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    n = nprocs*(nprocs + 1)/2   ! sum of rank + 1

    ! Allreduce
    i0 = rank + 1; i1 = rank + 1; i2 = rank + 1; i3 = rank + 1
    call MPI_Allreduce(i0, j0, 1, MPI_INTEGER, MPI_SUM, MPI_COMM_WORLD, ierr)
    call MPI_Allreduce(i1, j1, 3, MPI_INTEGER, MPI_SUM, MPI_COMM_WORLD, ierr)
    call MPI_Allreduce(i2, j2, 4, MPI_INTEGER, MPI_SUM, MPI_COMM_WORLD, ierr)
    call MPI_Allreduce(i3, j3, 8, MPI_INTEGER, MPI_SUM, MPI_COMM_WORLD, ierr)
    if (j0 /= n .or. any(j1 /= n) .or. any(j2 /= n) .or. any(j3 /= n)) error stop "allreduce integer"

    r0 = rank + 1; r1 = rank + 1; r2 = rank + 1; r3 = rank + 1
    call MPI_Allreduce(r0, s0, 1, MPI_REAL, MPI_SUM, MPI_COMM_WORLD, ierr)
    call MPI_Allreduce(r1, s1, 3, MPI_REAL, MPI_SUM, MPI_COMM_WORLD, ierr)
    call MPI_Allreduce(r2, s2, 4, MPI_REAL, MPI_SUM, MPI_COMM_WORLD, ierr)
    call MPI_Allreduce(r3, s3, 8, MPI_REAL, MPI_SUM, MPI_COMM_WORLD, ierr)
    if (s0 /= n .or. any(s1 /= n) .or. any(s2 /= n) .or. any(s3 /= n)) error stop "allreduce real(4)"

    d0 = rank + 1; d1 = rank + 1; d2 = rank + 1; d3 = rank + 1
    call MPI_Allreduce(d0, e0, 1, MPI_DOUBLE_PRECISION, MPI_SUM, MPI_COMM_WORLD, ierr)
    call MPI_Allreduce(d1, e1, 3, MPI_DOUBLE_PRECISION, MPI_SUM, MPI_COMM_WORLD, ierr)
    call MPI_Allreduce(d2, e2, 4, MPI_DOUBLE_PRECISION, MPI_SUM, MPI_COMM_WORLD, ierr)
    call MPI_Allreduce(d3, e3, 8, MPI_DOUBLE_PRECISION, MPI_SUM, MPI_COMM_WORLD, ierr)
    if (e0 /= n .or. any(e1 /= n) .or. any(e2 /= n) .or. any(e3 /= n)) error stop "allreduce real(8)"

    l0 = rank == 0; l1 = rank == 0; l2 = rank == 0; l3 = rank == 0
    call MPI_Allreduce(l0, m0, 1, MPI_LOGICAL, MPI_LOR, MPI_COMM_WORLD, ierr)
    call MPI_Allreduce(l1, m1, 3, MPI_LOGICAL, MPI_LOR, MPI_COMM_WORLD, ierr)
    call MPI_Allreduce(l2, m2, 4, MPI_LOGICAL, MPI_LOR, MPI_COMM_WORLD, ierr)
    call MPI_Allreduce(l3, m3, 8, MPI_LOGICAL, MPI_LOR, MPI_COMM_WORLD, ierr)
    if (.not. (m0 .and. all(m1) .and. all(m2) .and. all(m3))) error stop "allreduce logical"

    ! Allreduce in place
    i2 = rank + 1; r3 = rank + 1; d1 = rank + 1; l0 = rank == 0
    call MPI_Allreduce(MPI_IN_PLACE, i2, 4, MPI_INTEGER, MPI_SUM, MPI_COMM_WORLD, ierr)
    call MPI_Allreduce(MPI_IN_PLACE, r3, 8, MPI_REAL, MPI_SUM, MPI_COMM_WORLD, ierr)
    call MPI_Allreduce(MPI_IN_PLACE, d1, 3, MPI_DOUBLE_PRECISION, MPI_SUM, MPI_COMM_WORLD, ierr)
    call MPI_Allreduce(MPI_IN_PLACE, l0, 1, MPI_LOGICAL, MPI_LAND, MPI_COMM_WORLD, ierr)
    if (any(i2 /= n) .or. any(r3 /= n) .or. any(d1 /= n)) error stop "allreduce in place"
    if (l0 .neqv. (nprocs == 1)) error stop "allreduce in place logical"

    ! Reduce to the last rank; MPI_IN_PLACE is only valid at the root
    i1 = rank + 1; r2 = rank + 1; d3 = rank + 1; l1 = rank == 0
    j1 = 0; s2 = 0; e3 = 0; m1 = .false.
    call MPI_Reduce(i1, j1, 3, MPI_INTEGER, MPI_SUM, nprocs - 1, MPI_COMM_WORLD, ierr)
    call MPI_Reduce(r2, s2, 4, MPI_REAL, MPI_SUM, nprocs - 1, MPI_COMM_WORLD, ierr)
    call MPI_Reduce(d3, e3, 8, MPI_DOUBLE_PRECISION, MPI_SUM, nprocs - 1, MPI_COMM_WORLD, ierr)
    call MPI_Reduce(l1, m1, 3, MPI_LOGICAL, MPI_LOR, nprocs - 1, MPI_COMM_WORLD, ierr)
    if (rank == nprocs - 1) then
        if (any(j1 /= n) .or. any(s2 /= n) .or. any(e3 /= n)) error stop "reduce"
        if (.not. all(m1)) error stop "reduce logical"
    end if

    i3 = rank + 1; d0 = rank + 1
    if (rank == 0) then
        call MPI_Reduce(MPI_IN_PLACE, i3, 8, MPI_INTEGER, MPI_SUM, 0, MPI_COMM_WORLD, ierr)
        call MPI_Reduce(MPI_IN_PLACE, d0, 1, MPI_DOUBLE_PRECISION, MPI_SUM, 0, MPI_COMM_WORLD, ierr)
        if (any(i3 /= n) .or. d0 /= n) error stop "reduce in place"
    else
        call MPI_Reduce(i3, j3, 8, MPI_INTEGER, MPI_SUM, 0, MPI_COMM_WORLD, ierr)
        call MPI_Reduce(d0, e0, 1, MPI_DOUBLE_PRECISION, MPI_SUM, 0, MPI_COMM_WORLD, ierr)
    end if
    if (ierr /= MPI_SUCCESS) error stop "ierr"

    call MPI_Finalize(ierr)
end program reduce_types_1
