program owned_handle_status_1
    use mpi
    implicit none
    integer, parameter :: extent = MPI_STATUS_SIZE
    integer :: ierr, rank, nprocs, group, another_group, empty, n, datatype, requests(2), saved, i, index
    integer :: ranges(3, 1), guarded(extent + 2), statuses(extent, 2), status(extent)
    integer, asynchronous :: sent(2), received(2)
    logical :: done

    call MPI_Init(ierr)
    call check(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)
    call check(ierr)
    call MPI_Comm_size(MPI_COMM_WORLD, nprocs, ierr)
    call check(ierr)
    datatype = MPI_INTEGER
    call MPI_Type_commit(datatype, ierr)
    call check(ierr)
    if (datatype /= MPI_INTEGER) error stop "predefined datatype identity"
    call MPI_Comm_group(MPI_COMM_WORLD, group, ierr)
    call check(ierr)
    call MPI_Comm_group(MPI_COMM_WORLD, another_group, ierr)
    call check(ierr)
    call MPI_Group_free(another_group, ierr)
    call check(ierr)
    call MPI_Group_size(group, n, ierr)
    call check(ierr)
    if (n /= nprocs) error stop "separate group acquisition lost"
    ranges(:, 1) = [0, 0, 1]
    do i = 1, 64
        call MPI_Group_range_incl(group, 0, ranges, empty, ierr)
        call check(ierr)
        if (empty /= MPI_GROUP_EMPTY) error stop "empty group identity"
        call MPI_Group_free(empty, ierr)
        call check(ierr)
        if (empty /= MPI_GROUP_NULL) error stop "group free"
        call MPI_Group_size(MPI_GROUP_EMPTY, n, ierr)
        call check(ierr)
        if (n /= 0) error stop "immutable empty group"

        call MPI_Type_contiguous(2, MPI_INTEGER, datatype, ierr)
        call check(ierr)
        saved = datatype
        call MPI_Type_commit(datatype, ierr)
        call check(ierr)
        if (datatype /= saved) error stop "commit changed live identity"
        received = -1
        sent = [i, -i]
        call MPI_Irecv(received, 1, datatype, rank, i, MPI_COMM_WORLD, requests(1), ierr)
        call check(ierr)
        saved = requests(1)
        call MPI_Test(requests(1), done, MPI_STATUS_IGNORE, ierr)
        call check(ierr)
        if (done .or. requests(1) /= saved) error stop "incomplete request retired"
        call MPI_Isend(sent, 1, datatype, rank, i, MPI_COMM_WORLD, requests(2), ierr)
        call check(ierr)
        if (mod(i, 2) == 0) then
            call MPI_Waitall(2, requests, statuses, ierr)
            call check(ierr)
        else
            done = .false.
            do while (.not. done)
                call MPI_Testall(2, requests, done, statuses, ierr)
                call check(ierr)
            end do
        end if
        if (any(requests /= MPI_REQUEST_NULL)) error stop "completed requests not retired"
        if (any(received /= sent)) error stop "derived datatype payload"
        if (statuses(MPI_SOURCE, 1) /= rank .or. statuses(MPI_TAG, 1) /= i) error stop "owned status fields"
        call MPI_Get_count(statuses(:, 1), datatype, n, ierr)
        call check(ierr)
        if (n /= 1) error stop "owned status derived count"
        call MPI_Get_count(statuses(:, 1), MPI_INTEGER, n, ierr)
        call check(ierr)
        if (n /= 2) error stop "owned status basic count"
        call MPI_Type_free(datatype, ierr)
        call check(ierr)
        if (datatype /= MPI_DATATYPE_NULL) error stop "datatype free"
    end do
    call MPI_Group_free(group, ierr)
    call check(ierr)
    call MPI_Waitany(2, requests, index, status, ierr)
    call check(ierr)
    if (index /= MPI_UNDEFINED) error stop "null waitany"
    call MPI_Waitall(0, requests, MPI_STATUSES_IGNORE, ierr)
    call check(ierr)
    guarded = -12345
    call MPI_Sendrecv(sent, 2, MPI_INTEGER, MPI_PROC_NULL, 81, received, 2, MPI_INTEGER, &
        MPI_PROC_NULL, 81, MPI_COMM_WORLD, guarded(2:extent+1), ierr)
    call check(ierr)
    if (guarded(1) /= -12345 .or. guarded(extent+2) /= -12345) error stop "status overrun"
    if (guarded(MPI_SOURCE+1) /= MPI_PROC_NULL) error stop "proc-null status rank"
    if (guarded(MPI_TAG+1) /= MPI_ANY_TAG) error stop "proc-null status tag"
    call MPI_Get_count(guarded(2:extent+1), MPI_INTEGER, n, ierr)
    call check(ierr)
    if (n /= 0) error stop "empty status count"
    call MPI_Finalize(ierr)
    call check(ierr)
    if (rank == 0) print *, "owned_handle_status_1: OK"
contains
    subroutine check(code)
        integer, intent(in) :: code
        if (code /= MPI_SUCCESS) error stop "owned handle/status operation"
    end subroutine
end program
