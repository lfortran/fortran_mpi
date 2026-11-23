#include "mpi_internal.h"

/* Selected by a compile/link probe, not by MPI_VERSION or a vendor version. */
const int fmpi_has_serializers = 0;

int fmpi_toint(int family, fmpi_handle handle)
{
    (void)family;
    (void)handle;
    return 0;
}

fmpi_handle fmpi_fromint(int family, int token)
{
    fmpi_handle unused = {0};
    (void)family;
    (void)token;
    return unused;
}
