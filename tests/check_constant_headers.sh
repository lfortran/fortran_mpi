#!/bin/bash
set -eo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
if [[ $# != 1 || -z "${CONDA_PREFIX:-}" ]]; then
    echo "Usage (inside the selected Pixi environment): bash tests/check_constant_headers.sh <build-directory>" >&2
    exit 1
fi
mkdir -p "$1"
cd "$1"
HEADER_DIR="$PWD/headers"
mkdir -p "$HEADER_DIR"
for header in mpif.h mpif-config.h mpif-constants.h mpif-handles.h mpif-sizeof.h \
        mpif-io-constants.h mpif-io-handles.h mpif-externals.h mpif-sentinels.h mpi_fortran.h; do
    printf '#error vendor Fortran headers must not be used by fortran_mpi\n' > "$HEADER_DIR/$header"
done
FC="${FC:-gfortran} -I$HEADER_DIR" CFLAGS="${CFLAGS:-} -I$HEADER_DIR" \
    bash "$ROOT/tools/build_module.sh" "$PWD/module"
nm -u module/libfortran_mpi.a > undefined-symbols.log
if grep -E 'MPI_(Comm|Group|Request|Type|Op|Info|Errhandler|Status)_[fc]2[cf]' undefined-symbols.log; then
    echo "fortran_mpi: unexpected vendor Fortran conversion dependency" >&2
    exit 1
fi
echo "Module and adapter build without vendor Fortran headers or conversion symbols."
