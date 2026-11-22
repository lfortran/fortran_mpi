program dims_create_1
    use mpi
    implicit none
    integer :: ierr, dims(3), storage(6)

    call MPI_Init(ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Init failed"
    call MPI_Comm_set_errhandler(MPI_COMM_WORLD, MPI_ERRORS_RETURN, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Comm_set_errhandler failed"
    call MPI_Comm_set_errhandler(MPI_COMM_SELF, MPI_ERRORS_RETURN, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Comm_set_errhandler failed"

    ! This local grid calculation does not require six MPI ranks.
    dims = [0, 3, 0]
    print *, "Constrained dimensions before:", dims
    call MPI_Dims_create(6, 3, dims, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Dims_create with a fixed dimension failed"
    if (any(dims /= [2, 3, 1])) error stop "MPI_Dims_create changed a fixed dimension"

    storage = [0, -71, 3, -72, 0, -73]
    print *, "Strided dimensions before:", storage(1:6:2)
    call MPI_Dims_create(6, 3, storage(1:6:2), ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Dims_create with strided dimensions failed"
    if (any(storage(1:6:2) /= [2, 3, 1])) error stop "MPI_Dims_create lost strided input dimensions"
    if (any(storage(2:6:2) /= [-71, -72, -73])) error stop "MPI_Dims_create overwrote unselected elements"

    dims = [1, 3, 2]
    print *, "Fully fixed dimensions before:", dims
    call MPI_Dims_create(6, 3, dims, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Dims_create with all dimensions fixed failed"
    if (any(dims /= [1, 3, 2])) error stop "MPI_Dims_create reordered fixed dimensions"

    storage = [1, -71, 3, -72, 2, -73]
    print *, "Fully fixed strided dimensions before:", storage(1:6:2)
    call MPI_Dims_create(6, 3, storage(1:6:2), ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Dims_create with fixed strided dimensions failed"
    if (any(storage(1:6:2) /= [1, 3, 2])) error stop "MPI_Dims_create reordered fixed strided dimensions"
    if (any(storage(2:6:2) /= [-71, -72, -73])) error stop "MPI_Dims_create overwrote unselected elements"

    call MPI_Finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Finalize failed"
    print *, "dims_create_1: OK"
end program dims_create_1
