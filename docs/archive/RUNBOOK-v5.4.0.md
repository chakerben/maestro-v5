# Runbook — publication 5.4.0 + transfert vers `chakerben`

## Où on en est

**Local et distant sont au même point.** `HEAD` = `origin/main` = `04bd136`, tag `v5.3.1`,
dernier push le 14/07/2026. Il n'y a donc pas deux versions divergentes : le dépôt GitHub est
en 5.3.1, ton clone était en 5.3.1, et tout ce qui s'y ajoute est le travail d'aujourd'hui,
non committé.

Un bémol d'honnêteté : le pont vers ta machine n'a pas de réseau, je lis donc le **dernier état
connu** de `origin/main` (ton reflog), pas GitHub en direct. Comme tu es le seul à pousser, c'est
sûr à 99 % — la commande de vérification est en étape 0.

**Ce qui change avec 5.4.0**

| | avant | après |
|---|---|---|
| Version (9 manifestes) | 5.3.1 | **5.4.0** |
| Dépôt | `arabiipte/maestro-v5` | **`chakerben/maestro-v5`** |
| Package npm | `@arabiipte/maestro` | **`@chakerben/maestro`** |
| Nom du marketplace | `maestro` | **`maestro`** (inchangé) |
| `enabledPlugins` des 32 projets | `maestro-core@maestro`… | **inchangé** |

Le dernier point est le plus important : parce que le **nom** du marketplace ne bouge pas, les
32 projets migrés n'ont rien à changer. Seul le chemin d'où le marketplace est tiré change.

**Le piège à connaître** : un transfert de dépôt GitHub met en place une redirection d'URL, mais
**un scope npm ne suit pas un transfert**. `@chakerben/maestro` est un package neuf qui démarre
à 5.4.0 ; `@arabiipte/maestro` garde les 5.3.x et la v4 archivée. J'ai aussi mis à jour le champ
`repository` de `package.json` — GitHub Packages refuse la publication s'il ne pointe pas vers
le dépôt qui publie, et c'est l'erreur la plus fréquente sur ce chemin.

---

## Étape 0 — pré-vol (2 min)

```bash
cd ~/Documents/maestro-v5-work/maestro
rm -f .git/index.lock                 # résidu de mon inspection, git refusera de committer sinon
git fetch origin && git status -sb    # doit afficher : ## main...origin/main  (sans ahead/behind)
npm test                              # doit être vert : versions + validate + 34 + 10
```

Si `git status -sb` affiche `behind`, arrête-toi et dis-le moi : quelqu'un d'autre a poussé.

Vérifie aussi que `github.com/chakerben/maestro-v5` **n'existe pas déjà** — un dépôt de même nom
sur le compte cible fait échouer le transfert.

---

## Étape 1 — committer (local)

```bash
git add -A
git commit -m "feat: v5.4.0 — audit fixes + transfert vers chakerben

- memory-sync: bloc matché par paire ancrée, abandon si ambigu, écriture
  atomique sous lock, noms validés, symlinks ignorés
- migrate-v4-to-v5: settings.json/CLAUDE.md/memory-bank sauvegardés,
  garde sur les options inconnues
- PHILOSOPHY #5: distingue ce qui est enforcé de ce qui est instruit
- tests: suite memory-sync (10 cas) + garde anti-dérive de version
- owner: arabiipte -> chakerben (repo + scope npm)"
```

`MAESTRO-CONTEXT-HANDOFF.md` sera inclus (il est encore non versionné) — c'est ton document de
passation, à toi de voir si tu le veux dans le dépôt public.

---

## Étape 2 — transférer le dépôt sur GitHub

Interface : `Settings` → tout en bas, `Danger Zone` → `Transfer ownership` → nouveau owner
`chakerben` → taper le nom du dépôt pour confirmer.

Si `arabiipte` est une **organisation**, le transfert vers un compte perso génère une invitation
que tu dois accepter côté `chakerben` (Notifications, ou l'e-mail).

**Ce qui ne suit pas le transfert et qu'il faut re-vérifier après :**

- les **secrets et variables d'Actions** — `publish.yml` n'utilise que `secrets.GITHUB_TOKEN`,
  qui est automatique, donc a priori rien à refaire ; vérifie quand même
  `Settings → Actions → General` que les workflows sont autorisés à tourner ;
- les **collaborateurs** hérités de l'org ;
- les **packages publiés** — ils restent sous `arabiipte`, par conception.

---

## Étape 3 — repointer et pousser

```bash
git remote set-url origin https://github.com/chakerben/maestro-v5.git
git remote -v                       # vérifie
git push origin main
```

Attends que la CI passe au vert sur `main` **avant** de taguer. `npm test` y inclut désormais la
garde de version, donc un désalignement se voit ici et pas au moment de publier.

---

## Étape 4 — taguer et publier

```bash
git tag -a v5.4.0 -m "Maestro 5.4.0 — audit fixes + owner move"
git push origin v5.4.0
```

`publish.yml` se déclenche sur `v*` : il lance `npm test` (qui vérifie maintenant que le tag
`v5.4.0` et `package.json` disent la même chose) puis `npm publish` sous `@chakerben` avec
`GITHUB_TOKEN`.

Suis le run dans l'onglet Actions. Si `npm publish` échoue en 403/404, les deux causes sont
presque toujours : `repository.url` de `package.json` qui ne pointe pas vers le dépôt qui publie
(corrigé), ou `permissions: packages: write` absent du workflow (présent).

---

## Étape 5 — ta machine

```bash
# nouveau scope dans ~/.npmrc (garde la ligne de token existante)
grep -q '@chakerben:registry' ~/.npmrc || \
  echo '@chakerben:registry=https://npm.pkg.github.com' >> ~/.npmrc

# le marketplace : essaie d'abord la redirection
claude plugin marketplace update maestro
claude plugin list          # les 7 plugins doivent apparaître en 5.4.0
```

Si `update` échoue (la redirection GitHub n'est pas un contrat), repointe proprement :

```bash
claude plugin marketplace remove maestro
claude plugin marketplace add chakerben/maestro-v5
```

Le nom recréé est le même (`maestro`), donc les `enabledPlugins` des 32 projets se rebranchent
seuls. Fais-le quand même sur **un projet pilote d'abord**, pas les 32 en même temps.

---

## Étape 6 — vérifier que le correctif est réellement actif

C'est l'étape qui compte : le bug corrigé aujourd'hui détruit des `CLAUDE.md`.

```bash
cd ~/Documents/Projects/<un-projet-migré>
git status --porcelain CLAUDE.md     # doit être propre au départ
```

Ouvre une session Claude Code dans ce projet, puis re-vérifie `git status`. Le hook doit soit
n'avoir rien changé, soit n'avoir touché que le bloc `<maestro_memory>`. Si un fichier
`.claude-md.maestro.lock` traîne après la session, dis-le moi.

Test de non-régression rapide, hors projet réel :

```bash
cd ~/Documents/maestro-v5-work/maestro && bash scripts/tests/memory-sync.test.sh
# attendu : memory-sync: 10 passed, 0 failed
```

---

## Étape 7 — l'ancien package (optionnel, quand tout est vert)

```bash
npm deprecate --registry=https://npm.pkg.github.com \
  "@arabiipte/maestro@>=5.0.0" "Moved to @chakerben/maestro — see chakerben/maestro-v5"
```

Ne le fais qu'après avoir confirmé que `@chakerben/maestro@5.4.0` est bien installable. Et
laisse `@arabiipte/maestro@<5.0.0` tel quel : c'est la v4 archivée, déjà dépréciée avec son
propre message.

---

## Si ça tourne mal

| Symptôme | Cause probable | Sortie |
|---|---|---|
| Le transfert est refusé | un `maestro-v5` existe déjà sur `chakerben` | renommer ou supprimer l'autre dépôt |
| `git push` → 403 après transfert | `origin` pointe encore sur l'ancienne URL | `git remote set-url` (étape 3) |
| `npm publish` → 403/404 | `repository.url` ou le scope | vérifier que les deux disent `chakerben` |
| `marketplace update` → introuvable | redirection non suivie | `remove` + `add` (étape 5) |
| Un projet ne voit plus ses plugins | marketplace retiré mais pas ré-ajouté | ré-ajouter sous le nom `maestro` |
| Il faut tout annuler | — | GitHub permet de re-transférer vers `arabiipte` ; le tag `v5.4.0` peut être supprimé (`git push --delete origin v5.4.0`), mais **un package npm publié ne se dépublie pas** : il faudrait sortir un 5.4.1 |

---

## Reste ouvert après cette release

Non traité aujourd'hui, et toujours dans `docs/AUDIT-5.3.1.md` :

- `validate.js` — ne compte les hooks que dans `plugins/**/hooks.json`, détection des reviewers
  par nom de fichier, strip de commentaires naïf
- `bash-guard.js` — 45 contournements confirmés ; décider entre requalifier en garde-fou
  anti-accident ou tokeniser
- les 14 autres défauts des scripts de migration (P1-2 à P1-16)
- le jalon `/sdlc` en réel, qui conditionne la v5.5
