program provided_hdf5_1
    use mpi
    use iso_c_binding, only: c_int
    implicit none
    integer :: ierr, duplicate, returned, retired, comparison, size, expected_size, i, input
    interface
        integer(c_int) function hdf5_provided_world(comm) bind(C)
            import c_int
            integer(c_int), value :: comm
        end function
        integer(c_int) function hdf5_provided_failures(comm, null_comm) bind(C)
            import c_int
            integer(c_int), value :: comm, null_comm
        end function
        integer(c_int) function hdf5_provided_roundtrip(comm, returned) bind(C)
            import c_int
            integer(c_int), value :: comm
            integer(c_int), intent(out) :: returned
        end function
        integer(c_int) function hdf5_provided_retired(comm) bind(C)
            import c_int
            integer(c_int), value :: comm
        end function
    end interface
    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) error stop "init"
    call check(hdf5_provided_world(MPI_COMM_WORLD))
    call MPI_Comm_size(MPI_COMM_WORLD, expected_size, ierr)
    if (ierr /= MPI_SUCCESS) error stop "world size"
    call MPI_Comm_dup(MPI_COMM_WORLD, duplicate, ierr)
    if (ierr /= MPI_SUCCESS) error stop "dup"
    call check(hdf5_provided_failures(MPI_COMM_WORLD, MPI_COMM_NULL))
    do i = 1, 2
        input = MPI_COMM_WORLD
        if (i == 2) input = duplicate
        call check(hdf5_provided_roundtrip(input, returned))
        call MPI_Comm_compare(input, returned, comparison, ierr)
        if (ierr /= MPI_SUCCESS .or. comparison /= MPI_CONGRUENT) error stop "HDF5 returned communicator"
        call MPI_Comm_size(returned, size, ierr)
        if (ierr /= MPI_SUCCESS .or. size /= expected_size) error stop "HDF5 returned size"
        call MPI_Barrier(returned, ierr)
        if (ierr /= MPI_SUCCESS) error stop "HDF5 returned barrier"
        retired = returned
        call MPI_Comm_free(returned, ierr)
        if (ierr /= MPI_SUCCESS .or. returned /= MPI_COMM_NULL) error stop "HDF5 returned free"
        ! Check retirement before another allocation can reuse the token.
        call check(hdf5_provided_retired(retired))
    end do
    call MPI_Comm_free(duplicate, ierr)
    if (ierr /= MPI_SUCCESS .or. duplicate /= MPI_COMM_NULL) error stop "free dup"
    call check(hdf5_provided_world(MPI_COMM_WORLD))
    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop "finalize"
    print *, "provided_hdf5_1: OK"
contains
    subroutine check(code)
        integer, intent(in) :: code
        if (code /= 0) then
            print *, "provided HDF5 oracle:", code
            error stop
        end if
    end subroutine
end program
