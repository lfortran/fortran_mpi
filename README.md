# Custom MPI Wrapper for Fortran

Welcome to the Custom MPI Wrapper project! This repository contains a Fortran-based implementation of MPI wrappers that bind directly to native MPI library routines using ISO_C_BINDING. The goal is to eliminate intermediate C wrappers and call MPI functions directly from Fortran.

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
  This project supports OpenMPI and MPICH. Install the desired MPI library along with its development headers.

- **Conda Environment (Optional):**  
  It is recommended to create separate conda environments for MPICH and OpenMPI:
  - For **MPICH**:
    ```bash
    conda create -n mpich_env mpich=4.3.0
    conda activate mpich_env
    ```
  - For **OpenMPI**:
    ```bash
    conda create -n openmpi_env openmpi=5.0.6
    conda activate openmpi_env
    ```

---

## Running Tests

The repository contains a collection of standalone tests located in the `tests/` directory. These tests validate the functionality of the custom MPI wrappers.

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
