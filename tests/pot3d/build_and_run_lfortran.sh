set -ex

if [[ "$(uname)" == "Linux" ]]; then
  CC=gcc
else
  CC=clang
fi

cd src
$CC -I$CONDA_PREFIX/include -c ../../../src/mpi_constants.c
$FC -c ../../../src/mpi_c_bindings.f90
$FC -c ../../../src/mpi.f90
$FC -c psi_io.f90 --no-style-warnings -Wno-warnings
$FC -c --cpp --implicit-interface pot3d.F90 --no-style-warnings -Wno-warnings
$FC mpi_constants.o mpi_c_bindings.o mpi.o psi_io.o pot3d.o -o pot3d -L$CONDA_PREFIX/lib -lmpi -Wl,-rpath,$CONDA_PREFIX/lib
cp pot3d ../bin/

cd ..
./validate.sh
