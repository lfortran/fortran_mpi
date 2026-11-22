module mpi
    use mpi_native_constants
    use mpi_c_bindings, only: MPI_HANDLE_KIND
    use iso_c_binding, only: c_int, c_char, c_ptr, c_loc, c_null_ptr, c_associated
    implicit none

    ! Handles, status metadata and special ranks come from the selected
    ! runtime's headers. The remaining scalar conventions retain their
    ! MPI-5 ABI values and are normalized at the C boundary. See doc/design.md.

    integer, parameter :: MPI_SUCCESS = 0

    integer, parameter :: MPI_INTEGER_KIND = kind(0)

    ! Error classes
    integer, parameter :: MPI_ERR_BUFFER                = 1
    integer, parameter :: MPI_ERR_COUNT                 = 2
    integer, parameter :: MPI_ERR_TYPE                  = 3
    integer, parameter :: MPI_ERR_TAG                   = 4
    integer, parameter :: MPI_ERR_COMM                  = 5
    integer, parameter :: MPI_ERR_RANK                  = 6
    integer, parameter :: MPI_ERR_REQUEST               = 7
    integer, parameter :: MPI_ERR_ROOT                  = 8
    integer, parameter :: MPI_ERR_GROUP                 = 9
    integer, parameter :: MPI_ERR_OP                    = 10
    integer, parameter :: MPI_ERR_TOPOLOGY              = 11
    integer, parameter :: MPI_ERR_DIMS                  = 12
    integer, parameter :: MPI_ERR_ARG                   = 13
    integer, parameter :: MPI_ERR_UNKNOWN               = 14
    integer, parameter :: MPI_ERR_TRUNCATE              = 15
    integer, parameter :: MPI_ERR_OTHER                 = 16
    integer, parameter :: MPI_ERR_INTERN                = 17
    integer, parameter :: MPI_ERR_PENDING               = 18
    integer, parameter :: MPI_ERR_IN_STATUS             = 19
    integer, parameter :: MPI_ERR_ACCESS                = 20
    integer, parameter :: MPI_ERR_AMODE                 = 21
    integer, parameter :: MPI_ERR_ASSERT                = 22
    integer, parameter :: MPI_ERR_BAD_FILE              = 23
    integer, parameter :: MPI_ERR_BASE                  = 24
    integer, parameter :: MPI_ERR_CONVERSION            = 25
    integer, parameter :: MPI_ERR_DISP                  = 26
    integer, parameter :: MPI_ERR_DUP_DATAREP           = 27
    integer, parameter :: MPI_ERR_FILE_EXISTS           = 28
    integer, parameter :: MPI_ERR_FILE_IN_USE           = 29
    integer, parameter :: MPI_ERR_FILE                  = 30
    integer, parameter :: MPI_ERR_INFO_KEY              = 31
    integer, parameter :: MPI_ERR_INFO_NOKEY            = 32
    integer, parameter :: MPI_ERR_INFO_VALUE            = 33
    integer, parameter :: MPI_ERR_INFO                  = 34
    integer, parameter :: MPI_ERR_IO                    = 35
    integer, parameter :: MPI_ERR_KEYVAL                = 36
    integer, parameter :: MPI_ERR_LOCKTYPE              = 37
    integer, parameter :: MPI_ERR_NAME                  = 38
    integer, parameter :: MPI_ERR_NO_MEM                = 39
    integer, parameter :: MPI_ERR_NOT_SAME              = 40
    integer, parameter :: MPI_ERR_NO_SPACE              = 41
    integer, parameter :: MPI_ERR_NO_SUCH_FILE          = 42
    integer, parameter :: MPI_ERR_PORT                  = 43
    integer, parameter :: MPI_ERR_QUOTA                 = 44
    integer, parameter :: MPI_ERR_READ_ONLY             = 45
    integer, parameter :: MPI_ERR_RMA_ATTACH            = 46
    integer, parameter :: MPI_ERR_RMA_CONFLICT          = 47
    integer, parameter :: MPI_ERR_RMA_RANGE             = 48
    integer, parameter :: MPI_ERR_RMA_SHARED            = 49
    integer, parameter :: MPI_ERR_RMA_SYNC              = 50
    integer, parameter :: MPI_ERR_SERVICE               = 51
    integer, parameter :: MPI_ERR_SIZE                  = 52
    integer, parameter :: MPI_ERR_SPAWN                 = 53
    integer, parameter :: MPI_ERR_UNSUPPORTED_DATAREP   = 54
    integer, parameter :: MPI_ERR_UNSUPPORTED_OPERATION = 55
    integer, parameter :: MPI_ERR_WIN                   = 56
    integer, parameter :: MPI_ERR_RMA_FLAVOR            = 57
    integer, parameter :: MPI_ERR_PROC_ABORTED          = 58
    integer, parameter :: MPI_ERR_VALUE_TOO_LARGE       = 59
    integer, parameter :: MPI_ERR_SESSION               = 60
    integer, parameter :: MPI_ERR_ERRHANDLER            = 61
    integer, parameter :: MPI_ERR_ABI                   = 62
    integer, parameter :: MPI_ERR_LASTCODE = 16383

    ! Thread levels
    integer, parameter :: MPI_THREAD_SINGLE = 0
    integer, parameter :: MPI_THREAD_FUNNELED = 1024
    integer, parameter :: MPI_THREAD_SERIALIZED = 2048
    integer, parameter :: MPI_THREAD_MULTIPLE = 4096

    integer, parameter :: MPI_COMM_TYPE_SHARED = 221

    integer, parameter :: MPI_MAX_OBJECT_NAME = 128
    integer, parameter :: MPI_MAX_ERROR_STRING = 512
    integer, parameter :: MPI_MAX_PROCESSOR_NAME = 256

    ! Results of MPI_Comm_compare
    integer, parameter :: MPI_IDENT = 201
    integer, parameter :: MPI_CONGRUENT = 202
    integer, parameter :: MPI_SIMILAR = 203
    integer, parameter :: MPI_UNEQUAL = 204

    ! MPI_IN_PLACE is recognized by its address (in_place_or), so it must not
    ! be copied. Its type does not matter, since buffers are type(*).
    integer, target :: MPI_IN_PLACE

    ! MPI_STATUS_IGNORE and MPI_STATUSES_IGNORE are recognized by their
    ! address, so they must not be copied: is_status_ignore.
    integer, target :: MPI_STATUS_IGNORE(MPI_STATUS_SIZE)
    integer, target :: MPI_STATUSES_IGNORE(MPI_STATUS_SIZE, 1)

    private :: check_native_mpi, check_predefined_handles, check_handle
    private :: allocate_statuses, release_statuses, status_at
    private :: op_f2c, comm_f2c, comm_c2f, group_f2c, group_c2f, info_f2c
    private :: request_f2c, request_c2f, datatype_f2c, datatype_c2f
    private :: rank_f2c, rank_c2f, tag_f2c, tag_c2f, thread_level_f2c, thread_level_c2f
    private :: split_type_f2c, color_f2c, count_c2f, index_c2f, comparison_c2f
    private :: status_c2f, status_f2c, c_string_to_fortran, set_ierror
    private :: errhandler_f2c, error_class_c2f, is_status_ignore, is_statuses_ignore
    private :: in_place_or
    private :: c_int, c_char, c_ptr, c_loc, c_null_ptr, c_associated

    contains

    ! All public handles use the runtime's own integer representation,
    ! including predefined, created and null handles.

    subroutine check_native_mpi()
        ! Checks that this library was compiled for the MPI library it is
        ! linked with. Called before MPI is initialized.
        use mpi_c_bindings, only: c_sizeof_mpi_comm, c_sizeof_int, c_sizeof_mpi_fint, &
            c_mpi_f_status_size, c_mpi_f_source, c_mpi_f_tag, c_mpi_f_error, &
            c_mpi_max_object_name, c_mpi_max_error_string, c_mpi_max_processor_name, &
            c_mpi_any_source, c_mpi_any_tag, c_mpi_proc_null, c_mpi_root, c_mpi_undefined
        if (c_sizeof_mpi_comm /= MPI_HANDLE_KIND) then
            print *, "fortran_mpi: compiled with MPI_HANDLE_KIND =", MPI_HANDLE_KIND, &
                "but the MPI library's handles have", c_sizeof_mpi_comm, "bytes."
            print *, "Compile src/mpi_c_bindings.f90 with -DOPEN_MPI for Open MPI,", &
                " or with -DMPI_ABI for the MPI-5 ABI (libmpi_abi)."
            error stop 1
        end if
        if (kind(0) /= c_int .or. storage_size(0)/8 /= c_sizeof_int .or. &
                c_sizeof_int /= c_sizeof_mpi_fint) then
            print *, "fortran_mpi: default INTEGER, C int and MPI handle integers must match."
            error stop 1
        end if
        if (MPI_STATUS_SIZE /= c_mpi_f_status_size .or. MPI_SOURCE /= c_mpi_f_source + 1 .or. &
                MPI_TAG /= c_mpi_f_tag + 1 .or. MPI_ERROR /= c_mpi_f_error + 1 .or. &
                MPI_ANY_SOURCE /= c_mpi_any_source .or. MPI_ANY_TAG /= c_mpi_any_tag .or. &
                MPI_PROC_NULL /= c_mpi_proc_null .or. MPI_ROOT /= c_mpi_root .or. &
                MPI_UNDEFINED /= c_mpi_undefined) then
            print *, "fortran_mpi: mismatched MPI constant headers; rebuild with the matching mpif.h and mpi.h."
            error stop 1
        end if
        if (c_mpi_max_object_name > MPI_MAX_OBJECT_NAME) then
            print *, "fortran_mpi: the native MPI_MAX_OBJECT_NAME is", &
                c_mpi_max_object_name, "more than", MPI_MAX_OBJECT_NAME
            error stop 1
        end if
        if (c_mpi_max_error_string > MPI_MAX_ERROR_STRING) then
            print *, "fortran_mpi: the native MPI_MAX_ERROR_STRING is", &
                c_mpi_max_error_string, "more than", MPI_MAX_ERROR_STRING
            error stop 1
        end if
        if (c_mpi_max_processor_name > MPI_MAX_PROCESSOR_NAME) then
            print *, "fortran_mpi: the native MPI_MAX_PROCESSOR_NAME is", &
                c_mpi_max_processor_name, "more than", MPI_MAX_PROCESSOR_NAME
            error stop 1
        end if
    end subroutine check_native_mpi

    subroutine check_handle(native, expected, family)
        integer, intent(in) :: native, expected
        character(*), intent(in) :: family
        if (native /= expected) then
            print *, "fortran_mpi: mismatched predefined ", family, " handle:", expected, "expected", native
            print *, "Rebuild with the MPI library's matching constant headers."
            error stop 1
        end if
    end subroutine check_handle

    subroutine check_predefined_handles()
        ! Conversions are legal only after initialization. In ABI mode these
        ! toint calls also register predefined handles before any fromint.
        use mpi_c_bindings, only: c_op_table, c_comm_table, c_group_table, c_info_table, &
            c_request_table, c_datatype_table, c_errhandler_table, c_mpi_op_c2f, &
            c_mpi_comm_c2f, c_mpi_group_c2f, c_mpi_info_c2f, c_mpi_request_c2f, &
            c_mpi_type_c2f, c_mpi_errhandler_c2f
        integer, parameter :: ops(*) = [MPI_OP_NULL, MPI_SUM, MPI_MIN, MPI_MAX, MPI_PROD, &
            MPI_BAND, MPI_BOR, MPI_BXOR, MPI_LAND, MPI_LOR, MPI_LXOR, MPI_MINLOC, MPI_MAXLOC, MPI_REPLACE, MPI_NO_OP]
        integer, parameter :: comms(*) = [MPI_COMM_NULL, MPI_COMM_WORLD, MPI_COMM_SELF]
        integer, parameter :: groups(*) = [MPI_GROUP_NULL, MPI_GROUP_EMPTY]
        integer, parameter :: handlers(*) = [MPI_ERRHANDLER_NULL, MPI_ERRORS_ARE_FATAL, MPI_ERRORS_ABORT, MPI_ERRORS_RETURN]
        integer, parameter :: types(*) = [MPI_DATATYPE_NULL, MPI_INT, MPI_FLOAT, MPI_DOUBLE, MPI_LOGICAL, &
            MPI_INTEGER, MPI_REAL, MPI_DOUBLE_PRECISION, MPI_DOUBLE_COMPLEX, MPI_CHARACTER, &
            MPI_INT32_T, MPI_INT64_T, MPI_REAL4, MPI_INTEGER8, MPI_REAL8]
        integer :: i
        do i = 1, size(ops)
            call check_handle(c_mpi_op_c2f(c_op_table(i)), ops(i), "operation")
        end do
        do i = 1, size(comms)
            call check_handle(c_mpi_comm_c2f(c_comm_table(i)), comms(i), "communicator")
        end do
        do i = 1, size(groups)
            call check_handle(c_mpi_group_c2f(c_group_table(i)), groups(i), "group")
        end do
        call check_handle(c_mpi_info_c2f(c_info_table(1)), MPI_INFO_NULL, "info")
        call check_handle(c_mpi_request_c2f(c_request_table(1)), MPI_REQUEST_NULL, "request")
        do i = 1, size(handlers)
            call check_handle(c_mpi_errhandler_c2f(c_errhandler_table(i)), handlers(i), "error handler")
        end do
        do i = 1, size(types)
            call check_handle(c_mpi_type_c2f(c_datatype_table(i)), types(i), "datatype")
        end do
    end subroutine check_predefined_handles

    integer(kind=MPI_HANDLE_KIND) function op_f2c(op) result(c_op)
        use mpi_c_bindings, only: c_mpi_op_f2c
        integer, intent(in) :: op
        c_op = c_mpi_op_f2c(op)
    end function op_f2c

    integer(kind=MPI_HANDLE_KIND) function comm_f2c(comm) result(c_comm)
        use mpi_c_bindings, only: c_mpi_comm_f2c
        integer, intent(in) :: comm
        c_comm = c_mpi_comm_f2c(comm)
    end function comm_f2c

    integer function comm_c2f(c_comm) result(comm)
        use mpi_c_bindings, only: c_mpi_comm_c2f
        integer(kind=MPI_HANDLE_KIND), intent(in) :: c_comm
        comm = c_mpi_comm_c2f(c_comm)
    end function comm_c2f

    integer(kind=MPI_HANDLE_KIND) function group_f2c(group) result(c_group)
        use mpi_c_bindings, only: c_mpi_group_f2c
        integer, intent(in) :: group
        c_group = c_mpi_group_f2c(group)
    end function group_f2c

    integer function group_c2f(c_group) result(group)
        use mpi_c_bindings, only: c_mpi_group_c2f
        integer(kind=MPI_HANDLE_KIND), intent(in) :: c_group
        group = c_mpi_group_c2f(c_group)
    end function group_c2f

    integer(kind=MPI_HANDLE_KIND) function info_f2c(info) result(c_info)
        use mpi_c_bindings, only: c_mpi_info_f2c
        integer, intent(in) :: info
        c_info = c_mpi_info_f2c(info)
    end function info_f2c

    integer(kind=MPI_HANDLE_KIND) function request_f2c(request) result(c_request)
        use mpi_c_bindings, only: c_mpi_request_f2c
        integer, intent(in) :: request
        c_request = c_mpi_request_f2c(request)
    end function request_f2c

    integer function request_c2f(c_request) result(request)
        use mpi_c_bindings, only: c_mpi_request_c2f
        integer(kind=MPI_HANDLE_KIND), intent(in) :: c_request
        request = c_mpi_request_c2f(c_request)
    end function request_c2f

    integer(kind=MPI_HANDLE_KIND) function datatype_f2c(datatype) result(c_datatype)
        use mpi_c_bindings, only: c_mpi_type_f2c
        integer, intent(in) :: datatype
        c_datatype = c_mpi_type_f2c(datatype)
    end function datatype_f2c

    integer function datatype_c2f(c_datatype) result(datatype)
        use mpi_c_bindings, only: c_mpi_type_c2f
        integer(kind=MPI_HANDLE_KIND), intent(in) :: c_datatype
        datatype = c_mpi_type_c2f(c_datatype)
    end function datatype_c2f

    integer(kind=MPI_HANDLE_KIND) function errhandler_f2c(errhandler) result(c_errhandler)
        use mpi_c_bindings, only: c_mpi_errhandler_f2c
        integer, intent(in) :: errhandler
        c_errhandler = c_mpi_errhandler_f2c(errhandler)
    end function errhandler_f2c

    integer function error_class_c2f(c_class) result(class)
        use mpi_c_bindings, only: c_error_class_table
        integer, intent(in) :: c_class
        integer :: i
        do i = 0, ubound(c_error_class_table, 1)
            if (c_class == c_error_class_table(i)) then
                class = i
                return
            end if
        end do
        class = MPI_ERR_UNKNOWN
    end function error_class_c2f

    ! Ranks and tags are passed unchanged, except for the special values,
    ! which are all negative.

    integer function rank_f2c(rank) result(c_rank)
        use mpi_c_bindings, only: c_mpi_any_source, c_mpi_proc_null, c_mpi_root
        integer, intent(in) :: rank
        if (rank >= 0) then
            c_rank = rank
        else if (rank == MPI_PROC_NULL) then
            c_rank = c_mpi_proc_null
        else if (rank == MPI_ANY_SOURCE) then
            c_rank = c_mpi_any_source
        else if (rank == MPI_ROOT) then
            c_rank = c_mpi_root
        else
            c_rank = rank
        end if
    end function rank_f2c

    integer function rank_c2f(c_rank) result(rank)
        use mpi_c_bindings, only: c_mpi_any_source, c_mpi_proc_null, c_mpi_root, &
            c_mpi_undefined
        integer, intent(in) :: c_rank
        if (c_rank >= 0) then
            rank = c_rank
        else if (c_rank == c_mpi_proc_null) then
            rank = MPI_PROC_NULL
        else if (c_rank == c_mpi_any_source) then
            rank = MPI_ANY_SOURCE
        else if (c_rank == c_mpi_root) then
            rank = MPI_ROOT
        else if (c_rank == c_mpi_undefined) then
            rank = MPI_UNDEFINED
        else
            rank = c_rank
        end if
    end function rank_c2f

    integer function tag_f2c(tag) result(c_tag)
        use mpi_c_bindings, only: c_mpi_any_tag
        integer, intent(in) :: tag
        if (tag == MPI_ANY_TAG) then
            c_tag = c_mpi_any_tag
        else
            c_tag = tag
        end if
    end function tag_f2c

    integer function tag_c2f(c_tag) result(tag)
        use mpi_c_bindings, only: c_mpi_any_tag
        integer, intent(in) :: c_tag
        if (c_tag == c_mpi_any_tag) then
            tag = MPI_ANY_TAG
        else
            tag = c_tag
        end if
    end function tag_c2f

    integer function thread_level_f2c(level) result(c_level)
        use mpi_c_bindings, only: c_mpi_thread_single, c_mpi_thread_funneled, &
            c_mpi_thread_serialized, c_mpi_thread_multiple
        integer, intent(in) :: level
        select case (level)
        case (MPI_THREAD_SINGLE)
            c_level = c_mpi_thread_single
        case (MPI_THREAD_FUNNELED)
            c_level = c_mpi_thread_funneled
        case (MPI_THREAD_SERIALIZED)
            c_level = c_mpi_thread_serialized
        case (MPI_THREAD_MULTIPLE)
            c_level = c_mpi_thread_multiple
        case default
            c_level = level
        end select
    end function thread_level_f2c

    integer function thread_level_c2f(c_level) result(level)
        use mpi_c_bindings, only: c_mpi_thread_single, c_mpi_thread_funneled, &
            c_mpi_thread_serialized, c_mpi_thread_multiple
        integer, intent(in) :: c_level
        if (c_level == c_mpi_thread_single) then
            level = MPI_THREAD_SINGLE
        else if (c_level == c_mpi_thread_funneled) then
            level = MPI_THREAD_FUNNELED
        else if (c_level == c_mpi_thread_serialized) then
            level = MPI_THREAD_SERIALIZED
        else if (c_level == c_mpi_thread_multiple) then
            level = MPI_THREAD_MULTIPLE
        else
            level = c_level
        end if
    end function thread_level_c2f

    integer function split_type_f2c(split_type) result(c_split_type)
        use mpi_c_bindings, only: c_mpi_comm_type_shared, c_mpi_undefined
        integer, intent(in) :: split_type
        if (split_type == MPI_COMM_TYPE_SHARED) then
            c_split_type = c_mpi_comm_type_shared
        else if (split_type == MPI_UNDEFINED) then
            c_split_type = c_mpi_undefined
        else
            c_split_type = split_type
        end if
    end function split_type_f2c

    integer function color_f2c(color) result(c_color)
        use mpi_c_bindings, only: c_mpi_undefined
        integer, intent(in) :: color
        if (color == MPI_UNDEFINED) then
            c_color = c_mpi_undefined
        else
            c_color = color
        end if
    end function color_f2c

    integer function comparison_c2f(c_result) result(comparison)
        ! The result of MPI_Comm_compare
        use mpi_c_bindings, only: c_mpi_ident, c_mpi_congruent, c_mpi_similar, c_mpi_unequal
        integer, intent(in) :: c_result
        if (c_result == c_mpi_ident) then
            comparison = MPI_IDENT
        else if (c_result == c_mpi_congruent) then
            comparison = MPI_CONGRUENT
        else if (c_result == c_mpi_similar) then
            comparison = MPI_SIMILAR
        else if (c_result == c_mpi_unequal) then
            comparison = MPI_UNEQUAL
        else
            comparison = c_result
        end if
    end function comparison_c2f

    integer function count_c2f(c_count) result(count)
        ! A count that MPI returns, which may be MPI_UNDEFINED
        use mpi_c_bindings, only: c_mpi_undefined
        integer, intent(in) :: c_count
        if (c_count == c_mpi_undefined) then
            count = MPI_UNDEFINED
        else
            count = c_count
        end if
    end function count_c2f

    integer function index_c2f(c_index) result(index)
        ! An index into an array of requests: C counts from 0, Fortran from 1.
        ! MPI_UNDEFINED means that no request was active.
        use mpi_c_bindings, only: c_mpi_undefined
        integer, intent(in) :: c_index
        if (c_index == c_mpi_undefined) then
            index = MPI_UNDEFINED
        else
            index = c_index + 1
        end if
    end function index_c2f

    logical function is_status_ignore(status)
        ! Whether the status argument is MPI_STATUS_IGNORE. The pointers are
        ! compared as variables, which works around an LFortran bug with
        ! c_associated(c_loc(a), c_loc(b)).
        integer, target :: status(MPI_STATUS_SIZE)
        type(c_ptr) :: p, ignore
        p = c_loc(status)
        ignore = c_loc(MPI_STATUS_IGNORE)
        is_status_ignore = c_associated(p, ignore)
    end function is_status_ignore

    logical function is_statuses_ignore(statuses)
        integer, target :: statuses(MPI_STATUS_SIZE, *)
        type(c_ptr) :: p, ignore
        p = c_loc(statuses)
        ignore = c_loc(MPI_STATUSES_IGNORE)
        is_statuses_ignore = c_associated(p, ignore)
    end function is_statuses_ignore

    logical function allocate_statuses(count, storage, name, ierror) result(ok)
        use iso_c_binding, only: c_size_t
        use mpi_c_bindings, only: c_malloc, c_sizeof_mpi_status, c_error_class_table
        integer, intent(in) :: count
        type(c_ptr), intent(out) :: storage
        character(*), intent(in) :: name
        integer, optional, intent(out) :: ierror
        integer(c_size_t) :: n, stride
        n = int(max(count, 1), c_size_t)
        stride = int(c_sizeof_mpi_status, c_size_t)
        storage = c_null_ptr
        if (n <= huge(n)/stride) storage = c_malloc(n*stride)
        ok = c_associated(storage)
        if (.not. ok) call set_ierror(c_error_class_table(MPI_ERR_NO_MEM), name, ierror)
    end function allocate_statuses

    subroutine release_statuses(storage)
        use mpi_c_bindings, only: c_free
        type(c_ptr), intent(inout) :: storage
        call c_free(storage)
        storage = c_null_ptr
    end subroutine release_statuses

    function status_at(storage, index) result(pointer)
        use iso_c_binding, only: c_int8_t, c_size_t, c_f_pointer
        use mpi_c_bindings, only: c_sizeof_mpi_status
        type(c_ptr), intent(in) :: storage
        integer, intent(in) :: index
        type(c_ptr) :: pointer
        integer(c_int8_t), pointer :: bytes(:)
        integer(c_size_t) :: stride, offset
        stride = int(c_sizeof_mpi_status, c_size_t)
        offset = int(index - 1, c_size_t)*stride
        call c_f_pointer(storage, bytes, [offset + stride])
        pointer = c_loc(bytes(offset + 1))
    end function status_at

    subroutine status_c2f(c_status, status, mpi_ierror)
        use mpi_c_bindings, only: c_mpi_status_c2f
        type(c_ptr), intent(in) :: c_status
        integer, intent(out) :: status(MPI_STATUS_SIZE)
        integer(c_int), intent(inout) :: mpi_ierror
        integer(c_int) :: conversion_ierror
        conversion_ierror = c_mpi_status_c2f(c_status, status)
        if (conversion_ierror /= MPI_SUCCESS) then
            call set_ierror(conversion_ierror, "MPI_Status_c2f")
            ! Do not hide a native completion error with a conversion error.
            if (mpi_ierror == MPI_SUCCESS) mpi_ierror = conversion_ierror
        end if
    end subroutine status_c2f

    subroutine status_f2c(status, c_status, ierror)
        use mpi_c_bindings, only: c_mpi_status_f2c
        integer, intent(in) :: status(MPI_STATUS_SIZE)
        type(c_ptr), intent(in) :: c_status
        integer(c_int), intent(out) :: ierror
        ierror = c_mpi_status_f2c(status, c_status)
    end subroutine status_f2c

    subroutine c_string_to_fortran(c_name, resultlen, name)
        character(kind=c_char), intent(in) :: c_name(*)
        integer, intent(in) :: resultlen
        character(len=*), intent(out) :: name
        integer :: i
        name = ""
        do i = 1, min(resultlen, len(name))
            name(i:i) = c_name(i)
        end do
    end subroutine c_string_to_fortran

    subroutine set_ierror(c_ierror, name, ierror)
        ! Returns the error code in ierror if it is present, and prints it
        ! otherwise.
        integer(c_int), intent(in) :: c_ierror
        character(len=*), intent(in) :: name
        integer, optional, intent(out) :: ierror
        if (present(ierror)) then
            ierror = c_ierror
        else if (c_ierror /= MPI_SUCCESS) then
            print *, name, " failed with error code: ", c_ierror
        end if
    end subroutine set_ierror

    ! The MPI routines. Each has exactly one specific procedure. A buffer is
    ! type(*), dimension(..), so it accepts every type, kind and rank, and
    ! the C function gets c_loc of it. Blocking routines declare it
    ! contiguous: a non-contiguous section is passed as a contiguous copy.
    ! Nonblocking routines cannot use a copy, so they require a contiguous
    ! buffer.

    subroutine MPI_Init(ierr)
        use mpi_c_bindings, only: c_mpi_init
        integer, optional, intent(out) :: ierr
        integer(c_int) :: argc, local_ierr
        type(c_ptr) :: argv
        call check_native_mpi()
        argc = 0
        argv = c_null_ptr
        local_ierr = c_mpi_init(argc, argv)
        if (local_ierr == MPI_SUCCESS) call check_predefined_handles()
        call set_ierror(local_ierr, "MPI_Init", ierr)
    end subroutine MPI_Init

    subroutine MPI_Init_thread(required, provided, ierr)
        use mpi_c_bindings, only: c_mpi_init_thread
        integer, intent(in) :: required
        integer, intent(out) :: provided
        integer, optional, intent(out) :: ierr
        integer(c_int) :: argc, c_provided, local_ierr
        type(c_ptr) :: argv
        call check_native_mpi()
        argc = 0
        argv = c_null_ptr
        local_ierr = c_mpi_init_thread(argc, argv, thread_level_f2c(required), c_provided)
        if (local_ierr == MPI_SUCCESS) call check_predefined_handles()
        provided = thread_level_c2f(c_provided)
        call set_ierror(local_ierr, "MPI_Init_thread", ierr)
    end subroutine MPI_Init_thread

    subroutine MPI_Initialized(flag, ierr)
        use mpi_c_bindings, only: c_mpi_initialized
        logical, intent(out) :: flag
        integer, optional, intent(out) :: ierr
        integer(c_int) :: c_flag, local_ierr
        local_ierr = c_mpi_initialized(c_flag)
        flag = (c_flag /= 0)
        call set_ierror(local_ierr, "MPI_Initialized", ierr)
    end subroutine MPI_Initialized

    subroutine MPI_Finalized(flag, ierror)
        use mpi_c_bindings, only: c_mpi_finalized
        logical, intent(out) :: flag
        integer, optional, intent(out) :: ierror
        integer(c_int) :: c_flag, local_ierr
        local_ierr = c_mpi_finalized(c_flag)
        flag = (c_flag /= 0)
        call set_ierror(local_ierr, "MPI_Finalized", ierror)
    end subroutine MPI_Finalized

    subroutine MPI_Finalize(ierr)
        use mpi_c_bindings, only: c_mpi_finalize
        integer, optional, intent(out) :: ierr
        call set_ierror(c_mpi_finalize(), "MPI_Finalize", ierr)
    end subroutine MPI_Finalize

    subroutine MPI_Abort(comm, errorcode, ierror)
        use mpi_c_bindings, only: c_mpi_abort
        integer, intent(in) :: comm, errorcode
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_abort(comm_f2c(comm), errorcode), "MPI_Abort", ierror)
    end subroutine MPI_Abort

    function MPI_Wtime() result(time)
        use mpi_c_bindings, only: c_mpi_wtime
        real(8) :: time
        time = c_mpi_wtime()
    end function MPI_Wtime

    function MPI_Wtick() result(tick)
        use mpi_c_bindings, only: c_mpi_wtick
        real(8) :: tick
        tick = c_mpi_wtick()
    end function MPI_Wtick

    subroutine MPI_Get_processor_name(name, resultlen, ierror)
        use mpi_c_bindings, only: c_mpi_get_processor_name
        character(len=*), intent(out) :: name
        integer, intent(out) :: resultlen
        integer, optional, intent(out) :: ierror
        character(kind=c_char) :: c_name(MPI_MAX_PROCESSOR_NAME)
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_get_processor_name(c_name, resultlen)
        call c_string_to_fortran(c_name, resultlen, name)
        call set_ierror(local_ierr, "MPI_Get_processor_name", ierror)
    end subroutine MPI_Get_processor_name

    ! Communicators and groups

    subroutine MPI_Comm_size(comm, size, ierror)
        use mpi_c_bindings, only: c_mpi_comm_size
        integer, intent(in) :: comm
        integer, intent(out) :: size
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_comm_size(comm_f2c(comm), size), "MPI_Comm_size", ierror)
    end subroutine MPI_Comm_size

    subroutine MPI_Comm_rank(comm, rank, ierror)
        use mpi_c_bindings, only: c_mpi_comm_rank
        integer, intent(in) :: comm
        integer, intent(out) :: rank
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_comm_rank(comm_f2c(comm), rank), "MPI_Comm_rank", ierror)
    end subroutine MPI_Comm_rank

    subroutine MPI_Comm_compare(comm1, comm2, result, ierror)
        use mpi_c_bindings, only: c_mpi_comm_compare
        integer, intent(in) :: comm1, comm2
        integer, intent(out) :: result
        integer, optional, intent(out) :: ierror
        integer(c_int) :: c_result, local_ierr
        local_ierr = c_mpi_comm_compare(comm_f2c(comm1), comm_f2c(comm2), c_result)
        result = comparison_c2f(c_result)
        call set_ierror(local_ierr, "MPI_Comm_compare", ierror)
    end subroutine MPI_Comm_compare

    subroutine MPI_Comm_Group(comm, group, ierror)
        use mpi_c_bindings, only: c_mpi_comm_group
        integer, intent(in) :: comm
        integer, intent(out) :: group
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_group
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_comm_group(comm_f2c(comm), c_group)
        group = group_c2f(c_group)
        call set_ierror(local_ierr, "MPI_Comm_group", ierror)
    end subroutine MPI_Comm_Group

    subroutine MPI_Group_size(group, size, ierror)
        use mpi_c_bindings, only: c_mpi_group_size
        integer, intent(in) :: group
        integer, intent(out) :: size
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_group_size(group_f2c(group), size), "MPI_Group_size", ierror)
    end subroutine MPI_Group_size

    subroutine MPI_Group_free(group, ierror)
        use mpi_c_bindings, only: c_mpi_group_free
        integer, intent(inout) :: group
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_group
        integer(c_int) :: local_ierr
        c_group = group_f2c(group)
        local_ierr = c_mpi_group_free(c_group)
        group = group_c2f(c_group)
        call set_ierror(local_ierr, "MPI_Group_free", ierror)
    end subroutine MPI_Group_free

    subroutine MPI_Group_range_incl(group, n, ranks, newgroup, ierror)
        use mpi_c_bindings, only: c_mpi_group_range_incl
        integer, intent(in) :: group
        integer, intent(in) :: n
        integer, dimension(:,:), intent(in) :: ranks
        integer, intent(out) :: newgroup
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_newgroup
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_group_range_incl(group_f2c(group), n, ranks, c_newgroup)
        newgroup = group_c2f(c_newgroup)
        call set_ierror(local_ierr, "MPI_Group_range_incl", ierror)
    end subroutine MPI_Group_range_incl

    subroutine MPI_Comm_create(comm, group, newcomm, ierror)
        use mpi_c_bindings, only: c_mpi_comm_create
        integer, intent(in) :: comm
        integer, intent(in) :: group
        integer, intent(out) :: newcomm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_newcomm
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_comm_create(comm_f2c(comm), group_f2c(group), c_newcomm)
        newcomm = comm_c2f(c_newcomm)
        call set_ierror(local_ierr, "MPI_Comm_create", ierror)
    end subroutine MPI_Comm_create

    subroutine MPI_Comm_dup(comm, newcomm, ierror)
        use mpi_c_bindings, only: c_mpi_comm_dup
        integer, intent(in) :: comm
        integer, intent(out) :: newcomm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_newcomm
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_comm_dup(comm_f2c(comm), c_newcomm)
        newcomm = comm_c2f(c_newcomm)
        call set_ierror(local_ierr, "MPI_Comm_dup", ierror)
    end subroutine MPI_Comm_dup

    subroutine MPI_Comm_free(comm, ierror)
        use mpi_c_bindings, only: c_mpi_comm_free
        integer, intent(inout) :: comm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_comm
        integer(c_int) :: local_ierr
        c_comm = comm_f2c(comm)
        local_ierr = c_mpi_comm_free(c_comm)
        comm = comm_c2f(c_comm)
        call set_ierror(local_ierr, "MPI_Comm_free", ierror)
    end subroutine MPI_Comm_free

    subroutine MPI_Comm_split(comm, color, key, newcomm, ierror)
        use mpi_c_bindings, only: c_mpi_comm_split
        integer, intent(in) :: comm, color, key
        integer, intent(out) :: newcomm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_newcomm
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_comm_split(comm_f2c(comm), color_f2c(color), key, c_newcomm)
        newcomm = comm_c2f(c_newcomm)
        call set_ierror(local_ierr, "MPI_Comm_split", ierror)
    end subroutine MPI_Comm_split

    subroutine MPI_Comm_split_type(comm, split_type, key, info, newcomm, ierror)
        use mpi_c_bindings, only: c_mpi_comm_split_type
        integer, intent(in) :: comm
        integer, intent(in) :: split_type, key
        integer, intent(in) :: info
        integer, intent(out) :: newcomm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_newcomm
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_comm_split_type(comm_f2c(comm), split_type_f2c(split_type), key, &
            info_f2c(info), c_newcomm)
        newcomm = comm_c2f(c_newcomm)
        call set_ierror(local_ierr, "MPI_Comm_split_type", ierror)
    end subroutine MPI_Comm_split_type

    subroutine MPI_Comm_get_name(comm, comm_name, resultlen, ierror)
        use mpi_c_bindings, only: c_mpi_comm_get_name
        integer, intent(in) :: comm
        character(len=*), intent(out) :: comm_name
        integer, intent(out) :: resultlen
        integer, optional, intent(out) :: ierror
        character(kind=c_char) :: c_name(MPI_MAX_OBJECT_NAME)
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_comm_get_name(comm_f2c(comm), c_name, resultlen)
        call c_string_to_fortran(c_name, resultlen, comm_name)
        call set_ierror(local_ierr, "MPI_Comm_get_name", ierror)
    end subroutine MPI_Comm_get_name

    subroutine MPI_Type_get_name(datatype, type_name, resultlen, ierror)
        use mpi_c_bindings, only: c_mpi_type_get_name
        integer, intent(in) :: datatype
        character(len=*), intent(out) :: type_name
        integer, intent(out) :: resultlen
        integer, optional, intent(out) :: ierror
        character(kind=c_char) :: c_name(MPI_MAX_OBJECT_NAME)
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_type_get_name(datatype_f2c(datatype), c_name, resultlen)
        call c_string_to_fortran(c_name, resultlen, type_name)
        call set_ierror(local_ierr, "MPI_Type_get_name", ierror)
    end subroutine MPI_Type_get_name

    ! Topologies

    subroutine MPI_Cart_create(comm_old, ndims, dims, periods, reorder, comm_cart, ierror)
        use mpi_c_bindings, only: c_mpi_cart_create
        integer, intent(in) :: ndims, dims(ndims)
        logical, intent(in) :: periods(ndims), reorder
        integer, intent(in) :: comm_old
        integer, intent(out) :: comm_cart
        integer, optional, intent(out) :: ierror
        integer(c_int) :: reorder_c, periods_c(ndims), local_ierr
        integer(kind=MPI_HANDLE_KIND) :: c_comm_cart
        reorder_c = merge(1, 0, reorder)
        periods_c = merge(1, 0, periods)
        local_ierr = c_mpi_cart_create(comm_f2c(comm_old), ndims, dims, periods_c, reorder_c, &
            c_comm_cart)
        comm_cart = comm_c2f(c_comm_cart)
        call set_ierror(local_ierr, "MPI_Cart_create", ierror)
    end subroutine MPI_Cart_create

    subroutine MPI_Cart_coords(comm, rank, maxdims, coords, ierror)
        use mpi_c_bindings, only: c_mpi_cart_coords
        integer, intent(in) :: comm
        integer, intent(in) :: rank, maxdims
        integer, intent(out) :: coords(maxdims)
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_cart_coords(comm_f2c(comm), rank, maxdims, coords), &
            "MPI_Cart_coords", ierror)
    end subroutine MPI_Cart_coords

    subroutine MPI_Cart_shift(comm, direction, disp, rank_source, rank_dest, ierror)
        use mpi_c_bindings, only: c_mpi_cart_shift
        integer, intent(in) :: comm
        integer, intent(in) :: direction, disp
        integer, intent(out) :: rank_source, rank_dest
        integer, optional, intent(out) :: ierror
        integer(c_int) :: c_rank_source, c_rank_dest, local_ierr
        local_ierr = c_mpi_cart_shift(comm_f2c(comm), direction, disp, c_rank_source, c_rank_dest)
        rank_source = rank_c2f(c_rank_source)
        rank_dest = rank_c2f(c_rank_dest)
        call set_ierror(local_ierr, "MPI_Cart_shift", ierror)
    end subroutine MPI_Cart_shift

    subroutine MPI_Dims_create(nnodes, ndims, dims, ierror)
        use mpi_c_bindings, only: c_mpi_dims_create
        integer, intent(in) :: nnodes, ndims
        integer, intent(inout) :: dims(ndims)
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_dims_create(nnodes, ndims, dims), "MPI_Dims_create", ierror)
    end subroutine MPI_Dims_create

    subroutine MPI_Cart_sub(comm, remain_dims, newcomm, ierror)
        use mpi_c_bindings, only: c_mpi_cart_sub
        integer, intent(in) :: comm
        logical, intent(in) :: remain_dims(:)
        integer, intent(out) :: newcomm
        integer, optional, intent(out) :: ierror
        integer(c_int), target :: remain_dims_c(size(remain_dims))
        integer(kind=MPI_HANDLE_KIND) :: c_newcomm
        integer(c_int) :: local_ierr
        remain_dims_c = merge(1, 0, remain_dims)
        local_ierr = c_mpi_cart_sub(comm_f2c(comm), c_loc(remain_dims_c), c_newcomm)
        newcomm = comm_c2f(c_newcomm)
        call set_ierror(local_ierr, "MPI_Cart_sub", ierror)
    end subroutine MPI_Cart_sub

    ! Synchronization and completion

    subroutine MPI_Barrier(comm, ierror)
        use mpi_c_bindings, only: c_mpi_barrier
        integer, intent(in) :: comm
        integer, intent(out), optional :: ierror
        call set_ierror(c_mpi_barrier(comm_f2c(comm)), "MPI_Barrier", ierror)
    end subroutine MPI_Barrier

    subroutine MPI_Wait(request, status, ierror)
        use mpi_c_bindings, only: c_mpi_wait, c_mpi_status_ignore
        integer, intent(inout) :: request
        integer, target, intent(out) :: status(MPI_STATUS_SIZE)
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_request
        type(c_ptr) :: c_status
        integer(c_int) :: local_ierr
        c_request = request_f2c(request)
        if (is_status_ignore(status)) then
            local_ierr = c_mpi_wait(c_request, c_mpi_status_ignore)
        else
            if (.not. allocate_statuses(1, c_status, "MPI_Wait", ierror)) return
            local_ierr = c_mpi_wait(c_request, c_status)
            if (local_ierr == MPI_SUCCESS) call status_c2f(c_status, status, local_ierr)
            call release_statuses(c_status)
        end if
        request = request_c2f(c_request)
        call set_ierror(local_ierr, "MPI_Wait", ierror)
    end subroutine MPI_Wait

    subroutine MPI_Waitall(count, array_of_requests, array_of_statuses, ierror)
        use mpi_c_bindings, only: c_mpi_waitall, c_mpi_statuses_ignore
        integer, intent(in) :: count
        integer, dimension(count), intent(inout) :: array_of_requests
        integer, target, intent(out) :: array_of_statuses(MPI_STATUS_SIZE, *)
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_requests(count)
        type(c_ptr) :: c_statuses
        integer(c_int) :: local_ierr
        integer :: i
        do i = 1, count
            c_requests(i) = request_f2c(array_of_requests(i))
        end do
        if (is_statuses_ignore(array_of_statuses) .or. count <= 0) then
            local_ierr = c_mpi_waitall(count, c_requests, c_mpi_statuses_ignore)
        else
            if (.not. allocate_statuses(count, c_statuses, "MPI_Waitall", ierror)) return
            local_ierr = c_mpi_waitall(count, c_requests, c_statuses)
            if (local_ierr == MPI_SUCCESS) then
                do i = 1, count
                    call status_c2f(status_at(c_statuses, i), array_of_statuses(:, i), local_ierr)
                end do
            end if
            call release_statuses(c_statuses)
        end if
        do i = 1, count
            array_of_requests(i) = request_c2f(c_requests(i))
        end do
        call set_ierror(local_ierr, "MPI_Waitall", ierror)
    end subroutine MPI_Waitall

    subroutine MPI_Test(request, flag, status, ierror)
        use mpi_c_bindings, only: c_mpi_test, c_mpi_status_ignore
        integer, intent(inout) :: request
        logical, intent(out) :: flag
        integer, target, intent(out) :: status(MPI_STATUS_SIZE)
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_request
        type(c_ptr) :: c_status
        integer(c_int) :: c_flag, local_ierr
        c_request = request_f2c(request)
        if (is_status_ignore(status)) then
            local_ierr = c_mpi_test(c_request, c_flag, c_mpi_status_ignore)
        else
            if (.not. allocate_statuses(1, c_status, "MPI_Test", ierror)) return
            local_ierr = c_mpi_test(c_request, c_flag, c_status)
            if (local_ierr == MPI_SUCCESS .and. c_flag /= 0) call status_c2f(c_status, status, local_ierr)
            call release_statuses(c_status)
        end if
        flag = (c_flag /= 0)
        request = request_c2f(c_request)
        call set_ierror(local_ierr, "MPI_Test", ierror)
    end subroutine MPI_Test

    subroutine MPI_Testall(count, array_of_requests, flag, array_of_statuses, ierror)
        use mpi_c_bindings, only: c_mpi_testall, c_mpi_statuses_ignore
        integer, intent(in) :: count
        integer, dimension(count), intent(inout) :: array_of_requests
        logical, intent(out) :: flag
        integer, target, intent(out) :: array_of_statuses(MPI_STATUS_SIZE, *)
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_requests(count)
        type(c_ptr) :: c_statuses
        integer(c_int) :: c_flag, local_ierr
        integer :: i
        do i = 1, count
            c_requests(i) = request_f2c(array_of_requests(i))
        end do
        if (is_statuses_ignore(array_of_statuses) .or. count <= 0) then
            local_ierr = c_mpi_testall(count, c_requests, c_flag, c_mpi_statuses_ignore)
        else
            if (.not. allocate_statuses(count, c_statuses, "MPI_Testall", ierror)) return
            local_ierr = c_mpi_testall(count, c_requests, c_flag, c_statuses)
            if (local_ierr == MPI_SUCCESS .and. c_flag /= 0) then
                do i = 1, count
                    call status_c2f(status_at(c_statuses, i), array_of_statuses(:, i), local_ierr)
                end do
            end if
            call release_statuses(c_statuses)
        end if
        flag = (c_flag /= 0)
        do i = 1, count
            array_of_requests(i) = request_c2f(c_requests(i))
        end do
        call set_ierror(local_ierr, "MPI_Testall", ierror)
    end subroutine MPI_Testall

    subroutine MPI_Waitany(count, array_of_requests, index, status, ierror)
        use mpi_c_bindings, only: c_mpi_waitany, c_mpi_status_ignore
        integer, intent(in) :: count
        integer, dimension(count), intent(inout) :: array_of_requests
        integer, intent(out) :: index
        integer, target, intent(out) :: status(MPI_STATUS_SIZE)
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_requests(count)
        type(c_ptr) :: c_status
        integer(c_int) :: c_index, local_ierr
        integer :: i
        do i = 1, count
            c_requests(i) = request_f2c(array_of_requests(i))
        end do
        if (is_status_ignore(status)) then
            local_ierr = c_mpi_waitany(count, c_requests, c_index, c_mpi_status_ignore)
        else
            if (.not. allocate_statuses(1, c_status, "MPI_Waitany", ierror)) return
            local_ierr = c_mpi_waitany(count, c_requests, c_index, c_status)
            if (local_ierr == MPI_SUCCESS) call status_c2f(c_status, status, local_ierr)
            call release_statuses(c_status)
        end if
        index = index_c2f(c_index)
        do i = 1, count
            array_of_requests(i) = request_c2f(c_requests(i))
        end do
        call set_ierror(local_ierr, "MPI_Waitany", ierror)
    end subroutine MPI_Waitany

    ! Point-to-point

    subroutine MPI_Send(buf, count, datatype, dest, tag, comm, ierror)
        use mpi_c_bindings, only: c_mpi_send
        type(*), dimension(..), contiguous, target, intent(in) :: buf
        integer, intent(in) :: count, datatype, dest, tag, comm
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_send(c_loc(buf), count, datatype_f2c(datatype), rank_f2c(dest), &
            tag_f2c(tag), comm_f2c(comm)), "MPI_Send", ierror)
    end subroutine MPI_Send

    subroutine MPI_Ssend(buf, count, datatype, dest, tag, comm, ierror)
        use mpi_c_bindings, only: c_mpi_ssend
        type(*), dimension(..), contiguous, target, intent(in) :: buf
        integer, intent(in) :: count, datatype, dest, tag, comm
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_ssend(c_loc(buf), count, datatype_f2c(datatype), rank_f2c(dest), &
            tag_f2c(tag), comm_f2c(comm)), "MPI_Ssend", ierror)
    end subroutine MPI_Ssend

    subroutine MPI_Recv(buf, count, datatype, source, tag, comm, status, ierror)
        use mpi_c_bindings, only: c_mpi_recv, c_mpi_status_ignore
        type(*), dimension(..), contiguous, target, intent(inout) :: buf
        integer, intent(in) :: count, datatype, source, tag, comm
        integer, target, intent(out) :: status(MPI_STATUS_SIZE)
        integer, optional, intent(out) :: ierror
        type(c_ptr) :: c_status
        integer(c_int) :: local_ierr
        if (is_status_ignore(status)) then
            local_ierr = c_mpi_recv(c_loc(buf), count, datatype_f2c(datatype), rank_f2c(source), &
                tag_f2c(tag), comm_f2c(comm), c_mpi_status_ignore)
        else
            if (.not. allocate_statuses(1, c_status, "MPI_Recv", ierror)) return
            local_ierr = c_mpi_recv(c_loc(buf), count, datatype_f2c(datatype), rank_f2c(source), &
                tag_f2c(tag), comm_f2c(comm), c_status)
            if (local_ierr == MPI_SUCCESS) call status_c2f(c_status, status, local_ierr)
            call release_statuses(c_status)
        end if
        call set_ierror(local_ierr, "MPI_Recv", ierror)
    end subroutine MPI_Recv

    subroutine MPI_Isend(buf, count, datatype, dest, tag, comm, request, ierror)
        use mpi_c_bindings, only: c_mpi_isend
        type(*), dimension(..), target, asynchronous, intent(in) :: buf
        integer, intent(in) :: count, datatype, dest, tag, comm
        integer, intent(out) :: request
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_request
        integer(c_int) :: local_ierr
        if (.not. is_contiguous(buf)) then
            error stop "MPI_Isend: the buffer of a nonblocking call must be contiguous"
        end if
        local_ierr = c_mpi_isend(c_loc(buf), count, datatype_f2c(datatype), rank_f2c(dest), &
            tag_f2c(tag), comm_f2c(comm), c_request)
        request = request_c2f(c_request)
        call set_ierror(local_ierr, "MPI_Isend", ierror)
    end subroutine MPI_Isend

    subroutine MPI_Irecv(buf, count, datatype, source, tag, comm, request, ierror)
        use mpi_c_bindings, only: c_mpi_irecv
        type(*), dimension(..), target, asynchronous, intent(inout) :: buf
        integer, intent(in) :: count, datatype, source, tag, comm
        integer, intent(out) :: request
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_request
        integer(c_int) :: local_ierr
        if (.not. is_contiguous(buf)) then
            error stop "MPI_Irecv: the buffer of a nonblocking call must be contiguous"
        end if
        local_ierr = c_mpi_irecv(c_loc(buf), count, datatype_f2c(datatype), rank_f2c(source), &
            tag_f2c(tag), comm_f2c(comm), c_request)
        request = request_c2f(c_request)
        call set_ierror(local_ierr, "MPI_Irecv", ierror)
    end subroutine MPI_Irecv

    subroutine MPI_Sendrecv(sendbuf, sendcount, sendtype, dest, sendtag, &
            recvbuf, recvcount, recvtype, source, recvtag, comm, status, ierror)
        use mpi_c_bindings, only: c_mpi_sendrecv, c_mpi_status_ignore
        type(*), dimension(..), contiguous, target, intent(in) :: sendbuf
        type(*), dimension(..), contiguous, target, intent(inout) :: recvbuf
        integer, intent(in) :: sendcount, sendtype, dest, sendtag
        integer, intent(in) :: recvcount, recvtype, source, recvtag, comm
        integer, target, intent(out) :: status(MPI_STATUS_SIZE)
        integer, optional, intent(out) :: ierror
        type(c_ptr) :: c_status_ptr
        integer(c_int) :: local_ierr
        logical :: ignore
        ignore = is_status_ignore(status)
        if (ignore) then
            c_status_ptr = c_mpi_status_ignore
        else
            if (.not. allocate_statuses(1, c_status_ptr, "MPI_Sendrecv", ierror)) return
        end if
        local_ierr = c_mpi_sendrecv(c_loc(sendbuf), sendcount, datatype_f2c(sendtype), &
            rank_f2c(dest), tag_f2c(sendtag), c_loc(recvbuf), recvcount, datatype_f2c(recvtype), &
            rank_f2c(source), tag_f2c(recvtag), comm_f2c(comm), c_status_ptr)
        if (.not. ignore) then
            if (local_ierr == MPI_SUCCESS) call status_c2f(c_status_ptr, status, local_ierr)
            call release_statuses(c_status_ptr)
        end if
        call set_ierror(local_ierr, "MPI_Sendrecv", ierror)
    end subroutine MPI_Sendrecv

    subroutine MPI_Probe(source, tag, comm, status, ierror)
        use mpi_c_bindings, only: c_mpi_probe, c_mpi_status_ignore
        integer, intent(in) :: source, tag, comm
        integer, target, intent(out) :: status(MPI_STATUS_SIZE)
        integer, optional, intent(out) :: ierror
        type(c_ptr) :: c_status
        integer(c_int) :: local_ierr
        if (is_status_ignore(status)) then
            local_ierr = c_mpi_probe(rank_f2c(source), tag_f2c(tag), comm_f2c(comm), &
                c_mpi_status_ignore)
        else
            if (.not. allocate_statuses(1, c_status, "MPI_Probe", ierror)) return
            local_ierr = c_mpi_probe(rank_f2c(source), tag_f2c(tag), comm_f2c(comm), &
                c_status)
            if (local_ierr == MPI_SUCCESS) call status_c2f(c_status, status, local_ierr)
            call release_statuses(c_status)
        end if
        call set_ierror(local_ierr, "MPI_Probe", ierror)
    end subroutine MPI_Probe

    subroutine MPI_Iprobe(source, tag, comm, flag, status, ierror)
        use mpi_c_bindings, only: c_mpi_iprobe, c_mpi_status_ignore
        integer, intent(in) :: source, tag, comm
        logical, intent(out) :: flag
        integer, target, intent(out) :: status(MPI_STATUS_SIZE)
        integer, optional, intent(out) :: ierror
        type(c_ptr) :: c_status
        integer(c_int) :: c_flag, local_ierr
        if (is_status_ignore(status)) then
            local_ierr = c_mpi_iprobe(rank_f2c(source), tag_f2c(tag), comm_f2c(comm), c_flag, &
                c_mpi_status_ignore)
        else
            if (.not. allocate_statuses(1, c_status, "MPI_Iprobe", ierror)) return
            local_ierr = c_mpi_iprobe(rank_f2c(source), tag_f2c(tag), comm_f2c(comm), c_flag, &
                c_status)
            if (local_ierr == MPI_SUCCESS .and. c_flag /= 0) call status_c2f(c_status, status, local_ierr)
            call release_statuses(c_status)
        end if
        flag = (c_flag /= 0)
        call set_ierror(local_ierr, "MPI_Iprobe", ierror)
    end subroutine MPI_Iprobe

    subroutine MPI_Get_count(status, datatype, count, ierror)
        use mpi_c_bindings, only: c_mpi_get_count
        integer, intent(in) :: status(MPI_STATUS_SIZE)
        integer, intent(in) :: datatype
        integer, intent(out) :: count
        integer, optional, intent(out) :: ierror
        type(c_ptr) :: c_status
        integer(c_int) :: c_count, local_ierr
        if (.not. allocate_statuses(1, c_status, "MPI_Get_count", ierror)) return
        call status_f2c(status, c_status, local_ierr)
        if (local_ierr == MPI_SUCCESS) then
            local_ierr = c_mpi_get_count(c_status, datatype_f2c(datatype), c_count)
            if (local_ierr == MPI_SUCCESS) count = count_c2f(c_count)
        end if
        call release_statuses(c_status)
        call set_ierror(local_ierr, "MPI_Get_count", ierror)
    end subroutine MPI_Get_count

    ! Collectives

    subroutine MPI_Bcast(buffer, count, datatype, root, comm, ierror)
        use mpi_c_bindings, only: c_mpi_bcast
        type(*), dimension(..), contiguous, target, intent(inout) :: buffer
        integer, intent(in) :: count, datatype, root, comm
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_bcast(c_loc(buffer), count, datatype_f2c(datatype), rank_f2c(root), &
            comm_f2c(comm)), "MPI_Bcast", ierror)
    end subroutine MPI_Bcast

    subroutine MPI_Reduce(sendbuf, recvbuf, count, datatype, op, root, comm, ierror)
        use mpi_c_bindings, only: c_mpi_reduce
        type(*), dimension(..), contiguous, target, intent(in) :: sendbuf
        type(*), dimension(..), contiguous, target, intent(inout) :: recvbuf
        integer, intent(in) :: count, datatype, op, root, comm
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_reduce(in_place_or(c_loc(sendbuf)), c_loc(recvbuf), count, &
            datatype_f2c(datatype), op_f2c(op), rank_f2c(root), comm_f2c(comm)), "MPI_Reduce", &
            ierror)
    end subroutine MPI_Reduce

    subroutine MPI_Allreduce(sendbuf, recvbuf, count, datatype, op, comm, ierror)
        use mpi_c_bindings, only: c_mpi_allreduce
        type(*), dimension(..), contiguous, target, intent(in) :: sendbuf
        type(*), dimension(..), contiguous, target, intent(inout) :: recvbuf
        integer, intent(in) :: count, datatype, op, comm
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_allreduce(in_place_or(c_loc(sendbuf)), c_loc(recvbuf), count, &
            datatype_f2c(datatype), op_f2c(op), comm_f2c(comm)), "MPI_Allreduce", ierror)
    end subroutine MPI_Allreduce

    subroutine MPI_Exscan(sendbuf, recvbuf, count, datatype, op, comm, ierror)
        use mpi_c_bindings, only: c_mpi_exscan
        type(*), dimension(..), contiguous, target, intent(in) :: sendbuf
        type(*), dimension(..), contiguous, target, intent(inout) :: recvbuf
        integer, intent(in) :: count, datatype, op, comm
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_exscan(in_place_or(c_loc(sendbuf)), c_loc(recvbuf), count, &
            datatype_f2c(datatype), op_f2c(op), comm_f2c(comm)), "MPI_Exscan", ierror)
    end subroutine MPI_Exscan

    subroutine MPI_Allgather(sendbuf, sendcount, sendtype, recvbuf, recvcount, recvtype, &
            comm, ierror)
        use mpi_c_bindings, only: c_mpi_allgather
        type(*), dimension(..), contiguous, target, intent(in) :: sendbuf
        type(*), dimension(..), contiguous, target, intent(inout) :: recvbuf
        integer, intent(in) :: sendcount, sendtype, recvcount, recvtype, comm
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_allgather(in_place_or(c_loc(sendbuf)), sendcount, &
            datatype_f2c(sendtype), c_loc(recvbuf), recvcount, datatype_f2c(recvtype), &
            comm_f2c(comm)), "MPI_Allgather", ierror)
    end subroutine MPI_Allgather

    subroutine MPI_Gatherv(sendbuf, sendcount, sendtype, recvbuf, recvcounts, displs, &
            recvtype, root, comm, ierror)
        use mpi_c_bindings, only: c_mpi_gatherv
        type(*), dimension(..), contiguous, target, intent(in) :: sendbuf
        type(*), dimension(..), contiguous, target, intent(inout) :: recvbuf
        integer, intent(in) :: sendcount, sendtype, recvtype, root, comm
        integer, intent(in) :: recvcounts(:), displs(:)
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_gatherv(in_place_or(c_loc(sendbuf)), sendcount, &
            datatype_f2c(sendtype), c_loc(recvbuf), recvcounts, displs, datatype_f2c(recvtype), &
            rank_f2c(root), comm_f2c(comm)), "MPI_Gatherv", ierror)
    end subroutine MPI_Gatherv

    subroutine MPI_Allgatherv(sendbuf, sendcount, sendtype, recvbuf, recvcounts, displs, &
            recvtype, comm, ierror)
        use mpi_c_bindings, only: c_mpi_allgatherv
        type(*), dimension(..), contiguous, target, intent(in) :: sendbuf
        type(*), dimension(..), contiguous, target, intent(inout) :: recvbuf
        integer, intent(in) :: sendcount, sendtype, recvtype, comm
        integer, intent(in) :: recvcounts(:), displs(:)
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_allgatherv(in_place_or(c_loc(sendbuf)), sendcount, &
            datatype_f2c(sendtype), c_loc(recvbuf), recvcounts, displs, datatype_f2c(recvtype), &
            comm_f2c(comm)), "MPI_Allgatherv", ierror)
    end subroutine MPI_Allgatherv

    subroutine MPI_Scatter(sendbuf, sendcount, sendtype, recvbuf, recvcount, recvtype, &
            root, comm, ierror)
        use mpi_c_bindings, only: c_mpi_scatter
        type(*), dimension(..), contiguous, target, intent(in) :: sendbuf
        type(*), dimension(..), contiguous, target, intent(inout) :: recvbuf
        integer, intent(in) :: sendcount, sendtype, recvcount, recvtype, root, comm
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_scatter(c_loc(sendbuf), sendcount, datatype_f2c(sendtype), &
            in_place_or(c_loc(recvbuf)), recvcount, datatype_f2c(recvtype), rank_f2c(root), &
                comm_f2c(comm)), &
            "MPI_Scatter", ierror)
    end subroutine MPI_Scatter

    subroutine MPI_Gather(sendbuf, sendcount, sendtype, recvbuf, recvcount, recvtype, &
            root, comm, ierror)
        use mpi_c_bindings, only: c_mpi_gather
        type(*), dimension(..), contiguous, target, intent(in) :: sendbuf
        type(*), dimension(..), contiguous, target, intent(inout) :: recvbuf
        integer, intent(in) :: sendcount, sendtype, recvcount, recvtype, root, comm
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_gather(in_place_or(c_loc(sendbuf)), sendcount, &
            datatype_f2c(sendtype), c_loc(recvbuf), recvcount, datatype_f2c(recvtype), &
            rank_f2c(root), comm_f2c(comm)), "MPI_Gather", ierror)
    end subroutine MPI_Gather

    subroutine MPI_Scatterv(sendbuf, sendcounts, displs, sendtype, recvbuf, recvcount, &
            recvtype, root, comm, ierror)
        use mpi_c_bindings, only: c_mpi_scatterv
        type(*), dimension(..), contiguous, target, intent(in) :: sendbuf
        type(*), dimension(..), contiguous, target, intent(inout) :: recvbuf
        integer, intent(in) :: sendcounts(*), displs(*)
        integer, intent(in) :: sendtype, recvcount, recvtype, root, comm
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_scatterv(c_loc(sendbuf), sendcounts, displs, &
            datatype_f2c(sendtype), in_place_or(c_loc(recvbuf)), recvcount, &
            datatype_f2c(recvtype), rank_f2c(root), comm_f2c(comm)), "MPI_Scatterv", ierror)
    end subroutine MPI_Scatterv

    subroutine MPI_Alltoall(sendbuf, sendcount, sendtype, recvbuf, recvcount, recvtype, &
            comm, ierror)
        use mpi_c_bindings, only: c_mpi_alltoall
        type(*), dimension(..), contiguous, target, intent(in) :: sendbuf
        type(*), dimension(..), contiguous, target, intent(inout) :: recvbuf
        integer, intent(in) :: sendcount, sendtype, recvcount, recvtype, comm
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_alltoall(in_place_or(c_loc(sendbuf)), sendcount, &
            datatype_f2c(sendtype), c_loc(recvbuf), recvcount, datatype_f2c(recvtype), &
            comm_f2c(comm)), "MPI_Alltoall", ierror)
    end subroutine MPI_Alltoall

    subroutine MPI_Alltoallv(sendbuf, sendcounts, sdispls, sendtype, recvbuf, recvcounts, &
            rdispls, recvtype, comm, ierror)
        use mpi_c_bindings, only: c_mpi_alltoallv
        type(*), dimension(..), contiguous, target, intent(in) :: sendbuf
        type(*), dimension(..), contiguous, target, intent(inout) :: recvbuf
        integer, intent(in) :: sendcounts(*), sdispls(*), recvcounts(*), rdispls(*)
        integer, intent(in) :: sendtype, recvtype, comm
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_alltoallv(in_place_or(c_loc(sendbuf)), sendcounts, sdispls, &
            datatype_f2c(sendtype), c_loc(recvbuf), recvcounts, rdispls, &
            datatype_f2c(recvtype), comm_f2c(comm)), "MPI_Alltoallv", ierror)
    end subroutine MPI_Alltoallv

    subroutine MPI_Scan(sendbuf, recvbuf, count, datatype, op, comm, ierror)
        use mpi_c_bindings, only: c_mpi_scan
        type(*), dimension(..), contiguous, target, intent(in) :: sendbuf
        type(*), dimension(..), contiguous, target, intent(inout) :: recvbuf
        integer, intent(in) :: count, datatype, op, comm
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_scan(in_place_or(c_loc(sendbuf)), c_loc(recvbuf), count, &
            datatype_f2c(datatype), op_f2c(op), comm_f2c(comm)), "MPI_Scan", ierror)
    end subroutine MPI_Scan

    subroutine MPI_Reduce_scatter_block(sendbuf, recvbuf, recvcount, datatype, op, comm, &
            ierror)
        use mpi_c_bindings, only: c_mpi_reduce_scatter_block
        type(*), dimension(..), contiguous, target, intent(in) :: sendbuf
        type(*), dimension(..), contiguous, target, intent(inout) :: recvbuf
        integer, intent(in) :: recvcount, datatype, op, comm
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_reduce_scatter_block(in_place_or(c_loc(sendbuf)), c_loc(recvbuf), &
            recvcount, datatype_f2c(datatype), op_f2c(op), comm_f2c(comm)), &
            "MPI_Reduce_scatter_block", ierror)
    end subroutine MPI_Reduce_scatter_block

    ! Derived datatypes

    subroutine MPI_Type_contiguous(count, oldtype, newtype, ierror)
        use mpi_c_bindings, only: c_mpi_type_contiguous
        integer, intent(in) :: count, oldtype
        integer, intent(out) :: newtype
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_newtype
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_type_contiguous(count, datatype_f2c(oldtype), c_newtype)
        newtype = datatype_c2f(c_newtype)
        call set_ierror(local_ierr, "MPI_Type_contiguous", ierror)
    end subroutine MPI_Type_contiguous

    subroutine MPI_Type_vector(count, blocklength, stride, oldtype, newtype, ierror)
        use mpi_c_bindings, only: c_mpi_type_vector
        integer, intent(in) :: count, blocklength, stride, oldtype
        integer, intent(out) :: newtype
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_newtype
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_type_vector(count, blocklength, stride, datatype_f2c(oldtype), &
            c_newtype)
        newtype = datatype_c2f(c_newtype)
        call set_ierror(local_ierr, "MPI_Type_vector", ierror)
    end subroutine MPI_Type_vector

    subroutine MPI_Type_commit(datatype, ierror)
        use mpi_c_bindings, only: c_mpi_type_commit
        integer, intent(inout) :: datatype
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_datatype
        integer(c_int) :: local_ierr
        c_datatype = datatype_f2c(datatype)
        local_ierr = c_mpi_type_commit(c_datatype)
        datatype = datatype_c2f(c_datatype)
        call set_ierror(local_ierr, "MPI_Type_commit", ierror)
    end subroutine MPI_Type_commit

    subroutine MPI_Type_free(datatype, ierror)
        use mpi_c_bindings, only: c_mpi_type_free
        integer, intent(inout) :: datatype
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_datatype
        integer(c_int) :: local_ierr
        c_datatype = datatype_f2c(datatype)
        local_ierr = c_mpi_type_free(c_datatype)
        datatype = datatype_c2f(c_datatype)
        call set_ierror(local_ierr, "MPI_Type_free", ierror)
    end subroutine MPI_Type_free

    ! Errors

    subroutine MPI_Comm_set_errhandler(comm, errhandler, ierror)
        use mpi_c_bindings, only: c_mpi_comm_set_errhandler
        integer, intent(in) :: comm, errhandler
        integer, optional, intent(out) :: ierror
        call set_ierror(c_mpi_comm_set_errhandler(comm_f2c(comm), errhandler_f2c(errhandler)), &
            "MPI_Comm_set_errhandler", ierror)
    end subroutine MPI_Comm_set_errhandler

    subroutine MPI_Error_class(errorcode, errorclass, ierror)
        ! Error codes are native; their classes are translated.
        use mpi_c_bindings, only: c_mpi_error_class
        integer, intent(in) :: errorcode
        integer, intent(out) :: errorclass
        integer, optional, intent(out) :: ierror
        integer(c_int) :: c_class, local_ierr
        local_ierr = c_mpi_error_class(errorcode, c_class)
        errorclass = error_class_c2f(c_class)
        call set_ierror(local_ierr, "MPI_Error_class", ierror)
    end subroutine MPI_Error_class

    subroutine MPI_Error_string(errorcode, string, resultlen, ierror)
        use mpi_c_bindings, only: c_mpi_error_string
        integer, intent(in) :: errorcode
        character(len=*), intent(out) :: string
        integer, intent(out) :: resultlen
        integer, optional, intent(out) :: ierror
        character(kind=c_char) :: c_string(MPI_MAX_ERROR_STRING)
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_error_string(errorcode, c_string, resultlen)
        call c_string_to_fortran(c_string, resultlen, string)
        call set_ierror(local_ierr, "MPI_Error_string", ierror)
    end subroutine MPI_Error_string

    ! The native MPI_IN_PLACE if p is the address of MPI_IN_PLACE, else p.
    function in_place_or(p) result(r)
        use mpi_c_bindings, only: c_mpi_in_place
        type(c_ptr), intent(in) :: p
        type(c_ptr) :: r
        type(c_ptr) :: in_place
        in_place = c_loc(MPI_IN_PLACE)
        if (c_associated(p, in_place)) then
            r = c_mpi_in_place
        else
            r = p
        end if
    end function in_place_or

end module mpi
