#include "fortran_mpi.h"
#include <stdio.h>

int main(int argc, char **argv)
{
    MPI_Comm comm;
    int rank, size, comparison;
    if (MPI_Init(&argc, &argv) != MPI_SUCCESS) return 92;
    if (MPI_Comm_dup(MPI_COMM_WORLD, &comm) != MPI_SUCCESS) return 92;
    if (MPI_Comm_compare(comm, MPI_COMM_WORLD, &comparison) != MPI_SUCCESS ||
            comparison != MPI_CONGRUENT) return 92;
    if (MPI_Comm_rank(comm, &rank) != MPI_SUCCESS || MPI_Comm_size(comm, &size) != MPI_SUCCESS) return 92;
    fprintf(stderr, "abort_control: ready rank=%d size=%d code=73\n", rank, size);
    fflush(stderr);
    if (MPI_Barrier(comm) != MPI_SUCCESS) return 92;
    if (rank == 0) {
        int rc = MPI_Abort(comm, 73);
        fprintf(stderr, "abort_control: returned rc=%d\n", rc);
        fflush(stderr);
        return 91;
    }
    MPI_Barrier(comm);
    fprintf(stderr, "abort_control: peer survived\n");
    return 92;
}
