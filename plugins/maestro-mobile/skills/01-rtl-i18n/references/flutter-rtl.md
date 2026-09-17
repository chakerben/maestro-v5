# RTL et arabe en Flutter

> Référence de `maestro-mobile:01-rtl-i18n`. Les règles du SKILL.md (logical CSS,
> pluriels, Hijri, SAR, typographie) restent valables sur le fond ; ce fichier
> donne leur forme Flutter, qui ne ressemble à aucune des deux autres.

## Flutter — les règles web ne s'y appliquent pas

- **Direction** : `MaterialApp` reçoit `localizationsDelegates` +
  `supportedLocales`; Flutter pose alors la `Directionality` tout seul. Ne
  jamais forcer un `TextDirection` en dur sauf pour isoler un fragment.
- **Marges et alignements** : `EdgeInsetsDirectional.only(start:, end:)`,
  `AlignmentDirectional`, `PositionedDirectional`,
  `BorderRadiusDirectional`. Un `EdgeInsets.only(left:)` sur un élément
  directionnel est un bug RTL, pas un détail.
- **Chaînes** : fichiers ARB + `gen_l10n` (`AppLocalizations.of(context)!`).
  Un ternaire `isArabic ? '…' : '…'` dans le widget est l'anti-patron :
  il ne se traduit pas, ne se teste pas, et disperse la langue dans l'UI.
  Migration : extraire par écran, un ARB par locale, `@@locale` renseigné.
- **Pluriels** : la syntaxe ICU d'ARB couvre les six catégories arabes
  (`zero one two few many other`) — les utiliser toutes, pas `count == 1`.
- **Polices** : une police latine (Space Grotesk, Inter, Poppins…) n'a
  **aucun glyphe arabe** — le texte retombe sur la police système, rendu
  incontrôlé. Déclarer une famille arabe (Cairo, Tajawal, IBM Plex Sans
  Arabic) et la sélectionner par locale dans le `TextTheme`.
- **Hauteur de ligne** : `TextStyle(height: 1.6…1.8)` pour l'arabe, sinon
  les diacritiques et les descendantes sont rognées. `letterSpacing` reste
  à 0 — il casse la liaison cursive.
- **Icônes et gestes** : `Icons.arrow_back` se retourne via
  `Transform.flip` selon `Directionality.of(context)`; `Slider`,
  `PageView` et les swipes de navigation s'inversent aussi.
- **Chiffres et dates** : `NumberFormat`/`DateFormat` avec la locale
  (`ar` → chiffres indo-arabes selon la décision projet, `ar_SA` →
  calendrier umalqura). Jamais de `toString()` sur un nombre affiché.
