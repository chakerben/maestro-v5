# ZATCA e-invoicing (Fatoora) — KSA invoices

Reference of `maestro-mobile:02-pdf-rtl`. Applies to any invoice issued by a
VAT-registered KSA seller. Source: ZATCA "Guide to developing FATOORA
compliant QR code" (zatca.gov.sa → E-Invoicing → Systems Developers).
Check the current ZATCA developer portal before shipping: waves,
integration deadlines and XML rules move.

## Phase 1 (generation) — the QR on every PDF

TLV bytes (`tag` 1 byte · `length` 1 byte · `value` UTF-8), concatenated,
**base64** encoded, rendered as a QR (≤ 500 chars). Tags:

| Tag | Value |
|---|---|
| 1 | Seller name |
| 2 | Seller VAT registration number (15 digits) |
| 3 | Invoice timestamp, ISO 8601 (`2026-09-19T10:30:00Z`) |
| 4 | Invoice total **with** VAT |
| 5 | VAT amount |

```ts
const tlv = (tag: number, v: string) => {
  const b = Buffer.from(v, 'utf8');
  return Buffer.concat([Buffer.from([tag, b.length]), b]);
};
const qr = Buffer.concat([
  tlv(1, seller), tlv(2, vatNo), tlv(3, iso), tlv(4, total), tlv(5, vat),
]).toString('base64');
```

Amounts as fixed 2-decimal strings with a `.` separator and Latin digits in
the TLV, whatever the visible document uses. Also print the VAT number in
plain text (Arabic label + value) and, for tax invoices, the buyer's.

## Phase 2 (integration) — XML, clearance / reporting

- Invoice = **UBL 2.1 XML** with ZATCA's KSA extensions; the PDF is a
  human-readable rendering of it (PDF/A-3 with the XML embedded when the
  spec asks for it).
- **Standard tax invoice (B2B)** → *clearance*: sent to ZATCA before
  delivery; ZATCA signs and returns it; the QR then carries ZATCA's stamp.
- **Simplified tax invoice (B2C)** → *reporting*: signed on the device
  (ECDSA, CSID issued by ZATCA), delivered immediately, reported within
  24 h. Its QR adds tags **6** (invoice XML hash), **7** (ECDSA signature),
  **8** (ECDSA public key) and **9** (ZATCA technical CA signature of the
  public key) to tags 1–5.
- Each invoice carries a UUID, a sequential counter (ICV) and the previous
  invoice hash (PIH): a chain, so generation must be single-writer per
  device/branch.

Integration is a backend concern (sandbox → simulation → production via
ZATCA's compliance CSID flow), not something a PDF template does; this
skill only guarantees the PDF shows what the XML says and that the QR is
scannable (test with the ZATCA app).

## Checks

- QR decodes to base64 → TLV with tags 1–5 (1–9 on phase 2 simplified).
- Tag 4 − tag 5 equals the pre-VAT subtotal printed on the page.
- Timestamp in the QR equals the printed issue date/time.
