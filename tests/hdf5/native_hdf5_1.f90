program native_hdf5_1
    use mpi
    use iso_c_binding, only: c_int
    implicit none
    integer :: world = MPI_COMM_WORLD
    integer :: ierr, duplicate, returned, comparison, size, expected_size, i, input
    interface
        integer(c_int) function hdf5_native_world(comm) bind(C)
            import c_int
            integer(c_int), value :: comm
        end function
        integer(c_int) function hdf5_native_roundtrip(comm, returned) bind(C)
            import c_int
            integer(c_int), value :: comm
            integer(c_int), intent(out) :: returned
        end function
    end interface
    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) error stop "init"
    ! Fail safely on a private token before entering the unmodified C shim.
    if (hdf5_native_world(world) /= 0) error stop "not a native MPI_Fint communicator"
    call MPI_Comm_size(world, expected_size, ierr)
    if (ierr /= MPI_SUCCESS) error stop "world size"
    call MPI_Comm_dup(world, duplicate, ierr)
    if (ierr /= MPI_SUCCESS) error stop "dup"
    do i = 1, 2
        input = world
        if (i == 2) input = duplicate
        if (hdf5_native_roundtrip(input, returned) /= 0) error stop "unchanged HDF5 shim"
        call MPI_Comm_compare(input, returned, comparison, ierr)
        if (ierr /= MPI_SUCCESS .or. comparison /= MPI_CONGRUENT) error stop "HDF5 returned communicator"
        call MPI_Comm_size(returned, size, ierr)
        if (ierr /= MPI_SUCCESS .or. size /= expected_size) error stop "HDF5 returned size"
        call MPI_Barrier(returned, ierr)
        if (ierr /= MPI_SUCCESS) error stop "HDF5 returned barrier"
        call MPI_Comm_free(returned, ierr)
        if (ierr /= MPI_SUCCESS .or. returned /= MPI_COMM_NULL) error stop "HDF5 returned free"
    end do
    call MPI_Comm_free(duplicate, ierr)
    if (ierr /= MPI_SUCCESS .or. duplicate /= MPI_COMM_NULL) error stop "free dup"
    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop "finalize"
    print *, "native_hdf5_1: OK"
end program
