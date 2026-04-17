program scatter_1
    use mpi
    implicit none

    integer :: ierr, rank, nprocs, root
    integer, parameter :: blocksize = 3
    real(8), allocatable :: sendbuf(:)
    real(8) :: recvbuf(blocksize)
    integer :: i
    real(8), parameter :: tol = 1.0e-10_8

    root = 0

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)

    allocate(sendbuf(blocksize * nprocs))
    if (rank == root) then
        do i = 1, blocksize * nprocs
            sendbuf(i) = real(i, 8)
        end do
    else
        sendbuf = -1.0_8
    end if

    recvbuf = -999.0_8

    call MPI_Scatter(sendbuf, blocksize, MPI_DOUBLE_PRECISION, &
                     recvbuf, blocksize, MPI_DOUBLE_PRECISION, &
                     root, MPI_COMM_WORLD, ierr)

    if (ierr /= MPI_SUCCESS) then
        print *, "Rank", rank, ": MPI_Scatter failed with error code ", ierr
        error stop 1
    end if

    do i = 1, blocksize
        if (abs(recvbuf(i) - real(rank * blocksize + i, 8)) > tol) then
            print *, "Rank", rank, ": recvbuf(", i, ") = ", recvbuf(i), &
                     " expected ", real(rank * blocksize + i, 8)
            error stop 2
        end if
    end do

    if (rank == root) then
        print *, "MPI_Scatter test passed (nprocs=", nprocs, ")"
    end if

    deallocate(sendbuf)

    call MPI_Finalize(ierr)
end program scatter_1
