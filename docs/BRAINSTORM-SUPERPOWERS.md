# Superpowers × Maestro — brainstorm

**Date** : 2026-08-01 · **Source** : `github.com/obra/superpowers` v6.2.0 (cloné, lu intégralement :
14 SKILL.md, hooks, tests, docs, manifestes multi-runtime, 1 361 lignes de RELEASE-NOTES)
**Cadre** : règle #7 — *« Superpowers, GSD, AIDD sont des sources dont on absorbe des idées,
jamais des couches qu'on empile. »*

---

## 0. Le constat qui structure tout le reste

Superpowers et Maestro ne se recouvrent presque pas.

- **Superpowers est une colonne vertébrale de processus** : *comment* travailler. 14 skills,
  zéro couverture métier. Aucun fichier ne mentionne i18n, RTL, accessibilité, mobile,
  sécurité, PM, release, CI, migrations. C'est délibéré — son `CLAUDE.md` refuse par principe
  les « domain-specific skills ».
- **Maestro est une couche métier + un corpus de connaissances** : *quoi* savoir. RTL arabe,
  Hijri, SAR, KSA, stack Next.js/Prisma/Clerk, PRD/stories/specs. Son processus (sdlc → plan →
  implement → review) existe, mais **n'a jamais tourné en réel** et n'a aucun mécanisme derrière
  ses règles.

Autrement dit : **Superpowers est fort exactement là où Maestro est faible, et vide exactement
là où Maestro est fort.** C'est la configuration qui donne le plus envie d'empiler — et c'est
précisément pour ça que la règle #7 doit tenir. La suite explique pourquoi l'empilement casse
concrètement, et ce qu'on prend à la place.

---

## 1. Comparaison

| | **Maestro 5.3.1** | **Superpowers 6.2.0** |
|---|---|---|
| Nature | couche métier + processus | colonne vertébrale de processus |
| Skills | 23 (dont 8 avec `actions/`) | 14, toutes avec un état terminal explicite |
| Agents déclarés | 5, model-pinnés, `tools:` restreints | **0** — les rôles sont des templates markdown |
| Commandes | 1 (`/maestro`) + 20 raccourcis perso | **0** |
| Hooks | 2 (SessionStart écriture fichier, PreToolUse regex) | **1** (SessionStart, `cat` d'un fichier) |
| Dépendances runtime | node (2 hooks), python3 (scripts) | **aucune** (`package.json` sans `dependencies`) |
| Taille | 100 fichiers, 170 Ko | 180 fichiers, 2,2 Mo |
| Tests | 34 cas bash-guard + 10 memory-sync (depuis aujourd'hui) | 2 400 lignes de tests node sur l'infra + 4 tests de déclenchement de skill |
| Rythme | 8 versions en 2 jours (14/07), puis 2 | 54 versions en 9 mois, ~3/mois |
| Portabilité | Claude Code uniquement | 8 runtimes (Claude Code, Cursor, Codex, Kimi, Gemini, OpenCode, Pi, Copilot) |
| Couverture métier | RTL/AR, mobile, web, PM, sécurité, perf, release | **aucune** |
| Mécanique de processus | déclarée dans les SKILL.md, non outillée | outillée : ledger, scripts, templates, budgets de contexte |

### Trois constats

**(a) Les deux sur-promettent leur application — mais pas de la même façon.**
Le README de Superpowers dit *« Mandatory workflows, not suggestions »* ; il n'existe aucun hook,
validateur ou garde d'outil dans tout le dépôt qui puisse empêcher un agent de sauter une skill.
C'est exactement la critique que je faisais à `validate.js`. La différence : Superpowers paie
cette dette en **évaluations chiffrées** (« control 8/10 → treatment 5/10 », « 50/50 runs »)…
dans un dépôt séparé, gitignoré, non reproductible depuis le clone public. Maestro, lui, n'a
mesuré rien du tout jusqu'à l'audit d'aujourd'hui.

**(b) La différence de rythme est le vrai écart de maturité.**
Maestro a été construit en un sprint (5.0.0 → 5.3.1 le 14/07) puis figé. Superpowers a 54
versions dont les notes documentent des régressions trouvées **en usage réel** : *« un run a mis
ses 26 reviewers sur le tier le plus cher »*, *« une dispatch réelle a atteint 42 k caractères
dont 99 % d'historique collé »*, *« des controllers ayant perdu leur place ont re-dispatché des
séquences entières de tâches — l'échec le plus coûteux observé »*. Chaque règle de Superpowers
a un cadavre derrière elle. Maestro a exactement un cadavre — le crash du 13/07 — et il a produit
ses 8 meilleures règles. Le jalon `/sdlc` en réel n'est pas une case à cocher : c'est la
condition pour que la v5.4 soit écrite à partir de faits.

**(c) L'hygiène d'ingénierie de Superpowers est nettement au-dessus.**
`.version-bump.json` déclare 7 fichiers et le chemin JSON de la version dans chacun ;
`bump-version.sh --audit` grep tout le dépôt à la recherche de versions périmées. Maestro porte
`5.3.1` dans 9 endroits à la main — et le CHANGELOG 5.2.1 documente déjà un incident
d'alignement de versions. Le `hooks/run-hook.cmd` est un polyglotte cmd/bash pour que le même
fichier tourne sous Windows et sous bash. `.gitattributes` épingle LF sur les scripts pour que
ça marche.

**Là où Maestro gagne** : agents déclarés et model-pinnés (Superpowers colle un modèle en
placeholder dans un template, avec l'avertissement *« un modèle omis hérite silencieusement du
plus cher de la session »* — Maestro n'a pas ce problème) ; profondeur métier ; et une doctrine
écrite qui se relit.

---

## 2. Ce qu'il faut absorber — 12 mécanismes, classés par valeur pour Maestro

Critère de tri : ce qui répare un manque **déjà identifié** dans Maestro, pas ce qui est joli.

### Rang 1 — L'économie de contexte (répare `02-implement`, qui n'a aucun mécanisme)

`02-implement/SKILL.md` promet *« chaque phase est dispatchée à un contexte executor FRAIS ne
portant que : le fichier de phase, l'objectif, les références mémoire, la posture »*. C'est une
intention sans outil : rien ne garantit qu'on ne colle pas le plan entier.

**1. Les artefacts circulent en chemins de fichier, jamais en texte collé.**
`skills/subagent-driven-development/scripts/task-brief` extrait **une** tâche du plan vers un
fichier (20 lignes d'awk qui suit les clôtures ``` pour ne pas matcher un `### Task N` dans un
bloc de code) ; `review-package` écrit `git log` + `--stat` + `git diff -U10` d'un intervalle
dans un fichier unique. Le dispatch contient le **chemin**. Justification citée :
*« tout ce que vous collez dans un prompt de dispatch — et tout ce qu'un subagent renvoie —
reste résident dans votre contexte pour le reste de la session, et est relu à chaque tour. »*
→ **Deux scripts de ~20 lignes dans `maestro-dev/skills/02-implement/scripts/`.** C'est le vol
le plus rentable du lot.

**2. Le subagent renvoie moins de 15 lignes.** Le rapport long va dans
`task-N-report.md` ; le retour est un statut (`DONE | DONE_WITH_CONCERNS | BLOCKED |
NEEDS_CONTEXT`), les commits, une ligne de tests, les réserves, le chemin du rapport.
→ à écrire dans `02-execute.md` comme contrat de retour de l'executor.

**3. Le ledger, et la règle anti-amnésie.** `<repo>/.superpowers/sdd/<plan>/` (auto-ignoré par
un `.gitignore` contenant `*`) porte un ledger dont la règle de reprise est binaire : une tâche
est faite **si et seulement si** le ledger contient `Task N: complete`. Et surtout :
*« Après compaction, faites confiance au ledger et à `git log` plutôt qu'à votre souvenir. »*
→ Maestro a déjà le frontmatter `status:`, qui est l'équivalent — **il manque juste la phrase**.
Le scénario « je re-dispatche une phase déjà faite après compaction » n'est nulle part interdit
dans `02-execute.md`.

### Rang 2 — L'intégrité de la revue (répare `04-review` et `checker`)

**4. `BASE` enregistré avant le dispatch, jamais `HEAD~1`.** Répété trois fois dans le dépôt :
*« jamais `HEAD~1`, qui laisse silencieusement tomber tous les commits d'une tâche sauf le
dernier. »* Maestro dispatche le checker avec « le diff », sans définir contre quoi.
→ une ligne dans `sdlc/04-review.md` et dans `02-execute.md`.

**5. La règle anti-préjugement des prompts de revue.**
*« Si le prompt que vous écrivez contient "ne signale pas", "ne traite pas X comme un défaut",
"au pire Mineur", ou "le plan a choisi" — arrêtez : vous préjugez, en général pour vous épargner
une boucle de revue. »* C'est le contre-poison exact du problème structurel de Maestro : c'est
l'orchestrateur qui rédige le prompt du checker.
→ dans `04-review.md`, verbatim.

**6. « Ne faites pas confiance au rapport ».** Le reviewer reçoit :
*« les justifications de conception dans le rapport sont aussi des affirmations… une raison
invoquée ne réduit jamais la gravité d'un constat. »*
→ dans `checker.md`, à côté de « Demand command output or file evidence, never bare claims »
qui s'arrête à mi-chemin.

**7. Boucle de réparation bornée + adjudication explicite au plafond.** 5 rounds ; rounds 1-3
sur le même implémenteur, 4-5 sur un implémenteur neuf et un modèle plus capable avec le cadrage
*« un implémenteur précédent a tenté cette tâche N fois ; elle est à vous maintenant »* ; au
plafond, trois issues seulement — parquer (contestable), parquer (réel mais non porteur),
BLOQUÉ — et *« chaque adjudication est une entrée de ledger ; un abandon silencieux est
interdit »*. Maestro a « max 3 tentatives puis blocked » : il manque **l'escalade de modèle** et
**l'interdiction de l'abandon silencieux**.

**8. Une seule vague de correction après la revue finale.** *« la vague de correction de la
revue finale d'une session réelle a coûté plus que toutes ses tâches réunies. »*
→ à ajouter dans `04-review.md` : findings groupés, un dispatch, une re-revue ciblée, pas de
deuxième vague.

### Rang 3 — L'authoring et la mesure (répare le trou « 15 skills sans `actions/` » et la roadmap v5.3)

**9. « La description n'est pas un résumé du workflow ».** `writing-skills/SKILL.md`, avec sa
preuve : *« une description disant "revue de code entre les tâches" a fait faire UNE revue à
l'agent, alors que le flowchart de la skill en montrait clairement DEUX… Le piège : les
descriptions qui résument le workflow créent un raccourci que les agents emprunteront. Le corps
de la skill devient de la documentation que les agents sautent. »*
→ Ça explique **pourquoi 15 skills Maestro sans `actions/` est dangereux** et pas seulement
inélégant : quand tout tient dans le SKILL.md, le modèle traite le SKILL.md comme le livrable.

**10. « Adapter la forme à l'échec », et les interdictions qui se retournent.** Table à 4
entrées type d'échec → forme de consigne correcte. Résultat mesuré : *« dans des tests A/B de
formulation, le bras "interdiction" a produit nettement plus du contenu non voulu que le bras
"recette" (distributions totalement séparées), et a même fait moins bien que le contrôle sans
consigne. »* Plus deux corollaires : *« pas de clauses de nuance »* et *« les clauses d'exemption
ne cadrent rien : "cette limite ne s'applique pas aux blocs de code" supprime quand même les
blocs de code. »*
→ Maestro est écrit majoritairement en interdictions (« Never », « no », « jamais »). C'est le
constat qui pourrait faire gagner le plus de qualité de sortie, pour zéro ligne de code.

**11. Les tests de déclenchement de skill, qui grep le flux d'appels d'outils.**
`tests/explicit-skill-requests/run-test.sh` lance
`claude -p "$PROMPT" --plugin-dir "$DIR" --output-format stream-json` dans un projet temporaire,
puis assert sur le JSON : présence d'un appel `Skill` **et** — la partie intéressante —
qu'**aucun outil non-`Skill` n'a été appelé avant lui**, ce qui attrape le cas où l'agent commence
à travailler avant de charger la skill.
→ **C'est le `skill-eval harness` déjà inscrit dans `docs/ROADMAP.md` pour v5.3.** Une
implémentation qui marche existe, en bash, en ~60 lignes. À reprendre tel quel.

**12. Micro-tester une formulation avant de l'écrire.** Cinq règles mécaniques : un échantillon
par appel en contexte frais ; **toujours un contrôle sans consigne** (*« si le contrôle ne
présente pas l'échec, il n'y a rien à corriger — arrêtez, n'écrivez pas la consigne »*) ; 5
répétitions minimum ; relire chaque match à la main (*« les échos de template et les
contre-exemples cités se font passer pour des occurrences »*) ; et **la variance est une
métrique** : *« cinq interprétations différentes sur cinq répétitions, c'est que la formulation
n'est pas contraignante. »*

**Bonus hors classement** : `.version-bump.json` + `bump-version.sh --audit` → à intégrer dans
`maestro-vcs:02-release`, Maestro ayant 9 fichiers portant la version à la main.

---

## 3. Ce qu'il faut explicitement refuser

| Élément | Pourquoi non |
|---|---|
| **Le bootstrap SessionStart** (`cat` d'une skill dans chaque session, ~800 tokens, à chaque `clear` et chaque compaction) | Maestro occupe déjà ce créneau avec `memory-sync`. Deux injections se disputent la même autorité, avec des ordres de priorité contradictoires. Et c'est du contexte permanent payé à chaque tour |
| **Le HARD-GATE de `brainstorming`** — *« la SEULE skill que vous invoquez après brainstorming est writing-plans »*, avec `frontend-design` et `mcp-builder` nommément interdits | Suppression par nom de skills d'autres plugins. Incompatible frontalement avec la règle #8 (« ne jamais reconstruire ce qu'Anthropic maintient » suppose de pouvoir composer avec) |
| **`dispatching-parallel-agents` sans plafond** — « un agent par domaine de défaillance indépendant », aucune limite écrite | C'est la forme du crash v4 remontée d'un étage : d'un `tsc` non borné à des subagents non bornés. Si on absorbe quoi que ce soit de cette skill, on absorbe un plafond chiffré |
| **Le commit non sollicité dans `.gitignore`** (`using-git-worktrees` : *« si non ignoré : ajoutez au .gitignore, committez le changement, puis continuez »*) | Un plugin ne committe pas dans le dépôt d'un client sans demander |
| **`receiving-code-review`** (étiquette : « ne jamais dire merci ») | De la prose comportementale sans artefact ni garde. Coût en contexte, gain nul |
| **Installer Superpowers à côté de Maestro** | La comparaison ci-dessus est l'argument : bootstrap concurrent, hard-gate nommant d'autres plugins, espace de noms de skills plat (`brainstorming`, `test-driven-development` sont des noms génériques). La règle #7 n'est pas de la superstition post-traumatique, elle est mécaniquement justifiée ici |

---

## 4. Protocole de test réel — bac à sable

Précision d'honnêteté : j'ai lu tout le code de Superpowers, mais je ne peux pas le lancer dans
**ton** Claude Code. Ce qui suit est le protocole à exécuter toi-même, conçu pour qu'aucun de
tes 32 projets ne soit exposé.

**Garde-fous**

1. Dépôt neuf et jetable, hors `~/Documents/Projects` : `mkdir -p ~/tmp/sp-lab && cd ~/tmp/sp-lab && git init`.
2. Maestro désactivé au scope projet dans ce dépôt (`.claude/settings.json` → `enabledPlugins` vide).
   Objectif : observer Superpowers **seul**, pas un empilement.
3. Rien d'installé au scope `user`. `claude plugin install superpowers@superpowers-marketplace --scope project` uniquement.
4. Ne pas lancer le compagnon visuel de brainstorming au premier passage : c'est un serveur
   HTTP+WebSocket en `nohup`, avec une image distante `primeradiant.com` (désactivable par
   `SUPERPOWERS_DISABLE_TELEMETRY=1`). Optionnel, à évaluer séparément.

**Ce qu'on mesure — 4 chiffres, une feature jouet** (par exemple « un convertisseur SAR ↔ USD
avec formatage arabe », qui a l'avantage de tomber pile dans le trou métier de Superpowers)

| Mesure | Comment | Pourquoi ce chiffre |
|---|---|---|
| **Déclenchement** | prompt « Let's make a react todo list » — `brainstorming` doit s'invoquer seule, sans qu'aucun outil ne tourne avant | c'est le test d'acceptation de leur propre doc de portage ; s'il échoue, tout le reste est décoratif |
| **Coût par session** | `/context` juste après le SessionStart, avant tout prompt | quantifie les ~800 tokens du bootstrap, à comparer au coût de ton bloc `<maestro_memory>` |
| **Nombre de subagents** | compter les dispatches sur une feature à 3 tâches | vérifie le plafond théorique (jusqu'à 12 invocations par tâche) contre le réel, et donc l'ordre de grandeur de la facture |
| **Empreinte disque** | `git status` + `ls -a` après la run | attend : `docs/superpowers/specs/*`, `docs/superpowers/plans/*` **committés**, `.superpowers/`, `.worktrees/`, et un éventuel commit dans `.gitignore` |

**Le test qui compte vraiment** — le même prompt, deux fois :
« ajoute le support arabe RTL à cet écran ». Superpowers n'a aucune skill i18n : on observe ce
que produit une colonne vertébrale de processus sans corpus métier. C'est la mesure directe de
ce que vaut la partie de Maestro qu'il ne faut surtout pas jeter.

**Sortie** : `nodels` avant/après (aucun process fantôme toléré), puis
`claude plugin uninstall superpowers` et `rm -rf ~/tmp/sp-lab`. Une page de notes → alimente
la décision v5.4.

---

## 5. Maestro sous Cowork

**La bonne nouvelle : le format est déjà le bon.** Un plugin Cowork utilise exactement le même
schéma que Claude Code — `.claude-plugin/plugin.json`, `skills/<nom>/SKILL.md`, `agents/*.md`,
`.mcp.json`, `${CLAUDE_PLUGIN_ROOT}`. La différence est de **distribution** (un fichier `.plugin`,
c'est-à-dire un zip, installé depuis le chat, pas un marketplace git) et d'**usage** : Cowork est
un outil de travail documentaire, pas un terminal.

Ce qui change les priorités :

| Composant Maestro | Sous Cowork |
|---|---|
| `maestro-pm` (PRD, user stories, specs) | **Transfert direct, et c'est le meilleur candidat.** Ce sont des livrables documentaires — exactement le terrain de Cowork. Et les connecteurs (Gmail, Drive, Calendar) donnent ce que Claude Code n'a pas : le PRD peut lire les vrais échanges client au lieu d'interviewer à vide |
| `01-rtl-i18n`, `02-pdf-rtl` | Transfert direct. Ce sont des corpus de connaissance, pas des workflows git. Le `02-pdf-rtl` prend même de la valeur : générer une facture arabe correcte est une tâche Cowork typique |
| `00-web-standards`, `00-mobile-standards`, `01-ux-standards` | Transfèrent, mais leur public est un développeur. Utilité réelle limitée sauf pour la revue de specs |
| `maestro-dev` (sdlc, plan, implement) | **Ne transfère pas.** Sans branches, commits et boucle de build, le pipeline n'a pas de sol |
| `maestro-vcs`, `maestro-quality` | Ne transfèrent pas (git, gates de commit) |
| `maestro-core` (onboard, memory, gardener, doctor) | Partiellement. Cowork a **sa propre mémoire projet persistante** — la reconstruire violerait la règle #8. Le `gardener` (mesure du poids de contexte, détection de contradictions) garde du sens ; le reste non |
| Les 2 hooks | À laisser. Les hooks sont explicitement « rarement utilisés » côté Cowork, et ce sont les deux pièces les plus fragiles du framework |

**La forme que ça prendrait** : un plugin unique, `maestro-docs` ou `arabii-ksa`, 6-7 skills —
PRD, user stories, specs, RTL/i18n, PDF arabe, conformité KSA (TVA, résidence des données,
Hijri), design review. Zéro hook, zéro commande, packagé en `.plugin`. Si tu veux le distribuer
hors ARABII, le motif `~~` (`~~project tracker` au lieu de « Jira ») + un `CONNECTORS.md` rendent
le plugin agnostique de l'outillage client.

**Et l'idée qui vaut peut-être plus que tout le reste** : c'est un produit vendable. Une couche
KSA/arabe pour Cowork — factures conformes, documents bilingues, dates Hijri, PDF arabe qui ne
casse pas — n'existe pas sur le marché, et c'est exactement ce que tu as déjà écrit. Maestro l'a
enfoui dans un framework de développement que toi seul utilises.

**Portabilité, en prime** : Superpowers montre le patron pour ça — un seul corpus de skills,
N adaptateurs minces (un manifeste, un injecteur de bootstrap, une table de correspondance
d'outils par runtime), avec l'invariant écrit noir sur blanc dans `docs/porting-to-a-new-harness.md` :
*« les skills nomment des actions, jamais des outils »*. C'est la condition pour qu'un même
`01-rtl-i18n` serve Claude Code et Cowork sans fork.

---

## 6. Proposition de roadmap

**v5.3.2 — fiabilité** *(fait aujourd'hui : memory-sync, backups de migration, règle #5 honnête,
suite de régression)*. Reste : `validate.js` (marcher depuis la racine, allowlist reviewer par
frontmatter, câbler `claude plugin validate`), et la décision `bash-guard` — requalifier ou
tokeniser.

**v5.4 — mécanique de processus** (le lot Superpowers, aucun code métier)
1. `task-brief` + `review-package` dans `02-implement/scripts/` (rang 1, #1)
2. Contrat de retour < 15 lignes de l'executor (#2) ; règle anti-amnésie post-compaction (#3)
3. `BASE` avant dispatch (#4) ; règle anti-préjugement (#5) ; « ne faites pas confiance au
   rapport » (#6) ; escalade de modèle + interdiction de l'abandon silencieux (#7) ; une seule
   vague de correction finale (#8)
4. `skill-eval harness` repris de `tests/explicit-skill-requests/` (#11) — sort de la roadmap
   v5.3 où il dort depuis juillet
5. `.version-bump.json` + `--audit` dans `02-release`

**v5.4 — dette doctrinale**
6. Trancher la règle #4 : `actions/` obligatoire, ou deux catégories de skills assumées dans
   PHILOSOPHY.md (avec l'argument #9 à l'appui)
7. Passe de réécriture « interdiction → recette » sur les skills les plus prescriptives (#10),
   validée par micro-tests avec contrôle (#12)

**Prérequis à tout ça, et non négociable** : **une vraie feature via `/sdlc`**, puis le bac à
sable Superpowers. Absorber des mécanismes conçus pour des échecs qu'on n'a pas encore rencontrés,
c'est refaire l'erreur de la v4 — empiler de la machinerie par anticipation. Superpowers a 54
versions de cadavres derrière ses règles. Maestro en a un seul, et il a produit ses 8 meilleures.

---

**Sources** : [obra/superpowers](https://github.com/obra/superpowers) ·
[obra/superpowers-marketplace](https://github.com/obra/superpowers-marketplace) ·
[« Superpowers: How I'm using coding agents »](https://blog.fsck.com/2025/10/09/superpowers/)
