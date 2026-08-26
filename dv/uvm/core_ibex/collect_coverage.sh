#!/usr/bin/env bash
# Copyright lowRISC contributors is NOT the author of this file — internal
# project script for the Ibex UVM/VCS verification work
# (see ../../../../doc/ibex_uvm_vcs_internship_execution_plan.md, Stage S2).
#
# Merge + report is already automatic in the upstream flow when COV=1
# (wrapper.mk -> scripts/merge_cov.py -> `urg`, producing
# <OUT>/run/coverage/report/dashboard.txt). What upstream does NOT do is turn
# that into a machine-readable summary for VCS runs: scripts/collect_results.py
# only implements create_cov_summary_dict() for the xlm (Xcelium) simulator —
# for vcs it prints "Warning: Not generating coverage summary, unsupported
# simulator vcs" and moves on. This script fills that specific gap.
#
# Usage: ./collect_coverage.sh <out_dir> <config> <csv_path> [seed_count] [exclusion_elfile]
#
#   <out_dir>    an OUT= directory from a completed `make ... COV=1` run
#                (must contain run/coverage/report/dashboard.txt and
#                run/regr.log)
#   <config>     the IBEX_CONFIG name that was used (small, maxperf, ...)
#   <csv_path>   CSV file to append a summary row to (created with a header
#                if it doesn't exist yet)
#   [seed_count] optional, recorded verbatim in the row for traceability
#   [exclusion_elfile] optional. If given, re-report the SAME merged.vdb
#                with `urg -elfile <file>` applied and append a SECOND row
#                (excluded=true) alongside the normal row (excluded=false)
#                -- Stage S4/S5's "with and without exclusions" pair for
#                Chapter 6, per doc/s7_readiness_worklist.md item 5. Verify
#                <exclusion_elfile> against a real build first
#                (waivers/s4_functional_coverage_exclusions.el documents
#                how); a stale/mismatched checksum makes urg reject entries
#                silently rather than erroring the whole run.
#
# Never overwrites: always appends. Callers are responsible for using a
# fresh <out_dir> per run (see run_regression.sh) so numbers stay traceable
# to a stored run, per the execution plan's Appendix E principle 5.

set -euo pipefail

if [[ $# -lt 3 ]]; then
  echo "Usage: $0 <out_dir> <config> <csv_path> [seed_count]" >&2
  exit 1
fi

OUT_DIR="$1"
CONFIG="$2"
CSV_PATH="$3"
SEED_COUNT="${4:-}"
EXCLUSION_ELFILE="${5:-}"

DASHBOARD="${OUT_DIR}/run/coverage/report/dashboard.txt"
REGR_LOG="${OUT_DIR}/run/regr.log"

if [[ ! -f "$DASHBOARD" ]]; then
  echo "error: $DASHBOARD not found — was this run made with COV=1?" >&2
  exit 1
fi
if [[ ! -f "$REGR_LOG" ]]; then
  echo "error: $REGR_LOG not found — regression did not complete?" >&2
  exit 1
fi
if [[ -n "$EXCLUSION_ELFILE" && ! -f "$EXCLUSION_ELFILE" ]]; then
  echo "error: exclusion_elfile $EXCLUSION_ELFILE not found" >&2
  exit 1
fi

# "Total Coverage Summary" block in dashboard.txt looks like:
#   SCORE  LINE   TOGGLE FSM    BRANCH ASSERT GROUP
#    48.94  63.71  31.27  27.78  61.02 --      60.90
# Match on the header row itself (not a fixed line offset from the title —
# the blank-line spacing around the title varies between urg runs) and take
# the very next line as the data row. ASSERT is often "--" (no assertions
# instrumented / hit) — normalize to empty rather than a bogus 0.
read_coverage_row() {
  awk '/^SCORE[[:space:]]+LINE[[:space:]]+TOGGLE[[:space:]]+FSM[[:space:]]+BRANCH[[:space:]]+ASSERT[[:space:]]+GROUP/{getline; print; exit}' "$1"
}

read -r SCORE LINE TOGGLE FSM BRANCH ASSERT GROUP < <(read_coverage_row "$DASHBOARD")
[[ "$ASSERT" == "--" ]] && ASSERT=""

# regr.log first line: "100.00% PASS 3 PASSED, 0 FAILED"
SUMMARY_LINE=$(head -1 "$REGR_LOG")
PASS_PCT=$(sed -n 's/^\([0-9.]*\)% PASS.*/\1/p' <<<"$SUMMARY_LINE")
PASSED=$(sed -n 's/.*PASS \([0-9]*\) PASSED.*/\1/p' <<<"$SUMMARY_LINE")
FAILED=$(sed -n 's/.*, \([0-9]*\) FAILED.*/\1/p' <<<"$SUMMARY_LINE")
TOTAL=$(( PASSED + FAILED ))

DATE_UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)
IBEX_COMMIT=$(cd "$(dirname "$0")/../../.." && git rev-parse HEAD 2>/dev/null || echo "unknown")

if [[ ! -f "$CSV_PATH" ]]; then
  echo "date_utc,ibex_commit,config,seed_count,excluded,tests_total,tests_passed,tests_failed,pass_pct,line_pct,toggle_pct,fsm_pct,branch_pct,assert_pct,group_pct,out_dir" > "$CSV_PATH"
fi

echo "${DATE_UTC},${IBEX_COMMIT},${CONFIG},${SEED_COUNT},false,${TOTAL},${PASSED},${FAILED},${PASS_PCT},${LINE},${TOGGLE},${FSM},${BRANCH},${ASSERT},${GROUP},${OUT_DIR}" >> "$CSV_PATH"

echo "Appended coverage summary to ${CSV_PATH}:"
tail -1 "$CSV_PATH"

# Optional second pass: re-report the same merged.vdb with the exclusion
# file applied, so both figures (Chapter 6's "with and without exclusions")
# come from the exact same underlying coverage data, not two different runs.
if [[ -n "$EXCLUSION_ELFILE" ]]; then
  MERGED_VDB="${OUT_DIR}/run/coverage/merged.vdb"
  if [[ ! -e "$MERGED_VDB" ]]; then
    echo "error: $MERGED_VDB not found — expected next to $DASHBOARD" >&2
    exit 1
  fi
  EXCLUDED_REPORT_DIR="${OUT_DIR}/run/coverage/report_excluded"
  EXCLUDED_LOG="${OUT_DIR}/run/coverage/merge_excluded.log"
  urg -full64 -format both \
    -dir "$MERGED_VDB" \
    -elfile "$EXCLUSION_ELFILE" \
    -report "$EXCLUDED_REPORT_DIR" \
    -log "$EXCLUDED_LOG"

  EXCLUDED_DASHBOARD="${EXCLUDED_REPORT_DIR}/dashboard.txt"
  if [[ ! -f "$EXCLUDED_DASHBOARD" ]]; then
    echo "error: $EXCLUDED_DASHBOARD not produced — check $EXCLUDED_LOG" >&2
    exit 1
  fi

  read -r SCORE_X LINE_X TOGGLE_X FSM_X BRANCH_X ASSERT_X GROUP_X < <(read_coverage_row "$EXCLUDED_DASHBOARD")
  [[ "$ASSERT_X" == "--" ]] && ASSERT_X=""

  echo "${DATE_UTC},${IBEX_COMMIT},${CONFIG},${SEED_COUNT},true,${TOTAL},${PASSED},${FAILED},${PASS_PCT},${LINE_X},${TOGGLE_X},${FSM_X},${BRANCH_X},${ASSERT_X},${GROUP_X},${EXCLUDED_REPORT_DIR}" >> "$CSV_PATH"

  echo "Appended WITH-EXCLUSIONS coverage summary to ${CSV_PATH}:"
  tail -1 "$CSV_PATH"
fi
