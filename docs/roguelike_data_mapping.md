# Roguelike Data Mapping Blueprint

## Inputs
- **Vedabase export** (`../dataset/DUMPS/vedabase/json/*.json`): canonical verse text with translations, synonyms, purports.
- **GitHub reposets** (`reposets/*.json` TBD): curated code/artifact snapshots referenced in prompt narratives.
- **Promptset transcripts** (`promptsets/*.jsonl`): recorded interactions that seed quest/dialog content.
- **Chatset logs** (`chatsets/*.jsonl`): conversational data for NPC speech patterns and hint systems.

## Goals
Transform the combined inputs into Emacs Lisp data structures that power a roguelike rendered inside Emacs buffers. Deliverables include:
- Rooms with context-sensitive descriptions.
- Items (sacred texts, audio relics) tied back to Vedabase verses.
- Characters/NPCs with dialogue trees derived from chat/prompt corpora.
- Concept screens (lore, relationship charts) built from reposet metadata.

## Data Flow Overview

```
dataset exports ─┐
reposets ────────┼─> ETL (Python) ──> canonical YAML ──> Emacs Lisp loader
promptsets ──────┤
chatsets ────────┘
```

1. **ETL Layer (Python)**
   - Implement `scripts/build_blueprint.py` that reads all inputs and produces `build/roguelike_blueprint.yaml`.
   - Key sections:
     - `rooms`: graph definition (id, title, vedabase_ref, neighbors).
     - `items`: id, type, source (`vedabase`, `reposet`), lore text, stat bonuses.
     - `characters`: id, archetype, dialogue nodes with references to chatset conversations.
     - `concept_screens`: Markdown or Org fragments for overlays.
   - Maintain a `manifest` subtree linking every YAML entry back to originating file and checksum (supports future diffs).

2. **Emacs Lisp Loader**
   - Add `rl_dspy/roguelike-loader.el` (new) that:
     - Reads YAML via `yaml.el` (already dependency) or pre-converted elisp file.
     - Creates in-memory structures: `(defstruct room id title neighbors lore)` etc.
     - Exposes API for rendering (`roguelike-render-room`, `roguelike-list-inventory`).

3. **Runtime Integration**
   - Hook loader into existing Emacs MCP pipeline so Codex/Gemini can request `roguelike` views via ACP.
   - Provide `make roguelike-preview` target to regenerate YAML and open Emacs buffer for inspection.

## Mapping Rules

| Source | Target | Notes |
|--------|--------|-------|
| Vedabase verse | Room lore / item description | Use `sanskrit` + `translation`; include purport snippets as hidden lore. |
| Reposet metadata | Concept screens | Summarize repo purpose, link to associated prompts. |
| Promptset commands | Quest objectives | Parse imperative sentences to create tasks (collect item, speak to NPC). |
| Chatset dialogue | NPC dialogue trees | Use speaker tags to build branching responses; maintain sentiment for NPC disposition. |

Special handling:
- **Underword translation**: store transliteration + translation pairs so Emacs can render stacked text (ties to `dataset` PDF work).
- **Audio hooks**: reference audio fragment IDs from dataset plan, enabling playback triggers inside Emacs or via iOS app.

## Validation Checklist
- YAML schema validated by `vedarogue/tests/test_blueprint_schema.py` (to be written).
- Ensure every room has at least one exit; isolated nodes flagged during build.
- Confirm all referenced Vedabase IDs exist in dataset manifest.
- Run Emacs batch smoke test: `emacs --batch -l rl_dspy/roguelike-loader.el -f roguelike-self-test`.

## Next Implementation Tasks
1. Write the ETL script skeleton with CLI options for selecting subsets of books/prompts.
2. Decide on world graph generation strategy (manual seeding vs algorithmic using embeddings).
3. Prototype Emacs buffer renderer showing one room, inventory sidebar, and NPC dialogue window.
