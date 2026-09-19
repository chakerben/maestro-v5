---
name: 02-pdf-rtl
description: Generate correct RTL Arabic PDFs — invoices, reports, contracts. Use whenever a PDF must contain Arabic text. Encodes the hard-won route that avoids broken letter-joining and reversed text. Not for LTR-only PDFs (any library works there).
argument-hint: "[invoice | report | contract]"
---

# Skill: pdf-rtl

Arabic PDF is a trap: most PDF libraries do neither **bidi reordering** nor
**glyph shaping** (contextual letter joining). Naive output renders Arabic
disconnected and left-to-right. This skill encodes the reliable route.

## The decision tree (binding)

1. **Default route — browser print engine.** Render HTML/CSS with
   `dir="rtl"` and print via Playwright/Puppeteer: `await
   document.fonts.ready` before `page.pdf({ printBackground: true })`. The
   browser does bidi + shaping natively. Server-side: a headless Chromium
   worker; Next.js: an API route or queued job (NEVER in the request path
   for bulk).
2. **react-pdf / pdfkit / jsPDF direct text**: only for LTR or with an
   explicit shaping pipeline — treat as an exception requiring a
   tech-decisions.md entry. Their Arabic support ranges from partial to wrong.
3. **Serverless constraint** (no Chromium): use `@sparticuz/chromium` with
   Playwright-core; if truly impossible, generate HTML and convert in a
   container job.

## Template rules (HTML route)

- `<html dir="rtl" lang="ar">`; logical CSS properties throughout (the
  01-rtl-i18n rules apply verbatim).
- **Embed fonts** — never rely on system fonts in headless: Amiri or
  Noto Naskh Arabic for body, Cairo for headings, `@font-face` with local
  files, `font-display: block`.
- Numbers in tables: decide arab vs latn digits per document type (invoices
  for government: follow the authority's requirement; record it).
- Dual dates on official docs: Hijri (islamic-umalqura) + Gregorian.
- Currency: inline SVG from `01-rtl-i18n/assets/sar-icon.svg` (see its
  `references/sar.md`); icon fonts often don't load headless.
- Mixed content cells (Arabic + product codes): wrap LTR runs in
  `<bdi>` or `dir="ltr"` spans — invoice line items are the #1 bidi bug site.
- Page footer/header via CSS `@page` margins, or the print API's
  header/footer templates — those inherit neither the page CSS nor its
  fonts (inline both); page numbers localized.
- `invoice` for a KSA seller → apply `references/zatca.md` (QR TLV, phases).

## Validation (every generated PDF)

- Letters JOIN (السلام, not س ل ا م disconnected) — the shaping smoke test.
- Text is selectable and copies in logical order (copy a sentence out).
- A mixed line ("فاتورة رقم INV-2024 بتاريخ...") reads correctly.
- Amounts align to the start edge of their column, digits consistent.

## Test

Every PDF produced under this skill passes the four checks in
"Validation" above, and the run reports the shaping smoke test explicitly
(a screenshot or the copied text of one Arabic sentence).
