---
name: 04-writing
description: Standing rules for any prose a human will read — README, PR body, commit body, client message, release note, doc, proposal, in FR / EN / AR. Applies whenever such text is produced; also answers "reformule", "ça fait IA", "écris ça naturellement", "réponds en expert". Not for code comments or UI strings (those follow the code's conventions).
argument-hint: "[rewrite <path or text>] [lang fr|en|ar]"
effort: low
---

# Skill: writing

> Absorbed from stop-slop (the tells and the self-score), the "/ghost" and
> "L99" prompt folklore (natural voice; commit to a recommendation), with an
> Arabic section nothing upstream had. Nothing installed.

Text that reads as machine-written costs trust — with a client, a reviewer,
an app-store reviewer. These rules remove the tells without removing the
substance.

## Voice

- Say the thing. First sentence carries the point; no throat-clearing ("Il
  est important de noter que", "In today's fast-paced world", "من الجدير
  بالذكر").
- **Commit.** When asked for an opinion or a recommendation, give one, with
  the reason and the trade-off. No "it depends" without saying on what; no
  hedge stack ("perhaps", "might", "could potentially").
- One idea per paragraph. Short where the reader is busy (clients, PR
  reviewers), longer only where the reasoning is the deliverable.
- Concrete over generic: a number, a file, a date, a name — not "various
  improvements".

## Tells to remove (all languages)

- Binary contrast frames: "it's not X, it's Y", "ce n'est pas seulement…
  c'est…", "ليس مجرد… بل…".
- Triplets by reflex ("fast, reliable, and scalable") when two or four
  would be true.
- Em-dash chains and colon-cascades; "Additionally / Furthermore / Moreover"
  as paragraph glue; closing summaries that repeat the opening.
- Empty intensifiers: "seamlessly", "robust", "cutting-edge", "délicieusement
  simple", "بكل سلاسة".
- Praise of the question, apology for the answer, "I hope this helps".
- Headers and bullets in a message that is three sentences long.

## Arabic (العربية) — the tells are different

- Formulaic openers/closers: «في عالمنا اليوم», «لا شك أن», «وفي الختام»,
  «نأمل أن يكون هذا مفيدًا». Cut.
- Over-formal MSA fillers where the audience is a Saudi client on WhatsApp:
  «يُرجى التكرم بالعلم» → «للعلم». Match the register the client uses in
  their own messages; read one before writing.
- Numbers: consistent digits (arab or latn) within one text, per the project's
  decision; dates in Hijri + Gregorian for anything contractual.
- Direction: any Latin token (code, URL, SKU) inside Arabic text is wrapped so
  it does not break the line's direction when pasted (in markdown: put it in
  backticks).
- Punctuation: Arabic comma «،» and question mark «؟»; no Latin comma in an
  Arabic sentence.

## French

- Vouvoiement by default with clients unless they tutoie first; tutoiement in
  internal notes. No anglicisms where a common French word exists in the
  team's usage ("livrer", not "shipper", in client text).
- Accents kept in ALL CAPS and in file names shown to clients.

## Self-check before delivering (score 1–5, silently)

Directness · Specificity · Register match · Tells removed · Reads aloud
naturally. Anything under 4 on any axis gets one rewrite pass. Output only
the text — never the score, never "here is a natural version".

## `rewrite` mode

Given a text: keep every fact, quantity and commitment; change voice only.
Show the result, and in one line what category of tells was removed.

## Test

- The delivered text contains none of the listed tells for its language.
- A recommendation request received one recommendation with a reason, not a
  menu of options without a pick.
- `rewrite` preserved every number, name and date of the source (diff the
  digits).
