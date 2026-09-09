#!/usr/bin/env python3
"""Capture local, source-only analysis evidence; never installs tools or edits RTL.

Run from any directory. Outputs are restricted to doc/dungpc/evidence.
An existing baseline is preserved; use a new analysis directory to rebaseline.
"""
import hashlib
import importlib.metadata
import json
import os
from pathlib import Path
import platform
import shlex
import shutil
import subprocess
import sys
from datetime import datetime, timezone

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[2]

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def run(name, argv):
    try:
        p = subprocess.run(argv, cwd=ROOT, text=True, stdout=subprocess.PIPE,
                           stderr=subprocess.STDOUT, timeout=60,
                           env={**os.environ, 'PYTHONDONTWRITEBYTECODE': '1'})
        result = {'command': shlex.join(argv), 'exit_status': p.returncode,
                  'output': p.stdout}
    except FileNotFoundError as exc:
        result = {'command': shlex.join(argv), 'exit_status': None,
                  'launch_status': 'TOOL-NOT-FOUND', 'output': str(exc)}
    (OUT / (name + '.log')).write_text(json.dumps(result, indent=2) + '\n')
    return result

def main():
    if (OUT / 'baseline.json').exists():
        raise SystemExit('Baseline exists; preserve it. See reproduction instructions in 01_repository_baseline.md.')
    names = subprocess.check_output(['git', 'ls-files', '-z'], cwd=ROOT).decode().split('\0')
    manifest = []
    for name in sorted(filter(None, names)):
        p = ROOT / name
        if p.is_file():
            manifest.append({'path': name, 'sha256': digest(p), 'bytes': p.stat().st_size})
    (OUT / 'source_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    run('git_revision', ['git', 'log', '-1', '--format=fuller'])
    run('git_status_initial', ['git', 'status', '--short', '--untracked-files=all'])
    run('git_submodules', ['git', 'submodule', 'status', '--recursive'])
    patch = subprocess.check_output(['git', 'diff', '--binary', 'HEAD'], cwd=ROOT)
    (OUT / 'source_changes.patch').write_bytes(patch)
    versions = {}
    for name in ['PyYAML', 'fusesoc', 'edalize', 'pyslang', 'hjson']:
        try:
            versions[name] = importlib.metadata.version(name)
        except importlib.metadata.PackageNotFoundError:
            versions[name] = None
    commands = ['fusesoc', 'verilator', 'iverilog', 'vvp', 'yosys', 'sby', 'slang',
                'verible-verilog-lint', 'riscv32-unknown-elf-gcc', 'riscv64-unknown-elf-gcc',
                'gcc', 'make', 'python3']
    baseline = {'baseline': 'BASE-01', 'captured_utc': datetime.now(timezone.utc).isoformat(),
                'revision': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT).decode().strip(),
                'host': platform.platform(), 'python': sys.version,
                'tools': {name: shutil.which(name) for name in commands},
                'python_packages': versions,
                'relevant_environment': {name: os.environ.get(name) for name in ['IBEX_CONFIG_FILE', 'RISCV', 'RV32_TOOLCHAIN']},
                'source_manifest_sha256': digest(OUT / 'source_manifest.json'),
                'source_patch_sha256': digest(OUT / 'source_changes.patch'),
                'tracked_files_hashed': len(manifest),
                'firmware_image': None, 'execution_baseline': 'NOT-ESTABLISHED'}
    (OUT / 'baseline.json').write_text(json.dumps(baseline, indent=2) + '\n')
    run('python_version', ['python3', '--version'])
    run('config_small', ['python3', 'util/ibex_config.py', 'small', 'fusesoc_opts'])
    run('config_opentitan', ['python3', 'util/ibex_config.py', 'opentitan', 'fusesoc_opts'])
    run('fusesoc_version', ['fusesoc', '--version'])
    run('verilator_version', ['verilator', '--version'])
    run('simple_system_setup', ['fusesoc', '--cores-root=.', 'run', '--target=sim', '--setup',
                               '--build-root=doc/dungpc/evidence/build/simple_system',
                               'lowrisc:ibex:ibex_simple_system'])
    run('firmware_dry_run', ['make', '-n', '-C', 'examples/sw/simple_system/hello_test'])
    print(json.dumps(baseline, indent=2))

if __name__ == '__main__':
    main()
