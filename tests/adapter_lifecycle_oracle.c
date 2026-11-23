#include "fortran_mpi.h"

int adapter_predefined(const int tokens[3])
{
    MPI_Comm expected[3] = {MPI_COMM_NULL, MPI_COMM_WORLD, MPI_COMM_SELF};
    for (int i = 0; i < 3; ++i) {
        MPI_Comm first, second;
        int token;
        if (fortran_mpi_comm_to_c(tokens[i], &first) != MPI_SUCCESS) return 1;
        if (fortran_mpi_comm_to_c(tokens[i], &second) != MPI_SUCCESS) return 2;
        if (first != expected[i] || second != first) return 3;
        if (fortran_mpi_comm_from_c(first, &token) != MPI_SUCCESS || token != tokens[i]) return 4;
    }
    MPI_Comm unchanged = MPI_COMM_SELF;
    int rc = fortran_mpi_comm_to_c(0, &unchanged), error_class;
    if (rc == MPI_SUCCESS || unchanged != MPI_COMM_SELF) return 5;
    if (MPI_Error_class(rc, &error_class) != MPI_SUCCESS || error_class != MPI_ERR_COMM) return 6;
    if (fortran_mpi_comm_to_c(tokens[1], 0) != MPI_ERR_ARG ||
            fortran_mpi_comm_from_c(MPI_COMM_WORLD, 0) != MPI_ERR_ARG) return 7;
    return 0;
}

int adapter_dynamic(int token, int parent_token, int expected_size, int expected_rank)
{
    MPI_Comm first, second, parent;
    int imported, size, rank, comparison;
    if (fortran_mpi_comm_to_c(token, &first) != MPI_SUCCESS) return 1;
    if (fortran_mpi_comm_to_c(token, &second) != MPI_SUCCESS) return 2;
    if (fortran_mpi_comm_to_c(parent_token, &parent) != MPI_SUCCESS) return 3;
    if (first == MPI_COMM_NULL || first != second || first == parent) return 4;
    if (fortran_mpi_comm_from_c(first, &imported) != MPI_SUCCESS || imported != token) return 5;
    if (MPI_Comm_size(first, &size) != MPI_SUCCESS || size != expected_size) return 6;
    if (MPI_Comm_rank(first, &rank) != MPI_SUCCESS || rank != expected_rank) return 7;
    if (MPI_Comm_compare(first, second, &comparison) != MPI_SUCCESS || comparison != MPI_IDENT) return 8;
    if (MPI_Barrier(first) != MPI_SUCCESS) return 9;
    return 0;
}

int adapter_distinct(int left_token, int right_token)
{
    MPI_Comm left, right;
    int comparison;
    if (fortran_mpi_comm_to_c(left_token, &left) != MPI_SUCCESS) return 1;
    if (fortran_mpi_comm_to_c(right_token, &right) != MPI_SUCCESS) return 2;
    if (left_token == right_token || left == right || left == MPI_COMM_NULL || right == MPI_COMM_NULL) return 3;
    if (MPI_Comm_compare(left, right, &comparison) != MPI_SUCCESS || comparison != MPI_CONGRUENT) return 4;
    return 0;
}

int adapter_create(int world_token, int *token)
{
    MPI_Comm world, created, exported;
    int repeated, comparison;
    if (fortran_mpi_comm_to_c(world_token, &world) != MPI_SUCCESS || world != MPI_COMM_WORLD) return 1;
    if (MPI_Comm_dup(world, &created) != MPI_SUCCESS) return 2;
    if (fortran_mpi_comm_from_c(created, token) != MPI_SUCCESS) {
        MPI_Comm_free(&created);
        return 3;
    }
    /* Successful import transfers release responsibility to the Fortran test. */
    if (fortran_mpi_comm_from_c(created, &repeated) != MPI_SUCCESS || repeated != *token) return 4;
    if (fortran_mpi_comm_to_c(*token, &exported) != MPI_SUCCESS || exported != created) return 5;
    if (exported == world) return 6;
    if (MPI_Comm_compare(exported, world, &comparison) != MPI_SUCCESS || comparison != MPI_CONGRUENT) return 7;
    return 0;
}

int adapter_retired(int token)
{
    MPI_Comm output = MPI_COMM_NULL;
    int error_class, error = fortran_mpi_comm_to_c(token, &output);
    if (error == MPI_SUCCESS) return 1;
    if (MPI_Error_class(error, &error_class) != MPI_SUCCESS || error_class != MPI_ERR_COMM) return 2;
    return 0;
}
