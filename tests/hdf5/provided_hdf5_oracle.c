#include "fortran_mpi.h"
#include <hdf5.h>
#include <stddef.h>

static int watched_frees, cleanup_ok, import_error;

static int communicator_deleted(MPI_Comm comm, int key, void *attribute, void *extra_state)
{
    (void)comm;
    (void)key;
    (void)extra_state;
    ++*(int *)attribute;
    return MPI_SUCCESS;
}

static int watch(MPI_Comm comm)
{
    int key;
    watched_frees = 0;
    cleanup_ok = 0;
    if (comm == MPI_COMM_NULL) return MPI_ERR_COMM;
    int rc = MPI_Comm_create_keyval(MPI_COMM_NULL_COPY_FN, communicator_deleted, &key, NULL);
    if (rc != MPI_SUCCESS) return rc;
    rc = MPI_Comm_set_attr(comm, key, &watched_frees);
    /* The attached attribute retains the key until its communicator is freed. */
    int key_rc = MPI_Comm_free_keyval(&key);
    return rc == MPI_SUCCESS ? key_rc : rc;
}

static herr_t set_fapl(hid_t fapl, int token)
{
    MPI_Comm comm;
    if (fortran_mpi_comm_to_c(token, &comm) != MPI_SUCCESS) return -1;
    return H5Pset_fapl_mpio(fapl, comm, MPI_INFO_NULL);
}

static herr_t get_fapl(hid_t fapl, int *out, int reject_import)
{
    MPI_Comm comm = MPI_COMM_NULL;
    int token;
    if (fortran_mpi_comm_from_c(MPI_COMM_NULL, out) != MPI_SUCCESS) return -1;
    if (H5Pget_fapl_mpio(fapl, &comm, NULL) < 0) return -1;
    if (reject_import && watch(comm) != MPI_SUCCESS) {
        if (comm != MPI_COMM_NULL) MPI_Comm_free(&comm);
        return -1;
    }
    /* A null output provokes a real adapter error without exhausting memory. */
    import_error = fortran_mpi_comm_from_c(comm, reject_import ? NULL : &token);
    if (import_error != MPI_SUCCESS) {
        if (comm != MPI_COMM_NULL) {
            int rc = MPI_Comm_free(&comm);
            cleanup_ok = rc == MPI_SUCCESS && comm == MPI_COMM_NULL;
        }
        return -1;
    }
    *out = token;
    return 0;
}

int hdf5_provided_world(int token)
{
    MPI_Comm comm;
    int reverse;
    if (fortran_mpi_comm_to_c(token, &comm) != MPI_SUCCESS || comm != MPI_COMM_WORLD) return 1;
    if (fortran_mpi_comm_from_c(comm, &reverse) != MPI_SUCCESS || reverse != token) return 2;
    return 0;
}

int hdf5_provided_roundtrip(int token, int *returned)
{
    MPI_Comm input, native;
    int comparison, reverse;
    if (fortran_mpi_comm_to_c(token, &input) != MPI_SUCCESS) return 1;
    hid_t fapl = H5Pcreate(H5P_FILE_ACCESS);
    if (fapl < 0) return 2;
    if (set_fapl(fapl, token) < 0 || H5Pget_driver(fapl) != H5FD_MPIO ||
            get_fapl(fapl, returned, 0) < 0) {
        H5Pclose(fapl);
        return 3;
    }
    if (fortran_mpi_comm_to_c(*returned, &native) != MPI_SUCCESS) return 4;
    if (native == input || native == MPI_COMM_NULL) return 5;
    if (fortran_mpi_comm_from_c(native, &reverse) != MPI_SUCCESS || reverse != *returned) return 6;
    if (MPI_Comm_compare(input, native, &comparison) != MPI_SUCCESS || comparison != MPI_CONGRUENT) return 7;
    if (watch(native) != MPI_SUCCESS) {
        H5Pclose(fapl);
        return 8;
    }
    if (H5Pclose(fapl) < 0 || watched_frees != 0) return 8;
    /* The Fortran caller now owns exactly one release of the imported duplicate. */
    return 0;
}

int hdf5_provided_retired(int token)
{
    MPI_Comm unchanged = MPI_COMM_SELF;
    int error_class;
    if (watched_frees != 1) return 1;
    int rc = fortran_mpi_comm_to_c(token, &unchanged);
    if (rc == MPI_SUCCESS || unchanged != MPI_COMM_SELF) return 2;
    if (MPI_Error_class(rc, &error_class) != MPI_SUCCESS || error_class != MPI_ERR_COMM) return 3;
    return 0;
}

int hdf5_provided_failures(int world, int null_comm)
{
    H5E_auto2_t error_handler;
    void *error_data;
    int result = 1, returned = world, error_class;
    hid_t fapl = H5I_INVALID_HID;
    if (H5Eget_auto2(H5E_DEFAULT, &error_handler, &error_data) < 0) return 1;
    if (H5Eset_auto2(H5E_DEFAULT, NULL, NULL) < 0) return 2;
    fapl = H5Pcreate(H5P_FILE_ACCESS);
    if (fapl < 0) goto done;
    result = 3;
    if (set_fapl(fapl, 0) >= 0 || set_fapl(H5I_INVALID_HID, world) >= 0) goto done;
    result = 4;
    if (get_fapl(H5I_INVALID_HID, &returned, 0) >= 0 || returned != null_comm ||
            watched_frees != 0) goto done;
    result = 5;
    if (set_fapl(fapl, world) < 0 || H5Pget_driver(fapl) != H5FD_MPIO) goto done;
    returned = world;
    result = 6;
    if (get_fapl(fapl, &returned, 1) >= 0 || returned != null_comm ||
            watched_frees != 1 || !cleanup_ok) goto done;
    result = 7;
    if (MPI_Error_class(import_error, &error_class) != MPI_SUCCESS || error_class != MPI_ERR_ARG) goto done;
    result = hdf5_provided_world(world);
done:
    if (fapl >= 0 && H5Pclose(fapl) < 0) result = 8;
    if (H5Eset_auto2(H5E_DEFAULT, error_handler, error_data) < 0) result = 9;
    return result;
}
