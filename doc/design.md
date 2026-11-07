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
   - Compiled against the MPI-5 ABI header (`mpi_abi.h`), every table is the
     identity and every special integer is its ABI value. The file goes away
     once every MPI library we support has the ABI.

5. **Everything vendor-specific is translated at the boundary, in both
   directions.** That covers handles, special integers and statuses. Each value
   that crosses between Fortran and C goes through one translation function
   (`comm_f2c`, `rank_c2f`, `status_c2f`, ...) in `src/mpi.f90`. No wrapper
   converts values inline. A predefined handle is a lookup in a table; nothing
   is translated with a chain of `if`s.

6. **Pure Fortran.** The only C is `src/mpi_constants.c`. Every MPI function
   is called directly from Fortran, through a `bind(C)` interface in
   `src/mpi_c_bindings.f90` that mirrors the C prototype exactly.

7. **One preprocessor block in the Fortran code.** At the top of
   `src/mpi_c_bindings.f90`, one `#if` block selects, for each of three
   targets:
   - the size of a C handle: 8 bytes for the MPI-5 ABI (`-DMPI_ABI`) and Open
     MPI (`-DOPEN_MPI`), both pointers; 4 for MPICH (`int`);
   - the names of the 9 functions that convert handles between C and
     Fortran integers: `MPI_*_toint`/`MPI_*_fromint` in the ABI,
     `MPI_*_c2f`/`MPI_*_f2c` otherwise.

   The block goes away once every MPI library we support has the ABI.
   `src/mpi_constants.c` uses `#if` only to ask whether the library defines a
   constant at all, for the error classes of MPI 4 and later.

8. **One specific procedure per routine.** A buffer is `type(*),
   dimension(..)`, so every routine takes buffers of any type, kind and rank,
   as with the vendors' `mpi` module. Routines are added when a real code
   needs them (POT3D, PARALLAX, user reports), together with a test.

9. **Verified by running programs.**
   - Every test runs with 1, 2 and 4 ranks.
   - The test matrix covers 3 MPI libraries (Open MPI, MPICH, and MPICH's
     MPI-5 ABI library `libmpi_abi`) × 4 compilers (gfortran, flang, ifx,
     LFortran) × 2 OSes, with and without optimization.
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

`MPI_Waitall` receives the native statuses into one array, each
`sizeof(MPI_Status)` bytes, and converts them one by one.

### `MPI_IN_PLACE`, `MPI_STATUS_IGNORE` and `MPI_STATUSES_IGNORE`

These constants are not values; the standard requires recognizing them by
their address. Values worked badly: a buffer whose first element was -1002
was taken as `MPI_IN_PLACE`.

**`MPI_IN_PLACE`** is an `integer, target` variable.
- Buffers are `type(*)`, so it can be passed for any buffer.
- `in_place_or` compares the address of a buffer argument with the address
  of `MPI_IN_PLACE`, and passes the native `MPI_IN_PLACE` to C if they match.
  Every buffer that the standard allows to be `MPI_IN_PLACE` goes through it.
- No data can be taken for `MPI_IN_PLACE`: another variable never has its
  address.

**`MPI_STATUS_IGNORE` and `MPI_STATUSES_IGNORE`** are integer arrays of the
shape of a status, `(MPI_STATUS_SIZE)`, and of an array of statuses,
`(MPI_STATUS_SIZE, 1)`.
- `is_status_ignore` and `is_statuses_ignore` compare the address of the
  argument with the address of the constant. If they match, the core passes
  the native `MPI_STATUS_IGNORE` or `MPI_STATUSES_IGNORE` to C.
- Status arguments have the `target` attribute and explicit shape, so the
  compiler passes the actual array and does not copy it.
- The addresses are first stored in `c_ptr` variables and then compared:
  LFortran gets `c_associated(c_loc(a), c_loc(b))` wrong.

### Errors

- Error handlers are predefined handles with a table:
  `MPI_ERRORS_ARE_FATAL`, `MPI_ERRORS_ABORT`, `MPI_ERRORS_RETURN`.
  `MPI_Comm_set_errhandler` sets one.
- Error codes, which MPI returns in `ierror`, are left native. They are
  implementation-specific in the MPI-5 ABI too. Only `MPI_SUCCESS` = 0 is a
  fixed code.
- Error classes have their ABI values (`MPI_ERR_ROOT` = 8, ...).
  `MPI_Error_class` translates the native class back to the ABI value through
  the table `c_error_class_table`, so codes are compared with the classes as
  the standard intends:

  ```fortran
  call MPI_Error_class(ierr, errorclass)
  if (errorclass == MPI_ERR_ROOT) ...
  ```

- `MPI_Error_string` takes the native code.

### Startup checks

`MPI_Init` and `MPI_Init_thread` first call `check_native_mpi`. It stops the
program with an explanation in two cases:

- `MPI_HANDLE_KIND` does not match the size of a native handle. For example,
  `src/mpi_c_bindings.f90` was compiled without `-DOPEN_MPI` for Open MPI, or
  without `-DMPI_ABI` for `libmpi_abi`.
  Without this check, handles would be silently truncated.
- The native `MPI_Status`, `MPI_MAX_OBJECT_NAME` or `MPI_MAX_ERROR_STRING`
  does not fit the ABI sizes.

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
2. In `src/mpi.f90`, add one specific procedure, e.g. `MPI_Bcast_proc`,
   under the generic interface `MPI_Bcast`.
   - Each buffer is `type(*), dimension(..), target`, and the C function
     gets `c_loc` of it. A buffer that may be `MPI_IN_PLACE` goes through
     `in_place_or`.
   - A blocking routine declares its buffers `contiguous`. The compiler then
     passes a non-contiguous section as a contiguous copy, and copies it back
     afterwards.
   - A nonblocking routine cannot use a copy, because the transfer outlives
     the call. Its buffers are `asynchronous` instead of `contiguous`, and it
     stops with an error if `is_contiguous` is false. That is the rule of
     the vendors' `mpi` module too.
   - It translates every handle, rank, tag and status, both into and out of
     the C call.
   - It hands the error code to `set_ierror`, which stores it in the optional
     `ierror`, or prints it if `ierror` is absent and the call failed.
3. Add a test in `tests/`. It must also pass with the vendor's `mpif90`.

```fortran
subroutine MPI_Bcast_proc(buffer, count, datatype, root, comm, ierror)
    use mpi_c_bindings, only: c_mpi_bcast
    type(*), dimension(..), contiguous, target, intent(inout) :: buffer
    integer, intent(in) :: count, datatype, root, comm
    integer, optional, intent(out) :: ierror
    call set_ierror(c_mpi_bcast(c_loc(buffer), count, datatype_f2c(datatype), &
        rank_f2c(root), comm_f2c(comm)), "MPI_Bcast", ierror)
end subroutine MPI_Bcast_proc
```

`type(*), dimension(..)` needs a Fortran 2018 compiler: gfortran, flang,
ifx, or an LFortran release newer than 0.68 (it needs lfortran/lfortran#16101,
#17132 and #17133).

## The MPI-5 ABI

MPI 5.0 defines a standard C ABI (chapter 21). MPICH 5 implements it in a
separate library, `libmpi_abi`, with the header `mpi_abi.h`. The conda-forge
MPICH package ships both; Open MPI 5.0 does not have the ABI yet.

To build against it, compile everything with `-DMPI_ABI`: MPICH's `mpi.h`
then includes `mpi_abi.h` for `src/mpi_constants.c`, and
`src/mpi_c_bindings.f90` selects the ABI's handle size and conversion
functions. Link with `-lmpi_abi` instead of `-lmpi`. The `*-mpich-abi` pixi
environments set `MPI_ABI=yes`, which makes the test and POT3D scripts do
this.

With the ABI:

- A C handle is pointer-sized, and a predefined one is its ABI integer
  (`MPI_COMM_WORLD` is `(MPI_Comm)0x101`). The tables in
  `src/mpi_constants.c` come out as the identity, and the special integers
  as their ABI values. So ranks, tags, thread levels and statuses pass
  through the translation functions unchanged.
- Handles that MPI creates are converted with `MPI_*_toint`/`MPI_*_fromint`.
  The ABI library has no `MPI_*_c2f`/`MPI_*_f2c`, because they depend on a
  Fortran ABI, which MPI-5 does not define (§21.4).
- MPICH's `MPI_Comm_toint(MPI_COMM_WORLD)` is 257, the ABI value, although
  the standard does not require it. A user handle is MPICH's usual large
  integer, so `USER_HANDLE_OFFSET` is still added, and it is harmless.

`src/mpi.f90` is the same source for all three targets.

What remains, once Open MPI ships the ABI too:

- Drop `src/mpi_constants.c` and the tables. The translation functions
  become the identity for predefined handles and special integers.
- Drop the `#if` block in `src/mpi_c_bindings.f90`: `MPI_HANDLE_KIND` is
  `c_intptr_t`, and handles convert with `MPI_*_toint`/`MPI_*_fromint`.
- Drop `USER_HANDLE_OFFSET`, if `MPI_*_toint` is guaranteed to keep the
  handles MPI creates outside 1 .. 4095. MPICH's do; the standard only says
  so for the C handles.

## Known deviations

- Error codes are compared with error classes only through
  `MPI_Error_class`. Code that compares `ierror` directly with `MPI_ERR_*`
  works only when the native code equals the ABI class.
- There are no user-defined error handlers or error classes.
- The buffer of a nonblocking routine must be contiguous; the program stops
  otherwise. With the vendors' `mpi` module, the compiler may pass a
  temporary copy instead, which MPI then uses after it is gone.
