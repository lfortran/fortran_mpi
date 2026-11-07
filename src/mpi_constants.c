/*
 * Native values of the MPI constants, indexed by their MPI-5 ABI value.
 *
 * src/mpi.f90 gives every MPI constant its MPI-5 ABI value (MPI 5.0,
 * chapter 21), the same for all MPI implementations. This file is compiled
 * against the native <mpi.h> and tells the Fortran code which value the MPI
 * library actually uses for each of them. It contains no functions, only
 * initialized data, and works with any MPI implementation. It goes away once
 * we link against an MPI-5 ABI library, where the native values are the ABI
 * values. See doc/design.md.
 *
 * Each handle table covers the ABI range of one handle type, and is indexed
 * by the ABI value minus the first value of the range. Entries that
 * src/mpi.f90 has no constant for are left zero, which is never a valid
 * handle. The table sizes must match src/mpi_c_bindings.f90.
 */

#include <stddef.h>
#include <mpi.h>

/* Handles */

MPI_Op c_op_table[32] = {               /* ABI 0x020 .. 0x03f */
    [0x00] = MPI_OP_NULL,
    [0x01] = MPI_SUM,
    [0x02] = MPI_MIN,
    [0x03] = MPI_MAX,
    [0x04] = MPI_PROD,
    [0x08] = MPI_BAND,
    [0x09] = MPI_BOR,
    [0x0a] = MPI_BXOR,
    [0x10] = MPI_LAND,
    [0x11] = MPI_LOR,
    [0x12] = MPI_LXOR,
    [0x18] = MPI_MINLOC,
    [0x19] = MPI_MAXLOC,
    [0x1c] = MPI_REPLACE,
    [0x1d] = MPI_NO_OP,
};

MPI_Comm c_comm_table[3] = {            /* ABI 0x100 .. 0x102 */
    [0x00] = MPI_COMM_NULL,
    [0x01] = MPI_COMM_WORLD,
    [0x02] = MPI_COMM_SELF,
};

MPI_Group c_group_table[2] = {          /* ABI 0x108 .. 0x109 */
    [0x00] = MPI_GROUP_NULL,
    [0x01] = MPI_GROUP_EMPTY,
};

MPI_Info c_info_table[1] = {            /* ABI 0x130 */
    [0x00] = MPI_INFO_NULL,
};

MPI_Request c_request_table[1] = {      /* ABI 0x180 */
    [0x00] = MPI_REQUEST_NULL,
};

MPI_Datatype c_datatype_table[256] = {  /* ABI 0x200 .. 0x2ff */
    [0x00] = MPI_DATATYPE_NULL,
    [0x09] = MPI_INT,
    [0x10] = MPI_FLOAT,
    [0x14] = MPI_DOUBLE,
    [0x18] = MPI_LOGICAL,
    [0x19] = MPI_INTEGER,
    [0x1a] = MPI_REAL,
    [0x1c] = MPI_DOUBLE_PRECISION,
    [0x1e] = MPI_CHARACTER,
    [0xd2] = MPI_REAL4,
    [0xda] = MPI_REAL8,
};

/* Integer constants. These are passed to and returned by MPI as plain
 * integers, so their native values differ between implementations. */

int c_MPI_ANY_SOURCE = MPI_ANY_SOURCE;
int c_MPI_ANY_TAG = MPI_ANY_TAG;
int c_MPI_PROC_NULL = MPI_PROC_NULL;
int c_MPI_ROOT = MPI_ROOT;
int c_MPI_UNDEFINED = MPI_UNDEFINED;

int c_MPI_THREAD_SINGLE = MPI_THREAD_SINGLE;
int c_MPI_THREAD_FUNNELED = MPI_THREAD_FUNNELED;
int c_MPI_THREAD_SERIALIZED = MPI_THREAD_SERIALIZED;
int c_MPI_THREAD_MULTIPLE = MPI_THREAD_MULTIPLE;

int c_MPI_COMM_TYPE_SHARED = MPI_COMM_TYPE_SHARED;

int c_MPI_MAX_OBJECT_NAME = MPI_MAX_OBJECT_NAME;

/* Addresses */

void* c_MPI_IN_PLACE = MPI_IN_PLACE;
MPI_Status* c_MPI_STATUSES_IGNORE = MPI_STATUSES_IGNORE;

/* Layout of the native MPI_Status, to convert it to the ABI layout of the
 * Fortran status, and the size of a native handle, to check MPI_HANDLE_KIND. */

int c_sizeof_MPI_Status = sizeof(MPI_Status);
int c_offsetof_MPI_SOURCE = offsetof(MPI_Status, MPI_SOURCE);
int c_offsetof_MPI_TAG = offsetof(MPI_Status, MPI_TAG);
int c_offsetof_MPI_ERROR = offsetof(MPI_Status, MPI_ERROR);

int c_sizeof_MPI_Comm = sizeof(MPI_Comm);
