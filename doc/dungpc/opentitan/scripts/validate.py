#!/usr/bin/env python3
"""Verify published evidence; --seal explicitly records a new artifact manifest."""
import argparse,ast,gzip,hashlib,json,re,subprocess
from pathlib import Path
import yaml
from run import ROOT,BASE,OUT,HERE,CASES,make_case
ap=argparse.ArgumentParser();ap.add_argument('--seal',action='store_true');args=ap.parse_args()
errors=[];links=0
def require(ok,why):
 if not ok:errors.append(why)
for doc in BASE.glob('*.md'):
 for target in re.findall(r'\[[^\]]*\]\(([^)]+)\)',doc.read_text()):
  if target.startswith(('http:','https:','#')):continue
  file,_,anchor=target.partition('#');p=(doc.parent/file).resolve();links+=1
  if p==OUT/'validation_report.json':continue
  require(p.exists(),'missing link '+target)
  if p.is_file() and re.fullmatch(r'L\d+',anchor):require(0<int(anchor[1:])<=len(p.read_text().splitlines()),'invalid line '+target)
for p in HERE.glob('*.py'):ast.parse(p.read_text())
deps=json.loads((OUT/'source_dependencies_sha256.json').read_text())
for name,digest in deps.items():require(hashlib.sha256((ROOT/name).read_bytes()).hexdigest()==digest,'dependency changed '+name)
require((HERE/'run.py').read_bytes()==(OUT/'runner_snapshot.py').read_bytes(),'runner archive stale')
require((HERE/'opentitan_tb.sv').read_bytes()==(OUT/'opentitan_tb.sv').read_bytes(),'harness archive stale')
require(yaml.safe_load((ROOT/'ibex_configs.yaml').read_text())['opentitan']==json.loads((OUT/'preset.json').read_text()),'YAML changed')
rows=json.loads((OUT/'results.json').read_text())
require(len(rows)==len(CASES) and {r['id'] for r in rows}==set(CASES),'case matrix mismatch')
for r in rows:
 tag=r['id'];mode,name,lat=CASES[tag];mem,debug,expected,_,activity=make_case(name,mode)
 require(r['status']=='PASS' and not r['errors'],'failed case '+tag)
 require(r['mode']==mode and r['latency']==lat,'stimulus mode/latency '+tag)
 for suffix,words in [('.hex',mem),('.debug.hex',debug)]:
  actual=[int(s,16) for s in (OUT/(tag+suffix)).read_text().splitlines()]
  require(actual==words,'program mismatch '+tag+suffix)
 log=(OUT/(tag+'.log')).read_text()
 regs={int(s[1]):int(s[2],16) for l in log.splitlines() if (s:=l.split()) and s[0]=='REG'}
 require(all(regs.get(reg)==v for reg,v in expected.items()),'register oracle '+tag)
 count_lines=[l for l in log.splitlines() if l.startswith('COUNTS ')]
 cc={k:int(v) for k,v in (w.split('=') for w in count_lines[0].split()[1:])} if count_lines else {}
 require(cc==r['counts'] and all(cc.get(k,0)>=v for k,v in activity.items()),'activity oracle '+tag)
 if not name.startswith('fault') or name=='fault7':require(all(cc.get(k,0)==0 for k in ['ai','ab','am']),'unexpected alert '+tag)
 if r['waveform']:
  with gzip.open(OUT/r['waveform'],'rb') as f:require(b'$enddefinitions' in f.read(),'invalid waveform '+tag)
for name in ['parameter_checks.json','analysis_checks.json']:
 require(all(r['status']=='PASS' for r in json.loads((OUT/name).read_text())),'failed '+name)
require(json.loads((OUT/'checker_negative_control.json').read_text())['status']=='PASS','negative control failed')
h=json.loads((OUT/'hierarchy.json').read_text());modules={m['module']:m['original'] for m in h['parameters']}
cells=[modules.get(c['submodname'],c['submodname']) for c in h['cells'] if c['hier'].startswith('opentitan_tb.dut.')]
require(cells.count('ibex_core')==2,'expected two cores')
require(cells.count('prim_ram_1p_scr')==4,'expected four shared scrambled RAM banks')
require(not any(c=='ibex_branch_predict' for c in cells),'unexpected branch predictor instance')
tracked=subprocess.check_output(['git','diff','--name-only','HEAD'],cwd=ROOT,text=True).splitlines()
require(not any(not p.startswith('doc/dungpc/') for p in tracked),'production tracked changes present')
manifest={str(p.relative_to(BASE)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(BASE.rglob('*')) if p.is_file() and '__pycache__' not in p.parts and p.name not in ['artifact_manifest.json','validation_report.json']}
if args.seal:
 (OUT/'artifact_manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
else:require(manifest==json.loads((OUT/'artifact_manifest.json').read_text()),'artifact manifest mismatch; inspect changes before resealing')
report={'status':'FAIL' if errors else 'PASS','errors':errors,'directed_runs':len(rows),'preset_parameter_checks':len(json.loads((OUT/'parameter_checks.json').read_text())),'trace_checks_including_run_oracles':len(json.loads((OUT/'analysis_checks.json').read_text())),'negative_controls':1,'waveforms':sum(bool(r['waveform']) for r in rows),'links_checked':links,'source_dependencies_hashed':len(deps),'artifacts_hashed':len(manifest),'scope':'exact-preset directed CPU analysis; not full SVA/formal/physical/security sign-off'}
(OUT/'validation_report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
if errors:raise SystemExit(1)
