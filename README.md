# Cours

Supports de cours de Jean-Mathieu Chantrein : un dossier par cours, une charte commune.

| Cours | Diapos | Rendus adaptés | Sources |
|---|---|---|---|
| Docker : fondements de la conteneurisation | [`docker.pdf`](docker/docker.pdf) | — | [`docker/`](docker/) (travaux pratiques) |
| Fondements de la virtualisation de machines | [`virtualisation.pdf`](virtualisation/virtualisation.pdf) | [daltonisme](virtualisation/virtualisation-daltonien.pdf) · [dyslexie](virtualisation/virtualisation-dyslexie.pdf) · [polycopié](virtualisation/virtualisation-polycopie.pdf) | [`virtualisation/`](virtualisation/) (Typst) |

## Rendus adaptés
Chaque cours Typst est compilé en plusieurs rendus, à partir des mêmes sources ; la charte commune
(`commun/theme-cours.typ`) applique la variante choisie à la compilation.

| Variante | Fichier | Pour qui, quoi |
|---|---|---|
| normal | `<cours>.pdf` | La projection en cours. |
| daltonien | `<cours>-daltonien.pdf` | Daltonisme rouge-vert (deutéranopie, protanopie) : le vert devient bleu-vert, bien distinct de l’orange et du bleu. |
| dyslexie | `<cours>-dyslexie.pdf` | Lettres, mots et lignes plus espacés ; pas de capitales forcées ni d’italique. |
| polycopie | `<cours>-polycopie.pdf` | Relecture, impression : une page par diapo dans son état final, sans les étapes d’apparition. |

## Organisation
- `<cours>/<cours>.typ` : les diapos d’un cours, en [Typst](https://typst.app) avec [Touying](https://github.com/touying-typ/touying).
- `commun/` : la charte partagée (`theme-cours.typ`) et les polices IBM Plex ; voir [`commun/README.md`](commun/README.md).
- `<cours>/<cours>.pdf` : le PDF publié, compilé par la CI.

## Compiler
Typst 0.15 ou plus récent, depuis la racine du dépôt (Touying se télécharge seul à la première compilation) :

    typst compile --root . --font-path commun/fonts virtualisation/virtualisation.typ build/virtualisation.pdf
    typst watch   --root . --font-path commun/fonts virtualisation/virtualisation.typ build/virtualisation.pdf

Pour une variante : ajouter `--input variante=daltonien` (ou `dyslexie`, `polycopie`).

`--root .` autorise l’import de `../commun/theme-cours.typ`. On compile dans `build/` (ignoré par git) :
le PDF versionné `<cours>/<cours>.pdf` est produit et commité par la CI, ce qui évite les conflits sur ce fichier binaire.

Sur GitHub, l’action `.github/workflows/compilation-cours.yml` recompile chaque cours `<cours>/<cours>.typ`
à chaque push sur `main` touchant les sources ou la charte, et commite `<cours>/<cours>.pdf` et ses variantes.
Ajouter un cours : créer `<cours>/<cours>.typ` qui importe `../commun/theme-cours.typ`, rien d’autre.

## Licences
Contenus sous CC BY-NC-SA 4.0 (voir [`LICENSE.md`](LICENSE.md)). Les polices IBM Plex de `commun/fonts/`
restent sous SIL Open Font License 1.1 (voir `commun/fonts/OFL-IBM-Plex.txt`).
