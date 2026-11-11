program get_processor_name_1
    ! MPI_Get_processor_name. The tests run on one machine, so every rank
    ! must get the same name.
    use mpi
    implicit none
    integer :: ierr, rank, resultlen, len0
    character(len=MPI_MAX_PROCESSOR_NAME) :: name, name0

    call MPI_Init(ierr)
    call MPI_Comm_rank(MPI_COMM_WORLD, rank, ierr)

    name = "?"
    call MPI_Get_processor_name(name, resultlen, ierr)
    if (ierr /= MPI_SUCCESS) error stop "MPI_Get_processor_name failed"
    if (resultlen < 1 .or. resultlen > MPI_MAX_PROCESSOR_NAME) then
        print *, "resultlen =", resultlen
        error stop "MPI_Get_processor_name: wrong resultlen"
    end if
    if (len_trim(name) /= resultlen) then
        print *, "name = '", trim(name), "', resultlen =", resultlen
        error stop "MPI_Get_processor_name: resultlen is not the length of the name"
    end if
    if (index(name(1:resultlen), achar(0)) /= 0) error stop "MPI_Get_processor_name: NUL in name"

    name0 = name
    len0 = resultlen
    call MPI_Bcast(name0, MPI_MAX_PROCESSOR_NAME, MPI_CHARACTER, 0, MPI_COMM_WORLD, ierr)
    call MPI_Bcast(len0, 1, MPI_INTEGER, 0, MPI_COMM_WORLD, ierr)
    if (name0 /= name .or. len0 /= resultlen) then
        print *, "rank", rank, ": '", trim(name), "' /= '", trim(name0), "'"
        error stop "MPI_Get_processor_name: ranks on one machine got different names"
    end if

    if (rank == 0) print *, "get_processor_name_1: OK, ", name(1:resultlen)
    call MPI_Finalize(ierr)
end program get_processor_name_1
