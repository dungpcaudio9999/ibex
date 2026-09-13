#!/usr/bin/env python3
"""Build exactly the repository's opentitan preset and run directed CPU-design experiments."""
import argparse,gzip,hashlib,json,subprocess,sys
from pathlib import Path
import yaml
HERE=Path(__file__).resolve().parent;BASE=HERE.parent;ROOT=BASE.parents[2];OUT=BASE/'evidence'
sys.path.insert(0,str(BASE.parent/'microarchitecture/scripts'))
from run_core import PRIM,i,r,s,branch,jal,program
from run_extended import stimulus,cheri
OBJ=Path('/tmp/ibex-opentitan');BINARY=OBJ/'Vopentitan_tb'

def build():
 OUT.mkdir(exist_ok=True);OBJ.mkdir(exist_ok=True)
 preset=yaml.safe_load((ROOT/'ibex_configs.yaml').read_text())['opentitan']
 (OUT/'preset.json').write_text(json.dumps(preset,indent=2)+'\n')
 h=OUT/'opentitan_params.svh';h.write_text(',\n'.join(f'    .{k}({v})' for k,v in preset.items())+'\n')
 snapshot=OUT/'opentitan_tb.sv';snapshot.write_bytes((HERE/'opentitan_tb.sv').read_bytes())
 (OUT/'runner_snapshot.py').write_bytes(Path(__file__).read_bytes())
 opts=subprocess.run([sys.executable,str(ROOT/'util/ibex_config.py'),'opentitan','fusesoc_opts'],cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,check=True)
 (OUT/'named_config_options.txt').write_text(opts.stdout)
 generic=ROOT/'vendor/lowrisc_ip/ip/prim_generic/rtl'
 sources=[PRIM/f'{n}.sv' for n in ['prim_cipher_pkg','prim_util_pkg','prim_count_pkg','prim_secded_pkg','prim_mubi_pkg']]
 sources += [generic/'prim_ram_1p_pkg.sv',ROOT/'rtl/ibex_pkg.sv',ROOT/'rtl/ibex_cheriot_pkg.sv']
 sources += sorted(p for p in (ROOT/'rtl').glob('*.sv') if p.stem not in {'ibex_pkg','ibex_cheriot_pkg','ibex_top_tracing','ibex_tracer','ibex_tracer_pkg'})
 cmd=['verilator','--binary','--timing','--trace','--assert','-j','2','-Wno-fatal','-Wno-PINMISSING','-DDV_FCOV_DISABLE','-DRVFI',f'-I{PRIM}',f'-I{generic}',f'-I{OUT}',f'-I{ROOT/"vendor/pulp_common_cells/rtl"}',f'-I{ROOT/"vendor/lowrisc_ip/dv/sv/dv_utils"}','--top-module','opentitan_tb','--Mdir',str(OBJ)]+list(map(str,sources))+[str(snapshot)]
 (OUT/'build.command.json').write_text(json.dumps(cmd,indent=2)+'\n')
 res=subprocess.run(cmd,cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
 (OUT/'build.log').write_text(res.stdout)
 if res.returncode:raise RuntimeError(res.stdout[-5000:])
 print('BUILD PASS: exact YAML parameters, one runtime-selectable binary',flush=True)

CASES={
 'rv.arithmetic':(0,'arithmetic',1),'rv.control':(0,'control',1),'rv.compressed':(0,'compressed',1),
 'rv.memory_d1':(0,'memory',1),'rv.memory_d4':(0,'memory',4),
 'rv.independent_d1':(0,'independent',1),'rv.independent_d4':(0,'independent',4),
 'rv.error_young':(0,'error_young',4),'rv.error_split_load_first':(0,'error_split_load_first',4),'rv.error_split_load_second':(0,'error_split_load_second',4),
 'rv.pmp_deny':(0,'pmp_deny',1),'rv.pmp_region15':(0,'pmp_region15',1),
 'rv.bitmanip':(0,'bitmanip',1),'rv.counters':(0,'counters',1),
 'rv.zcmp':(0,'zc',1),'rv.zcmp_debug':(0,'zcmp_debug',4),'rv.zcmp_irq':(0,'zcmp_irq',4),'rv.zcmp_irq_multi':(0,'zcmp_irq_multi',4),
 'rv.sleep':(0,'sleep',4),'rv.dret':(0,'dret',4),'rv.debug_irq':(0,'debug_irq',4),'rv.nmi_return':(0,'nmi_return',4),
 'rv.div_debug':(0,'div_debug',4),'rv.debug_trigger':(0,'debug_trigger',4),
 'rv.cache':(0,'cache',1),'rv.cache_debug_key':(0,'cache_debug_key',1),'rv.reset':(0,'reset',4),
 'rv.iferror_second':(0,'iferror_second',1),
 'rv.dit_off_zero':(0,'dit_off_zero',1),'rv.dit_off_nonzero':(0,'dit_off_nonzero',1),
 'rv.dit_on_zero':(0,'dit_on_zero',1),'rv.dit_on_nonzero':(0,'dit_on_nonzero',1),
 'rv.dit_branch_taken':(0,'ditbranch_on_taken',1),'rv.dit_branch_nt':(0,'ditbranch_on_nt',1),
 'rv.dummy_dit_cache':(0,'dummy_dit_cache',1),
 'rv.fault1':(0,'fault1',1),'rv.fault2':(0,'fault2',1),'rv.fault3':(0,'fault3',1),'rv.fault4':(0,'fault4',1),'rv.fault6':(0,'fault6',1),'rv.fault7':(0,'fault7',1),'rv.fault10':(0,'fault10',1),
 'cap.live':(1,'cap',1),'cap.revoked':(1,'cap_revoked',1),'cap.cache':(1,'cap_cache',1),'cap.fault':(1,'cap_fault',1),
 'cap.bound':(1,'cap_bound',1),'cap.roundtrip':(1,'cap_roundtrip',4),'cap.debug':(1,'cap_debug',4),
 'cap.arithmetic':(1,'cap_arithmetic',1),'cap.zcmp_illegal':(1,'zcmp_illegal',1),
 'cap.invalid_mode':(1,'fault5',1),'cap.rf_ecc':(1,'fault8',1),'cap.bitmap_ecc':(1,'fault9',1),
}
# Preserve representative waves for each distinct interaction; all runs have complete text traces.
WAVES={'rv.zcmp_irq_multi','rv.zcmp_irq','rv.control','rv.memory_d4','rv.independent_d4','rv.error_young','rv.zcmp_debug','rv.div_debug','rv.debug_trigger','rv.cache','rv.cache_debug_key','rv.dummy_dit_cache','rv.sleep','rv.reset','rv.fault2','rv.fault3','rv.fault4','rv.fault6','rv.fault10','cap.roundtrip','cap.debug','cap.zcmp_illegal','cap.bitmap_ecc'}

def make_case(name,mode):
 debug=[0x6f]*1024;debug[512:515]=[i(13,0,118),0x7b200073,0x6f]
 if name in ['memory','error_split_load_first','error_split_load_second']:
  mem,expected,args=program(name);activity={}
 elif name in ['independent','error_young','bitmanip','counters','dummy_dit_cache','cap_arithmetic','zcmp_illegal']:
  mem,_,_,_=stimulus('cap' if mode else 'reset');expected={};args=[];activity={}
  if name in ['independent','error_young']:
   code=[i(1,0,0x208),i(2,1,0,2,3),i(3,0,9),i(4,2,1),i(15,0,123),0x6f]
   expected={2:0x44332211,3:9,4:0x44332212,15:123};activity={'data':1}
   if name=='error_young':args=['+err_addr=520'];expected={2:0,3:0,4:0,10:5,11:0x84,12:0x208,15:119}
  elif name=='bitmanip':
   code=[i(1,0,-1),i(2,0,1),r(3,1,2,7,0x20),i(4,1,0x602,1),i(5,2,0x600,1),r(6,2,2,1,0x30),i(15,0,123),0x6f]
   expected={3:0xfffffffe,4:32,5:31,6:2,15:123}
  elif name=='counters':
   code=[i(1,0,0x208),i(2,1,0,2,3),i(3,0,0xb05,2,0x73),i(4,0,0xb85,2,0x73),i(5,0,0xb0c,2,0x73),i(6,0,7),r(7,2,6,4,1),i(8,0,0xb0c,2,0x73),i(9,0,0xb0d,2,0x73),i(14,0,0x32c,2,0x73),i(15,0,123),0x6f]
   expected={3:1,4:0,5:0,7:0x44332211//7,8:36,9:0,14:512,15:123}
  elif name=='dummy_dit_cache':
   code=[i(1,0,7),i(0,1,0x7c0,1,0x73),i(2,0,24),i(2,2,-1),branch(2,0,-4,1),i(15,0,123),0x6f]
   expected={2:0,15:123};activity={'dummy':1,'hit':1}
  elif name=='cap_arithmetic':
   code=[i(1,0,7),i(2,0,12),r(3,1,2),r(4,1,2,0,1),r(5,4,1,4,1),i(15,0,123),0x6f];expected={3:19,4:84,5:12,15:123}
  else:
   code=[0x0001b842,i(15,0,123),0x6f];expected={10:2,11:0x80,15:119}
  mem[32:32+len(code)]=code
 elif name in ['zcmp_irq','zcmp_irq_multi']:
  mem,_,_,_=stimulus('zc')
  code=[i(1,0,128),i(0,1,0x304,1,0x73),i(1,0,8),i(0,1,0x300,2,0x73)]+mem[32:39]
  mem[32:32+len(code)]=code;args=['+event=9'];expected={1:55,2:0x2f0,10:0x80000007,11:0x9a,15:119};activity={'expanded':1,'data':1}
  if name=='zcmp_irq_multi':
   mem[38]=0xba62b862;expected[2]=0x300;expected[11]=0x98
 elif name=='pmp_region15':
  mem,expected,args,activity=stimulus('pmp_deny')
  # Region 15 uses pmpaddr15 and byte3 of pmpcfg3.
  mem[33]=i(0,1,0x3bf,1,0x73);mem[34]=0x980000b7;mem[35]=i(0,1,0x3a3,1,0x73)
 elif name in ['zcmp_debug','div_debug','debug_trigger','cache_debug_key','cap_debug','cap_bound','cap_roundtrip']:
  original={'zcmp_debug':'zc','div_debug':'dret','debug_trigger':'dret','cache_debug_key':'cache','cap_debug':'cap','cap_bound':'cap','cap_roundtrip':'cap'}[name]
  mem,expected,args,activity=stimulus(original)
  if name=='zcmp_debug':args=['+event=6'];expected[13]=118
  if name=='div_debug':mem[37]=r(4,2,1,4,1);expected={4:65,13:118,15:123};args=['+event=5']
  if name=='cache_debug_key':args=['+event=8'];expected[13]=118
  if name=='cap_debug':args=['+event=7'];expected[13]=118
  if name=='cap_bound':
   mem[34:38]=[i(1,1,4,2,0x5b),i(2,1,0,3,3),i(15,0,123),0x6f];expected={2:0,10:28,11:0x8c,15:119};activity={}
  if name=='cap_roundtrip':
   code=[cheri(1,0,29,high=1),i(1,1,0x200,1,0x5b),i(2,1,0,3,3),i(1,1,8,1,0x5b),s(2,1,0,3),i(4,1,0,3,3),cheri(5,4,4),i(15,0,123),0x6f]
   mem[32:32+len(code)]=code;expected={2:0x1000,4:0x1000,5:1,15:123};activity={'data':6,'bitmap':2}
  if name=='debug_trigger':
   debug[512:523]=[i(14,14,1),i(13,0,118),i(5,0,1),branch(14,5,24,1),i(5,0,0x98),i(0,5,0x7a2,1,0x73),i(5,0,4),i(0,5,0x7a1,1,0x73),0x7b200073,i(0,0,0x7a1,1,0x73),0x7b200073]
   expected[14]=2
 elif name.startswith('dit_'):
  mem,expected,args,activity=stimulus(name)
  # Match the mode token, not the substring in 'nonzero'.
  mem[32]=i(1,0,2 if name.split('_')[1]=='on' else 0)
 else:mem,expected,args,activity=stimulus(name)
 return mem,debug,expected,args,activity

def run_case(tag):
 mode,name,lat=CASES[tag];mem,debug,expected,extra,activity=make_case(name,mode)
 prog=OUT/f'{tag}.hex';dbgprog=OUT/f'{tag}.debug.hex'
 for p,words in [(prog,mem),(dbgprog,debug)]:p.write_text('\n'.join(f'{v:08x}' for v in words)+'\n')
 cmd=[str(BINARY),f'+program={prog}',f'+debug_program={dbgprog}',f'+mode={mode}',f'+latency={lat}']+extra
 wave=OUT/f'{tag}.vcd'
 if tag in WAVES:cmd.append(f'+wave={wave}')
 res=subprocess.run(cmd,cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
 log=OUT/f'{tag}.log';log.write_text(res.stdout)
 rr={int(w[1]):int(w[2],16) for line in res.stdout.splitlines() if (w:=line.split()) and w[0]=='REG'}
 cs=[line.split()[1:] for line in res.stdout.splitlines() if line.startswith('COUNTS ')]
 counts={k:int(v) for k,v in (w.split('=') for w in cs[0])} if cs else {}
 errors=[f'x{k} expected {v:x}, got {rr.get(k)}' for k,v in expected.items() if rr.get(k)!=v]
 errors += [f'{k} activity missing' for k,v in activity.items() if counts.get(k,0)<v]
 if not name.startswith('fault') or name=='fault7':
  if any(counts.get(k,0) for k in ['ai','ab','am']):errors.append('unexpected alert')
 if res.returncode or 'FINISH' not in res.stdout:errors.append(f'simulator exit {res.returncode}')
 if 'PROTOCOL_CHECKS ' not in res.stdout:errors.append('protocol checker did not complete')
 if name=='fault10' and (counts.get('ai') or counts.get('ab')):errors.append('cache recoverable fault raised major')
 row={'id':tag,'mode':mode,'case':name,'latency':lat,'command':cmd,'expected':expected,'minimum_activity':activity,'registers':rr,'counts':counts,'waveform':wave.name+'.gz' if tag in WAVES else None,'errors':errors,'status':'FAIL' if errors else 'PASS'}
 if wave.exists():
  with gzip.open(str(wave)+'.gz','wb') as f:f.write(wave.read_bytes())
  wave.unlink()
 print(tag,row['status'],errors,flush=True)
 return row

if __name__=='__main__':
 ap=argparse.ArgumentParser();ap.add_argument('--skip-build',action='store_true');ap.add_argument('--build-only',action='store_true');ap.add_argument('--cases');opts=ap.parse_args()
 if not opts.skip_build:build()
 if opts.build_only:raise SystemExit(0)
 rows=json.loads((OUT/'results.json').read_text()) if (OUT/'results.json').exists() else []
 for tag in opts.cases.split(',') if opts.cases else CASES:
  row=run_case(tag);rows=[r for r in rows if r['id']!=tag]+[row];(OUT/'results.json').write_text(json.dumps(rows,indent=2)+'\n')
 if any(r['status']!='PASS' for r in rows):raise SystemExit(1)
