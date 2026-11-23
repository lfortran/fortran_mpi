#include "fortran_mpi.h"
#include <stdio.h>

int abort_ready(int token, int expected_size, int expected_rank)
{
    MPI_Comm comm;
    int size, rank, comparison;
    if (fortran_mpi_comm_to_c(token, &comm) != MPI_SUCCESS) return 1;
    if (comm == MPI_COMM_NULL || comm == MPI_COMM_WORLD) return 2;
    if (MPI_Comm_compare(comm, MPI_COMM_WORLD, &comparison) != MPI_SUCCESS ||
            comparison != MPI_CONGRUENT) return 3;
    if (MPI_Comm_size(comm, &size) != MPI_SUCCESS || size != expected_size) return 4;
    if (MPI_Comm_rank(comm, &rank) != MPI_SUCCESS || rank != expected_rank) return 5;
    fprintf(stderr, "abort_1: ready rank=%d size=%d code=73\n", rank, size);
    fflush(stderr);
    return 0;
}

void abort_returned(int code)
{
    fprintf(stderr, "abort_1: returned rc=%d\n", code);
    fflush(stderr);
}
