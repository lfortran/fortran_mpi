module split_type_1_mod
    use mpi
    implicit none
    integer :: nproc
    integer :: nprocsh
    integer :: iprocw
    integer :: iprocsh
    integer :: comm_shared

    contains

    subroutine init_mpi
        implicit none
        integer :: ierr,tcheck
        call MPI_Init_thread (MPI_THREAD_FUNNELED,tcheck,ierr)
        call MPI_Comm_size (MPI_COMM_WORLD,nproc,ierr)
        call MPI_Comm_rank (MPI_COMM_WORLD,iprocw,ierr)
        call MPI_Comm_split_type (MPI_COMM_WORLD,MPI_COMM_TYPE_SHARED,0, &
                                  MPI_INFO_NULL,comm_shared,ierr)
        call MPI_Comm_size (comm_shared,nprocsh,ierr)
        call MPI_Comm_rank (comm_shared,iprocsh,ierr)
    end subroutine
end module

program split_type_1
    use mpi
    use split_type_1_mod
    implicit none
    integer :: ierr
    call init_mpi
    ! All ranks of the tests run on one node
    if (nprocsh /= nproc) then
        print *, "MPI_COMM_TYPE_SHARED communicator has", nprocsh, "ranks, expected", nproc
        error stop
    end if
    call MPI_Finalize (ierr)
    if (ierr /= 0) error stop
end program split_type_1
