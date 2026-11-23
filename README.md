# Custom MPI Wrapper for Fortran

This project provides `use mpi` through direct ISO_C_BINDING calls to the C
MPI library. Small C helpers own handle conversion, status packing and
datatype initialization; ordinary MPI operations do not have C wrappers.
The provided binding requires no vendor Fortran headers, modules or libraries.

The design and its guiding principles are described in [doc/design.md](doc/design.md).

This project currently supports MPI routines such as `MPI_Init`, `MPI_Bcast`, `MPI_Reduce`, `MPI_Comm_split_type`, `MPI_Recv`, `MPI_Ssend`, `MPI_Waitall`, and more. In addition, the repository provides several tests to verify the correctness of these custom wrappers.


---

## Prerequisites

- **Fortran Compiler:**  
  You can use LFortran, gfortran, or any standard Fortran compiler.

- **MPI Library:**  
  Open MPI or MPICH's C headers and C library, including C-only installations.
  The separate MPI-5 ABI profiles use `mpi_abi.h` and `libmpi_abi`. Vendor
  Fortran packages are used only by the independent `mpif90` controls.

- **Pixi (Optional):**  
  [pixi](https://pixi.sh) provides an environment `<compiler>-<mpi>` for each
  compiler (`gfortran`, `lfortran`, and on Linux also `flang` and `ifx`) and
  MPI (`openmpi`, `mpich`, and `mpich-abi` for MPICH's MPI-5 standard ABI
  library `libmpi_abi`), the same ones the CI uses. The compiler is passed
  to the task:
    ```bash
    pixi run -e lfortran-mpich test 'lfortran --cpp'
    pixi run -e gfortran-openmpi test 'gfortran -cpp -O3 -march=native'
    pixi run -e gfortran-openmpi test-without-wrappers
    pixi run -e flang-mpich test 'flang -cpp'
    pixi run -e gfortran-mpich pot3d 'gfortran -cpp'
    pixi run -e lfortran-openmpi pot3d-lfortran 'lfortran --cpp'
    pixi run -e gfortran-mpich-abi test 'gfortran -cpp'
    ```
  With Open MPI, pixi also passes `-DOPEN_MPI=yes` to the compiler, and with
  `mpich-abi` it passes `-DMPI_ABI` and links `libmpi_abi` (see
  [doc/design.md](doc/design.md#the-mpi-5-abi)). POT3D
  with flang or ifx needs a larger stack, `ulimit -s unlimited`.

---

## Runtime-specific modules and the explicit C boundary

Public handles are binding-owned `INTEGER(C_INT)` tokens, not native
`MPI_Fint` values. Statuses use an owned eight-integer representation.
An unchanged shim that calls native `MPI_Comm_f2c` on such a token remains
unsupported. Use the public `fortran_mpi.h` adapter instead:

```c
int fortran_mpi_comm_to_c(int token, MPI_Comm *out);
int fortran_mpi_comm_from_c(MPI_Comm comm, int *out);
```

Conversion neither duplicates nor frees. Export borrows a live communicator;
do not free it through C behind a live token. After successful import of a
created communicator, release it through this binding's `MPI_Comm_free`.
On import failure the C caller still owns it and must clean up. Null/WORLD/
SELF map explicitly, and repeated imports preserve live identity. Freed tokens
must not be used; they may be reused. Both functions return native C MPI errors
and leave the output unchanged on error.

The adapter, module, C consumer and HDF5 must share one C MPI ABI/runtime.
For example, an HDF5 setter borrows an exported communicator; a getter imports
the duplicate it returns. If import fails, the shim must free that duplicate
and report failure rather than return apparent success.

Use a separate module/build directory for each compiler and MPI installation:

```bash
pixi run -e gfortran-openmpi build-module 'gfortran -cpp' build/gfortran-openmpi
pixi run -e lfortran-mpich build-module '/path/to/lfortran --cpp' build/lfortran-mpich
```

The helper produces `mpi.mod`, `mpi_c_bindings.mod`, `mpi_native_constants.mod`,
`fortran_mpi.h` and `libfortran_mpi.a`. Compile clients with only that module
directory on their MPI module search path; link client objects, then the
archive, then the matching C MPI library.
Do not add the vendor Fortran module directory to clients' `USE mpi` path.
The standalone and POT3D build paths use the same helper. Test outputs are
isolated under `build/`; untracked source/test files are never removed.

C sources use `CC` from the activated environment, or its `mpicc` when `CC`
is unset. The Linux Flang/LFortran profiles explicitly provide the GCC
toolchain required by the packaged MPI wrappers. To override the C compiler,
set `CC` inside the activated environment; MPI headers and libraries still
come from the selected `CONDA_PREFIX`, or an explicit
`FORTRAN_MPI_PREFIX=/absolute/external/prefix`. The test/run launchers use that
same prefix. This permits testing actual Fortran-disabled MPI installations
without changing the compiler profile.

For CMake consumers, use an explicit imported archive/interface target with
the output directory as its module/header include directory and the matching
`MPI::MPI_C` dependency. There is no `find_package(fortran_mpi)` package.
The files `mpi-prefix` and `mpi-library` record the selected build inputs.

Handle/status/special-rank parameters are binding-owned and remain usable in
constant expressions before `MPI_Init`. Native error constants are generated
from the selected **C header** by a scalar emitter that does not initialize MPI.
Cross builds must explicitly provide `FORTRAN_MPI_TARGET_RUNNER` if target
executables cannot run locally; host constants are never substituted.
Error classes, `MPI_SUCCESS` and `MPI_ERR_LASTCODE` use the same
namespace as native error codes. `MPI_Error_class` returns the runtime's class
unchanged; `MPI_Error_string` accepts both detailed codes and class constants
or results. Classify detailed codes (including status errors) before comparing
with `MPI_ERR_*`. `MPI_ERR_LASTCODE` is a bound, not a class to query.

The 64 routine interfaces remain available, but newer error-class names are
exported only when C compile probes establish they are present.
The helper saves availability and diagnostics under `mpi-constant-checks/`
in the build directory. Missing names are unavailable, never aliases or
invented values. For example, native Open MPI 5.0.11 lacks
`MPI_ERR_ERRHANDLER` and `MPI_ERR_ABI`, while MPICH 5.0.2 supplies both.
Thread, comparison, split and string-capacity conventions are unchanged.

Default `INTEGER` must match 32-bit C `int`; GNU `-fdefault-integer-8` is rejected.
The selected compiler's ISO_C_BINDING kinds and numeric model are checked.
Native profiles use matching C numeric datatypes; LOGICAL uses its observed
storage and exact literal patterns with narrow LAND/LOR/LXOR operations, not
one-byte `MPI_C_BOOL`. MPI-ABI profiles register the selected Fortran type and
boolean properties through C when absent, and check existing registration
without overwriting it. See [the datatype contract](doc/design.md#c-only-datatype-policy).

`mpich-abi` uses the separate MPI-5 ABI integer serialization and status
layout with `libmpi_abi`. C consumers define `MPI_ABI` when including
`fortran_mpi.h`. Do not mix this profile with native HDF5/C-MPI libraries.

## Running Tests

The repository contains a collection of standalone tests located in the `tests/` directory. These tests validate the functionality of the custom MPI wrappers.

`adapter_lifecycle_1.f90` and its C oracle check the explicit boundary for
predefined, null, created and imported communicators, live identity and reuse.
`owned_handle_status_1.f90` exercises group/type/request retirement, incomplete
Test, Wait/Test arrays and owned status/count roundtrips.
`logical_representation_1.f90` checks exact logical patterns and numeric payloads.
The unchanged `native_handle_status_1.f90` remains a vendor-module control for
the old raw-native contract; it is not a provided-mode compatibility claim.
Vendor runs exclude both binding-owned lifecycle/status tests, but retain
`native_handle_status_1` and `logical_representation_1`. `run_tests.sh --list-tests`
(optionally with `--without-wrappers`) reports that same selection without
building or launching MPI. Ordinary tests still run at 1, 2 and 4 ranks.

`error_classes_1.f90` is registered with a same-runtime C oracle for native
and MPI-ABI builds. It checks classes as codes, self-mapping and idempotence,
real detailed errors, and exact C message bytes and lengths, including
permitted queries before initialization and after finalization.

`test-constant-headers` poisons every vendor Fortran header name and checks that
the built archive has no vendor handle/status conversion dependencies. It
applies to native and MPI-ABI profiles. The scalar emitter executes, but no
MPI program runs:

```bash
pixi run -e gfortran-openmpi test-constant-headers 'gfortran -cpp' build/gfortran-openmpi/header-check
```

The optional `test-native-hdf5` task accepts a compiler and an unchanged
`vtkhdf_h5_c_shim.c` source file. It is the preserved **vendor-module** control,
requiring the vendor `mpif90`/`mpifort`, not this provided module. It runs with
one rank. Provided-mode HDF5 applications must adapt their shim explicitly;
the original raw-Fint assumption has not become valid.
The optional `hdf5-mpich` and `hdf5-openmpi` profiles provide pinned native
dependencies without adding HDF5 to ordinary API-test environments:

```bash
pixi run -e hdf5-mpich test-native-hdf5 'mpif90' /path/to/vtkhdf_h5_c_shim.c
```

`test-provided-hdf5` is the separate, self-contained public-adapter capability
test used by CI for GNU/LFortran and both native MPI implementations. It
builds the provided module and C client against one matching native MPI core,
never a vendor Fortran module or `libmpi_abi`. At one rank it checks WORLD and
a duplicate, HDF5 setter/getter and MPIO driver, reverse token identity,
congruence, size, barrier and exactly-once release through the binding.
It also checks invalid setter/getter inputs and cleanup after a deliberately
failed import (a real adapter argument error, not allocation-failure coverage).
The C oracle observes communicator destruction with a noncopying attribute
and its delete callback, without intercepting MPI symbols or linking PMPI.
This small client does not substitute for testing an application's adapted shim.

```bash
pixi run --locked -e hdf5-mpich test-provided-hdf5 'gfortran -cpp'
pixi run --locked -e hdf5-openmpi test-provided-hdf5 '/path/to/lfortran --cpp'
```

For an external C-only stack, set `FORTRAN_MPI_PREFIX` to its MPI installation
and `FORTRAN_MPI_HDF5_PREFIX` to the parallel HDF5 installation built against
that exact core. Without the latter, HDF5 comes from the MPI prefix.

`test-abort` separately registers `tests/abort/abort_1.f90`; intentional failure
must not enter the ordinary success-only glob. It checks a dynamically
duplicated communicator with a C adapter oracle, all rank-readiness records,
the runtime's diagnostic for the requested abort argument 73, nonzero launcher
completion and **no return from MPI_Abort**. MPI-5.0 section 12.4.2 makes exit-code
propagation optional: neither exit 73 nor equal C/provided launcher statuses
are required. The actual statuses are recorded independently.
A native C control using the same MPI library runs alongside it at each of
1, 2 and 4 ranks. Each launch has a 60-second timeout plus a 10-second kill
grace. A helper records the launcher status separately from the watchdog and
returns zero only after writing that record. Timeout/signal diagnostics,
watchdog/helper failures and missing status records are rejected, not counted
as MPI aborts. Full native output, launcher `.log.exit`, watchdog
`.log.watchdog`/`.log.watchdog.exit`, and supervision `.log.reason` records
remain in the unique build directory.
Set `FORTRAN_MPI_TIMEOUT` to a GNU `timeout` executable when it is not on PATH.

```bash
pixi run --locked -e gfortran-openmpi test-abort 'gfortran -cpp'
```

MPICH 5.0.2 can return success before Hydra terminates ranks
(pmodels/mpich#7716; lfortran/lfortran#18448). The abort task reports the native
control separately and **fails**, rather than treating that runtime race as
a binding regression or an expected pass. CI therefore qualifies strict abort
on Linux Open MPI; MPICH's ordinary successful suite alone exercises at most
63 of the 64 routines. Corrected/C-only MPICH qualification must run this same
strict task successfully; merely finding an abort call in a failure branch
does not establish coverage.

### Running All Standalone Tests

To execute **all** standalone tests, navigate to the `tests/` directory and run:

```bash
cd tests/
FC='lfortran --cpp' ./run_tests.sh
```

or, to run them with GFortran compiler, do:

```bash
cd tests/
FC='gfortran -cpp' ./run_tests.sh
```

### Running a Specific Standalone Test

If you want to run a single test (for example, `test_filename.f90`), execute:

```bash
cd tests/
FC='lfortran --cpp' ./run_tests.sh test_filename.f90
```

or, to run it with GFortran compiler, do:

```bash
cd tests/
FC='gfortran -cpp' ./run_tests.sh test_filename.f90
```

### Running the `pot3d` Test

To build and run the `pot3d` test, navigate to the `tests/pot3d/` directory.

- For LFortran run:

```bash
cd tests/pot3d/
FC='lfortran --cpp' ./build_and_run_lfortran.sh
```

- For GFortran run:

```bash
cd tests/pot3d/
FC='gfortran -cpp' ./build_and_run_gfortran.sh
```

---

## Customizing Compiler Flags

You can pass custom flags to your Fortran compiler using the `FC` environment variable. For example, to compile with optimization flags using gfortran, run:

```bash
FC='gfortran -cpp -O3' ./run_tests.sh
```

This enables you to tailor the compilation process to your needs.
