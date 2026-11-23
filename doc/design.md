# Design

fortran_mpi implements `use mpi` using the **C MPI interface**. Ordinary MPI
operations are direct `BIND(C)` calls from Fortran. Small C helpers own handle
conversion, status packing and datatype initialization; they do not wrap the
64 MPI operations. No vendor Fortran headers, modules, conversion routines or
MPI Fortran libraries are required by the provided binding.

## Public contract

The existing routine signatures, buffers and scalar conventions are retained.
Buffers are `type(*), dimension(..)`; blocking routines accept contiguous
temporaries, while nonblocking routines require a contiguous asynchronous
buffer. Each MPI routine has one module procedure. `mpi.f90` has no preprocessor
branches and no compiler-specific lowering.

Public handles are binding-owned default `INTEGER` tokens, with default
`INTEGER` required to match 32-bit C `int`. Predefined handles are constant
expressions, using the MPI-5 ABI predefined IDs in every profile. These are
**not native MPI_Fint values**. Never pass a private token to native
`MPI_Comm_f2c`, or pass native `MPI_Comm_c2f` results to this module.

The same applies to the binding's eight-integer statuses: they are not vendor
Fortran statuses. Mixing this module with vendor Fortran objects or modules
is not an interoperability mechanism.

### Public C communicator adapter

`src/fortran_mpi.h`, also copied to the build output directory, declares:

```c
int fortran_mpi_comm_to_c(int token, MPI_Comm *out);
int fortran_mpi_comm_from_c(MPI_Comm comm, int *out);
```

Both functions return the selected C MPI's error codes, with outputs unchanged
on error. Call them between initialization and finalization of this binding.

- Export borrows the exact live C communicator; it neither duplicates nor
  transfers ownership. A C consumer must not free it behind a live token.
- Import registers an existing live C communicator, without duplication or
  freeing. A successfully imported created communicator must subsequently be
  released through this binding's `MPI_Comm_free`. If import fails, the C
  caller retains responsibility and must clean up its object.
- Null, WORLD and SELF have explicit mappings. Repeated conversions of a live
  object preserve identity. Distinct congruent communicators remain distinct.
- After free, the token must not be used. Tokens/slots may be reused; there is
  no generation-number or persistent stale-token guarantee.

The adapter, provided module, application shim and HDF5 must use **the same C
MPI ABI and runtime**. An HDF5 setter can borrow an exported communicator;
HDF5 duplicates it internally. A getter's newly returned duplicate can be
imported, then freed by the Fortran caller. On failed import the shim must
C-free that duplicate and report failure. It must not pretend the original
raw-native-Fint shim now accepts private tokens.

Native MPI and `mpi_abi.h`/`libmpi_abi` are separate ABIs, even when both were
built by MPICH. Selecting an ABI must be explicit, not inferred from a token.

## Dimension constraints

`MPI_Dims_create` takes `dims` as `intent(inout)`: positive entries are input
constraints that remain fixed, while zero entries are computed. A temporary
created for a noncontiguous array section must receive those input values.
On success, the results update only the selected section, not its neighbors.
Check `ierror` before using the returned dimensions. This is a local grid
calculation; `nnodes` need not equal the number of MPI ranks running the program.

## Files and build artifacts

```
mpi.f90                   public Fortran procedures and scalar normalization
mpi_native_constants.f90  owned handle/status parameters and C error constants
mpi_c_bindings.f90        direct C interfaces and C handle storage width
mpi_constants.c           C tables, sizes, sentinels, owned status packing
mpi_handles.c             typed handle bookkeeping and public communicator adapter
mpi_serializers.c         C toint/fromint provider
mpi_no_serializers.c      fallback provider for runtimes without those functions
mpi_types.c               compiler datatype contract, logical operations, ABI registration
fortran_mpi.h             public C boundary
mpi_internal.h            private C helper interface
```

All entry points use `tools/build_module.sh`. Each build directory contains
`mpi.mod`, `mpi_c_bindings.mod`, `mpi_native_constants.mod`, the public
`fortran_mpi.h` and `libfortran_mpi.a`. Link application objects **before**
the archive, then the matching C MPI library. `mpi-prefix` and `mpi-library`
record that selection. Only the provided module directory goes on a client's
`USE mpi` search path.

By default the MPI prefix is the active Pixi environment's `CONDA_PREFIX`.
`FORTRAN_MPI_PREFIX=/absolute/prefix` selects an external C-only installation,
including its headers, library and launcher, without replacing the compiler
environment. `MPI_ABI=yes` selects the existing ABI profile. `CC` is the C
compiler or MPI C wrapper; Fortran never receives vendor include paths.
Do not copy module files between compilers or builds.

There is no `find_package(fortran_mpi)` package. A consumer can define an
imported static-library/interface target with the archive path, its module/
header include directory, and the matching `MPI::MPI_C` dependency. ABI
consumers also define `MPI_ABI` when including the public header.

## The MPI-5 ABI

The existing `*-mpich-abi` Pixi profiles select `mpi_abi.h` and `libmpi_abi`
with `MPI_ABI=yes`/`-DMPI_ABI`, rather than the native header/library.
The low-level Fortran interfaces use pointer-sized C handle storage in this
profile. Canonical serialization, status layout and error constants remain
separate from native MPICH; `mpi.f90` is shared unchanged between profiles.
See the handle and datatype sections below for initialization and lifetime.

## Handle conversion and lifetime

The C predefined tables supply real typed `MPI_Comm`, `MPI_Group`,
`MPI_Request`, `MPI_Datatype`, `MPI_Op`, `MPI_Info` and `MPI_Errhandler` objects.
No pointer is truncated into a Fortran token.

The build compiles and links all seven C `*_toint`/`*_fromint` pairs to select
the serialization provider. It does not infer availability from MPI_VERSION.
In native MPICH these serialize native integer values, not canonical ABI
predefined IDs. Predefined handles always use the binding's tables. A dynamic
serialization is used only after a roundtrip check, outside the reserved
0..4095 range, with explicit collision handling. Otherwise the typed map
supplies the token. No `c2f + 4096` arithmetic remains.

Open MPI installations without these pairs use the same small typed-object
map without invoking serializers. In MPI-ABI mode the canonical predefined
serializations are checked/registered before any `fromint`, and dynamic
serializations are preserved where possible.

The map grows with the high-water mark of simultaneously live objects,
reuses retired slots and is released on finalization. It reserves a slot
**before** a creating MPI call, so allocation failure cannot lose a new
communicator or an active request. A failed operation releases the reservation
without reading an undefined output; a failed registration cleans up the new
object. Public C import is different: failure leaves the object with its caller.

Successful frees and completions retire entries. Wait/Test arrays update every
request, preserving incomplete ones and retiring only those that became null.
Updates compare stored typed values and never call `fromint` on an object that
the preceding MPI call may already have freed. Immutable predefined entries,
including `MPI_GROUP_EMPTY`, are not retired when a local variable is freed.
Separate creating calls that return the same reference-counted C group or
completed request retain their acquisitions until each is released; repeated
imports alone do not add acquisitions.

Registry synchronization is local and short-lived. No lock spans a blocking
MPI operation or cleanup call. `MPI_Init_thread` still requests and reports
the runtime's actual support level; the registry does not weaken it.

## C-only datatype policy

The binding validates the selected compiler, not a vendor Fortran build.
Default integer, real, double precision, integer(8), double complex and
character kinds must match the corresponding ISO_C_BINDING kinds. Numeric
radix, digits, exponent ranges, storage and C MPI datatype sizes/extents are
checked at initialization. The supported numeric model is 32-bit C integer,
32-bit real and 64-bit double/integer(8), with interoperable double complex.
Type-changing flags that violate this contract are rejected, not guessed.

Native profiles use matching C predefined numeric datatypes. For example,
the public `MPI_REAL4` uses C `MPI_FLOAT`, even in a genuine C-only Open MPI
build where the vendor's `MPI_REAL4` name is absent. Public Fortran datatype
names remain distinct and `MPI_Type_get_name` returns their binding names.
This is not a claim that vendor Fortran datatype handles are interchangeable.

Default LOGICAL is **not** aliased to one-byte `MPI_C_BOOL`. Its exact true and
false byte patterns come from the selected compiler. Native profiles transmit
its 1/2/4/8-byte storage with the corresponding C integer type and use three
small user operations for LAND/LOR/LXOR. These operations produce those exact
literal patterns and work with the existing direct collective calls, including
in-place and scan variants. Other logical reductions are rejected.

MPI-ABI profiles retain the ABI's Fortran datatypes. Initialization queries
`MPI_Abi_get_fortran_info` and `MPI_Abi_get_fortran_booleans`; it supplies the
selected compiler's properties only when unregistered. Existing registration
must agree for the exposed types and booleans. It is never blindly overwritten.
The MPI-5 type-registration interface allows this path to use a C-only runtime.

## Constants and errors

Native error-class parameters are emitted from the selected **C header** by a
small scalar program, without `MPI_Init` or handle conversion. The output is
an owned Fortran include compiled into the private constants module.
Optional-name probes are C compile checks with a required MPI_SUCCESS control.
Their diagnostics/availability live under `mpi-constant-checks/`. Missing names
stay unavailable; no numeric aliases are invented. The ABI profile retains
its specified error parameters.

The emitter is target code. Native builds execute it directly; cross builds
must supply `FORTRAN_MPI_TARGET_RUNNER` when target code cannot run locally.
Execution failure is an error, never a fallback to host constants. All public
parameters remain usable in constant expressions before initialization.

Error codes, classes and defined status error fields are in one selected C MPI
domain. `MPI_Error_class` returns its result unchanged; `MPI_Error_string`
accepts both detailed codes and class constants/results and preserves C message
bytes and length. Classify detailed errors before comparing them with classes.
`MPI_ERR_LASTCODE` remains a bound, not a class to query. Error queries before
initialization and after finalization do not need the handle registry.

## Statuses, scalars and sentinels

`MPI_STATUS_SIZE=8`, `MPI_SOURCE=1`, `MPI_TAG=2`, `MPI_ERROR=3` are binding-owned
parameters. Native packing places public fields first and packs the remaining
C status bytes, including count/cancellation data, in the remaining words.
`sizeof`/`offsetof` checks reject C layouts that do not fit. Source/tag are
normalized in both directions; error codes are not. MPI-ABI retains its
specified direct eight-integer layout.

Native C scratch uses aligned `malloc` storage, sized/strided by
`sizeof(MPI_Status)`, not by a vendor Fortran status extent. Allocation is
overflow-checked and every path releases its scratch. Ignore and zero-count
paths do not allocate or pack statuses. This change does not alter which
completion errors make statuses defined.

Ranks, tags, undefined counts, comparison results, thread levels and split
types use the existing scalar translation helpers. Request indices are
translated from C's zero-based indices to Fortran's one-based indices.

`MPI_IN_PLACE`, `MPI_STATUS_IGNORE` and `MPI_STATUSES_IGNORE` are binding-owned
target objects recognized by address, never by their contents. C receives its
own corresponding sentinel addresses.

## Regression coverage

The normal/optimized profile matrix, POT3D and 1/2/4-rank selections are retained.
Standard Fortran tests also run with vendor `mpif90`.

- `adapter_lifecycle_1` checks both directions of the explicit C boundary,
  predefined/null and created/imported identity, retirement and repeated reuse.
- `owned_handle_status_1` checks group/datatype/request lifetimes, incomplete
  Test, Wait/Test arrays, owned statuses/counts and untouched guard words.
- `logical_representation_1` checks exact literal patterns for all three
  logical operations, in-place reductions, integer(8) and double complex.
- Existing error-class/oracle, datatype, group, request and sentinel tests
  remain registered.
- `test-constant-headers` poisons every vendor Fortran header name and checks
  the archive for forbidden handle/status conversion dependencies. It runs
  the scalar constant emitter but no MPI program.

The unchanged `native_handle_status_1` and raw-HDF5 fixture remain **vendor
controls**, not provided-mode claims. Provided HDF5 applications must use the
public adapter; their application-level qualification is separate from these
standalone tests.

## Extending the binding

For a new routine:

1. Add its exact C prototype as a `BIND(C)` interface in `mpi_c_bindings.f90`.
   C handles use `integer(kind=MPI_HANDLE_KIND), value`; buffers use
   `type(c_ptr), value`.
2. Add one module procedure in `mpi.f90`. Buffers use `type(*), dimension(..),
   target`; blocking calls add `contiguous`, and nonblocking calls add
   `asynchronous` and reject noncontiguous actuals.
3. Validate input tokens before entering C. For a newly returned object,
   reserve storage before the MPI call and save the result only on success.
   For an inout/free/completion handle, update its existing mapping instead.
4. Translate ranks/tags/statuses in both directions, recognize allowed
   in-place/ignore sentinels by address, and pass native errors to `set_ierror`.
5. Add a standard Fortran test under `tests/`, runnable with vendor `mpif90`.
   Adapter-specific tests additionally have an explicit provided-only branch.

For a new constant, add its owned predefined ID and typed C table entry,
or extend the C scalar emitter and optional-name probe for an error class.
Never copy observed native handle numbers or normalize error classes into
a second domain. Add constant-expression and behavior tests.

Assumed-type/assumed-rank buffers require a Fortran 2018 compiler: gfortran,
flang, ifx, or LFortran 0.69 or newer (including lfortran/lfortran#16101,
#17132 and #17133).

## Known deviations

- There are no user-defined error handlers or error classes.
- A noncontiguous buffer for a nonblocking routine is rejected rather than
  passed through a temporary whose lifetime ends before completion.
