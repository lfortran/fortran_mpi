#!/bin/bash
set -ex

POT3D_HOME=$PWD
# we can provide first argument to decide which test case we want to run to validate.sh script
TEST="${1:-validation}"
MPIEXEC=${CONDA_PREFIX}/bin/mpiexec

cp ${POT3D_HOME}/testsuite/${TEST}/input/* ${POT3D_HOME}/testsuite/${TEST}/run/
cd ${POT3D_HOME}/testsuite/${TEST}/run

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

# A 3D array of the validation grid is 10 MB, more than the default stack, and
# ifx puts array temporaries on the stack
ulimit -s hard

for np in 1 2 4; do
  rm -rf pot3d.log pot3d.out timing.out

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

  echo "Running POT3D with $np MPI rank..."

  ${MPIEXEC} -np ${np} ${MPIEXEC_ARGS} ${POT3D_HOME}/bin/pot3d 1> pot3d.log 2>pot3d.err \
    || { cat pot3d.log pot3d.err; exit 1; }
  echo "Done!"

  runtime=($(tail -n 5 timing.out | head -n 1))
  echo "Wall clock time:                ${runtime[6]} seconds"
  echo " "

  #Validate run:
  ${POT3D_HOME}/scripts/pot3d_validation.sh pot3d.out ${POT3D_HOME}/testsuite/${TEST}/validation/pot3d.out
  if [ $? -ne 0 ]; then
    echo "Validation failed for $np MPI rank. Exiting..."
    exit 1
  fi
  echo ""
done

echo "Done!"
