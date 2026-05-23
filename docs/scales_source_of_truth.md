# Scales Source of Truth (SoT)

This document defines the required contract before adding or rendering any guitar scale fingering pattern.

## 1) Baseline Convention

- Tuning: `EADGBE_STANDARD` (`E2 A2 D3 G3 B3 E4`)
- Strings supported: 6
- Note naming: sharps-only (`C#`, `D#`, etc.)
- Fretboard range: `0..22`

## 2) Supported Pattern Systems (Initial)

1. `caged`
2. `threeNps`
3. `block`
4. `pentatonicBox`

## 3) Mandatory Pattern Payload

Each pattern must provide:

- `id` (unique)
- `name`
- `system`
- `status` (`draft`, `validated`, `published`)
- `scaleType`
- `root`
- `tonic`
- `position` (`anchorFret`, `minFret`, `maxFret`)
- `notes[]` with:
  - `stringNumber` (1-6)
  - `fret` (0-22)
  - `interval` (recommended)
  - `noteName` (recommended)
  - `suggestedFinger` (optional)

Template file: `/assets/data/scale_patterns_template.json`

## 4) Automatic Validation Rules

Patterns are rejected when any of the following fails:

- A note does not belong to the target scale.
- Required structural intervals are missing by system.
- Fret span exceeds ergonomic threshold.
- String/fret mapping is inconsistent with standard tuning.
- 3NPS pattern does not contain exactly 3 notes per used string.

## 5) Review Workflow

- Status pipeline: `draft -> validated -> published`
- Suggested review cadence: 10 patterns per batch
- Approval checklist per pattern:
  - Note correctness
  - String/fret correctness
  - Position coherence
  - Pedagogical coherence

Only `validated`/`published` patterns should be exposed in production UI.
