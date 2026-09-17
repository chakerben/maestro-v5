# Audit adversarial — Maestro 5.5.0

> Date : 2026-09-17 · Dépôt : `chakerben/maestro-v5` @ `2abb2e3` (tag `v5.5.0`, arbre propre, `origin/main` à jour)
> Méthode : lecture intégrale des 116 fichiers versionnés, exécution de `npm test` (vert : validate + 34 cas bash-guard + 10 cas memory-sync), rejeu de 45 commandes contre `bash-guard.js`, vérification de la doc officielle des plugins (skills, marketplace) au jour de l'audit, et pointage de chaque item ouvert de `AUDIT-5.3.1.md`.
> **Suite donnée le jour même : voir CHANGELOG 5.6.0** — tout ce qui est marqué B/C/D/E ci-dessous a été traité, sauf C-6 (décision propriétaire) et C-11 (optionnel).
> Périmètre : le framework lui-même. Aucun projet client n'a été touché. **Aucune correction appliquée** — chaque constat est une décision à prendre, pas un patch posé.

## Verdict en une page

La 5.4.0 a tenu ses promesses : les deux P0 sur `memory-sync.js` sont réellement fermés (le hook est aujourd'hui la pièce la plus solide du dépôt), le transfert vers `chakerben` est fait, tagué, et les 9 manifestes sont verrouillés par `check-versions.js`. La 5.5.0 ajoute `03-brainstorm`, qui est la skill la mieux écrite du framework et la seule à documenter *pourquoi* elle diverge de sa source.

Ce qui reste n'est plus du même ordre. Il n'y a plus de bug qui détruit un fichier utilisateur. Il reste **trois écarts entre ce que le framework affirme et ce qu'il fait**, et c'est le genre d'écart que PHILOSOPHY.md (règle #5, dernier paragraphe) désigne lui-même comme le pire : « une règle décrite comme garantie quand elle est seulement demandée est pire que pas de règle ».

1. **Le scan de secrets « jamais désactivable » ne voit pas les commits qui comptent.** `02-implement/actions/02-execute.md` committe chaque phase directement (`feat(<slug>): phase <n>`), sans passer par `maestro-vcs:00-commit`. Quand `00-sdlc/05-ship` délègue enfin au gate, tout le code est déjà dans l'historique de la branche ; le gate scanne un diff quasi vide. Un `sk_live_…` introduit en phase 2 est poussé avec la PR. C'est le constat le plus important de cet audit : il ne demande pas de code, il demande une ligne dans `02-execute.md`.
2. **`bash-guard.js` est un garde-fou anti-accident vendu comme un garde de sécurité.** Sur 45 commandes rejouées, 30 passent, dont `rm -rf /*`, `git push -f`, `chmod -R 777`, `bash <(curl …)`, `source .env`, `dd of=/dev/sda`. L'audit 5.3.1 l'avait déjà chiffré ; la 5.4.0 a choisi de ne pas trancher. Il faut trancher maintenant, dans un sens ou dans l'autre — les deux sont acceptables, l'entre-deux ne l'est pas.
3. **`validate.js` protège la Philosophy contre le repo, pas contre un retour du v4.** Il ne compte que `plugins/**/hooks.json`. Un hook déclaré dans la clé `hooks` d'un `plugin.json` ou dans `.claude/settings.json` reste invisible (P0-3 de 5.3.1, inchangé). Tant que Chaker est le seul contributeur, c'est théorique ; le jour où un projet client « remonte » un hook, ça ne l'est plus.

À côté de ça : la CI n'exécute pas `check-versions.js` sur `main` (seulement au tag), `publish.yml` porte encore `scope: '@arabiipte'`, README annonce encore « TDD, debug » que 5.5.0 disait avoir retirés, PHILOSOPHY.md cite une skill `maestro-dev:03-review` qui n'existe pas (03 est `brainstorm`), et les scripts de migration v4→v5 — dont la mission est accomplie depuis juillet — traînent 9 défauts confirmés qui n'ont plus de raison d'être corrigés, seulement archivés.

Le prérequis nommé en fin de RUNBOOK-5.4.0 reste vrai : **la première vraie feature via `/sdlc` n'a toujours pas été exécutée**. Rien dans ce dépôt ne le prouve, et c'est le seul test qui compte.

---

## A — Ce qui a été fermé depuis 5.3.1 (vérifié, à ne pas rouvrir)

| Item 5.3.1 | État | Preuve |
|---|---|---|
| P0-1 memory-sync détruit CLAUDE.md | **Fermé** | `BLOCK_RE` appairé, ancré ligne ; test 1, 2, 4 du suite |
| P0-2 corruption concurrente | **Fermé** | lock `wx` + tmp/rename ; test 8 (40 paires) vert |
| P3 injection par nom de fichier | **Fermé** | `SAFE_NAME`, test 6 |
| P3 symlink CLAUDE.md | **Fermé** | `lstatSync` + `isFile()`, test 7 |
| P3 liste on-demand non bornée | **Fermé** | `MAX_ON_DEMAND = 200` |
| P3 CI vide sur les hooks | **Fermé** | les deux suites tournent dans `ci.yml` |
| P1-1 backup incomplet (migrate) | **Fermé** | `settings.json`, `CLAUDE.md`, `memory-bank` dans la liste |
| P1-5 option inconnue = nom de projet | **Fermé** | branche `-*) exit 2` |
| P2 `user-invocable: false` non documenté | **Fermé par la plateforme** | documenté aujourd'hui : « hides it from the `/` menu ». Le comportement voulu est obtenu |
| P2 `strict` non documenté | **Fermé par la plateforme** | documenté, **valeur par défaut `true`** → les 7 `"strict": true` sont redondants, sans effet |
| Dérive de version des 9 manifestes | **Fermé** | `check-versions.js` + `npm test` |
| Descriptions mensongères des manifestes | **Fermé** (manifestes seulement, voir C-3) | `plugin.json` + `marketplace.json` listent ce qui existe |

---

## B — P1 · Écarts affirmé / réel (à trancher avant la prochaine feature)

### B-1 · Les commits de phase contournent le gate de secrets

`plugins/maestro-dev/skills/02-implement/actions/02-execute.md`, étape 3 :

> Green → set `status: done`, commit the phase as ONE unit (code + status), conventional message `feat(<slug>): phase <n> — <name>`.

Rien ne dit *par quoi* committer. `maestro-vcs:00-commit/actions/01-gate.md` affirme : « Secrets scan (always, never skippable) ». `00-quality-gate/SKILL.md` : « The secrets scan is constitutional: no level disables it ». `ARCHITECTURE.md`, tableau « Where quality runs » : « Before commit → Secret detection ».

Chaîne réelle d'un `/sdlc` : phase 1 commit (pas de gate) → phase 2 commit (pas de gate) → … → `05-ship` délègue à `00-commit`, qui scanne `git diff --cached` — c'est-à-dire, au mieux, le changement de `status:` du plan. Le secret est déjà dans trois commits derrière.

Aggravant : `01-gate.md` scanne « the diff's ADDED lines » du *staged*. Aucune action ne scanne `git diff <default>...HEAD` avant le push. Et `01-pull-request` (« Preconditions: […] clean tree, branch pushed ») ne scanne rien non plus.

**Correctif (une décision, pas du code)** : dans `02-execute.md` étape 3, remplacer « commit the phase » par « commit the phase **via `maestro-vcs:00-commit`** (gate + message) ; si maestro-vcs n'est pas installé, exécuter le scan `assets/secret-patterns.md` sur le diff de phase avant de committer ». Et ajouter à `01-pull-request` étape 1 un scan de `git diff <base>...HEAD` — c'est le vrai dernier filet avant que ça devienne public.

Le test associé existe déjà dans `01-gate.md` (« A diff containing `sk_live_xxx…` is blocked even at level `off` ») ; il ne s'applique aujourd'hui qu'à un chemin que `/sdlc` n'emprunte pas.

### B-2 · `bash-guard.js` — décider ce qu'il est

45 commandes rejouées contre le hook (`plugins/maestro-quality/hooks/bash-guard.js`, 7 règles). **30 passent.** Extrait, par règle :

| Règle | Bloque | Laisse passer (confirmé) |
|---|---|---|
| rm -rf racine/home | `rm -rf /`, `~`, `$HOME`, `"$HOME"`, `sudo rm -rf /` | `rm -rf /*` · `rm -rf ${HOME}` · `rm -Rf /` (R majuscule) · `rm -rf /  # commentaire` · `cd / && rm -rf *` · `rm -rf .` à la racine · `find / -delete` |
| curl \| sh | `curl … \| bash`, `wget … \| sh` | `curl … \| sudo bash` · `bash <(curl …)` · `sh -c "$(curl …)"` · `curl -o x.sh && bash x.sh` |
| chmod 777 | `chmod 777 f` | `chmod -R 777 .` · `chmod 0777 f` · `chmod a+rwx` seul n'est pas testé |
| écriture disque | `> /dev/sda` | `dd of=/dev/sda` · `mkfs.ext4 /dev/sda1` |
| lecture .env | `cat .env`, `.env.local`, `./.env` | `source .env` · `grep . .env` · `cat < .env` · `cp .env /tmp/x` · `printenv` · `env` · `node -e "console.log(process.env)"` · `cat .envrc` |
| echo secrets | `echo $API_KEY` | `echo $DATABASE_URL` · `printf "%s" "$SECRET_KEY"` · `echo ${AWS_SECRET…}` (le `{` est prévu, mais `printf` non) |
| push --force | `--force` | `git push -f` · `git push origin +main` · `git reset --hard` · `git clean -fdx` |

Le pattern est clair : la règle attrape la forme *canonique* et rien d'autre. C'est exactement le profil d'un **garde-fou anti-accident** (le modèle tape `rm -rf ~` par erreur) — et c'est utile. Ce n'est pas un garde de sécurité contre un modèle qui *veut* contourner, et il ne le sera jamais avec des regex sur une ligne de shell (les 45 contournements de 5.3.1 le démontraient déjà).

Deux sorties honnêtes, au choix :

- **(a) Requalifier.** Commentaire de tête et `PHILOSOPHY.md` règle #1 : « pure security gate » → « accident guard : blocks the canonical spelling of six irreversible commands ; a determined caller can bypass it ; the platform permission system (`permissions.deny`) is the enforced layer ». Ajouter `git push -f`, `rm -Rf`, `${HOME}`, `chmod -R 777` — les oublis à coût nul. Fin. Cette option prend 20 minutes.
- **(b) Tokeniser.** Découper sur `;`, `&&`, `||`, `|`, `$(…)`, `<(…)`, normaliser les flags, résoudre `~`/`$HOME`/`${HOME}`. Deux jours, une suite de 200 cas, et toujours pas étanche (`eval`, alias, scripts sur disque).

L'audit recommande **(a)**, pour une raison de doctrine : la règle #8 dit de ne pas reconstruire ce qu'Anthropic maintient, et `permissions.deny` dans `settings.json` est ce mécanisme. `migrate-v4-to-v5.sh` en pose d'ailleurs déjà trois entrées (`Bash(rm -rf /)`, `Bash(curl * | bash)`, `Bash(wget * | sh)`) dans chaque projet migré. Le hook double ce que la plateforme fait mieux.

Point de doc : `PHILOSOPHY.md` (tableau des métriques) annonce `bash-guard <20 ms`. 5.3.1 mesurait 40-50 ms (démarrage Node). Non re-mesuré ici (machine différente) ; la ligne reste à corriger ou à prouver.

### B-3 · `validate.js` ne verrait pas revenir le v4

Inchangé depuis 5.3.1 (P0-3), vérifié sur le source :

| Ligne | Ce qui est vérifié | Ce qui échappe |
|---|---|---|
| `walk(ROOT/plugins)` + `e.name === 'hooks.json'` | uniquement `plugins/**/hooks.json` | clé `hooks` d'un `plugin.json` (documentée, chargée par la plateforme) ; `.claude/settings.json` à la racine ; `hooks-*.json` |
| strip de commentaires par regex | `/*…*/` et `//…` | une URL `https://` dans une chaîne mange la fin de ligne — un `execSync('npx jest')` derrière devient invisible |
| `isReviewer = /checker\|devil-advocate/.test(f)` | deux noms de fichier | `m-i18n-checker` est attrapé par accident (`checker`) ; un futur `m-auditor.md` avec `Edit` passe |
| `\b(Edit\|Write\|MultiEdit)\b` | trois noms | `NotebookEdit` passe |
| frontmatter skills | `name` + `description` | règle #4 (`actions/*.md` + `## Test`) : **non vérifiée** ; `name:` ≠ nom de dossier : non vérifié |
| `${CLAUDE_PLUGIN_ROOT}` | présent quelque part dans le fichier | `timeout` absent : non vu (règle #5 dit « hooks carry a platform timeout ») |

À noter en positif : `m-architect.md` porte `tools: Read, Grep, Glob, Write` — non signalé parce qu'il n'est pas « reviewer », et c'est correct : il *doit* écrire `tech-decisions.md`. Mais `Write` sans restriction de chemin lui permet d'écrire du code de prod, ce que son propre `# Guardrails` interdit. Instruit, pas imposé — à dire dans PHILOSOPHY.md règle #5 comme c'est dit pour `checker`+`Bash`.

**Correctifs (ordre de rendement)** : (1) compter les hooks dans `plugins/*/.claude-plugin/plugin.json` clé `hooks` et refuser tout `.claude/settings.json` versionné à la racine ; (2) remplacer la détection par nom de fichier par une clé frontmatter `role: reviewer` et une allowlist ; (3) vérifier `timeout` dans chaque hook ; (4) câbler `claude plugin validate ./plugins/<nom>` dans `npm test` — c'est le seul validateur qui suit la plateforme, et il n'a toujours pas été câblé depuis que 5.3.1 l'a recommandé.

---

## C — P2 · Dette de cohérence (chaque item : < 30 min)

| # | Fichier | Constat | Correctif |
|---|---|---|---|
| C-1 | `.github/workflows/ci.yml` | Lance `validate.js` + 2 suites, **pas `check-versions.js`**. `npm test` le fait ; la CI le réimplémente à la main et l'oublie. Une dérive de version passe verte sur `main` et n'est attrapée qu'au tag | remplacer les 3 steps par `npm test` |
| C-2 | `.github/workflows/publish.yml:19` | `scope: '@arabiipte'` — résidu du transfert. Le publish 5.4.0/5.5.0 a probablement marché parce que `publishConfig.registry` prime et que l'auth est par hôte, mais le fichier ment sur ce qu'il publie | `scope: '@chakerben'` |
| C-3 | `README.md`, tableau Plugins | `maestro-dev` : « sdlc, plan, implement, review, TDD, debug » — exactement la phrase que CHANGELOG 5.5.0 dit avoir corrigée (« Honest plugin descriptions »). Corrigée dans les manifestes, pas dans le README que GitHub affiche | aligner sur `plugin.json` |
| C-4 | `PHILOSOPHY.md:28` | « Tests → gates of `maestro-vcs:00-commit` and **`maestro-dev:03-review`** » — n'existe pas ; 03 est `brainstorm`, la review est `00-sdlc/actions/04-review` + agent `checker` | corriger la référence |
| C-5 | `README.md`, `MAESTRO-CONTEXT-HANDOFF.md` | « 23 skills » — il y en a **24** depuis 5.5.0. HANDOFF dit aussi « v5.4.0 » et date du 18/07 ; il est gitignoré mais c'est le document « à coller au début de toute nouvelle conversation » | mettre à jour ou supprimer HANDOFF (la mémoire de ce compte le remplace) |
| C-6 | `marketplace.json`, 7 `plugin.json` | `owner.name` / `author.name` = `ARABII` après transfert vers `chakerben`. Pas faux (marque), mais à décider une fois | décider, et l'écrire dans CHANGELOG |
| C-7 | `marketplace.json` | `"recommended": true` sur 3 plugins : **non documenté**, ignoré. Le champ documenté est `defaultEnabled` (ou `relevance`) | remplacer ou retirer |
| C-8 | `marketplace.json` | `"strict": true` ×7 : documenté, mais **valeur par défaut** — bruit | retirer |
| C-9 | `scripts/release-5.4.0.sh`, `scripts/update-projects-5.4.0.sh` | « Script à usage unique : à supprimer une fois la release passée ». La release est passée, `release.sh` et `update-projects.sh` les remplacent ; `release-5.4.0.sh` écrit encore dans `~/.npmrc` et lance `npm deprecate` | supprimer (ils sont dans l'historique git) |
| C-10 | `scripts/release.sh` étape 3 | `BEHIND=$(git rev-list --count HEAD..origin/main)` **sans `git fetch`** — compare à la copie locale de `origin/main`, donc toujours 0 si on n'a pas fetché. `ls-remote` juste avant vérifie la joignabilité, pas l'état. Le push échouera proprement (non-fast-forward), mais le message « rien en retard » est faux | `git fetch origin main` avant |
| C-11 | `scripts/release.sh` | « CI verte, on tague ? » demande à l'humain, ne vérifie pas. `gh run list --branch main -L1 --json conclusion` est à une ligne | optionnel |
| C-12 | `docs/RUNBOOK-v5.4.0.md` | Runbook d'une release faite. Sa dernière section (« prérequis non négociable : exécuter la première feature via /sdlc ») est le seul contenu encore vivant | déplacer cette phrase dans ROADMAP.md, archiver le runbook |
| C-13 | `scripts/tests/bash-guard.test.sh:6` | le harnais construit le JSON par `echo "…\"$2\"…"` : un cas contenant `\` ou `"` casse le JSON et le hook **fail-open → exit 0**, ce qui fait passer un cas « MUST PASS » pour la mauvaise raison. Fonctionne aujourd'hui parce qu'aucun des 34 cas n'en contient | passer par `node -e` + `JSON.stringify` (comme fait pour cet audit) |
| C-14 | `03-condense/SKILL.md` | Skill à effet persistant (« applies to EVERY response until explicitly stopped ») **sans `disable-model-invocation: true`**. Le modèle peut l'auto-déclencher sur « sois plus concis » et rester en mode télégraphique pour la session. `02-release` a la clé pour moins que ça | ajouter la clé |
| C-15 | `00-commit/assets/secret-patterns.md` | `// gate:allow <reason>` désactive le scan sur la ligne. Contredit « never skippable » (c'est une porte, documentée, mais une porte). Et le pattern générique `(api[_-]?key\|secret\|password\|token)\s*[:=]\s*['"]…{16,}` ne matche pas `SECRET_KEY = "…"` en Python (`_KEY` après `secret` : ok ; mais `Secret` capitalisé sans `(?i)` effectif si le moteur est JS : `(?i)` inline n'existe pas en JS) | préciser le moteur regex visé, ou retirer `(?i)` et écrire les deux casses |

---

## D — P3 · Scripts de migration v4→v5 : archiver, pas corriger

Les 32 projets sont migrés depuis juillet (`HANDOFF` : « 0 contrebande »). `migrate-v4-to-v5.sh`, `verify-migration.sh`, `setup-all.sh`, `install-shortcuts.sh` n'ont plus de cas d'usage sauf un nouveau projet v4 — il n'y en aura pas.

État des P1 de 5.3.1 sur ces scripts, vérifié : **P1-1, P1-5 fermés ; P1-3, P1-4, P1-7, P1-8, P1-9, P1-10, P1-12, P1-13, P1-14, P1-15, P1-16 inchangés** (P1-11 `grep "a\|b"` : fonctionne en GNU grep, non vérifié sur BSD grep macOS — `printf 'claude-flow\n' | grep -c "claude-flow\|ruv-swarm"` doit afficher `1` sur le Mac).

Deux options : corriger 11 défauts dans du code qui ne tournera plus, ou déplacer les quatre scripts dans `scripts/archive/v4-migration/` avec un README de trois lignes (« mission accomplie le 2026-07-xx ; défauts connus : voir AUDIT-5.3.1 P1 ; ne pas relancer sur un projet migré »). L'audit recommande la seconde. `MIGRATION-FROM-V4.md` suit le même chemin.

Ce qui reste vivant dans `scripts/` après ça : `validate.js`, `check-versions.js`, `release.sh`, `update-projects.sh`, `tests/`. Cinq fichiers, tous couverts par `npm test` ou par une release réelle.

---

## E — Règle #4 : 9 skills sur 24 sont des routeurs

| Avec `actions/` (9) | Sans (15) |
|---|---|
| core: onboard, memory, gardener, doctor · dev: sdlc, plan, implement, brainstorm · vcs: commit | core: condense · mobile: ×3 · web: ×3 · pm: ×3 · quality: ×3 · vcs: pull-request, release |

Les 27 fichiers d'action ont tous leur `## Test`. Les 15 autres skills ont pour la plupart un `## Test` dans `SKILL.md` directement (security-audit, perf-audit, pull-request, release) ou aucun (les « standards », condense, pm).

Ce n'est pas un défaut de code, c'est un défaut de règle : elle dit « every skill » et le framework la viole à 62 %. Chaque nouvelle skill hérite de l'ambiguïté. Le CHANGELOG 5.5.0 le reconnaît (« 15 of the 23 existing skills still do not honour »). Proposition minimale : réécrire la règle #4 en deux classes — **routeur** (`actions/` obligatoire, `## Test` par action) et **contrat simple** (un seul `## Test` dans `SKILL.md`, obligatoire) — et faire vérifier la seconde par `validate.js`. Les 6 skills sans aucun `## Test` (les trois « standards », condense, prd, user-stories, specs) en reçoivent un.

---

## F — Ce qui est solide (et pourquoi)

- **`memory-sync.js`** : le contrat de sécurité est écrit dans l'en-tête, chaque clause a un test de régression qui reproduit une corruption réelle. C'est le modèle à suivre pour le reste. Deux remarques mineures, non bloquantes : `writeAtomic` crée le fichier avec le umask courant, pas le mode de l'original (un `CLAUDE.md` en `600` repasse en `644`) ; et un `CLAUDE.md` en CRLF reçoit un bloc en LF (le regex tolère `\r`, l'émission non).
- **`03-brainstorm`** : description = conditions de déclenchement, off-ramp explicite, journal avec `Change :`, stop condition falsifiable, quatre sorties dont « dropped ». La seule skill qui documente ses divergences avec sa source.
- **`check-versions.js`** et **`release.sh`** : `set -euo pipefail`, dry-run qui ne prétend rien, bump par parseur, confirmation par phase, rien de destructif. Le seul défaut est C-10.
- **`references/cognitive-protocols.md`** et **`expert-postures.md`** : courts, cités par toutes les skills dev, pas de duplication.
- **La compat bash 3.2** des scripts (pas de `declare -A`, `mapfile`, `${var,,}`) reste propre.
- **La règle #8** est appliquée dans les faits : aucune skill ne réimplémente LSP, security-guidance ou commit-commands.

---

## G — Ordre proposé

Tout tient en une séance, sauf B-2(b) et E qui sont des décisions.

1. **B-1** — deux lignes dans `02-execute.md` et `01-pull-request/SKILL.md`. Avant tout `/sdlc` réel.
2. **C-1, C-2, C-4, C-3, C-5** — dix minutes, zéro risque, et le dépôt cesse de se contredire.
3. **B-2** — décider (a) ou (b). Si (a) : 4 regex + 2 paragraphes.
4. **C-9, C-12, D** — supprimer/archiver. Le dépôt passe de 116 à ~95 fichiers, tous vivants.
5. **B-3** — `validate.js` : les 4 correctifs, dans l'ordre. Ajouter `claude plugin validate` à `npm test`.
6. **E** — réécrire la règle #4 ; 6 `## Test` à écrire.
7. **C-7, C-8, C-6, C-14, C-15, C-13, C-10** — au fil de l'eau.

Puis la première feature réelle via `/sdlc`, journal à l'appui. Tant qu'elle n'a pas eu lieu, tout ce qui précède est de la théorie bien rangée.

---

## Note de méthode

Chaque « confirmé » de ce document a été reproduit dans la session d'audit (commande + sortie), sauf : le timing des hooks (machine différente), `claude plugin validate` (CLI absente de l'environnement d'audit), et le comportement de BSD grep (P1-11). Les trois sont marqués comme tels dans le texte. L'état de la doc officielle a été lu le jour de l'audit et peut bouger — `user-invocable` et `strict` étaient non documentés en août, ils le sont en septembre ; `recommended` ne l'est toujours pas.
