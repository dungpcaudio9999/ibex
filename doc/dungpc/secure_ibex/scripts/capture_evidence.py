#!/usr/bin/env python3
"""Capture elaborated parameters and dependencies from the exact archived harness commands."""
import gzip
import hashlib
import json
import subprocess
import xml.etree.ElementTree as ET
from pathlib import Path
from run_all import BASE, CASES
ROOT=BASE.parents[2];OUT=BASE/'evidence';deps=set()
keys={'SEC','CACHE','PRED','DUAL','MODE','SCR','ICECC','PMP','ZC','OFFSET','TWEAK',
 'BaseIsa','SecureIbex','LockstepOffset','Lockstep','ResetAll','DummyInstructions','DataIndTiming',
 'PCIncrCheck','ShadowCSR','RegFileECC','RegFileLockstepECC','RegFileDataWidth','RegFileDataEccWidth',
 'RegFileCapEccWidth','MemECC','MemDataWidth','ICache','ICacheECC','ICacheScramble','ICacheTweakInfection',
 'TweakInfection','TagSizeECC','LineSizeECC','DataWidth','CapWidth','WritebackStage','BranchTargetALU',
 'RV32M','RV32B','RV32ZC','PMPEnable','NumPrinceRoundsHalf','NumAddrScrRounds','NumDiffRounds',
 'EnableParity','ReplicateKeyStream'}
for config in CASES:
 cmd=json.loads((OUT/f'{config}.command.json').read_text());cmd[cmd.index('--binary')]='--xml-only'
 res=subprocess.run(cmd,cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
 (OUT/f'{config}.elaboration.log').write_text(res.stdout)
 if res.returncode:raise RuntimeError(res.stdout[-2000:])
 obj=Path(cmd[cmd.index('--Mdir')+1]);xml=obj/'Vtop_tb.xml';tree=ET.parse(xml)
 params=[]
 for mod in tree.findall('.//netlist/module'):
  selected={v.get('name'):[c.attrib for c in v.findall('.//const')] for v in mod.findall('var') if (v.get('param') or v.get('localparam')) and v.get('name') in keys}
  if selected:params.append({'module':mod.get('name'),'original':mod.get('origName'),'parameters':selected})
 (OUT/f'{config}.hierarchy.json').write_text(json.dumps({'cells':[dict(c.attrib) for c in tree.findall('.//cells//cell')],'parameters':params},indent=2)+'\n')
 with gzip.open(OUT/f'{config}.elaboration.xml.gz','wb') as f:f.write(xml.read_bytes())
 for dep in obj.glob('*__ver.d'):
  content=dep.read_text();(OUT/f'{config}.dependencies.txt').write_text(content)
  for word in content.split(' : ',1)[-1].split():
   p=Path(word)
   if p.is_file() and p.is_relative_to(ROOT):deps.add(p)
 deps.add(OUT/f'{config}.harness.sv');deps.add(OUT/f'{config}.runner.py')
deps.update((ROOT/'rtl').glob('*.sv'));deps.add(ROOT/'ibex_configs.yaml')
(OUT/'source_dependencies_sha256.json').write_text(json.dumps({str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(deps)},indent=2)+'\n')
(OUT/'baseline.json').write_text(json.dumps({'revision':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'verilator':subprocess.check_output(['verilator','--version'],text=True).strip(),'scope':'five actual ibex_top configurations; archived harness, generic primitives; no production RTL edits'},indent=2)+'\n')
print('Captured',len(CASES),'configurations;',len(deps),'dependency hashes')
