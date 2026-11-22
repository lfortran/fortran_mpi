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
mkdir -p "$1"
cd "$1"
# Replace only our outputs, never clean source trees or vendor modules.
rm -f mpi.o mpi.mod mpi_c_bindings.o mpi_c_bindings.mod \
    mpi_native_constants.o mpi_native_constants.mod mpi_constants.o mpi-prefix mpi-library
printf 'Fortran compiler: %s\nMPI prefix: %s\nMPI library: %s\n' "${FC_COMMAND[*]}" "$PREFIX" "$MPI_LIB"
set -x
"${CC_COMMAND[@]}" "${C_FLAGS[@]}" "${DEFINITIONS[@]}" -std=c11 -I"$PREFIX/include" \
    -c "$ROOT/src/mpi_constants.c" -o mpi_constants.o
"${FC_COMMAND[@]}" "${CPP[@]}" "${DEFINITIONS[@]}" "${HEADER_FLAGS[@]}" \
    -I. -I"$PREFIX/include" -c "$ROOT/src/mpi_native_constants.f90" -o mpi_native_constants.o
# Vendor include directories must NOT be on the USE mpi search path.
"${FC_COMMAND[@]}" "${CPP[@]}" "${DEFINITIONS[@]}" -I. \
    -c "$ROOT/src/mpi_c_bindings.f90" -o mpi_c_bindings.o
"${FC_COMMAND[@]}" -I. -c "$ROOT/src/mpi.f90" -o mpi.o
set +x
printf '%s\n' "$PREFIX" > mpi-prefix
printf '%s\n' "$MPI_LIB" > mpi-library
