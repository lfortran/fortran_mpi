#!/bin/bash
set -eo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
if [[ $# != 1 || -z "${CONDA_PREFIX:-}" ]]; then
    echo "Usage (inside an Open MPI Pixi environment): bash tests/check_constant_headers.sh <build-directory>" >&2
    exit 1
fi
if ! grep -q 'OMPI_MAJOR_VERSION' "$CONDA_PREFIX/include/mpi.h" || \
        [[ -n "${MPI_ABI:-}" ]]; then
    echo "This compile-only regression requires native Open MPI." >&2
    exit 1
fi

mkdir -p "$1"
cd "$1"
HEADER_DIR="$PWD/headers"
mkdir -p "$HEADER_DIR"
# Keep the selected installation's include chain and constants unchanged,
# but make its unneeded procedure header unusable on every compiler.
cp "$CONDA_PREFIX/include/mpif.h" "$HEADER_DIR/"
cp "$ROOT/tests/headers/openmpi/mpif-sizeof.inc" "$HEADER_DIR/mpif-sizeof.h"
FC="${FC:-gfortran} -I$HEADER_DIR" bash "$ROOT/tools/build_module.sh" "$PWD/module"
echo "Constant-header probes and modules compile without vendor procedure headers."
