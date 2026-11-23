#include <mpi.h>
#include <hdf5.h>

/* Implemented by the unmodified application shim supplied to the test. */
extern herr_t H5Pset_fapl_mpio_Fcomm(hid_t fapl, MPI_Fint comm);
extern herr_t H5Pget_fapl_mpio_Fcomm(hid_t fapl, MPI_Fint *comm);

_Static_assert(_Generic((MPI_Fint)0, int: 1, default: 0), "MPI_Fint must match C int");

int hdf5_native_world(MPI_Fint comm)
{
    return comm == MPI_Comm_c2f(MPI_COMM_WORLD) ? 0 : 1;
}

int hdf5_native_roundtrip(MPI_Fint comm, MPI_Fint *returned)
{
    hid_t fapl = H5Pcreate(H5P_FILE_ACCESS);
    if (fapl < 0) return 1;
    if (H5Pset_fapl_mpio_Fcomm(fapl, comm) < 0 ||
        H5Pget_driver(fapl) != H5FD_MPIO ||
        H5Pget_fapl_mpio_Fcomm(fapl, returned) < 0) {
        H5Pclose(fapl);
        return 2;
    }
    MPI_Comm native = MPI_Comm_f2c(*returned);
    int comparison;
    int rc = MPI_Comm_compare(MPI_Comm_f2c(comm), native, &comparison);
    herr_t close_rc = H5Pclose(fapl);
    if (rc != MPI_SUCCESS || comparison != MPI_CONGRUENT || close_rc < 0) {
        MPI_Comm_free(&native);
        return 3;
    }
    return 0;
}
