#pragma once
#include "fortran_mpi.h"

enum fmpi_family {
    FMPI_COMM = 1, FMPI_GROUP, FMPI_REQUEST, FMPI_TYPE,
    FMPI_OP, FMPI_INFO, FMPI_ERRHANDLER
};

typedef union {
    MPI_Comm comm;
    MPI_Group group;
    MPI_Request request;
    MPI_Datatype datatype;
    MPI_Op op;
    MPI_Info info;
    MPI_Errhandler errhandler;
} fmpi_handle;

extern MPI_Comm c_comm_table[3];
extern MPI_Group c_group_table[2];
extern MPI_Request c_request_table[1];
extern MPI_Datatype c_datatype_table[15];
extern MPI_Op c_op_table[15];
extern MPI_Info c_info_table[1];
extern MPI_Errhandler c_errhandler_table[4];
extern MPI_Op c_logical_op_table[3];

extern const int fmpi_has_serializers;
int fmpi_toint(int family, fmpi_handle handle);
fmpi_handle fmpi_fromint(int family, int token);

int fortran_mpi_handle_to_c(int family, int token, void *out);
int fortran_mpi_handle_reserve(int family, int *token);
int fortran_mpi_handle_store(int family, const void *handle, int *token, int acquired);
void fortran_mpi_handle_release(int family, int token);
void fortran_mpi_handles_finalize(void);
int fortran_mpi_handles_init(void);

int fortran_mpi_types_init(const int *model, int logical_size, const void *truth, const void *falsity);
int fortran_mpi_types_finalize(void);
