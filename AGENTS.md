# Agent Instructions

## Monorepo Sync Duties (ALWAYS)

- Treat a user prompt as relevant when it requires changes inside `vedarogue/`; perform the requested work here in that case.
- If a prompt is unrelated to `vedarogue/`, append it verbatim to `UNRELEVANT_NON_EXECUTED_AGENTS_PROMPTS.md` (create the file if needed) and do not execute it.
- Before running any commands, synchronize this subtree with `git subtree pull --prefix=vedarogue vedarogue from-monorepo-$(git rev-parse --abbrev-ref HEAD)`.
- After completing relevant work, push the subtree upstream with `git subtree push --prefix=vedarogue vedarogue from-monorepo-$(git rev-parse --abbrev-ref HEAD)`.
