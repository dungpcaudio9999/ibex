#!/usr/bin/env bash
# Validate the controlled variables and test population of the three Stage S3
# baseline runs. This intentionally does not judge individual test failures;
# their classifications live in doc/s3_to_s4_validation.md.

set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <c0-results-dir> <c1-results-dir> <c2-results-dir>" >&2
  exit 1
fi

RUN_DIRS=("$1" "$2" "$3")
EXPECTED_CONFIGS=(small maxperf maxperf-icache)

metadata_value() {
  local metadata_file="$1"
  local key="$2"
  sed -n "s/^${key}:[[:space:]]*//p" "$metadata_file" | head -1
}

test_ids() {
  local regr_log="$1"
  # Failure entries can span multiple indented lines that also contain
  # colons. Accept only the leading test_name.numeric_seed field.
  sed -n 's/^\([[:alnum:]_]*\.[0-9][0-9]*\):.*/\1/p' "$regr_log" | sort
}

check_equal() {
  local label="$1"
  local actual="$2"
  local expected="$3"
  if [[ "$actual" != "$expected" ]]; then
    echo "FAIL: ${label}: expected '${expected}', got '${actual}'" >&2
    exit 1
  fi
}

for index in 0 1 2; do
  run_dir="${RUN_DIRS[$index]}"
  metadata_file="${run_dir}/out/metadata/metadata.yaml"
  regr_log="${run_dir}/out/run/regr.log"
  dashboard="${run_dir}/out/run/coverage/report/dashboard.txt"
  coverage_tests="${run_dir}/out/run/coverage/report/tests.txt"

  for required_file in "$metadata_file" "$regr_log" "$dashboard" "$coverage_tests"; do
    if [[ ! -f "$required_file" ]]; then
      echo "FAIL: required artifact missing: ${required_file}" >&2
      exit 1
    fi
  done

  check_equal "config" "$(metadata_value "$metadata_file" ibex_config)" \
    "${EXPECTED_CONFIGS[$index]}"
  check_equal "base seed" "$(metadata_value "$metadata_file" seed)" "260816"
  check_equal "coverage" "$(metadata_value "$metadata_file" cov)" "True"
  check_equal "waves" "$(metadata_value "$metadata_file" waves)" "False"
  check_equal "simulator" "$(metadata_value "$metadata_file" simulator)" "vcs"
  check_equal "ISS" "$(metadata_value "$metadata_file" iss)" "spike"
  check_equal "test selector" "$(metadata_value "$metadata_file" test)" "all"
  check_equal "testlist" "$(metadata_value "$metadata_file" riscvdv_testlist_arg)" \
    "riscv_dv_extension/testlist_c_ladder.yaml"
  check_equal "iteration override" "$(metadata_value "$metadata_file" iterations)" ""
  check_equal "signature address" "$(metadata_value "$metadata_file" signature_addr)" \
    "8ffffffc"

  test_count="$(test_ids "$regr_log" | wc -l)"
  check_equal "test iteration count" "$test_count" "480"
  unique_test_count="$(test_ids "$regr_log" | sort -u | wc -l)"
  check_equal "unique test iteration count" "$unique_test_count" "480"
  # URG records the 480 RTL simulations plus the single riscv-dv functional
  # coverage-generator run. This also confirms failed RTL tests were retained
  # by the baseline's deliberate all-scheduled-iterations policy.
  coverage_test_count="$(sed -n 's/^Total tests in report: //p' "$coverage_tests")"
  check_equal "URG test record count" "$coverage_test_count" "481"

  if rg -q 'Error-\[FCIBH\]|Error-\[ICSD\]' "${run_dir}/out/run/tests"; then
    echo "FAIL: infrastructure error FCIBH or ICSD found under ${run_dir}" >&2
    exit 1
  fi

  echo "PASS controls: ${EXPECTED_CONFIGS[$index]}"
  head -1 "$regr_log"
  awk '/^SCORE[[:space:]]+LINE[[:space:]]+TOGGLE/{getline; print "coverage:", $0; exit}' \
    "$dashboard"
done

if ! diff -u <(test_ids "${RUN_DIRS[0]}/out/run/regr.log") \
                   <(test_ids "${RUN_DIRS[1]}/out/run/regr.log"); then
  echo "FAIL: C0 and C1 test iteration sets differ" >&2
  exit 1
fi

if ! diff -u <(test_ids "${RUN_DIRS[0]}/out/run/regr.log") \
                   <(test_ids "${RUN_DIRS[2]}/out/run/regr.log"); then
  echo "FAIL: C0 and C2 test iteration sets differ" >&2
  exit 1
fi

echo "PASS: S3 controlled variables and all 480 test/seed identifiers match."
