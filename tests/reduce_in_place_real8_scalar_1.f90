program reduce_in_place_real8_scalar_1
    use mpi
    use iso_c_binding, only: c_double
    implicit none

    integer :: ierr, rank, nprocs, root
    real(c_double) :: value, total, expected

    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Init failed'
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Comm_rank failed'
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Comm_size failed'

    value = real(rank+1, c_double)
    expected = real(nprocs*(nprocs+1)/2, c_double)
    do root = 0, nprocs-1
        total = value
        if (rank == root) then
            call MPI_Reduce(MPI_IN_PLACE, total, 1, MPI_REAL8, MPI_SUM, root, MPI_COMM_WORLD, ierr)
        else
            call MPI_Reduce(value, total, 1, MPI_REAL8, MPI_SUM, root, MPI_COMM_WORLD, ierr)
        end if
        if (ierr /= MPI_SUCCESS) error stop 'In-place scalar real8 reduce failed'
        if (rank == root) then
            if (total /= expected) error stop 'Incorrect in-place scalar real8 reduction result'
        end if
    end do

    if (rank == 0) print *, 'In-place scalar real8 reductions passed'
    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Finalize failed'
end program reduce_in_place_real8_scalar_1
