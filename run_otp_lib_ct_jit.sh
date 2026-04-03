#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Run OTP lib/<app> Common Test suites with a prebuilt debug+JIT release, without `make test`.

Usage:
  run_otp_lib_ct_jit.sh [options]

Options:
  --app NAME            OTP library app under lib/ (default: kernel)
  --erl-top PATH         OTP source root (default: auto-detect from script path)
  --release-root PATH    Released OTP root containing bin/ct_run (default: $ERL_TOP/RELEASE)
  --beam-name NAME       Emulator binary name: beam.debug.smp or beam.smp (default: beam.smp)
  --direct-beam          Bypass ct_run and invoke selected beam directly (default: enabled)
  --beam-bin PATH        Beam executable for --direct-beam
                         (default: /home/vagrant/arm32-jit/otp/RELEASE/erts-15.0/bin/beam.smp)
  --suite NAME           Run specific suite (repeatable, e.g. logger_SUITE)
  --case NAME            Run specific case (requires exactly one --suite)
  --recompile-module M   Only run `erlc +debug_info` for M.erl in staged test dir and exit
  --recompile-verbose    Verbose logging for --recompile-module (erlc -v +verbose +report*)
  --recompile-watch      Print periodic heartbeat while --recompile-module runs
  --spec FILE            Spec file in <app>/test (default: <app>.spec)
  --logdir PATH          CT log directory (default: lib/<app>/make_test_dir/ct_logs_jit_debug)
  --node NAME            Short node name for ct_run (default: <app>_jit_test)
  --gdb-port PORT        Set QEMU_GDB=PORT before running (for gdb-multiarch attach)
  --qemu-trace           Run direct-beam under qemu-arm trace (-d in_asm,cpu)
  --qemu-trace-file P    Trace output file (default: $MAKE_TEST_DIR/qemu_ct.trace)
  --qemu-trace-events E  qemu -d events (default: in_asm,cpu)
  --stop-mode MODE       Direct-beam post-CT action: halt|stop|none (default: halt)
  --post-ct-sleep SEC    In direct-beam mode, sleep SEC seconds after CT and before stop action
  --jit-purge-nofree     Set ERL_JIT_PURGE_NOFREE=1 for this run (diagnostic)
  --no-auto-compile      Disable Common Test auto-compilation of suites/helpers
  --compile-data         Compile *_SUITE_data Erlang files before running tests
  --multiply-timetraps N Multiply Common Test timetraps by N (e.g. 4, 8)
  --prebuild-local       Prebuild staged test modules using local host/VM `erl` (fast)
  --prebuild-erl PATH    `erl` executable to use with --prebuild-local (default: `command -v erl`)
  --prebuild-only        Prebuild and exit (do not start ct_run)
  --help                 Show this help

Environment:
  EXTRA_ERL_ARGS         Extra args appended to -erl_args (split on spaces)

Examples:
  ./run_otp_lib_ct_jit.sh --app kernel
  ./run_otp_lib_ct_jit.sh --app kernel --suite logger_SUITE
  ./run_otp_lib_ct_jit.sh --app stdlib --suite beam_lib_SUITE --case chunkify
  ./run_otp_lib_ct_jit.sh --app ssl --suite ssl_SUITE
  EXTRA_ERL_ARGS="+JPperf true" ./run_otp_lib_ct_jit.sh --app kernel --suite kernel_SUITE
EOF
}

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
if [[ -d "$SCRIPT_DIR/otp/lib" ]]; then
    ERL_TOP_DEFAULT="$(cd -- "$SCRIPT_DIR/otp" && pwd)"
else
    ERL_TOP_DEFAULT="$SCRIPT_DIR"
fi

APP_NAME="kernel"
ERL_TOP="$ERL_TOP_DEFAULT"
RELEASE_ROOT=""
SPEC_FILE=""
LOGDIR=""
CT_NODE=""
DEFAULT_BEAM_BIN="/home/vagrant/arm32-jit/otp/RELEASE/erts-15.0/bin/beam.smp"
DIRECT_BEAM=1
BEAM_BIN="$DEFAULT_BEAM_BIN"
BEAM_NAME="beam.smp"
COMPILE_DATA=0
NO_AUTO_COMPILE=0
PREBUILD_LOCAL=0
PREBUILD_ONLY=0
PREBUILD_ERL=""
MULTIPLY_TIMETRAPS=""
GDB_PORT=""
QEMU_TRACE=0
QEMU_TRACE_FILE=""
QEMU_TRACE_EVENTS="in_asm,cpu"
STOP_MODE="halt"
POST_CT_SLEEP_SECS=""
JIT_PURGE_NOFREE=0
RECOMPILE_MODULE=""
RECOMPILE_VERBOSE=0
RECOMPILE_WATCH=0

declare -a SUITES=()
CASE_NAME=""
APP_SET_BY_USER=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --app)
            APP_NAME="$2"
            APP_SET_BY_USER=1
            shift 2
            ;;
        --erl-top)
            ERL_TOP="$2"
            shift 2
            ;;
        --release-root)
            RELEASE_ROOT="$2"
            shift 2
            ;;
        --suite)
            SUITES+=("$2")
            shift 2
            ;;
        --direct-beam)
            DIRECT_BEAM=1
            shift
            ;;
        --beam-name)
            BEAM_NAME="$2"
            shift 2
            ;;
        --beam-bin)
            BEAM_BIN="$2"
            shift 2
            ;;
        --case)
            CASE_NAME="$2"
            shift 2
            ;;
        --recompile-module)
            RECOMPILE_MODULE="$2"
            shift 2
            ;;
        --recompile-verbose)
            RECOMPILE_VERBOSE=1
            shift
            ;;
        --recompile-watch)
            RECOMPILE_WATCH=1
            shift
            ;;
        --spec)
            SPEC_FILE="$2"
            shift 2
            ;;
        --logdir)
            LOGDIR="$2"
            shift 2
            ;;
        --node)
            CT_NODE="$2"
            shift 2
            ;;
        --gdb-port)
            GDB_PORT="$2"
            shift 2
            ;;
        --qemu-trace)
            QEMU_TRACE=1
            shift
            ;;
        --qemu-trace-file)
            QEMU_TRACE=1
            QEMU_TRACE_FILE="$2"
            shift 2
            ;;
        --qemu-trace-events)
            QEMU_TRACE=1
            QEMU_TRACE_EVENTS="$2"
            shift 2
            ;;
        --stop-mode)
            STOP_MODE="$2"
            shift 2
            ;;
        --post-ct-sleep)
            POST_CT_SLEEP_SECS="$2"
            shift 2
            ;;
        --jit-purge-nofree)
            JIT_PURGE_NOFREE=1
            shift
            ;;
        --no-auto-compile)
            NO_AUTO_COMPILE=1
            shift
            ;;
        --compile-data)
            COMPILE_DATA=1
            shift
            ;;
        --multiply-timetraps)
            MULTIPLY_TIMETRAPS="$2"
            shift 2
            ;;
        --prebuild-local)
            PREBUILD_LOCAL=1
            shift
            ;;
        --prebuild-erl)
            PREBUILD_ERL="$2"
            shift 2
            ;;
        --prebuild-only)
            PREBUILD_ONLY=1
            shift
            ;;
        --help|-h)
            usage
            exit 0
            ;;
        *)
            if [[ "$1" == -* ]]; then
                echo "Unknown option: $1" >&2
                usage
                exit 2
            fi
            if [[ "$APP_SET_BY_USER" -eq 1 ]]; then
                echo "Unexpected positional argument: $1" >&2
                usage
                exit 2
            fi
            APP_NAME="$1"
            APP_SET_BY_USER=1
            shift
            ;;
    esac
done

if [[ ! "$APP_NAME" =~ ^[A-Za-z0-9_]+$ ]]; then
    echo "Invalid app name: $APP_NAME (expected [A-Za-z0-9_]+)" >&2
    exit 2
fi

if [[ -z "$SPEC_FILE" ]]; then
    SPEC_FILE="${APP_NAME}.spec"
fi

if [[ -z "$CT_NODE" ]]; then
    CT_NODE="${APP_NAME}_jit_test"
fi

LOG_PREFIX="[otp-lib-ct:${APP_NAME}]"

if [[ "$STOP_MODE" != "halt" && "$STOP_MODE" != "stop" && "$STOP_MODE" != "none" ]]; then
    echo "Unsupported --stop-mode: $STOP_MODE (expected halt|stop|none)" >&2
    exit 2
fi

if [[ -n "$POST_CT_SLEEP_SECS" ]]; then
    if [[ ! "$POST_CT_SLEEP_SECS" =~ ^[0-9]+$ ]]; then
        echo "Invalid --post-ct-sleep value: $POST_CT_SLEEP_SECS (expected non-negative integer seconds)" >&2
        exit 2
    fi
fi

if [[ -z "$RELEASE_ROOT" ]]; then
    RELEASE_ROOT="$ERL_TOP/RELEASE"
fi

if [[ "$BEAM_NAME" != "beam.debug.smp" && "$BEAM_NAME" != "beam.smp" ]]; then
    echo "Unsupported --beam-name: $BEAM_NAME (expected beam.debug.smp or beam.smp)" >&2
    exit 2
fi

if [[ -n "$GDB_PORT" && "$DIRECT_BEAM" -eq 0 ]]; then
    echo "$LOG_PREFIX --gdb-port requested; forcing --direct-beam for stable qemu-arm gdbstub attach"
    DIRECT_BEAM=1
fi

if [[ "$QEMU_TRACE" -eq 1 && "$DIRECT_BEAM" -eq 0 ]]; then
    echo "$LOG_PREFIX --qemu-trace requested; forcing --direct-beam"
    DIRECT_BEAM=1
fi

APP_DIR="$ERL_TOP/lib/$APP_NAME"
TEST_DIR="$APP_DIR/test"
MAKE_TEST_DIR="$APP_DIR/make_test_dir"
REL_TEST_DIR="$MAKE_TEST_DIR/${APP_NAME}_test"
CT_RUN="$RELEASE_ROOT/bin/ct_run"
ERLC_BIN="$RELEASE_ROOT/bin/erlc"
BEAM_BINDIR=""
SELECTED_BEAM_PATH=""
SELECTED_BEAM_BASENAME=""

if [[ ! -d "$APP_DIR" ]]; then
    echo "$LOG_PREFIX app directory not found: $APP_DIR" >&2
    exit 1
fi

if [[ ! -d "$TEST_DIR" ]]; then
    echo "$LOG_PREFIX test directory not found: $TEST_DIR" >&2
    exit 1
fi

if [[ -z "$LOGDIR" ]]; then
    LOGDIR="$MAKE_TEST_DIR/ct_logs_jit_debug"
fi

shopt -s nullglob
_erts_bindir_candidates=("$RELEASE_ROOT"/erts-*/bin)
shopt -u nullglob
if [[ ${#_erts_bindir_candidates[@]} -gt 0 ]]; then
    BEAM_BINDIR="$(cd -- "${_erts_bindir_candidates[0]}" && pwd)"
fi

if [[ "$DIRECT_BEAM" -eq 0 ]]; then
    if [[ ! -x "$CT_RUN" ]]; then
        echo "ct_run not found or not executable: $CT_RUN" >&2
        exit 1
    fi

    if [[ -z "$BEAM_BINDIR" ]]; then
        echo "Unable to locate RELEASE/erts-*/bin for --beam-name $BEAM_NAME" >&2
        exit 1
    fi
    SELECTED_BEAM_PATH="$BEAM_BINDIR/$BEAM_NAME"
    if [[ ! -x "$SELECTED_BEAM_PATH" ]]; then
        echo "Selected beam executable is not executable: $SELECTED_BEAM_PATH" >&2
        exit 1
    fi
    SELECTED_BEAM_BASENAME="$BEAM_NAME"
else
    if [[ -z "$BEAM_BIN" ]]; then
        if [[ -n "$BEAM_BINDIR" ]]; then
            BEAM_BIN="$BEAM_BINDIR/$BEAM_NAME"
        fi
    fi
    if [[ -z "$BEAM_BIN" || ! -x "$BEAM_BIN" ]]; then
        echo "Beam executable not found or not executable: $BEAM_BIN" >&2
        echo "Use --beam-bin /path/to/beam.smp" >&2
        exit 1
    fi
    BEAM_BINDIR="$(cd -- "$(dirname -- "$BEAM_BIN")" && pwd)"
    SELECTED_BEAM_PATH="$BEAM_BIN"
    SELECTED_BEAM_BASENAME="$(basename -- "$BEAM_BIN")"
fi

if [[ ! -x "$ERLC_BIN" ]]; then
    echo "erlc not found or not executable: $ERLC_BIN" >&2
    exit 1
fi

if [[ -n "$CASE_NAME" && "${#SUITES[@]}" -ne 1 ]]; then
    echo "--case requires exactly one --suite" >&2
    exit 2
fi

if [[ -n "$MULTIPLY_TIMETRAPS" ]]; then
    if [[ ! "$MULTIPLY_TIMETRAPS" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        echo "Invalid --multiply-timetraps value: $MULTIPLY_TIMETRAPS" >&2
        echo "Expected a positive number, e.g. 2, 4, 8, 1.5" >&2
        exit 2
    fi
fi

if [[ "$PREBUILD_LOCAL" -eq 1 && "$NO_AUTO_COMPILE" -eq 0 ]]; then
    echo "$LOG_PREFIX forcing -no_auto_compile because --prebuild-local is enabled"
    NO_AUTO_COMPILE=1
fi

if [[ "$NO_AUTO_COMPILE" -eq 1 && "$COMPILE_DATA" -eq 0 ]]; then
    echo "$LOG_PREFIX forcing --compile-data because -no_auto_compile can skip *_SUITE_data modules"
    COMPILE_DATA=1
fi

mkdir -p "$MAKE_TEST_DIR" "$LOGDIR"

export ERL_TOP

echo "$LOG_PREFIX staging test files into: $REL_TEST_DIR"
make -C "$TEST_DIR" RELEASE_PATH="$MAKE_TEST_DIR" release_tests_spec >/dev/null

# ts_install_cth derives ts_conf_dir from data_dir and expects a
# make_test_dir/test_server/variables file for Makefile.src substitutions in
# *_SUITE_data directories (e.g. os_SUITE_data/my_echo,my_fds helpers).
TS_VARS_SRC="$ERL_TOP/lib/common_test/test_server/variables"
TS_VARS_DST_DIR="$MAKE_TEST_DIR/test_server"
TS_VARS_DST="$TS_VARS_DST_DIR/variables"
if [[ -f "$TS_VARS_SRC" ]]; then
    mkdir -p "$TS_VARS_DST_DIR"
    cp "$TS_VARS_SRC" "$TS_VARS_DST"
    echo "$LOG_PREFIX prepared ts_install_cth variables: $TS_VARS_DST"
else
    echo "$LOG_PREFIX warning: missing variables source: $TS_VARS_SRC" >&2
    echo "$LOG_PREFIX warning: Makefile.src helpers in *_SUITE_data may fail to build" >&2
fi

compile_suite_data_dir() {
    local dir="$1"
    local compiler="${2:-$ERLC_BIN}"
    [[ -d "$dir" ]] || return 0

    local had_files=0
    local failed_files=0
    local src_dir src_base
    while IFS= read -r -d '' f; do
        had_files=1
        src_dir="$(dirname -- "$f")"
        src_base="$(basename -- "$f")"
        if ! (
            cd "$src_dir"
            "$compiler" +debug_info "$src_base"
        ); then
            failed_files=$((failed_files + 1))
            echo "$LOG_PREFIX warning: failed to compile suite-data file (skipping): $f" >&2
        fi
    done < <(find "$dir" -type f -name '*.erl' -print0)

    if [[ "$had_files" -eq 1 ]]; then
        echo "$LOG_PREFIX compiled data dir (recursive): $dir"
        if [[ "$failed_files" -gt 0 ]]; then
            echo "$LOG_PREFIX warning: $failed_files suite-data source file(s) failed in $dir" >&2
        fi
    fi
}

if [[ "$COMPILE_DATA" -eq 1 && "$PREBUILD_LOCAL" -eq 0 ]]; then
    echo "$LOG_PREFIX compiling suite data files (release erlc)"
    if [[ "${#SUITES[@]}" -eq 0 ]]; then
        shopt -s nullglob
        for d in "$REL_TEST_DIR"/*_SUITE_data; do
            compile_suite_data_dir "$d"
        done
        shopt -u nullglob
    else
        for s in "${SUITES[@]}"; do
            compile_suite_data_dir "$REL_TEST_DIR/${s}_data"
        done
    fi
fi

prebuild_with_local_erl() {
    local local_erl="$PREBUILD_ERL"
    local local_erlc=""
    local erl_dir=""

    if [[ -z "$local_erl" ]]; then
        local_erl="$(command -v erl || true)"
    fi

    if [[ -z "$local_erl" || ! -x "$local_erl" ]]; then
        echo "Unable to find local erl executable for --prebuild-local" >&2
        echo "Use --prebuild-erl /path/to/erl" >&2
        exit 1
    fi

    erl_dir="$(cd -- "$(dirname -- "$local_erl")" && pwd)"
    if [[ -x "$erl_dir/erlc" ]]; then
        local_erlc="$erl_dir/erlc"
    fi

    echo "$LOG_PREFIX prebuild-local enabled"
    echo "$LOG_PREFIX local erl: $local_erl"
    if [[ -n "$local_erlc" ]]; then
        echo "$LOG_PREFIX local erlc: $local_erlc"
    fi

    (
        cd "$REL_TEST_DIR"
        "$local_erl" -noshell -pa "$ERL_TOP/lib/tools/ebin" \
            -eval 'case make:all() of up_to_date -> halt(0); error -> halt(1); _ -> halt(0) end.'
    )

    if [[ "$COMPILE_DATA" -eq 1 ]]; then
        local data_compiler="$ERLC_BIN"
        if [[ -n "$local_erlc" ]]; then
            data_compiler="$local_erlc"
        fi
        echo "$LOG_PREFIX compiling suite data files with: $data_compiler"
        if [[ "${#SUITES[@]}" -eq 0 ]]; then
            shopt -s nullglob
            for d in "$REL_TEST_DIR"/*_SUITE_data; do
                compile_suite_data_dir "$d" "$data_compiler"
            done
            shopt -u nullglob
        else
            for s in "${SUITES[@]}"; do
                compile_suite_data_dir "$REL_TEST_DIR/${s}_data" "$data_compiler"
            done
        fi
    fi
}

if [[ "$PREBUILD_LOCAL" -eq 1 ]]; then
    prebuild_with_local_erl

    if [[ "$PREBUILD_ONLY" -eq 1 ]]; then
        echo "$LOG_PREFIX prebuild completed (prebuild-only)"
        exit 0
    fi
fi

export PATH="$RELEASE_ROOT/bin:$PATH"

# epmd lives in erts-*/bin and is required for distributed startup (-sname/-name).
# Ensure it's resolvable both for ct_run and direct beam mode.
if [[ -n "${BEAM_BINDIR:-}" ]]; then
    export PATH="$BEAM_BINDIR:$PATH"
fi

if ! command -v epmd >/dev/null 2>&1; then
    echo "epmd not found in PATH (required for distributed tests)" >&2
    echo "PATH=$PATH" >&2
    exit 1
fi

ensure_epmd_running() {
    local epmd_cmd host_epmd
    local -i attempt

    epmd_cmd="$(command -v epmd || true)"
    host_epmd="/usr/bin/epmd"

    # Fast path: epmd is already reachable.
    if epmd -names >/dev/null 2>&1; then
        return 0
    fi

    echo "$LOG_PREFIX epmd is not reachable yet; starting daemon"
    if ! "$epmd_cmd" -daemon >/dev/null 2>&1; then
        # Fallback: when RELEASE/erts-*/bin/epmd is non-runnable on host arch,
        # use host epmd to satisfy local node registration.
        if [[ -x "$host_epmd" && "$host_epmd" != "$epmd_cmd" ]]; then
            echo "$LOG_PREFIX fallback to host epmd: $host_epmd"
            "$host_epmd" -daemon >/dev/null 2>&1 || true
        fi
    fi

    for attempt in 1 2 3 4 5 6 7 8 9 10; do
        if epmd -names >/dev/null 2>&1; then
            return 0
        fi
        sleep 0.2
    done

    echo "epmd did not become reachable (inet_tcp registration will fail)" >&2
    echo "ERL_EPMD_ADDRESS=${ERL_EPMD_ADDRESS:-<unset>}" >&2
    echo "ERL_EPMD_PORT=${ERL_EPMD_PORT:-<unset>}" >&2
    command -v ss >/dev/null 2>&1 && ss -ltnp | grep 4369 >&2 || true
    exit 1
}

ensure_epmd_running

print_gdb_attach_hint() {
    local beam_bin="$SELECTED_BEAM_PATH"

    echo "$LOG_PREFIX gdb mode enabled (QEMU_GDB=$GDB_PORT)"
    if [[ -n "$beam_bin" ]]; then
        echo "$LOG_PREFIX attach with:"
        echo "  gdb-multiarch -q --nh \\"
        echo "    -ex 'set architecture arm' \\"
        echo "    -ex 'set sysroot /usr/arm-linux-gnueabihf' \\"
        echo "    -ex 'file $beam_bin' \\"
        echo "    -ex 'target remote localhost:$GDB_PORT'"
    else
        echo "$LOG_PREFIX attach with: gdb-multiarch -ex 'target remote localhost:$GDB_PORT'"
    fi
}

check_gdb_port_available() {
    [[ -n "$GDB_PORT" ]] || return 0
    command -v ss >/dev/null 2>&1 || return 0

    if ss -ltn "( sport = :$GDB_PORT )" 2>/dev/null | grep -q LISTEN; then
        echo "$LOG_PREFIX gdb port $GDB_PORT is already in use" >&2
        ss -ltnp "( sport = :$GDB_PORT )" 2>/dev/null || true
        echo "$LOG_PREFIX pick another port or stop the stale qemu/erl process first" >&2
        exit 1
    fi
}

if [[ -n "$RECOMPILE_MODULE" ]]; then
    target_file="$REL_TEST_DIR/${RECOMPILE_MODULE}.erl"
    if [[ ! -f "$target_file" ]]; then
        echo "Module source not found in staged test dir: $target_file" >&2
        exit 1
    fi

    echo "$LOG_PREFIX recompile-only mode"
    echo "$LOG_PREFIX file: $target_file"
    if [[ -n "$GDB_PORT" ]]; then
        print_gdb_attach_hint
    fi

    cd "$REL_TEST_DIR"
    if [[ "$RECOMPILE_VERBOSE" -eq 1 ]]; then
        echo "$LOG_PREFIX erlc command:"
        echo "  $ERLC_BIN -v +debug_info +verbose +report_errors +report_warnings ${RECOMPILE_MODULE}.erl"
        ERLC_CMD=("$ERLC_BIN" -v +debug_info +verbose +report_errors +report_warnings "${RECOMPILE_MODULE}.erl")
    else
        ERLC_CMD=("$ERLC_BIN" +debug_info "${RECOMPILE_MODULE}.erl")
    fi

    if [[ "$RECOMPILE_WATCH" -eq 1 ]]; then
        "${ERLC_CMD[@]}" &
        erlc_pid=$!
        start_ts=$(date +%s)
        echo "$LOG_PREFIX recompile heartbeat: pid=$erlc_pid (every 5s)"
        while kill -0 "$erlc_pid" 2>/dev/null; do
            now_ts=$(date +%s)
            elapsed=$((now_ts - start_ts))
            ps -p "$erlc_pid" -o pid=,stat=,pcpu=,etime=,args= | sed "s/^/$LOG_PREFIX [${elapsed}s] /"
            sleep 5
        done
        wait "$erlc_pid"
    else
        "${ERLC_CMD[@]}"
    fi
    echo "$LOG_PREFIX recompile completed"
    exit 0
fi

declare -a CT_ARGS
if [[ "${#SUITES[@]}" -gt 0 ]]; then
    CT_ARGS=(-suite "${SUITES[@]}")
else
    if [[ "$SPEC_FILE" = /* ]]; then
        CT_ARGS=(-spec "$SPEC_FILE")
    else
        CT_ARGS=(-spec "$REL_TEST_DIR/$SPEC_FILE")
    fi
fi

if [[ -n "$CASE_NAME" ]]; then
    CT_ARGS+=(-case "$CASE_NAME")
fi

if [[ "$NO_AUTO_COMPILE" -eq 1 ]]; then
    CT_ARGS+=(-no_auto_compile)
fi

declare -a CT_TIMETRAP_ARGS=()
if [[ -n "$MULTIPLY_TIMETRAPS" ]]; then
    CT_TIMETRAP_ARGS+=(-multiply_timetraps "$MULTIPLY_TIMETRAPS")
fi

declare -a ERL_RUNTIME_ARGS
case "$SELECTED_BEAM_BASENAME" in
    beam.debug.smp)
        ERL_RUNTIME_ARGS=(
            -emu_type debug
            -emu_flavor smp
        )
        ;;
    beam.smp)
        ERL_RUNTIME_ARGS=(
            -emu_flavor smp
        )
        ;;
    *)
        # Fallback for custom --beam-bin names.
        ERL_RUNTIME_ARGS=(
            -emu_flavor smp
        )
        ;;
esac

if [[ -n "${EXTRA_ERL_ARGS:-}" ]]; then
    # Intentional word splitting for CLI-style extra args.
    # shellcheck disable=SC2206
    EXTRA_SPLIT=(${EXTRA_ERL_ARGS})
    ERL_RUNTIME_ARGS+=("${EXTRA_SPLIT[@]}")
fi

# Ensure any `erl` process spawned by CT/test_server (for example slave nodes)
# uses the same emulator flavor/args as ct_run itself.
declare -a ERL_AFLAGS_ARGS=("${ERL_RUNTIME_ARGS[@]}")
if [[ -n "${ERL_AFLAGS:-}" ]]; then
    # Intentional word splitting for CLI-style existing ERL_AFLAGS.
    # shellcheck disable=SC2206
    EXISTING_AFLAGS_SPLIT=(${ERL_AFLAGS})
    ERL_AFLAGS_ARGS+=("${EXISTING_AFLAGS_SPLIT[@]}")
fi

ERL_AFLAGS="${ERL_AFLAGS_ARGS[*]}"
export ERL_AFLAGS

echo "$LOG_PREFIX release root: $RELEASE_ROOT"
echo "$LOG_PREFIX selected beam: $SELECTED_BEAM_PATH"
if [[ "$DIRECT_BEAM" -eq 0 ]]; then
    echo "$LOG_PREFIX ct_run: $CT_RUN"
else
    echo "$LOG_PREFIX direct beam mode: $BEAM_BIN"
    echo "$LOG_PREFIX direct beam stop mode: $STOP_MODE"
    if [[ -n "$POST_CT_SLEEP_SECS" ]]; then
        echo "$LOG_PREFIX direct beam post-ct sleep: ${POST_CT_SLEEP_SECS}s"
    fi
fi
if [[ "$QEMU_TRACE" -eq 1 ]]; then
    echo "$LOG_PREFIX qemu trace events: $QEMU_TRACE_EVENTS"
fi
echo "$LOG_PREFIX args: ${CT_ARGS[*]}"
if [[ ${#CT_TIMETRAP_ARGS[@]} -gt 0 ]]; then
    echo "$LOG_PREFIX timetrap args: ${CT_TIMETRAP_ARGS[*]}"
fi
echo "$LOG_PREFIX logs: $LOGDIR"
echo "$LOG_PREFIX ERL_AFLAGS (propagated to spawned erl): $ERL_AFLAGS"
if [[ "$JIT_PURGE_NOFREE" -eq 1 ]]; then
    echo "$LOG_PREFIX ERL_JIT_PURGE_NOFREE=1 (diagnostic)"
fi
if [[ -n "$GDB_PORT" ]]; then
    print_gdb_attach_hint
fi
check_gdb_port_available

cd "$REL_TEST_DIR"

declare -a EMU_LAUNCHER=()
if [[ -n "$GDB_PORT" || "$QEMU_TRACE" -eq 1 ]]; then
    QEMU_ARM_BIN="$(command -v qemu-arm || true)"
    if [[ -z "$QEMU_ARM_BIN" ]]; then
        echo "qemu-arm not found in PATH (required for --gdb-port/--qemu-trace)" >&2
        exit 1
    fi
    EMU_LAUNCHER=("$QEMU_ARM_BIN" -L /usr/arm-linux-gnueabihf)
    if [[ -n "$GDB_PORT" ]]; then
        EMU_LAUNCHER+=(-g "$GDB_PORT")
    fi
    if [[ "$QEMU_TRACE" -eq 1 ]]; then
        if [[ -z "$QEMU_TRACE_FILE" ]]; then
            QEMU_TRACE_FILE="$MAKE_TEST_DIR/qemu_ct.trace"
        fi
        mkdir -p "$(dirname -- "$QEMU_TRACE_FILE")"
        : > "$QEMU_TRACE_FILE"
        EMU_LAUNCHER+=(-d "$QEMU_TRACE_EVENTS" -D "$QEMU_TRACE_FILE")
        echo "$LOG_PREFIX qemu trace file: $QEMU_TRACE_FILE"
    fi
fi

if [[ "$DIRECT_BEAM" -eq 0 ]]; then
    EMU_NAME="${SELECTED_BEAM_BASENAME%.smp}"
    if [[ "$JIT_PURGE_NOFREE" -eq 1 ]]; then
        export ERL_JIT_PURGE_NOFREE=1
    fi
    ROOTDIR="$RELEASE_ROOT" \
    BINDIR="$BEAM_BINDIR" \
    PROGNAME=erl \
    EMU="$EMU_NAME" \
    "${EMU_LAUNCHER[@]}" "$CT_RUN" -logdir "$LOGDIR" \
        -pa "$ERL_TOP/lib/common_test/test_server" \
        -config "$ERL_TOP/lib/common_test/test_server/ts.config" \
        -config "$ERL_TOP/lib/common_test/test_server/ts.unix.config" \
        -exit_status ignore_config \
        "${CT_TIMETRAP_ARGS[@]}" \
        "${CT_ARGS[@]}" \
        -erl_args \
        -env ERL_CRASH_DUMP "$MAKE_TEST_DIR/${APP_NAME}_erl_crash.dump" \
        -boot start_sasl \
        -sasl errlog_type error \
        -pz "$ERL_TOP/lib/common_test/test_server" \
        -pz "." \
        -ct_test_vars "{net_dir,\"\"}" \
        -noinput \
        -sname "$CT_NODE" \
        -rsh ssh \
        "${ERL_RUNTIME_ARGS[@]}"
else
    EMU_NAME="$(basename -- "$BEAM_BIN")"
    EMU_NAME="${EMU_NAME%.smp}"
    if [[ "$JIT_PURGE_NOFREE" -eq 1 ]]; then
        export ERL_JIT_PURGE_NOFREE=1
    fi

    POST_CT_ACTION=()
    POST_CT_SLEEP_ACTION=()
    if [[ -n "$POST_CT_SLEEP_SECS" ]]; then
        POST_CT_SLEEP_ACTION=(-eval "timer:sleep(${POST_CT_SLEEP_SECS}*1000).")
    fi
    case "$STOP_MODE" in
        halt)
            POST_CT_ACTION=(-s erlang halt)
            ;;
        stop)
            POST_CT_ACTION=(-s init stop)
            ;;
        none)
            POST_CT_ACTION=()
            ;;
    esac

    ROOTDIR="$RELEASE_ROOT" \
    BINDIR="$BEAM_BINDIR" \
    PROGNAME=erl \
    EMU="$EMU_NAME" \
    "${EMU_LAUNCHER[@]}" "$BEAM_BIN" -- \
        -root "$RELEASE_ROOT" \
        -bindir "$BEAM_BINDIR" \
        -progname erl \
        -home "${HOME:-/home/vagrant}" \
        -sname "$CT_NODE" \
        -s ct_run script_start \
        "${POST_CT_SLEEP_ACTION[@]}" \
        "${POST_CT_ACTION[@]}" \
        -logdir "$LOGDIR" \
        -pa "$ERL_TOP/lib/common_test/test_server" \
        -ct_config "$ERL_TOP/lib/common_test/test_server/ts.config" \
        -ct_config "$ERL_TOP/lib/common_test/test_server/ts.unix.config" \
        -exit_status ignore_config \
        "${CT_TIMETRAP_ARGS[@]}" \
        "${CT_ARGS[@]}" \
        -ct_erl_args \
        -env ERL_CRASH_DUMP "$MAKE_TEST_DIR/${APP_NAME}_erl_crash.dump" \
        -boot start_sasl \
        -sasl errlog_type error \
        -pz "$ERL_TOP/lib/common_test/test_server" \
        -pz "." \
        -ct_test_vars "{net_dir,\"\"}" \
        -noinput \
        -rsh ssh \
        "${ERL_RUNTIME_ARGS[@]}"
fi
