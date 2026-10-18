#!/usr/bin/env python3
"""Verifica los límites de Play en store/listing.md.

Uso:  python -I store/check_listing.py
Título ≤ 30, descripción breve ≤ 80, descripción completa ≤ 4000 caracteres.
Sale con código 1 si alguno se pasa.
"""
import re
import sys
from pathlib import Path

LIMITS = {'Título': 30, 'Title': 30, 'Descripción breve': 80, 'Short description': 80,
          'Descripción completa': 4000, 'Full description': 4000}

text = (Path(__file__).parent / 'listing.md').read_text(encoding='utf-8')
bad = 0
for m in re.finditer(r'^### ([^\n]+)\n(.*?)(?=\n### |\n---|\Z)', text, re.S | re.M):
    name, body = m[1].strip(), m[2].strip()
    if name not in LIMITS:
        continue
    n = len(body)
    ok = n <= LIMITS[name]
    bad += not ok
    print(f"{'ok ' if ok else 'MAL'} {name:<22} {n:>5} / {LIMITS[name]}")
sys.exit(1 if bad else 0)
