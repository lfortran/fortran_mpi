#!/bin/bash
set -ex

POT3D_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$POT3D_DIR/../.." && pwd)
BUILD_DIR="$ROOT/build/${PIXI_ENVIRONMENT_NAME:-manual}/pot3d-$(date +%Y%m%d%H%M%S)-$$"
bash "$ROOT/tools/build_module.sh" "$BUILD_DIR"
cd "$BUILD_DIR"
MPI_LIB=$(cat mpi-library)
$FC -I. -c "$POT3D_DIR/src/psi_io.f90" -o psi_io.o --no-style-suggestions --no-warnings
$FC -I. -c --cpp --implicit-interface "$POT3D_DIR/src/pot3d.F90" -o pot3d.o --no-style-suggestions --no-warnings
$FC mpi_constants.o mpi_native_constants.o mpi_c_bindings.o mpi.o psi_io.o pot3d.o \
  -o pot3d -L"$CONDA_PREFIX/lib" -l"$MPI_LIB" -Wl,-rpath,"$CONDA_PREFIX/lib"
cp pot3d "$POT3D_DIR/bin/"

cd "$POT3D_DIR"
./validate.sh
./validate.sh validation2
