// theme-cours.typ — charte commune des cours (virtualisation, Docker…) pour Touying.
// Reprend les couleurs, polices et proportions du deck HTML (maquette 1920 × 1080 px).

#import "@preview/touying:0.8.0": *
#import themes.simple: *

// ---------- Rôles pédagogiques ----------
// Le cours dit ce qu’est un bloc (son rôle) ; la charte décide de son apparence.
#let roles-def = (
  notion: (nom: "Notion", projection: "bleu", sens: "définir, expliquer"),
  pratique: (nom: "Pratique", projection: "vert", sens: "exemple, démonstration, exercice, usage réel"),
  retenir: (nom: "À retenir", projection: "bleu nuit", sens: "synthèse, point clé"),
  precaution: (nom: "Précaution", projection: "jaune", sens: "nuance, confusion fréquente, limite"),
  avertissement: (nom: "Avertissement", projection: "orange", sens: "erreur probable, mauvaise pratique"),
  danger: (nom: "Danger", projection: "rouge", sens: "risque réel : sécurité, perte de données"),
)

// ---------- Variantes de rendu ----------
// Choisies à la compilation : typst compile --input variante=<nom> …
// - normal (défaut) : rendu de projection, pensé pour la vision typique ;
// - deuteranopie, protanopie, tritanopie, achromatopsie : palette propre à chaque vision ;
// - dyslexie : lettres, mots et lignes plus espacés, ni capitales forcées ni italique.
// Chaque palette garde les rôles distincts pour la vision visée (écarts ΔE CIELAB simulés : Machado 2009
// pour les dichromasies, clarté seule pour l’achromatopsie) ; les pictogrammes doublent la couleur partout.
// Contraste du texte d’en-tête (blanc ou encre, choisi selon la clarté) et du texte sur terminal : ≥ 4,5.
// Clés : en-têtes des rôles ; invite / invite-clair (schémas) ; appli ; cadres de terminal hote-t, invite-t, imbrique-t.
#let palette-projection = (
  notion: rgb("#1F63C9"), pratique: rgb("#1E7A46"), retenir: rgb("#14213D"),
  precaution: rgb("#F2C94C"), avertissement: rgb("#B4530F"), danger: rgb("#B3123C"),
  invite: rgb("#7B3FB0"), invite-clair: rgb("#DDC4F5"), appli: rgb("#D3E4FB"),
  hote-t: rgb("#7DB4FF"), invite-t: rgb("#C9A7F5"), imbrique-t: rgb("#FF9EC4"),
)
// Dichromasies rouge-vert : seuls l’axe bleu/jaune et la clarté restent. Le vert passe au bleu-vert, le rouge
// s’assombrit, l’invité (violet, vu comme du bleu) devient ocre. Écart minimal entre rôles : 28 (deutéranopie),
// 23 (protanopie), contre 9 et 12 avec la palette de projection.
#let rouge-vert = (pratique: rgb("#006E7A"), danger: rgb("#7A0F2A"), invite: rgb("#7A5A00"),
  invite-clair: rgb("#EEDC9A"), invite-t: rgb("#E8C95A"), imbrique-t: rgb("#E8E8E8"))
#let palettes = (
  deuteranopie: rouge-vert,
  protanopie: rouge-vert,
  // Confusion bleu/vert et jaune/violet : le vert tire vers l’olive. Écart minimal : 18 → 28.
  tritanopie: (pratique: rgb("#6B6B00"), danger: rgb("#C2002F"), invite: rgb("#8E2C8C"),
    invite-clair: rgb("#F4C6E6"), invite-t: rgb("#F29ACB"), imbrique-t: rgb("#E9E39A")),
  // Sans couleur : une échelle de clarté L* (en-têtes 8/20/31/45/70/90, invité 38 ;
  // cadres 58/76/91), la pratique et la précaution passant en en-tête clair à texte foncé.
  achromatopsie: (retenir: rgb("#10172A"), danger: rgb("#68001D"), notion: rgb("#25468A"),
    avertissement: rgb("#9E582D"), pratique: rgb("#7EB88F"), precaution: rgb("#FFDF8A"),
    invite: rgb("#714793"), invite-clair: rgb("#CCBADC"), appli: rgb("#E0ECFC"),
    hote-t: rgb("#6C8DBF"), invite-t: rgb("#CAB1E8"), imbrique-t: rgb("#FFDAF4")),
)
#let variantes = ("normal", "dyslexie") + palettes.keys()
#let variante = sys.inputs.at("variante", default: "normal")
#assert(variante in variantes,
  message: "variante inconnue : " + variante + " (attendu : " + variantes.join(", ") + ")")
#let dys = variante == "dyslexie"
// Capitales décoratives (surtitres, étiquettes), gardées en casse normale pour la variante dyslexie.
#let maj(x) = if dys { x } else { upper(x) }

// Échelle : 1 px de la maquette = 0,4385 pt sur la page 16:9 de Touying.
#let px(n) = n * 0.4385pt

#let pal = palette-projection + palettes.at(variante, default: (:))
#let c = (
  nuit: rgb("#0F1E33"), encre: rgb("#14213D"), gris: rgb("#5B6680"),
  ardoise: rgb("#44506A"), fond: rgb("#F6F7F3"), espace: rgb("#EDF0F3"),
  filet: rgb("#D5DAE0"), prompt: rgb("#7DB4FF"), commentaire: rgb("#9FB0C8"), texte-term: rgb("#E6EDF7"),
  encart: rgb("#2A3954"),
  // Accent de la charte (surtitres, code, numéros) : la couleur des notions.
  bleu: pal.notion, bleu-clair: rgb("#E8EFFA"),
  // Structure des schémas : hôte et applications en bleu, invité (VM, OS invité) en violet.
  appli: pal.appli, invite: pal.invite, invite-clair: pal.invite-clair,
  hote-t: pal.hote-t, invite-t: pal.invite-t, imbrique-t: pal.imbrique-t,
)

// Texte lisible sur une couleur : encre sur fond clair, blanc cassé sur fond foncé.
#let clarte(col) = {
  let (r, g, b, ..) = col.rgb().components()
  let lin(x) = { let v = x / 100%; if v <= 0.04045 { v / 12.92 } else { calc.pow((v + 0.055) / 1.055, 2.4) } }
  0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
}
#let texte-sur(col) = if clarte(col) > 0.3 { c.encre } else { c.fond }

// Fonds clairs des rôles en projection (choisis à la main) ; dans les variantes, dérivés de l’en-tête.
#let fonds-projection = (
  notion: rgb("#E8EFFA"), pratique: rgb("#E4F2E9"), retenir: rgb("#E6E9F0"),
  precaution: rgb("#FFF6D9"), avertissement: rgb("#FBE9DA"), danger: rgb("#FBE3E8"),
)
#let roles = roles-def.keys().map(r => {
  let entete = pal.at(r)
  let fond = if variante in palettes { color.mix((entete, 14%), (c.fond, 86%)) } else { fonds-projection.at(r) }
  // accent : texte coloré sur le fond clair du rôle (le jaune, trop clair, est assombri)
  let accent = if clarte(entete) > 0.3 { entete.darken(60%) } else { entete }
  (r, (entete: entete, fond: fond, texte: texte-sur(entete), accent: accent))
}).to-dict()

// Pictogramme d’un rôle : cerveau pour « à retenir », coureur en sueur pour « pratique »
// (dessins Tabler Icons, MIT, dans pictos/), triangle « ! » pour les trois niveaux d’alerte ; rien pour une notion.
// Les dessins au trait paraissent plus petits qu’une forme pleine : on les agrandit d’un quart.
#let icone(fichier, couleur, t) = box(width: t * 1.25, height: t * 1.25, baseline: 24%,
  image(bytes(read(fichier).replace("currentColor", couleur.to-hex())), format: "svg", width: t * 1.25, height: t * 1.25))
#let picto(role, forme, glyphe, t: px(30)) = {
  if role == "retenir" { return icone("pictos/cerveau.svg", forme, t) }
  if role == "pratique" { return icone("pictos/coureur.svg", forme, t) }
  if role not in ("precaution", "avertissement", "danger") { return none }
  box(width: t, height: t, baseline: 18%, {
    polygon(fill: forme, (t * 0.5, 0pt), (t, t * 0.95), (0pt, t * 0.95))
    place(top + left, dy: t * 0.2, box(width: t, height: t * 0.8,
      align(center + horizon, text(size: t * 0.62, weight: 700, fill: glyphe, top-edge: "cap-height", bottom-edge: "baseline", "!"))))
  })
}

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
    config-common(new-section-slide-fn: none, show-strong-with-alert: false),
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
// role : notion (défaut), pratique, retenir, precaution, avertissement, danger (voir roles-def).
#let bloc(titre, role: "notion", poids: 1, taille: px(28), taille-titre: px(28), corps) = {
  assert(role in roles, message: "rôle inconnu : " + role + " (attendu : " + roles.keys().join(", ") + ")")
  (titre: titre, role: role, poids: poids, taille: taille, taille-titre: taille-titre, corps: corps)
}

// En-tête d’un rôle : pictogramme puis titre.
#let entete-role(role, titre, taille) = {
  let r = roles.at(role)
  let p = picto(role, r.texte, r.entete, t: taille * 1.05)
  text(fill: r.texte, size: taille, weight: 600, { if p != none { p; h(taille * 0.4) }; titre })
}

#let rendre-bloc(b, hauteur: auto) = block(
  width: 100%, height: hauteur, radius: px(12), clip: true, fill: roles.at(b.role).fond,
  stack(
    block(width: 100%, fill: roles.at(b.role).entete, inset: (x: px(28), y: px(12)),
      entete-role(b.role, b.titre, b.taille-titre)),
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

// Petite note sur le fond clair d’un rôle, avec son pictogramme.
#let note(role: "pratique", taille: px(20), corps) = {
  let r = roles.at(role)
  let p = picto(role, r.accent, r.fond, t: taille * 1.05)
  block(width: 100%, fill: r.fond, radius: px(10), inset: (x: px(18), y: px(12)),
    text(size: taille, fill: c.encre, { if p != none { p; h(taille * 0.4) }; corps }))
}

// Encadré pleine hauteur sur le fond clair d’un rôle, à libellé en tête (« En vrai : », « Intérêt : »…).
#let encadre(role: "notion", libelle: none, taille: px(22), hauteur: auto, corps) = {
  let r = roles.at(role)
  let p = picto(role, r.accent, r.fond, t: taille * 1.05)
  block(width: 100%, height: hauteur, fill: r.fond, radius: px(12), inset: (x: px(20), y: px(12)),
    align(horizon, text(size: taille, {
      if p != none { p; h(taille * 0.4) }
      if libelle != none { text(weight: 600, fill: r.accent, libelle); " " }
      corps
    })))
}

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
    block(below: px(6), text(font: mono, size: px(22), weight: 600, fill: c.invite-t, maj(titre)))
    corps
  })

// Cadre dans un terminal : une machine lancée par la commande au-dessus.
// niveau 0 = hôte (bleu, trait plein), 1 = VM invitée (violet, tirets), 2 = VM imbriquée (rose, pointillés) :
// le trait double la couleur.
#let cadre(etiquette, niveau: 0, corps) = {
  let couleur = (c.hote-t, c.invite-t, c.imbrique-t).at(niveau)
  let trait = ("solid", "dashed", "dotted").at(niveau)
  block(
    width: 100%, stroke: (paint: couleur, thickness: px(2), dash: trait), radius: px(10),
    fill: couleur.transparentize(90%),
    inset: (x: px(12), top: px(6), bottom: px(8)), above: px(8), below: px(4), {
      block(below: px(6), text(size: px(18), weight: 600, tracking: px(1), fill: couleur, maj(etiquette)))
      corps
    },
  )
}

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

#let vm(nom, haut: "Appli", bas: "OS invité", couleur: c.invite, fond-bas: c.invite-clair, case: px(80),
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
#let couverture-seule(titre, sous-titre, auteur, date, surtitre: "Cours · LERIA") = touying-slide-wrapper(self => {
  self = utils.merge-dicts(self,
    config-common(subslide-preamble: none),
    config-page(fill: c.nuit, footer: none, margin: px(128)))
  touying-slide(self: self, {
    // Illustration : trois VM sur un hyperviseur, sur le matériel.
    place(top + left, dx: px(1104), dy: px(184), stack(spacing: px(16),
      grid(columns: (px(176),) * 3, column-gutter: px(16),
        ..range(3).map(_ => box(width: px(176), height: px(96), fill: c.invite-t, radius: px(12)))),
      box(width: px(560), height: px(56), fill: c.hote-t, radius: px(12)),
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

// ---------- Légende (variantes seulement) ----------
// Relie ce rendu à la projection : quand l’enseignant dit « le bloc orange », c’est le bloc avertissement.
// Hors numérotation, pour que les numéros de diapo restent ceux de la projection.
#let legende = touying-slide-wrapper(self => {
  self = utils.merge-dicts(self, config-common(subslide-preamble: none, freeze-slide-counter: true))
  touying-slide(self: self, {
    text(size: px(24), weight: 600, tracking: px(2), fill: c.bleu, maj("Légende · rendu " + variante))
    v(px(16), weak: true)
    text(size: px(64), weight: 600)[Lire les couleurs de ce rendu]
    v(px(28))
    grid(columns: (1fr, 1fr), column-gutter: px(32), row-gutter: px(20),
      ..roles-def.pairs().map(((r, d)) => block(width: 100%, radius: px(12), clip: true, fill: roles.at(r).fond, stack(
        block(width: 100%, fill: roles.at(r).entete, inset: (x: px(24), y: px(10)), entete-role(r, d.nom, px(26))),
        block(width: 100%, inset: (x: px(24), y: px(12)), text(size: px(22))[
          #d.sens. En projection : *#d.projection*.]),
      ))))
    v(px(24))
    grid(columns: (1fr, 1fr, 1fr), column-gutter: px(24),
      ..((0, [Hôte], [bleu, trait plein]), (1, [VM invitée], [violet, tirets]), (2, [VM imbriquée], [rose, pointillés]))
        .map(((n, nom, proj)) => block(width: 100%, fill: c.nuit, radius: px(12), inset: px(12),
          cadre([#nom], niveau: n)[#text(size: px(20), fill: c.texte-term)[En projection : #proj]])))
  })
})

#let couverture(..args) = {
  couverture-seule(..args)
  if variante != "normal" { legende }
}
