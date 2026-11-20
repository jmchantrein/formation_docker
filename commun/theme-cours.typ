// theme-cours.typ — charte commune des cours (virtualisation, Docker…) pour Touying.
// Reprend les couleurs, polices et proportions du deck HTML (maquette 1920 × 1080 px).

#import "@preview/touying:0.8.0": *
#import themes.simple: *

// ---------- Variantes de rendu ----------
// Choisies à la compilation, sans toucher aux cours : typst compile --input variante=<nom> …
// - normal (défaut) : rendu de projection ;
// - daltonien : le vert devient bleu-vert, distinct de l’orange et du bleu en deutéranopie et protanopie ;
// - dyslexie : lettres, mots et lignes plus espacés, ni capitales forcées ni italique ;
// - polycopie : une page par diapo, dans son état final (sans les apparitions au clic).
#let variantes = ("normal", "daltonien", "dyslexie", "polycopie")
#let variante = sys.inputs.at("variante", default: "normal")
#assert(variante in variantes,
  message: "variante inconnue : " + variante + " (attendu : " + variantes.join(", ") + ")")
#let dys = variante == "dyslexie"
// Capitales décoratives (surtitres, étiquettes), gardées en casse normale pour la variante dyslexie.
#let maj(x) = if dys { x } else { upper(x) }

// Échelle : 1 px de la maquette = 0,4385 pt sur la page 16:9 de Touying.
#let px(n) = n * 0.4385pt

#let c = (
  bleu: rgb("#1F63C9"), bleu-clair: rgb("#E8EFFA"),
  vert: rgb("#1E7A46"), vert-clair: rgb("#E4F2E9"),
  orange: rgb("#B4530F"), orange-clair: rgb("#FBE9DA"),
  nuit: rgb("#0F1E33"), encre: rgb("#14213D"), gris: rgb("#5B6680"),
  ardoise: rgb("#44506A"), fond: rgb("#F6F7F3"), espace: rgb("#EDF0F3"),
  filet: rgb("#D5DAE0"), appli: rgb("#D6E6FB"), os: rgb("#FBDDC2"),
  prompt: rgb("#7DB4FF"), commentaire: rgb("#9FB0C8"), texte-term: rgb("#E6EDF7"),
  ambre: rgb("#F29A4B"), menthe: rgb("#8FD6A8"), encart: rgb("#2A3954"),
) + if variante == "daltonien" {
  // Écarts simulés (ΔE, Machado 2009) : vert/orange 36 → 58 en deutéranopie, 22 → 45 en protanopie,
  // en gardant vert/bleu ≥ 60 ; texte blanc sur l’en-tête : contraste 6,1.
  (vert: rgb("#00695C"), vert-clair: rgb("#E0F2F1"), menthe: rgb("#A0E0D0"))
} else { (:) }

#let mono = "IBM Plex Mono"

// ---------- Thème ----------
#let cours-theme(auteur: none, titre-court: none, body) = {
  show: simple-theme.with(
    aspect-ratio: "16-9",
    header: none,
    header-right: none,
    footer: grid(
      columns: (1fr, auto, 1fr),
      text(size: px(22), fill: c.gris, auteur),
      text(size: px(22), fill: c.gris, titre-court),
      align(right, text(size: px(22), fill: c.gris,
        context [#utils.slide-counter.display()/#utils.last-slide-number])),
    ),
    footer-right: none,
    primary: c.bleu,
    // Chaque diapo : surtitre = section (titre `=`), titre = diapo (titre `==`).
    subslide-preamble: block(below: px(36), {
      text(size: px(24), weight: 600, tracking: px(2), fill: c.bleu,
        maj(utils.display-current-heading(level: 1)))
      v(px(16), weak: true)
      text(size: px(64), weight: 600, utils.display-current-heading(level: 2))
    }),
    config-common(new-section-slide-fn: none, show-strong-with-alert: false, handout: variante == "polycopie"),
    config-page(fill: c.fond, margin: (x: px(128), top: px(120), bottom: px(150)), footer-descent: px(62)),
  )
  // Boîtes de ligne comme en CSS (ascendante → descendante) : mêmes hauteurs de blocs que le deck HTML.
  set text(font: "IBM Plex Sans", size: px(28), fill: c.encre, lang: "fr",
    top-edge: "ascender", bottom-edge: "descender")
  set par(leading: 0.38em)
  // Dyslexie : espacements augmentés (le code garde ses colonnes), pas d’italique.
  set text(tracking: 0.04em, spacing: 130%) if dys
  set par(leading: 0.6em) if dys
  show raw: set text(tracking: 0pt, spacing: 100%) if dys
  show raw.where(block: true): set par(leading: 0.38em) if dys
  show emph: it => if dys { it.body } else { it }
  show strong: it => text(weight: 600, it.body)  // gras sans recoloration
  show raw: set text(font: mono)
  // Typst réduit déjà le code à 0,8 em : 1,15 em donne environ 0,92 de la taille du texte.
  show raw.where(block: false): set text(size: 1.15em, fill: c.bleu)
  show raw.where(block: true): set text(size: px(20))
  body
}

// ---------- Rangées de même hauteur ----------
// Chaque cellule est une fonction hauteur => contenu ; toutes prennent la hauteur de la plus haute
// (équivalent du « align-items: stretch » du deck HTML).
#let rangee(gouttiere: px(32), poids: auto, ..cellules) = layout(taille => {
  let cs = cellules.pos()
  let p = if poids == auto { (1,) * cs.len() } else { poids }
  let utile = taille.width - gouttiere * (cs.len() - 1)
  let largeurs = p.map(x => utile * x / p.sum())
  let h = calc.max(..cs.zip(largeurs).map(((f, l)) => std.measure(block(width: l, f(auto))).height))
  grid(columns: largeurs, column-gutter: gouttiere, ..cs.map(f => f(h)))
})

// ---------- Blocs colorés ----------
// bloc(...) décrit un bloc ; colonnes(...) les pose côte à côte, à hauteur égale.
#let bloc(titre, entete: c.bleu, fond: c.bleu-clair, poids: 1, taille: px(28), taille-titre: px(28), corps) = (
  titre: titre, entete: entete, fond: fond, poids: poids, taille: taille, taille-titre: taille-titre, corps: corps,
)

#let rendre-bloc(b, hauteur: auto) = block(
  width: 100%, height: hauteur, radius: px(12), clip: true, fill: b.fond,
  stack(
    block(width: 100%, fill: b.entete, inset: (x: px(28), y: px(12)),
      text(fill: c.fond, size: b.taille-titre, weight: 600, b.titre)),
    block(width: 100%, inset: (x: px(28), y: px(22)), { set text(size: b.taille); b.corps }),
  ),
)

#let colonnes(gouttiere: px(32), ..blocs) = rangee(gouttiere: gouttiere,
  poids: blocs.pos().map(b => b.poids),
  ..blocs.pos().map(b => h => rendre-bloc(b, hauteur: h)))

#let espace = v(px(24))

// Bandeau sombre (origine, éditeur, version…).
#let bandeau(taille: px(25), corps) = block(width: 100%, fill: c.nuit, radius: px(12),
  inset: (x: px(28), y: px(16)), {
    set text(size: taille, fill: c.texte-term)
    show raw.where(block: false): set text(fill: c.prompt)
    corps
  })

// Petite note sur fond coloré.
#let note(fond: c.vert-clair, couleur: c.encre, taille: px(20), corps) = block(width: 100%, fill: fond,
  radius: px(10), inset: (x: px(18), y: px(12)), text(size: taille, fill: couleur, corps))

// ---------- Terminal ----------
// Lignes « $ … » : invite colorée ; lignes « # … » : commentaire grisé.
#let terminal(titre: "Terminal", taille: px(20), hauteur: auto, corps) = block(
  width: 100%, height: hauteur, fill: c.nuit, radius: px(12), inset: (x: px(22), y: px(14)), {
    set text(fill: c.texte-term)
    show raw.where(block: true): set text(size: taille)
    show raw.where(block: true): set block(above: px(4), below: px(4))
    show raw.line: l => {
      let t = l.text
      if t.starts-with("$ ") { text(fill: c.prompt)[\$]; " " + t.slice(2) }
      else if t.starts-with("# ") { text(fill: c.commentaire, t) }
      else { t }
    }
    if titre != none {
      block(below: px(8), text(size: px(24), weight: 600, tracking: px(2), fill: c.prompt, maj(titre)))
    }
    corps
  },
)

// Encart plus clair dans un terminal (moniteur QEMU, session dans l'invité…).
#let encart(titre, corps) = block(width: 100%, fill: c.encart, radius: px(8),
  inset: (x: px(14), y: px(10)), above: px(10), below: px(4), {
    block(below: px(6), text(font: mono, size: px(22), weight: 600, fill: c.ambre, maj(titre)))
    corps
  })

// Cadre coloré dans un terminal : une machine lancée par la commande au-dessus.
#let cadre(etiquette, couleur, corps) = block(
  width: 100%, stroke: px(2) + couleur, radius: px(10), fill: couleur.transparentize(90%),
  inset: (x: px(12), top: px(6), bottom: px(8)), above: px(8), below: px(4), {
    block(below: px(6), text(size: px(18), weight: 600, tracking: px(1), fill: couleur, maj(etiquette)))
    corps
  },
)

// ---------- Listes à deux colonnes (chronologie, fiches) ----------
#let lignes(largeur: px(260), taille-cle: px(36), taille: px(30), ..paires) = {
  let ps = paires.pos()
  grid(columns: (largeur, 1fr), align: horizon,
    inset: (x, y) => (y: px(12), left: if x == 1 { px(40) } else { 0pt }),
    stroke: (x, y) => if y < ps.len() - 1 { (bottom: px(1) + c.filet) },
    ..ps.map(((k, v)) => (text(size: taille-cle, weight: 600, fill: c.bleu, k), text(size: taille, v))).flatten())
}

// Plan du cours : numéro, titre de partie, description.
#let plan-cours(..parties) = {
  let ps = parties.pos()
  grid(columns: (px(96), 1fr), align: horizon, column-gutter: px(40),
    inset: (y: px(16)),
    stroke: (x, y) => if y < ps.len() - 1 { (bottom: px(1) + c.filet) },
    ..ps.enumerate().map(((i, (t, d))) => (
      text(size: px(64), weight: 600, fill: c.bleu, str(i + 1)),
      { text(size: px(40), weight: 600, t); linebreak(); text(size: px(32), fill: c.ardoise, d) },
    )).flatten())
}

// ---------- Corrigé de TP ----------
#let question(n, corps) = grid(columns: (auto, 1fr), column-gutter: px(12),
  box(fill: c.bleu, radius: px(6), inset: (x: px(10), y: px(2)),
    text(size: px(22), weight: 600, fill: c.fond, str(n))),
  text(size: px(26), fill: c.ardoise, corps))

#let filet-corrige = line(length: 100%, stroke: px(2) + rgb("#C9D6EA"))

#let corrige(n, q, reponse) = grid(columns: (px(700), 1fr), column-gutter: px(32),
  question(n, q), reponse)

// ---------- Schémas en couches ----------
#let couche(texte, fond: c.nuit, hauteur: px(72), taille: px(30), puces: ()) = block(
  width: 100%, height: hauteur, fill: fond, radius: px(8),
  align(center + horizon, stack(spacing: px(8),
    text(fill: c.fond, size: taille, weight: 600, texte),
    if puces.len() > 0 {
      puces.map(p => box(fill: c.bleu, radius: px(8), inset: (x: px(12), y: px(4)),
        text(fill: c.fond, size: px(24), weight: 600, p))).join(h(px(10)))
    },
  )),
)

#let vm(nom, haut: "Appli", bas: "OS invité", couleur: c.orange, fond-bas: c.os, case: px(80),
  taille: px(28)) = block(
  width: 100%, stroke: px(3) + couleur, radius: px(12), inset: px(8), fill: c.fond,
  stack(spacing: px(8),
    align(center, text(fill: couleur, size: px(24), weight: 600, nom)),
    block(width: 100%, height: case, fill: c.appli, radius: px(8),
      align(center + horizon, text(size: taille, weight: 600, haut))),
    block(width: 100%, height: case, fill: fond-bas, radius: px(8),
      align(center + horizon, text(size: taille, weight: 600, bas))),
  ),
)

// Pile complète : titre, espace utilisateur (gestion + VM/conteneurs), noyau ou hyperviseur, matériel.
#let pile-archi(titre, espace, gestion, cases, noyau, puces, materiel) = stack(spacing: px(8),
  text(size: px(40), weight: 600, titre),
  v(px(8)),
  block(width: 100%, fill: c.espace, radius: px(12), inset: (x: px(12), top: px(12), bottom: px(20)),
    stack(spacing: px(8),
      text(size: px(24), weight: 600, fill: c.gris, espace),
      block(width: 100%, stroke: (paint: c.gris, thickness: px(2), dash: "dashed"), radius: px(10),
        inset: (x: px(12), y: px(8)), align(center, text(size: px(24), fill: c.ardoise, gestion))),
      grid(columns: (1fr,) * cases.len(), column-gutter: px(12), ..cases),
    )),
  couche(noyau, hauteur: px(108), taille: px(28), puces: puces),
  couche(materiel, fond: c.ardoise, hauteur: px(80), taille: px(32)),
)

// Élément placé sur un canevas aux coordonnées de la maquette (px).
#let pose(x, y, corps) = place(top + left, dx: px(x), dy: px(y), corps)

// ---------- Couverture ----------
#let couverture(titre, sous-titre, auteur, date, surtitre: "Cours · LERIA") = touying-slide-wrapper(self => {
  self = utils.merge-dicts(self,
    config-common(subslide-preamble: none),
    config-page(fill: c.nuit, footer: none, margin: px(128)))
  touying-slide(self: self, {
    // Illustration : trois VM sur un hyperviseur, sur le matériel.
    place(top + left, dx: px(1104), dy: px(184), stack(spacing: px(16),
      grid(columns: (px(176),) * 3, column-gutter: px(16),
        ..range(3).map(_ => box(width: px(176), height: px(96), fill: c.ambre, radius: px(12)))),
      box(width: px(560), height: px(56), fill: rgb("#4F8FE6"), radius: px(12)),
      box(width: px(560), height: px(56), fill: c.gris, radius: px(12)),
    ))
    text(size: px(24), weight: 600, tracking: px(2), fill: c.prompt, maj(surtitre))
    v(1fr)
    block(width: px(1040), {
      text(size: px(144), weight: 600, fill: c.fond, titre)
      v(px(32), weak: true)
      text(size: px(64), fill: rgb("#C3D0E4"), sous-titre)
    })
    v(1fr)
    text(size: px(40), weight: 600, fill: c.fond, auteur)
    v(px(8), weak: true)
    text(size: px(32), fill: rgb("#C3D0E4"), date)
  })
})
