module mod_uop
    contains
    subroutine uop( cin, cout, count)
        use mpi
        integer cin(*), cout(*)
        integer count
        integer i

        do i=1, count
            cout(i) = cin(i) + cout(i)
        end do
    end subroutine
end module mod_uop
  
program allreduce_1
    use mpi
    use mod_uop
    integer ierr, errs
    real(8)  :: vin(65000),vout(65000)
    integer :: i, count, size
    integer :: comm

    errs = 0

    call mpi_init(ierr)

    comm = MPI_COMM_WORLD
    call mpi_comm_size( comm, size, ierr )
    count = 1
    do while (count < 65000)
        do i=1, count
            vin(i) = i
            vout(i) = -1
        end do
        call mpi_allreduce( vin, vout, count, MPI_REAL8, MPI_SUM, comm, ierr )
        if (ierr /= MPI_SUCCESS) error stop "mpi_allreduce failed"
    !         Check that all results are correct
        do i=1, count
            if (vout(i) /= i * size) then
                errs = errs + 1
                if (errs < 10) print *, "vout(",i,") = ", vout(i)
            end if
        end do
        count = count + count
    end do

    print *, "Allreduce test completed with ", errs, " errors."
    if (errs /= 0) error stop "mpi_allreduce gave wrong sums"
    call mpi_finalize(ierr)
    if (ierr /= MPI_SUCCESS) error stop "mpi_finalize failed"
end program allreduce_1
