# Charte commune des cours

- `theme-cours.typ` : couleurs, polices, blocs, terminaux, schémas… pour Touying. Import depuis un cours :
  `#import "../commun/theme-cours.typ": *`
- `fonts/` : IBM Plex Sans et Mono (SIL Open Font License 1.1, voir `fonts/OFL-IBM-Plex.txt`).

## Écrire une diapo
- Une section (surtitre bleu) = un titre `=` ; une diapo = un titre `==`.
- Blocs colorés côte à côte, à hauteur égale :
  `#colonnes(bloc[Titre][- point], bloc(entete: c.vert, fond: c.vert-clair)[Titre][- point])`
- Terminal : `#terminal[```...```]` ; une ligne `$ ` colore l’invite, une ligne `# ` grise le commentaire.
- Bandeau sombre (origine, éditeur, version) : `#bandeau[...]`.
- Notes de l’orateur : `#speaker-note[...]`.
- Apparitions au clic : voir, dans `virtualisation/virtualisation.typ`, les diapos « Architecture simplifiée et bilan »,
  « La migration à chaud » et le corrigé du TP (style callback : `#slide(repeat: n, self => ...)` avec `uncover("2-", ...)`).
  Chaque étape devient une page du PDF.

Édition avec aperçu en direct : extension Tinymist (VS Code, VSCodium, Neovim…), avec la racine du dépôt comme racine du projet.
