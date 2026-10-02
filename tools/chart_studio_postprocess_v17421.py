#!/usr/bin/env python3
"""Beat UP! v17.4.21 Chart Studio readability post-process.

Applies the validated v17.4.19 Big-Daddy-benchmark safety policy to freshly
created custom charts without moving any retained timestamp or direction.
"""
from __future__ import annotations
import argparse, json, math
from pathlib import Path
from typing import Dict, List, Tuple

VERSION = "17.4.21"
REVERSE_RATIO = {"normal": 0.06, "hard": 0.12, "master": 0.17}
OPENING_SECONDS = {"normal": 8.0, "hard": 4.0, "master": 2.0}
REVERSE_INDEX_GAP = {"normal": 4, "hard": 2, "master": 1}
INTENSE = {"pre_chorus", "chorus", "climax"}
CALM = {"intro", "outro", "interlude"}
ROLE_WEIGHT = {"intro": .52, "outro": .54, "interlude": .68, "bridge": .80,
               "verse": .92, "pre_chorus": 1.08, "chorus": 1.22, "climax": 1.36}

def section_for_time(chart: Dict, t: float) -> Dict:
    for s in chart.get("sections", []):
        if float(s.get("start", -1)) <= t < float(s.get("end", 1e30)):
            return s
    return {"role":"verse","energy":.5}

def cd(a,b):
    d=abs(a-b); return min(d,1-d)

def phase_priority(chart,t):
    beat=60.0/max(1e-6,float(chart.get("bpm",120)))
    frac=((t-float(chart.get("beat_offset",0)))/beat)%1.0
    if cd(frac,0)<=.035: return 3.2
    if cd(frac,.5)<=.035: return 2.45
    if cd(frac,.25)<=.035 or cd(frac,.75)<=.035: return 1.35
    return 1.0

def keep_score(chart, events, idx, spaces):
    e=events[idx]; t=float(e["time"]); score=phase_priority(chart,t)
    if round(t,6) in spaces: score += 12
    sec=section_for_time(chart,t); role=str(sec.get("role","verse")); energy=float(sec.get("energy",.5))
    score += .22 if role in ("chorus","climax") else (-.10 if role in CALM else .04)
    score += energy*.06
    if str(e.get("type","normal")).lower()=="reverse": score -= .15
    return score

def window_cap(chart, seconds, role):
    diff=str(chart.get("chart_difficulty",chart.get("difficulty","normal"))).lower()
    bpm=float(chart.get("bpm",120)); intense=role in INTENSE; calm=role in CALM
    if diff=="normal":
        if seconds==.5: return 4 if intense and bpm>=180 else 3
        if seconds==1.0: return 6 if intense else (4 if calm else 5)
        return 15 if intense else (11 if calm else 13)
    if diff=="hard":
        if seconds==.5: return 5 if intense else 4
        if seconds==1.0: return 8 if intense else (5 if calm else 6)
        return 19 if intense else (15 if calm else 17)
    if seconds==.5: return 6 if intense else 5
    if seconds==1.0: return 9 if intense else (7 if calm else 8)
    return 21 if intense else (17 if calm else 19)

def enforce_window(chart, events, seconds):
    events=[dict(e) for e in sorted(events,key=lambda e:float(e["time"]))]; spaces={round(float(t),6) for t in chart.get("space_events",[])}; removed=0
    while True:
        violation=None; left=0
        for right in range(len(events)):
            while left<right and float(events[right]["time"])-float(events[left]["time"])>seconds+1e-9: left+=1
            w=events[left:right+1]
            if not w: continue
            mid=(float(w[0]["time"])+float(w[-1]["time"]))/2
            role=str(section_for_time(chart,mid).get("role","verse"))
            if len(w)>window_cap(chart,seconds,role): violation=(left,right); break
        if violation is None: break
        l,r=violation
        victim=min(range(l,r+1), key=lambda i:(keep_score(chart,events,i,spaces),-float(events[i]["time"])))
        events.pop(victim); removed+=1
    return events, removed

def chain_limit(chart, threshold, role):
    diff=str(chart.get("chart_difficulty",chart.get("difficulty","normal"))).lower(); intense=role in INTENSE
    if threshold<=.100001:
        base={"normal":1,"hard":2,"master":3}[diff]
        return base+(1 if diff=="master" and intense else 0)
    base={"normal":3,"hard":5,"master":7}[diff]
    if intense and diff!="normal": base+=1
    return base

def enforce_chain(chart, events, threshold):
    events=[dict(e) for e in events]; spaces={round(float(t),6) for t in chart.get("space_events",[])}; removed=0
    while True:
        violation=None; start=0
        for i in range(1,len(events)):
            gap=float(events[i]["time"])-float(events[i-1]["time"])
            if gap < threshold-1e-9:
                mid=(float(events[start]["time"])+float(events[i]["time"]))/2
                role=str(section_for_time(chart,mid).get("role","verse"))
                if i-start+1>chain_limit(chart,threshold,role): violation=(start,i); break
            else: start=i
        if violation is None: break
        l,r=violation; candidates=list(range(l+1,r)) if r-l>=2 else list(range(l,r+1))
        victim=min(candidates,key=lambda i:(keep_score(chart,events,i,spaces),-float(events[i]["time"])))
        events.pop(victim); removed+=1
    return events, removed

def neighbor_gaps(chart,events,idx):
    beat=60.0/max(1e-6,float(chart.get("bpm",120))); t=float(events[idx]["time"])
    prev=t-float(events[idx-1]["time"]) if idx>0 else 99
    nxt=float(events[idx+1]["time"])-t if idx+1<len(events) else 99
    return prev,nxt,prev/beat,nxt/beat

def relocate_reverse(chart,events):
    diff=str(chart.get("chart_difficulty",chart.get("difficulty","normal"))).lower()
    target=int(round(len(events)*REVERSE_RATIO[diff])); original={round(float(e["time"]),6) for e in events if str(e.get("type","normal")).lower()=="reverse"}
    first=float(events[0]["time"]) if events else 0
    for e in events: e["type"]="normal"
    if target<=0 or not events: return 0
    abs_thr, beat_thr = {"normal":(.18,.75),"hard":(.15,.55),"master":(.12,.40)}[diff]
    min_gap=REVERSE_INDEX_GAP[diff]; chosen=set()
    for abs_lim,beat_lim in [(abs_thr,beat_thr),(max(.10,abs_thr-.03),max(.30,beat_thr-.15)),(.08,.25)]:
        ranked=[]
        for i,e in enumerate(events):
            if i in chosen: continue
            t=float(e["time"])
            if t<first+OPENING_SECONDS[diff]: continue
            ps,ns,pb,nb=neighbor_gaps(chart,events,i)
            if min(ps,ns)+1e-9<abs_lim or min(pb,nb)+1e-9<beat_lim: continue
            sec=section_for_time(chart,t); role=str(sec.get("role","verse")); energy=float(sec.get("energy",.5))
            score=phase_priority(chart,t)*.22+ROLE_WEIGHT.get(role,.9)*.55+energy*.18+min(pb,nb,2)*.10
            if round(t,6) in original: score+=.24
            score += ((i*2654435761)&0xFFFF)/65535*.006
            ranked.append((score,i))
        ranked.sort(reverse=True)
        for _,i in ranked:
            if any(abs(i-j)<=min_gap for j in chosen): continue
            chosen.add(i)
            if len(chosen)>=target: break
        if len(chosen)>=target: break
        if min_gap>0: min_gap-=1
    if len(chosen)<target:
        for i,e in enumerate(events):
            if i in chosen or float(e["time"])<first+OPENING_SECONDS[diff]: continue
            if any(abs(i-j)<=min_gap for j in chosen): continue
            chosen.add(i)
            if len(chosen)>=target: break
    for i in chosen: events[i]["type"]="reverse"
    return len(chosen)

def longest_chain(times,threshold):
    if not times:return 0
    best=cur=1
    for i in range(1,len(times)):
        if times[i]-times[i-1]<threshold-1e-9: cur+=1; best=max(best,cur)
        else:cur=1
    return best

def patch(path:Path):
    chart=json.loads(path.read_text(encoding="utf-8")); before=[dict(e) for e in chart.get("events",[])]; spaces=list(chart.get("space_events",[]))
    original={(round(float(e["time"]),6),int(e["direction"])) for e in before}
    events,r05=enforce_window(chart,before,.5); events,r10=enforce_window(chart,events,1.0); events,r30=enforce_window(chart,events,3.0)
    events,ru=enforce_chain(chart,events,.100); events,rt=enforce_chain(chart,events,.170); rev=relocate_reverse(chart,events)
    for e in events:
        if (round(float(e["time"]),6),int(e["direction"])) not in original: raise RuntimeError("retained timing/direction changed")
    if list(chart.get("space_events",[]))!=spaces: raise RuntimeError("SPACE changed")
    chart["events"]=events; diff=str(chart.get("chart_difficulty",chart.get("difficulty","normal"))).lower(); times=[float(e["time"]) for e in events]
    chart["special_note_counts"]={"reverse":rev}
    gm=chart.setdefault("generator_meta",{}); gm["postprocess_version"]=VERSION; gm["postprocess_code"]="BUP-CS-17421"; gm["postprocess_policy"]="big_daddy_benchmark_readability_guard"
    diag=chart.setdefault("generator_diagnostics",{}); diag.update({"chart_studio_postprocess":VERSION,"removed_notes":len(before)-len(events),"removed_0_5s_budget":r05,"removed_1s_budget":r10,"removed_3s_budget":r30,"removed_ultra_chain":ru,"removed_tight_chain":rt,"longest_sub_100ms_chain_notes":longest_chain(times,.100),"longest_sub_170ms_chain_notes":longest_chain(times,.170),"reverse_count":rev,"space_count":len(spaces)})
    profile=chart.setdefault("difficulty_profile",{}); profile.update({"balance_version":"v17.4.21","benchmark_chart":"big_daddy_v17.4.18","reverse_target_ratio":REVERSE_RATIO[diff],"burst_readability_guard":True,"sustained_tight_chain_guard":True})
    path.write_text(json.dumps(chart,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
    return {"difficulty":diff,"before":len(before),"after":len(events),"removed":len(before)-len(events),"reverse":rev,"space":len(spaces)}

def main():
    ap=argparse.ArgumentParser(); ap.add_argument("--directory",required=True); ap.add_argument("--output")
    args=ap.parse_args(); d=Path(args.directory).resolve(); results=[]
    for p in sorted(d.glob("*.json")): results.append(patch(p))
    payload={"ok":True,"version":VERSION,"results":results}
    text=json.dumps(payload,ensure_ascii=False,indent=2)
    if args.output: Path(args.output).write_text(text,encoding="utf-8")
    else: print(text)

if __name__=="__main__": main()
