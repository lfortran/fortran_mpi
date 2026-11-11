program gatherv_3
  use mpi
  implicit none

  integer :: rank, nprocs, ierr, i
  integer :: local_data(3)
  integer, allocatable :: gathered_data(:)
  integer, allocatable :: counts(:), displacements(:)

  call MPI_INIT(ierr)
  call MPI_COMM_RANK(MPI_COMM_WORLD, rank, ierr)
  call MPI_COMM_SIZE(MPI_COMM_WORLD, nprocs, ierr)

  local_data = (/ rank*3+1, rank*3+2, rank*3+3 /)

  allocate(counts(nprocs))
  allocate(displacements(nprocs))

  call gatherIntegers(local_data, gathered_data, counts, displacements, rank, nprocs, MPI_COMM_WORLD)

  ! Rank r sent 3*r+1 .. 3*r+3, so the root has 1 .. 3*nprocs in order
  if (rank == 0) then
    if (size(gathered_data) /= 3*nprocs) error stop "wrong size of gathered_data"
    do i = 1, 3*nprocs
      if (gathered_data(i) /= i) then
        print *, "gathered_data(", i, ") =", gathered_data(i), "expected", i
        error stop "MPI_GatherV gathered wrong data"
      end if
    end do
    print *, "MPI_GatherV test passed:", gathered_data
  end if
  if (any(counts /= 3)) error stop "wrong counts"
  if (any(displacements /= [(3*i, i = 0, nprocs - 1)])) error stop "wrong displacements"

  deallocate(counts, displacements)
  if (rank == 0) deallocate(gathered_data)

  call MPI_FINALIZE(ierr)
  if (ierr /= MPI_SUCCESS) error stop "MPI_FINALIZE failed"

contains

  subroutine gatherIntegers(local_data, gathered_data, counts, displacements, rank, nprocs, comm)
    integer, intent(in) :: local_data(:)
    integer, allocatable, intent(out) :: gathered_data(:)
    integer, intent(out) :: counts(:)
    integer, intent(out) :: displacements(:)
    integer, intent(in) :: rank, nprocs, comm

    integer :: i, total_elements, ierr
    integer :: local_size

    local_size = size(local_data)
    counts = local_size

    displacements(1) = 0
    do i = 2, nprocs
       displacements(i) = displacements(i-1) + counts(i-1)
    end do

    total_elements = local_size * nprocs

    if (rank == 0) then
       allocate(gathered_data(total_elements))
    else
       allocate(gathered_data(1))
    end if

    call MPI_GatherV(local_data, local_size, MPI_INTEGER, &
                     gathered_data, counts, displacements, MPI_INTEGER, &
                     0, comm, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_GatherV failed"

  end subroutine gatherIntegers

end program gatherv_3
