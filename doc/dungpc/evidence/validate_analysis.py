#!/usr/bin/env python3
"""Mechanical QA of this analysis deliverable; no claim of RTL correctness.

Validate local links, findings, evidence labels, Python syntax, recorded
outcomes, and all baseline source hashes. Emit a report and artifact hashes.
"""
import ast
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
from urllib.parse import unquote

OUT = Path(__file__).resolve().parent
DOC = OUT.parent
ROOT = OUT.parents[2]
GUIDE = DOC / 'rtl_soc_source_analysis_guide_v3.1.md'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def main():
    errors = []
    docs = sorted(p for p in DOC.rglob('*.md') if p != GUIDE)
    all_text = '\n'.join(p.read_text() for p in docs)
    future = {OUT / 'validation_report.json', OUT / 'artifact_manifest.json'}
    link_count = 0
    for path in docs:
        content = path.read_text()
        if len(re.findall(r'^```', content, re.M)) % 2:
            errors.append(f'Unbalanced code fence: {path.relative_to(ROOT)}')
        for char in ['\u200b', '\u200c', '\u200d', '\ufeff']:
            if char in content:
                errors.append(f'Invisible formatting character in {path.relative_to(ROOT)}')
        for target in re.findall(r'\[[^\]\n]*\]\(([^)\n]+)\)', content):
            if target.startswith(('http:', 'https:', '#', 'mailto:')):
                continue
            target = unquote(target.strip('<>'))
            name, _, fragment = target.partition('#')
            destination = (path.parent / name).resolve()
            link_count += 1
            if not destination.exists() and destination not in future:
                errors.append(f'Broken local link: {path.relative_to(ROOT)} -> {target}')
            if destination.is_file() and re.fullmatch(r'L\d+', fragment):
                line = int(fragment[1:])
                if line < 1 or line > len(destination.read_text().splitlines()):
                    errors.append(f'Invalid line anchor: {target}')
    used_findings = set(re.findall(r'\bFND-[A-Z0-9]+-\d+\b', all_text))
    defined_findings = set(re.findall(r'(?m)^(?:#{1,6}\s+|\*\*)(FND-[A-Z0-9]+-\d+)', all_text))
    missing_findings = used_findings - defined_findings
    if missing_findings:
        errors.append('Finding references without record: ' + ', '.join(sorted(missing_findings)))
    known_evidence = set(re.findall(r'\bEVD-\d+\b', (OUT / 'README.md').read_text()))
    missing_evidence = set(re.findall(r'\bEVD-\d+\b', all_text)) - known_evidence
    if missing_evidence:
        errors.append('Evidence references without index: ' + ', '.join(sorted(missing_evidence)))
    known_questions = set(re.findall(r'\| (OQ-\d+) \|', (DOC / '13_open_questions.md').read_text()))
    missing_questions = set(re.findall(r'\bOQ-\d+\b', all_text)) - known_questions
    if missing_questions:
        errors.append('OQ references without register: ' + ', '.join(sorted(missing_questions)))
    valid_results = {'DECLARED', 'ESTABLISHED', 'OBSERVED', 'PROVED', 'BOUNDED-PASS',
                     'REFUTED', 'INCONCLUSIVE', 'NOT-RUN'}
    for kind, result in re.findall(r'\b(SPEC|RTL|SIM|FORMAL|STATIC|SILICON):([A-Z-]+)', all_text):
        if result not in valid_results:
            errors.append(f'Invalid evidence result: {kind}:{result}')
    for path in OUT.glob('*.py'):
        try:
            ast.parse(path.read_text(), filename=str(path))
        except SyntaxError as exc:
            errors.append(str(exc))
    baseline = json.loads((OUT / 'baseline.json').read_text())
    if sha(OUT / 'source_manifest.json') != baseline['source_manifest_sha256']:
        errors.append('Source manifest digest changed')
    if sha(OUT / 'source_changes.patch') != baseline['source_patch_sha256']:
        errors.append('Preserved source patch digest changed')
    entries = json.loads((OUT / 'source_manifest.json').read_text())
    changed = []
    for entry in entries:
        path = ROOT / entry['path']
        if not path.is_file() or sha(path) != entry['sha256']:
            changed.append(entry['path'])
    if changed:
        errors.append('Baseline source inputs changed: ' + ', '.join(changed))
    diff = subprocess.check_output(['git', 'diff', '--binary', 'HEAD'], cwd=ROOT)
    if diff != (OUT / 'source_changes.patch').read_bytes():
        errors.append('Current tracked-source patch differs from baseline')
    runs = json.loads((OUT / 'check_runs.json').read_text())
    if not all(r['expected_exit_matched'] and r['expected_marker_present'] for r in runs):
        errors.append('Unexpected check process outcome')
    positive = json.loads((OUT / 'model_positive.json').read_text())
    negative = json.loads((OUT / 'model_negative.json').read_text())
    if positive['result'] != 'PREDICTIONS-MATCH-MODEL' or len(positive['timer_trace']) != 10:
        errors.append('Positive model evidence does not match documented result')
    if negative['result'] != 'EXPECTED-NEGATIVE-DETECTED' or negative['edge'] != 5:
        errors.append('Negative evidence does not show intended comparator failure')
    status = subprocess.check_output(['git', 'status', '--short', '--untracked-files=all'], cwd=ROOT).decode()
    outside = [line for line in status.splitlines() if not line[3:].startswith('doc/dungpc/')]
    if outside:
        errors.append('Worktree changes outside requested output directory: ' + '\n'.join(outside))
    report = {'validation_utc': datetime.now(timezone.utc).isoformat(),
              'source_baseline': baseline['revision'],
              'status': 'PASS' if not errors else 'FAIL',
              'analysis_markdown_files': len(docs), 'local_links_checked': link_count,
              'source_files_hash_verified': len(entries), 'source_files_changed': changed,
              'findings_with_records': sorted(defined_findings),
              'questions_indexed': sorted(known_questions),
              'evidence_indexed': sorted(known_evidence),
              'tracked_patch_unchanged': diff == (OUT / 'source_changes.patch').read_bytes(),
              'all_changes_inside_doc_dungpc': not outside,
              'checks': 'Links and line bounds, ID references, evidence label vocabulary, Python AST, process outcomes, baseline hashes and worktree scope',
              'limitations': 'Mechanical document QA only. No HDL compile/simulation, formal proof, technical peer review or physical validation.',
              'errors': errors}
    (OUT / 'validation_report.json').write_text(json.dumps(report, indent=2) + '\n')
    manifest = []
    for path in sorted(DOC.rglob('*')):
        if path.is_file() and path not in {GUIDE, OUT / 'artifact_manifest.json'} and '__pycache__' not in path.parts:
            manifest.append({'path': str(path.relative_to(DOC)), 'sha256': sha(path), 'bytes': path.stat().st_size})
    (OUT / 'artifact_manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print(json.dumps(report, indent=2))
    return 0 if not errors else 1

if __name__ == '__main__':
    sys.exit(main())
