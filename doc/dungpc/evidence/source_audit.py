#!/usr/bin/env python3
"""Text/manifest inventory, not an SV parser, elaborator, linter, or simulation."""
import collections
import json
from pathlib import Path
import re
import yaml

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[2]

def read(path):
    return (ROOT / path).read_text()

def main():
    configs = yaml.safe_load(read('ibex_configs.yaml'))
    cores = {}
    for path in ['ibex_core.core', 'ibex_top.core', 'ibex_top_tracing.core',
                 'examples/simple_system/ibex_simple_system.core']:
        data = yaml.safe_load(read(path))
        cores[path] = {'name': data['name'], 'parameters': list(data.get('parameters', {})),
                       'targets': data.get('targets', {}),
                       'config_fields_not_declared': sorted(set(configs['small']) - set(data.get('parameters', {})))}
    legacy = yaml.safe_load(read('src_files.yml'))
    missing = [{'group': group, 'path': path} for group, value in legacy.items()
               for path in value.get('files', []) if not (ROOT / path).exists()]
    modules = []
    for path in sorted((ROOT / 'rtl').glob('*.sv')):
        text = path.read_text()
        modules.append({'path': str(path.relative_to(ROOT)), 'lines': len(text.splitlines()),
                        'declarations_text_only': re.findall(r'^\s*(?:module|package)\s+(\w+)', text, re.M),
                        'assert_macro_occurrences_text_only': len(re.findall(r'`ASSERT\w*\s*\(', text)),
                        'ifdefs': re.findall(r'^\s*`(?:ifdef|ifndef)\s+(\w+)', text, re.M)})
    locks = {}
    for path in sorted((ROOT / 'vendor').glob('*.lock.hjson')):
        locks[str(path.relative_to(ROOT))] = dict(re.findall(r'^\s*(url|rev):\s*(\S+)', path.read_text(), re.M))
    source_manifest = json.loads((OUT / 'source_manifest.json').read_text())
    counts = collections.Counter(p['path'].split('/')[0] for p in source_manifest)
    result = {'method': 'PyYAML and regular expressions; intended declarations only; no elaboration',
              'configurations': configs, 'core_manifests': cores,
              'missing_src_files_yml_paths': missing, 'rtl_inventory': modules,
              'vendor_lock_declarations': locks, 'tracked_files_by_root': dict(sorted(counts.items()))}
    (OUT / 'source_audit.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({'named_config_count': len(configs), 'rtl_sv_files': len(modules),
                      'rtl_lines': sum(m['lines'] for m in modules),
                      'missing_src_files_yml_paths': missing,
                      'configuration_fields_not_declared_in_simple_system': cores['examples/simple_system/ibex_simple_system.core']['config_fields_not_declared'],
                      'result': 'Inventory completed; findings require contextual review, not a lint pass'}, indent=2))

if __name__ == '__main__':
    main()
