#include <mpi.h>

MPI_Status* c_MPI_STATUSES_IGNORE = MPI_STATUSES_IGNORE;

MPI_Info c_MPI_INFO_NULL = MPI_INFO_NULL;

void* c_MPI_IN_PLACE = MPI_IN_PLACE;

// DataType Declarations

MPI_Datatype c_MPI_DOUBLE = MPI_DOUBLE;

MPI_Datatype c_MPI_FLOAT = MPI_FLOAT;

MPI_Datatype c_MPI_INT = MPI_INT;

MPI_Datatype c_MPI_LOGICAL = MPI_LOGICAL;

MPI_Datatype c_MPI_CHARACTER = MPI_CHARACTER;

MPI_Datatype c_MPI_REAL = MPI_REAL;

// Operation Declarations

MPI_Op c_MPI_SUM = MPI_SUM;

MPI_Op c_MPI_MAX = MPI_MAX;

MPI_Op c_MPI_LOR = MPI_LOR;

// Communicators Declarations

MPI_Comm c_MPI_COMM_NULL = MPI_COMM_NULL;

MPI_Comm c_MPI_COMM_WORLD = MPI_COMM_WORLD;

MPI_Comm c_MPI_COMM_SELF = MPI_COMM_SELF;