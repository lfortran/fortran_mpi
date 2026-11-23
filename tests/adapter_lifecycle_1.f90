program adapter_lifecycle_1
    use mpi
    use iso_c_binding, only: c_int
    implicit none
    integer, parameter :: predefined(3) = [MPI_COMM_NULL, MPI_COMM_WORLD, MPI_COMM_SELF]
    integer :: ierr, rank, nprocs, first, second, split, imported, retired, comparison, provided, i
    interface
        integer(c_int) function adapter_predefined(tokens) bind(C)
            import c_int
            integer(c_int), intent(in) :: tokens(*)
        end function
        integer(c_int) function adapter_dynamic(token, parent, size, rank) bind(C)
            import c_int
            integer(c_int), value :: token, parent, size, rank
        end function
        integer(c_int) function adapter_distinct(left, right) bind(C)
            import c_int
            integer(c_int), value :: left, right
        end function
        integer(c_int) function adapter_create(world, token) bind(C)
            import c_int
            integer(c_int), value :: world
            integer(c_int), intent(out) :: token
        end function
        integer(c_int) function adapter_retired(token) bind(C)
            import c_int
            integer(c_int), value :: token
        end function
    end interface
    call MPI_Init_thread(MPI_THREAD_MULTIPLE, provided, ierr)
    call check(ierr)
    call check(adapter_predefined(predefined))
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call check(ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    call check(ierr)
    call MPI_Comm_dup(MPI_COMM_WORLD, first, ierr)
    call check(ierr)
    call MPI_Comm_dup(MPI_COMM_WORLD, second, ierr)
    call check(ierr)
    call check(adapter_dynamic(first, MPI_COMM_WORLD, nprocs, rank))
    call check(adapter_distinct(first, second))
    call MPI_Comm_split(MPI_COMM_WORLD, mod(rank, 2), rank, split, ierr)
    call check(ierr)
    call check(adapter_dynamic(split, MPI_COMM_WORLD, (nprocs + 1 - mod(rank, 2))/2, rank/2))
    call MPI_Barrier(split, ierr)
    call check(ierr)
    call MPI_Comm_free(split, ierr)
    call check(ierr)
    if (split /= MPI_COMM_NULL) error stop "split not null"
    retired = first
    call MPI_Comm_free(first, ierr)
    call check(ierr)
    if (first /= MPI_COMM_NULL) error stop "first not null"
    ! Check retirement before any new allocation. Freed token reuse is legal.
    call check(adapter_retired(retired))
    do i = 1, 64
        call check(adapter_create(MPI_COMM_WORLD, imported))
        call MPI_Comm_compare(imported, MPI_COMM_WORLD, comparison, ierr)
        call check(ierr)
        if (comparison /= MPI_CONGRUENT) error stop "import not congruent"
        call MPI_Barrier(imported, ierr)
        call check(ierr)
        retired = imported
        call MPI_Comm_free(imported, ierr)
        call check(ierr)
        if (imported /= MPI_COMM_NULL) error stop "import not null"
        call check(adapter_retired(retired))
    end do
    call MPI_Comm_free(second, ierr)
    call check(ierr)
    call check(adapter_predefined(predefined))
    call MPI_Finalize(ierr)
    call check(ierr)
    if (rank == 0) print *, "adapter_lifecycle_1: OK"
contains
    subroutine check(code)
        integer, intent(in) :: code
        if (code /= MPI_SUCCESS) then
            print *, "adapter error:", code
            error stop
        end if
    end subroutine
end program
