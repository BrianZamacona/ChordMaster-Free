# UI/UX Audit Matrix (Scales + Chords + Navigation)

| Area | Issue | Severity | Standardization Action |
|---|---|---:|---|
| Scales cards | Dense expanded content causes cognitive overload | High | Collapse sections by default and progressively disclose fingerings/modes |
| Scales patterns | Inconsistent pattern quality | Critical | Hide non-validated patterns and render only SoT-approved data |
| Chords filters | Multiple horizontal rows increase decision fatigue | High | Consolidate filters into reusable grouped filter pattern |
| Navigation drawer | Mixed information hierarchy across sections | Medium | Keep intent-based grouping (Practice / Create & Track) with consistent tile style |
| Accessibility | Risk of text wrapping/overlap on small devices | High | Apply stricter spacing tokens and responsive text behavior |
| Accessibility | Controls may be too dense for touch | Medium | Preserve larger hit areas and avoid stacking actionable chips tightly |
| Localization readiness | Hardcoded strings in key navigation areas | High | Move shared labels to localization keys (EN/ES baseline first) |

## Pilot Scope Applied in This Iteration

- Scales module: guarded rendering for validated patterns.
- Navigation shell: localized labels and language selector in drawer.
- Foundation: localization infrastructure with fallback policy.
