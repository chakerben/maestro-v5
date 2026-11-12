---
name: 06-eas-build-and-ota
description: Use when building a store or tester binary or publishing an over-the-air update — "eas build", "eas update", "OTA", or a tester saying an update did not arrive. Not for the store submission checklist (03-store-release).
---

# Skill: eas-build-and-ota

A binary is permanent and an update is an unreviewed release to every
user. Every rule names the incident class it prevents.

## Before the first store build

- Set the update URL and the runtime-version policy before the first store
  build — because builds shipped without them can never receive an update.
- Tie the runtime version to the app version — because an update landed on
  a runtime it was not built for and crashed at launch.
- Record the environment of each build profile: **tester builds point at
  the acceptance environment by default; a tester build on the production
  API exists only by an explicit, recorded project decision** — because
  test data and unreleased client code reached production.
- The builder's ignore file replaces `.gitignore`: repeat the secret
  patterns in it — because env files were uploaded with the sources.
- Generate the lockfile with the builder's package-manager version —
  because the cloud install failed on the lockfile format.
- A root `postinstall` builds the workspace packages that tools import —
  because cloud workers and fresh worktrees run no manual step.

## Build

- Build from a clean clone of a committed sha, never from a live working
  tree — because the builder packs uncommitted and neighbour edits, and a
  failed upload burns a build number.
- Config plugins throw when their anchor is missing; read the generated
  plist / manifest from a local prebuild before a cloud build — because
  "the plugin ran" was assumed and the native change was absent.
- Verify a native change from the built artifact, not from the source —
  because precompiled modules ignored the patch.

## Update (OTA)

- Never ship a native change over the air: diff the native inputs
  (dependencies with native code, config plugins, app config) since the
  runtime's build before choosing OTA — because the update crashed on the
  installed runtime.
- Publish from a directory with a **real dependency install**, never a
  wholesale `node_modules` symlink — because the bundle embedded stale
  packages.
- Pass every public env variable explicitly at export time, then grep the
  exported bundle for the expected API host — because an update shipped
  pointing at the wrong backend.
- Check which runtime version is installed in the field, and that the
  target backend already serves what the update calls — because an update
  targeted a runtime nobody had, or reached users before the API.
- Publish to the production channel only on an explicit order in the
  current request — because an update is a release to every user.

## Tell the truth about delivery

- Read the update list (`eas update:list --branch <branch>`) before saying
  "published" or "not published" — because wrong status comments were
  posted in bulk from memory.
- Name the build number or the update id in every delivery note; on a
  reopened ticket, check whether the fix was published before coding —
  because testers retested the old build.

## Ship as guards, not as prose

- A CI check that the app config carries `updates.url` and a runtime policy.
- A publish wrapper that refuses a dirty tree, exports with an explicit env
  list and greps the bundle for the host.
- A unit test of each config plugin on a fixture with its anchor removed.

## Test

- Every build or update done under this skill leaves a delivery note with:
  commit sha, profile or channel, target environment, build number or
  update id, and the output line of the update list that proves it.
- No update was published from a tree with uncommitted changes or a
  symlinked `node_modules`, and none carried a native-input change.
- No production-channel publish happened without the order quoted from the
  current request; no tester profile points at production without the
  recorded decision.
