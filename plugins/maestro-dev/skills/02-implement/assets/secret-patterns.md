<!-- Mirror of maestro-vcs/skills/00-commit/assets/secret-patterns.md — keep in sync (validate.js enforces it). -->

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
| `gh[opsru]_[A-Za-z0-9]{36,}` | GitHub token (PAT / OAuth / app / refresh) |
| `github_pat_[A-Za-z0-9_]{20,}` | GitHub PAT (fine-grained) |
| `glpat-[A-Za-z0-9_-]{20,}` | GitLab PAT |
| `npm_[A-Za-z0-9]{36}` | npm token |
| `SG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}` | SendGrid key |
| `sbp_[a-f0-9]{40}` | Supabase token |
| `SK[a-f0-9]{32}` | Twilio key |
| `https://[a-f0-9]{32}@[a-z0-9.]+/[0-9]+` | Sentry DSN |
| `xox[bpars]-[A-Za-z0-9-]{10,}` | Slack token |
| `AKIA[0-9A-Z]{16}` | AWS access key |
| `-----BEGIN (RSA\|EC\|OPENSSH\|DSA\|PGP) PRIVATE KEY` | Private key |
| `AIza[0-9A-Za-z_-]{35}` | Google API key |
| `eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}` | JWT |
| `sk-[A-Za-z0-9]{20,}T3BlbkFJ[A-Za-z0-9]{20,}` | OpenAI key |
| `sk-ant-[A-Za-z0-9-]{20,}` | Anthropic key |
| `postgres(ql)?://[^[:space:]:]+:[^[:space:]@]+@` | DB URL with password |
| `mongodb(\+srv)?://[^[:space:]:]+:[^[:space:]@]+@` | MongoDB URL with password |
| `whsec_[A-Za-z0-9]{20,}` | Stripe webhook secret |
| `(api[_-]?key\|secret\|password\|passwd\|token)[A-Za-z0-9_]*[[:space:]]*[:=][[:space:]]*['"]?[A-Za-z0-9+/=_.-]{16,}` | Generic hardcoded credential |

The generic pattern is case-insensitive (`-i`) and accepts unquoted values
(`DB_PASSWORD=…` in a `.env`). Placeholder values are not hits: the script drops a match whose text contains
`example`, `changeme`, `placeholder`, `xxx…`, `your_`/`your-`, `<…>` or `${`
(so `API_KEY=changeme_placeholder_value` is clean, `DB_PASSWORD=hunter2hunter2hunter2` is RED).

False-positive escape: a line ending in a `gate:allow <reason>` comment
(`// gate:allow r`, `# gate:allow r`, `-- gate:allow r`, `/* gate:allow r */`,
`<!-- gate:allow r -->`) is skipped, the allowance is echoed in the gate report
AND written into the commit body (`Gate-Allow: <file>:<line> — <reason>`), so a
human sees it in `git log`.
