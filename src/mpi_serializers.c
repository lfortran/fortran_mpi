#include "mpi_internal.h"

const int fmpi_has_serializers = 1;

int fmpi_toint(int family, fmpi_handle handle)
{
    switch (family) {
    case FMPI_COMM: return MPI_Comm_toint(handle.comm);
    case FMPI_GROUP: return MPI_Group_toint(handle.group);
    case FMPI_REQUEST: return MPI_Request_toint(handle.request);
    case FMPI_TYPE: return MPI_Type_toint(handle.datatype);
    case FMPI_OP: return MPI_Op_toint(handle.op);
    case FMPI_INFO: return MPI_Info_toint(handle.info);
    case FMPI_ERRHANDLER: return MPI_Errhandler_toint(handle.errhandler);
    }
    return 0;
}

fmpi_handle fmpi_fromint(int family, int token)
{
    fmpi_handle handle = {0};
    switch (family) {
    case FMPI_COMM: handle.comm = MPI_Comm_fromint(token); break;
    case FMPI_GROUP: handle.group = MPI_Group_fromint(token); break;
    case FMPI_REQUEST: handle.request = MPI_Request_fromint(token); break;
    case FMPI_TYPE: handle.datatype = MPI_Type_fromint(token); break;
    case FMPI_OP: handle.op = MPI_Op_fromint(token); break;
    case FMPI_INFO: handle.info = MPI_Info_fromint(token); break;
    case FMPI_ERRHANDLER: handle.errhandler = MPI_Errhandler_fromint(token); break;
    }
    return handle;
}
