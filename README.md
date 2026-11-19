# Cours

Supports de cours de Jean-Mathieu Chantrein : un dossier par cours, une charte commune.

| Cours | Diapos | Sources |
|---|---|---|
| Docker : fondements de la conteneurisation | [`docker.pdf`](docker.pdf) | [`docker/`](docker/) (travaux pratiques) |
| Fondements de la virtualisation de machines | [`virtualisation.pdf`](virtualisation.pdf) | [`virtualisation/`](virtualisation/) (Typst) |

## Organisation
- `<cours>/<cours>.typ` : les diapos d’un cours, en [Typst](https://typst.app) avec [Touying](https://github.com/touying-typ/touying).
- `commun/` : la charte partagée (`theme-cours.typ`) et les polices IBM Plex ; voir [`commun/README.md`](commun/README.md).
- `<cours>.pdf` à la racine : le PDF publié, compilé par la CI.

## Compiler
Typst 0.15 ou plus récent, depuis la racine du dépôt (Touying se télécharge seul à la première compilation) :

    typst compile --root . --font-path commun/fonts virtualisation/virtualisation.typ
    typst watch   --root . --font-path commun/fonts virtualisation/virtualisation.typ

`--root .` autorise l’import de `../commun/theme-cours.typ`.

Sur GitHub, l’action `.github/workflows/compilation-cours.yml` recompile chaque cours `<cours>/<cours>.typ`
à chaque push sur `master` touchant les sources ou la charte, et dépose `<cours>.pdf` à la racine.
Ajouter un cours : créer `<cours>/<cours>.typ` qui importe `../commun/theme-cours.typ`, rien d’autre.

## Licences
Contenus sous CC BY-NC-SA 4.0 (voir [`LICENSE.md`](LICENSE.md)). Les polices IBM Plex de `commun/fonts/`
restent sous SIL Open Font License 1.1 (voir `commun/fonts/OFL-IBM-Plex.txt`).
