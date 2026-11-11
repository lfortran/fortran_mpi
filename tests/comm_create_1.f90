program minimal_mre_range
  use mpi
  implicit none

  integer :: ierr, rank, new_rank, size, new_size, group_size
  integer :: group_world, group_range, new_comm
  integer, dimension(1,3) :: range   ! 1D array to define a single range

  call MPI_INIT(ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_INIT failed"
  call MPI_COMM_RANK(MPI_COMM_WORLD, rank, ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_COMM_RANK failed"
  call MPI_COMM_SIZE(MPI_COMM_WORLD, size, ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_COMM_SIZE failed"

  ! Get the group of MPI_COMM_WORLD
  call MPI_COMM_GROUP(MPI_COMM_WORLD, group_world, ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_COMM_GROUP failed"

  ! Define 1D range: start, end, stride
  range(1,1) = 0         ! start
  range(1,2) = size - 1  ! end
  range(1,3) = 1         ! stride


  ! Create a new group that includes all ranks
  call MPI_GROUP_RANGE_INCL(group_world, 1, range, group_range, ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_GROUP_RANGE_INCL failed"
  call MPI_GROUP_SIZE(group_range, group_size, ierr)
  if (ierr /= MPI_SUCCESS .or. group_size /= size) error stop "wrong size of the range group"

  ! Create new communicator
  call MPI_COMM_CREATE(MPI_COMM_WORLD, group_range, new_comm, ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_COMM_CREATE failed"

  ! Every rank is in the range, so every rank is in new_comm, with its own rank
  if (new_comm == MPI_COMM_NULL) then
    print *, 'Rank', rank, 'is NOT in the new communicator.'
    error stop "MPI_COMM_CREATE left out a rank of the group"
  end if
  call MPI_COMM_RANK(new_comm, new_rank, ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_COMM_RANK on new_comm failed"
  call MPI_COMM_SIZE(new_comm, new_size, ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_COMM_SIZE on new_comm failed"
  print *, 'Global rank', rank, 'is in new_comm with local rank', new_rank
  if (new_rank /= rank .or. new_size /= size) then
    print *, 'Rank', rank, ': new_comm rank, size =', new_rank, new_size, &
             'expected', rank, size
    error stop "wrong rank or size in new_comm"
  end if

  ! Free groups (no comm_free)
  call MPI_GROUP_FREE(group_range, ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_GROUP_FREE(group_range) failed"

  ! A strided range: the even ranks are in the new communicator, the odd
  ! ranks get MPI_COMM_NULL
  range(1,3) = 2
  call MPI_GROUP_RANGE_INCL(group_world, 1, range, group_range, ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_GROUP_RANGE_INCL (stride 2) failed"
  call MPI_GROUP_SIZE(group_range, group_size, ierr)
  if (ierr /= MPI_SUCCESS .or. group_size /= (size + 1) / 2) &
    error stop "wrong size of the strided range group"
  call MPI_COMM_CREATE(MPI_COMM_WORLD, group_range, new_comm, ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_COMM_CREATE (stride 2) failed"
  if (mod(rank, 2) == 0) then
    if (new_comm == MPI_COMM_NULL) error stop "even rank left out of the strided communicator"
    call MPI_COMM_RANK(new_comm, new_rank, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_COMM_RANK on the strided communicator failed"
    call MPI_COMM_SIZE(new_comm, new_size, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_COMM_SIZE on the strided communicator failed"
    if (new_rank /= rank / 2 .or. new_size /= (size + 1) / 2) then
      print *, 'Rank', rank, ': strided rank, size =', new_rank, new_size, &
               'expected', rank / 2, (size + 1) / 2
      error stop "wrong rank or size in the strided communicator"
    end if
  else
    if (new_comm /= MPI_COMM_NULL) error stop "odd rank got a strided communicator"
  end if

  call MPI_GROUP_FREE(group_range, ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_GROUP_FREE(group_range) failed"
  call MPI_GROUP_FREE(group_world, ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_GROUP_FREE(group_world) failed"

  call MPI_FINALIZE(ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_FINALIZE failed"
end program minimal_mre_range
