#!/usr/bin/env python3
import json
from pathlib import Path
ROOT = Path(__file__).resolve().parents[1]
BASE = Path('/mnt/data/Beat_UP_v17.4.17')
master = json.loads((ROOT/'charts/big_daddy/master.json').read_text(encoding='utf-8'))
normal = json.loads((ROOT/'charts/big_daddy/normal.json').read_text(encoding='utf-8'))
hard = json.loads((ROOT/'charts/big_daddy/hard.json').read_text(encoding='utf-8'))

events = master['events']
assert len(events) == 974
assert sum(1 for e in events if e.get('type') == 'reverse') == 163
assert len(master.get('space_events', [])) == 20
assert all(events[i]['time'] < events[i+1]['time'] for i in range(len(events)-1))
assert all(e.get('type') in ('normal','reverse') for e in events)
assert all(int(e.get('direction',0)) in (1,2,3,4,6,7,8,9) for e in events)
assert master.get('telemetry_master_rebalance',{}).get('version') == '17.4.18'
assert master.get('star_rating') == 11

# NORMAL/HARD structure remains frozen.
assert (len(normal['events']), sum(1 for e in normal['events'] if e.get('type')=='reverse'), len(normal.get('space_events',[]))) == (608,37,14)
assert (len(hard['events']), sum(1 for e in hard['events'] if e.get('type')=='reverse'), len(hard.get('space_events',[]))) == (820,101,17)

# New MASTER must be a pure-removal subset of v17.4.17: retained event objects are unchanged.
if BASE.exists():
    old = json.loads((BASE/'charts/big_daddy/master.json').read_text(encoding='utf-8'))
    old_by_time = {round(float(e['time']),6): e for e in old['events']}
    for e in events:
        t = round(float(e['time']),6)
        assert t in old_by_time
        assert e == old_by_time[t]

print('v17.4.18 Big Daddy MASTER telemetry rebalance checks: PASS')
