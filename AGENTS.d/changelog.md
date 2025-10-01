# Changelog Maintenance Guidelines

Always ensure that listable objects (structured lists that benefit from snapshots) are included in the changelog for visibility and traceability.

## Listable Objects Policy

- Pseudocode screenshots (80×80): when TUIs are added/changed or when a session introduces notable TUIs, include monospaced 80×80 pseudographic diagrams in `CHANGELOG.md`.
  - Use `scripts/generate_changelog.sh` which collects changed TUIs and also reads `docs/session_tui_list.txt` for session-specific TUIs.
  - Update `docs/session_tui_list.txt` whenever a session introduces or highlights new TUIs.
- Deployments catalog: ensure `README.deployments.md` is generated in CI and linked from Releases.
- Docker test logs: make sure `docker-test-logs` artifacts are uploaded in CI; releases attach them.

## Process Before Commit/Push (especially when user says "c")

1) Refresh changelog and release notes:
   - `bash scripts/generate_changelog.sh`
2) If TUIs were introduced without GIF/docs, update `docs/session_tui_list.txt` so the 80×80 diagrams are included.
3) Optionally refresh docker logs:
   - `bash scripts/run_docker_tests.sh`
4) Auto-commit & push with:
   - `bash scripts/auto_commit.sh "<subject>"`

CI will handle crates.io publishing, GHCR image pushes, and GitHub Release creation on tags.

