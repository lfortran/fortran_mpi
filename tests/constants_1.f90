program constants_1
    ! Each predefined datatype and communicator must be the object of the
    ! same name in the MPI library.
    use mpi
    implicit none
    integer :: ierr

    call MPI_Init(ierr)

    call check_type(MPI_INTEGER, "MPI_INTEGER")
    call check_type(MPI_REAL, "MPI_REAL")
    call check_type(MPI_DOUBLE_PRECISION, "MPI_DOUBLE_PRECISION")
    call check_type(MPI_LOGICAL, "MPI_LOGICAL")
    call check_type(MPI_CHARACTER, "MPI_CHARACTER")
    call check_type(MPI_REAL4, "MPI_REAL4")
    call check_type(MPI_REAL8, "MPI_REAL8")
    call check_type(MPI_INT, "MPI_INT")
    call check_type(MPI_FLOAT, "MPI_FLOAT")
    call check_type(MPI_DOUBLE, "MPI_DOUBLE")
    call check_type(MPI_INT32_T, "MPI_INT32_T")
    call check_type(MPI_INT64_T, "MPI_INT64_T")

    call check_comm(MPI_COMM_WORLD, "MPI_COMM_WORLD")
    call check_comm(MPI_COMM_SELF, "MPI_COMM_SELF")

    call MPI_Finalize(ierr)

contains

    subroutine check_type(datatype, expected)
        integer, intent(in) :: datatype
        character(len=*), intent(in) :: expected
        character(len=MPI_MAX_OBJECT_NAME) :: name
        integer :: resultlen, ierr
        call MPI_Type_get_name(datatype, name, resultlen, ierr)
        if (ierr /= MPI_SUCCESS .or. name(1:resultlen) /= expected) then
            print *, "Datatype ", expected, " is named '", name(1:resultlen), "'"
            error stop
        end if
    end subroutine check_type

    subroutine check_comm(comm, expected)
        integer, intent(in) :: comm
        character(len=*), intent(in) :: expected
        character(len=MPI_MAX_OBJECT_NAME) :: name
        integer :: resultlen, ierr
        call MPI_Comm_get_name(comm, name, resultlen, ierr)
        if (ierr /= MPI_SUCCESS .or. name(1:resultlen) /= expected) then
            print *, "Communicator ", expected, " is named '", name(1:resultlen), "'"
            error stop
        end if
    end subroutine check_comm

end program constants_1
