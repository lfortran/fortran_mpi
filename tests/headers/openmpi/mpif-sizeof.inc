! The constants-only build must not read vendor procedure interfaces.
! Poison this include without changing any selected MPI constant or kind.
      include 'fortran_mpi_unexpected_vendor_procedures.h'
