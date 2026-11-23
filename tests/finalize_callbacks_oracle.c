#if defined(MPI_ABI)
#include <mpi_abi.h>
#else
#include <mpi.h>
#endif
#include <stdio.h>

extern int fmpi_finalizer_logical_probe(void);
static int calls, last_code;

static int deleted(MPI_Comm comm, int key, void *attribute, void *extra)
{
    (void)comm;
    (void)key;
    (void)attribute;
    (void)extra;
    int finalized = -1, error_class = MPI_ERR_OTHER;
    int rc = MPI_Finalized(&finalized);
    ++calls;
    last_code = rc;
    if (rc == MPI_SUCCESS) {
        last_code = finalized ? MPI_ERR_OTHER : fmpi_finalizer_logical_probe();
        if (!finalized) {
            rc = MPI_Error_class(last_code, &error_class);
            if (rc != MPI_SUCCESS) last_code = rc;
        }
    }
    printf("FMPI_CALLBACK call=%d finalized=%d success=%d op_error=%d code=%d class=%d\n",
           calls, finalized, last_code == MPI_SUCCESS,
           error_class == MPI_ERR_OP, last_code, error_class);
    fflush(stdout);
    /* Record failures without stopping MPI's remaining finalization callbacks. */
    return MPI_SUCCESS;
}

int fmpi_finalizer_install(void)
{
    int key = MPI_KEYVAL_INVALID;
    int rc = MPI_Comm_create_keyval(MPI_COMM_NULL_COPY_FN, deleted, &key, NULL);
    if (rc != MPI_SUCCESS) return rc;
    rc = MPI_Comm_set_attr(MPI_COMM_SELF, key, &calls);
    if (rc == MPI_SUCCESS) rc = MPI_Comm_delete_attr(MPI_COMM_SELF, key);
    if (rc == MPI_SUCCESS) rc = last_code;
    if (rc == MPI_SUCCESS) rc = MPI_Comm_set_attr(MPI_COMM_SELF, key, &calls);
    int free_rc = MPI_Comm_free_keyval(&key);
    return rc == MPI_SUCCESS ? free_rc : rc;
}

int fmpi_finalizer_calls(void)
{
    return calls;
}

int fmpi_finalizer_result(void)
{
    return last_code;
}
