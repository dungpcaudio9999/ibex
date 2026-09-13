#!/usr/bin/env python3
"""Check observed detector paths/timing against source-derived predictions; emit tables."""
import json
from pathlib import Path
BASE=Path(__file__).resolve().parents[1];OUT=BASE/'evidence'
def rows(name,prefix):
 return [r.split() for r in (OUT/f'{name}.log').read_text().splitlines() if r.startswith(prefix+' ')]
def fields(row):return dict(w.split('=') for w in row[2:])
def detector_from_text(text,key):
 rr=[line.split() for line in text.splitlines() if line.startswith('SAMPLE ')]
 return next((int(r[1]) for r in rr if fields(r).get(key)=='1'),None)
def first_detector(name,key):
 return detector_from_text((OUT/f'{name}.log').read_text(),key)
def require_detector(text,key,cycle):
 assert detector_from_text(text,key)==cycle
checks=[];timing=[]
for name,n in [('dit_off_zero',2),('dit_off_nonzero',37),('dit_on_zero',37),('dit_on_nonzero',37),
               ('ditbranch_off_taken',1),('ditbranch_off_nt',1),('ditbranch_on_taken',2),('ditbranch_on_nt',2)]:
 pc=0x8c if 'branch' in name else 0x90
 rr=[r for r in rows('secure.'+name,'C') if int(r[2],16)==pc and r[3]=='1']
 assert len(rr)==n,(name,len(rr),n)
 timing.append(dict(id=name,id_cycles=len(rr),multdiv_stall_cycles=sum(int(r[5]) for r in rr)))
 checks.append({'id':name,'status':'PASS','check':'ID residence matches source-derived timing expectation'})
predictions={'secure.fault1':('ab',5),'secure.fault2':('ab',8),'secure.fault3':('rf',103),
 'secure.fault4':('mismatch',105),'secure.fault6':('pc',100),'secure_dual.fault5':('mode',100),
 'secure_dual.fault8':('rf',102),'secure_dual.fault9':('ab',16),
 'secure_offset2.fault3':('rf',104),'secure_offset2.fault4':('mismatch',106)}
faults=[]
for name,(key,cycle) in predictions.items():
 actual=first_detector(name,key);assert actual==cycle,(name,key,actual,cycle)
 faults.append(dict(id=name,detector=key,first_stable_sample=actual))
 checks.append(dict(id=name,status='PASS',check='detector identity and first-sample consistency for this preserved stimulus'))
# A load payload integrity fault must suppress that architectural write, not merely raise an alert.
w=rows('secure.fault2','W');assert not any(r[2]=='2' for r in w)
assert any(r[2]=='10' and r[3]=='ffffffe0' for r in w)
assert any(r[2]=='12' and r[3]=='00000208' for r in w)
checks.append(dict(id='bad_load_containment',status='PASS',check='no destination write, internal ECC NMI cause/address'))
# No extra architectural write from a well-formed unsolicited response.
w=rows('secure.fault7','W');assert sum(r[2]=='2' for r in w)==1
assert all(r[2] in ('1','2','3','15') for r in w)
assert not rows('secure.fault7','ALERT')
checks.append(dict(id='unsolicited_response',status='PASS',check='one legitimate load write, no foreign destination/alert'))
w=rows('secure.dummy','W');assert all(r[2] in ('1','2','15') for r in w)
assert not rows('secure.dummy','ALERT')
checks.append(dict(id='dummy_isolation',status='PASS',check='no architectural writes outside real program destinations; no alerts'))
for name in ('dret','debug_irq','nmi_return'):
 pc=[int(r[3],16) for r in rows('secure.'+name,'R')]
 entry=0x7c if name=='nmi_return' else 0x40
 assert pc.index(0x94)<pc.index(entry)
 if name=='debug_irq':assert pc.index(0x44)<pc.index(0x1c) and 0x98 not in pc
 elif name=='dret':assert pc.index(0x44)<pc.index(0x98)
 else:assert pc.index(0x30c)<pc.index(0x98)
 checks.append(dict(id=name+'_ordering',status='PASS',check='older load retirement, event entry and return/priority order'))
for config in ('secure_dual','secure_combo'):
 for case,tag in [('cap',1),('cap_revoked',0)]:
  name=config+'.'+case;w=next(r for r in rows(name,'W') if r[2]=='2')
  assert ((int(w[4],16)>>32)&1)==tag
  assert [int(r[3],16) for r in rows(name,'D')]==[0x200,0x204]
  assert len(rows(name,'B'))==1
  checks.append(dict(id=name+'_tag',status='PASS',check='two data words, one bitmap, resulting RF tag'))
r={x['id']:x for x in json.loads((OUT/'results.json').read_text())}
assert len(r)==40 and all(x['status']=='PASS' for x in r.values())
for name in ('secure_cache.cache','secure_cache.fault10'):
 c=r[name]['counts'];assert c['keys']>=1 and c['hit']>0
 if name.endswith('fault10'):
  assert c['am']>0 and c['ai']==c['ab']==0
  alerts=rows(name,'ALERT');assert alerts[0]==['ALERT','minor','350']
 else:assert c['am']==c['ai']==c['ab']==0
 checks.append(dict(id=name+'_cache',status='PASS',check='key response, hits, correct alert class and final result'))
assert r['secure_combo.cap_cache']['counts']['hit']>0
checks.append(dict(id='secure_combo_cache',status='PASS',check='combined cap/bitmap/cache activity with no alerts'))
# Negative control: a checker of the fault path must reject a log with detector evidence removed.
negative_name='secure.fault3';original=(OUT/f'{negative_name}.log').read_text()
mutated=original.replace('rf=1','rf=0')
assert any('rf=1' in line for line in original.splitlines() if line.startswith('SAMPLE '))
require_detector(original,'rf',103)
rejected=False
try:require_detector(mutated,'rf',103)
except AssertionError:rejected=True
assert rejected,'checker accepted a log without required detector evidence'
(OUT/'checker_negative_control.json').write_text(json.dumps({'status':'PASS','mutation':'remove RF detector high samples from an in-memory copy of secure.fault3','expected':'required detector evidence absent; reject','observed':'rejected'},indent=2)+'\n')
(OUT/'analysis_checks.json').write_text(json.dumps(checks,indent=2)+'\n')
(OUT/'timing_metrics.json').write_text(json.dumps(timing,indent=2)+'\n')
(OUT/'detector_metrics.json').write_text(json.dumps(faults,indent=2)+'\n')
lines=['# Bảng số đo Secure Ibex','', 'Tự sinh từ logs RTL bằng [script](scripts/summarize_experiments.py).', '', '| Test | ID residence | Mult/div stall cycles |','|---|---:|---:|']
for x in timing:lines.append(f"| {x['id']} | {x['id_cycles']} | {x['multdiv_stall_cycles']} |")
lines+=['','| Fault test | Detector | First stable sample cycle |','|---|---|---:|']
for x in faults:lines.append(f"| {x['id']} | {x['detector']} | {x['first_stable_sample']} |")
lines+=['','Cycle label lấy root-clock counter. SAMPLE chạy negedge+1ns sau stimuli settle;',
        'force RF/EX/PC/cap tại negedge cycle100, release110; mode invalid từ100.',
        'Bus faults xuất hiện theo response, không ở100. Cache injection tại350..354,',
        'first minor alert350. Đây là độ trễ của stimulus cụ thể, không bound cho mọi fault.',
        'C/W/R ghi tại gated posedge trước state update; các vùng delta-cycle khác nhau',
        'có thể lệch một nhãn cycle so với SAMPLE, nên dùng SAMPLE cho detector latency.',
        '',f'{len(r)} directed runs PASS; {len(checks)} additional analysis checks PASS.',
        'Alert counter đếm số root cycles có alert, không phải số faults độc lập.']
(BASE/'07_measured_tables.md').write_text('\n'.join(lines)+'\n')
print('PASS',len(r),'runs;',len(checks),'analysis checks')
