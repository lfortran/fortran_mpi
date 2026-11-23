#!/bin/bash
set -eo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
if [[ $# != 1 || -z "${CONDA_PREFIX:-}" ]]; then
    echo "Usage (inside the selected Pixi environment): bash tools/build_module.sh <build-directory>" >&2
    exit 1
fi
PREFIX=${FORTRAN_MPI_PREFIX:-$CONDA_PREFIX}
if [[ ! -f "$PREFIX/include/mpi.h" ]]; then
    echo "fortran_mpi: matching MPI C headers are missing from $PREFIX/include" >&2
    exit 1
fi
PREFIX=$(cd "$PREFIX" && pwd)

read -r -a FC_COMMAND <<< "${FC:-gfortran}"
read -r -a CC_COMMAND <<< "${CC:-$PREFIX/bin/mpicc}"
read -r -a AR_COMMAND <<< "${AR:-ar}"
read -r -a C_FLAGS <<< "${CFLAGS:-}"
read -r -a TARGET_RUNNER <<< "${FORTRAN_MPI_TARGET_RUNNER:-}"
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
case "${FC_COMMAND[0]##*/}" in
    *lfortran*) CPP=(--cpp) ;;
    *ifx*|*ifort*) CPP=(-fpp) ;;
    *) CPP=(-cpp) ;;
esac
mkdir -p "$1"
cd "$1"
rm -f mpi.o mpi.mod mpi_c_bindings.o mpi_c_bindings.mod \
    mpi_native_constants.o mpi_native_constants.mod mpi_constants.o \
    mpi_handles.o mpi_types.o mpi_serializers.o libfortran_mpi.a \
    mpi-prefix mpi-library fortran_mpi.h mpi_c_constants.inc \
    mpi_optional_error_exports.inc mpi_optional_constants.inc
mkdir -p mpi-constant-checks
printf 'Fortran compiler: %s\nMPI prefix: %s\nMPI library: %s\n' "${FC_COMMAND[*]}" "$PREFIX" "$MPI_LIB"
C_OPTIONS=("${C_FLAGS[@]}" "${DEFINITIONS[@]}" -std=c11 -I"$PREFIX/include" -I"$ROOT/src")
MPI_LINK=(-L"$PREFIX/lib" -l"$MPI_LIB" -Wl,-rpath,"$PREFIX/lib")
set -x
printf '#include "fortran_mpi.h"\nint main(void) { int flag; return MPI_Initialized(&flag); }\n' > mpi_c_control.c
"${CC_COMMAND[@]}" "${C_OPTIONS[@]}" mpi_c_control.c "${MPI_LINK[@]}" -o mpi_c_control \
    > mpi-constant-checks/c-control.log 2>&1 || {
    cat mpi-constant-checks/c-control.log >&2
    exit 1
}

# All seven pairs must be declared and linkable in the selected C ABI.
printf 'int main(void) { return 0; }\n' > mpi_serializer_check.c
if "${CC_COMMAND[@]}" "${C_OPTIONS[@]}" -Werror=implicit-function-declaration \
        -c "$ROOT/src/mpi_serializers.c" -o mpi_serializers.o \
        > mpi-constant-checks/serializers.log 2>&1 &&
        "${CC_COMMAND[@]}" "${C_OPTIONS[@]}" mpi_serializer_check.c mpi_serializers.o \
        "${MPI_LINK[@]}" -o mpi_serializer_check >> mpi-constant-checks/serializers.log 2>&1; then
    printf 'C toint/fromint with checked private-token adaptation\n' > mpi-constant-checks/handle-provider
else
    if [[ "$MPI_LIB" == mpi_abi ]]; then
        cat mpi-constant-checks/serializers.log >&2
        echo "fortran_mpi: the MPI-5 ABI requires C handle serialization" >&2
        exit 1
    fi
    "${CC_COMMAND[@]}" "${C_OPTIONS[@]}" -c "$ROOT/src/mpi_no_serializers.c" -o mpi_serializers.o
    printf 'typed C-object map\n' > mpi-constant-checks/handle-provider
fi

if [[ "$MPI_LIB" == mpi ]]; then
    printf '! Optional names from the selected C header.\n' > mpi_optional_error_exports.inc
    : > mpi_optional_constants.inc
    printf 'name\tavailable\n' > mpi-constant-checks/availability.tsv
    for name in MPI_SUCCESS MPI_ERR_PROC_ABORTED MPI_ERR_VALUE_TOO_LARGE \
            MPI_ERR_SESSION MPI_ERR_ERRHANDLER MPI_ERR_ABI; do
        printf '#include <mpi.h>\nint mpi_constant_check = %s;\n' "$name" > mpi_constant_check.c
        c_status=0
        "${CC_COMMAND[@]}" "${C_OPTIONS[@]}" -c mpi_constant_check.c -o mpi_constant_check.o \
            > "mpi-constant-checks/$name-c.log" 2>&1 || c_status=$?
        if [[ $c_status -gt 1 || ( "$name" == MPI_SUCCESS && $c_status != 0 ) ]]; then
            cat "mpi-constant-checks/$name-c.log" >&2
            echo "fortran_mpi: unusable C constant headers for $name" >&2
            exit 1
        fi
        if [[ $c_status == 0 ]]; then
            printf '%s\tyes\n' "$name" >> mpi-constant-checks/availability.tsv
            if [[ "$name" != MPI_SUCCESS ]]; then
                printf 'public :: %s\n' "$name" >> mpi_optional_error_exports.inc
                printf 'emit("%s", %s);\n' "$name" "$name" >> mpi_optional_constants.inc
            fi
        else
            printf '%s\tno\n' "$name" >> mpi-constant-checks/availability.tsv
        fi
    done
    "${CC_COMMAND[@]}" "${C_OPTIONS[@]}" -I. "$ROOT/tools/emit_constants.c" -o mpi_emit_constants
    # This scalar-only target program never initializes MPI. Cross builds
    # must supply a target runner; failed execution never falls back to host values.
    if ! "${TARGET_RUNNER[@]}" ./mpi_emit_constants > mpi_c_constants.inc; then
        echo "fortran_mpi: cannot execute target constant emitter; set FORTRAN_MPI_TARGET_RUNNER for cross builds" >&2
        exit 1
    fi
fi
for source in mpi_constants mpi_handles mpi_types; do
    "${CC_COMMAND[@]}" "${C_OPTIONS[@]}" -c "$ROOT/src/$source.c" -o "$source.o"
done
# No vendor include directory is passed to any Fortran compilation.
"${FC_COMMAND[@]}" "${CPP[@]}" "${DEFINITIONS[@]}" -I. \
    -c "$ROOT/src/mpi_native_constants.f90" -o mpi_native_constants.o
"${FC_COMMAND[@]}" "${CPP[@]}" "${DEFINITIONS[@]}" -I. \
    -c "$ROOT/src/mpi_c_bindings.f90" -o mpi_c_bindings.o
"${FC_COMMAND[@]}" -I. -c "$ROOT/src/mpi.f90" -o mpi.o
"${AR_COMMAND[@]}" rcs libfortran_mpi.a mpi.o mpi_c_bindings.o mpi_native_constants.o \
    mpi_constants.o mpi_handles.o mpi_serializers.o mpi_types.o
cp "$ROOT/src/fortran_mpi.h" fortran_mpi.h
rm -f mpi_c_control.c mpi_c_control mpi_serializer_check.c mpi_serializer_check \
    mpi_constant_check.c mpi_constant_check.o mpi_emit_constants
set +x
printf '%s\n' "$PREFIX" > mpi-prefix
printf '%s\n' "$MPI_LIB" > mpi-library
