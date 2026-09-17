# Secret patterns (scan on ADDED diff lines)

**Executor**: these are POSIX ERE patterns, run with `grep -Ei` — never matched
"by reading". The reference command, from the repo root:

```bash
git diff --cached -U0 | grep '^+' | grep -v '^+++' | grep -Ei -e '<pattern1>' -e '<pattern2>' ...
```

(`-i` provides the case-insensitivity the generic pattern needs; the `\|` in
the table below is markdown escaping for `|` — use a plain `|` in the command.)

| Pattern (regex) | Name |
|---|---|
| `sk_(live\|test)_[A-Za-z0-9]{20,}` | Stripe key |
| `rk_(live\|test)_[A-Za-z0-9]{20,}` | Stripe restricted key |
| `ghp_[A-Za-z0-9]{36,}` | GitHub PAT (classic) |
| `github_pat_[A-Za-z0-9_]{20,}` | GitHub PAT (fine-grained) |
| `xox[bpars]-[A-Za-z0-9-]{10,}` | Slack token |
| `AKIA[0-9A-Z]{16}` | AWS access key |
| `-----BEGIN (RSA\|EC\|OPENSSH\|DSA\|PGP) PRIVATE KEY` | Private key |
| `AIza[0-9A-Za-z\-_]{35}` | Google API key |
| `eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}` | JWT |
| `sk-[A-Za-z0-9]{20,}T3BlbkFJ[A-Za-z0-9]{20,}` | OpenAI key |
| `sk-ant-[A-Za-z0-9-]{20,}` | Anthropic key |
| `postgres(ql)?://[^[:space:]:]+:[^[:space:]@]+@` | DB URL with password |
| `mongodb(\+srv)?://[^[:space:]:]+:[^[:space:]@]+@` | MongoDB URL with password |
| `whsec_[A-Za-z0-9]{20,}` | Stripe webhook secret |
| `(api[_-]?key\|secret\|password\|token)[[:space:]]*[:=][[:space:]]*['"][A-Za-z0-9+/_-]{16,}['"]` | Generic hardcoded credential (case-insensitive via `-i`) |

False-positive escape: a line ending in `// gate:allow <reason>` is skipped,
the allowance is echoed in the gate report AND written into the commit body
(`Gate-Allow: <file>:<line> — <reason>`), so a human sees it in `git log`.
