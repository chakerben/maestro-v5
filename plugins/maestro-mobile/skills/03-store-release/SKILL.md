---
name: 03-store-release
description: Use when a mobile build is about to be submitted to the App Store or Google Play — "on soumet", "TestFlight", "review Apple", "publier sur le store", a release checklist request, or a store rejection to work through. Produces a go/no-go checklist with evidence, KSA-specific items included (Arabic screenshots, age rating, data disclosure, payment rules). Not for cutting the git release (maestro-vcs:02-release) nor for building features.
argument-hint: "[ios | android | both] [rejection text]"
allowed-tools: Bash   # turn-scoped: the !`…` injections above use shell builtins, pipes and $(…) that pattern grants do not cover
---

# Skill: store-release

A store submission is a one-way door with a 1–3 day review cost on the other
side. This skill makes the checklist explicit and evidence-backed so the
submission is right the first time.

## Live state (computed at invocation)

Version and identifiers (first source that answers wins):
!`if [ -f app.json ]; then node -e 'const a=require(process.cwd()+"/app.json");const e=a.expo||a;console.log("app.json | name:",e.name,"| version:",e.version,"| ios build:",(e.ios||{}).buildNumber,"| android versionCode:",(e.android||{}).versionCode,"| bundle:",(e.ios||{}).bundleIdentifier,"| package:",(e.android||{}).package)'; elif ls app.config.js app.config.ts >/dev/null 2>&1; then npx --no-install expo config --json --type public 2>/dev/null | node -e 'let d="";process.stdin.on("data",c=>d+=c).on("end",()=>{try{const e=JSON.parse(d);console.log("app.config | name:",e.name,"| version:",e.version,"| ios build:",(e.ios||{}).buildNumber,"| android versionCode:",(e.android||{}).versionCode)}catch{console.log("(app.config.* present but expo config failed: run npx expo config --json --type public)")}})'; elif [ -f pubspec.yaml ]; then echo "pubspec.yaml | $(grep -m1 '^version:' pubspec.yaml)"; elif [ -f android/app/build.gradle ]; then echo "build.gradle | $(grep -m1 versionCode android/app/build.gradle | tr -s ' ') $(grep -m1 versionName android/app/build.gradle | tr -s ' ')"; else echo "(no app.json / app.config.* / pubspec.yaml / build.gradle found)"; fi; [ -f eas.json ] && node -e 'const s=((require(process.cwd()+"/eas.json").cli||{}).appVersionSource);console.log("eas.json appVersionSource:",s||"(unset = local)",s==="remote"?"→ EAS manages buildNumber/versionCode; do not bump them locally":"")'; true`

Locales shipped:
!`{ ls messages locales src/locales i18n assets/locales 2>/dev/null; ls lib/l10n/*.arb 2>/dev/null; } | tr '\n' ' '; echo`

Last tag and uncommitted changes:
!`git describe --tags --abbrev=0 2>/dev/null || echo "(no tag)"; git status --short | wc -l | sed 's/$/ uncommitted file(s)/'`

Arguments: `$ARGUMENTS` (platform, then optional rejection text)

## Process

1. Copy `assets/checklist.md` into
   `maestro_docs/releases/<version>_<platform>.md` (create the folder). Every
   item gets one of: ✅ + evidence (file, screenshot name, command output),
   ❌ + what is missing, ➖ + why it does not apply. No item stays blank.
2. Work the checklist in order: **Build → Compliance → Store listing → KSA
   → Final**. Stop at the first ❌ in Build or Compliance; those are
   blocking by definition.
3. With a rejection text as argument: map each sentence of the rejection to
   the checklist item it violates, mark it ❌, and append `## Rejection` with
   the store's words and the planned answer.
4. Verdict at the top of the file: `GO` (zero ❌), `NO-GO (n blocking)`.
   Never `GO` with a ❌ anywhere, even in Store listing.
5. Hand off: `GO` → `maestro-vcs:02-release` for the tag; the store upload
   itself is a human act (EAS submit / Play Console) and this skill says so.

## Binding rules

- Screenshots for an `ar` locale are taken IN Arabic, RTL, with real
  content — not the English screens mirrored.
- Every permission in the manifest has a one-line justification in the
  checklist, and the same sentence appears in the store's purpose string.
- Age rating and data-safety answers are read from the code (analytics SDKs,
  auth, payments, UGC), not from memory.
- A build submitted from an uncommitted tree is a `NO-GO`.

## Test

- `maestro_docs/releases/<version>_<platform>.md` exists, every item is
  ✅/❌/➖ with a note, and the verdict line matches the count of ❌.
- The skill changed no file outside `maestro_docs/releases/`.
