---
status: pending        # pending | in-progress | done | blocked
phase: <n>
attempts: 0            # 02-implement increments it; blocked at 3
---

# Phase <n> — <name>

## Scope

<what this phase builds — and what it deliberately does NOT>

## Acceptance criteria

- [ ] <falsifiable criterion>

## Validation

```bash
# one command, exit code = the gate. A grep on Arabic text needs LC_ALL=C.UTF-8
# (without it `\x{0600}` errors and `! grep` passes vacuously — pilot 5.15.0).
<command whose exit code gates this phase>
```

## Log

<!-- the orchestrator (02-implement) logs each attempt: timestamp, what, result -->
