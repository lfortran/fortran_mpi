program bcast_real_scalar_1
    use mpi
    use iso_c_binding, only: c_float, c_double
    implicit none

    integer :: ierr, rank
    real(c_float) :: single_value
    real(c_double) :: double_value

    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Init failed'
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Comm_rank failed'

    single_value = -1.0_c_float
    double_value = -1.0_c_double
    if (rank == 0) then
        single_value = 8.25_c_float
        double_value = 9.125_c_double
    end if

    call MPI_Bcast(single_value, 1, MPI_REAL4, 0, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS .or. single_value /= 8.25_c_float) &
        error stop 'Scalar real4 broadcast failed'
    call MPI_Bcast(double_value, 1, MPI_REAL8, 0, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS .or. double_value /= 9.125_c_double) &
        error stop 'Scalar real8 broadcast failed'

    if (rank == 0) print *, 'Scalar real4 and real8 broadcasts passed'
    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Finalize failed'
end program bcast_real_scalar_1
