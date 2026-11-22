#!/bin/bash

set -e

# Define ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'  # Reset color

if [ $# -lt 2 ]; then
    echo -e "${RED}Usage: $0 <Fortran file> <mpiexec arguments>${RESET}"
    exit 1
fi

ROOT=$(cd "$(dirname "$0")" && pwd)
TEST_FILE=$(cd "$(dirname "$1")" && pwd)/$(basename "$1")
shift  # Remove the first argument (Fortran file)
MPI_ARGS=("$@")

EXECUTABLE=$(basename "$TEST_FILE" .f90)
TEST_OBJ="$EXECUTABLE.o"
BUILD_DIR="$ROOT/build/${PIXI_ENVIRONMENT_NAME:-manual}/run-$(date +%Y%m%d%H%M%S)-$$"

CC=${CC:-$CONDA_PREFIX/bin/mpicc}
FC=${FC:-gfortran}

echo -e "${BOLD}${CYAN}Configuration results${RESET}"
echo -e "${CYAN}---------------------${RESET}"
echo -e "${YELLOW}Using C compiler: ${RESET}${GREEN}$CC${RESET}"
echo -e "${YELLOW}Using Fortran compiler: ${RESET}${GREEN}$FC${RESET}"
echo ""

FC="$FC" CC="$CC" bash "$ROOT/tools/build_module.sh" "$BUILD_DIR"
cd "$BUILD_DIR"
MPI_LIB=$(cat mpi-library)

echo -e "${BLUE}Compiling $TEST_FILE with $FC...${RESET}"
$FC -I. -c "$TEST_FILE" -o "$TEST_OBJ"

echo -e "${CYAN}Linking objects to create executable: ${BOLD}${EXECUTABLE}${RESET}"
$FC mpi_constants.o mpi_native_constants.o mpi_c_bindings.o mpi.o "$TEST_OBJ" \
    -o "$EXECUTABLE" -L"$CONDA_PREFIX/lib" -l"$MPI_LIB" -Wl,-rpath,"$CONDA_PREFIX/lib"

echo -e "${BOLD}${GREEN}Running in $BUILD_DIR:${RESET} ${YELLOW}mpiexec ${MPI_ARGS[*]} ./$EXECUTABLE${RESET}"
"$CONDA_PREFIX/bin/mpiexec" "${MPI_ARGS[@]}" ./"$EXECUTABLE"
