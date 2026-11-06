program bcast_character_1
    ! MPI_CHARACTER must be distinct from the other datatype handles, and a
    ! character buffer broadcast with it must arrive unchanged on all ranks.
    use mpi
    implicit none

    integer :: ierr, rank
    character(len=32) :: msg

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)

    if (MPI_CHARACTER == MPI_REAL .or. MPI_CHARACTER == MPI_INTEGER .or. &
        MPI_CHARACTER == MPI_DOUBLE_PRECISION .or. &
        MPI_CHARACTER == MPI_LOGICAL) error stop "MPI_CHARACTER not distinct"

    if (rank == 0) then
        msg = "compiled with fortran_mpi"
    else
        msg = repeat("x", len(msg))
    end if

    call MPI_Bcast(msg, len(msg), MPI_CHARACTER, 0, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Bcast failed"
    if (msg /= "compiled with fortran_mpi") then
        print *, "rank", rank, "got '", msg, "'"
        error stop "wrong character broadcast"
    end if

    if (rank == 0) print *, "bcast_character_1: OK"
    call MPI_Finalize(ierr)
end program bcast_character_1
