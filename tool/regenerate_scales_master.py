#!/usr/bin/env python3
"""Fase 3: regenera `positions` de assets/data/scales_master.json con reglas musicales.

Uso:  python3 tool/regenerate_scales_master.py [ruta/scales_master.json]

Las posiciones se expresan para raíz C (semitono 0); la app suma el semitono de la raíz
a fret_offset (ver ScalePosition.resolveCoordinates). Cuerdas: 1 = mi aguda ... 6 = mi grave.

Reglas
  CAGED  : por cada forma (C,A,G,E,D) la ventana de trastes de la plantilla de acorde
           (windowStart/windowEnd relativos al traste de la raíz en la cuerda raíz, igual que
           cagedTemplates.ts), recortada a 5 trastes. Posición = TODAS las notas de la escala
           dentro de esa ventana, en las 6 cuerdas.
  3NPS   : sólo escalas de 7 notas. Posición k = escalera ascendente de notas de la escala
           que arranca en el grado k sobre la 6ª cuerda; 3 notas consecutivas por cuerda.
  2NPS   : sólo pentatónicas y blues. Caja k = escalera de 2 notas consecutivas por cuerda; en blues se
           añade la b5 en las cuerdas que ya tienen 4ª y 5ª separadas por 2 trastes.
  4NPS   : sólo escalas de 7 notas y modos. Cada posición 3NPS + la nota siguiente en cada cuerda
           (la repetida en el cambio de cuerda). Berklee NO se genera: no hay definición verificable.
Corrige además los `intervals` de los 7 modos (eran los de Jónico para todos).
No toca id/name/category/description/systems. Idempotente.
"""
import json, sys
from pathlib import Path

OPEN_LOW_TO_HIGH = [4, 9, 2, 7, 11, 4]        # 6ª..1ª (clase de nota)
OPEN_ABS = [40, 45, 50, 55, 59, 64]            # alturas MIDI absolutas, 6ª..1ª
def string_no(i): return 6 - i                  # índice 0 (6ª) -> string 6 ... índice 5 -> string 1
# forma -> (índice de cuerda raíz 0=6ª, windowStart, windowEnd) igual que cagedTemplates.ts
CAGED = {'C': (1, -3, 2), 'A': (1, 0, 4), 'G': (0, -3, 2), 'E': (0, 0, 4), 'D': (2, 0, 4)}
CAGED_ORDER = ['C', 'A', 'G', 'E', 'D']
MAX_BOX = 5                                      # trastes de ancho (incl. extremos)
MODE_ROT = {'ionian': 0, 'dorian': 1, 'phrygian': 2, 'lydian': 3, 'mixolydian': 4, 'aeolian': 5, 'locrian': 6}
MAJOR = [0, 2, 4, 5, 7, 9, 11]
SPANISH = {'C': 'Forma C', 'A': 'Forma A', 'G': 'Forma G', 'E': 'Forma E', 'D': 'Forma D'}

def coord(i, fret, is_root):
    c = {'string': string_no(i), 'fret_offset': fret}
    if is_root: c['is_root'] = True
    return c

def caged_positions(intervals):
    allowed = set(intervals); out = []
    for k, shape in enumerate(CAGED_ORDER):
        rs, ws, we = CAGED[shape]
        anchor = (0 - OPEN_LOW_TO_HIGH[rs]) % 12      # traste de la raíz C en la cuerda raíz
        lo, hi = anchor + ws, min(anchor + we, anchor + ws + MAX_BOX - 1)
        notes = []
        for i in range(6):
            for f in range(max(lo, 0), hi + 1):
                pc = (OPEN_LOW_TO_HIGH[i] + f) % 12
                if pc in allowed: notes.append(coord(i, f, pc == 0))
        frets = [n['fret_offset'] for n in notes]
        out.append({'id': f'caged_{shape.lower()}', 'name': SPANISH[shape], 'system_id': 'caged',
                    'starting_fret': min(frets), 'fret_span': max(frets) - min(frets) + 1,
                    'coordinates': notes})
    return out

def ladder_from(intervals, k, octave, count):
    """Escalera ascendente de `count` alturas absolutas que arranca en el grado k sobre la 6ª cuerda."""
    n = len(intervals); pitch = None
    for f in range(0, 12):
        if (40 + f) % 12 == intervals[k] % 12: pitch = 40 + f + octave; break
    out, idx, cur = [], k, pitch
    for _ in range(count):
        out.append(cur)
        cur += (intervals[(idx + 1) % n] - intervals[idx % n]) % 12; idx += 1
    return out

def make_positions(intervals, system_id, prefix, per_string, extra, max_span):
    """per_string notas consecutivas por cuerda; extra=1 añade la nota siguiente (4NPS)."""
    n = len(intervals); out = []
    for k in range(n):
        for octave in (0, 12):
            ladder = ladder_from(intervals, k, octave, 6 * per_string + extra)
            notes, ok = [], True
            for s in range(6):
                for j in range(per_string + extra):
                    p = ladder[s * per_string + j]; fret = p - OPEN_ABS[s]
                    if fret < 0: ok = False
                    notes.append(coord(s, fret, p % 12 == 0))
            frets = [x['fret_offset'] for x in notes]
            if ok and max(frets) - min(frets) <= max_span:
                out.append({'id': f'{prefix}_{k + 1}', 'name': f'Posición {k + 1}', 'system_id': system_id,
                            'starting_fret': min(frets), 'fret_span': max(frets) - min(frets) + 1,
                            'coordinates': notes})
                break
        else:
            raise RuntimeError(f'{system_id} sin posición válida: {intervals} grado {k}')
    return out

def nps_positions(intervals):            # 3NPS
    return make_positions(intervals, 'three_nps', 'nps', 3, 0, 6)

def linear4_positions(intervals):        # 4NPS = cada posición 3NPS + 1 nota extra por cuerda
    return make_positions(intervals, 'linear_four_notes', 'lin4', 3, 1, 9)

def pentatonic_box_positions(intervals):  # 2 notas por cuerda; blues: añade la b5 entre 4ª y 5ª
    base = [i for i in intervals if i != 6]
    out = make_positions(base, 'pentatonic_two_notes', 'box', 2, 0, 5)
    if 6 in intervals:
        for p in out:
            by = {}
            for c in p['coordinates']: by.setdefault(c['string'], []).append(c['fret_offset'])
            extra = []
            for st, frets in by.items():
                i = 6 - st
                pcs = {(OPEN_LOW_TO_HIGH[i] + f) % 12: f for f in frets}
                if 5 in pcs and 7 in pcs and pcs[7] == pcs[5] + 2:
                    extra.append(coord(i, pcs[5] + 1, False))
            p['coordinates'] += extra
            p['coordinates'].sort(key=lambda c: (-c['string'], c['fret_offset']))
            fr = [c['fret_offset'] for c in p['coordinates']]
            p['starting_fret'], p['fret_span'] = min(fr), max(fr) - min(fr) + 1
    return out

def main(path):
    data = json.loads(Path(path).read_text(encoding='utf-8'))
    for s in data['modes']:
        s['intervals'] = sorted({(m - MAJOR[MODE_ROT[s['id']]]) % 12 for m in MAJOR})
    for s in data['scales'] + data['modes']:
        iv = s['intervals']; pos = []; systems = []
        if s in data['scales']:
            systems.append({'id': 'caged', 'name': 'CAGED'}); pos += caged_positions(iv)
        if len(iv) == 7:
            systems.append({'id': 'three_nps', 'name': '3NPS'}); pos += nps_positions(iv)
        if s in data['scales'] and s['id'] in ('pentatonic_minor', 'pentatonic_major', 'blues_minor'):
            systems.append({'id': 'pentatonic_two_notes', 'name': 'Pentatonic Box (2NPS)'}); pos += pentatonic_box_positions(iv)
        if len(iv) == 7:
            systems.append({'id': 'linear_four_notes', 'name': 'Linear (4NPS)'}); pos += linear4_positions(iv)
        s['systems'], s['positions'] = systems, pos
    data['_meta'] = {'version': 3, 'source': 'rule-generated: tool/regenerate_scales_master.py'}
    Path(path).write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    print('scales_master.json regenerado:', sum(len(s['positions']) for s in data['scales'] + data['modes']), 'posiciones')

if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else str(Path(__file__).resolve().parent.parent / 'assets' / 'data' / 'scales_master.json'))
