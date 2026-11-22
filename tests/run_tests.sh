#!/bin/bash
set -e
TEST_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$TEST_DIR/.." && pwd)
cd "$TEST_DIR"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

USE_WRAPPERS=1
# Process command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --without-wrappers)
            USE_WRAPPERS=0
            shift
            ;;
        *)
            # Remaining arguments are test files
            break
            ;;
    esac
done

MPIEXEC=${CONDA_PREFIX}/bin/mpiexec

# detect MPI implementation
MPI_VERSION=$($MPIEXEC --version 2>&1)
if echo "$MPI_VERSION" | grep -q "Open MPI"; then
  MPI_TYPE="openmpi"
elif echo "$MPI_VERSION" | grep -q "MPICH"; then
  MPI_TYPE="mpich"
else
  # we don't yet support other MPI implementations
  # like intel MPI etc.0
  echo -e "${RED}Unknown MPI implementation!${NC}"
  exit 1
fi


if [ $USE_WRAPPERS -eq 0 ]; then
  FC="$CONDA_PREFIX/bin/mpif90"
fi
CC=${CC:-$CONDA_PREFIX/bin/mpicc}

# Define preprocessor flags based on MPI type
FC_FLAGS=""
if [[ "$MPI_TYPE" == "openmpi" ]]; then
  FC_FLAGS="-DOPEN_MPI"
fi

# MPI_ABI=yes: link with the MPI-5 standard ABI library, libmpi_abi
CFLAGS=""
MPI_LIB=mpi
if [[ -n "$MPI_ABI" ]]; then
  FC_FLAGS="-DMPI_ABI"
  CFLAGS="-DMPI_ABI"
  MPI_LIB=mpi_abi
fi

BUILD_DIR="$ROOT/build/${PIXI_ENVIRONMENT_NAME:-manual}/tests-$(date +%Y%m%d%H%M%S)-$$"
mkdir -p "$BUILD_DIR"
echo -e "#################################"
echo -e "${YELLOW}Using FC=${FC} compiler${NC}"
echo -e "${YELLOW}Using CC=${CC} compiler${NC}"
echo -e "################################"
echo -e

# If user specified a particular test (e.g. ./run_tests.sh bcast.f90),
# then only build & run that file. Otherwise, build & run all *.f90 files.

if [ $# -gt 0 ]; then
  TEST_FILES=("$@")
  echo -e "${YELLOW}Received argument(s). Will only compile/run: ${TEST_FILES[*]}${NC}"
else
  # No arguments, so gather all .f90 test files in the current directory
  TEST_FILES=( *.f90 )
  echo -e "${YELLOW}No specific test file given. Will compile/run all .f90 tests...${NC}"
fi

for i in "${!TEST_FILES[@]}"; do
  if [[ "${TEST_FILES[$i]}" != /* ]]; then
    TEST_FILES[$i]="$TEST_DIR/${TEST_FILES[$i]}"
  fi
done
cd "$BUILD_DIR"
if [ $USE_WRAPPERS -eq 1 ]; then
  FC="$FC" CC="$CC" MPI_DEFS="$FC_FLAGS" bash "$ROOT/tools/build_module.sh" .
fi

start_time=$(date +%s)

# Now compile & run each requested test
for file in "${TEST_FILES[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo -e "${RED}Test file '$file' not found! Skipping...${NC}"
    continue
  fi

  filename=$(basename "$file" .f90)
  EXTRA_OBJECTS=()
  if [[ "$filename" == native_handle_status_1 ]]; then
    if [[ "$MPI_LIB" == mpi_abi ]]; then
      echo "native_handle_status_1 tests native MPI_Fint, not MPI-5 ABI serialization"
      continue
    fi
    $CC -std=c11 -I"$CONDA_PREFIX/include" -c "$TEST_DIR/native_handle_status_oracle.c" \
      -o native_handle_status_oracle.o
    EXTRA_OBJECTS=(native_handle_status_oracle.o)
  fi
  echo -e "${YELLOW}Compiling $filename...${NC}"
  $FC -I. -c "$file" -o "$filename.o"

  if [ $USE_WRAPPERS -eq 1 ]; then
    $FC mpi_constants.o mpi_native_constants.o mpi_c_bindings.o mpi.o "$filename.o" "${EXTRA_OBJECTS[@]}" \
      -o "$filename" -L"$CONDA_PREFIX/lib" -l$MPI_LIB -Wl,-rpath,"$CONDA_PREFIX/lib"
  else
    $FC "$filename.o" "${EXTRA_OBJECTS[@]}" -o "$filename"
  fi

  # Test with 1, 2, and 4 ranks
  for np in 1 2 4; do
    # set MPIEXEC_ARGS based on MPI type and number of ranks
    # `--oversubscribe` isn't needed with Open MPI when running
    # with 1 or 2 ranks
    if [[ "$MPI_TYPE" == "openmpi" && $np -gt 2 ]]; then
      MPIEXEC_ARGS="--oversubscribe"
    elif [[ "$MPI_TYPE" == "mpich" ]]; then
      # otherwise Hydra can spend seconds resolving the hostname (macOS)
      MPIEXEC_ARGS="-hosts localhost"
    else
      MPIEXEC_ARGS=""
    fi

    echo -e "${YELLOW}Running $filename with $np MPI ranks...${NC}"
    if ${MPIEXEC} -np $np $MPIEXEC_ARGS ./$filename; then
      echo -e "${GREEN}Test $filename with $np MPI ranks PASSED!${NC}"
    else
      echo -e "${RED}Test $filename with $np MPI ranks FAILED!${NC}"
      exit 1
    fi
  done

done

end_time=$(date +%s)
elapsed_time=$((end_time - start_time))

echo ""
echo -e "${YELLOW}... Running standalone tests took ${elapsed_time} seconds ...${NC}"
echo ""
