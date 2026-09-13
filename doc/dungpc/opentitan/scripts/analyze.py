#!/usr/bin/env python3
"""Check temporal/architectural properties from traces, not simulator FINISH alone."""
import json,statistics
from run import OUT,CASES,make_case
rows={r['id']:r for r in json.loads((OUT/'results.json').read_text())}
logs={k:(OUT/(k+'.log')).read_text().splitlines() for k in CASES}
checks=[]
def check(name,ok,evidence):checks.append({'id':name,'status':'PASS' if ok else 'FAIL','evidence':evidence})
def records(k,p):return [s.split() for s in logs[k] if s.startswith(p+' ')]
def writes(k,rd):return [(int(s[1]),int(s[3],16)) for s in records(k,'W') if int(s[2])==rd]
def first(k,rd,value=None):return next(c for c,v in writes(k,rd) if value is None or v==value)
def tids(k,pc):return [s for s in records(k,'T') if int(s[2],16)==pc and s[3]=='1']
def counts(k):return rows[k]['counts']
def event(k):return int(records(k,'EVENT')[0][1])
def debug_entry(k):return min(int(s[1]) for s in records(k,'R') if int(s[3],16)==0x1a110800)
def younger_blocked(lines):return not any(s.startswith('W ') and int(s.split()[2]) in (2,3,4) for s in lines)
def sample(k,field):return any(field+'=1' in s for s in logs[k] if s.startswith('SAMPLE '))

check('complete_matrix',set(rows)==set(CASES),{'count':len(rows),'expected':len(CASES)})
for k,(mode,name,lat) in CASES.items():
 _,_,expected,_,activity=make_case(name,mode)
 rr={int(s[1]):int(s[2],16) for s in records(k,'REG')}
 ok=all(rr.get(reg)==value for reg,value in expected.items())
 ok &= all(counts(k).get(a,0)>=v for a,v in activity.items())
 ok &= rows[k]['status']=='PASS' and not rows[k]['errors']
 ok &= bool(records(k,'PROTOCOL_CHECKS')) and int(records(k,'PROTOCOL_CHECKS')[0][1])>1100
 check('oracle.'+k,ok,{'expected_registers':expected,'minimum_activity':activity,'protocol_cycles':records(k,'PROTOCOL_CHECKS')})

for k in ['rv.independent_d1','rv.independent_d4']:
 times=[first(k,r) for r in [2,3,4]]
 check('load_before_independent.'+k,times[0]<times[1]<times[2],times)
check('failed_load_no_younger_write',younger_blocked(logs['rv.error_young']),{'log':'rv.error_young.log','forbidden_destinations':[2,3,4]})
check('load_integrity_no_destination_write',not writes('rv.fault2',2),{'log':'rv.fault2.log'})
for k in ['rv.pmp_deny','rv.pmp_region15','cap.bound','cap.fault','cap.zcmp_illegal']:
 check('reject_before_bus.'+k,not records(k,'D') and not records(k,'B'),{'data':counts(k)['data'],'bitmap':counts(k)['bitmap']})
for k,rd in [('rv.div_debug',4),('rv.dret',3),('cap.debug',2)]:
 ts=[event(k),first(k,rd),debug_entry(k)]
 check('drain_before_debug.'+k,ts[0]<ts[1]<ts[2],{'request_write_debug':ts})
k='rv.zcmp_debug';ts=[event(k),first(k,2,0x2f0),debug_entry(k),max(c for c,v in writes(k,2) if v==0x300)]
check('zcmp_debug_at_sequence_boundary',ts==sorted(ts) and len(set(ts))==4,ts)
check('zcmp_irq_single_completed',writes('rv.zcmp_irq',11)[-1][1]==0x9a and writes('rv.zcmp_irq',2)[-1][1]==0x2f0,{'mepc':0x9a,'sp':0x2f0})
check('zcmp_irq_multi_restartable',writes('rv.zcmp_irq_multi',11)[-1][1]==0x98 and writes('rv.zcmp_irq_multi',2)==[(24,0x300)] and len(records('rv.zcmp_irq_multi','D'))==2,{'mepc':0x98,'sp':0x300,'accepted_stores':2})
entries=[int(s[1]) for s in records('rv.debug_trigger','R') if int(s[3],16)==0x1a110800]
check('hardware_execute_trigger_reentry',len(entries)==2 and writes('rv.debug_trigger',14)==[(42,1),(78,2)] and first('rv.debug_trigger',15)>entries[-1],{'debug_entries':entries})
dr=records('cap.roundtrip','D');br=records('cap.roundtrip','B')
check('capability_store_load_tag_roundtrip',len(dr)==6 and len(br)==2 and all(s[-1]=='tag=1' for s in dr[2:4]) and first('cap.roundtrip',4)>int(br[1][1]) and writes('cap.roundtrip',5)[-1][1]==1,{'data_transfers':dr,'bitmap_requests':br})
check('revocation_changes_tag',writes('cap.live',3)[-1][1]==1 and writes('cap.revoked',3)[-1][1]==0 and writes('cap.bitmap_ecc',3)[-1][1]==0,{'live':1,'revoked':0,'bitmap_ecc':0})
check('debug_beats_regular_irq',first('rv.debug_irq',13)<first('rv.debug_irq',10,0x80000007),{'debug_marker':first('rv.debug_irq',13),'irq_cause':first('rv.debug_irq',10)})
check('fence_key_debug_progress',bool(records('rv.cache_debug_key','KEY')) and event('rv.cache_debug_key')<first('rv.cache_debug_key',13)<first('rv.cache_debug_key',15),{'event':event('rv.cache_debug_key'),'keys':records('rv.cache_debug_key','KEY')})
check('wfi_sleep_and_wake',counts('rv.sleep')['sleep']>=20 and event('rv.sleep')<first('rv.sleep',15),{'sleep_cycles':counts('rv.sleep')['sleep'],'wake':event('rv.sleep'),'write_marker':first('rv.sleep',15)})

timing=[]
for k,pc,want in [('rv.dit_off_zero',0x90,2),('rv.dit_off_nonzero',0x90,37),('rv.dit_on_zero',0x90,37),('rv.dit_on_nonzero',0x90,37),('rv.dit_branch_taken',0x8c,2),('rv.dit_branch_nt',0x8c,2)]:
 ts=tids(k,pc);csr_word=int((OUT/(k+'.hex')).read_text().splitlines()[32],16);dit=0 if '_off_' in k else 2
 check('timing.'+k,len(ts)==want and csr_word>>20==dit,{'valid_id_cycles':len(ts),'expected':want,'cpu_ctrl_setup':hex(csr_word)})
 timing.append({'case':k,'pc':hex(pc),'first_id_cycle':int(ts[0][1]),'last_id_cycle':int(ts[-1][1]),'valid_id_cycles':len(ts)})
for pc,label in [(0x88,'ADD'),(0x8c,'MUL'),(0x90,'DIV'),(0x9c,'MULH')]:
 ts=tids('rv.arithmetic',pc);timing.append({'case':'rv.arithmetic','instruction':label,'pc':hex(pc),'first_id_cycle':int(ts[0][1]),'last_id_cycle':int(ts[-1][1]),'valid_id_cycles':len(ts)})
for k in ['rv.independent_d1','rv.independent_d4']:
 timing.append({'case':k,'load_grant':int(records(k,'D')[0][1]),'load_write':first(k,2),'independent_write':first(k,3),'dependent_write':first(k,4)})
cycles=[c for c,v in writes('rv.cache',2)]
for low,high,label in [(80,240,'cache_initial_invalidation'),(300,600,'cache_warm')]:
 window=[c for c in cycles if low<=c<=high];intervals=[b-a for a,b in zip(window,window[1:])]
 timing.append({'case':'rv.cache','window':label,'start':low,'end':high,'iterations':len(intervals),'cycle_intervals':sorted(set(intervals)),'median':statistics.median(intervals)})
check('dit_dummy_cache_coexist',counts('rv.dummy_dit_cache')['dummy']>0 and counts('rv.dummy_dit_cache')['hit']>0 and all(counts('rv.dummy_dit_cache')[a]==0 for a in ('ai','ab','am')),counts('rv.dummy_dit_cache'))
for k,field in [('rv.fault3','rf'),('rv.fault4','mismatch'),('rv.fault6','pc'),('cap.invalid_mode','mode'),('cap.rf_ecc','rf')]:
 check('detector.'+k,sample(k,field),{'sample_field':field})
check('cache_ecc_minor_and_progress',counts('rv.fault10')['am']>0 and counts('rv.fault10')['ai']==counts('rv.fault10')['ab']==0 and writes('rv.fault10',15)[-1][1]==123,counts('rv.fault10'))
check('unsolicited_response_characterization',all(counts('rv.fault7')[a]==0 for a in ('ai','ab','am')) and writes('rv.fault7',15)[-1][1]==123,{'scope':'one unsolicited response point; not proof all malformed responses are benign'})

# Run the actual checker against a deliberately corrupted trace as a negative control.
mutated=logs['rv.error_young']+['W 18 3 00000009 000000000']
negative={'status':'PASS' if younger_blocked(logs['rv.error_young']) and not younger_blocked(mutated) else 'FAIL','mutation':'insert forbidden younger x3 write into failed-load trace','checker':'younger_blocked','original_accepted':younger_blocked(logs['rv.error_young']),'mutation_rejected':not younger_blocked(mutated)}
(OUT/'checker_negative_control.json').write_text(json.dumps(negative,indent=2)+'\n')
(OUT/'analysis_checks.json').write_text(json.dumps(checks,indent=2)+'\n')
(OUT/'timing.json').write_text(json.dumps(timing,indent=2)+'\n')
print('Checks',len(checks),'failures',[c['id'] for c in checks if c['status']!='PASS'])
if negative['status']!='PASS' or any(c['status']!='PASS' for c in checks):raise SystemExit(1)
