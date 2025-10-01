# LFS Budget and Large Files Guidance

When adding assets, proactively avoid exceeding Git LFS budgets and GitHub file size limits.

- Run `make lfs-audit` (or `bash scripts/check_lfs_budget.sh`) to produce a report under `build/lfs_report/` and fail on problematic sizes.
- Prefer external storage or release artifacts over committing large binaries or media.
- If needed, use Git LFS sparingly and only for appropriate types; review `.gitattributes`.
- To remediate history bloat, consider BFG Repo-Cleaner or `git filter-repo` to purge large blobs.
- CI runs an LFS audit on every push and uploads logs as the `lfs-audit-logs` artifact.

