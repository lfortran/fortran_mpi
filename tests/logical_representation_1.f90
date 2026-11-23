program logical_representation_1
    use mpi
    use iso_c_binding, only: c_int8_t
    implicit none
    integer, parameter :: bytes = storage_size(.true.)/8
    integer :: ierr, rank, nprocs, i
    integer(c_int8_t) :: actual(2*bytes), expected(2*bytes)
    integer, parameter :: operations(3) = [MPI_LAND, MPI_LOR, MPI_LXOR]
    logical :: input(2), output(2), answer(2)
    complex(8) :: z, total
    integer(8) :: wide, wide_sum
    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) error stop "init"
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    do i = 1, 3
        if (i == 1) then
            input = [.true., rank /= 0]
        else
            input = [rank == 0, .false.]
        end if
        answer = [.true., .false.]
        call MPI_Allreduce(input, output, 2, MPI_LOGICAL, operations(i), MPI_COMM_WORLD, ierr)
        if (ierr /= MPI_SUCCESS) error stop "logical reduction"
        actual = transfer(output, actual)
        expected = transfer(answer, expected)
        if (any(actual /= expected)) error stop "logical literal representation"
        call MPI_Allreduce(MPI_IN_PLACE, input, 2, MPI_LOGICAL, operations(i), MPI_COMM_WORLD, ierr)
        if (ierr /= MPI_SUCCESS) error stop "in-place logical reduction"
        actual = transfer(input, actual)
        if (any(actual /= expected)) error stop "in-place logical literal representation"
    end do
    z = cmplx(real(rank+1, 8), -real(rank+1, 8), 8)
    call MPI_Allreduce(z, total, 1, MPI_DOUBLE_COMPLEX, MPI_SUM, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "double complex reduction"
    if (total /= cmplx(real(nprocs*(nprocs+1)/2, 8), -real(nprocs*(nprocs+1)/2, 8), 8)) error stop "complex payload"
    wide = 1099511627776_8 + int(rank, 8)
    call MPI_Allreduce(wide, wide_sum, 1, MPI_INTEGER8, MPI_SUM, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "integer8 reduction"
    if (wide_sum /= 1099511627776_8*nprocs + nprocs*(nprocs-1)/2) error stop "integer8 payload"
    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop "finalize"
end program
