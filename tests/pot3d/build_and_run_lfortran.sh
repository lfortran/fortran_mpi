#!/bin/bash
set -ex

if [[ "$(uname)" == "Linux" ]]; then
  CC=gcc
else
  CC=clang
fi

# MPI_ABI=yes: link with the MPI-5 standard ABI library, libmpi_abi
CFLAGS=""
MPI_LIB=mpi
if [[ -n "$MPI_ABI" ]]; then
  CFLAGS="-DMPI_ABI"
  MPI_LIB=mpi_abi
fi

cd src
$CC $CFLAGS -I$CONDA_PREFIX/include -c ../../../src/mpi_constants.c
$FC -c ../../../src/mpi_c_bindings.f90
$FC -c ../../../src/mpi.f90
$FC -c psi_io.f90 --no-style-suggestions --no-warnings
$FC -c --cpp --implicit-interface pot3d.F90 --no-style-suggestions --no-warnings
$FC mpi_constants.o mpi_c_bindings.o mpi.o psi_io.o pot3d.o -o pot3d -L$CONDA_PREFIX/lib -l$MPI_LIB -Wl,-rpath,$CONDA_PREFIX/lib
cp pot3d ../bin/

cd ..
./validate.sh
./validate.sh validation2
