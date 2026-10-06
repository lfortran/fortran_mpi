program bcast_real_3d_1
    use mpi
    use iso_c_binding, only: c_float
    implicit none

    integer :: ierr, rank
    real(c_float) :: field(2,2,2)

    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Init failed'
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Comm_rank failed'

    field = -1.0_c_float
    if (rank == 0) then
        field = reshape([1.25_c_float, 2.25_c_float, 3.25_c_float, 4.25_c_float, &
                         5.25_c_float, 6.25_c_float, 7.25_c_float, 8.25_c_float], shape(field))
    end if
    call MPI_Bcast(field, size(field), MPI_REAL4, 0, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Bcast failed'
    if (any(field /= reshape([1.25_c_float, 2.25_c_float, 3.25_c_float, 4.25_c_float, &
                              5.25_c_float, 6.25_c_float, 7.25_c_float, 8.25_c_float], shape(field)))) &
        error stop 'Rank-three real4 broadcast failed'

    if (rank == 0) print *, 'Rank-three real4 broadcast passed'
    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop 'MPI_Finalize failed'
end program bcast_real_3d_1
