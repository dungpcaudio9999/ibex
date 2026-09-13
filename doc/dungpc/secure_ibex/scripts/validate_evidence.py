#!/usr/bin/env python3
"""Mechanical validation of published links, hashes, results and active feature paths."""
import ast
import hashlib
import json
import re
import subprocess
from pathlib import Path
from run_all import BASE, CASES
ROOT=BASE.parents[2];OUT=BASE/'evidence';errors=[];links=0
for doc in BASE.glob('*.md'):
 for target in re.findall(r'\[[^\]]*\]\(([^)]+)\)',doc.read_text()):
  if target.startswith(('https:','http:','#')):continue
  file,_,anchor=target.partition('#');p=(doc.parent/file).resolve();links+=1
  if p==OUT/'validation_report.json':continue
  if not p.exists():errors.append('missing '+str(p))
  elif re.fullmatch('L[0-9]+',anchor) and int(anchor[1:])>len(p.read_text().splitlines()):errors.append('bad line '+target)
for p in (BASE/'scripts').glob('*.py'):ast.parse(p.read_text())
hashes=json.loads((OUT/'source_dependencies_sha256.json').read_text())
for name,digest in hashes.items():
 if hashlib.sha256((ROOT/name).read_bytes()).hexdigest()!=digest:errors.append('changed dependency '+name)
results=json.loads((OUT/'results.json').read_text());expected={c+'.'+t for c,tests in CASES.items() for t in tests.split(',')}
if {r['id'] for r in results}!=expected or len(results)!=len(expected):errors.append('result matrix mismatch')
for r in results:
 if r['status']!='PASS' or r['errors']:errors.append('test failed '+r['id'])
 for suffix in ('.log','.vcd.gz'):
  if not (OUT/(r['id']+suffix)).exists():errors.append('missing artifact '+r['id']+suffix)
for name in ('analysis_checks.json','checker_negative_control.json'):
 obj=json.loads((OUT/name).read_text());rr=obj if isinstance(obj,list) else [obj]
 if any(x['status']!='PASS' for x in rr):errors.append('failed '+name)
active={}
for config in CASES:
 h=json.loads((OUT/f'{config}.hierarchy.json').read_text())
 def integer(m,k):return int(m['parameters'][k][0]['name'].split('h')[-1],16)
 core=[m for m in h['parameters'] if m['original']=='ibex_core']
 if len(core)!=2:errors.append(config+' needs main and shadow core')
 if sorted(integer(m,'RegFileECC') for m in core)!=[0,1]:errors.append(config+' RF ECC split incorrect')
 for m in core:
  if any(integer(m,k)!=1 for k in ('SecureIbex','DataIndTiming','PCIncrCheck','ResetAll','MemECC')):errors.append(config+' missing secure feature')
  if integer(m,'ShadowCSR')!=0:errors.append(config+' unexpected shadow CSR')
 top=next(m for m in h['parameters'] if m['original']=='ibex_top')
 active[config]={k:integer(top,k) for k in ('SecureIbex','LockstepOffset','MemECC','ICache','ICacheECC','ICacheScramble','ICacheTweakInfection','BaseIsa','PMPEnable')}
 for bank in [m for m in h['parameters'] if m['original']=='prim_ram_1p_scr']:
  if integer(bank,'EnableParity')!=0 or integer(bank,'NumDiffRounds')!=0:errors.append(config+' unexpected RAM options')
changed=subprocess.check_output(['git','diff','--name-only','HEAD'],cwd=ROOT,text=True).splitlines()
if any(not p.startswith('doc/dungpc/') for p in changed):errors.append('production tracked changes: '+str(changed))
manifest={str(p.relative_to(BASE)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(BASE.rglob('*')) if p.is_file() and '__pycache__' not in p.parts and p.name not in ('artifact_manifest.json','validation_report.json')}
(OUT/'artifact_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
report={'status':'FAIL' if errors else 'PASS','errors':errors,'directed_runs':len(results),'analysis_checks':len(json.loads((OUT/'analysis_checks.json').read_text())),'links_checked':links,'dependencies_hashed':len(hashes),'artifacts_hashed':len(manifest),'active_parameters':active,'scope':'mechanical checks plus directed simulation oracles; not formal/security certification'}
(OUT/'validation_report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
if errors:raise SystemExit(1)
