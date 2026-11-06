# 06 - Agent runbook

Where things are, for a human in Claude Code. The full runbook is `docs/qa-agents.md` in the Injaz repository; the
machine side is `docs/qa-agents.md` in `injaz-qa-worker`.

| Question | Answer |
|---|---|
| Turn a project on | Injaz › المشاريع التقنية › <project> › وكلاء الجودة: target (GitHub URL), environments declared in `docs/qa-agent-scope.md`, the project × agent line |
| Stop everything now | Injaz › الإعدادات › وكلاء الجودة › الإيقاف الطارئ (kill switch): queued runs cancelled, machines paused |
| Why no ticket | `observeOnly` (pilot: findings «مقترح»), a precision under 50 % (back to observation automatically), or the daily ticket cap |
| What it costs | the costs tab (`qa_agents.viewCosts`): spend per project and agent, monthly budget alert at 80 % |
| The machines | الإعدادات › وكلاء الجودة › الأجهزة: one `qa_` key per agent, shown once; `محطة مطوّر (قراءة فقط)` = the key of this workstation |
| This workstation's key | create «محطة مطوّر (قراءة فقط)», store it with `qa-set-workstation-key` (this plugin's `bin/`, hidden input) in `~/.config/injaz-qa/.env`; it can only resolve a repository to its project |
| A run that says `blocked_env` | the environment answered a protection page, a bad certificate or nothing — not a bug, no finding |
| A run that says `blocked_by_policy` | a model refused the task — a human decides, nothing is retried elsewhere |
| Weekly digest | one permanent `improvement` ticket per project + `qa.weekly_digest` |

## Process

1. Answer from the table; open the named Injaz screen rather than reading the database.
2. Never put a key, a password or a `.env` value in a chat, a ticket, a commit or a command line.
3. A change to the agents' rules goes through the versioned rulebook (admin API `/api/qa-agents/rulebook/versions`,
   activation logged and announced as `qa.rulebook_activated`), never a prompt edited on the machine.

## Test

- Every answer points at an Injaz screen, a command or a file path — never at a database query on production.
- No answer prints a secret.
