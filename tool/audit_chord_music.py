#!/usr/bin/env python3
"""Audita assets/data/chords.json: ¿cada digitación suena al acorde que dice ser?

Uso:  python3 tool/audit_chord_music.py [ruta/chords.json]
Sale con código 1 si hay defectos en campos que deben estar limpios
(cagedPositions, triadInversions). Los demás campos se reportan como deuda.
"""
import json, sys
from collections import Counter

NOTES = ['C','C#','D','D#','E','F','F#','G','G#','A','A#','B']
FLAT = {'Db':'C#','Eb':'D#','Gb':'F#','Ab':'G#','Bb':'A#'}
OPEN = [4, 9, 2, 7, 11, 4]            # E A D G B e (6a -> 1a), afinación estándar
FIELDS = ['fretPositions', 'cagedPositions', 'voicings', 'triadInversions', 'advancedInversions']
MUST_BE_CLEAN = {'cagedPositions', 'triadInversions'}

def pitch_classes(frets):
    return {(OPEN[i] + f) % 12 for i, f in enumerate(frets) if f >= 0}

def main(path):
    data = json.load(open(path, encoding='utf-8'))
    bad, total, examples = Counter(), Counter(), {}
    for c in data:
        root = NOTES.index(FLAT.get(c['root'], c['root']))
        allowed = {(root + i) % 12 for i in c['intervals']}
        entries = [('fretPositions', c['name'], c['fretPositions'])]
        for f in FIELDS[1:]:
            entries += [(f, f"{c['name']} / {p.get('title')}", p['fretPositions']) for p in c.get(f, [])]
        for field, label, frets in entries:
            total[field] += 1
            if len(frets) != 6 or pitch_classes(frets) - allowed:
                bad[field] += 1
                examples.setdefault(field, (label, frets))
    print(f"{'campo':<20}{'evaluadas':>10}{'con notas ajenas':>18}")
    for f in FIELDS:
        print(f"{f:<20}{total[f]:>10}{bad[f]:>18}")
        if f in examples: print(f"{'':<20}ej: {examples[f]}")
    return 1 if any(bad[f] for f in MUST_BE_CLEAN) else 0

if __name__ == '__main__':
    sys.exit(main(sys.argv[1] if len(sys.argv) > 1 else '../assets/data/chords.json'))
