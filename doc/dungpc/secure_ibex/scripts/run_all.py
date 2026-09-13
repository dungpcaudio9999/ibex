#!/usr/bin/env python3
"""Reproduce the bounded Secure Ibex experiment matrix."""
import argparse
import subprocess
import sys
from pathlib import Path
BASE=Path(__file__).resolve().parents[1]
RUNNER=BASE.parent/'microarchitecture/scripts/run_extended.py'
CASES={
 'secure':'arithmetic,sleep,reset,dret,debug_irq,nmi_return,dit_off_zero,dit_off_nonzero,dit_on_zero,dit_on_nonzero,ditbranch_off_taken,ditbranch_off_nt,ditbranch_on_taken,ditbranch_on_nt,dummy,fault1,fault2,fault3,fault4,fault6,fault7',
 'secure_offset2':'arithmetic,sleep,reset,dret,fault3,fault4',
 'secure_dual':'cap,cap_revoked,cap_fault,fault5,fault8,fault9',
 'secure_cache':'cache,fault10,reset',
 'secure_combo':'cap,cap_cache,cap_revoked,cap_fault',
}
if __name__=='__main__':
 ap=argparse.ArgumentParser();ap.add_argument('--skip-build',action='store_true');args=ap.parse_args()
 failed=[]
 for config,cases in CASES.items():
  cmd=[sys.executable,str(RUNNER),'--configs',config,'--cases',cases,'--out',str(BASE/'evidence')]
  if args.skip_build:cmd.append('--skip-build')
  ret=subprocess.run(cmd).returncode
  if ret:failed.append(config)
 if failed:raise SystemExit('Some invocations failed (including prior persisted failures): '+','.join(failed))
