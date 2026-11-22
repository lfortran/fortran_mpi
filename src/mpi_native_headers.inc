#if defined(OPEN_MPI)
    ! mpif.h also includes compiler-specific MPI_SIZEOF procedure interfaces.
    ! These three vendor headers supply all constants used by this binding.
    include 'mpif-config.h'
    include 'mpif-constants.h'
    include 'mpif-handles.h'
#else
    include 'mpif.h'
#endif
