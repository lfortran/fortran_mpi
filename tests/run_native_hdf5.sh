#!/bin/bash
set -e

ROOT=$(cd "$(dirname "$0")/.." && pwd)
if [[ $# != 1 || ! -f "$1" ]]; then
    echo "Usage: bash tests/run_native_hdf5.sh <unchanged-vtkhdf_h5_c_shim.c>" >&2
    exit 1
fi
PREFIX=${FORTRAN_MPI_PREFIX:-$CONDA_PREFIX}
if [[ ! -f "$PREFIX/include/hdf5.h" ]]; then
    echo "A Pixi environment with parallel HDF5 and matching native MPI is required." >&2
    exit 1
fi
if [[ -n "${MPI_ABI:-}" || " ${MPI_DEFS:-} " == *"-DMPI_ABI"* ]]; then
    echo "The native MPI_Fint HDF5 shim is not an MPI-5 ABI interface." >&2
    exit 1
fi
SHIM=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
BUILD_DIR="$ROOT/build/${PIXI_ENVIRONMENT_NAME:-manual}/hdf5-$(date +%Y%m%d%H%M%S)-$$"
echo "HDF5 build directory: $BUILD_DIR"
FC=${FC:-$PREFIX/bin/mpif90}
read -r -a FC_COMMAND <<< "$FC"
case "${FC_COMMAND[0]##*/}" in
    *mpif90*|*mpifort*) ;;
    *)
        echo "This preserved raw-MPI_Fint control requires the vendor mpif90/mpifort." >&2
        echo "Provided bindings require a shim using fortran_mpi.h, not native f2c." >&2
        exit 1
        ;;
esac
CC=${CC:-$PREFIX/bin/mpicc}
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"
$CC -std=c11 -I"$PREFIX/include" -DUSE_MPI -c "$SHIM" -o unchanged_shim.o
$CC -std=c11 -I"$PREFIX/include" -c "$ROOT/tests/hdf5/native_hdf5_oracle.c" -o native_hdf5_oracle.o
$FC -I. -c "$ROOT/tests/hdf5/native_hdf5_1.f90" -o native_hdf5_1.o
$FC native_hdf5_1.o \
    native_hdf5_oracle.o unchanged_shim.o -o native_hdf5_1 \
    -L"$PREFIX/lib" -lhdf5 -lmpi -Wl,-rpath,"$PREFIX/lib"
MPIEXEC_ARGS=()
if grep -q 'MPICH_VERSION' "$PREFIX/include/mpi.h"; then
    MPIEXEC_ARGS=(-hosts localhost)
fi
"$PREFIX/bin/mpiexec" -n 1 "${MPIEXEC_ARGS[@]}" ./native_hdf5_1
