# 02 - Expo bundle and MobSF

Mobile apps are checked on what ships, not only on the source.

## The bundle lane

- `expo export` builds the JavaScript bundle the store would ship; `rnsec` 1.4.0 and `react-native-lupin` 1.3.0 scan it
  (installed in `~/.local/share/injaz-qa/tools` on the QA machine, versions pinned).
- What it finds: secrets and API keys compiled into the bundle, `http://` endpoints, debug flags, insecure storage of
  tokens (AsyncStorage instead of SecureStore), WebView settings, deep-link handling.
- rnsec's own dependency check is dropped: the `deps` lane owns vulnerable packages (one fingerprint, one ticket).
- A match in a non-app path (design files, scripts) counts low.

## MobSF (`mobile_static`)

- Runs as a separate container (GPL-3.0, no code linking), image pinned by digest, started on demand.
- Scans the **release** Android build. Findings about the signing certificate of that QA build (debug keystore, SHA1)
  count **low**: the store build is signed differently. Secret strings MobSF prints are dropped from the finding text.
- Manifest findings (cleartext traffic, exported components, storage permissions) keep MobSF's severity.

## Process

1. A secret in the bundle is a secret shipped to every phone: treat it as public — rotate, then move it server-side
   (an `EXPO_PUBLIC_*` variable is public by construction).
2. Cleartext / `http://`: point the app at https; an exception needs a written reason in the ticket.
3. Insecure storage: tokens in `expo-secure-store`, never AsyncStorage.
4. Rebuild and re-export locally to confirm the match is gone; the agent's re-test checks it again on «اختبار».

## Test

- After the fix, `expo export` produces a bundle where the matched string no longer appears.
- No `EXPO_PUBLIC_*` variable carries a secret.
