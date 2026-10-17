#!/usr/bin/env python3
"""Fase 2: regenera las digitaciones defectuosas de assets/data/chords.json.

Uso (desde cualquier carpeta):  python3 tool/regenerate_chord_data.py [ruta/chords.json]

Corrige, con reglas musicales explícitas (no parches manuales):
  1. Principal de los 11 Sus2 mal transpuestos  -> forma A:  x-r-(r+2)-(r+2)-r-r
  2. Principal de F mayor/menor/7/m7            -> forma E en cejilla al traste 1
  3. Principal de E dim (llevaba la 6ª de dim7)  -> 0-1-2-0-x-x  (E-Bb-E-G)
  4. 'Top-Set Tension' de Dom 7                  -> G-B-e con 1ª-3ª-b7 (la 3ª se había subido a 4ª)
  5. advancedInversions (7mas, 144 entradas)     -> búsqueda por reglas (ver generate_inversion)
  6. Formas de principiante en 4 cuerdas, sin cejilla grande, para acordes cuya única forma
     baja es una cejilla completa (F, B, Bm, F#m): se añaden a `voicings` como 'Beginner Grip'.
  7. Power chords (tipo power5): raíz-5ª-octava (R-5-R) sin repetir la 5ª, con la raíz en la
     6ª, 5ª, 4ª y 3ª cuerda (en la 4ª y 3ª la octava cae un traste más arriba por la afinación
     de la 2ª cuerda). Al aire si cae en el traste 0. Van a `voicings`; la principal es la
     abierta si hay (E5, A5, D5) o la más baja con raíz en la 6ª o la 5ª cuerda.
No toca ningún otro campo. Idempotente: correrlo dos veces da el mismo archivo.
"""
import json, sys
from pathlib import Path

NOTES = ['C','C#','D','D#','E','F','F#','G','G#','A','A#','B']
OPEN = [4, 9, 2, 7, 11, 4]                      # E A D G B e (6a -> 1a)
INV_IDX = {'root': 0, '1st': 1, '2nd': 2, '3rd': 3}
MAX_FRET = 15                                    # tope para el diseño de inversiones

def rel(string, fret, root):                     # intervalo (0-11) de una nota respecto a la raíz
    return (OPEN[string] + fret - root) % 12

# ---------- dedos: un dedo solo cubre cuerdas contiguas sin un traste MÁS BAJO en medio ----------
def assign_fingers(frets):
    """frets: 6 valores (-1 = muteada). Devuelve (dedos[6], nº de dedos) o None si no se puede."""
    notes = [(s, f) for s, f in enumerate(frets) if f > 0]
    actions = []                                  # [(fret, [cuerdas])]
    for fret in sorted({f for _, f in notes}):
        strings = [s for s, f in notes if f == fret]
        run = [strings[0]]
        for s in strings[1:]:
            between = [frets[x] for x in range(run[-1] + 1, s)]
            lower_between = any(0 < b < fret for b in between) or any(b == 0 for b in between)
            if lower_between: actions.append((fret, run)); run = [s]
            else: run.append(s)
        actions.append((fret, run))
    if len(actions) > 4: return None
    fingers = [0] * 6
    for n, (_, strings) in enumerate(actions, start=1):
        for s in strings: fingers[s] = n
    return fingers, len(actions)

# ---------- inversiones de 7ª en las cuerdas A-D-G-B ----------
def generate_inversion(root, intervals, inv, need=None):
    bass = intervals[INV_IDX[inv]]
    full = need is None
    if need is None: need = {intervals[0], intervals[1], intervals[3]}   # raíz, 3ª y 7ª siempre presentes
    tones = set(intervals)
    best = None
    for fa in range(1, MAX_FRET + 1):
        if rel(1, fa, root) != bass: continue
        for fd in range(1, MAX_FRET + 1):
            if rel(2, fd, root) not in tones: continue
            for fg in range(1, MAX_FRET + 1):
                if rel(3, fg, root) not in tones: continue
                for fb in range(1, MAX_FRET + 1):
                    r_b = rel(4, fb, root)
                    if r_b not in tones: continue
                    frets = [-1, fa, fd, fg, fb, -1]
                    got = {rel(i, f, root) for i, f in enumerate(frets) if f >= 0}
                    if not need <= got: continue
                    played = [fa, fd, fg, fb]
                    span = max(played) - min(played)
                    if span > 4: continue
                    fg_ = assign_fingers(frets)
                    if fg_ is None: continue
                    key = (min(played), span, sum(played))
                    if best is None or key < best[0]: best = (key, frets, fg_[0])
    if best is None and full:
        # respaldo (p. ej. Gmaj7/B): sin raíz alcanzable en 4 trastes, basta 3ª + 7ª
        return generate_inversion(root, intervals, inv, need={intervals[1], intervals[3]})
    if best is None: raise RuntimeError(f"sin voicing: root={root} {intervals} {inv}")
    return best[1], best[2]

# 6. (raíz, tipo) -> (fretPositions, fingerPositions), orden 6ª -> 1ª.
BEGINNER_GRIPS = {
    ('F', 'major'):  ([-1, -1, 3, 2, 1, 1], [0, 0, 3, 2, 1, 1]),   # F A C F (cejilla mini 2 cuerdas)
    ('B', 'major'):  ([-1, -1, 4, 4, 4, 2], [0, 0, 2, 3, 4, 1]),   # F# B D# F#
    ('B', 'minor'):  ([-1, -1, 4, 4, 3, 2], [0, 0, 3, 4, 2, 1]),   # F# B D F#
    ('F#', 'minor'): ([-1, -1, 4, 2, 2, 2], [0, 0, 3, 1, 1, 1]),   # F# A C# F# (cejilla mini 3 cuerdas)
}
BEGINNER_TITLE = 'Beginner Grip'

# 7. Power chords: cuerda de la raíz (0 = 6ª) -> desplazamientos de traste de R, 5, R.
POWER_SHAPES = [
    (0, 'Root on 6th string', (0, 2, 2)),
    (1, 'Root on 5th string', (0, 2, 2)),
    (2, 'Root on 4th string', (0, 2, 3)),
    (3, 'Root on 3rd string', (0, 3, 3)),
]

def power_chord(root, string, offsets):
    base = (root - OPEN[string]) % 12
    frets = [-1] * 6
    fingers = [0] * 6
    for k, off in enumerate(offsets):
        frets[string + k] = base + off
    # Móvil: índice, anular y meñique. Al aire: la raíz suena sin pisar
    # (E5/A5/D5: dedos 1 y 2; G5, con la 5ª y la octava en el 3: anular y meñique).
    if base == 0:
        used = (0, 3, 4) if offsets == (0, 3, 3) else (0, 1, 2)
    else:
        used = (1, 3, 4)
    for k, finger in enumerate(used):
        fingers[string + k] = finger
    return frets, fingers

def main(path):
    data = json.load(open(path, encoding='utf-8'))
    changed = {'sus2': 0, 'F': 0, 'Edim': 0, 'TopSet': 0, 'inversiones': 0, 'principiante': 0}
    E_SHAPE_F = {  # forma E en cejilla al traste 1 (raíz F en la 6ª cuerda)
        'major':     ([1,3,3,2,1,1], [1,3,4,2,1,1]),
        'minor':     ([1,3,3,1,1,1], [1,3,4,1,1,1]),
        'dominant7': ([1,3,1,2,1,1], [1,3,1,2,1,1]),
        'minor7':    ([1,3,1,1,1,1], [1,3,1,1,1,1]),
    }
    for c in data:
        r = NOTES.index(c['root']); t = c['type']
        allowed = {(r + i) % 12 for i in c['intervals']}
        ok = not ({(OPEN[i] + f) % 12 for i, f in enumerate(c['fretPositions']) if f >= 0} - allowed)
        # 1-3. digitación principal (solo si hoy está mal)
        if not ok:
            if t == 'sus2':
                a = (r - 9) % 12
                c['fretPositions'] = [-1, a, a + 2, a + 2, a, a]
                c['fingerPositions'] = [0, 0, 1, 2, 0, 0] if a == 0 else [0, 1, 3, 4, 1, 1]
                c['baseFret'] = max(1, a); changed['sus2'] += 1
            elif c['root'] == 'F' and t in E_SHAPE_F:
                c['fretPositions'], c['fingerPositions'] = map(list, E_SHAPE_F[t]); c['baseFret'] = 1; changed['F'] += 1
            elif t == 'diminished' and c['root'] == 'E':
                c['fretPositions'], c['fingerPositions'], c['baseFret'] = [0,1,2,0,-1,-1], [0,1,2,0,0,0], 1; changed['Edim'] += 1
        # 4. Top-Set Tension
        for p in c.get('voicings', []):
            if p['title'] == 'Top-Set Tension' and t == 'dominant7':
                a = p['fretPositions'][3]
                p['fretPositions'] = [-1, -1, -1, a, a, a + 1]
                p['fingerPositions'] = [0, 0, 0, 1, 1, 2]
                changed['TopSet'] += 1
        # 5. inversiones de 7ª
        for p in c.get('advancedInversions', []):
            inv = next(k for k in INV_IDX if p['title'].lower().startswith(k))
            frets, fingers = generate_inversion(r, c['intervals'], inv)
            new = (frets, fingers, min(f for f in frets if f > 0))
            if (p['fretPositions'], p['fingerPositions'], p['baseFret']) != new: changed['inversiones'] += 1
            p['fretPositions'], p['fingerPositions'], p['baseFret'] = new
        # 7. power chords
        if t == 'power5':
            shapes = []
            for string, title, offsets in POWER_SHAPES:
                frets, fingers = power_chord(r, string, offsets)
                got = {(OPEN[i] + f) % 12 for i, f in enumerate(frets) if f >= 0}
                if got != {r, (r + 7) % 12}:
                    raise RuntimeError(f"power chord inválido: {c['name']} {frets}")
                shapes.append({'title': title, 'shape': 'Power chord',
                               'description': 'Root, fifth and octave (R-5-R).',
                               'fretPositions': frets, 'fingerPositions': fingers,
                               'baseFret': 1 if 0 in frets else min(f for f in frets if f > 0)})
            # Principal: la abierta (E5, A5, D5) si existe; si no, la más baja con raíz
            # en la 6ª o la 5ª cuerda.
            opened = [v for v in shapes[:3] if 0 in v['fretPositions']]
            low = opened[0] if opened else min(
                shapes[:2], key=lambda v: min(f for f in v['fretPositions'] if f >= 0))
            new_main = (low['fretPositions'], low['fingerPositions'], low['baseFret'])
            if (c['fretPositions'], c['fingerPositions'], c['baseFret']) != new_main or c.get('voicings') != shapes:
                changed['power'] = changed.get('power', 0) + 1
            c['fretPositions'], c['fingerPositions'], c['baseFret'] = list(new_main[0]), list(new_main[1]), new_main[2]
            c['voicings'] = shapes
        # 6. forma de principiante
        grip = BEGINNER_GRIPS.get((c['root'], t))
        if grip:
            frets, fingers = grip
            got = {(OPEN[i] + f) % 12 for i, f in enumerate(frets) if f >= 0}
            if not got <= allowed or {r} - got:
                raise RuntimeError(f"forma de principiante inválida: {c['name']}")
            entry = {'title': BEGINNER_TITLE, 'shape': 'Top set',
                     'description': 'Four-string beginner shape without a full barre.',
                     'fretPositions': list(frets), 'fingerPositions': list(fingers),
                     'baseFret': min(f for f in frets if f > 0)}
            voicings = c.setdefault('voicings', [])
            current = [v for v in voicings if v['title'] == BEGINNER_TITLE]
            if current != [entry]:
                voicings[:] = [v for v in voicings if v['title'] != BEGINNER_TITLE] + [entry]
                changed['principiante'] += 1
    Path(path).write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding='utf-8')
    print("entradas modificadas:", changed)

if __name__ == '__main__':
    default = Path(__file__).resolve().parent.parent / 'assets' / 'data' / 'chords.json'
    main(sys.argv[1] if len(sys.argv) > 1 else default)
