# Custom MPI Wrapper for Fortran

Welcome to the Custom MPI Wrapper project! This repository contains a Fortran-based implementation of MPI wrappers that bind directly to native MPI library routines using ISO_C_BINDING. The goal is to eliminate intermediate C wrappers and call MPI functions directly from Fortran.

The design and its guiding principles are described in [doc/design.md](doc/design.md).

This project currently supports MPI routines such as `MPI_Init`, `MPI_Bcast`, `MPI_Reduce`, `MPI_Comm_split_type`, `MPI_Recv`, `MPI_Ssend`, `MPI_Waitall`, and more. In addition, the repository provides several tests to verify the correctness of these custom wrappers.


<!-- ## Features

- **Direct MPI Bindings:**  
  Use ISO_C_BINDING to call MPI functions directly without custom C wrappers.

- **Comprehensive Wrappers:**  
  Implements wrappers for various MPI functions (e.g., broadcast, reduction, communicator splitting, synchronous send/receive, wait-all).

- **Status and Request Conversions:**  
  Converts between Fortran integer handles and C pointers for MPI requests, statuses, and other objects.

- **Cross-MPI Compatibility:**  
  Supports both OpenMPI and MPICH. You can build separate conda environments for each MPI implementation. -->
---

## Prerequisites

- **Fortran Compiler:**  
  You can use LFortran, gfortran, or any standard Fortran compiler.

- **MPI Library:**  
  This project supports OpenMPI and MPICH. Native builds require `mpi.h`
  and the matching `mpif.h` constant headers from the same installation.
  The private header module exports constants only; provided builds do not
  use vendor `mpi.mod` or link vendor Fortran MPI implementations.

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

## Runtime-specific modules and native interoperability

Native public handles are ordinary `INTEGER` values equal to the runtime's
`MPI_*_c2f` results. Predefined, created and null handles cross native C
boundaries unchanged, including the `MPI_Comm_f2c` boundary of a parallel-HDF5
shim. Status arrays use the native Fortran representation. The binding, C
consumer and HDF5 must use the same MPI installation.

Use a separate module/build directory for each compiler and MPI installation:

```bash
pixi run -e gfortran-openmpi build-module 'gfortran -cpp' build/gfortran-openmpi
pixi run -e lfortran-mpich build-module '/path/to/lfortran --cpp' build/lfortran-mpich
```

The helper produces `mpi.mod`, `mpi_c_bindings.mod`, `mpi_native_constants.mod`
and four objects: `mpi.o`, `mpi_c_bindings.o`, `mpi_native_constants.o`,
`mpi_constants.o`. Compile clients with only that module directory on their
MPI module search path; link all four objects with the matching C `libmpi`.
Do not add the vendor Fortran module directory to clients' `USE mpi` path.
The standalone and POT3D build paths use the same helper. Test outputs are
isolated under `build/`; untracked source/test files are never removed.

The handle/status/special-rank parameters and supported error classes come
from the selected headers and remain usable in constant expressions before
`MPI_Init`. Error classes, `MPI_SUCCESS` and `MPI_ERR_LASTCODE` use the same
namespace as native error codes. `MPI_Error_class` returns the runtime's class
unchanged; `MPI_Error_string` accepts both detailed codes and class constants
or results. Classify detailed codes (including status errors) before comparing
with `MPI_ERR_*`. `MPI_ERR_LASTCODE` is a bound, not a class to query.

The 64 routine interfaces remain available, but newer error-class names are
exported only when compile-only C and `mpif.h` probes agree they are present.
The helper saves availability and diagnostics under `mpi-constant-checks/`
in the build directory. Missing names are unavailable, never aliases or
invented values. For example, native Open MPI 5.0.11 lacks
`MPI_ERR_ERRHANDLER` and `MPI_ERR_ABI`, while MPICH 5.0.2 supplies both.
Thread, comparison, split and string-capacity conventions are unchanged.

Default `INTEGER` must match 32-bit C `int`/`MPI_Fint`; type-changing modes
such as GNU `-fdefault-integer-8` are rejected. Datatype sizes and logical
representation must also match the MPI installation. Missing or mismatched
constant headers are errors, not a fallback to guessed integers.

`mpich-abi` uses the separate MPI-5 ABI integer serialization and status
layout with `libmpi_abi`. This is **not** native `MPI_Fint` compatibility;
do not mix it with native HDF5/C-MPI libraries.

## Running Tests

The repository contains a collection of standalone tests located in the `tests/` directory. These tests validate the functionality of the custom MPI wrappers.

`native_handle_status_1.f90` is registered with its native C oracle. It checks
native constant expressions, created/null handles, status roundtrips and
ignore/zero-count paths. It applies only to native builds; the ordinary API
tests still run with MPI-ABI.

`error_classes_1.f90` is registered with a same-runtime C oracle for native
and MPI-ABI builds. It checks classes as codes, self-mapping and idempotence,
real detailed errors, and exact C message bytes and lengths, including
permitted queries before initialization and after finalization.

The optional `test-native-hdf5` task accepts a compiler and an unchanged
`vtkhdf_h5_c_shim.c` source file. In a Pixi environment with parallel HDF5 and
matching native MPI, it checks predefined and duplicated communicators through
that shim, including handles returned to `use mpi`. It runs with one rank.
The optional `hdf5-mpich` and `hdf5-openmpi` profiles provide pinned native
dependencies without adding HDF5 to ordinary API-test environments:

```bash
pixi run -e hdf5-mpich test-native-hdf5 '/path/to/compiler' /path/to/vtkhdf_h5_c_shim.c
```

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
