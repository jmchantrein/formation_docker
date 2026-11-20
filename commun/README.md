# Charte commune des cours

- `theme-cours.typ` : couleurs, polices, blocs, terminaux, schémas… pour Touying. Import depuis un cours :
  `#import "../commun/theme-cours.typ": *`
- `fonts/` : IBM Plex Sans et Mono (SIL Open Font License 1.1, voir `fonts/OFL-IBM-Plex.txt`).

## Principe : le cours dit le rôle, la charte décide de l’apparence
Un cours n’écrit jamais de couleur : il déclare le **rôle pédagogique** d’un bloc, et la charte en tire
la couleur, le pictogramme et leur adaptation dans chaque variante.

| Rôle | Pictogramme | Couleur en projection | Usage |
|---|---|---|---|
| `notion` (défaut) | — | bleu | définir, expliquer |
| `pratique` | coureur en sueur (l’effort) | vert clair | exemple, démonstration, exercice (la question), usage réel |
| `reponse` | coureur en sueur | vert foncé | corrigé : la réponse à une question pratique |
| `retenir` | cerveau | bleu nuit | synthèse, point clé |
| `precaution` | triangle ! + feu du bas | jaune | nuance, confusion fréquente, limite |
| `avertissement` | triangle ! + feu du milieu | orange | erreur probable, mauvaise pratique |
| `danger` | triangle ! + feu du haut | rouge | risque réel : sécurité, perte de données |

Les trois niveaux d’alerte suivent la gradation des normes de signalisation (ISO 3864, ANSI Z535) :
précaution, avertissement, danger ; les trois partagent le triangle « ! », suivi d’un feu tricolore dont
le feu allumé (bas, milieu, haut) donne le niveau par sa position, donc même sans couleur. Les dessins du cerveau et du coureur viennent de Tabler Icons (MIT, `pictos/LICENSE-tabler-icons.txt`).

Dans les schémas : hôte et applications en **bleu**, invité (VM, OS invité) en **violet** (`c.invite`,
`c.invite-clair`). Dans les terminaux, `cadre(…, niveau: 0 | 1 | 2)` : hôte (trait plein), VM invitée (tirets),
VM imbriquée (pointillés).

## Écrire une diapo
- Une section (surtitre bleu) = un titre `=` ; une diapo = un titre `==`.
- Blocs colorés côte à côte, à hauteur égale :
  `#colonnes(bloc[Titre][- point], bloc(role: "pratique")[Titre][- point])`
- Note courte : `#note(role: "pratique")[...]` ; encadré à libellé : `#encadre(role: "precaution", libelle: [En vrai :])[...]`.
- Corrigé de TP : `#corrige(n, [question], uncover("2-", reponse(terminal[...])))` ; la question porte le vert
  clair de la pratique, la réponse une barre vert foncé qui apparaît avec elle.
- Machine lancée par la commande au-dessus, dans un terminal : `#cadre([VM (niveau 1)], niveau: 1)[...]`.
- Terminal : `#terminal[```...```]` ; une ligne `$ ` colore l’invite, une ligne `# ` grise le commentaire.
- Bandeau sombre (origine, éditeur, version) : `#bandeau[...]`.
- Notes de l’orateur : `#speaker-note[...]`.
- Apparitions au clic : voir, dans `virtualisation/virtualisation.typ`, les diapos « Architecture simplifiée et bilan »,
  « La migration à chaud » et le corrigé du TP (style callback : `#slide(repeat: n, self => ...)` avec `uncover("2-", ...)`).
  Chaque étape devient une page du PDF.

Édition avec aperçu en direct : extension Tinymist (VS Code, VSCodium, Neovim…), avec la racine du dépôt comme racine du projet.

## Variantes de rendu
La charte lit `--input variante=<nom>` (normal, deuteranopie, protanopie, tritanopie, achromatopsie, dyslexie)
et adapte palette et espacements ; les cours n’ont rien à faire. Chaque variante commence par une page
« Légende », hors numérotation, qui relie ses couleurs à celles de la projection (« le bloc orange » = avertissement). Les réglages et leur justification sont en tête
de `theme-cours.typ`. Une nouvelle palette s’ajoute dans `palettes` ; penser à l’ajouter aussi à la liste des
variantes de `.github/workflows/compilation-cours.yml`. Si une variante déborde, chercher d’abord une mise en page qui tienne ; le débordement n’est acceptable qu’en
dernier recours.
