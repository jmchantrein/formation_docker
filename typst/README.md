# Cours « Fondements de la virtualisation de machines » en Typst

Les 30 diapos du cours Virtualisation, écrites en texte et compilées en PDF par
[Typst](https://typst.app) avec le paquet [Touying](https://github.com/touying-typ/touying).

## Fichiers
- `virtualisation.typ` : le contenu des diapos, dans l'ordre, avec les notes de l'orateur.
- `theme-cours.typ` : la charte (couleurs, polices, blocs, terminaux, schémas…), réutilisable pour le cours Docker.
- `fonts/` : IBM Plex Sans et Mono.

## Compiler
Typst 0.15 ou plus récent. Touying 0.8.0 se télécharge seul à la première compilation.

    cd typst
    typst compile --font-path fonts virtualisation.typ   # produit le PDF
    typst watch   --font-path fonts virtualisation.typ   # recompile à chaque enregistrement

Édition avec aperçu en direct : extension Tinymist (VS Code, VSCodium, Neovim…).

## Écrire une diapo
- Une section (surtitre bleu) = un titre `=` ; une diapo = un titre `==`.
- Blocs colorés côte à côte, à hauteur égale :
  `#colonnes(bloc[Titre][- point], bloc(entete: c.vert, fond: c.vert-clair)[Titre][- point])`
- Terminal : `#terminal[```...```]` ; une ligne `$ ` colore l'invite, une ligne `# ` grise le commentaire.
- Bandeau sombre (origine, éditeur, version) : `#bandeau[...]`.
- Notes de l'orateur : `#speaker-note[...]`.
- Apparitions au clic : voir les diapos « Architecture simplifiée et bilan », « La migration à chaud »
  et le corrigé du TP (style callback : `#slide(repeat: n, self => ...)` avec `uncover("2-", ...)`).
  Chaque étape devient une page du PDF.

## Licences
Les sources de ce dossier suivent la licence du dépôt (CC BY-NC-SA 4.0, voir `LICENSE.md` à la racine).
Les polices IBM Plex du dossier `fonts/` restent sous leur propre licence, SIL Open Font License 1.1
(voir `fonts/OFL-IBM-Plex.txt`).
