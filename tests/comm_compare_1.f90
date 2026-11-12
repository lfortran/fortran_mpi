program comm_compare_1
    ! MPI_Comm_compare: identical, congruent, similar and unequal
    use mpi
    implicit none
    integer :: ierr, rank, nprocs, result
    integer :: dup, reversed, halves

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)

    if (MPI_IDENT == MPI_CONGRUENT .or. MPI_IDENT == MPI_SIMILAR .or. &
        MPI_IDENT == MPI_UNEQUAL .or. MPI_CONGRUENT == MPI_SIMILAR .or. &
        MPI_CONGRUENT == MPI_UNEQUAL .or. MPI_SIMILAR == MPI_UNEQUAL) &
        error stop "The results of MPI_Comm_compare are not distinct"

    call MPI_Comm_compare(MPI_COMM_WORLD, MPI_COMM_WORLD, result, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Comm_compare failed"
    if (result /= MPI_IDENT) error stop "MPI_COMM_WORLD is not MPI_IDENT to itself"

    ! Same group, same order, different context
    call MPI_Comm_dup(MPI_COMM_WORLD, dup, ierr)
    call MPI_Comm_compare(MPI_COMM_WORLD, dup, result, ierr)
    if (result /= MPI_CONGRUENT) error stop "A duplicate is not MPI_CONGRUENT"

    ! Same group, reversed order
    call MPI_Comm_split(MPI_COMM_WORLD, 0, nprocs - rank, reversed, ierr)
    call MPI_Comm_compare(MPI_COMM_WORLD, reversed, result, ierr)
    if (nprocs == 1) then
        if (result /= MPI_CONGRUENT) error stop "A 1-rank split is not MPI_CONGRUENT"
    else
        if (result /= MPI_SIMILAR) then
            print *, "rank", rank, ": result =", result
            error stop "A reordered communicator is not MPI_SIMILAR"
        end if
    end if

    ! Different groups
    call MPI_Comm_split(MPI_COMM_WORLD, mod(rank, 2), rank, halves, ierr)
    call MPI_Comm_compare(MPI_COMM_WORLD, halves, result, ierr)
    if (nprocs == 1) then
        if (result /= MPI_CONGRUENT) error stop "A 1-rank split is not MPI_CONGRUENT"
    else
        if (result /= MPI_UNEQUAL) error stop "A smaller communicator is not MPI_UNEQUAL"
    end if

    call MPI_Comm_compare(MPI_COMM_WORLD, MPI_COMM_SELF, result, ierr)
    if (nprocs == 1) then
        if (result /= MPI_CONGRUENT) error stop "MPI_COMM_SELF is not MPI_CONGRUENT with 1 rank"
    else
        if (result /= MPI_UNEQUAL) error stop "MPI_COMM_SELF is not MPI_UNEQUAL"
    end if

    call MPI_Comm_free(dup, ierr)
    call MPI_Comm_free(reversed, ierr)
    call MPI_Comm_free(halves, ierr)
    if (rank == 0) print *, "comm_compare_1: OK"
    call MPI_Finalize(ierr)
end program comm_compare_1
