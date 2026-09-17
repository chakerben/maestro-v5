# Vetting a third-party skill, plugin or MCP before it enters a Maestro project

Five questions, in order. The first "no" ends the evaluation.

1. **Hooks?** Open its `hooks/hooks.json`, `plugin.json` (`hooks` key) and
   every `SKILL.md` frontmatter (`hooks:`). Any hook → it does not come in as
   a plugin. If the idea is good, the skill text can (rule #1: two hooks in
   the whole framework, both Maestro's).
2. **Runtime tooling?** Does anything it ships run tests, formatters,
   typecheck, an LLM call, or a daemon on tool events? That is Maestro v4
   coming back (13/07/2026). Reject outright.
3. **Orchestrator?** Does it want to own the session (SessionStart injection
   of "mandatory workflows", its own plan/execute/review loop)? Rule #7: one
   framework. Absorb the ideas, do not install.
4. **Official already?** Check `claude-plugins-official` first (context7,
   firecrawl, playwright, github, security-guidance, frontend-design…).
   Rule #8: the official one wins, always.
5. **Cost of being wrong?** External account, API key custody, volatile
   pricing, model switching under Claude Code → LATER, on one project, with
   a date to re-evaluate.

Passed all five → install **skill-level only**, `--scope project`, and note
it in `tech-decisions.md` with the date and the reason. `04-doctor` will
flag any hook that appears afterwards.

Applied to the 2026-09 TikTok list: `docs/TOOLING-AUDIT-2026-09.md`.
