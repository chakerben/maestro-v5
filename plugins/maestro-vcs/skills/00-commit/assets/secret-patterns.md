# Secret patterns (scan on ADDED diff lines)

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
| `postgres(ql)?://[^\s:]+:[^\s@]+@` | DB URL with password |
| `mongodb(\+srv)?://[^\s:]+:[^\s@]+@` | MongoDB URL with password |
| `whsec_[A-Za-z0-9]{20,}` | Stripe webhook secret |
| `(?i)(api[_-]?key\|secret\|password\|token)\s*[:=]\s*['"][A-Za-z0-9+/_-]{16,}['"]` | Generic hardcoded credential |

False-positive escape: a line ending in `// gate:allow <reason>` is skipped
and the allowance is echoed in the gate report.
