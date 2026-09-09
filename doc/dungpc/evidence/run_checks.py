#!/usr/bin/env python3
"""Run the documented source/model checks, recording exact process outcomes.

No HDL simulation is performed. Existing per-check outputs are replaced;
baseline and source manifests are never changed.
"""
from datetime import datetime, timezone
import json
from pathlib import Path
import subprocess
import sys

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[2]

def main():
    cases = [
        ('EVD-03', 'audit_run', ['python3', 'doc/dungpc/evidence/source_audit.py'], 0),
        ('EVD-06', 'model_run', ['python3', 'doc/dungpc/evidence/model_experiments.py'], 0),
        ('EVD-07', 'model_negative_run', ['python3', 'doc/dungpc/evidence/model_experiments.py', '--corrupt-check'], 1),
        ('EVD-09', 'uvm_vcs_options', ['python3', 'util/ibex_config.py', 'small', 'vcs_opts',
                                    '--ins_hier_path', 'core_ibex_tb_top',
                                    '--string_define_prefix', 'IBEX_CFG_'], 0),
    ]
    runs = []
    markers = {'audit_run': 'Inventory completed', 'model_run': 'PREDICTIONS-MATCH-MODEL',
               'model_negative_run': 'EXPECTED-NEGATIVE-DETECTED',
               'uvm_vcs_options': '+define+IBEX_CFG_BaseIsa=ibex_pkg::BaseIsaRV32I'}
    for evidence_id, name, command, expected in cases:
        p = subprocess.run(command, cwd=ROOT, text=True, stdout=subprocess.PIPE,
                           stderr=subprocess.STDOUT, timeout=60)
        record = {'evidence_id': evidence_id, 'command_argv': command,
                  'cwd': str(ROOT), 'run_utc': datetime.now(timezone.utc).isoformat(),
                  'exit_status': p.returncode, 'expected_exit_status': expected,
                  'expected_exit_matched': p.returncode == expected, 'output': p.stdout,
                  'expected_marker': markers[name],
                  'expected_marker_present': markers[name] in p.stdout,
                  'RTL_simulation_performed': False}
        (OUT / (name + '.log')).write_text(json.dumps(record, indent=2) + '\n')
        runs.append(record)
    (OUT / 'check_runs.json').write_text(json.dumps(runs, indent=2) + '\n')
    # Small immutable-source extracts make important claims reviewable without
    # presenting a text search as compiler or elaboration evidence.
    extracts = {
        'examples/simple_system/rtl/ibex_simple_system.sv': [(25, 31), (55, 65), (116, 138), (245, 315)],
        'rtl/ibex_if_stage.sv': [(219, 256)],
        'rtl/ibex_top.sv': [(207, 235), (304, 339), (623, 658), (1275, 1284), (1361, 1371)],
        'rtl/ibex_trvk.sv': [(313, 379), (396, 420)],
        'rtl/ibex_core.sv': [(1620, 1638)],
        'shared/rtl/timer.sv': [(72, 114)],
        'shared/rtl/ram_2p.sv': [(41, 53)],
        'shared/rtl/bus.sv': [(96, 116)],
        'vendor/lowrisc_ip/ip/prim/rtl/prim_assert.sv': [(102, 113)],
        'vendor/lowrisc_ip/ip/prim/rtl/prim_assert_dummy_macros.svh': [(1, 30)],
        'dv/formal/check/protocol/mem.sv': [(14, 63)],
        'dv/formal/check/top.sv': [(162, 197)],
        'dv/formal/thm/riscv.proof': [(134, 138), (167, 180)],
        'dv/uvm/core_ibex/tb/core_ibex_tb_top.sv': [(43, 80), (101, 117), (182, 189), (208, 235)],
        'dv/uvm/core_ibex/scripts/ibex_cmd.py': [(33, 60)],
    }
    revision = json.loads((OUT / 'baseline.json').read_text())['revision']
    blocks = [f'EVD-08 — source excerpts, revision {revision}\nSource-only; no elaboration or runtime assertion evidence.\n']
    for name, ranges in extracts.items():
        lines = (ROOT / name).read_text().splitlines()
        blocks.append('\nFILE ' + name)
        for start, end in ranges:
            blocks.append('\n'.join(f'{i}: {lines[i-1]}' for i in range(start, min(end, len(lines)) + 1)))
    (OUT / 'source_extracts.txt').write_text('\n'.join(blocks) + '\n')
    ok = all(run['expected_exit_matched'] and run['expected_marker_present'] for run in runs)
    print(json.dumps({'all_expected_exits_matched': ok, 'checks': len(runs), 'RTL_simulation_performed': False}))
    return 0 if ok else 1

if __name__ == '__main__':
    sys.exit(main())
