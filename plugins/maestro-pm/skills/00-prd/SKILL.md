---
name: 00-prd
description: Write or refine a Product Requirements Document — problem, users, scope, success metrics, risks. Use at the start of a product or major feature, before any spec. Output in FR, EN, or AR per the user's language. Not for technical specs (02-specs) or stories (01-user-stories).
argument-hint: "<product/feature idea>"
---

# Skill: prd

A PRD answers WHY and FOR WHOM before anyone discusses HOW.

## Process

1. **Interview, don't assume.** Ask (grouped, once): who has the problem
   today and how do they cope; what changes for them if this ships; how do we
   know it worked (a measurable signal); what is explicitly OUT of v1;
   deadline/constraints.
2. Draft from `assets/prd-template.md`. Every section filled or marked
   `TBD (owner: <who>)` — no silent gaps.
3. **Shadow pass**: scan your own draft for blind spots per category —
   edge users, empty/first-run experience, failure paths, i18n/RTL market,
   legal/compliance (Saudi context: data residency, VAT on invoices),
   operational cost. Add findings to Risks.
4. Run m-devil-advocate mentally on the success metric: can it be gamed? Is
   it measurable with current tooling?
5. Save to `maestro_docs/specs/prd-<slug>.md` in the user's language.

## Test

- Success metrics are numeric and measurable with named tooling.
- Out-of-scope is non-empty (a PRD without exclusions is a wish list).
