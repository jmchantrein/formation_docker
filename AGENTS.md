# Consignes pour les agents

La charte graphique est dans [`commun/README.md`](commun/README.md) (rôles, pictogrammes, schémas, variantes) ;
l’organisation et la compilation dans [`README.md`](README.md).

- Dans un cours, déclare des rôles : `bloc(role: …)`, `note`, `encadre`, `corrige` + `reponse`, `cadre(niveau: …)`.
- Prends les couleurs dans la charte (`c.*`, `roles.*`) ; écris toute couleur nouvelle dans `commun/theme-cours.typ`.
- Choisis le rôle d’après le sens du bloc, selon le tableau de `commun/README.md`.
- Pour un besoin visuel nouveau, ajoute un rôle ou un composant à la charte, avec sa couleur dans chaque palette.
- Après une modification, compile chaque variante dans `build/` et vérifie qu’elle a le nombre de pages
  de la projection, plus une (la légende).
- Laisse la CI produire les PDF versionnés `<cours>/<cours>*.pdf`.
