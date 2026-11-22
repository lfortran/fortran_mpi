#!/bin/bash
set -eo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
if [[ $# != 1 || -z "${CONDA_PREFIX:-}" ]]; then
    echo "Usage (inside the selected Pixi environment): bash tools/build_module.sh <build-directory>" >&2
    exit 1
fi
PREFIX=$CONDA_PREFIX
if [[ ! -f "$PREFIX/include/mpi.h" ]]; then
    echo "fortran_mpi: matching MPI C headers are missing from $PREFIX/include" >&2
    exit 1
fi

read -r -a FC_COMMAND <<< "${FC:-gfortran}"
read -r -a CC_COMMAND <<< "${CC:-$PREFIX/bin/mpicc}"
read -r -a C_FLAGS <<< "${CFLAGS:-}"
MPI_LIB=mpi
if [[ -n "${MPI_ABI:-}" || " ${MPI_DEFS:-} " == *"-DMPI_ABI"* ]]; then
    DEFINITIONS=(-DMPI_ABI)
    MPI_LIB=mpi_abi
    if [[ ! -f "$PREFIX/include/mpi_abi.h" ]]; then
        echo "fortran_mpi: matching mpi_abi.h is required in $PREFIX/include" >&2
        exit 1
    fi
elif grep -q 'OMPI_MAJOR_VERSION' "$PREFIX/include/mpi.h"; then
    DEFINITIONS=(-DOPEN_MPI)
elif grep -q 'MPICH_VERSION' "$PREFIX/include/mpi.h"; then
    DEFINITIONS=()
else
    echo "fortran_mpi: unsupported MPI C handle representation in $PREFIX/include/mpi.h" >&2
    exit 1
fi
if [[ "$MPI_LIB" == mpi && ! -f "$PREFIX/include/mpif.h" ]]; then
    echo "fortran_mpi: matching mpif.h constant metadata is required in $PREFIX/include" >&2
    exit 1
fi

HEADER_FLAGS=()
case "${FC_COMMAND[0]##*/}" in
    *lfortran*) CPP=(--cpp); HEADER_FLAGS=(--implicit-interface) ;;
    *gfortran*) CPP=(-cpp); HEADER_FLAGS=(-std=legacy) ;;
    *ifx*|*ifort*) CPP=(-fpp) ;;
    *) CPP=(-cpp) ;;
esac
HEADER_INCLUDES=(-I. -I"$ROOT/src" -I"$PREFIX/include")
mkdir -p "$1"
cd "$1"
# Replace only our outputs, never clean source trees or vendor modules.
rm -f mpi.o mpi.mod mpi_c_bindings.o mpi_c_bindings.mod \
    mpi_native_constants.o mpi_native_constants.mod mpi_constants.o mpi-prefix mpi-library \
    mpi_optional_error_exports.inc
printf 'Fortran compiler: %s\nMPI prefix: %s\nMPI library: %s\n' "${FC_COMMAND[*]}" "$PREFIX" "$MPI_LIB"
set -x
"${CC_COMMAND[@]}" "${C_FLAGS[@]}" "${DEFINITIONS[@]}" -std=c11 -I"$PREFIX/include" \
    -c "$ROOT/src/mpi_constants.c" -o mpi_constants.o
if [[ "$MPI_LIB" == mpi ]]; then
    printf '! Optional error classes from matching C and Fortran headers.\n' > mpi_optional_error_exports.inc
    mkdir -p mpi-constant-checks
    printf 'name\tavailable\n' > mpi-constant-checks/availability.tsv
    # Compile-only controls distinguish absent names from a broken setup.
    for name in MPI_SUCCESS MPI_ERR_PROC_ABORTED MPI_ERR_VALUE_TOO_LARGE \
            MPI_ERR_SESSION MPI_ERR_ERRHANDLER MPI_ERR_ABI; do
        printf '#include <mpi.h>\nint mpi_constant_check = %s;\n' "$name" > mpi_constant_check.c
        printf 'module mpi_constant_check\nimplicit none\nprivate\n#include "mpi_native_headers.inc"\n' \
            > mpi_constant_check.f90
        printf 'integer, parameter :: required_constant = %s\nend module\n' "$name" \
            >> mpi_constant_check.f90
        c_status=0
        "${CC_COMMAND[@]}" "${C_FLAGS[@]}" "${DEFINITIONS[@]}" -std=c11 -I"$PREFIX/include" \
            -c mpi_constant_check.c -o mpi_constant_check_c.o \
            > "mpi-constant-checks/$name-c.log" 2>&1 || c_status=$?
        f_status=0
        "${FC_COMMAND[@]}" "${CPP[@]}" "${DEFINITIONS[@]}" "${HEADER_FLAGS[@]}" \
            "${HEADER_INCLUDES[@]}" -c mpi_constant_check.f90 -o mpi_constant_check.o \
            > "mpi-constant-checks/$name-fortran.log" 2>&1 || f_status=$?
        if [[ $c_status -gt 1 || $f_status -gt 1 || \
                ( "$name" == MPI_SUCCESS && ( $c_status != 0 || $f_status != 0 ) ) || \
                $c_status != $f_status ]]; then
            cat "mpi-constant-checks/$name-c.log" "mpi-constant-checks/$name-fortran.log" >&2
            echo "fortran_mpi: inconsistent or unusable C/Fortran constant headers for $name" >&2
            exit 1
        fi
        if [[ $c_status == 0 ]]; then
            printf '%s\tyes\n' "$name" >> mpi-constant-checks/availability.tsv
            if [[ "$name" != MPI_SUCCESS ]]; then
                printf 'public :: %s\n' "$name" >> mpi_optional_error_exports.inc
            fi
        else
            printf '%s\tno\n' "$name" >> mpi-constant-checks/availability.tsv
            echo "fortran_mpi: $name unavailable in selected headers (see mpi-constant-checks/)"
        fi
    done
    rm -f mpi_constant_check.c mpi_constant_check.f90 mpi_constant_check_c.o \
        mpi_constant_check.o mpi_constant_check.mod
fi
"${FC_COMMAND[@]}" "${CPP[@]}" "${DEFINITIONS[@]}" "${HEADER_FLAGS[@]}" \
    "${HEADER_INCLUDES[@]}" -c "$ROOT/src/mpi_native_constants.f90" -o mpi_native_constants.o
# Vendor include directories must NOT be on the USE mpi search path.
"${FC_COMMAND[@]}" "${CPP[@]}" "${DEFINITIONS[@]}" -I. \
    -c "$ROOT/src/mpi_c_bindings.f90" -o mpi_c_bindings.o
"${FC_COMMAND[@]}" -I. -c "$ROOT/src/mpi.f90" -o mpi.o
set +x
printf '%s\n' "$PREFIX" > mpi-prefix
printf '%s\n' "$MPI_LIB" > mpi-library
