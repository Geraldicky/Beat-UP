#!/usr/bin/env python3
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
for name, expected in {'normal':(608,37,14),'hard':(820,101,17)}.items():
    d=json.loads((ROOT/'charts/big_daddy'/f'{name}.json').read_text(encoding='utf-8'))
    actual=(len(d['events']),sum(1 for e in d['events'] if str(e.get('type','normal')).lower()=='reverse'),len(d.get('space_events',[])))
    assert actual==expected,(name,actual,expected)
master=json.loads((ROOT/'charts/big_daddy/master.json').read_text(encoding='utf-8'))
assert len(master['events']) > 900
assert len(master['events']) > 820
assert sum(1 for e in master['events'] if e.get('type')=='reverse') > 101
assert len(master.get('space_events',[])) == 20
print('v17.4.17 Big Daddy difficulty-anchor compatibility checks: PASS')
