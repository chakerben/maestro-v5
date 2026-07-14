---
name: 02-perf-audit
description: Performance audit of a scope — DB query patterns, N+1, bundle weight, render behavior, caching. Use when something is slow, before scaling, or as a periodic pulse. Measures before recommending. Not for micro-optimizing readable code.
argument-hint: "[scope path]"
allowed-tools: Read, Grep, Glob, Bash
---

# Skill: perf-audit

Adopt the performance engineer posture. Iron rule: **measure before
recommending** — a recommendation without a measurement or a query plan is
labeled "hypothesis".

## Process

1. **Data layer.** Prisma queries in the scope: missing `select` (over-fetch),
   loops containing queries (N+1 — propose `include`/batched variants),
   missing indexes for frequent `where`/`orderBy` (check schema), unbounded
   `findMany` without pagination.
2. **Server.** Route handlers doing serial awaits that could be `Promise.all`,
   missing caching (`revalidate`, `unstable_cache`, HTTP cache headers),
   heavyweight work in request path that belongs in a queue.
3. **Client.** Bundle: heavy deps imported at top level that could be dynamic;
   images unoptimized (raw `<img>` vs framework image); client components
   that could be server components; long lists without virtualization.
4. **Mobile (when RN/Expo).** Re-render hotspots (missing memo on list rows),
   images without caching, JS-thread animations that belong on the UI thread
   (Reanimated), Hermes enabled?
5. Report: finding → measurement or evidence → expected win → cost of fix.
   Rank by win/cost. Top 3 get concrete diffs proposed.

## Test

- Every non-hypothesis finding carries a measurement, a query shape, or a
  bundle number.
- No code was modified.
