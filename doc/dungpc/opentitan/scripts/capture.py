#!/usr/bin/env python3
"""Archive actual elaboration and check YAML against resolved SV constants."""
import gzip,hashlib,json,re,subprocess,xml.etree.ElementTree as ET
from pathlib import Path
from run import ROOT,OUT,HERE
cmd=json.loads((OUT/'build.command.json').read_text());cmd[cmd.index('--binary')]='--xml-only'
res=subprocess.run(cmd,cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
(OUT/'elaboration.log').write_text(res.stdout)
if res.returncode:raise RuntimeError(res.stdout[-3000:])
obj=Path(cmd[cmd.index('--Mdir')+1])
xml=obj/'Vopentitan_tb.xml';tree=ET.parse(xml)
params=[]
for mod in tree.findall('.//netlist/module'):
 selected={v.get('name'):[c.attrib for c in v.findall('.//const')] for v in mod.findall('var') if v.get('param') or v.get('localparam')}
 if selected:params.append({'module':mod.get('name'),'original':mod.get('origName'),'parameters':selected})
hier={'cells':[dict(c.attrib) for c in tree.findall('.//cells//cell')],'parameters':params}
(OUT/'hierarchy.json').write_text(json.dumps(hier,indent=2)+'\n')
with gzip.open(OUT/'elaboration.xml.gz','wb') as f:f.write(xml.read_bytes())
def integer(m,k):
 value=m['parameters'][k][0]['name'];return int(value.split('h')[-1],16)
top=next(m for m in params if m['original']=='ibex_top')
preset=json.loads((OUT/'preset.json').read_text());source=(ROOT/'rtl/ibex_pkg.sv').read_text();checks=[]
for k,v in preset.items():
 if isinstance(v,str) and '::' in v:v=int(re.search(r'\b'+v.split('::')[1]+r'\s*=\s*(\d+)',source)[1])
 actual=integer(top,k);checks.append({'parameter':k,'expected':int(v),'actual':actual,'status':'PASS' if actual==int(v) else 'FAIL'})
cores=[m for m in params if m['original']=='ibex_core']
assert len(cores)==2 and sorted(integer(m,'RegFileECC') for m in cores)==[0,1]
for m in cores:
 for k in ('DataIndTiming','PCIncrCheck','ResetAll','MemECC'):assert integer(m,k)==1,(m['module'],k)
 assert integer(m,'ShadowCSR')==0
(OUT/'parameter_checks.json').write_text(json.dumps(checks,indent=2)+'\n')
deps=set((ROOT/'rtl').glob('*.sv'))
for dep in obj.glob('*__ver.d'):
 content=dep.read_text();(OUT/'dependencies.txt').write_text(content)
 for word in content.split(' : ',1)[-1].split():
  p=Path(word)
  if p.is_file() and p.is_relative_to(ROOT):deps.add(p)
deps.update([ROOT/'ibex_configs.yaml',ROOT/'util/ibex_config.py',HERE/'run.py',HERE/'opentitan_tb.sv',OUT/'runner_snapshot.py',OUT/'opentitan_tb.sv',OUT/'opentitan_params.svh'])
deps.update(ROOT/'doc/dungpc/microarchitecture/scripts'/p for p in ['run_core.py','run_extended.py'])
(OUT/'source_dependencies_sha256.json').write_text(json.dumps({str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(deps)},indent=2)+'\n')
# Record the exact preprocessor assertion policy; --assert does not undo macros disabled for Verilator.
acmd=cmd.copy();acmd[acmd.index('--xml-only')]='-E'
ares=subprocess.run(acmd,cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE,check=True)
audit={'prim_assert_policy':(ROOT/'vendor/lowrisc_ip/ip/prim/rtl/prim_assert.sv').read_text(),'expanded_assert_property_count':len(re.findall(r'assert\s+property',ares.stdout)),'harness_fatal_count':ares.stdout.count('$fatal'),'note':'Immediate harness protocol checks active; this count does not establish a full SVA regression.'}
(OUT/'assertion_audit.json').write_text(json.dumps(audit,indent=2)+'\n')
(OUT/'baseline.json').write_text(json.dumps({'revision':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'verilator':subprocess.check_output(['verilator','--version'],text=True).strip(),'scope':'exact repository opentitan preset, top defaults, generic primitives; runtime ISA selection; no production RTL edits','previous_source_delta':subprocess.check_output(['git','diff','--stat','fc3b3dd6','HEAD','--','rtl','ibex_configs.yaml','util/ibex_config.py','vendor/lowrisc_ip/ip/prim/rtl','vendor/lowrisc_ip/ip/prim_generic/rtl'],cwd=ROOT,text=True)},indent=2)+'\n')
assert all(c['status']=='PASS' for c in checks)
print('PASS',len(checks),'preset parameters;',len(deps),'source dependencies; main/shadow secure localparams checked')
