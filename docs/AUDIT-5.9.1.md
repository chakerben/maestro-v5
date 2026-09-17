# Audit adversarial — Maestro 5.9.1 → 5.9.2

> Date : 2026-09-17 · Cible : `main` @ 5.9.1 (les six versions 5.6.0 → 5.9.1 écrites le même jour)
> Méthode : un auditeur **indépendant** (agent séparé, sans accès aux conclusions de l'auteur, avec le code et une consigne de reproduction) a attaqué les cinq surfaces livrées dans la journée. Chaque constat ci-dessous a été reproduit par lui puis re-reproduit par moi avant correction ; chaque correction a un cas de régression dans `npm test`.
> Résultat : **1 P1, 8 P2, 8 P3 — tous corrigés en 5.9.2**, sauf trois P3 documentés comme acceptés. Suites : bash-guard 71 → 95 cas, memory-sync 19 → 25, secret-scan 8 → 14.

## Verdict

Rien dans 5.9.1 ne détruisait un fichier utilisateur — le noyau de `memory-sync.js` a tenu sous attaque (mentions en prose, blocs multiples, symlinks, 40 paires concurrentes, verrou périmé, répertoire en lecture seule). Ce qui a cédé, c'est ce que j'avais écrit trop vite dans la journée : un trou dans `validate.js` (la forme *tableau* de `hooks` dans `plugin.json` n'était pas comptée — trois hooks de contrebande passaient au vert), une suite de tests qui passait **à vide sur macOS** (`md5sum` n'existe pas, les deux côtés de la comparaison étaient vides, donc égaux), et des bords tranchants dans `secret-scan.sh` (config `diff.noprefix` → noms de fichiers perdus ; erreur git → verdict « clean » au lieu de « skipped »).

La leçon, pour la méthode : une release écrite et testée sur GNU/Linux par la personne qui l'a écrite n'est pas auditée. Le test `md5sum` est exactement le cas — vert ici, vide là-bas.

## Constats et corrections

| # | Sév. | Fichier | Défaut (reproduit) | Correction 5.9.2 | Test |
|---|---|---|---|---|---|
| 1 | **P1** | `validate.js` | `hooks: ["./extra.json"]` dans un `plugin.json` (forme documentée) : le tableau était itéré comme un objet, 0 hook compté, 3 hooks PreToolUse passaient au vert | forme string ET tableau refusées, et chaque cible résolue et **comptée** quand même (double filet) | auto-test : 3 ❌ |
| 2 | P2 | `validate.js` | un agent `m-gatekeeper.md` « Reviews and judges work » avec `Write, Edit` passait : ni `role:` ni nom de fichier reconnu | `role:` **obligatoire** sur chaque agent (`reviewer | builder | advisor`) ; heuristique sur la description en plus du nom (« never judges » exclu) | auto-test |
| 3 | P2 | `memory-sync.js` | un exemple `<maestro_routing>` dans un bloc ``` de CLAUDE.md était pris pour LE bloc et réécrit *dans* la fence | masque des régions fencées avant matching ; tags dans une fence = documentation, bloc réel ajouté dehors | cas 15 |
| 4 | P2 | `memory-sync.test.sh` | `md5sum` absent de macOS → cas 4, 5, 10 comparaient `""` à `""` : verts à vide sur la machine où `release.sh` exécute le gate | `shasum -a 1` (présent partout) | — |
| 5 | P2 | `secret-scan.sh` | `diff.noprefix=true` (global fréquent) → `+++ b/` jamais vu, chaque hit rapporté `:N` sans fichier | `--src-prefix=a/ --dst-prefix=b/ --no-ext-diff` forcés | cas 9 |
| 6 | P2 | `secret-scan.sh` | erreur git en mode `branch` avalée → `clean — 0 added line(s)` | code retour capturé → `SECRET SCAN: skipped — git diff failed (…)` | cas 14 |
| 7 | P2 | `m-i18n-checker.md` | précharge `maestro-mobile:01-rtl-i18n` alors que maestro-dev ne dépend pas de maestro-mobile : préchargement pendant sur un projet web sans mobile | `maestro-mobile` ajouté aux dépendances de maestro-dev (l'arabe est le différenciateur ; `mobile-standards` se charge par `paths`, coût nul sur le web) | validate |
| 8 | P2 | `release.sh` | aucune vérification de branche : commit sur la branche courante, `push origin main` pousse l'ancien main, le tag pointe sur un HEAD non poussé | garde `branch --show-current = main` en préflight | — |
| 9 | P2 | `bash-guard.js` | 15 contournements de l'orthographe « canonique » : `rm -rf ~ 2>/dev/null`, `rm -rf "/"`, `rm -rf "$HOME/"`, `$HOME/*`, `~/.`, `$HOME/..`, `rm -rf ~/ /tmp/x`, tabulations, `git push -fu`, `git -c x=y push --force`, `curl | sudo -E bash`, `cat -- .env`, `cat -n .env`, `cat .env.local.bak`, `printf "$SECRET_KEY"` | tous fermés (cibles quotées appariées, `/*` `/.` `/..` sur home, terminateurs redirect/pipe, flags courts combinés, `sudo -X`, options avant `.env`, suffixes multiples, `printf`) | 18 cas |
| 10 | P2 | `bash-guard.js` | faux positifs : `rm -rf node_modules # ~`, `cat README.env.md`, `cat docs/.env.md`, `echo "$TOKEN_LIMIT"` | commentaire `#` retiré avant matching ; `.env` ancré sur un chemin, suffixes doc exclus ; le mot secret doit terminer le nom de variable | 6 cas |
| 11 | P3 | `memory-sync.js` | fichier CRLF → bloc écrit en LF, fins mixtes | EOL détecté, bloc réécrit avec ; regex de fermeture ne consomme plus le `\r` | cas 16 |
| 12 | P3 | `memory-sync.js` | `maestro_docs/memory` **fichier** → `existsSync` vrai → routeur ajouté à un dépôt étranger | `statSync().isDirectory()` | cas 17 |
| 13 | P3 | `secret-scan.sh` | une ligne ajoutée `++i;` ou `+++ b/x` en contenu : sautée, numéros décalés, `FILE` réécrit | en-têtes reconnus seulement après `diff --git`/`---` ; `++…` est du contenu | cas 10, 11 |
| 14 | P3 | `secret-scan.sh` | `break` après le premier pattern : une ligne `gate:allow` portant deux secrets n'en listait qu'un ; `\r` dans la raison | `continue` sur les lignes allow ; `\r` retiré | cas 12, 13 |
| 15 | P3 | `validate.js` | `!`cmd`` en milieu de ligne sans `allowed-tools` passait ; pas de détection de cycle dans `dependencies` | regex `(^|\s)!`` ; parcours de cycle (vcs→quality→vcs détecté) | auto-test |
| 16 | P3 | 8 SKILL.md | `allowed-tools: Bash(git *)…` ne couvre pas `node -e`, `for`, `B=$(…)`, `head`, `wc` utilisés dans les injections ; selon la plateforme, prompt ou abandon | `allowed-tools: Bash` (**turn-scoped**, retombe à l'envoi du message suivant) sur les skills à injection, avec le commentaire qui dit pourquoi | — |
| 17 | P3 | `install-shortcuts.sh` | `git config --global alias.wt` écrivait `~/.gitconfig` sans le dire ; `/menu` pointait vers un id qui n'est pas une skill ; le compte final incluait les commandes non-Maestro | alias en opt-in `--git-alias` ; `/menu` → `/maestro` ; message de compte honnête | — |
| 18 | P3 | `ARCHITECTURE.md` | anatomie sans `scripts/`, `commands/`, `references/` de plugin (dont `routing.md`, lu par le hook) | ajoutés | — |

## Accepté, documenté, non corrigé

- `chmod 0777 /tmp/x` et `chmod 777 -R x` bloqués : par conception d'un garde-fou anti-accident (la commande est rarement légitime, jamais urgente).
- `git push origin +feature:refs/for/x` bloqué : le `+` est un force-push, c'est le comportement voulu ; `--force-with-lease` reste la voie.
- Les contournements de classe `$(…)`/`eval`/script sur disque : hors contrat, dit dans l'en-tête et assertés comme passants dans la suite.

## Ce qui a tenu

Le noyau `memory-sync.js` (appairage, atomicité, verrou, symlinks, 40 paires concurrentes), `secret-scan.sh` sur lignes de 200 Ko / espaces dans les noms / binaires, les 15 patterns POSIX ERE (aucun `\s \d \w \b`, `LC_ALL=C`), la compatibilité bash 3.2 des scripts, la cohérence des références `maestro-x:NN-name` (100 % résolues hors ROADMAP), les compteurs du CHANGELOG et du menu.

## Suite

`npm test` = 8 validateurs/suites, 134 cas. La prochaine release passe par `./scripts/release.sh 5.9.2`, qui refuse désormais de partir hors de `main` — et dont le gate `npm test` ne peut plus être vert à vide sur macOS.
