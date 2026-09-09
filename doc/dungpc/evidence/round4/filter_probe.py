"""Probe the actual test filter without importing the unavailable DV dependencies.

Only the inspected pure function is compiled from its AST; annotations are deferred
and the typeguard decorator is omitted. This probes Python selection, not RTL.
Run from repository root: python3 doc/dungpc/evidence/round4/filter_probe.py
"""
import ast
import json
import logging
from pathlib import Path
from types import SimpleNamespace

source = Path('dv/uvm/core_ibex/scripts/ibex_cmd.py')
tree = ast.parse(source.read_text())
function = next(n for n in tree.body if isinstance(n, ast.FunctionDef)
                and n.name == 'filter_tests_by_config')
function.decorator_list = []
module = ast.Module(body=[ast.ImportFrom(module='__future__',
                    names=[ast.alias(name='annotations')], level=0), function],
                    type_ignores=[])
ast.fix_missing_locations(module)
namespace = {'logger': logging.getLogger('round4-filter-probe')}
exec(compile(module, str(source), 'exec'), namespace)
filter_tests = namespace['filter_tests_by_config']
config = SimpleNamespace(params={'PMPEnable': 0, 'ICache': 0})
cases = [
    {'test': 'first_matches_second_fails', 'rtl_params': {'PMPEnable': 0, 'ICache': 1}},
    {'test': 'both_match', 'rtl_params': {'PMPEnable': 0, 'ICache': 0}},
]
actual = [[t['test'] for t in filter_tests(config, [case])] for case in cases]
expected = [[], ['both_match']]
report = {'scope': 'Actual Python filter function, decorator omitted; no RTL run',
          'source': str(source), 'config': config.params, 'cases': cases,
          'expected': expected, 'actual': actual,
          'matches_intended_filter_contract': actual == expected}
print(json.dumps(report, indent=2))
Path('doc/dungpc/evidence/round4/filter_probe.json').write_text(
    json.dumps(report, indent=2) + '\n')
