#pragma once

#if defined(MPI_ABI)
#include <mpi_abi.h>
#else
#include <mpi.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Convert this binding's INTEGER(C_INT) communicator tokens, not MPI_Fint.
 * The binding, this header's C MPI ABI, and every consumer must use the same
 * MPI runtime. Call after MPI_Init[ _thread ] and before MPI_Finalize.
 *
 * to_c borrows the live communicator: do not free it through C while its
 * token remains live. from_c neither duplicates nor frees its argument.
 * After a successful import, release a created communicator through the
 * binding's MPI_Comm_free; on import failure the C caller still owns it.
 * Repeated imports of the same live object return the same token. Null,
 * WORLD and SELF have explicit mappings. Freed tokens may be reused and
 * must not be used again. The output is unchanged on error.
 *
 * Both functions return errors in the selected C MPI error-code domain.
 */
int fortran_mpi_comm_to_c(int token, MPI_Comm *out);
int fortran_mpi_comm_from_c(MPI_Comm comm, int *out);

#ifdef __cplusplus
}
#endif
