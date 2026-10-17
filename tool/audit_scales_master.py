#!/usr/bin/env python3
"""Audita assets/data/scales_master.json: toda nota de cada posición debe pertenecer a la escala
y la etiqueta `interval` (si existe) debe coincidir con la nota real. Raíz C (como en los datos).
Uso: python3 tool/audit_scales_master.py [ruta/scales_master.json]   (exit 1 si hay defectos)"""
import json, sys
from collections import Counter
from pathlib import Path
H = [4, 11, 7, 2, 9, 4]                       # cuerdas 1..6 (1 = mi aguda)
IV = {'1':0,'b2':1,'2':2,'#2':3,'b3':3,'3':4,'4':5,'#4':6,'b5':6,'5':7,'#5':8,'b6':8,'6':9,'bb7':9,'b7':10,'7':11}
path = sys.argv[1] if len(sys.argv) > 1 else str(Path(__file__).resolve().parent.parent / 'assets' / 'data' / 'scales_master.json')
d = json.load(open(path, encoding='utf-8'))
bad, total, ex = Counter(), Counter(), {}
for grp in ('scales', 'modes'):
    for s in d[grp]:
        allowed = set(s['intervals'])
        for p in s['positions']:
            for c in p['coordinates']:
                iv = (H[c['string'] - 1] + c['fret_offset']) % 12
                total[p['system_id']] += 1
                lab = c.get('interval')
                if iv not in allowed or (lab in IV and IV[lab] != iv):
                    bad[p['system_id']] += 1; ex.setdefault(p['system_id'], (s['id'], p['id'], c))
print(f"{'sistema':<14}{'notas':>8}{'defectuosas':>14}")
for k in total: print(f"{k:<14}{total[k]:>8}{bad[k]:>14}" + (f"   ej: {ex[k]}" if k in ex else ''))
sys.exit(1 if sum(bad.values()) else 0)
