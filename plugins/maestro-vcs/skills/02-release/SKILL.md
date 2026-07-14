---
name: 02-release
description: Cut a release — semver bump from conventional commits since the last tag, changelog section, annotated tag. Use to tag and document a release. Not for deploying (CI does that) or committing features.
argument-hint: "[major | minor | patch]"
disable-model-invocation: true
---

# Skill: release

## Process

1. Collect commits since the last tag. No tag → propose v0.1.0.
2. Derive the bump from conventional types (feat → minor, fix → patch,
   BREAKING CHANGE / ! → major) unless the argument overrides. Show the
   reasoning.
3. Write the changelog section: grouped Added / Fixed / Changed, one line
   per user-visible change, no internal noise. Prepend to CHANGELOG.md.
4. Gate: run `maestro-vcs:00-commit` gate action on the changelog change,
   commit `chore(release): v<x.y.z>`, create the annotated tag.
5. Confirm before pushing the tag (a pushed tag is public history).

## Test

- The tag matches the CHANGELOG top section version.
- The bump decision names the commits that justified it.
