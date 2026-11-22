# Design

fortran_mpi provides the Fortran `mpi` module (`use mpi`) on top of the C MPI
library. It calls the C functions directly through `iso_c_binding`. The vendor's
compiled Fortran bindings are not used, and neither is a C wrapper library.
Native builds obtain compile-time constants from the matching vendor `mpif.h`.

## Why

A compiled `mpi.mod` only works with the compiler that built it. The Fortran
bindings that Open MPI and MPICH ship were compiled with one compiler, usually
gfortran. LFortran, flang and ifx cannot use them. The C ABI of an MPI library
does not depend on a Fortran compiler. Binding to it makes `use mpi` available
to other compilers whose default types match the selected MPI configuration.

## Principles

1. **Drop-in `use mpi` for implemented routines and available constants.** The tests
   are written against the MPI standard, not against this library. CI also
   builds them with the vendor's own `mpif90` (`test-without-wrappers`), so a
   test that passes only with our module is a wrong test.

2. **`src/mpi.f90` has no `#ifdef`.** It is the same source for every MPI
   implementation and every platform.

3. **Native integer handles and statuses.** `src/mpi_native_constants.f90`
   includes the matching `mpif.h` in a private module and exports only the
   41 existing handle parameters, four status parameters, five special
   rank/tag/undefined parameters and supported error constants. They remain
   usable in initialization expressions before `MPI_Init`. Values are never
   generated from a running program or copied from observed native IDs. The
   other 13 scalar parameters retain the binding's existing conventions.

4. **C supplies independent metadata.** `src/mpi_constants.c` contains
   initialized data and compile-time assertions, not MPI function wrappers.
   It supplies C storage sizes, Fortran status metadata, address sentinels
   and remaining scalar conversions. Its compact predefined-handle tables
   check header/library agreement after initialization; they do not implement
   a private handle namespace.

5. **Conversions stay at the boundary.** Native public integers equal the
   corresponding `MPI_*_c2f` result. All predefined, created and null handles
   go directly through `MPI_*_f2c`/`MPI_*_c2f`. Native status arrays go through
   `MPI_Status_f2c`/`MPI_Status_c2f`, without repacking or translating their
   words. Non-native scalar conventions use the existing normalization helpers.

6. **Pure Fortran.** The only C is `src/mpi_constants.c`. Every MPI function
   is called directly from Fortran, through a `bind(C)` interface in
   `src/mpi_c_bindings.f90` that mirrors the C prototype exactly.

7. **Backend selection is internal.** `src/mpi_c_bindings.f90` selects:
   - the size of a C handle: 8 bytes for the MPI-5 ABI (`-DMPI_ABI`) and Open
     MPI (`-DOPEN_MPI`), both pointers; 4 for MPICH (`int`);
   - the names of the functions that convert handles between C and
     Fortran integers: `MPI_*_toint`/`MPI_*_fromint` in the ABI,
     `MPI_*_c2f`/`MPI_*_f2c` otherwise.

   Native builds use the vendor's status converters. MPI-5 ABI builds use
   its explicitly specified all-integer status layout instead.
   `src/mpi_native_constants.f90` has a separate MPI-5 ABI constant branch.
   Neither selection changes public routine signatures.

8. **One module procedure per routine.** A buffer is `type(*),
   dimension(..)`, so every routine takes buffers of any type, kind and rank,
   as with the vendors' `mpi` module. Each routine is a plain module
   procedure named after it, such as `MPI_Bcast`; a generic interface is
   only needed for a routine that dispatches on type, such as `MPI_Sizeof`.
   Routines are added when a real code needs them (POT3D, PARALLAX, user
   reports), together with a test.

9. **Verified by running programs.**
   - The standalone API runner retains its 1, 2 and 4-rank matrix. The
     optional native-HDF5 boundary test is separate and runs with one rank.
   - The test matrix covers 3 MPI libraries (Open MPI, MPICH, and MPICH's
     MPI-5 ABI library `libmpi_abi`) × 4 compilers (gfortran, flang, ifx,
     LFortran) × 2 OSes, with and without optimization.
   - POT3D is the end-to-end test: its output is compared with reference
     results.

## Files

```
user code:  use mpi
              │
src/mpi.f90             module mpi: scalar constants, MPI module procedures,
              │         private conversion and storage helpers
src/mpi_native_constants.f90
              │         private vendor-header constants (or MPI-5 ABI constants)
src/mpi_c_bindings.f90  module mpi_c_bindings: bind(C) interfaces to the
              │         C functions, bind(C) views of the tables, MPI_HANDLE_KIND
src/mpi_constants.c     C metadata, scalar tables and startup handle checks
              │
libmpi (C), from Open MPI, MPICH or any other implementation
```

## Dimension constraints

`MPI_Dims_create` takes `dims` as `intent(inout)`: positive entries are input
constraints that remain fixed, while zero entries are computed. A temporary
created for a noncontiguous array section must receive those input values.
On success, the results update only the selected section, not its neighbors.
Check `ierror` before using the returned dimensions. This is a local grid
calculation; `nnodes` need not equal the number of MPI ranks running the program.

## Constants and their translation

Native builds are specific to the MPI installation and Fortran compiler.
Compile the private constants module before `mpi.f90`. The shared
`tools/build_module.sh` does this for the test, standalone and POT3D paths.
Only the private constants module receives the vendor Fortran include
directory and GNU's legacy-header mode or LFortran's `--implicit-interface`.
Those options are not propagated to clients or the MPI procedure module.
Missing `mpif.h` is an unsupported setup, not a reason to guess values or
borrow headers from another installation.

The helper compiles `MPI_SUCCESS` controls and probes for the five newer error
classes in both C and Fortran headers. It rejects disagreement or an unusable
control, and writes only available `PUBLIC` declarations into the build-local
`mpi_optional_error_exports.inc`. This include contains no numeric values.
Diagnostics and availability are saved under `mpi-constant-checks/`.
Neither probing nor compiling the private constant module executes target code
or imports vendor procedures. An absent name stays absent from `use mpi`.

Default `INTEGER`, `integer(c_int)` and the library's `MPI_Fint` must have
matching 32-bit storage. The private module rejects a different default
integer kind, including GNU `-fdefault-integer-8`. Datatype sizes and logical
representation must also match the native library's Fortran configuration.

### Predefined handles

These are communicators, groups, datatypes, operations, info, error handlers
and requests. Each native public parameter has the matching legacy Fortran
header value. Conversion uses that integer directly:

```fortran
c_comm = c_mpi_comm_f2c(comm)
```

The reverse conversion is `c_mpi_comm_c2f(c_comm)`, including null handles.
No public integer range is reserved by this binding.

Every constant maps to the native object of the same name. For example,
`MPI_INTEGER` is the library's `MPI_INTEGER`, not the C `MPI_INT`. So the
library's idea of the size of a Fortran type applies. That size was fixed when
the library was built, so the C library must have been built with Fortran
types. Both the conda-forge Open MPI and MPICH packages are.

### Handles that MPI creates

Created handles use the same native conversions as predefined handles,
without any offset. A native C consumer can pass the public communicator to
`MPI_Comm_f2c`, and a communicator returned through `MPI_Comm_c2f` can be
passed back to this module. This includes the unchanged
`H5Pset_fapl_mpio_Fcomm`/`H5Pget_fapl_mpio_Fcomm` contract when HDF5 and the
binding use the same native MPI installation.

### Special integers

Wildcards and special ranks (`MPI_ANY_SOURCE`, `MPI_ANY_TAG`, `MPI_PROC_NULL`,
`MPI_ROOT`, `MPI_UNDEFINED`) use native values so native status fields can be
compared with them directly. Thread levels, `MPI_COMM_TYPE_SHARED`, comparison
results and string capacities keep the existing MPI-5 ABI
scalar conventions; the private header module is not a wholesale vendor API
reexport.

`src/mpi_constants.c` exports the native values (`c_MPI_PROC_NULL`, ...):

- `rank_f2c` and `rank_c2f` translate ranks. Valid ranks are never negative
  and all special ranks are, so the common case costs one comparison.
- `tag_f2c`/`tag_c2f`, `thread_level_f2c`/`thread_level_c2f` and
  `split_type_f2c` translate tags, thread levels and split types.
- `comparison_c2f` translates the result of `MPI_Comm_compare`.
- `count_c2f` translates a count that MPI returns, which may be
  `MPI_UNDEFINED` (`MPI_Get_count`). `index_c2f` translates an index into an
  array of requests (`MPI_Waitany`): it may be `MPI_UNDEFINED`, and otherwise
  it counts from 0 in C and from 1 in Fortran.

Every rank or tag that a wrapper passes to C goes through `rank_f2c` or
`tag_f2c`. Scalar ranks returned by routines such as `MPI_Cart_shift` go
through `rank_c2f`. Status words are already native and are not rewritten.

### Status

`MPI_STATUS_SIZE`, `MPI_SOURCE`, `MPI_TAG` and `MPI_ERROR` come from the
matching Fortran header. Native converters preserve the complete native
status, including count and cancellation information. The public Fortran
extent does not determine C storage or field offsets.

C scratch is allocated through a direct libc `malloc` binding. A C assertion
checks that `malloc` supports the alignment of `MPI_Status`. Arrays stride
by C `sizeof(MPI_Status)`, independently of the Fortran extent. Every return
path releases its scratch. Allocation overflow/failure returns the native
no-memory code before the operation, leaving requests unchanged. Zero-request
Waitall/Testall calls and ignore paths allocate and convert nothing.
Conversion errors are reported without hiding native operation errors.

`MPI_Waitall` and `MPI_Testall` receive the native statuses into one array, each
`sizeof(MPI_Status)` bytes, and convert them one by one.

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

- Error handlers are native handles:
  `MPI_ERRORS_ARE_FATAL`, `MPI_ERRORS_ABORT`, `MPI_ERRORS_RETURN`.
  `MPI_Comm_set_errhandler` sets one.
- Error codes in `ierror` and defined status error fields, and classes returned
  by `MPI_Error_class`, all belong to the selected C MPI namespace. Native
  builds import classes, `MPI_SUCCESS` and `MPI_ERR_LASTCODE` from the matching
  `mpif.h`; no private numbering or lookup translates them. Detailed codes
  need not equal their classes, so classify before comparing:

  ```fortran
  call MPI_Error_class(ierr, errorclass, query_ierr)
  if (errorclass == MPI_ERR_ROOT) ...
  ```

- Classes are valid error codes: `MPI_Error_class(class)` returns that class.
  `MPI_Error_string` accepts raw codes and class constants or results. Both
  queries are permitted before initialization and after finalization.
  Mixing ABI-numbered classes with native codes is ambiguous when integers
  collide; an input lookup cannot repair that ambiguity.
- `MPI_ERR_LASTCODE` retains the selected header's bound. It is not guaranteed
  to be a valid class or code and is not queried as one.
- The optional MPI-4/5 names are `MPI_ERR_PROC_ABORTED`,
  `MPI_ERR_VALUE_TOO_LARGE`, `MPI_ERR_SESSION`, `MPI_ERR_ERRHANDLER` and
  `MPI_ERR_ABI`. Compile-only C/Fortran header probes select availability,
  never vendor names, version guesses or fallback values. Native Open MPI
  5.0.11 lacks the last two; MPICH 5.0.2 provides all five. This affects
  parameter availability, not routine interfaces or unrelated capabilities.
- MPI-ABI builds use standard ABI class definitions in the private module's
  separate branch, with `mpi_abi.h` and `libmpi_abi`, not native MPICH classes.
  Detailed codes remain implementation-specific within that namespace.
- Status allocation failure returns native `MPI_ERR_NO_MEM` directly,
  without normalization or treating a class as a table index.

The registered `error_classes_1` test checks the common class catalog against
the selected C header, constants as codes, idempotence and class-result strings,
real native/provided detailed errors, and exact C message bytes and lengths.
It never aliases a query's input code with its output error argument.

### Startup checks

`MPI_Init` and `MPI_Init_thread` first check sizes and Fortran status metadata
using C data, without calling native handle converters. They stop if:

- `MPI_HANDLE_KIND` does not match the size of a native handle. For example,
  `src/mpi_c_bindings.f90` was compiled without `-DOPEN_MPI` for Open MPI, or
  without `-DMPI_ABI` for `libmpi_abi`.
  Without this check, handles would be silently truncated.
- Default integer storage differs from C `int`/`MPI_Fint`, or the headers
  disagree on status extent, indices or special ranks/tags.
- A native string capacity exceeds the binding's existing capacity.

After successful initialization, all 41 predefined handle values are checked
against C conversions. Mismatched headers are rejected instead of silently
using foreign or private integers as handles.

### Adding a constant

1. Export a handle/status parameter from the private native-header module
   and add its standard ABI declaration in that module's ABI branch.
   Never copy a native numeric value into the source.
2. Extend the compact C startup table, its `bind(C)` view and the matching
   identity check. Add direct family conversions if needed.
3. For a special integer, export the native value from `src/mpi_constants.c`
   and translate it where it is passed or returned.
4. For an error class, export its native header definition and add its standard
   ABI declaration. Probe optional names in the helper; never invent a native
   fallback or normalize returned classes.
5. Extend the constant-expression/native-C regression and behavior tests.
   Do not export unrelated declarations from the vendor header.

### Adding a routine

1. Add a `bind(C)` interface to `src/mpi_c_bindings.f90` that mirrors the C
   prototype exactly: handles are `integer(kind=MPI_HANDLE_KIND), value`,
   buffers are `type(c_ptr), value`.
2. In `src/mpi.f90`, add one module procedure with the routine's name, e.g.
   `MPI_Bcast`.
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
subroutine MPI_Bcast(buffer, count, datatype, root, comm, ierror)
    use mpi_c_bindings, only: c_mpi_bcast
    type(*), dimension(..), contiguous, target, intent(inout) :: buffer
    integer, intent(in) :: count, datatype, root, comm
    integer, optional, intent(out) :: ierror
    call set_ierror(c_mpi_bcast(c_loc(buffer), count, datatype_f2c(datatype), &
        rank_f2c(root), comm_f2c(comm)), "MPI_Bcast", ierror)
end subroutine MPI_Bcast
```

`type(*), dimension(..)` needs a Fortran 2018 compiler: gfortran, flang,
ifx, or LFortran 0.69 or newer (it needs lfortran/lfortran#16101, #17132
and #17133).

## The MPI-5 ABI

MPI 5.0 defines a standard C ABI (chapter 21). MPICH 5 implements it in a
separate library, `libmpi_abi`, with the header `mpi_abi.h`. The conda-forge
MPICH package ships both; Open MPI 5.0 does not have the ABI yet.

To build against it, compile the modules with `-DMPI_ABI`:
`src/mpi_constants.c` explicitly includes `mpi_abi.h`, and
`src/mpi_c_bindings.f90` selects the ABI's handle size and conversion
functions. Link with `-lmpi_abi` instead of `-lmpi`. The `*-mpich-abi` pixi
environments set `MPI_ABI=yes`, which makes the test and POT3D scripts do
this.

With the ABI:

- A C handle is pointer-sized and predefined handles have their standard
  ABI values. The private module supplies those constants without native
  `mpif.h`. Status storage has the ABI's explicit eight-integer layout,
  checked by C assertions and copied as eight integers.
- Handles that MPI creates are converted with `MPI_*_toint`/`MPI_*_fromint`.
  The ABI library has no `MPI_*_c2f`/`MPI_*_f2c`, because they depend on a
  Fortran ABI, which MPI-5 does not define (§21.4).
- MPI 5.0 section 21.4.5 requires predefined `toint` results to equal the
  ABI constants and created handles to avoid the predefined range. No added
  offset is necessary. Post-initialization startup checks serialize each
  predefined handle before it is used with `fromint`.

`src/mpi.f90` is the same source for all three targets.

This serialization is **not native `MPI_Fint` interoperation**.
`mpi_abi.h` does not provide the native handle/status `f2c`/`c2f` APIs.
Do not link native HDF5/MPI beside `libmpi_abi` to satisfy a native shim.
Use a native MPICH or Open MPI build for that boundary.

## Known deviations

- There are no user-defined error handlers or error classes.
- The buffer of a nonblocking routine must be contiguous; the program stops
  otherwise. With the vendors' `mpi` module, the compiler may pass a
  temporary copy instead, which MPI then uses after it is gone.
