#!/usr/bin/env python3
"""Check architectural/transaction traces and extract measured cycle tables."""
import json
from collections import Counter
from run_core import OUT, program

def parse(path):
    rows={k:[] for k in ('C','W','R','D','MEM','REG','EVENT')}
    for line in path.read_text().splitlines():
        t=line.split()
        if t and t[0] in rows: rows[t[0]].append(t[1:])
    return rows

def check_trace(rows, case):
    errors=[]
    mem,_,_=program(case)
    raw=b''.join(x.to_bytes(4,'little') for x in mem)
    last=0
    for c,order,pc,insn,trap in rows['R']:
        pc=int(pc,16); insn=int(insn,16); order=int(order)
        if order!=last+1: errors.append('RVFI order discontinuity')
        last=order
        half=int.from_bytes(raw[pc:pc+2],'little')
        expected=half if half&3!=3 else int.from_bytes(raw[pc:pc+4],'little')
        if insn!=expected: errors.append(f'PC/instruction mismatch at {pc:x}')
    if not rows['R']: errors.append('no RVFI activity')
    if case=='memory':
        got=[(int(x[1]),int(x[2],16),int(x[3],16)) for x in rows['D']]
        expected=[(1,0x200,15),(0,0x200,15),(1,0x200,8),(1,0x204,7),
                  (0,0x200,8),(0,0x204,7),(0,0x204,1)]
        if got!=expected: errors.append('memory request count/order/address/byte-enable')
        final={int(a,16):int(v,16) for a,v in rows['MEM']}
        if final.get(0x200)!=0x56000055 or final.get(0x204)!=0x44000000:
            errors.append('memory byte-lane side effects')
        if any(v!=1 for v in Counter(int(x[1]) for x in rows['W']).values()):
            errors.append('duplicate RF side effect')
    if case=='control':
        pcs=[int(x[2],16) for x in rows['R']]
        if pcs[:8]!=[0x80,0x84,0x88,0x8c,0x94,0x9c,0xa0,0xa8]:
            errors.append('branch/return-address instruction order')
        if any(int(x[1]) in (20,21,22) for x in rows['W']): errors.append('wrong path RF write')
    if case.startswith('error'):
        if any(int(x[1]) in (3,20) for x in rows['W']): errors.append('faulting/younger RF side effect')
        expected_count=2 if 'split' in case else 1
        if len(rows['D'])!=expected_count: errors.append('fault request count')
    if case.startswith('event'):
        if len(rows['EVENT'])!=1: errors.append('event not triggered exactly once')
        w3=[int(x[0]) for x in rows['W'] if x[1]=='3']
        w31=[int(x[0]) for x in rows['W'] if x[1]=='31']
        if not w3 or not w31 or w3[0]>=w31[0]: errors.append('handler before ongoing operation completed')
    return sorted(set(errors))

records=json.loads((OUT/'core_results.json').read_text())
checks=[]
for rec in records:
    config,case,delay=rec['id'].split('.')
    rows=parse(OUT/(rec['id']+'.log'))
    errors=check_trace(rows,case)
    checks.append({'id':rec['id'],'status':'FAIL' if errors else 'PASS','failures':errors})
(OUT/'trace_checks.json').write_text(json.dumps(checks,indent=2)+'\n')
# Negative control: corrupt a recorded retired instruction and ensure checker rejects it.
rows=parse(OUT/'small.memory.d1.log')
rows['R'][0][3]='ffffffff'
negative=check_trace(rows,'memory')
assert any('mismatch' in x for x in negative)
(OUT/'negative_control.json').write_text(json.dumps({'mutation':'first RVFI instruction -> ffffffff',
    'expected':'checker rejects', 'observed':negative,'status':'PASS'},indent=2)+'\n')

md=['# 10 — Timing đo từ RTL simulation','',
    'SIM — Sinh bằng `scripts/analyze_traces.py`. Cycle lấy trước NBA của cạnh lên; '+
    '`C` là pipeline/control, `W` là cổng RF write, `R` là RVFI, `D` là accepted data transaction. '+
    'Số chu kỳ ID bao gồm mọi lần valid tại PC đó trước sentinel; không bao gồm fetch trước khi vào ID.','',
    '## Latency execution và thời điểm đạt signature','',
    '| Config | Bus | MUL tại 0x8c: cycles ID | MULH tại 0x9c | DIV tại 0x90 | Arithmetic: cycle ghi x31 | Memory: cycle ghi x31 |',
    '|---|---|---:|---:|---:|---:|---:|']
for config in ('small','wb','bt','single','slow'):
    for delay in ('d1','d4'):
        ar=parse(OUT/f'{config}.arithmetic.{delay}.log')
        me=parse(OUT/f'{config}.memory.{delay}.log')
        n=lambda pc:sum(int(x[1],16)==pc and x[2]=='1' for x in ar['C'])
        end=lambda rr:next(int(x[0]) for x in rr['W'] if x[1]=='31')
        md.append(f'| {config} | {delay} | {n(0x8c)} | {n(0x9c)} | {n(0x90)} | {end(ar)} | {end(me)} |')
md += ['', 'MUL/MULH ở bảng này dùng toán hạng cụ thể của chương trình. Slow MUL có early termination; '+
       'không dùng số đo đó cho mọi toán hạng. Cycle signature tính cả boot/fetch/stalls, không phải CPI steady-state. '+
       'D4 có cả response latency 4 và grant mỗi 3 cycle; không phải chỉ tăng latency RAM.', '',
       '## Load-use, split access và side effects','']
for config in ('small','wb'):
    name=f'{config}.memory.d1'
    rows=parse(OUT/f'{name}.log')
    md += [f'### {name}', '',f'[Log gốc](evidence/{name}.log) · [Waveform gzip](evidence/{name}.vcd.gz)', '',
           '| Cycle | PC ID | Valid | FSM | mem stall | load hazard | done ID | req/gnt | response | RF write | RVFI PC |',
           '|---:|---|---:|---|---:|---:|---:|---|---:|---|---|']
    stop=next(int(x[0]) for x in rows['W'] if x[1]=='31')+1
    for x in rows['C']:
        c=int(x[0])
        if c<3 or c>stop: continue
        writes=', '.join(f'x{w[1]}={w[2]}' for w in rows['W'] if int(w[0])==c) or '—'
        ret=', '.join(r[2] for r in rows['R'] if int(r[0])==c) or '—'
        md.append(f'| {c} | {x[1]} | {x[2]} | {"FIRST" if x[3]=="0" else "MULTI"} | {x[4]} | {x[5]} | {x[9]} | {x[11]}/{x[12]} | {x[14]} | {writes} | {ret} |')
    md.append('')
md += ['Ở WB1 cycle 7, load response đã tới và x3 được ghi nhưng dependent ADD tại 0x90 '+
       'vẫn có load hazard. Cycle 8 mới execute. Đường store→load không phụ thuộc data '+
       'có thể chuyển instruction tại chính response cycle. RF write và RVFI là hai mốc khác nhau.', '',
       '## Redirect và memory chậm','',
       '| Config/bus | BEQ not-taken 0x84: cycles ID | BEQ taken 0x8c | JAL 0x94 | JALR 0xa0 | Cycle target 0xa8 vào ID |',
       '|---|---:|---:|---:|---:|---:|']
for config in ('small','bt','wb','single'):
    for delay in ('d1','d4'):
        rows=parse(OUT/f'{config}.control.{delay}.log')
        n=lambda pc:sum(int(x[1],16)==pc and x[2]=='1' for x in rows['C'])
        target=next(int(x[0]) for x in rows['C'] if int(x[1],16)==0xa8 and x[2]=='1')
        md.append(f'| {config}/{delay} | {n(0x84)} | {n(0x8c)} | {n(0x94)} | {n(0xa0)} | {target} |')
md += ['', 'BTALU giảm chu kỳ chiếm ID cho taken branch/jump. Refill delay vẫn phụ thuộc fetch bus. '+
       'Các giá trị target absolute trong bảng không phải branch penalty của một instruction cô lập.', '',
       '## IRQ/debug giữa operation dài', '',
       '| Test (wb, D4) | Cycle phát event | Cycle ghi x3 của operation đang chạy | Cycle ghi marker handler |',
       '|---|---:|---:|---:|']
for case in ('event1','event2','event3','event4'):
    rows=parse(OUT/f'wb.{case}.d4.log')
    w=lambda reg:next(int(x[0]) for x in rows['W'] if x[1]==str(reg))
    md.append(f'| {case} | {rows["EVENT"][0][0]} | {w(3)} | {w(31)} |')
md += ['', 'event1/2: timer IRQ/debug khi load pending; event3/4: khi divider đang stall. '+
       'Marker handler xuất hiện sau completion của operation đang chạy. Đây không phải đo trực tiếp '+
       'latency từ IRQ đến entry: handler còn fetch và chạy instructions trước marker.', '']
(OUT.parent/'10_timing.md').write_text('\n'.join(md))
failed=[x for x in checks if x['failures']]
print(f'Trace checks: {len(checks)-len(failed)}/{len(checks)} PASS; negative control PASS')
if failed:
    print(json.dumps(failed,indent=2));raise SystemExit(1)
