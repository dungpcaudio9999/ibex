#!/usr/bin/env python3
"""Preserve Verilator elaborated hierarchy and actual source dependencies."""
import gzip
import hashlib
import json
import xml.etree.ElementTree as ET
from pathlib import Path
from run_core import ROOT, OUT, execute

dependencies=set()
for config in ('small','wb','bt','single','slow'):
    command=json.loads((OUT/f'{config}.build-command.json').read_text())
    command[command.index('--binary')]='--xml-only'
    execute(command,OUT/f'{config}.elaboration.log')
    obj=Path('/tmp/ibex-microarchitecture')/config
    xml=obj/'Vcore_tb.xml'
    tree=ET.parse(xml)
    cells=[dict(c.attrib) for c in tree.findall('.//cells//cell')]
    parameters=[]
    for module in tree.findall('.//netlist/module'):
        selected={}
        for var in module.findall('var'):
            if var.get('param') and var.get('name') in ('WB','BT','M','BaseIsa','WritebackStage','BranchTargetALU','RV32M','RV32ZC','ICache','SecureIbex'):
                selected[var.get('name')]=[c.attrib for c in var.findall('.//const')]
        if selected: parameters.append({'module':module.get('name'),'original':module.get('origName'),'parameters':selected})
    (OUT/f'{config}.hierarchy.json').write_text(json.dumps({'command':command,'cells':cells,'parameters':parameters},indent=2)+'\n')
    with gzip.open(OUT/f'{config}.elaboration.xml.gz','wb') as f: f.write(xml.read_bytes())
for dep in Path('/tmp/ibex-microarchitecture').glob('*/*__ver.d'):
    content=dep.read_text()
    (OUT/(dep.parent.name+'.dependencies.txt')).write_text(content)
    for word in content.split(' : ',1)[-1].split():
        p=Path(word)
        if p.is_file() and p.is_relative_to(ROOT): dependencies.add(p)
# Also hash all RTL/configuration files analyzed statically, including top/security variants.
dependencies.update((ROOT/'rtl').glob('*.sv'))
dependencies.add(ROOT/'ibex_configs.yaml')
hashes={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(dependencies)}
(OUT/'source_dependencies_sha256.json').write_text(json.dumps(hashes,indent=2)+'\n')
print(f'Captured 5 elaborated hierarchies and {len(hashes)} source dependencies')
