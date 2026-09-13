#!/usr/bin/env python3
"""Build unchanged Ibex RTL, run directed programs, preserve reproducible evidence."""
import argparse
import gzip
import hashlib
import json
from pathlib import Path
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
OUT = HERE.parent / 'evidence'
PRIM = ROOT / 'vendor/lowrisc_ip/ip/prim/rtl'

def i(rd, rs, imm, funct=0, op=0x13):
    return ((imm & 0xfff) << 20) | (rs << 15) | (funct << 12) | (rd << 7) | op

def r(rd, a, b, funct=0, high=0):
    return (high << 25) | (b << 20) | (a << 15) | (funct << 12) | (rd << 7) | 0x33

def s(rs, base, off=0, funct=2):
    return ((off & 0xfe0) << 20) | (rs << 20) | (base << 15) | (funct << 12) | ((off & 31) << 7) | 0x23

def branch(a, b, off, funct=0):
    return (((off >> 12)&1)<<31) | (((off >> 5)&63)<<25) | (b<<20) | (a<<15) | (funct<<12) | (((off>>1)&15)<<8) | (((off>>11)&1)<<7) | 0x63

def jal(rd, off):
    return (((off>>20)&1)<<31) | (((off>>1)&1023)<<21) | (((off>>11)&1)<<20) | (((off>>12)&255)<<12) | (rd<<7) | 0x6f

def program(name):
    mem = [0x6f]*1024
    # Direct/vectored trap and debug handlers capture cause/PC/mtval before sentinel.
    handler = [i(25,0,0x342,2,0x73),i(26,0,0x341,2,0x73),i(27,0,0x343,2,0x73),i(31,0,119),0x6f]
    mem[:len(handler)] = handler
    mem[7:12] = handler  # default mtvec vectored timer target = 7*4
    mem[16:18] = [i(31,0,118),0x6f]
    expected, args = {}, []
    if name == 'arithmetic':
        code=[i(1,0,7),i(2,1,5),r(3,1,2),r(4,1,2,0,1),r(5,4,1,4,1),r(6,4,1,6,1),
              i(7,0,-1),r(8,7,1,1,1),r(9,1,0,4,1),r(10,1,0,6,1),
              0x800005b7,i(12,0,-1),r(13,11,12,4,1),r(14,11,12,6,1),i(31,0,123),0x6f]
        expected={1:7,2:12,3:19,4:84,5:12,6:0,8:0xffffffff,9:0xffffffff,10:7,13:0x80000000,14:0,31:123}
    elif name == 'memory':
        code=[i(1,0,0x200),i(2,0,0x55),s(2,1),i(3,1,0,2,3),i(4,3,1),
              s(4,1,3),i(5,1,3,2,3),i(6,1,4,4,3),i(31,0,123),0x6f]
        expected={3:85,4:86,5:86,6:0,31:123}
    elif name == 'control':
        code=[i(1,0,1),branch(1,0,8),i(2,0,2),branch(1,1,8),i(20,0,99),
              jal(3,8),i(21,0,99),i(4,0,0xa8),i(5,4,0,0,0x67),i(22,0,99),i(31,0,123),0x6f]
        expected={2:2,3:0x98,5:0xa4,20:0,21:0,22:0,31:123}
    elif name == 'compressed':
        # c.nop at 0x80, 32-bit ADDI straddles two fetch words at 0x82.
        raw=(0x0001).to_bytes(2,'little')+i(1,0,7).to_bytes(4,'little')+(0x0085).to_bytes(2,'little')+i(31,0,123).to_bytes(4,'little')+(0x6f).to_bytes(4,'little')
        code=[int.from_bytes(raw[j:j+4],'little') for j in range(0,len(raw),4)]
        expected={1:8,31:123}
    elif name=='mret':
        code=[i(1,0,0x90),i(0,1,0x341,1,0x73),0x30200073,i(20,0,99),i(31,0,123),0x6f]
        expected={20:0,31:123}
    elif name=='wfi_pending':
        code=[i(1,0,128),i(0,1,0x304,1,0x73),i(2,0,0x200),i(3,2,0,2,3),
              0x10500073,i(31,0,123),0x6f]
        expected={3:0x44332211,25:0,31:123}
        args=['+event=1']
    elif name.startswith('error'):
        store='store' in name
        off=3 if 'split' in name else 0
        fault=0x204 if name.endswith('second') else 0x200
        code=[i(1,0,0x200),i(2,0,85),s(2,1,off) if store else i(3,1,off,2,3),i(20,0,99),0x6f]
        expected={3:0,20:0,25:7 if store else 5,26:0x88,27:0x200+off if fault==0x200 else fault,31:119}
        args=[f'+err_addr={fault}']
    elif name.startswith('event'):
        kind=int(name[-1])
        code=[i(1,0,128),i(0,1,0x304,1,0x73),i(1,0,8),i(0,1,0x300,2,0x73),
              i(2,0,0x200),i(3,2,0,2,3) if kind in (1,2) else r(3,2,1,4,1),i(20,0,99),0x6f]
        expected={3:0x44332211 if kind in (1,2) else 64,31:119 if kind in (1,3) else 118}
        if kind in (1,3): expected[25]=0x80000007
        args=[f'+event={kind}']
    else:
        raise ValueError(name)
    mem[32:32+len(code)] = code
    return mem,expected,args

def execute(cmd, log):
    result=subprocess.run(cmd,cwd=ROOT,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    log.write_text(result.stdout)
    if result.returncode:
        raise RuntimeError(f'{log}: exit {result.returncode}\n{result.stdout[-4000:]}')
    return result.stdout

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--configs',default='small,wb,bt,single,slow')
    ap.add_argument('--skip-build',action='store_true')
    ap.add_argument('--cases',help='Comma-separated subset; merge results with previous runs')
    opts=ap.parse_args()
    OUT.mkdir(exist_ok=True)
    variants={'small':(0,0,2),'wb':(1,0,2),'bt':(0,1,2),'single':(1,1,3),'slow':(0,0,1)}
    sources=[PRIM/'prim_cipher_pkg.sv',PRIM/'prim_util_pkg.sv',ROOT/'rtl/ibex_pkg.sv',ROOT/'rtl/ibex_cheriot_pkg.sv']
    sources += sorted(p for p in (ROOT/'rtl').glob('*.sv') if p.stem not in
        {'ibex_pkg','ibex_cheriot_pkg','ibex_top','ibex_top_tracing','ibex_lockstep','ibex_tracer','ibex_tracer_pkg','ibex_trvk'})
    records=json.loads((OUT/'core_results.json').read_text()) if opts.cases and (OUT/'core_results.json').exists() else []
    for config in opts.configs.split(','):
        wb,bt,m=variants[config]
        obj=Path('/tmp/ibex-microarchitecture')/config
        obj.mkdir(parents=True,exist_ok=True)
        cmd=['verilator','--binary','--timing','--trace','--assert','-j','2','-Wno-fatal','-Wno-PINMISSING',
             '-DDV_FCOV_DISABLE','-DRVFI',f'-I{PRIM}',f'-I{ROOT / "vendor/lowrisc_ip/dv/sv/dv_utils"}',
             '--top-module','core_tb','--Mdir',str(obj),f'-GWB={wb}',f'-GBT={bt}',f'-GM={m}']
        cmd += [str(p) for p in sources]+[str(HERE/'core_tb.sv')]
        (OUT/f'{config}.build-command.json').write_text(json.dumps(cmd,indent=2)+'\n')
        if not opts.skip_build: execute(cmd,OUT/f'{config}.build.log')
        cases=['arithmetic','memory','control','compressed','error_load','error_store',
               'error_split_load_first','error_split_load_second','error_split_store_first','error_split_store_second',
               'event1','event2','event3','event4','mret','wfi_pending']
        if opts.cases: cases=opts.cases.split(',')
        for case in cases:
            mem,expected,extra=program(case)
            path=OUT/f'{case}.hex'
            path.write_text('\n'.join(f'{x:08x}' for x in mem)+'\n')
            for delay in (1,4):
                tag=f'{config}.{case}.d{delay}'
                run=[str(obj/'Vcore_tb'),f'+program={path}',f'+latency={delay}',
                     f'+ilatency={delay}',f'+grant_period={1 if delay==1 else 3}']+extra
                wave=OUT/f'{tag}.vcd'
                if case in ('memory','control','compressed','error_split_load_second','event1'):
                    run += [f'+wave={wave}']
                output=execute(run,OUT/f'{tag}.log')
                regs={int(row.split()[1]):int(row.split()[2],16) for row in output.splitlines() if row.startswith('REG ')}
                failures=[f'x{k}: expected {v:08x}, got {regs.get(k)}' for k,v in expected.items() if regs.get(k)!=v]
                if 'FINISH' not in output: failures.append('missing finish')
                records=[record for record in records if record['id']!=tag]
                records.append({'id':tag,'command':run,'expected_registers':expected,'failures':failures,'status':'FAIL' if failures else 'PASS'})
                if wave.exists():
                    with gzip.open(str(wave)+'.gz','wb') as f: f.write(wave.read_bytes())
                    wave.unlink()
                print(tag,records[-1]['status'],failures,flush=True)
    (OUT/'core_results.json').write_text(json.dumps(records,indent=2)+'\n')
    baseline={'revision':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),
              'verilator':subprocess.check_output(['verilator','--version'],text=True).strip(),
              'source_sha256':{str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sources}}
    (OUT/'baseline.json').write_text(json.dumps(baseline,indent=2)+'\n')
    if any(r['failures'] for r in records): raise SystemExit(1)

if __name__=='__main__': main()
