#if defined(MPI_ABI)
#include <mpi_abi.h>
#else
#include <mpi.h>
#endif
#include <string.h>

void mpi_error_class_values(int values[58], int *lastcode)
{
    const int classes[58] = {
        MPI_SUCCESS, MPI_ERR_BUFFER, MPI_ERR_COUNT, MPI_ERR_TYPE, MPI_ERR_TAG,
        MPI_ERR_COMM, MPI_ERR_RANK, MPI_ERR_REQUEST, MPI_ERR_ROOT, MPI_ERR_GROUP,
        MPI_ERR_OP, MPI_ERR_TOPOLOGY, MPI_ERR_DIMS, MPI_ERR_ARG, MPI_ERR_UNKNOWN,
        MPI_ERR_TRUNCATE, MPI_ERR_OTHER, MPI_ERR_INTERN, MPI_ERR_PENDING,
        MPI_ERR_IN_STATUS, MPI_ERR_ACCESS, MPI_ERR_AMODE, MPI_ERR_ASSERT,
        MPI_ERR_BAD_FILE, MPI_ERR_BASE, MPI_ERR_CONVERSION, MPI_ERR_DISP,
        MPI_ERR_DUP_DATAREP, MPI_ERR_FILE_EXISTS, MPI_ERR_FILE_IN_USE, MPI_ERR_FILE,
        MPI_ERR_INFO_KEY, MPI_ERR_INFO_NOKEY, MPI_ERR_INFO_VALUE, MPI_ERR_INFO,
        MPI_ERR_IO, MPI_ERR_KEYVAL, MPI_ERR_LOCKTYPE, MPI_ERR_NAME, MPI_ERR_NO_MEM,
        MPI_ERR_NOT_SAME, MPI_ERR_NO_SPACE, MPI_ERR_NO_SUCH_FILE, MPI_ERR_PORT,
        MPI_ERR_QUOTA, MPI_ERR_READ_ONLY, MPI_ERR_RMA_ATTACH, MPI_ERR_RMA_CONFLICT,
        MPI_ERR_RMA_RANGE, MPI_ERR_RMA_SHARED, MPI_ERR_RMA_SYNC, MPI_ERR_SERVICE,
        MPI_ERR_SIZE, MPI_ERR_SPAWN, MPI_ERR_UNSUPPORTED_DATAREP,
        MPI_ERR_UNSUPPORTED_OPERATION, MPI_ERR_WIN, MPI_ERR_RMA_FLAVOR
    };
    memcpy(values, classes, sizeof(classes));
    *lastcode = MPI_ERR_LASTCODE;
}

int mpi_error_classes_control(void)
{
    int values[58], lastcode, result;
    mpi_error_class_values(values, &lastcode);
    for (int i = 0; i < 58; ++i) {
        if (MPI_Error_class(values[i], &result) != MPI_SUCCESS || result != values[i]) return 1;
    }
    return 0;
}

int mpi_error_text_matches(int code, const char *text, int length)
{
    char expected[MPI_MAX_ERROR_STRING];
    int expected_length;
    if (MPI_Error_string(code, expected, &expected_length) != MPI_SUCCESS) return 1;
    if (length != expected_length || length < 0 || length >= MPI_MAX_ERROR_STRING) return 1;
    return memcmp(expected, text, (size_t)length) != 0;
}

int mpi_error_native_root(int *code)
{
    int value = 1, result, rc;
    rc = MPI_Comm_set_errhandler(MPI_COMM_SELF, MPI_ERRORS_RETURN);
    if (rc != MPI_SUCCESS) return rc;
    *code = MPI_Bcast(&value, 1, MPI_INT, 1, MPI_COMM_SELF);
    if (*code == MPI_SUCCESS) return MPI_ERR_OTHER;
    rc = MPI_Error_class(*code, &result);
    if (rc != MPI_SUCCESS || result != MPI_ERR_ROOT) return MPI_ERR_OTHER;
    return MPI_SUCCESS;
}
