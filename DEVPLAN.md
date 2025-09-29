# Development Plan - vedarogue

## Current Objective
Transform Vedabase-derived materials into interactive Emacs Lisp roguelike experiences with translation-friendly publishing outputs.

## Next Step
- Expand `scripts/build_blueprint.py` to support multiple rooms/items via embeddings or manual lists, and add unit tests to validate the YAML schema.

## Backlog
- Capture a validation plan for the docker image toolchain after the roguelike data flow is defined.
- Document how managed workers should interact with notebook pipelines.
- Prototype “underword” translation-aware LaTeX layouts for multilingual texts.
- Align roguelike YAML generation with Emacs Lisp runtime requirements once the transformer spec is drafted.

## Notes
- Capture outcomes after each managed worker run and update this plan accordingly.
- codex-cli unavailable on current host; managed worker execution deferred.
- Docker docs and Makefile contain no hard-coded branch references.
- Operator requested new Emacs Lisp roguelike transformer fed by Vedabase plus conversational corpora.
- Data mapping blueprint captured in `docs/roguelike_data_mapping.md`.
- Minimal blueprint generator now lives at `scripts/build_blueprint.py`; iterate on it rather than creating a parallel script.
