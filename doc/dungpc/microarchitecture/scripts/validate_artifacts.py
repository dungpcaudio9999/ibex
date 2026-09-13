#!/usr/bin/env python3
"""Validate links, baseline hashes, active configurations and result/artifact consistency."""
import ast
import hashlib
import json
import re
import subprocess
from pathlib import Path
from run_core import ROOT, OUT, HERE

base=HERE.parent
errors=[]
links=0
for path in sorted(base.glob('*.md')):
    for target in re.findall(r'\[[^\]]*\]\(([^)]+)\)',path.read_text()):
        if target.startswith(('https://','http://','#')):continue
        file,_,anchor=target.partition('#')
        dest=(path.parent/file).resolve()
        links+=1
        if dest == OUT/'validation_report.json':continue  # Generated at the end of this run.
        if not dest.exists():errors.append(f'{path.name}: missing {target}')
        elif re.fullmatch(r'L\d+',anchor) and int(anchor[1:])>len(dest.read_text().splitlines()):
            errors.append(f'{path.name}: line out of range {target}')
for path in HERE.glob('*.py'):ast.parse(path.read_text(),filename=str(path))
hashes=json.loads((OUT/'source_dependencies_sha256.json').read_text())
for file,digest in hashes.items():
    if hashlib.sha256((ROOT/file).read_bytes()).hexdigest()!=digest:
        errors.append(f'changed source dependency: {file}')
counts={}
for file in ('core_results.json','trace_checks.json','unit_results.json'):
    rows=json.loads((OUT/file).read_text())
    counts[file]=len(rows)
    if any(row['status']!='PASS' for row in rows):errors.append(f'failure in {file}')
    if len({row['id'] for row in rows})!=len(rows):errors.append(f'duplicate ids in {file}')
if counts['core_results.json']!=160 or counts['trace_checks.json']!=160:
    errors.append('expected 160 core runs and trace checks')
units=json.loads((OUT/'unit_results.json').read_text())
if sum(row['checks'] for row in units)!=20:errors.append('expected 20 unit checks')
extended=OUT/'extended'
for name,n in [('results.json',21),('ordering_checks.json',6)]:
    rows=json.loads((extended/name).read_text())
    counts['extended/'+name]=len(rows)
    if len(rows)!=n or any(row['status']!='PASS' for row in rows):
        errors.append('failed extended checks '+name)
config_values={}
for name,expected in {'small':(0,0,2),'wb':(1,0,2),'bt':(0,1,2),'single':(1,1,3),'slow':(0,0,1)}.items():
    hierarchy=json.loads((OUT/f'{name}.hierarchy.json').read_text())
    core=next(m for m in hierarchy['parameters'] if m['original']=='ibex_core')
    vals={}
    for key in ('BaseIsa','WritebackStage','BranchTargetALU','RV32M','RV32ZC','ICache','SecureIbex'):
        literal=core['parameters'][key][0]['name']
        vals[key]=int(literal.split('h')[-1],16)
    if tuple(vals[k] for k in ('WritebackStage','BranchTargetALU','RV32M'))!=expected:
        errors.append(f'wrong active config {name}: {vals}')
    if any(vals[k] for k in ('BaseIsa','RV32ZC','ICache','SecureIbex')):
        errors.append(f'wrong baseline feature in {name}')
    config_values[name]=vals
changed=subprocess.check_output(['git','diff','--name-only','HEAD'],cwd=ROOT,text=True).splitlines()
outside=[p for p in changed if not p.startswith(('doc/dungpc/microarchitecture/','doc/dungpc/secure_ibex/'))]
if outside:errors.append(f'tracked files changed outside deliverable: {outside}')
manifest={}
for path in sorted(base.rglob('*')):
    if not path.is_file() or '__pycache__' in path.parts or path.name in ('artifact_manifest.json','validation_report.json'):continue
    manifest[str(path.relative_to(base))]=hashlib.sha256(path.read_bytes()).hexdigest()
(OUT/'artifact_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
report={'status':'FAIL' if errors else 'PASS','errors':errors,'local_links_checked':links,
        'source_dependencies_checked':len(hashes),'artifact_files_hashed':len(manifest),
        'result_counts':counts,'unit_checks':sum(r['checks'] for r in units),'active_core_parameters':config_values,
        'scope':'Mechanical consistency and reported directed tests; not an independent technical review.'}
(OUT/'validation_report.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2))
if errors:raise SystemExit(1)
