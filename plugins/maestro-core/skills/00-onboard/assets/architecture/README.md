# Architecture that a tool enforces

Written into the project by `00-onboard` scaffold step 4e, verified at every
commit by `maestro-check boundaries`. Four folders, one direction:

```
domain/          entities, value objects, domain services, repository PORTS (interfaces)
application/     use cases — orchestrate domain objects through the ports
infrastructure/  ADAPTERS — Prisma / Firestore / HTTP / Expo APIs implement the ports
ui | app | components | presentation/   screens — call use cases, never adapters
```

Allowed: `ui → application → domain`, `infrastructure → domain` (to implement
a port). Forbidden, and red at commit: `domain → anything`, `application →
infrastructure`, `ui → infrastructure`, any cycle. The wiring (which adapter
satisfies which port) lives at the edge: `app/_layout.tsx`, `app/providers`,
`infrastructure/di.ts`, `main.dart`.

Why files and not a rule in prose: a model writes `import { prisma } from
'@/infrastructure/db'` inside a use case the first time it is convenient,
and nothing in a SKILL.md stops it. `dependency-cruiser` does, with the file
and line. This is PHILOSOPHY rule 2d applied to SOLID/DDD.

Deviating is allowed — edit the config, say why in `tech-decisions.md`.
