#!/bin/bash
set -eo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
PREFIX=${FORTRAN_MPI_PREFIX:-${CONDA_PREFIX:?Run in the selected Pixi environment}}
PREFIX=$(cd "$PREFIX" && pwd)
TIMEOUT=${FORTRAN_MPI_TIMEOUT:-timeout}
if ! command -v "$TIMEOUT" >/dev/null; then
    echo "Set FORTRAN_MPI_TIMEOUT to the absolute GNU timeout executable." >&2
    exit 1
fi
read -r -a FC_COMMAND <<< "${FC:?Pass the provided Fortran compiler explicitly}"
case "${FC_COMMAND[0]##*/}" in
    *mpif90*|*mpifort*)
        echo "The intentional-abort client must use the provided binding." >&2
        exit 1 ;;
esac
read -r -a CC_COMMAND <<< "${CC:-$PREFIX/bin/mpicc}"
read -r -a C_FLAGS <<< "${CFLAGS:-}"
DEFINITIONS=()
if [[ -n "${MPI_ABI:-}" || " ${MPI_DEFS:-} " == *"-DMPI_ABI"* ]]; then
    DEFINITIONS=(-DMPI_ABI)
fi
if grep -q 'MPICH_VERSION' "$PREFIX/include/mpi.h"; then
    MPI_TYPE=mpich
elif grep -q 'OMPI_MAJOR_VERSION' "$PREFIX/include/mpi.h"; then
    MPI_TYPE=openmpi
else
    echo "Unsupported MPI abort diagnostic format." >&2
    exit 1
fi
BUILD_DIR="$ROOT/build/${PIXI_ENVIRONMENT_NAME:-manual}/abort-$(date +%Y%m%d%H%M%S)-$$"
mkdir -p "$BUILD_DIR"
echo "Intentional-abort build directory: $BUILD_DIR"
cd "$BUILD_DIR"
"$PREFIX/bin/mpiexec" --version > mpi-version.log 2>&1
cat mpi-version.log
bash "$ROOT/tools/build_module.sh" .
MPI_LIB=$(cat mpi-library)
MPI_LINK=(-L"$PREFIX/lib" -l"$MPI_LIB" -Wl,-rpath,"$PREFIX/lib")
"${CC_COMMAND[@]}" "${C_FLAGS[@]}" "${DEFINITIONS[@]}" -std=c11 -I. -I"$PREFIX/include" \
    "$ROOT/tests/abort/abort_control.c" "${MPI_LINK[@]}" -o abort_control
"${CC_COMMAND[@]}" "${C_FLAGS[@]}" "${DEFINITIONS[@]}" -std=c11 -I. -I"$PREFIX/include" \
    -c "$ROOT/tests/abort/abort_oracle.c" -o abort_oracle.o
"${FC_COMMAND[@]}" -I. -c "$ROOT/tests/abort/abort_1.f90" -o abort_1.o
"${FC_COMMAND[@]}" abort_1.o abort_oracle.o libfortran_mpi.a "${MPI_LINK[@]}" -o abort_1

check_abort_log() {
    local name=$1 np=$2 status=$3 log=$4 rank
    if [[ $(cat "$log.reason") != launcher_completed ]]; then
        echo "$name: watchdog or launch infrastructure failure; see $log.reason and $log.watchdog." >&2
        return 1
    fi
    if [[ $(grep -c "^$name: ready " "$log") != "$np" ]]; then
        echo "$name: missing or extra rank readiness records." >&2
        return 1
    fi
    for ((rank=0; rank<np; rank++)); do
        if [[ $(grep -Fxc "$name: ready rank=$rank size=$np code=73" "$log") != 1 ]]; then
            echo "$name: incorrect communicator/rank record." >&2
            return 1
        fi
    done
    if [[ $MPI_TYPE == mpich ]]; then
        grep -Eq 'Abort\(73\).*rank 0.*application called MPI_Abort\(comm=.*,[[:space:]]*73\)' "$log" || {
            echo "$name: missing MPICH MPI_Abort(communicator, 73) diagnostic." >&2
            return 1
        }
    else
        if ! grep -Eq 'MPI_ABORT was invoked on rank 0([[:space:]]|$)' "$log" ||
                ! grep -Eq '^[[:space:]]*(with errorcode 73\.|Errorcode:[[:space:]]+73)[[:space:]]*$' "$log"; then
            echo "$name: missing Open MPI rank/errorcode abort diagnostic." >&2
            return 1
        fi
    fi
    if grep -q "^$name: returned " "$log"; then
        if [[ $(grep -c "^$name: returned " "$log") == 1 ]] &&
                grep -Fxq "$name: returned rc=0" "$log"; then
            return 2
        fi
        echo "$name: MPI_Abort returned an unexpected error." >&2
        return 1
    fi
    if [[ $status == 0 ]]; then
        echo "$name: expected abnormal termination, but the launcher returned success." >&2
        return 1
    fi
    return 0
}

launch_abort() {
    local name=$1 np=$2 log="$1-n$2.log" watchdog_status=0 reason
    LAUNCH_STATUS=unavailable
    # The helper returns zero after recording mpiexec's actual status. Thus a
    # nonzero watchdog/helper status cannot be confused with MPI's exit code.
    LC_ALL=C "$TIMEOUT" --verbose --signal=TERM --kill-after=10s 60s \
        bash -c '
            set -e
            log=$1
            receipt=$2
            shift 2
            test -x "$1"
            exec 3> "$log"
            status=0
            "$@" >&3 2>&1 || status=$?
            exec 3>&-
            printf "%s\n" "$status" > "$receipt"
            exit 0
        ' abort-launch "$BUILD_DIR/$log" "$BUILD_DIR/$log.exit" \
        "$PREFIX/bin/mpiexec" -n "$np" "${MPIEXEC_ARGS[@]}" "./$name" \
        > "$log.watchdog" 2>&1 || watchdog_status=$?
    printf '%s\n' "$watchdog_status" > "$log.watchdog.exit"
    if grep -Eq '^[^[:space:]]*timeout: sending signal ' "$log.watchdog" ||
            [[ $watchdog_status == 124 ]]; then
        reason=watchdog_timeout_or_signal
    elif [[ $watchdog_status != 0 ]]; then
        reason=harness_failure
    elif [[ -s "$log.exit" ]] && read -r LAUNCH_STATUS < "$log.exit" &&
            [[ $LAUNCH_STATUS =~ ^[0-9]+$ && $LAUNCH_STATUS -le 255 ]]; then
        reason=launcher_completed
    else
        reason=missing_or_invalid_launcher_status
    fi
    printf '%s\n' "$reason" > "$log.reason"
    cat "$log.watchdog"
    if [[ -f "$log" ]]; then cat "$log"; fi
    echo "$name: launcher=$LAUNCH_STATUS watchdog=$watchdog_status reason=$reason"
}

for np in 1 2 4; do
    MPIEXEC_ARGS=()
    if [[ $MPI_TYPE == mpich ]]; then
        MPIEXEC_ARGS=(-hosts localhost)
    elif [[ $np -gt 2 ]]; then
        MPIEXEC_ARGS=(--oversubscribe)
    fi
    echo "Checking native C and provided MPI_Abort with $np MPI ranks"
    launch_abort abort_control "$np"
    control_status=$LAUNCH_STATUS
    control=0
    check_abort_log abort_control "$np" "$LAUNCH_STATUS" "abort_control-n$np.log" || control=$?
    if [[ $control == 1 ]]; then exit 1; fi
    launch_abort abort_1 "$np"
    binding_status=$LAUNCH_STATUS
    binding=0
    check_abort_log abort_1 "$np" "$LAUNCH_STATUS" "abort_1-n$np.log" || binding=$?
    if [[ $control == 2 || $binding == 2 ]]; then
        echo "MPI_Abort no-return qualification FAILED: native-C=$control provided=$binding (2 means returned success)." >&2
        if grep -Eq '#define[[:space:]]+MPICH_VERSION[[:space:]]+"5\.0\.2"' "$PREFIX/include/mpi.h"; then
            echo "MPICH 5.0.2 has a known return-before-Hydra-termination race: pmodels/mpich#7716, lfortran/lfortran#18448." >&2
            echo "This is not a pass or a 64/64 coverage claim; qualify a corrected runtime separately." >&2
        fi
        exit 1
    fi
    if [[ $binding != 0 ]]; then exit 1; fi
    echo "abort_1: observed launcher statuses with $np MPI ranks: native-C=$control_status provided=$binding_status"
    echo "abort_1: strict native-C/provided oracle PASSED with $np MPI ranks"
done
