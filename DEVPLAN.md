# Development Plan - vedarogue

## Current Objective
Transform Vedabase-derived materials into interactive Emacs Lisp roguelike experiences with translation-friendly publishing outputs.

## Next Step
- Architect the roguelike content pipeline that turns Vedabase datasets, GitHub reposets, promptsets, and chatsets into rooms, items, characters, and concept screens (capture glue code expectations for Emacs Lisp generators).

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
