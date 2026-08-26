#!/usr/bin/env bash
# Copyright lowRISC contributors is NOT the author of this file — internal
# project script for the Ibex UVM/VCS verification work
# (see ../../../../doc/ibex_uvm_vcs_internship_execution_plan.md, Stage S2).
#
# Runs the full riscv-dv testlist against a named Ibex configuration under
# VCS with Spike cosim and coverage enabled, unattended, into a dedicated,
# never-reused results directory. Wraps the upstream Makefile rather than
# reimplementing it — this script's job is only:
#   1. pick a config, seed count and a fresh, uniquely-named output location
#      (never reuse an OUT dir across configs/tests — see bringup_log.md,
#      2026-08-15 item #4, for what goes wrong if you do),
#   2. run the regression with coverage on,
#   3. append a machine-readable summary row (via collect_coverage.sh) so
#      results stay comparable across configs and over time,
#   4. record wall-clock, since that's what sizes the next seed budget.
#
# Usage:
#   ./run_regression.sh <config> [seed_count] [testlist] [base_seed]
#
#   <config>      IBEX_CONFIG name from ../../../ibex_configs.yaml
#                 (small, maxperf, ...). This project adds the named
#                 `maxperf-icache` configuration for the C2 rung.
#   [seed_count]  iterations per test, applied uniformly to the whole
#                 testlist (overrides each test's individual `iterations:`
#                 in the yaml). Pass the literal word "native" (or omit) to
#                 use each test's own testlist-declared iteration count
#                 instead of a uniform override -- this is the plan's
#                 preferred default (S2 bringup_log.md recommendation).
#                 Per the plan's Appendix E principle 1 ("equal effort, or
#                 no comparison"), always use the SAME seed_count (or
#                 "native" for all three) across configs you intend to
#                 compare -- "native" is equal effort across configs since
#                 it applies the identical per-test counts to each.
#   [testlist]    path to a testlist yaml, relative to dv/uvm/core_ibex.
#                 Default: riscv_dv_extension/testlist.yaml (the full
#                 upstream list).
#   [base_seed]   starting seed. Default: $(date +%y%m%d), so an overnight
#                 run's seed is reproducible and dated, per the plan's S0
#                 Makefile-comment convention.
#
# Output: results/<config>/<UTC timestamp>/ (relative to the ibex repo
# root), containing the full OUT= tree (out/run/regr.log, out/run/report.html,
# out/run/coverage/report/, ...) plus this run's row appended to
# results/coverage_summary.csv and results/run_log.csv.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  cat >&2 <<'EOF'
Usage: ./run_regression.sh <config> [seed_count|native] [testlist] [base_seed]
EOF
  exit 1
fi

CONFIG="$1"
SEED_COUNT="${2:-native}"
TESTLIST="${3:-riscv_dv_extension/testlist.yaml}"
BASE_SEED="${4:-$(date +%y%m%d)}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IBEX_ROOT="$(cd "${SCRIPT_DIR}/../../.." && pwd)"
RESULTS_ROOT="${IBEX_ROOT}/results"
TIMESTAMP="$(date -u +%Y%m%d_%H%M%SZ)"
RESULTS_DIR="${RESULTS_ROOT}/${CONFIG}/${TIMESTAMP}"

if [[ -e "$RESULTS_DIR" ]]; then
  echo "error: ${RESULTS_DIR} already exists — refusing to overwrite a result." >&2
  exit 1
fi
mkdir -p "$RESULTS_DIR"

OUT_DIR="${RESULTS_DIR}/out"

# "native" means: don't override ITERATIONS at all, let each test in the
# testlist use its own declared `iterations:` count (Makefile's ITERATIONS
# default is empty, which metadata.py's arg-list mapper turns into None,
# i.e. "use the testlist's own count" -- this is the existing, already-
# working default behaviour, not a new code path).
if [[ "$SEED_COUNT" == "native" ]]; then
  ITERATIONS_DESC="native (each test's own testlist iteration count)"
  ITERATIONS_ARGS=()
else
  ITERATIONS_DESC="${SEED_COUNT} (uniform override across testlist)"
  ITERATIONS_ARGS=(ITERATIONS="$SEED_COUNT")
fi

echo "== run_regression.sh =="
echo "config:      ${CONFIG}"
echo "seed_count:  ${ITERATIONS_DESC}"
echo "testlist:    ${TESTLIST}"
echo "base_seed:   ${BASE_SEED}"
echo "results_dir: ${RESULTS_DIR}"
echo "========================"

cd "$SCRIPT_DIR"

REGRESSION_START_SECONDS=$SECONDS
REGRESSION_WALL_CLOCK_S=0
set +e
make TEST=all \
     RISCV-DV-TESTLIST="$TESTLIST" \
     "${ITERATIONS_ARGS[@]}" \
     SEED="$BASE_SEED" \
     SIMULATOR=vcs \
     ISS=spike \
     IBEX_CONFIG="$CONFIG" \
     WAVES=0 \
     COV=1 \
     OUT="$OUT_DIR" \
     2>&1 | tee "${RESULTS_DIR}/make.log"
MAKE_STATUS=${PIPESTATUS[0]}
set -e
REGRESSION_WALL_CLOCK_S=$(( SECONDS - REGRESSION_START_SECONDS ))

echo "Regression make exit status: ${MAKE_STATUS} (nonzero can just mean a test failed, not that the run is broken — check regr.log)"
echo "Wall-clock: ${REGRESSION_WALL_CLOCK_S}s"

# Append to the master coverage CSV, if the run got far enough to have a
# dashboard (i.e. didn't die before check_logs/merge_cov).
if [[ -f "${OUT_DIR}/run/coverage/report/dashboard.txt" ]]; then
  "${SCRIPT_DIR}/collect_coverage.sh" "$OUT_DIR" "$CONFIG" "${RESULTS_ROOT}/coverage_summary.csv" "$SEED_COUNT"
else
  echo "warning: no dashboard.txt produced — regression did not reach coverage merge. Skipping CSV row." >&2
fi

# Append to the run log (plan Appendix B: date, config, testlist_version, seed_count, result_path, pass, fail, notes).
RUN_LOG="${RESULTS_ROOT}/run_log.csv"
if [[ ! -f "$RUN_LOG" ]]; then
  echo "date_utc,config,testlist,seed_count,base_seed,results_dir,make_status,wall_clock_s,notes" > "$RUN_LOG"
fi
NOTES=""
[[ "$MAKE_STATUS" -ne 0 ]] && NOTES="non-zero make exit; check regr.log"
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ),${CONFIG},${TESTLIST},${SEED_COUNT},${BASE_SEED},${RESULTS_DIR},${MAKE_STATUS},${REGRESSION_WALL_CLOCK_S},${NOTES}" >> "$RUN_LOG"

echo "Done. Results in ${RESULTS_DIR}"
echo "  - ${OUT_DIR}/run/regr.log            per-test pass/fail"
echo "  - ${OUT_DIR}/run/report.html          upstream HTML test report"
echo "  - ${OUT_DIR}/run/coverage/report/     merged URG coverage report (dashboard.html etc.)"
echo "  - ${RESULTS_ROOT}/coverage_summary.csv  (this run's row appended)"
echo "  - ${RESULTS_ROOT}/run_log.csv           (this run's row appended)"

exit "$MAKE_STATUS"
