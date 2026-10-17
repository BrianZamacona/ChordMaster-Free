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

def nps_positions(intervals):
    n = len(intervals); out = []
    for k in range(n):
        for octave in (0, 12):
            # primera nota: grado k en la 6ª cuerda, traste >= 0
            pitch = None
            for f in range(0, 12):
                if (40 + f) % 12 == intervals[k] % 12: pitch = 40 + f + octave; break
            ladder = []; idx = k; cur = pitch
            for _ in range(18):
                ladder.append(cur)
                # distancia hasta la siguiente nota de la escala (circular)
                gap = (intervals[(idx + 1) % n] - intervals[idx % n]) % 12
                cur += gap; idx += 1
            notes = []; ok = True
            for s in range(6):
                for j in range(3):
                    p = ladder[s * 3 + j]; fret = p - OPEN_ABS[s]
                    if fret < 0: ok = False
                    notes.append(coord(s, fret, p % 12 == 0))
            frets = [x['fret_offset'] for x in notes]
            if ok and max(frets) - min(frets) <= 6:
                out.append({'id': f'nps_{k + 1}', 'name': f'Posición {k + 1}', 'system_id': 'three_nps',
                            'starting_fret': min(frets), 'fret_span': max(frets) - min(frets) + 1,
                            'coordinates': notes})
                break
        else:
            raise RuntimeError(f'3NPS sin posición válida: {intervals} grado {k}')
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
        s['systems'], s['positions'] = systems, pos
    data['_meta'] = {'version': 2, 'source': 'rule-generated: tool/regenerate_scales_master.py'}
    Path(path).write_text(json.dumps(data, indent=2, ensure_ascii=False) + '\n', encoding='utf-8')
    print('scales_master.json regenerado:', sum(len(s['positions']) for s in data['scales'] + data['modes']), 'posiciones')

if __name__ == '__main__':
    main(sys.argv[1] if len(sys.argv) > 1 else str(Path(__file__).resolve().parent.parent / 'assets' / 'data' / 'scales_master.json'))
