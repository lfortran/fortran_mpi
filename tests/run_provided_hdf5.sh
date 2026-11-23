#!/bin/bash
set -eo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PREFIX=${FORTRAN_MPI_PREFIX:-${CONDA_PREFIX:?Run in the selected Pixi environment}}
HDF5_PREFIX=${FORTRAN_MPI_HDF5_PREFIX:-$PREFIX}
if [[ -n "${MPI_ABI:-}" || " ${MPI_DEFS:-} " == *"-DMPI_ABI"* ]]; then
    echo "Provided HDF5 requires native libmpi, not libmpi_abi." >&2
    exit 1
fi
if [[ ! -f "$PREFIX/include/mpi.h" || ! -f "$HDF5_PREFIX/include/hdf5.h" ]]; then
    echo "Matching native C MPI and parallel HDF5 prefixes are required." >&2
    exit 1
fi
PREFIX=$(cd "$PREFIX" && pwd)
HDF5_PREFIX=$(cd "$HDF5_PREFIX" && pwd)
read -r -a FC_COMMAND <<< "${FC:?Pass the provided Fortran compiler explicitly}"
case "${FC_COMMAND[0]##*/}" in
    *mpif90*|*mpifort*)
        echo "This is a provided-module test, not the vendor-wrapper control." >&2
        exit 1 ;;
esac
read -r -a CC_COMMAND <<< "${CC:-$PREFIX/bin/mpicc}"
read -r -a C_FLAGS <<< "${CFLAGS:-}"
BUILD_DIR="$ROOT/build/${PIXI_ENVIRONMENT_NAME:-manual}/provided-hdf5-$(date +%Y%m%d%H%M%S)-$$"
mkdir -p "$BUILD_DIR"
echo "Provided HDF5 build directory: $BUILD_DIR"
echo "MPI prefix: $PREFIX"
echo "HDF5 prefix: $HDF5_PREFIX"
cd "$BUILD_DIR"
bash "$ROOT/tools/build_module.sh" .
[[ $(cat mpi-prefix) == "$PREFIX" && $(cat mpi-library) == mpi ]]
"${CC_COMMAND[@]}" "${C_FLAGS[@]}" -std=c11 -I. -I"$PREFIX/include" -I"$HDF5_PREFIX/include" \
    -c "$ROOT/tests/hdf5/provided_hdf5_oracle.c" -o provided_hdf5_oracle.o
"${FC_COMMAND[@]}" -I. -c "$ROOT/tests/hdf5/provided_hdf5_1.f90" -o provided_hdf5_1.o
"${FC_COMMAND[@]}" provided_hdf5_1.o provided_hdf5_oracle.o libfortran_mpi.a \
    -L"$PREFIX/lib" -L"$HDF5_PREFIX/lib" -lhdf5 -lmpi \
    -Wl,-rpath,"$PREFIX/lib" -Wl,-rpath,"$HDF5_PREFIX/lib" -o provided_hdf5_1
MPIEXEC_ARGS=()
if grep -q 'MPICH_VERSION' "$PREFIX/include/mpi.h"; then
    MPIEXEC_ARGS=(-hosts localhost)
fi
status=0
"$PREFIX/bin/mpiexec" -n 1 "${MPIEXEC_ARGS[@]}" ./provided_hdf5_1 > provided_hdf5_1.log 2>&1 || status=$?
cat provided_hdf5_1.log
if [[ $status != 0 ]]; then exit "$status"; fi
[[ $(grep -c '^[[:space:]]*provided_hdf5_1: OK[[:space:]]*$' provided_hdf5_1.log) == 1 ]]
