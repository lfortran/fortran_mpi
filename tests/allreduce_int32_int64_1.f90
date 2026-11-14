program allreduce_int32_int64_1
    use mpi
    use iso_fortran_env, only: int32, int64
    implicit none

    integer :: ierr, rank, nprocs
    integer(int32) :: s32(2), r32(2), e32
    integer(int64) :: s64(2), r64(2), e64

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)

    s32 = [int(rank + 1, int32), 1_int32]
    e32 = int(nprocs * (nprocs + 1) / 2, int32)
    call MPI_Allreduce(s32, r32, 2, MPI_INT32_T, MPI_SUM, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "int32 allreduce failed"
    if (r32(1) /= e32 .or. r32(2) /= int(nprocs, int32)) error stop "int32 sum wrong"

    ! Values that do not fit in 32 bits
    s64 = [int(rank + 1, int64) * 4000000000_int64, 1_int64]
    e64 = int(nprocs * (nprocs + 1) / 2, int64) * 4000000000_int64
    call MPI_Allreduce(s64, r64, 2, MPI_INT64_T, MPI_SUM, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "int64 allreduce failed"
    if (r64(1) /= e64 .or. r64(2) /= int(nprocs, int64)) error stop "int64 sum wrong"

    call MPI_Allreduce(s64, r64, 2, MPI_INT64_T, MPI_MAX, MPI_COMM_WORLD, ierr)
    if (ierr /= MPI_SUCCESS) error stop "int64 max allreduce failed"
    if (r64(1) /= int(nprocs, int64) * 4000000000_int64) error stop "int64 max wrong"

    if (rank == 0) print *, "MPI_INT32_T / MPI_INT64_T allreduce passed"
    call MPI_Finalize(ierr)
end program allreduce_int32_int64_1
