# v4 → v5 migration scripts — ARCHIVED

Mission accomplished in July 2026: the 32 projects under `~/Documents/Projects`
were migrated to Maestro 5 (0 v4 leftovers, see `docs/archive/RUNBOOK-v5.4.0.md`).

These scripts are kept for the record only. **Do not re-run them on a migrated
project.** Known, unfixed defects: `docs/AUDIT-5.3.1.md` P1-3, P1-4, P1-7,
P1-8, P1-9, P1-10, P1-12 → P1-16 (re-confirmed in `docs/AUDIT-5.5.0.md` §D).
If a v4 project ever resurfaces, fix those first — or migrate it by hand, it
is a one-hour job for one project.

`update-projects.sh`, `release.sh` and `install-shortcuts.sh` (which now also
installs `gwt` for `maestro-vcs:03-worktree`) are the live tools in `scripts/`.
