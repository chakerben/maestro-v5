# 02 - Maestro mobile.dev flows

Maestro mobile.dev (the E2E tool, `maestro test`) — not Maestro 5 the plugin marketplace. Write or fix a YAML flow the
QA agent runs on the iOS simulator and the Android emulator (`e2e_mobile`), or a Safari-on-iOS flow (`safari_device`).

## What the lanes do

- `e2e_mobile`: Maestro mobile.dev 2.12.1; the TOP-LEVEL flows of `.maestro/` (flows in sub-folders are sub-flows,
  never run alone); the app built once per commit (cached by sha) and installed fresh on every run; iOS simulator
  `qa_iphone` + Android emulator `qa_api34` with `--shard-split 2`; JUnit output; status bar frozen (demo mode, 9:41).
- `safari_device` (D11, weekly): the flows of `qa/safari/` on the REAL mobile Safari of a simulator erased before every
  run — the only proof of a path on iPhone Safari. Never production.
- The map (`qa/map/<CODE>.scenarios.json`) ties a flow to its ref: `{ "ref": "AUTH-001", "status": "automated",
  "kind": "mobile", "flow": ".maestro/01-login.yaml", "tags": ["smoke"] }` (`kind: "safari"` for `qa/safari/`).

## Process

1. Every element a flow touches has a stable `testID` (React Native) / accessibility id — add it in the app first;
   tapping a visible Arabic text is a fallback, not the plan.
2. `appId` = the target's bundle id / Android package; environment values through `env:` and `-e`, never a secret in
   the YAML (accounts by variable name, filled by the worker from its own store).
3. Known traps: `hideKeyboard` is unreliable on iOS 26 (tap a neutral area instead); secure-field autofill on the
   simulator; `androidWebViewHierarchy: devtools` for WebViews; Arabic typing is proven by the Unicode canary — type
   the real text.
4. A flow that reaches a paid third party (payment, SMS) is `manual` in the map, with mocks — never automated (A37).
5. Run it: `maestro test --device <udid> .maestro/01-login.yaml`, then add the map entry (action 03).

## Test

- `maestro test` passes on both platforms; the flow has no `sleep`-style fixed waits where an `extendedWaitUntil` fits.
- Every `tapOn` / `assertVisible` targets an id or an exact text; no coordinates.
- The flow file has a map entry with the same path, and no secret value in the YAML.
