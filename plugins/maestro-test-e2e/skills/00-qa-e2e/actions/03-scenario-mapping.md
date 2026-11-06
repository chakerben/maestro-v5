# 03 - Scenario mapping

`qa/map/<CODE>.scenarios.json` ties every scenario of the Injaz library to what verifies it. Versioned in the tested
repository, proposed by a model, **validated by a human** (D9). The worker reads it; Injaz computes coverage from it.

## Format

```json
{ "project": "REMS", "version": 1,
  "web": { "allowedHosts": ["fonts.googleapis.com"] },
  "entries": [
    { "ref": "AUTH-001", "status": "automated", "kind": "web", "spec": "e2e/auth.spec.ts", "tags": ["smoke"] },
    { "ref": "AUTH-002", "status": "automated", "kind": "mobile", "flow": ".maestro/01-login.yaml", "env": "staging" },
    { "ref": "PAY-014", "status": "manual", "reason": "دفع حقيقي عبر مزود", "owner": "human" },
    { "ref": "LIB-007", "status": "blocked", "reason": "لا يوجد testID على الشاشة", "owner": "agent" }
  ] }
```

| Field | Rule |
|---|---|
| `ref` | exists in the Injaz library of this project (never invent one; `AGT-…` / `REG-…` come from the agent) |
| `status` | `automated` (a spec or flow verifies it), `manual` (a human must), `blocked` (automatable, not yet) |
| `reason` | mandatory for `manual` and `blocked`, Arabic, one line |
| `kind` | `web`, `mobile`, `safari` — which lane takes the entry |
| `spec` / `flow` | the file path, relative to the repository root; the Playwright title also carries `[REF]` |
| `owner` | `agent` or `human` — who closes the gap |
| `web.allowedHosts` | extra hosts the test browser may load (fonts, CDNs); payment providers are refused anyway |

## Process

1. Read the library: `injaz-test-scenarios.json` at the repository root (written by `/injaz-test-scenarios`) or the
   project's export in Injaz.
2. Read the tests: Playwright titles (`[REF]`), `.maestro/` and `qa/safari/` top-level flows.
3. Propose one entry per ref; keep every existing entry a human set (`manual`, `reason`, `owner`) unless the file it
   names is gone.
4. Show the human the diff grouped by status; write only what they accept.

## Test

- The file parses, `project` equals the Injaz code, every `ref` is unique and exists in the library.
- Every `automated` entry names a file that exists; every `manual` / `blocked` entry has a `reason`.
- Running it twice without a library or test change leaves the file byte-identical.
