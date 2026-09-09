#!/usr/bin/env python3
"""Finite arithmetic models of selected source equations. DOES NOT EXECUTE RTL.

Predictions: instruction indices alias modulo 1 MiB; data decoder rejects
aliases; sticky timer IRQ remains set after writing mtime backwards, clears
on a comparator write, and can reassert on the following edge.
Negative mode corrupts one observed model result to check the comparison only.
"""
import json
from pathlib import Path
import sys

OUT = Path(__file__).resolve().parent
MASK64 = (1 << 64) - 1

def timer_step(t, cmp, irq, write=None):
    nt = (t + 1) & MASK64
    nc = cmp
    if write is not None:
        offset, data, be = write
        mask = sum(0xff << (8 * b) for b in range(4) if (be >> b) & 1)
        if offset in (0, 4):
            shift = 8 * offset
            half = (((t >> shift) & 0xffffffff) & ~mask) | (data & mask)
            nt = (nt & ~(0xffffffff << shift)) | (half << shift)
        if offset in (8, 12):
            shift = 8 * (offset - 8)
            half = (((cmp >> shift) & 0xffffffff) & ~mask) | (data & mask)
            nc = (nc & ~(0xffffffff << shift)) | (half << shift)
    ni = int((t >= cmp or irq) and not (write and write[0] in (8, 12)))
    return nt, nc, ni

def main():
    negative = '--corrupt-check' in sys.argv
    # Each step starts with the previous post-edge state; no randomization.
    state = (0, 0, 0)
    stimulus = [None, (8, 100, 15), (0, 150, 15), None, (0, 0, 15), None,
                (8, 1, 15), None, (8, 0, 0), None]
    expected_irq = [1, 0, 0, 1, 1, 1, 0, 1, 0, 1]
    trace = []
    for edge, (write, expected) in enumerate(zip(stimulus, expected_irq), 1):
        before = state
        state = timer_step(*state, write)
        observed = state[2] ^ int(negative and edge == 5)
        trace.append({'edge': edge, 'before': before, 'write_offset_data_be': write,
                      'after': state, 'observed_irq': observed, 'expected_irq': expected})
        if observed != expected:
            result = {'model_only': True, 'result': 'EXPECTED-NEGATIVE-DETECTED' if negative else 'FAIL',
                      'edge': edge, 'trace': trace}
            (OUT / ('model_negative.json' if negative else 'model_positive.json')).write_text(json.dumps(result, indent=2) + '\n')
            print(json.dumps(result))
            return 1
    mapping = []
    regions = [('ram', 0x100000, 0xfff00000), ('simctrl', 0x20000, 0xfffffc00),
               ('timer', 0x30000, 0xfffffc00)]
    for address in [0x100000, 0x1fffff, 0x200000, 0x000080, 0x100080, 0x200080,
                    0x20000, 0x203ff, 0x20400, 0x30000, 0x303ff, 0x30400]:
        mapping.append({'address': hex(address), 'instruction_ram_word_index': (address >> 2) & 0x3ffff,
                        'data_targets': [n for n, base, mask in regions if address & mask == base]})
    result = {'model_only': True, 'randomization': None, 'result': 'PREDICTIONS-MATCH-MODEL',
              'timer_trace': trace, 'address_decode': mapping,
              'bitmap_bytes': 1 << 11, 'bitmap_bits': 8 * (1 << 11),
              'covered_heap_bytes': 8 * 8 * (1 << 11)}
    (OUT / 'model_positive.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({'result': result['result'], 'timer_edges': len(trace),
                      'address_cases': len(mapping), 'covered_heap_bytes': result['covered_heap_bytes'],
                      'RTL_SIMULATION': 'NOT-RUN'}))
    return 0

if __name__ == '__main__':
    sys.exit(main())
