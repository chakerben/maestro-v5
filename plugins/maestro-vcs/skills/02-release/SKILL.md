---
name: 02-release
description: Cut a release — semver bump from conventional commits since the last tag, changelog section, annotated tag. Use to tag and document a release. Not for deploying (CI does that) or committing features.
argument-hint: "[major | minor | patch]"
disable-model-invocation: true
allowed-tools: Bash   # turn-scoped: the !`…` injections above use shell builtins, pipes and $(…) that pattern grants do not cover
---

# Skill: release

## Live state (computed at invocation)

Last tag and commits since:
!`T=$(git describe --tags --abbrev=0 --match 'v[0-9]*' 2>/dev/null); if [ -n "$T" ]; then echo "last tag: $T"; git log --no-merges --format='%h %s' "$T..HEAD"; else echo "no tag yet"; git log --no-merges --format='%h %s' | head -50; fi`

Version file(s) of the stack:
!`for f in package.json pubspec.yaml app.json app.config.js app.config.ts Cargo.toml pyproject.toml; do [ -f "$f" ] && echo "$f: $(grep -m1 -E '"?version"?[[:space:]]*[:=]' "$f" | tr -d ' ' | head -c 60)"; done; true`

Top of CHANGELOG.md:
!`head -5 CHANGELOG.md 2>/dev/null || echo "(no CHANGELOG.md)"`

## Process

1. Collect commits since the last tag. No tag → propose v0.1.0.
2. Derive the bump from conventional types (feat → minor, fix → patch,
   BREAKING CHANGE / ! → major) unless the argument overrides. Show the
   reasoning.
3. Bump the app version file for the stack (listed in "Live state"):
   `package.json` (`npm version <x.y.z> --no-git-tag-version`), `pubspec.yaml`
   `version:` (keep the `+build` suffix, bump it too), `app.json` /
   `app.config.*` `version` (Expo), `Cargo.toml` `version`, `pyproject.toml`
   `version`… Say which file(s) you bumped; if none exists, say so.
4. Write the changelog section: grouped Added / Fixed / Changed, one line
   per user-visible change, no internal noise. Prepend to CHANGELOG.md.
5. Gate: run `maestro-vcs:00-commit` gate action on the version + changelog
   changes, commit `chore(release): v<x.y.z>`, create the annotated tag.
6. Confirm before pushing the tag (a pushed tag is public history).

## Test

- The tag matches the CHANGELOG top section version AND the version file(s)
  of the stack (the run names which file it bumped).
- Non-semver tags (`deploy-2024`, `nightly`) were ignored when picking the
  last tag.
- The bump decision names the commits that justified it.
