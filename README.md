# Cours

Supports de cours de Jean-Mathieu Chantrein : un dossier par cours, une charte commune.

| Cours | Diapos | Sources |
|---|---|---|
| Docker : fondements de la conteneurisation | [`docker.pdf`](docker/docker.pdf) | [`docker/`](docker/) (travaux pratiques) |
| Fondements de la virtualisation de machines | [`virtualisation.pdf`](virtualisation/virtualisation.pdf) | [`virtualisation/`](virtualisation/) (Typst) |

## Organisation
- `<cours>/<cours>.typ` : les diapos d’un cours, en [Typst](https://typst.app) avec [Touying](https://github.com/touying-typ/touying).
- `commun/` : la charte partagée (`theme-cours.typ`) et les polices IBM Plex ; voir [`commun/README.md`](commun/README.md).
- `<cours>/<cours>.pdf` : le PDF publié, compilé par la CI.

## Compiler
Typst 0.15 ou plus récent, depuis la racine du dépôt (Touying se télécharge seul à la première compilation) :

    typst compile --root . --font-path commun/fonts virtualisation/virtualisation.typ build/virtualisation.pdf
    typst watch   --root . --font-path commun/fonts virtualisation/virtualisation.typ build/virtualisation.pdf

`--root .` autorise l’import de `../commun/theme-cours.typ`. On compile dans `build/` (ignoré par git) :
le PDF versionné `<cours>/<cours>.pdf` est produit et commité par la CI, ce qui évite les conflits sur ce fichier binaire.

Sur GitHub, l’action `.github/workflows/compilation-cours.yml` recompile chaque cours `<cours>/<cours>.typ`
à chaque push sur `main` touchant les sources ou la charte, et commite `<cours>/<cours>.pdf`.
Ajouter un cours : créer `<cours>/<cours>.typ` qui importe `../commun/theme-cours.typ`, rien d’autre.

## Licences
Contenus sous CC BY-NC-SA 4.0 (voir [`LICENSE.md`](LICENSE.md)). Les polices IBM Plex de `commun/fonts/`
restent sous SIL Open Font License 1.1 (voir `commun/fonts/OFL-IBM-Plex.txt`).
