program mre_comm_free
  use mpi
  implicit none

  integer :: ierr, rank, size
  integer :: dup_comm, dup_rank, dup_size

  call MPI_INIT(ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_INIT failed"

  call MPI_COMM_RANK(MPI_COMM_WORLD, rank, ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_COMM_RANK failed"
  call MPI_COMM_SIZE(MPI_COMM_WORLD, size, ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_COMM_SIZE failed"

  ! Create a duplicate communicator (all processes participate)
  call MPI_COMM_DUP(MPI_COMM_WORLD, dup_comm, ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_COMM_DUP failed"

  ! Use the new communicator
  call MPI_COMM_RANK(dup_comm, dup_rank, ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_COMM_RANK(dup_comm) failed"
  call MPI_COMM_SIZE(dup_comm, dup_size, ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_COMM_SIZE(dup_comm) failed"
  if (dup_rank /= rank .or. dup_size /= size) error stop "wrong rank or size in dup_comm"

  print *, 'Original Rank:', rank, ' -> Duplicate Rank:', dup_rank, &
           ' / Size:', dup_size

  ! Free the duplicated communicator
  call MPI_COMM_FREE(dup_comm, ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_COMM_FREE failed"
  if (dup_comm /= MPI_COMM_NULL) error stop "MPI_COMM_FREE did not set dup_comm to MPI_COMM_NULL"

  print *, 'Rank', rank, 'successfully freed dup_comm.'

  call MPI_FINALIZE(ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_FINALIZE failed"
end program mre_comm_free