#!/usr/bin/env python3
"""Classify every uncovered C1 pipe_cross bin for the bounded S4 analysis."""

# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

import argparse
import csv
import itertools
import re
import sys
from pathlib import Path


EXPECTED_UNIVERSE = 516
EXPECTED_COVERED = 273
EXPECTED_MISSING = 243


def parse_covered_bins(report: Path):
    text = report.read_text(encoding="utf-8", errors="replace")
    starts = [m.start() for m in re.finditer(r"^Summary for Cross pipe_cross$", text, re.M)]
    if not starts:
        raise ValueError(f"no pipe_cross summary in {report}")

    # The merged report contains one instance per core.  Both have identical
    # bin topology; S4 deliberately analyzes the first reported instance.
    section = text[starts[0]:]
    next_summary = re.search(r"^Summary for ", section[1:], re.M)
    if next_summary:
        section = section[:next_summary.start() + 1]

    covered_marker = section.find("\nCovered bins\n")
    if covered_marker < 0:
        raise ValueError("pipe_cross has no Covered bins section")
    covered_text = section[covered_marker:]

    rows = set()
    row_re = re.compile(
        r"^(auto_InstrCategory\S+)\s+"
        r"(auto_IFStage\S+)\s+"
        r"(auto_PipeStage\S+)\s+"
        r"(auto_PipeStage\S+)\s+\d+\s+\d+\s*$"
    )
    for line in covered_text.splitlines():
        match = row_re.match(line)
        if match:
            rows.add(tuple(value.removeprefix("auto_") for value in match.groups()))
    if not rows:
        raise ValueError("failed to parse any covered pipe_cross bins")
    return rows


def classify(covered):
    categories = sorted({row[0] for row in covered})
    if_states = sorted({row[1] for row in covered})
    id_states = sorted({row[2] for row in covered})
    wb_states = sorted({row[3] for row in covered})

    universe = {
        row for row in itertools.product(categories, if_states, id_states, wb_states)
        if ((row[0] == "InstrCategoryNone") == (row[2] == "PipeStageEmpty"))
    }
    missing = sorted(universe - covered)

    if len(universe) != EXPECTED_UNIVERSE:
        raise ValueError(f"expected {EXPECTED_UNIVERSE} legal bins, found {len(universe)}")
    if len(covered) != EXPECTED_COVERED:
        raise ValueError(f"expected {EXPECTED_COVERED} covered bins, found {len(covered)}")
    if len(missing) != EXPECTED_MISSING:
        raise ValueError(f"expected {EXPECTED_MISSING} holes, found {len(missing)}")

    classified = []
    for category, if_state, id_state, wb_state in missing:
        if id_state == "PipeStageFullAndUnstalled" and (
                if_state.endswith("AndIdle") or wb_state == "PipeStageFullAndStalled"):
            cls = "C"
            family = "unstalled_ID_conflicts_with_backpressure"
            evidence = (
                "An unstalled valid ID instruction cannot coexist with an idle IF stage "
                "or a WB-stalled outstanding memory access."
            )
        else:
            cls = "A"
            family = "legal_state_tuple_missing_instruction_stimulus"
            state_tuple = (if_state, id_state, wb_state)
            state_seen = any(row[1:] == state_tuple for row in covered)
            category_seen = any(row[0] == category for row in covered)
            if not (state_seen and category_seen):
                raise ValueError(f"orthogonal reachability evidence missing for {(category,) + state_tuple}")
            evidence = (
                "The state tuple is covered with another instruction category and this "
                "instruction category is covered in another state tuple."
            )
        classified.append(((category, if_state, id_state, wb_state), cls, family, evidence))
    return classified


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("grpinfo", type=Path, help="C1 VCS group report (grpinfo.txt)")
    parser.add_argument("--output", type=Path, help="write exact-bin CSV here (default: stdout)")
    args = parser.parse_args()

    classified = classify(parse_covered_bins(args.grpinfo))
    output = args.output.open("w", newline="", encoding="utf-8") if args.output else sys.stdout
    try:
        writer = csv.writer(output)
        writer.writerow(("instruction_category", "if_state", "id_state", "wb_state",
                         "class", "family", "evidence"))
        for row, cls, family, evidence in classified:
            writer.writerow((*row, cls, family, evidence))
    finally:
        if args.output:
            output.close()

    counts = {cls: sum(1 for _, item_cls, _, _ in classified if item_cls == cls)
              for cls in ("A", "C")}
    print(f"pipe_cross: {len(classified)} holes; A={counts['A']}, C={counts['C']}",
          file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
