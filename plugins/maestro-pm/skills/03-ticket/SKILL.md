---
name: 03-ticket
description: Use when a defect, gap, or improvement has been FOUND and must be handed to the team instead of fixed on the spot — a bug seen during QA or an audit, a checker finding, a "seen on the way" note from 04-debug, "crée un ticket", "mets ça sur Trello". Turns each finding into one Trello card in the project's backlog list, following the Maestro card convention. Not for fixing the bug (maestro-dev:04-debug), not for product framing (00-prd), not for user stories of a new feature (01-user-stories).
argument-hint: "<finding, or 'from <report path>'>"
allowed-tools: Bash   # turn-scoped: the !`…` injections above use shell builtins, pipes and $(…) that pattern grants do not cover
---

# Skill: ticket

A found bug is a decision for a human — who fixes it, when, at what priority.
This skill records the finding so that decision can be made; it never makes
it. **It never fixes the code.**

## Live state (computed at invocation)

Target board / list (from the plugin's user config, set at enable time):
!`echo "board: ${CLAUDE_PLUGIN_OPTION_TRELLO_BOARD:-<not set — run: claude plugin config maestro-pm>}   list: ${CLAUDE_PLUGIN_OPTION_TRELLO_LIST:-À faire V1}"`

Repo context for the card body:
!`echo "repo: $(basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")  branch: $(git branch --show-current 2>/dev/null)  head: $(git rev-parse --short HEAD 2>/dev/null)"`

Source: `$ARGUMENTS`

## Process

1. **Collect the findings.** From the argument, from a report path
   (`review.md`, `debug.md` `## Seen on the way`, an audit report), or from
   the conversation. One finding = one card. Merge duplicates; split
   compound findings.
2. **Draft every card** with `assets/card-template.md` — all of them before
   creating any; priority and labels from its tables. Repro steps must be
   runnable by someone who was not in this session; "see above" is not a
   step.
3. **Show the batch** as a table (title · priority · labels) and wait for one
   approval. Edits requested → redraft, show again.
4. **Create** each approved card in list `${user_config.TRELLO_LIST}` of
   board `${user_config.TRELLO_BOARD}` through the connected Trello tool.
   No Trello tool available → write each card to
   `maestro_docs/tickets/<yyyy_mm_dd>_<slug>.md` and say so plainly; never
   pretend a card exists.
5. **Report** the card URLs (or file paths). If the findings came from a
   `debug.md` / `review.md`, append the URLs there under the finding.

## Binding rules

- Never fix the defect, never open a branch, never edit source in this skill.
- Never a `Co-Authored-By` or any AI attribution in a card or a comment.
- Language of the card = language of the board (read existing cards; when
  in doubt, French for the Maestro-managed boards, Arabic when the board is).
- Card body ends with the `Trouvé :` / `Found:` / `رُصد في:` line
  (`<repo>@<short-sha> — <date>`) so the team can find the state the bug was
  seen in.

## Test

- Each created card: title starts with one of 🔴🟠🟡⚪, body has the four
  sections of `assets/card-template.md` in the board's language (FR/EN/AR),
  at least one label, and the `Trouvé :` / `Found:` / `رُصد في:` line.
- No source file changed (`git status` unchanged by this skill).
- The user approved the batch before the first card was created.
