module mpi
    use mpi_native_constants
    use mpi_c_bindings, only: MPI_HANDLE_KIND
    use iso_c_binding, only: c_int, c_char, c_ptr, c_loc, c_null_ptr, c_associated
    implicit none

    ! Handles and statuses are binding-owned. Error codes/classes belong to
    ! the selected C MPI; other scalars are normalized at the C boundary.

    integer, parameter :: MPI_INTEGER_KIND = kind(0)

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

    integer, private, parameter :: comm_family = 1, group_family = 2, request_family = 3, &
        type_family = 4, op_family = 5, info_family = 6, errhandler_family = 7
    private :: check_native_mpi, initialize_binding, valid_handles, valid_reduction
    private :: handle_f2c, reserve_handle, save_handle, update_handle, null_handle
    private :: allocate_statuses, release_statuses, status_at
    private :: op_f2c, comm_f2c, group_f2c, info_f2c
    private :: request_f2c, datatype_f2c
    private :: rank_f2c, rank_c2f, tag_f2c, tag_c2f, thread_level_f2c, thread_level_c2f
    private :: split_type_f2c, color_f2c, count_c2f, index_c2f, comparison_c2f
    private :: status_c2f, status_f2c, c_string_to_fortran, set_ierror
    private :: errhandler_f2c, is_status_ignore, is_statuses_ignore
    private :: in_place_or
    private :: c_int, c_char, c_ptr, c_loc, c_null_ptr, c_associated

    contains

    subroutine check_native_mpi()
        ! Checks that this library was compiled for the MPI library it is
        ! linked with. Called before MPI is initialized.
        use mpi_c_bindings, only: c_sizeof_mpi_comm, c_sizeof_int, &
            c_mpi_max_object_name, c_mpi_max_error_string, c_mpi_max_processor_name
        if (c_sizeof_mpi_comm /= MPI_HANDLE_KIND) then
            print *, "fortran_mpi: compiled with MPI_HANDLE_KIND =", MPI_HANDLE_KIND, &
                "but the MPI library's handles have", c_sizeof_mpi_comm, "bytes."
            print *, "Compile src/mpi_c_bindings.f90 with -DOPEN_MPI for Open MPI,", &
                " or with -DMPI_ABI for the MPI-5 ABI (libmpi_abi)."
            error stop 1
        end if
        if (kind(0) /= c_int .or. storage_size(0)/8 /= c_sizeof_int) then
            print *, "fortran_mpi: default INTEGER and C int must match."
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

    subroutine initialize_binding(ierror)
        use iso_c_binding, only: c_int8_t, c_int64_t, c_float, c_double, c_double_complex
        use mpi_c_bindings, only: c_types_init, c_types_finalize, c_handles_init
        integer(c_int), intent(out) :: ierror
        integer, parameter :: bytes = storage_size(.true.)/8
        integer(c_int8_t) :: truth(bytes), falsity(bytes)
        integer(c_int), parameter :: model(*) = [storage_size(0)/8, radix(0), digits(0), &
            storage_size(0_8)/8, digits(0_8), storage_size(0.0)/8, radix(0.0), digits(0.0), &
            minexponent(0.0), maxexponent(0.0), storage_size(0.d0)/8, radix(0.d0), digits(0.d0), &
            minexponent(0.d0), maxexponent(0.d0), storage_size((0.d0, 0.d0))/8, storage_size('a')/8]
        integer(c_int) :: cleanup_ierror
        if (kind(0) /= c_int .or. kind(0_8) /= c_int64_t .or. kind(0.0) /= c_float .or. &
                kind(0.d0) /= c_double .or. kind((0.d0, 0.d0)) /= c_double_complex .or. &
                kind('a') /= c_char) then
            print *, "fortran_mpi: selected compiler kinds do not match the C datatype contract."
            ierror = MPI_ERR_TYPE
            return
        end if
        truth = transfer(.true., truth)
        falsity = transfer(.false., falsity)
        ierror = c_types_init(model, bytes, truth, falsity)
        if (ierror == MPI_SUCCESS) then
            ierror = c_handles_init()
            if (ierror /= MPI_SUCCESS) cleanup_ierror = c_types_finalize()
        end if
    end subroutine initialize_binding

    logical function valid_handles(families, tokens, name, ierror) result(ok)
        use mpi_c_bindings, only: c_check_handles
        integer, intent(in) :: families(:), tokens(:)
        character(*), intent(in) :: name
        integer, optional, intent(out) :: ierror
        integer(c_int) :: rc
        rc = c_check_handles(size(tokens), families, tokens)
        ok = rc == MPI_SUCCESS
        if (.not. ok) call set_ierror(rc, name, ierror)
    end function valid_handles

    logical function valid_reduction(datatype, op, comm, name, ierror) result(ok)
        integer, intent(in) :: datatype, op, comm
        character(*), intent(in) :: name
        integer, optional, intent(out) :: ierror
        ok = valid_handles([type_family, op_family, comm_family], [datatype, op, comm], name, ierror)
        if (ok .and. datatype == MPI_LOGICAL) then
            ok = op == MPI_LAND .or. op == MPI_LOR .or. op == MPI_LXOR
            if (.not. ok) call set_ierror(MPI_ERR_OP, name, ierror)
        end if
    end function valid_reduction

    integer function null_handle(family) result(token)
        integer, intent(in) :: family
        integer, parameter :: nulls(*) = [MPI_COMM_NULL, MPI_GROUP_NULL, MPI_REQUEST_NULL, &
            MPI_DATATYPE_NULL, MPI_OP_NULL, MPI_INFO_NULL, MPI_ERRHANDLER_NULL]
        token = nulls(family)
    end function null_handle

    logical function reserve_handle(family, token, name, ierror) result(ok)
        use mpi_c_bindings, only: c_reserve_handle
        integer, intent(in) :: family
        integer, intent(out) :: token
        character(*), intent(in) :: name
        integer, optional, intent(out) :: ierror
        integer(c_int) :: rc
        token = null_handle(family)
        rc = c_reserve_handle(family, token)
        ok = rc == MPI_SUCCESS
        if (.not. ok) then
            token = null_handle(family)
            call set_ierror(rc, name, ierror)
        end if
    end function reserve_handle

    subroutine save_handle(family, handle, token, ierror)
        use mpi_c_bindings, only: c_store_handle, c_release_handle, c_discard_created
        integer, intent(in) :: family
        integer(kind=MPI_HANDLE_KIND), target, intent(inout) :: handle
        integer, intent(inout) :: token
        integer(c_int), intent(inout) :: ierror
        integer(c_int) :: cleanup_ierror
        if (ierror == MPI_SUCCESS) then
            ierror = c_store_handle(family, c_loc(handle), token, 1)
            if (ierror /= MPI_SUCCESS) cleanup_ierror = c_discard_created(family, c_loc(handle))
        end if
        if (ierror /= MPI_SUCCESS) then
            call c_release_handle(family, token)
            token = null_handle(family)
        end if
    end subroutine save_handle

    subroutine update_handle(family, handle, token, ierror)
        use mpi_c_bindings, only: c_update_handle
        integer, intent(in) :: family
        integer(kind=MPI_HANDLE_KIND), target, intent(in) :: handle
        integer, intent(inout) :: token
        integer(c_int), intent(inout) :: ierror
        integer(c_int) :: rc
        rc = c_update_handle(family, c_loc(handle), token)
        if (ierror == MPI_SUCCESS) ierror = rc
    end subroutine update_handle

    function handle_f2c(family, token) result(handle)
        use mpi_c_bindings, only: c_handle_to_c
        integer, intent(in) :: family, token
        integer(kind=MPI_HANDLE_KIND), target :: handle
        integer(c_int) :: rc
        ! Every caller validates its inputs before invoking any C MPI routine.
        rc = c_handle_to_c(family, token, c_loc(handle))
        if (rc /= MPI_SUCCESS) error stop "fortran_mpi: handle invalidated during a call"
    end function handle_f2c

    integer(kind=MPI_HANDLE_KIND) function op_f2c(op, datatype) result(c_op)
        use mpi_c_bindings, only: c_logical_op_table
        integer, intent(in) :: op, datatype
        if (datatype == MPI_LOGICAL .and. op >= MPI_LAND .and. op <= MPI_LXOR) then
            c_op = c_logical_op_table(op - MPI_LAND + 1)
        else
            c_op = handle_f2c(op_family, op)
        end if
    end function op_f2c

    integer(kind=MPI_HANDLE_KIND) function comm_f2c(comm) result(c_comm)
        integer, intent(in) :: comm
        c_comm = handle_f2c(comm_family, comm)
    end function comm_f2c

    integer(kind=MPI_HANDLE_KIND) function group_f2c(group) result(c_group)
        integer, intent(in) :: group
        c_group = handle_f2c(group_family, group)
    end function group_f2c

    integer(kind=MPI_HANDLE_KIND) function info_f2c(info) result(c_info)
        integer, intent(in) :: info
        c_info = handle_f2c(info_family, info)
    end function info_f2c

    integer(kind=MPI_HANDLE_KIND) function request_f2c(request) result(c_request)
        integer, intent(in) :: request
        c_request = handle_f2c(request_family, request)
    end function request_f2c

    integer(kind=MPI_HANDLE_KIND) function datatype_f2c(datatype) result(c_datatype)
        integer, intent(in) :: datatype
        c_datatype = handle_f2c(type_family, datatype)
    end function datatype_f2c

    integer(kind=MPI_HANDLE_KIND) function errhandler_f2c(errhandler) result(c_errhandler)
        integer, intent(in) :: errhandler
        c_errhandler = handle_f2c(errhandler_family, errhandler)
    end function errhandler_f2c

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
        use mpi_c_bindings, only: c_malloc, c_sizeof_mpi_status
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
        if (.not. ok) call set_ierror(MPI_ERR_NO_MEM, name, ierror)
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
        if (conversion_ierror == MPI_SUCCESS) then
            status(MPI_SOURCE) = rank_c2f(status(MPI_SOURCE))
            status(MPI_TAG) = tag_c2f(status(MPI_TAG))
        end if
        if (conversion_ierror /= MPI_SUCCESS) then
            call set_ierror(conversion_ierror, "fortran_mpi status packing")
            ! Do not hide a native completion error with a conversion error.
            if (mpi_ierror == MPI_SUCCESS) mpi_ierror = conversion_ierror
        end if
    end subroutine status_c2f

    subroutine status_f2c(status, c_status, ierror)
        use mpi_c_bindings, only: c_mpi_status_f2c
        integer, intent(in) :: status(MPI_STATUS_SIZE)
        type(c_ptr), intent(in) :: c_status
        integer(c_int), intent(out) :: ierror
        integer :: native_status(MPI_STATUS_SIZE)
        native_status = status
        native_status(MPI_SOURCE) = rank_f2c(status(MPI_SOURCE))
        native_status(MPI_TAG) = tag_f2c(status(MPI_TAG))
        ierror = c_mpi_status_f2c(native_status, c_status)
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
        if (local_ierr == MPI_SUCCESS) call initialize_binding(local_ierr)
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
        if (local_ierr == MPI_SUCCESS) call initialize_binding(local_ierr)
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
        use mpi_c_bindings, only: c_mpi_finalize, c_types_finalize, c_handles_finalize
        integer, optional, intent(out) :: ierr
        integer(c_int) :: local_ierr, cleanup_ierr
        cleanup_ierr = c_types_finalize()
        local_ierr = c_mpi_finalize()
        if (local_ierr == MPI_SUCCESS) then
            call c_handles_finalize()
            local_ierr = cleanup_ierr
        end if
        call set_ierror(local_ierr, "MPI_Finalize", ierr)
    end subroutine MPI_Finalize

    subroutine MPI_Abort(comm, errorcode, ierror)
        use mpi_c_bindings, only: c_mpi_abort
        integer, intent(in) :: comm, errorcode
        integer, optional, intent(out) :: ierror
        if (.not. valid_handles([comm_family], [comm], "MPI_Abort", ierror)) return
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
        if (.not. valid_handles([comm_family], [comm], "MPI_Comm_size", ierror)) return
        call set_ierror(c_mpi_comm_size(comm_f2c(comm), size), "MPI_Comm_size", ierror)
    end subroutine MPI_Comm_size

    subroutine MPI_Comm_rank(comm, rank, ierror)
        use mpi_c_bindings, only: c_mpi_comm_rank
        integer, intent(in) :: comm
        integer, intent(out) :: rank
        integer, optional, intent(out) :: ierror
        if (.not. valid_handles([comm_family], [comm], "MPI_Comm_rank", ierror)) return
        call set_ierror(c_mpi_comm_rank(comm_f2c(comm), rank), "MPI_Comm_rank", ierror)
    end subroutine MPI_Comm_rank

    subroutine MPI_Comm_compare(comm1, comm2, result, ierror)
        use mpi_c_bindings, only: c_mpi_comm_compare
        integer, intent(in) :: comm1, comm2
        integer, intent(out) :: result
        integer, optional, intent(out) :: ierror
        integer(c_int) :: c_result, local_ierr
        if (.not. valid_handles([comm_family, comm_family], [comm1, comm2], "MPI_Comm_compare", ierror)) return
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
        if (.not. valid_handles([comm_family], [comm], "MPI_Comm_group", ierror)) return
        if (.not. reserve_handle(group_family, group, "MPI_Comm_group", ierror)) return
        local_ierr = c_mpi_comm_group(comm_f2c(comm), c_group)
        call save_handle(group_family, c_group, group, local_ierr)
        call set_ierror(local_ierr, "MPI_Comm_group", ierror)
    end subroutine MPI_Comm_Group

    subroutine MPI_Group_size(group, size, ierror)
        use mpi_c_bindings, only: c_mpi_group_size
        integer, intent(in) :: group
        integer, intent(out) :: size
        integer, optional, intent(out) :: ierror
        if (.not. valid_handles([group_family], [group], "MPI_Group_size", ierror)) return
        call set_ierror(c_mpi_group_size(group_f2c(group), size), "MPI_Group_size", ierror)
    end subroutine MPI_Group_size

    subroutine MPI_Group_free(group, ierror)
        use mpi_c_bindings, only: c_mpi_group_free
        integer, intent(inout) :: group
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_group
        integer(c_int) :: local_ierr
        if (.not. valid_handles([group_family], [group], "MPI_Group_free", ierror)) return
        c_group = group_f2c(group)
        local_ierr = c_mpi_group_free(c_group)
        call update_handle(group_family, c_group, group, local_ierr)
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
        if (.not. valid_handles([group_family], [group], "MPI_Group_range_incl", ierror)) return
        if (.not. reserve_handle(group_family, newgroup, "MPI_Group_range_incl", ierror)) return
        local_ierr = c_mpi_group_range_incl(group_f2c(group), n, ranks, c_newgroup)
        call save_handle(group_family, c_newgroup, newgroup, local_ierr)
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
        if (.not. valid_handles([comm_family, group_family], [comm, group], "MPI_Comm_create", ierror)) return
        if (.not. reserve_handle(comm_family, newcomm, "MPI_Comm_create", ierror)) return
        local_ierr = c_mpi_comm_create(comm_f2c(comm), group_f2c(group), c_newcomm)
        call save_handle(comm_family, c_newcomm, newcomm, local_ierr)
        call set_ierror(local_ierr, "MPI_Comm_create", ierror)
    end subroutine MPI_Comm_create

    subroutine MPI_Comm_dup(comm, newcomm, ierror)
        use mpi_c_bindings, only: c_mpi_comm_dup
        integer, intent(in) :: comm
        integer, intent(out) :: newcomm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_newcomm
        integer(c_int) :: local_ierr
        if (.not. valid_handles([comm_family], [comm], "MPI_Comm_dup", ierror)) return
        if (.not. reserve_handle(comm_family, newcomm, "MPI_Comm_dup", ierror)) return
        local_ierr = c_mpi_comm_dup(comm_f2c(comm), c_newcomm)
        call save_handle(comm_family, c_newcomm, newcomm, local_ierr)
        call set_ierror(local_ierr, "MPI_Comm_dup", ierror)
    end subroutine MPI_Comm_dup

    subroutine MPI_Comm_free(comm, ierror)
        use mpi_c_bindings, only: c_mpi_comm_free
        integer, intent(inout) :: comm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_comm
        integer(c_int) :: local_ierr
        if (.not. valid_handles([comm_family], [comm], "MPI_Comm_free", ierror)) return
        c_comm = comm_f2c(comm)
        local_ierr = c_mpi_comm_free(c_comm)
        call update_handle(comm_family, c_comm, comm, local_ierr)
        call set_ierror(local_ierr, "MPI_Comm_free", ierror)
    end subroutine MPI_Comm_free

    subroutine MPI_Comm_split(comm, color, key, newcomm, ierror)
        use mpi_c_bindings, only: c_mpi_comm_split
        integer, intent(in) :: comm, color, key
        integer, intent(out) :: newcomm
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_newcomm
        integer(c_int) :: local_ierr
        if (.not. valid_handles([comm_family], [comm], "MPI_Comm_split", ierror)) return
        if (.not. reserve_handle(comm_family, newcomm, "MPI_Comm_split", ierror)) return
        local_ierr = c_mpi_comm_split(comm_f2c(comm), color_f2c(color), key, c_newcomm)
        call save_handle(comm_family, c_newcomm, newcomm, local_ierr)
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
        if (.not. valid_handles([comm_family, info_family], [comm, info], "MPI_Comm_split_type", ierror)) return
        if (.not. reserve_handle(comm_family, newcomm, "MPI_Comm_split_type", ierror)) return
        local_ierr = c_mpi_comm_split_type(comm_f2c(comm), split_type_f2c(split_type), key, &
            info_f2c(info), c_newcomm)
        call save_handle(comm_family, c_newcomm, newcomm, local_ierr)
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
        if (.not. valid_handles([comm_family], [comm], "MPI_Comm_get_name", ierror)) return
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
        character(MPI_MAX_OBJECT_NAME) :: predefined_name
        if (.not. valid_handles([type_family], [datatype], "MPI_Type_get_name", ierror)) return
        ! Native C-only types may share storage with C predefined types, but
        ! their public names and Fortran datatype identities remain distinct.
        predefined_name = ""
        select case (datatype)
        case (MPI_LOGICAL)
            predefined_name = "MPI_LOGICAL"
        case (MPI_INTEGER)
            predefined_name = "MPI_INTEGER"
        case (MPI_REAL)
            predefined_name = "MPI_REAL"
        case (MPI_DOUBLE_PRECISION)
            predefined_name = "MPI_DOUBLE_PRECISION"
        case (MPI_DOUBLE_COMPLEX)
            predefined_name = "MPI_DOUBLE_COMPLEX"
        case (MPI_CHARACTER)
            predefined_name = "MPI_CHARACTER"
        case (MPI_REAL4)
            predefined_name = "MPI_REAL4"
        case (MPI_INTEGER8)
            predefined_name = "MPI_INTEGER8"
        case (MPI_REAL8)
            predefined_name = "MPI_REAL8"
        end select
        if (len_trim(predefined_name) > 0) then
            type_name = predefined_name
            resultlen = len_trim(predefined_name)
            call set_ierror(MPI_SUCCESS, "MPI_Type_get_name", ierror)
            return
        end if
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
        if (.not. valid_handles([comm_family], [comm_old], "MPI_Cart_create", ierror)) return
        if (.not. reserve_handle(comm_family, comm_cart, "MPI_Cart_create", ierror)) return
        reorder_c = merge(1, 0, reorder)
        periods_c = merge(1, 0, periods)
        local_ierr = c_mpi_cart_create(comm_f2c(comm_old), ndims, dims, periods_c, reorder_c, &
            c_comm_cart)
        call save_handle(comm_family, c_comm_cart, comm_cart, local_ierr)
        call set_ierror(local_ierr, "MPI_Cart_create", ierror)
    end subroutine MPI_Cart_create

    subroutine MPI_Cart_coords(comm, rank, maxdims, coords, ierror)
        use mpi_c_bindings, only: c_mpi_cart_coords
        integer, intent(in) :: comm
        integer, intent(in) :: rank, maxdims
        integer, intent(out) :: coords(maxdims)
        integer, optional, intent(out) :: ierror
        if (.not. valid_handles([comm_family], [comm], "MPI_Cart_coords", ierror)) return
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
        if (.not. valid_handles([comm_family], [comm], "MPI_Cart_shift", ierror)) return
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
        if (.not. valid_handles([comm_family], [comm], "MPI_Cart_sub", ierror)) return
        if (.not. reserve_handle(comm_family, newcomm, "MPI_Cart_sub", ierror)) return
        remain_dims_c = merge(1, 0, remain_dims)
        local_ierr = c_mpi_cart_sub(comm_f2c(comm), c_loc(remain_dims_c), c_newcomm)
        call save_handle(comm_family, c_newcomm, newcomm, local_ierr)
        call set_ierror(local_ierr, "MPI_Cart_sub", ierror)
    end subroutine MPI_Cart_sub

    ! Synchronization and completion

    subroutine MPI_Barrier(comm, ierror)
        use mpi_c_bindings, only: c_mpi_barrier
        integer, intent(in) :: comm
        integer, intent(out), optional :: ierror
        if (.not. valid_handles([comm_family], [comm], "MPI_Barrier", ierror)) return
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
        if (.not. valid_handles([request_family], [request], "MPI_Wait", ierror)) return
        c_request = request_f2c(request)
        if (is_status_ignore(status)) then
            local_ierr = c_mpi_wait(c_request, c_mpi_status_ignore)
        else
            if (.not. allocate_statuses(1, c_status, "MPI_Wait", ierror)) return
            local_ierr = c_mpi_wait(c_request, c_status)
            if (local_ierr == MPI_SUCCESS) call status_c2f(c_status, status, local_ierr)
            call release_statuses(c_status)
        end if
        call update_handle(request_family, c_request, request, local_ierr)
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
        if (.not. valid_handles([(request_family, i=1,count)], array_of_requests, "MPI_Waitall", ierror)) return
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
            call update_handle(request_family, c_requests(i), array_of_requests(i), local_ierr)
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
        if (.not. valid_handles([request_family], [request], "MPI_Test", ierror)) return
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
        call update_handle(request_family, c_request, request, local_ierr)
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
        if (.not. valid_handles([(request_family, i=1,count)], array_of_requests, "MPI_Testall", ierror)) return
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
            call update_handle(request_family, c_requests(i), array_of_requests(i), local_ierr)
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
        if (.not. valid_handles([(request_family, i=1,count)], array_of_requests, "MPI_Waitany", ierror)) return
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
            call update_handle(request_family, c_requests(i), array_of_requests(i), local_ierr)
        end do
        call set_ierror(local_ierr, "MPI_Waitany", ierror)
    end subroutine MPI_Waitany

    ! Point-to-point

    subroutine MPI_Send(buf, count, datatype, dest, tag, comm, ierror)
        use mpi_c_bindings, only: c_mpi_send
        type(*), dimension(..), contiguous, target, intent(in) :: buf
        integer, intent(in) :: count, datatype, dest, tag, comm
        integer, optional, intent(out) :: ierror
        if (.not. valid_handles([type_family, comm_family], [datatype, comm], "MPI_Send", ierror)) return
        call set_ierror(c_mpi_send(c_loc(buf), count, datatype_f2c(datatype), rank_f2c(dest), &
            tag_f2c(tag), comm_f2c(comm)), "MPI_Send", ierror)
    end subroutine MPI_Send

    subroutine MPI_Ssend(buf, count, datatype, dest, tag, comm, ierror)
        use mpi_c_bindings, only: c_mpi_ssend
        type(*), dimension(..), contiguous, target, intent(in) :: buf
        integer, intent(in) :: count, datatype, dest, tag, comm
        integer, optional, intent(out) :: ierror
        if (.not. valid_handles([type_family, comm_family], [datatype, comm], "MPI_Ssend", ierror)) return
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
        if (.not. valid_handles([type_family, comm_family], [datatype, comm], "MPI_Recv", ierror)) return
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
        if (.not. valid_handles([type_family, comm_family], [datatype, comm], "MPI_Isend", ierror)) return
        if (.not. is_contiguous(buf)) then
            error stop "MPI_Isend: the buffer of a nonblocking call must be contiguous"
        end if
        if (.not. reserve_handle(request_family, request, "MPI_Isend", ierror)) return
        local_ierr = c_mpi_isend(c_loc(buf), count, datatype_f2c(datatype), rank_f2c(dest), &
            tag_f2c(tag), comm_f2c(comm), c_request)
        call save_handle(request_family, c_request, request, local_ierr)
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
        if (.not. valid_handles([type_family, comm_family], [datatype, comm], "MPI_Irecv", ierror)) return
        if (.not. is_contiguous(buf)) then
            error stop "MPI_Irecv: the buffer of a nonblocking call must be contiguous"
        end if
        if (.not. reserve_handle(request_family, request, "MPI_Irecv", ierror)) return
        local_ierr = c_mpi_irecv(c_loc(buf), count, datatype_f2c(datatype), rank_f2c(source), &
            tag_f2c(tag), comm_f2c(comm), c_request)
        call save_handle(request_family, c_request, request, local_ierr)
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
        if (.not. valid_handles([type_family, type_family, comm_family], &
                [sendtype, recvtype, comm], "MPI_Sendrecv", ierror)) return
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
        if (.not. valid_handles([comm_family], [comm], "MPI_Probe", ierror)) return
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
        if (.not. valid_handles([comm_family], [comm], "MPI_Iprobe", ierror)) return
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
        if (.not. valid_handles([type_family], [datatype], "MPI_Get_count", ierror)) return
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
        if (.not. valid_handles([type_family, comm_family], [datatype, comm], "MPI_Bcast", ierror)) return
        call set_ierror(c_mpi_bcast(c_loc(buffer), count, datatype_f2c(datatype), rank_f2c(root), &
            comm_f2c(comm)), "MPI_Bcast", ierror)
    end subroutine MPI_Bcast

    subroutine MPI_Reduce(sendbuf, recvbuf, count, datatype, op, root, comm, ierror)
        use mpi_c_bindings, only: c_mpi_reduce
        type(*), dimension(..), contiguous, target, intent(in) :: sendbuf
        type(*), dimension(..), contiguous, target, intent(inout) :: recvbuf
        integer, intent(in) :: count, datatype, op, root, comm
        integer, optional, intent(out) :: ierror
        if (.not. valid_reduction(datatype, op, comm, "MPI_Reduce", ierror)) return
        call set_ierror(c_mpi_reduce(in_place_or(c_loc(sendbuf)), c_loc(recvbuf), count, &
            datatype_f2c(datatype), op_f2c(op, datatype), rank_f2c(root), comm_f2c(comm)), "MPI_Reduce", &
            ierror)
    end subroutine MPI_Reduce

    subroutine MPI_Allreduce(sendbuf, recvbuf, count, datatype, op, comm, ierror)
        use mpi_c_bindings, only: c_mpi_allreduce
        type(*), dimension(..), contiguous, target, intent(in) :: sendbuf
        type(*), dimension(..), contiguous, target, intent(inout) :: recvbuf
        integer, intent(in) :: count, datatype, op, comm
        integer, optional, intent(out) :: ierror
        if (.not. valid_reduction(datatype, op, comm, "MPI_Allreduce", ierror)) return
        call set_ierror(c_mpi_allreduce(in_place_or(c_loc(sendbuf)), c_loc(recvbuf), count, &
            datatype_f2c(datatype), op_f2c(op, datatype), comm_f2c(comm)), "MPI_Allreduce", ierror)
    end subroutine MPI_Allreduce

    subroutine MPI_Exscan(sendbuf, recvbuf, count, datatype, op, comm, ierror)
        use mpi_c_bindings, only: c_mpi_exscan
        type(*), dimension(..), contiguous, target, intent(in) :: sendbuf
        type(*), dimension(..), contiguous, target, intent(inout) :: recvbuf
        integer, intent(in) :: count, datatype, op, comm
        integer, optional, intent(out) :: ierror
        if (.not. valid_reduction(datatype, op, comm, "MPI_Exscan", ierror)) return
        call set_ierror(c_mpi_exscan(in_place_or(c_loc(sendbuf)), c_loc(recvbuf), count, &
            datatype_f2c(datatype), op_f2c(op, datatype), comm_f2c(comm)), "MPI_Exscan", ierror)
    end subroutine MPI_Exscan

    subroutine MPI_Allgather(sendbuf, sendcount, sendtype, recvbuf, recvcount, recvtype, &
            comm, ierror)
        use mpi_c_bindings, only: c_mpi_allgather
        type(*), dimension(..), contiguous, target, intent(in) :: sendbuf
        type(*), dimension(..), contiguous, target, intent(inout) :: recvbuf
        integer, intent(in) :: sendcount, sendtype, recvcount, recvtype, comm
        integer, optional, intent(out) :: ierror
        if (.not. valid_handles([type_family, type_family, comm_family], &
                [sendtype, recvtype, comm], "MPI_Allgather", ierror)) return
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
        if (.not. valid_handles([type_family, type_family, comm_family], &
                [sendtype, recvtype, comm], "MPI_Gatherv", ierror)) return
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
        if (.not. valid_handles([type_family, type_family, comm_family], &
                [sendtype, recvtype, comm], "MPI_Allgatherv", ierror)) return
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
        if (.not. valid_handles([type_family, type_family, comm_family], &
                [sendtype, recvtype, comm], "MPI_Scatter", ierror)) return
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
        if (.not. valid_handles([type_family, type_family, comm_family], &
                [sendtype, recvtype, comm], "MPI_Gather", ierror)) return
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
        if (.not. valid_handles([type_family, type_family, comm_family], &
                [sendtype, recvtype, comm], "MPI_Scatterv", ierror)) return
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
        if (.not. valid_handles([type_family, type_family, comm_family], &
                [sendtype, recvtype, comm], "MPI_Alltoall", ierror)) return
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
        if (.not. valid_handles([type_family, type_family, comm_family], &
                [sendtype, recvtype, comm], "MPI_Alltoallv", ierror)) return
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
        if (.not. valid_reduction(datatype, op, comm, "MPI_Scan", ierror)) return
        call set_ierror(c_mpi_scan(in_place_or(c_loc(sendbuf)), c_loc(recvbuf), count, &
            datatype_f2c(datatype), op_f2c(op, datatype), comm_f2c(comm)), "MPI_Scan", ierror)
    end subroutine MPI_Scan

    subroutine MPI_Reduce_scatter_block(sendbuf, recvbuf, recvcount, datatype, op, comm, &
            ierror)
        use mpi_c_bindings, only: c_mpi_reduce_scatter_block
        type(*), dimension(..), contiguous, target, intent(in) :: sendbuf
        type(*), dimension(..), contiguous, target, intent(inout) :: recvbuf
        integer, intent(in) :: recvcount, datatype, op, comm
        integer, optional, intent(out) :: ierror
        if (.not. valid_reduction(datatype, op, comm, "MPI_Reduce_scatter_block", ierror)) return
        call set_ierror(c_mpi_reduce_scatter_block(in_place_or(c_loc(sendbuf)), c_loc(recvbuf), &
            recvcount, datatype_f2c(datatype), op_f2c(op, datatype), comm_f2c(comm)), &
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
        if (.not. valid_handles([type_family], [oldtype], "MPI_Type_contiguous", ierror)) return
        if (.not. reserve_handle(type_family, newtype, "MPI_Type_contiguous", ierror)) return
        local_ierr = c_mpi_type_contiguous(count, datatype_f2c(oldtype), c_newtype)
        call save_handle(type_family, c_newtype, newtype, local_ierr)
        call set_ierror(local_ierr, "MPI_Type_contiguous", ierror)
    end subroutine MPI_Type_contiguous

    subroutine MPI_Type_vector(count, blocklength, stride, oldtype, newtype, ierror)
        use mpi_c_bindings, only: c_mpi_type_vector
        integer, intent(in) :: count, blocklength, stride, oldtype
        integer, intent(out) :: newtype
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_newtype
        integer(c_int) :: local_ierr
        if (.not. valid_handles([type_family], [oldtype], "MPI_Type_vector", ierror)) return
        if (.not. reserve_handle(type_family, newtype, "MPI_Type_vector", ierror)) return
        local_ierr = c_mpi_type_vector(count, blocklength, stride, datatype_f2c(oldtype), &
            c_newtype)
        call save_handle(type_family, c_newtype, newtype, local_ierr)
        call set_ierror(local_ierr, "MPI_Type_vector", ierror)
    end subroutine MPI_Type_vector

    subroutine MPI_Type_commit(datatype, ierror)
        use mpi_c_bindings, only: c_mpi_type_commit
        integer, intent(inout) :: datatype
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_datatype
        integer(c_int) :: local_ierr
        if (.not. valid_handles([type_family], [datatype], "MPI_Type_commit", ierror)) return
        c_datatype = datatype_f2c(datatype)
        local_ierr = c_mpi_type_commit(c_datatype)
        call update_handle(type_family, c_datatype, datatype, local_ierr)
        call set_ierror(local_ierr, "MPI_Type_commit", ierror)
    end subroutine MPI_Type_commit

    subroutine MPI_Type_free(datatype, ierror)
        use mpi_c_bindings, only: c_mpi_type_free
        integer, intent(inout) :: datatype
        integer, optional, intent(out) :: ierror
        integer(kind=MPI_HANDLE_KIND) :: c_datatype
        integer(c_int) :: local_ierr
        if (.not. valid_handles([type_family], [datatype], "MPI_Type_free", ierror)) return
        c_datatype = datatype_f2c(datatype)
        local_ierr = c_mpi_type_free(c_datatype)
        call update_handle(type_family, c_datatype, datatype, local_ierr)
        call set_ierror(local_ierr, "MPI_Type_free", ierror)
    end subroutine MPI_Type_free

    ! Errors

    subroutine MPI_Comm_set_errhandler(comm, errhandler, ierror)
        use mpi_c_bindings, only: c_mpi_comm_set_errhandler
        integer, intent(in) :: comm, errhandler
        integer, optional, intent(out) :: ierror
        if (.not. valid_handles([comm_family, errhandler_family], &
                [comm, errhandler], "MPI_Comm_set_errhandler", ierror)) return
        call set_ierror(c_mpi_comm_set_errhandler(comm_f2c(comm), errhandler_f2c(errhandler)), &
            "MPI_Comm_set_errhandler", ierror)
    end subroutine MPI_Comm_set_errhandler

    subroutine MPI_Error_class(errorcode, errorclass, ierror)
        ! Classes are also valid codes in the selected C MPI domain.
        use mpi_c_bindings, only: c_mpi_error_class
        integer, intent(in) :: errorcode
        integer, intent(out) :: errorclass
        integer, optional, intent(out) :: ierror
        integer(c_int) :: local_ierr
        local_ierr = c_mpi_error_class(errorcode, errorclass)
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
