program scatter_exscan_types_1
    ! MPI_Scatter from arrays of rank 1, 2 and 3 into scalars and arrays,
    ! and MPI_Exscan of integer, real(4) and real(8) arrays.
    use mpi
    implicit none
    integer, parameter :: maxp = 4
    integer :: ierr, rank, nprocs, i, k
    integer :: isend(maxp), irecv
    real(4) :: rsend(2, maxp), rrecv(2)
    real(8) :: dsend(2, 2, maxp), drecv(2, 2)
    integer :: ie(2), je(2)
    real(4) :: re(2, 2), se(2, 2)
    real(8) :: de(2, 2, 2), ee(2, 2, 2)

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    if (nprocs > maxp) error stop "at most 4 ranks"

    ! Scatter: each rank gets the slice with its rank number
    do i = 1, maxp
        isend(i) = 10*i
        rsend(:, i) = [10*i, 10*i + 1]
        dsend(:, :, i) = reshape([(10*i + k, k = 0, 3)], [2, 2])
    end do
    irecv = 0; rrecv = 0; drecv = 0
    call MPI_Scatter(isend, 1, MPI_INTEGER, irecv, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
    call MPI_Scatter(rsend, 2, MPI_REAL, rrecv, 2, MPI_REAL, 0, MPI_COMM_WORLD, ierr)
    call MPI_Scatter(dsend, 4, MPI_DOUBLE_PRECISION, drecv, 4, MPI_DOUBLE_PRECISION, 0, &
        MPI_COMM_WORLD, ierr)
    i = rank + 1
    if (irecv /= 10*i) error stop "scatter integer"
    if (any(rrecv /= [10*i, 10*i + 1])) error stop "scatter real(4)"
    if (any(drecv /= reshape([(10*i + k, k = 0, 3)], [2, 2]))) error stop "scatter real(8)"

    ! Exscan: the sum over the lower ranks; undefined on rank 0
    ie = rank + 1; re = rank + 1; de = rank + 1
    call MPI_Exscan(ie, je, 2, MPI_INTEGER, MPI_SUM, MPI_COMM_WORLD, ierr)
    call MPI_Exscan(re, se, 4, MPI_REAL, MPI_SUM, MPI_COMM_WORLD, ierr)
    call MPI_Exscan(de, ee, 8, MPI_DOUBLE_PRECISION, MPI_SUM, MPI_COMM_WORLD, ierr)
    if (rank > 0) then
        k = rank*(rank + 1)/2
        if (any(je /= k) .or. any(se /= k) .or. any(ee /= k)) error stop "exscan"
    end if
    if (ierr /= MPI_SUCCESS) error stop "ierr"

    call MPI_Finalize(ierr)
end program scatter_exscan_types_1
