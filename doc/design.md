# Design

fortran_mpi provides the Fortran `mpi` module (`use mpi`) on top of the C MPI
library. It calls the C functions directly through `iso_c_binding`. The vendor's
Fortran bindings are not used, and neither is a C wrapper library.

## Why

A compiled `mpi.mod` only works with the compiler that built it. The Fortran
bindings that Open MPI and MPICH ship were compiled with one compiler, usually
gfortran. LFortran, flang and ifx cannot use them. The C ABI of an MPI library
does not depend on a Fortran compiler. Binding to it makes `use mpi` available
to any Fortran compiler, with any MPI implementation.

## Principles

1. **Drop-in `use mpi`.** Existing MPI programs compile unchanged. The tests
   are written against the MPI standard, not against this library. CI also
   builds them with the vendor's own `mpif90` (`test-without-wrappers`), so a
   test that passes only with our module is a wrong test.

2. **`src/mpi.f90` has no `#ifdef`.** It is the same source for every MPI
   implementation and every platform.

3. **Every constant in `src/mpi.f90` has its MPI-5 ABI value.**
   - Handles, special integers and the status layout all use the values the
     MPI-5 standard ABI defines (MPI 5.0, chapter 21; the values are copied
     from `mpi.h` of [mpi-abi-stubs](https://github.com/mpi-forum/mpi-abi-stubs)).
   - These values are compile-time constants, as the standard requires: user
     code writes `integer, parameter :: ntype = MPI_DOUBLE_PRECISION`. They are
     the same for every implementation.
   - We never write a vendor's value into Fortran source.

4. **The native values come from C.** `src/mpi_constants.c` is compiled
   against the native `<mpi.h>` and tells the Fortran code which value the MPI
   library uses for each constant.
   - It contains no functions, only initialized data, so it works with any MPI
     implementation.
   - It is temporary. Once we link against an MPI-5 ABI library, the native
     values are the ABI values and the file goes away.

5. **Everything vendor-specific is translated at the boundary, in both
   directions.** That covers handles, special integers and statuses. Each value
   that crosses between Fortran and C goes through one translation function
   (`comm_f2c`, `rank_c2f`, `status_c2f`, ...) in `src/mpi.f90`. No wrapper
   converts values inline. A predefined handle is a lookup in a table; nothing
   is translated with a chain of `if`s.

6. **Pure Fortran.** The only C is `src/mpi_constants.c`. Every MPI function
   is called directly from Fortran, through a `bind(C)` interface in
   `src/mpi_c_bindings.f90` that mirrors the C prototype exactly.

7. **At most one `#ifdef`.** `src/mpi_c_bindings.f90` selects the size of a C
   handle: 8 bytes for Open MPI (pointers), 4 for MPICH (`int`). This is the
   only `#ifdef` in the library, and it goes away with the MPI-5 ABI, where a
   handle is always pointer-sized.

8. **Coverage grows with real use.** A routine, or a type/kind/rank variant
   of one, is added when a real code needs it (POT3D, PARALLAX, user
   reports), together with a test.

9. **Verified by running programs.**
   - Every test runs with 1, 2 and 4 ranks.
   - The test matrix covers 2 MPI implementations × 4 compilers (gfortran,
     flang, ifx, LFortran) × 2 OSes, with and without optimization.
   - POT3D is the end-to-end test: its output is compared with reference
     results.

## Files

```
user code:  use mpi
              │
src/mpi.f90             module mpi: the MPI-5 ABI constants, the MPI routines
              │         as generic interfaces, the translation functions
src/mpi_c_bindings.f90  module mpi_c_bindings: bind(C) interfaces to the
              │         C functions, bind(C) views of the tables, MPI_HANDLE_KIND
src/mpi_constants.c     native values of the constants, as tables
              │
libmpi (C), from Open MPI, MPICH or any other implementation
```

## Constants and their translation

The values below are what `src/mpi.f90` uses. "Native" means the value of the
MPI library we link against.

### Predefined handles

These are communicators, groups, datatypes, operations, info and requests.
The ABI gives them small integers:

- `MPI_COMM_WORLD` = 257 (0x101)
- `MPI_INTEGER` = 537 (0x219)
- `MPI_SUM` = 33 (0x021)

Each handle type has a range of values in the ABI. For each type,
`src/mpi_constants.c` has a table over that range, filled with the native
handles by static initializers:

```c
MPI_Comm c_comm_table[3] = {            /* ABI 0x100 .. 0x102 */
    [0x00] = MPI_COMM_NULL,
    [0x01] = MPI_COMM_WORLD,
    [0x02] = MPI_COMM_SELF,
};
```

Fortran sees the table as a `bind(C)` array. The translation looks it up:

```fortran
if (comm >= MPI_COMM_NULL .and. comm <= MPI_COMM_NULL + ubound(c_comm_table, 1)) then
    c_comm = c_comm_table(comm - MPI_COMM_NULL)
else
    c_comm = c_mpi_comm_f2c(comm - USER_HANDLE_OFFSET)
end if
```

The reverse direction (`comm_c2f`) compares the C handle with the few entries
of the table. It is only needed for handles that MPI returns, such as a new
communicator, which may be `MPI_COMM_NULL`. A table entry that `src/mpi.f90`
has no constant for is left zero, which is never a valid handle.

Every constant maps to the native object of the same name. For example,
`MPI_INTEGER` is the library's `MPI_INTEGER`, not the C `MPI_INT`. So the
library's idea of the size of a Fortran type applies. That size was fixed when
the library was built, so the C library must have been built with Fortran
types. Both the conda-forge Open MPI and MPICH packages are.

### Handles that MPI creates

Communicators, groups and requests that MPI creates are converted with the
native `MPI_*_c2f`, and then shifted by `USER_HANDLE_OFFSET` = 4096. On the
way back, the offset is subtracted and the result goes through `MPI_*_f2c`.

The offset is needed because the ABI reserves 1 .. 4095 for predefined
handles, but native Fortran handles are not restricted to that. Open MPI's
native Fortran handles are small indices into its tables: `MPI_REQUEST_NULL`
is 0, and live requests are 1, 2, ... Without the offset, a program with a few
hundred live requests would get the native handle 384, which is
`MPI_REQUEST_NULL` in the ABI. MPICH's are large negative integers, which the
offset does not disturb. `user_handle_c2f` stops the program if a shifted
handle still lands in 1 .. 4095.

### Special integers

These include the wildcards and special ranks (`MPI_ANY_SOURCE`,
`MPI_ANY_TAG`, `MPI_PROC_NULL`, `MPI_ROOT`, `MPI_UNDEFINED`), the thread levels
and `MPI_COMM_TYPE_SHARED`. MPI passes them as plain integers, and every
implementation has its own values:

| constant | ABI | Open MPI | MPICH |
|---|---|---|---|
| `MPI_ANY_SOURCE` | −1 | −1 | −2 |
| `MPI_PROC_NULL` | −3 | −2 | −1 |
| `MPI_THREAD_FUNNELED` | 1024 | 1 | 1 |
| `MPI_COMM_TYPE_SHARED` | 221 | 0 | 1 |

`src/mpi_constants.c` exports the native values (`c_MPI_PROC_NULL`, ...):

- `rank_f2c` and `rank_c2f` translate ranks. Valid ranks are never negative
  and all special ranks are, so the common case costs one comparison.
- `tag_f2c`, `thread_level_f2c`/`thread_level_c2f` and `split_type_f2c`
  translate tags, thread levels and split types.

Every rank or tag that a wrapper passes to C goes through `rank_f2c` or
`tag_f2c`. Every rank that comes back goes through `rank_c2f`: for example the
neighbors from `MPI_Cart_shift`, and `status(MPI_SOURCE)`.

The ABI values differ from both Open MPI and MPICH. So a translation that is
missing fails on both implementations, and the tests catch it. Before, our
values happened to match MPICH, and such bugs only showed with Open MPI.

### Status

The Fortran status has the ABI layout: `MPI_STATUS_SIZE` = 8 integers.
`status(MPI_SOURCE)`, `status(MPI_TAG)` and `status(MPI_ERROR)` are elements
1, 2 and 3, and elements 4 .. 8 hold the rest of the native `MPI_Status`.

- Wrappers receive the native `MPI_Status` into a local buffer of
  `MPI_STATUS_SIZE` C ints.
- `status_c2f` copies it into the Fortran status. It finds the three public
  fields using `offsetof`, which `src/mpi_constants.c` exports, and translates
  the source with `rank_c2f`.
- The native `MPI_Status` is 20 bytes in MPICH and 24 in Open MPI. Both fit.

We do not use the native `MPI_Status_c2f`. It writes the native Fortran
layout: 6 integers for Open MPI, and no rank translation.

### Startup checks

`MPI_Init` and `MPI_Init_thread` first call `check_native_mpi`. It stops the
program with an explanation in two cases:

- `MPI_HANDLE_KIND` does not match the size of a native handle. For example,
  `src/mpi_c_bindings.f90` was compiled without `-DOPEN_MPI` for Open MPI.
  Without this check, handles would be silently truncated.
- The native `MPI_Status` or `MPI_MAX_OBJECT_NAME` does not fit the ABI sizes.

### Adding a constant

1. Add the `integer, parameter` with its ABI value to `src/mpi.f90`.
2. For a predefined handle, add the native handle to its table in
   `src/mpi_constants.c`, at the ABI value minus the start of the range. If
   the range is new, add a table there, its `bind(C)` view in
   `src/mpi_c_bindings.f90`, and `*_f2c`/`*_c2f` functions in `src/mpi.f90`.
3. For a special integer, export the native value from `src/mpi_constants.c`
   and translate it where it is passed or returned.
4. Add or extend a test. `tests/constants_1.f90` checks each predefined
   datatype and communicator by its name (`MPI_Type_get_name`,
   `MPI_Comm_get_name`).

### Adding a routine

1. Add a `bind(C)` interface to `src/mpi_c_bindings.f90` that mirrors the C
   prototype exactly: handles are `integer(kind=MPI_HANDLE_KIND), value`,
   buffers are `type(c_ptr), value`.
2. Add the specific procedure to `src/mpi.f90`, under a generic interface.
   Translate every handle, rank, tag and status, both into and out of the C
   call. `ierror` is optional; if it is absent and the call fails, print the
   error.
3. Add a test in `tests/`. It must also pass with the vendor's `mpif90`.

## Moving to the MPI-5 ABI

MPI 5.0 defines a standard C ABI, `libmpi_abi`, which MPICH already supports.
When we can link against it:

- `MPI_HANDLE_KIND` is `c_intptr_t` everywhere, and the `#ifdef` goes away.
- A predefined C handle is its ABI integer, so the tables become the identity
  and `src/mpi_constants.c` is deleted.
- Handles that MPI creates go through `MPI_*_fromint`/`MPI_*_toint` without
  the offset. The ABI guarantees they are outside 1 .. 4095.
- Ranks, tags and statuses need no translation.

Only the translation functions change, and `src/mpi.f90` keeps its constants.
Two things to check when we get there:

- MPI-5 does not define a Fortran ABI (§21.4), so it does not say that
  `MPI_Comm_toint(MPI_COMM_WORLD)` is 257.
- We need to find which builds of MPICH and Open MPI ship `libmpi_abi`.

## Known deviations

- `MPI_IN_PLACE`, `MPI_STATUS_IGNORE` and `MPI_STATUSES_IGNORE` should be
  recognized by their address, as the standard intends. They are recognized
  by value instead: a buffer whose first element is −1002 is taken as
  `MPI_IN_PLACE`.
- `MPI_Waitall` ignores `array_of_statuses`.
- Error codes returned in `ierror` are the native ones, not translated. Only
  `MPI_SUCCESS` = 0 is the same everywhere.
- Each routine supports only the type/kind/rank variants that real codes have
  needed so far (#64, #138).
