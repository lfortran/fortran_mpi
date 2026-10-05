#!/bin/bash
set -e

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
  FC=mpif90
else
  if [[ "$(uname)" == "Linux" ]]; then
    CC=gcc
  else
    CC=clang
  fi
fi

# Define preprocessor flags based on MPI type
FC_FLAGS=""
if [[ "$MPI_TYPE" == "openmpi" ]]; then
  FC_FLAGS="-DOPEN_MPI"
fi

echo -e "${RED}Removing all untracked files${NC}"
git clean -dfx
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

if [ $USE_WRAPPERS -eq 1 ]; then
  $CC -I"$CONDA_PREFIX/include" -c ../src/mpi_constants.c
  $FC $FC_FLAGS -c ../src/mpi_c_bindings.f90
  $FC $FC_FLAGS -c ../src/mpi.f90
fi

start_time=$(date +%s)

# Now compile & run each requested test
for file in "${TEST_FILES[@]}"; do
  if [[ ! -f "$file" ]]; then
    echo -e "${RED}Test file '$file' not found! Skipping...${NC}"
    continue
  fi

  filename=$(basename "$file" .f90)
  echo -e "${YELLOW}Compiling $filename...${NC}"
  $FC -c "$file"

  if [ $USE_WRAPPERS -eq 1 ]; then
    $FC mpi_constants.o mpi_c_bindings.o mpi.o "$filename.o" \
      -o "$filename" -L"$CONDA_PREFIX/lib" -lmpi -Wl,-rpath,"$CONDA_PREFIX/lib"
  else
    $FC "$filename.o" -o "$filename"
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
