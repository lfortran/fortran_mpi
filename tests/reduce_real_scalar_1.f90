program reduce_real_scalar_1
    use mpi
    use iso_c_binding, only: c_float, c_double
    implicit none

    integer :: ierr, rank, nprocs
    real(c_float) :: single_value, single_sum
    real(c_double) :: double_value, double_sum

    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Init failed'
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Comm_rank failed'
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Comm_size failed'

    single_value = real(rank+1, c_float)
    double_value = real(rank+1, c_double)
    call MPI_Reduce(single_value, single_sum, 1, MPI_REAL4, MPI_SUM, 0, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop 'Scalar real4 reduce failed'
    if (rank == 0) then
        if (single_sum /= real(nprocs*(nprocs+1)/2, c_float)) &
            error stop 'Incorrect scalar real4 reduction result'
    end if
    call MPI_Reduce(double_value, double_sum, 1, MPI_REAL8, MPI_SUM, 0, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop 'Scalar real8 reduce failed'
    if (rank == 0) then
        if (double_sum /= real(nprocs*(nprocs+1)/2, c_double)) &
            error stop 'Incorrect scalar real8 reduction result'
        print *, 'Scalar real4 and real8 reductions passed'
    end if

    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Finalize failed'
end program reduce_real_scalar_1
