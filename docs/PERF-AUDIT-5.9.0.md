# Audit performance & tokens — Maestro 5.9.0 → 5.9.1

> Date : 2026-09-17 · Méthode : mesure de chaque octet que le framework injecte dans un contexte (index des skills, bloc de routage, préchargements d'agents, injections `!`, corps des skills et des actions), chronométrage des deux hooks, puis un modèle de coût par session, par dispatch et par feature. Tous les chiffres ci-dessous sont sortis d'un script, pas estimés à l'œil ; le script est devenu `scripts/context-budget.js` et tourne dans `npm test`.
> Conversion : ≈ 3,6 caractères par token sur ce mélange EN/FR/AR/markdown. Ordre de grandeur, pas comptage exact.

## Verdict en une page

Maestro ne coûte pas cher **par session** — environ 3 100 tokens fixes (index des 31 skills 2 641 + bloc de routage 461), soit moins de 2 % d'une fenêtre de 200k. Là où il coûtait, c'était **par dispatch d'agent** : l'executor 5.9.0 préchargeait quatre skills (≈ 4 000 tokens) à chaque phase et à chaque tentative de réparation, dont les standards mobile sur un projet web et les règles RTL sur un projet sans arabe. Sur une feature de cinq phases avec deux réparations, ça faisait ≈ 28 000 tokens de préchargement, dont plus de la moitié hors sujet.

La 5.9.1 corrige ça sans retirer une règle : l'executor précharge `lean-code` seul (≈ 1 300 tokens par dispatch, −66 %), et charge les standards de *sa* stack à la demande — web par `paths`, mobile et RTL par invocation explicite quand la phase ou le projet le demande. Même logique pour le checker et l'architecte. Le bloc de routage est ramené de 901 à 461 tokens en supprimant ce que les descriptions disent déjà. Et surtout : ces nombres ont maintenant un plafond testé — `context-budget.js` fait échouer `npm test` si une description, le routeur, ou un préchargement d'agent dépasse son budget. La dette de contexte ne pourra plus croître en silence, ce qui est exactement ce qui est arrivé entre 5.3 et 5.9.

Les hooks sont hors sujet côté tokens (ils n'en injectent aucun) et dans le contrat côté temps : 12–17 ms sur la machine de mesure, ≈ 40–60 ms sur macOS à cause du démarrage de Node ; le plafond de 100 ms de la règle #3 est maintenant vérifié par le même script.

## 1. Ce que coûte une session (fixe, chaque projet, chaque démarrage)

| Poste | Mesure | Tokens ≈ | Note |
|---|---|---|---|
| Index des skills (31 descriptions) | 9 506 car. | 2 641 | Chargé par la plateforme dans le prompt système. C'est le prix du routage par description — et c'est ce qui rend « texte simple » possible |
| Bloc `<maestro_routing>` | 5.9.0 : 3 244 car. → **5.9.1 : 1 659** | 901 → **461** | Dupliquait les descriptions. Ne garde que ce qu'une description ne peut pas dire : chemins par défaut, règles always-on, état |
| Bloc `<maestro_memory>` (tier 1, `@`-imports) | par projet | 0 – ~3 000 | Budget gardener : ≤ 200 lignes. Non mesurable ici ; `02-gardener/01-measure` le fait par projet |
| Commande `/maestro` | 757 | 0 | Seule sa description est indexée ; le corps ne se charge qu'à l'appel |
| **Total fixe Maestro** | | **≈ 3 100** | + la mémoire du projet |

Ce qui ne coûte rien tant qu'on ne l'appelle pas : les corps des skills (21 000 tokens au total), les actions (12 300), les références. La disclosure progressive fonctionne : un routeur lit `SKILL.md` puis **une** action à la fois.

## 2. Ce que coûte un dispatch d'agent (le vrai poste)

| Agent | 5.9.0 | 5.9.1 | Ce qui a changé |
|---|---|---|---|
| executor | 3 987 tok | **1 336** | précharge `lean-code` seul ; web-standards/ux-standards s'activent par `paths` sur les fichiers touchés ; mobile-standards et rtl-i18n invoquées quand la phase est Expo/Flutter ou que le projet a `ar` |
| checker | 2 858 | **1 518** | rtl-i18n invoquée seulement si `ar` ; `lean-code` gardée (il cite les rungs) |
| m-architect | 2 155 | **1 166** | standards de la stack invoquées avant de proposer une structure |
| m-i18n-checker | 1 421 | 1 421 | garde rtl-i18n : c'est son unique travail |
| m-devil-advocate | 376 | 376 | — |

Modèle sur une feature `/sdlc` de 5 phases, 2 réparations, 1 review qui itère une fois :

| | 5.9.0 | 5.9.1 |
|---|---|---|
| executor : 7 dispatches × préchargement | 27 900 | 9 350 |
| checker : 2 dispatches | 5 700 | 3 000 |
| **Préchargement total** | **≈ 33 600** | **≈ 12 400 (−63 %)** |

Ce qui reste dans un dispatch et n'est pas du framework : le fichier de phase, l'objectif du plan, les références mémoire, la posture experte — c'est le contenu utile, il ne bouge pas.

`maxTurns` de l'executor : 60 → 40. Une phase tient en ≤ 5 fichiers par construction (`01-plan`), et la boucle de réparation redispatche à neuf ; 60 tours dans un seul dispatch, c'est une phase qui tourne en rond, pas une phase qui travaille.

## 3. Injections `!` (à l'invocation seulement)

| Skill | Injections | Coût typique | Borné par |
|---|---|---|---|
| 00-commit | 4 | 100–400 tok | `--stat \| tail -20`, verdict du scan (1 ligne + hits) |
| 01-pull-request | 3 | 100–600 | `git log \| head -30`, scan de branche |
| 04-doctor | 4 | 200–800 | `grep -A3 @maestro`, `ls \| head -20` |
| 03-store-release | 3 | ~100 | une ligne par item |
| 02-release, 00-quality-gate, 03-ticket, 04-debug | 1–2 | < 200 | `head`, `describe`, `ls` |

Toutes bornées par un `head`/`tail`/`grep` ; aucune ne peut vider un `git log` complet dans le contexte. Rien à changer.

## 4. Corps des skills — les trois qui comptent

`05-lean-code` est la seule skill payée à **chaque** dispatch : 1 098 → **754 tokens** (même règles, moins de prose). `04-writing` (1 057) et `03-ticket` (1 042) ne sont payées qu'à l'appel — laissées telles quelles. Les trois plus longues descriptions (brainstorm 504, ticket 496, debug 459 car.) restent sous le plafond de 700 : leurs clauses « Not for… » évitent des mauvais routages qui coûteraient bien plus qu'une centaine de caractères.

## 5. Hooks — temps, pas tokens

| Hook | Ici (Linux, Node 22) | macOS attendu | Contrat |
|---|---|---|---|
| memory-sync (SessionStart) | 15–17 ms | 40–70 ms | < 100 ms, fail-open |
| bash-guard (PreToolUse Bash) | 12–13 ms | 40–60 ms | même chose |

Le plancher est le démarrage de Node (`node -e ''` ≈ 10 ms ici, ≈ 45 ms sur macOS). Réécrire bash-guard en shell pur gagnerait ~30 ms par commande Bash au prix d'un parseur JSON en bash — refusé : le gain est invisible à l'usage et le risque est un hook qui se trompe. `context-budget.js` mesure les deux à chaque `npm test` et échoue au-delà de 100 ms.

## 6. Le garde-fou — `scripts/context-budget.js`

| Budget | Valeur | Ce qu'il empêche |
|---|---|---|
| index des descriptions | 11 000 car. | 31 skills à 9 506 aujourd'hui ; ~5 skills de marge avant de devoir raccourcir |
| description unitaire | 700 car. | une description qui devient un corps (la plateforme tronque à 1 536) |
| routing.md | 2 000 car. | le routeur qui regrossit à chaque release |
| skill préchargée | 4 000 car. | une règle always-on qui s'allonge sans qu'on le voie |
| agent : corps + préchargements | 6 000 car. | le retour des 4 000 tokens par dispatch |
| SKILL.md unitaire | 5 500 car. | un contrat qui aurait dû être un routeur avec actions |
| hook | 100 ms | règle #3, mesurée |

Il imprime la facture même quand tout passe, pour qu'on la voie à chaque test.

## 7. Ce qui n'a pas été touché, et pourquoi

- `effort: high` sur checker, architecte, brainstorm, plan, security-audit : c'est du raisonnement acheté là où une erreur coûte une itération entière. `04-writing` et `condense` sont en `low`, `executor` en `medium`.
- Le checker en opus, jusqu'à 3 reviews par feature : par conception (règle #5). Une review sonnet qui laisse passer un défaut coûte plus que la différence.
- Les descriptions en trois langues : c'est ~15 % de l'index, et c'est ce qui fait que « ما يشتغل » route vers `04-debug`. Non négociable pour ce marché.
- La mémoire tier-1 : hors périmètre de ce dépôt, budgetée par le gardener projet par projet.

## 8. Ce qu'il reste à mesurer sur ta machine

Trois nombres que seul un vrai projet donne : la taille réelle du tier-1 mémoire d'un projet réel (`/maestro-core:02-gardener measure`), le temps réel des hooks sur macOS (`time node plugins/maestro-core/hooks/memory-sync.js` dans un projet), et le coût observé d'un `/sdlc` complet (`/cost` en fin de session). Si le troisième dépasse ~150k tokens pour une feature de 5 phases, le suspect est le contenu des phases, pas le framework — et `01-plan` a une règle pour ça (≤ 5 fichiers par phase).
