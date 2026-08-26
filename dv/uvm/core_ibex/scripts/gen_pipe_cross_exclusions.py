#!/usr/bin/env python3
"""Generate the VCS group-coverage exclusion section (`bins {...}` lines
under `coveritem "pipe_cross"`) for the class-C rows of the S4 pipe_cross
family register (doc/s4_pipe_cross_families.csv, produced by
analyze_s4_pipe_cross.py). Companion to
waivers/s4_functional_coverage_exclusions.el -- see doc/s5_worklist.md and
doc/s7_readiness_worklist.md item 5.

Output is meant to be pasted under the `coveritem "pipe_cross"` line of that
.el file's `uarch_cg` CHECKSUM/ANNOTATION/covergroup block -- see that file
for the verified header this block belongs under (verified by round-trip
through a real `urg -elfile` run, doc/s7_readiness_worklist.md item 5).

Each generated line has the exact syntax VCS's own
`urg -dump full_exclusions group` produces for an existing bin (confirmed
against a real dump from this project's build, not guessed):

  bins {{"auto_<category>"}, {"auto_<if_state>"}, {"auto_<id_state>"}, {"auto_<wb_state>"}}
"""

# Copyright lowRISC contributors.
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

import argparse
import csv
import sys
from pathlib import Path

FAMILY_HOLE_IDS = {
    "unstalled_ID_conflicts_with_backpressure": "S4-WB-010",
    "special_req_forces_retain_id": "S4-WB-011",
}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("families_csv", type=Path,
                         help="doc/s4_pipe_cross_families.csv")
    parser.add_argument("--output", type=Path,
                         help="write here (default: stdout)")
    args = parser.parse_args()

    rows = [r for r in csv.DictReader(args.families_csv.open())
            if r["class"] == "C"]
    if not rows:
        raise SystemExit(f"no class-C rows found in {args.families_csv}")

    unknown_families = {r["family"] for r in rows} - set(FAMILY_HOLE_IDS)
    if unknown_families:
        raise SystemExit(f"unrecognized family/families: {unknown_families} "
                          "-- add to FAMILY_HOLE_IDS before regenerating")

    rows.sort(key=lambda r: (r["family"], r["instruction_category"],
                              r["if_state"], r["id_state"], r["wb_state"]))

    out = args.output.open("w", newline="\n") if args.output else sys.stdout
    try:
        counts = {}
        last_family = None
        for r in rows:
            family = r["family"]
            counts[family] = counts.get(family, 0) + 1
            if family != last_family:
                out.write(f'\t\t// {FAMILY_HOLE_IDS[family]} ({family})\n')
                last_family = family
            item = (f'{{{{"auto_{r["instruction_category"]}"}}, '
                    f'{{"auto_{r["if_state"]}"}}, '
                    f'{{"auto_{r["id_state"]}"}}, '
                    f'{{"auto_{r["wb_state"]}"}}}}')
            out.write(f'\t\tbins {item}\n')
        print(f"generated {len(rows)} bin lines: {counts}", file=sys.stderr)
    finally:
        if args.output:
            out.close()
    return 0


if __name__ == "__main__":
    sys.exit(main())
