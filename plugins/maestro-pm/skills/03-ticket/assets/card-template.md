# Card template

Language of the card = language of the board. Structure is identical in the
three languages; only the section headings change.

## Priority

| Emoji | Level | Meaning |
|---|---|---|
| 🔴 | P0 | blocks users, payment, auth, data loss, security |
| 🟠 | P1 | wrong result on a main flow, no workaround |
| 🟡 | P2 | wrong but workaround exists, or secondary flow |
| ⚪ | P3 | polish, nice-to-have, tech debt |

The emoji is the first character of the card title.

## Labels

| Finding touches | Labels |
|---|---|
| security, payment, auth, anything P0 | `quality` |
| refactor, docs, minor bug | `fast` |
| RTL / Arabic / i18n | add `rtl` when the board has it |

## FR

**Title**: `<🔴|🟠|🟡|⚪> <verb + object, ≤ 70 chars>`

**Body** (markdown):

### Repro
1. <step someone outside this session can run>
2. …
Contexte : <locale, rôle, device, données>

### Attendu
<one or two sentences: the correct behaviour>

### Critères d'acceptation
- [ ] <falsifiable>
- [ ] <falsifiable — includes the `ar` locale when the project has one>

### Pistes techniques
- <file:line or module suspected, with the evidence quote>
- <the likely cause in one sentence, marked "hypothèse" if not verified>

Trouvé : <repo>@<short-sha> — <yyyy-mm-dd>

**Labels**: <quality | fast> [rtl]


## EN

**Title**: `<🔴|🟠|🟡|⚪> <verb + object, ≤ 70 chars>`

**Body** (markdown):

### Repro
1. <step someone outside this session can run>
2. …
Context: <locale, role, device, data>

### Expected
<one or two sentences: the correct behaviour>

### Acceptance criteria
- [ ] <falsifiable>
- [ ] <falsifiable — includes the `ar` locale when the project has one>

### Technical leads
- <file:line or module suspected, with the evidence quote>
- <the likely cause in one sentence, marked "hypothesis" if not verified>

Found: <repo>@<short-sha> — <yyyy-mm-dd>

**Labels**: <quality | fast> [rtl]

## AR

**العنوان**: `<🔴|🟠|🟡|⚪> <فعل + مفعول، ≤ 70 حرفًا>`

**المحتوى** (markdown):

### خطوات إعادة الإنتاج
1. <خطوة يستطيع تنفيذها شخص لم يحضر هذه الجلسة>
2. …
السياق: <اللغة، الدور، الجهاز، البيانات>

### السلوك المتوقع
<جملة أو جملتان: السلوك الصحيح>

### معايير القبول
- [ ] <قابل للتحقق>
- [ ] <قابل للتحقق، ويشمل اللغة العربية `ar` عند وجودها في المشروع>

### مسارات تقنية
- <الملف:السطر أو الوحدة المشتبه بها، مع اقتباس الدليل>
- <السبب المرجّح في جملة واحدة، مع وسم «فرضية» إن لم يُتحقق منه>

رُصد في: <repo>@<short-sha> — <yyyy-mm-dd>

**التصنيفات**: <quality | fast> [rtl]
