#!/usr/bin/env python3
"""Top-level experiments for plan completion and Secure Ibex follow-up."""
import argparse
import gzip
import json
import subprocess
from pathlib import Path
from run_core import ROOT, HERE, PRIM, i, r, s, branch, program

OUT=HERE.parent/'evidence/extended'
CONFIGS={'top':{},'predict':{'PRED':1},'zc':{'ZC':3},'cache':{'CACHE':1},
         'cheriot':{'DUAL':1,'MODE':1},'secure':{'SEC':1},
         'secure_offset2':{'SEC':1,'OFFSET':2},
         'secure_cache':{'SEC':1,'CACHE':1,'ICECC':1,'SCR':1},
         'secure_cache_ecc':{'SEC':1,'CACHE':1,'ICECC':1},
         'secure_cache_notweak':{'SEC':1,'CACHE':1,'ICECC':1,'SCR':1,'TWEAK':0},
         'secure_dual':{'SEC':1,'DUAL':1,'MODE':1},'secure_combo':{'SEC':1,'DUAL':1,'MODE':1,'CACHE':1,'ICECC':1,'SCR':1,'PMP':1},'pmp':{'PMP':1}}

def cheri(rd,rs,field,funct=0,high=0x7f):
    return (high<<25)|(field<<20)|(rs<<15)|(funct<<12)|(rd<<7)|0x5b

def stimulus(name):
    mem=[0x6f]*1024
    handler=[i(10,0,0x342,2,0x73),i(11,0,0x341,2,0x73),i(12,0,0x343,2,0x73),i(15,0,119),0x6f]
    mem[:5]=handler;mem[7:12]=handler;mem[31]=0x6f
    # NMI vector uses jal to a dedicated CSR-reading handler at 0x300.
    from run_core import jal
    mem[31]=jal(0,0x300-0x7c);mem[192:197]=handler
    mem[16:20]=[i(13,0,118),0x7b200073,0x6f,0x6f]
    args=[];expected={};activity={};code=[]
    if name in ('arithmetic','control','compressed'):
        return (*program(name)[:2],program(name)[2],{})
    if name=='loop':
        code=[i(1,0,3),i(1,1,-1),branch(1,0,-4,1),i(15,0,123),0x6f]
        expected={1:0,15:123};activity={'predict':1,'mispredict':1}
    elif name=='cache':
        code=[i(1,0,1),i(0,1,0x7c0,1,0x73),i(2,0,180),i(2,2,-1),branch(2,0,-4,1),
              0x0000100f,i(15,0,123),0x6f]
        expected={2:0,15:123};activity={'hit':1,'miss':1}
    elif name=='zc':
        code=[i(2,0,0x300),i(1,0,55),0xba42b842,i(8,0,-1),0x00019c61,i(15,0,123),0x6f]
        expected={2:0x300,1:55,8:255,15:123};activity={'expanded':1,'data':2}
    elif name=='iferror':
        code=[i(1,0,7),i(2,0,8),i(15,0,123),0x6f]
        args=['+iferr=132'];expected={1:7,2:0,10:1,11:0x84,12:0x84,15:119}
    elif name=='iferror_second':
        code=[(i(1,0,7)<<16 | 1)&0xffffffff,(i(1,0,7)>>16)|(0x0001<<16),i(15,0,123),0x6f]
        args=['+iferr=132'];expected={1:0,10:1,11:0x82,12:0x84,15:119}
    elif name=='reset':
        code=[i(1,0,7),i(15,0,123),0x6f];args=['+reset_at=7'];expected={1:7,15:123}
    elif name=='sleep':
        code=[i(1,0,128),i(0,1,0x304,1,0x73),0x10500073,i(15,0,123),0x6f]
        args=['+event=1'];expected={15:123};activity={'sleep':20}
    elif name in ('dret','debug_irq','nmi','nmi_return'):
        code=[i(1,0,128),i(0,1,0x304,1,0x73),i(1,0,8),i(0,1,0x300,2,0x73),
              i(2,0,0x208),i(3,2,0,2,3),i(15,0,123),0x6f]
        args=[f'+event={dict(dret=2,debug_irq=4,nmi=3,nmi_return=3)[name]}']
        expected={3:0x44332211}
        if name=='dret':expected.update({13:118,15:123})
        elif name=='debug_irq':expected.update({13:118,10:0x80000007,15:119})
        else:expected.update({10:0x8000001f,15:119})
        if name=='nmi_return':
            mem[195]=0x30200073;expected[15]=123
    elif name.startswith('cap'):
        mem[1]=cheri(11,0,31,high=1)  # MEPCC replaces scalar MEPC in CHERIoT mode.
        # cspecialrw c1, mtdc, c0; cincaddrimm c1,c1,0x200; clc c2,0(c1); cgettag x3,c2.
        code=[cheri(1,0,29,high=1),i(1,1,0x200,1,0x5b),i(2,1,0,3,3),cheri(3,2,4),i(15,0,123),0x6f]
        expected={2:0x1000,3:1,15:123};activity={'bitmap':1,'data':2}
        if name=='cap_cache':
            code=[i(1,0,1),i(0,1,0x7c0,1,0x73)]+code;activity['hit']=1
        if name=='cap_revoked':args=['+revoked=1'];expected[3]=0
        if name=='cap_fault':
            code=[i(1,0,0x200),i(2,1,0,3,3),i(15,0,123),0x6f]
            expected={2:0,10:28,11:0x84,15:119};activity={}
    elif name.startswith('dit_'):
        enabled='on' in name;zero=name.endswith('_zero')
        code=[i(1,0,2 if enabled else 0),i(0,1,0x7c0,1,0x73),i(2,0,123),i(3,0,0 if zero else 7),
              r(4,2,3,4,1),i(15,0,123),0x6f]
        expected={4:0xffffffff if zero else 17,15:123}
    elif name.startswith('ditbranch'):
        enabled='_on_' in name;taken=name.endswith('_taken')
        code=[i(1,0,2 if enabled else 0),i(0,1,0x7c0,1,0x73),i(2,0,1),branch(2,2 if taken else 0,8),i(3,0,33),i(15,0,123),0x6f]
        expected={3:0 if taken else 33,15:123}
    elif name=='dummy':
        code=[i(1,0,4),i(0,1,0x7c0,1,0x73),i(2,0,100),i(2,2,-1),branch(2,0,-4,1),i(15,0,123),0x6f]
        expected={2:0,15:123};activity={'dummy':1}
    elif name.startswith('fault'):
        fault=int(name[5:]);args=[f'+fault={fault}']
        code=[i(1,0,0x208),i(2,1,0,2,3),i(3,0,200),i(3,3,-1),branch(3,0,-4,1),i(15,0,123),0x6f]
        activity={'ab' if fault in (1,2,9) else 'ai':1}
        if fault==7:activity={};expected={2:0x44332211,3:0,15:123}
        if fault==5:
            mem,_,_,_=stimulus('cap');return mem,{},args,activity
        if fault==8:
            mem,_,_,_=stimulus('cap');mem[36]=0xffdff06f
            return mem,{},args,activity
        if fault==9:
            mem,expected,_,_=stimulus('cap');expected[3]=0
            return mem,expected,args,activity
        if fault==2:expected={2:0,10:0xffffffe0,12:0x208,15:119}
        if fault==10:
            mem,expected,_,_=stimulus('cache');activity={'am':1,'hit':1}
            return mem,expected,args,activity
    elif name=='pmp_deny':
        # Locked NAPOT region covers 0x200..0x207, no R/W/X; M-mode load must fault.
        code=[i(1,0,0x80),i(0,1,0x3b0,1,0x73),i(1,0,0x98),i(0,1,0x3a0,1,0x73),
              i(2,0,0x200),i(3,2,0,2,3),i(15,0,123),0x6f]
        expected={3:0,10:5,11:0x94,12:0x200,15:119}
    else:raise ValueError(name)
    mem[32:32+len(code)]=code
    return mem,expected,args,activity

def build(config,out):
    generic=ROOT/'vendor/lowrisc_ip/ip/prim_generic/rtl'
    sources=[PRIM/f'{n}.sv' for n in ('prim_cipher_pkg','prim_util_pkg','prim_count_pkg','prim_secded_pkg','prim_mubi_pkg')]
    sources += [generic/'prim_ram_1p_pkg.sv',ROOT/'rtl/ibex_pkg.sv',ROOT/'rtl/ibex_cheriot_pkg.sv']
    sources += sorted(p for p in (ROOT/'rtl').glob('*.sv') if p.stem not in {'ibex_pkg','ibex_cheriot_pkg','ibex_top_tracing','ibex_tracer','ibex_tracer_pkg'})
    snapshot=out/f'{config}.harness.sv';snapshot.write_bytes((HERE/'top_tb.sv').read_bytes())
    (out/f'{config}.runner.py').write_bytes(Path(__file__).read_bytes())
    obj=Path('/tmp/ibex-extended')/config;obj.mkdir(parents=True,exist_ok=True)
    cmd=['verilator','--binary','--timing','--trace','--assert','-j','2','-Wno-fatal','-Wno-PINMISSING',
         '-DDV_FCOV_DISABLE','-DRVFI',f'-I{PRIM}',f'-I{generic}',f'-I{ROOT/"vendor/pulp_common_cells/rtl"}',
         f'-I{ROOT/"vendor/lowrisc_ip/dv/sv/dv_utils"}','--top-module','top_tb','--Mdir',str(obj)]
    cmd += [f'-G{k}={v}' for k,v in CONFIGS[config].items()]+[str(p) for p in sources]+[str(snapshot.resolve())]
    (out/f'{config}.command.json').write_text(json.dumps(cmd,indent=2)+'\n')
    result=subprocess.run(cmd,cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    (out/f'{config}.build.log').write_text(result.stdout)
    if result.returncode:raise RuntimeError(result.stdout[-3500:])
    return obj/'Vtop_tb'

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--configs',default='top,predict,zc,cache,cheriot,pmp')
    ap.add_argument('--cases');ap.add_argument('--skip-build',action='store_true');ap.add_argument('--out',type=Path,default=OUT)
    opts=ap.parse_args();out=opts.out.resolve();out.mkdir(parents=True,exist_ok=True)
    records=json.loads((out/'results.json').read_text()) if (out/'results.json').exists() else []
    default={'top':['arithmetic','control','compressed','iferror','iferror_second','reset','sleep','dret','debug_irq','nmi'],
             'predict':['loop','control'],'zc':['zc'],'cache':['cache','iferror','control'],
             'cheriot':['cap','cap_revoked','cap_fault'],'pmp':['pmp_deny']}
    for config in opts.configs.split(','):
        binary=Path('/tmp/ibex-extended')/config/'Vtop_tb' if opts.skip_build else build(config,out)
        cases=opts.cases.split(',') if opts.cases else default.get(config,['arithmetic','sleep'])
        for case in cases:
            mem,expected,args,activity=stimulus(case)
            program_path=out/f'{case}.hex';program_path.write_text('\n'.join(f'{w:08x}' for w in mem)+'\n')
            tag=f'{config}.{case}';wave=out/f'{tag}.vcd'
            command=[str(binary),f'+program={program_path}',f'+wave={wave}',f'+latency={4 if case in ("reset","sleep","dret","debug_irq","nmi","nmi_return") else 1}']+args
            result=subprocess.run(command,cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
            (out/f'{tag}.log').write_text(result.stdout)
            regs={int(row.split()[1]):int(row.split()[2],16) for row in result.stdout.splitlines() if row.startswith('REG ')}
            lines=[row for row in result.stdout.splitlines() if row.startswith('COUNTS ')]
            counts={k:int(v) for k,v in (w.split('=') for w in lines[0].split()[1:])} if lines else {}
            errors=[f'x{k}: expected {v:x}, got {regs.get(k)}' for k,v in expected.items() if regs.get(k)!=v]
            errors += [f'{k} activity {counts.get(k)} < {v}' for k,v in activity.items() if counts.get(k,0)<v]
            if (not case.startswith('fault') or case=='fault7') and any(counts.get(k,0) for k in ('ai','ab','am')):errors.append('unexpected alert')
            if result.returncode or 'FINISH' not in result.stdout:errors.append(f'exit={result.returncode}, finish={"FINISH" in result.stdout}')
            record={'id':tag,'command':command,'expected':expected,'activity_minimum':activity,'counts':counts,'errors':errors,'status':'FAIL' if errors else 'PASS'}
            records=[r for r in records if r['id']!=tag]+[record]
            (out/'results.json').write_text(json.dumps(records,indent=2)+'\n')
            if wave.exists():
                with gzip.open(str(wave)+'.gz','wb') as f:f.write(wave.read_bytes())
                wave.unlink()
            print(tag,record['status'],errors,counts,flush=True)
    if any(r['errors'] for r in records):raise SystemExit(1)

if __name__=='__main__':main()
