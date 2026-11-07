program any_type_1
    ! MPI_Bcast and MPI_Allreduce with types, kinds and ranks that used to
    ! have no specific procedure, including a non-contiguous section.
    use mpi
    implicit none
    integer :: ierr, rank, nprocs, i, j
    integer :: m(2, 3)
    integer(8) :: big
    logical :: flag
    real(8) :: d(6), s(3)
    complex(8) :: z
    character(len=5) :: word

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)

    ! Bcast: integer 2D, integer(8) scalar, logical, complex, character
    m = 0; big = 0; flag = .false.; z = 0; word = ""
    if (rank == 0) then
        m = reshape([(i, i = 1, 6)], [2, 3])
        big = 2_8**40
        flag = .true.
        z = (1.5_8, -2.5_8)
        word = "hello"
    end if
    call MPI_Bcast(m, 6, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(big, 1, MPI_INTEGER8, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(flag, 1, MPI_LOGICAL, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(z, 1, MPI_DOUBLE_COMPLEX, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(word, 5, MPI_CHARACTER, 0, MPI_COMM_WORLD, ierr)
    do j = 1, 3
        do i = 1, 2
            if (m(i, j) /= i + 2*(j - 1)) error stop "bcast integer 2D"
        end do
    end do
    if (big /= 2_8**40) error stop "bcast integer(8)"
    if (.not. flag) error stop "bcast logical"
    if (z /= (1.5_8, -2.5_8)) error stop "bcast complex(8)"
    if (word /= "hello") error stop "bcast character"

    ! Bcast into a non-contiguous section: only every other element changes
    d = -1
    if (rank == 0) d(1::2) = [10, 20, 30]
    call MPI_Bcast(d(1::2), 3, MPI_DOUBLE_PRECISION, 0, MPI_COMM_WORLD, ierr)
    if (any(d(1::2) /= [10, 20, 30])) error stop "bcast section"
    if (any(d(2::2) /= -1)) error stop "bcast section touched the gaps"

    ! Allreduce: integer 2D, from a non-contiguous section, in place integer
    m = 1
    call MPI_Allreduce(MPI_IN_PLACE, m, 6, MPI_INTEGER, MPI_SUM, MPI_COMM_WORLD, ierr)
    if (any(m /= nprocs)) error stop "allreduce in place integer 2D"

    d = [(real(i, 8), i = 1, 6)]
    call MPI_Allreduce(d(2::2), s, 3, MPI_DOUBLE_PRECISION, MPI_SUM, MPI_COMM_WORLD, ierr)
    if (any(s /= [2, 4, 6]*nprocs)) error stop "allreduce from section"

    big = rank
    call MPI_Allreduce(MPI_IN_PLACE, big, 1, MPI_INTEGER8, MPI_MAX, MPI_COMM_WORLD, ierr)
    if (big /= nprocs - 1) error stop "allreduce in place integer(8)"

    call MPI_Finalize(ierr)
end program any_type_1
