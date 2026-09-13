#!/usr/bin/env python3
"""Finite retirement windows and selected ordering invariants from preserved RTL logs."""
import json
from run_core import HERE
base=HERE.parent;out=base/'evidence/extended'
def rows(path,prefix):
    return [r.split() for r in path.read_text().splitlines() if r.startswith(prefix+' ')]
checks=[]
for name in ('dret','debug_irq','nmi','nmi_return'):
    log=out/f'top.{name}.log';r=rows(log,'R');pcs=[int(x[3],16) for x in r]
    entry=0x40 if name in ('dret','debug_irq') else 0x7c
    assert pcs.index(0x94)<pcs.index(entry)
    if name=='debug_irq':assert pcs.index(0x44)<pcs.index(0x1c) and 0x98 not in pcs
    if name=='dret':assert pcs.index(0x44)<pcs.index(0x98)
    if name=='nmi_return':assert pcs.index(0x30c)<pcs.index(0x98)
    checks.append({'id':name,'status':'PASS','invariant':'older load retires before event entry; return/priority PC ordering'})
for name,tag in [('cap',1),('cap_revoked',0)]:
    log=out/f'cheriot.{name}.log';d=rows(log,'D');b=rows(log,'B');w=rows(log,'W')
    assert [int(x[3],16) for x in d]==[0x200,0x204] and len(b)==1
    capwrite=next(x for x in w if x[2]=='2')
    assert (int(capwrite[4],16)>>32)&1==tag and int(capwrite[1])>int(b[0][1])
    checks.append({'id':name,'status':'PASS','invariant':'two cap words, one bitmap, tag at RF after bitmap request'})
(out/'ordering_checks.json').write_text(json.dumps(checks,indent=2)+'\n')
lines=['# Cửa sổ throughput hữu hạn','',
'Đếm RVFI từ instruction đầu tới marker x31=123, loại toàn bộ JAL kết thúc. ',
'`IPC_interval=(N-1)/(cycle_last-cycle_first)` là tốc độ giữa hai mốc retirement;',
'không bao gồm boot/fill đầu, không phải IPC steady-state hay tổng benchmark.',
'Chương trình control gồm branch không taken, taken, JAL và JALR. `gap` là khoảng',
'RVFI giữa branch và instruction đích; `gap-1` là bubble quan sát, có thể gồm fetch stall.','',
'| Config | Memory | N | Δcycles | IPC_interval | NT gap | taken gap | JAL gap | JALR gap |',
'|---|---|---:|---:|---:|---:|---:|---:|---:|']
metrics=[]
for config in ('small','wb','bt','single','slow'):
 for mem in ('d1','d4'):
    rr=rows(base/f'evidence/{config}.control.{mem}.log','R');last=next(j for j,x in enumerate(rr) if int(x[3],16)==0xa8);rr=rr[:last+1]
    delta=int(rr[-1][1])-int(rr[0][1]);gaps=[]
    for pc in (0x84,0x8c,0x94,0xa0):
        j=next(j for j,x in enumerate(rr) if int(x[3],16)==pc);gaps.append(int(rr[j+1][1])-int(rr[j][1]))
    ipc=(len(rr)-1)/delta
    metrics.append(dict(config=config,memory=mem,N=len(rr),cycles=delta,ipc_interval=ipc,branch_gaps=gaps))
    lines.append(f'| {config} | {mem} | {len(rr)} | {delta} | {ipc:.3f} | '+ ' | '.join(map(str,gaps))+' |')
lines += ['','D1 và D4 là hai memory contracts của [01](01_configuration.md). Không cộng',
'memory/load-use/ID stall counters vì cùng một chu kỳ có thể thuộc nhiều điều kiện.',
'ALU liên tiếp có gap=1 khi IF cung cấp đủ; WB/BT thay đổi bubble và ownership,',
'không biến core thành superscalar. [Script](scripts/summarize_extended.py) và',
'[dữ liệu](evidence/extended/throughput.json) giúp tính lại bảng.']
lines += ['', '## Branch penalty đo từ ID', '',
'Định nghĩa `P = first_valid_ID(target) - first_valid_ID(control) - 1`.',
'P gồm hold của control instruction và khoảng redirect/fetch tới target.',
'Đây là số chu kỳ mất thêm so với hai instruction ID liên tiếp; D4 còn có memory stalls.',
'Khác với RVFI gap: control có thể retire trễ, nên JAL RVFI gap=1 vẫn có penalty.', '',
'| Config | Memory | NT P | Taken P | JAL P | JALR P |', '|---|---|---:|---:|---:|---:|']
for metric in metrics:
    first={}
    for row in rows(base/f"evidence/{metric['config']}.control.{metric['memory']}.log",'C'):
        if row[3]=='1':first.setdefault(int(row[2],16),int(row[1]))
    penalties=[first[target]-first[pc]-1 for pc,target in [(0x84,0x88),(0x8c,0x94),(0x94,0x9c),(0xa0,0xa8)]]
    metric['id_control_penalties']=penalties
    lines.append(f"| {metric['config']} | {metric['memory']} | "+' | '.join(map(str,penalties))+' |')
(base/'14_throughput.md').write_text('\n'.join(lines)+'\n')
(out/'throughput.json').write_text(json.dumps(metrics,indent=2)+'\n')
print('PASS',len(checks),'ordering checks;',len(metrics),'finite windows')
