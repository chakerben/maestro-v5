# Tooling audit — the 2026-09 list

> Date : 2026-09-17 · Source : 25 outils/skills notés depuis des vidéos TikTok, vérifiés contre leurs dépôts, leur doc, et le `marketplace.json` officiel d'Anthropic du jour.
> Grille : `plugins/maestro-core/references/third-party-vetting.md` (hooks ? outillage runtime ? orchestrateur ? déjà officiel ? coût d'erreur ?).
> Résultat : **10 absorbés** (l'idée devient du Maestro, rien d'installé), **4 recommandés** tels quels, **9 rejetés**, **2 à tester plus tard**. Ce document existe pour qu'on ne rejuge pas la même liste au prochain reel.

## Avertissement au lecteur (ce document est public)

Les verdicts ci-dessous — **ABSORBÉ, RECOMMANDÉ, REJETÉ** — sont prononcés
**contre les contraintes de Maestro**, pas contre la qualité des projets cités.
Maestro s'interdit plus de deux hooks, interdit tout outillage lourd déclenché
par un événement d'outil, et n'admet qu'un seul framework à la fois (règles #1,
#2, #7 de `PHILOSOPHY.md`). Un outil « rejeté » ici peut être excellent
ailleurs : `claude-mem` est rejeté parce qu'il pose six hooks et un démon, ce
qui est rédhibitoire *dans ce cadre* et parfaitement défendable dans un autre.

Les mécanismes décrits (nombre de hooks, présence d'un démon, d'un appel LLM)
ont été lus dans les dépôts le 2026-09-17 et sont vérifiables ; ils peuvent
avoir changé depuis. Les étoiles, prix et quotas datent du même jour et bougent
vite. Aucune intention de nuire à un auteur : si tu maintiens l'un de ces
projets et qu'une description est fausse ou périmée, ouvre une issue et elle
sera corrigée.

## Le principe

L'objectif de Chaker : taper une phrase simple, et que Maestro choisisse le meilleur outil sans qu'il nomme une skill, un MCP ou un plugin. Ça ne s'obtient pas en installant plus ; ça s'obtient avec **un routeur à jour dans chaque projet** (`<maestro_routing>`, maintenu par le hook SessionStart depuis 5.9.0) et des skills dont la description dit *quand*, pas *quoi*. Chaque outil ci-dessous a été jugé à cette aune : est-ce qu'il rend le routage meilleur, ou est-ce qu'il ajoute une chose de plus à nommer ?

## Absorbés — devenus des skills ou des règles Maestro (5.9.0)

| Outil | Ce qu'on en a pris | Où |
|---|---|---|
| **Ponytail** (140k ★, 3 hooks) | L'échelle skip → reuse → stdlib → platform → installed dep → one-liner → build ; le marqueur `debt:` | `maestro-dev:05-lean-code`, préchargée dans executor / checker / m-architect |
| **Karpathy guidelines** | Penser avant de coder (critère vérifiable), simplicité d'abord, changements chirurgicaux, exécution pilotée par le but | même skill — fusionnées pour ne pas avoir deux jeux de règles quasi identiques |
| **Stop-slop** (10k ★) | La liste des tics IA (contrastes binaires, triplets réflexes, intensificateurs vides, résumés qui répètent l'ouverture), l'auto-score | `maestro-pm:04-writing` |
| **/ghost** (« naturel humain ») | Folklore de prompt, pas une commande. L'effet réel = les règles de stop-slop | `04-writing`, section Voice |
| **L99** (« réponds en expert ») | Idem : un suffixe de prompt. L'effet réel = « engage-toi sur une recommandation, sans hedging » | `04-writing`, règle **Commit** |
| — | Section **arabe** que rien en amont n'avait : ouvertures formulaires, registre MSA vs client WhatsApp, chiffres, ponctuation «،» «؟», tokens latins dans le texte | `04-writing` |
| **GSAP** (gratuit depuis Webflow 2025) + **Lenis** (MIT) | Défauts de motion pour les surfaces marketing, reduced-motion d'abord, transform/opacity seulement, `SplitText` par **mots** jamais par caractères en arabe | `maestro-web:03-motion` |
| **Superpowers** (obra) | Déjà absorbé : brainstorm (5.5.0), debug systématique (5.8.0 `04-debug`), vérification avant « done » (cognitive-protocols 1 & 6). Non installé : rule #7, il veut posséder la session | — |
| **Task-observer** | Le journal des corrections répétées → candidats de skills | `02-gardener`, règle « skill-gap log », zéro skill always-on |
| **Everything Claude Code** | Une seule idée : « préserver l'état avant compaction » — déjà couvert par les dossiers `maestro_docs/tasks/` résumables (rule #6). Le reste (21 hooks) est l'anti-modèle | — |

## Recommandés — installés tels quels, via `00-onboard`

| Outil | Comment | Pourquoi |
|---|---|---|
| **Context7** | plugin officiel (déjà défaut) — désormais **obligatoire** avant tout code spécifique à une lib (executor, lean-code rung 4/5, routing) | tue les APIs hallucinées d'une version antérieure |
| **Impeccable** (Paul Bakaus) | `npx impeccable install`, **skill seulement, hook refusé** | meilleure skill de goût frontend ; aucune connaissance RTL → `01-rtl-i18n` et `02-design-review` par-dessus |
| **skills.sh / find-skills** (Vercel) | CLI de découverte, jamais `add` sans passer la grille de vetting | registre bruité, utile pour une niche |
| **agentskills.io** | c'est le standard SKILL.md — tes 31 skills le suivent ; `npm run test:platform` le vérifie | rien à faire |
| **Firecrawl** | plugin officiel, à installer **quand** un vrai crawl multi-pages arrive (docs Moyasar, etc.) | WebFetch couvre une page ; context7 les libs |

## Rejetés — avec la raison, pour ne pas y revenir

| Outil | Mécanisme réel | Raison du rejet |
|---|---|---|
| **Claude-mem** | 6 hooks, daemon Bun sur un port, SQLite, appel LLM dans le hook Stop | C'est le v4 du 13/07 : outillage runtime dans les hooks. Rule #1, #2, #3. La mémoire Maestro (memory bank + `01-memory`) couvre le besoin sans latence |
| **Everything Claude Code** | 21 hooks : Prettier et `tsc` en PostToolUse, quality gate, télémétrie en Stop | La définition exacte de ce qui a gelé la machine. Lecture utile, installation interdite |
| **Omniroute** | Passerelle multi-modèles via `ANTHROPIC_BASE_URL` | Change de modèle sous Claude Code : casse le tool-use, contredit « 100 % Claude Code », zone grise ToS |
| **Graphify** | Graphe de connaissance du code (Python, tree-sitter) | Rentable au-delà de ~200k lignes de monorepo ; sur tes projets, grep + ARCHITECTURE.md font le travail. À revoir si un projet dépasse ce seuil |
| **UI UX Pro Max** | CLI npm + scripts Python + CSV de palettes | Dépendance Python, doublon d'Impeccable, aucune couverture RTL. Sa checklist style → palette → typo → effets est un sous-ensemble de `02-design-review` |
| **Composio** | Plateforme de 1 500 intégrations, MCP HTTP, compte + clé | Doublonne les plugins officiels (github, connecteurs Gmail/Drive/Calendar), repricing d'août 2026 (−75 % de quota), garde de credentials chez un tiers |
| **Meetly / Meetily** | App desktop de transcription locale | Pas de MCP, pas d'intégration Claude Code — TikTok a confondu. Pas un outil de dev |
| **React Bits MCP** | MCP payant (Pro) ou wrappers communautaires | Composants LTR, WebGL lourd sur mobile ; copier un composant à la main quand une page en a besoin suffit |
| **Kimi Work** | Produit concurrent (Moonshot) | Hors périmètre ; rule #7 |

## À tester plus tard, sur un projet, avec une date

| Outil | Condition | Forme |
|---|---|---|
| **Strix** (pentest dynamique, Apache-2, Docker + ta clé LLM) | Avant une mise en prod d'une app Clerk/Prisma | CLI lancé par une future `maestro-quality:03-pentest` ; pas un hook, pas un MCP ; surveiller le coût en tokens |
| **Motion AI Kit** | Seulement si un projet choisit Motion plutôt que GSAP | MCP + skill officiels de motion.dev |

## Ce qui a changé dans le framework à cause de cet audit

- `maestro-core/references/routing.md` + le hook `memory-sync.js` : le routeur est poussé dans le CLAUDE.md de chaque projet à chaque session — la réponse structurelle à « je tape du texte simple ».
- 3 skills : `05-lean-code`, `04-writing`, `03-motion`.
- `00-onboard` : context7 obligatoire, Impeccable sans hook, Firecrawl à la demande, et une table « vetted third-party » pour que la question ne se repose pas.
- `references/third-party-vetting.md` : la grille, cinq questions.
- `02-gardener` : le journal des corrections répétées.

## Note de méthode

Deux agents de recherche ont vérifié chaque item sur son dépôt et sa doc (hooks.json lus, pas résumés) et le `marketplace.json` officiel a été lu brut le jour même. Les chiffres de stars, prix et quotas datent du 2026-09-17 et bougent ; les mécanismes (combien de hooks, quel daemon) ne bougent pas et sont ce qui fonde chaque décision.
