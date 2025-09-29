# Development Plan - vedarogue

## Current Objective
Transform Vedabase-derived materials into interactive Emacs Lisp roguelike experiences with translation-friendly publishing outputs.

## Next Step
- Expand `scripts/build_blueprint.py` to consume dataset lists-of-lists exports, produce multi-room/item layouts, and surface interim connectivity decisions.
- Add YAML schema tests (see `tests/test_blueprint_schema.py`) covering room graph shape, item/NPC placement, and concept screens.
- Document how audio hooks will reference dataset manifests inside the generated blueprint.

## Upcoming Milestones
1. **Blueprint Data Integration**
   - Align JSON contract with the dataset repo and support embedding-driven selection of rooms/items/NPCs.
   - Capture alternative room graph topologies (linear, hub, embedding) with rationale.
2. **Gameplay & Audio Hooks**
   - Flesh out audio trigger mapping, including asset naming and fallback behaviour when audio is missing.
   - Provide Golden YAML fixtures and regression tests to guard blueprint structure.
3. **Publishing Pipeline**
   - Prototype underword translation-aware LaTeX layouts and document publishing steps.
   - Coordinate managed worker automation for notebook pipelines and Emacs packaging.

## Backlog
- Capture a validation plan for the docker image toolchain after the roguelike data flow is defined.
- Document how managed workers should interact with notebook pipelines.
- Prototype “underword” translation-aware LaTeX layouts for multilingual texts.
- Align roguelike YAML generation with Emacs Lisp runtime requirements once the transformer spec is drafted.
- Wire in audio hooks referenced by the dataset plan so rooms can trigger playback.
- Create fixture data and Golden YAML snapshots to guard against regressions.
- Formalize release checklist for Emacs Lisp package builds and dataset dependency updates.

## Notes
- Capture outcomes after each managed worker run and update this plan accordingly.
- codex-cli unavailable on current host; managed worker execution deferred.
- Docker docs and Makefile contain no hard-coded branch references.
- Operator requested new Emacs Lisp roguelike transformer fed by Vedabase plus conversational corpora.
- Data mapping blueprint captured in `docs/roguelike_data_mapping.md`.
- Minimal blueprint generator now lives at `scripts/build_blueprint.py`; iterate on it rather than creating a parallel script.
