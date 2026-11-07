program allreduce_in_place_1
    ! MPI_IN_PLACE with scalar and array receive buffers. Ordinary data must
    ! never be taken for MPI_IN_PLACE, whatever its value.
    use mpi
    implicit none
    integer :: ierr, nprocs, i
    real(8) :: x, y, v(3)

    call MPI_Init(ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)

    x = 2
    call MPI_Allreduce(MPI_IN_PLACE, x, 1, MPI_REAL8, MPI_SUM, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS .or. x /= 2*nprocs) error stop "in-place scalar allreduce"

    v = [(real(i, 8), i = 1, 3)]
    call MPI_Allreduce(MPI_IN_PLACE, v, 3, MPI_REAL8, MPI_SUM, MPI_COMM_WORLD, ierr)
    do i = 1, 3
        if (v(i) /= i*nprocs) error stop "in-place array allreduce"
    end do

    ! -1002 used to be the value of MPI_IN_PLACE
    x = -1002
    y = 0
    call MPI_Allreduce(x, y, 1, MPI_REAL8, MPI_SUM, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS .or. y /= -1002*nprocs) then
        print *, "allreduce of -1002 gave", y
        error stop
    end if

    call MPI_Finalize(ierr)
end program allreduce_in_place_1
