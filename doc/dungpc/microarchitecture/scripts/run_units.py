#!/usr/bin/env python3
"""Directed CHERIoT EX and revocation tests; no ISA-compliance claim."""
import json
import subprocess
from pathlib import Path
from run_core import HERE, ROOT, OUT, PRIM, execute

results=[]
for name in ('cap_ex','cap_lsu','trvk'):
    obj=Path('/tmp/ibex-microarchitecture')/name
    obj.mkdir(parents=True,exist_ok=True)
    sources=[PRIM/'prim_util_pkg.sv',PRIM/'prim_count_pkg.sv',ROOT/'rtl/ibex_pkg.sv',ROOT/'rtl/ibex_cheriot_pkg.sv']
    sources += [ROOT/'rtl'/({'cap_ex':'ibex_cheriot_ex.sv','cap_lsu':'ibex_load_store_unit.sv','trvk':'ibex_trvk.sv'}[name])]
    cmd=['verilator','--binary','--timing','--assert','-j','2','-Wno-fatal','-Wno-PINMISSING',
         f'-I{PRIM}',f'-I{ROOT / "vendor/pulp_common_cells/rtl"}',
         '-DDV_FCOV_DISABLE',f'-I{ROOT / "vendor/lowrisc_ip/dv/sv/dv_utils"}',
         '--Mdir',str(obj),'--top-module',name+'_tb']+[str(p) for p in sources]+[str(HERE/(name+'_tb.sv'))]
    (OUT/f'{name}.build-command.json').write_text(json.dumps(cmd,indent=2)+'\n')
    execute(cmd,OUT/f'{name}.build.log')
    run=[str(obj/f'V{name}_tb')]
    output=execute(run,OUT/f'{name}.log')
    assert 'FINISH' in output
    results.append({'id':name,'command':run,'status':'PASS','checks':output.count('PASS ')})
    print(output,flush=True)
(OUT/'unit_results.json').write_text(json.dumps(results,indent=2)+'\n')
