---
name: 00-qa-security
description: Defensive security findings of a project the Injaz QA security agent scans — what each pinned scanner checks, the Expo bundle and MobSF, passive header / TLS / ZAP checks, scope and licences, triaging a finding by hand. Use when reading, reproducing or deciding a security finding or ticket in Claude Code. Not for writing E2E tests (maestro-test-e2e), never for offensive testing.
argument-hint: "scanners | bundle | passive | scope | triage"
---

# Skill: QA security (the Injaz QA security agent)

> **Maestro 5** = this plugin marketplace, the only orchestrator. **Maestro mobile.dev** = the mobile E2E tool
> (`maestro test`). Two different things that share a name.

Agent B of the QA Mac Studio runs **defensive** scanners only, on repositories and declared environments, and files
findings in Injaz (المشاريع التقنية › التذاكر, «وكيل الجودة — الأمن»). This skill is the human side: understand a
finding, reproduce it, decide it.

| Lane | Tool (pinned) | Where |
|---|---|---|
| `secrets` | gitleaks 8.30.1 | repository, history included |
| `deps` | OSV-Scanner 2.7.0 + Trivy 0.76.1 | lockfiles |
| `sast` | Semgrep 1.183.0, or Opengrep for code ContentCo does not own | repository |
| `bundle` | `expo export` → rnsec 1.4.0 + react-native-lupin 1.3.0 | the shipped JS |
| `mobile_static` | MobSF (separate container, pinned by digest) | the Android release build |
| `headers` | one GET per declared URL | staging, preview, production |
| `dast_passive` | OWASP ZAP passive (container, pinned by digest) | `local` environment only |

## Actions

| #  | Action                | Role                                                          | Input        |
|----|-----------------------|---------------------------------------------------------------|--------------|
| 01 | `defensive-scanners`  | What secrets / deps / sast check, fingerprints, severities    | finding      |
| 02 | `expo-bundle`         | The shipped bundle (rnsec, lupin) and MobSF on the release APK | finding      |
| 03 | `passive-checks`      | Headers, TLS, ZAP passive; why a protected env is not a bug   | finding / URL|
| 04 | `scope-and-licences`  | What may be scanned, what never; the licences behind the tools | question     |
| 05 | `finding-triage`      | Reproduce and decide one finding: fix, or cancel with a reason | ticket       |

Each action lives in `${CLAUDE_PLUGIN_ROOT}/skills/00-qa-security/actions/NN-name.md`; read only the one needed.
Command: `/maestro-security:qa-security-triage <ticket>` runs action 05.

## Transversal rules

- **Defensive only.** No exploit, no active scan, no fuzzing, no brute force, no third-party asset — even read-only.
  `allowActiveScan` stays false and no step reads it. A model's refusal stops the run (`blocked_by_policy`): a human
  decides, nothing is retried with another model.
- **A secret is never repeated.** Not in a chat, a ticket, a commit message or a command line; findings carry the rule,
  the file and a masked line only. A real leaked credential is **rotated** first — deleting the line is not a fix.
- **Facts are not triaged by a model**: a dependency inside a vulnerable range, a missing header, a named credential.
  Only code findings and generic secret matches go to the open-weights triage.
- **Fingerprints are stable** (`dep:<id>:<package>`, `secret:<rule>:<path>`, `sast:<rule>:<path>`, `header:<check>:<host>`):
  two runs never open two tickets; a cancelled ticket mutes its fingerprint.
- Reports stay internal (Semgrep rules licence, A40).

## Test

- A triage with action 05 ends with the ticket «مكتمل» after a fix, or «ملغي» with a one-line reason — never closed silently.
- No output of this skill contains a secret value, a key or a password.
- Nothing this skill does sends a request to a host outside the project's declared environments.
