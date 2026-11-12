program gatherv_character_2
    ! MPI_Gatherv and MPI_Allgatherv of MPI_CHARACTER, as pFUnit gathers
    ! strings (MpiContext.F90): rank r sends r strings of 3 characters,
    ! so rank 0 sends none
    use mpi
    implicit none
    integer, parameter :: nchar = 3
    integer :: ierr, rank, nprocs, root, i, j, p, k, total
    integer, allocatable :: counts(:), displs(:)
    character(len=1), allocatable :: sendbuf(:), recvbuf(:)
    character(len=nchar), allocatable :: words(:), all_words(:)
    character(len=nchar) :: expected

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    root = 0

    allocate(counts(nprocs), displs(nprocs))
    total = 0
    do p = 1, nprocs
        counts(p) = (p-1)*nchar
        displs(p) = total
        total = total + counts(p)
    end do

    ! MPI_Gatherv of character(len=1) arrays
    allocate(sendbuf(max(rank*nchar, 1)))
    do i = 1, rank
        do j = 1, nchar
            sendbuf((i-1)*nchar + j) = word_char(rank, i, j)
        end do
    end do
    allocate(recvbuf(max(total, 1)))
    recvbuf = "?"
    call MPI_Gatherv(sendbuf, rank*nchar, MPI_CHARACTER, recvbuf, counts, displs, &
        MPI_CHARACTER, root, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Gatherv of MPI_CHARACTER failed"
    if (rank == root) then
        k = 0
        do p = 0, nprocs - 1
            do i = 1, p
                do j = 1, nchar
                    k = k + 1
                    if (recvbuf(k) /= word_char(p, i, j)) then
                        print *, "rank", p, "word", i, "char", j, ": got '", recvbuf(k), "'"
                        error stop "MPI_Gatherv of MPI_CHARACTER: wrong result"
                    end if
                end do
            end do
        end do
        if (k /= total) error stop "MPI_Gatherv of MPI_CHARACTER: wrong total"
    end if

    ! MPI_Allgatherv of character(len=3) strings; the counts are in characters
    allocate(words(max(rank, 1)), all_words(max(total/nchar, 1)))
    do i = 1, rank
        do j = 1, nchar
            words(i)(j:j) = word_char(rank, i, j)
        end do
    end do
    all_words = "???"
    call MPI_Allgatherv(words, rank*nchar, MPI_CHARACTER, all_words, counts, displs, &
        MPI_CHARACTER, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Allgatherv of MPI_CHARACTER failed"
    k = 0
    do p = 0, nprocs - 1
        do i = 1, p
            k = k + 1
            do j = 1, nchar
                expected(j:j) = word_char(p, i, j)
            end do
            if (all_words(k) /= expected) then
                print *, "rank", rank, ": word", k, "= '", all_words(k), "', expected '", &
                    expected, "'"
                error stop "MPI_Allgatherv of MPI_CHARACTER: wrong result"
            end if
        end do
    end do

    if (rank == 0) print *, "gatherv_character_2: OK"
    call MPI_Finalize(ierr)

contains

    ! Character j of word i of rank p, e.g. "b2c" for p = 1, i = 2
    character function word_char(p, i, j)
        integer, intent(in) :: p, i, j
        select case (j)
        case (1)
            word_char = achar(iachar("a") + p)
        case (2)
            word_char = achar(iachar("0") + i)
        case default
            word_char = achar(iachar("a") + mod(p + i + j, 26))
        end select
    end function word_char

end program gatherv_character_2
