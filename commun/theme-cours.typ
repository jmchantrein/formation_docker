// theme-cours.typ — charte commune des cours (virtualisation, Docker…) pour Touying.
// Reprend les couleurs, polices et proportions du deck HTML (maquette 1920 × 1080 px).

#import "@preview/touying:0.8.0": *
#import themes.simple: *

// ---------- Rôles pédagogiques ----------
// Le cours dit ce qu’est un bloc (son rôle) ; la charte décide de son apparence.
#let roles-def = (
  notion: (nom: "Notion", projection: "bleu", sens: "définir, expliquer"),
  retenir: (nom: "À retenir", projection: "bleu nuit", sens: "synthèse, point clé"),
  pratique: (nom: "Pratique", projection: "vert", sens: "exemple, démonstration, usage réel"),
  question: (nom: "Question", projection: "vert clair", sens: "exercice : ce qu’on demande de faire"),
  reponse: (nom: "Réponse", projection: "vert foncé", sens: "corrigé d’une question"),
  precaution: (nom: "Précaution", projection: "jaune", sens: "nuance, confusion fréquente, limite"),
  avertissement: (nom: "Avertissement", projection: "orange", sens: "erreur probable, mauvaise pratique"),
  danger: (nom: "Danger", projection: "rouge", sens: "risque réel : sécurité, perte de données"),
)

// ---------- Variantes de rendu ----------
// Choisies à la compilation : typst compile --input variante=<nom> …
// - projection (défaut) : rendu de projection, pensé pour la vision typique ;
// - deuteranopie, protanopie, tritanopie, achromatopsie : palette propre à chaque vision ;
// - dyslexie : lettres, mots et lignes plus espacés, ni capitales forcées ni italique.
// Chaque palette garde les rôles distincts pour la vision visée (écarts ΔE CIELAB simulés : Machado 2009
// pour les dichromasies, clarté seule pour l’achromatopsie) ; les pictogrammes doublent la couleur partout.
// Contraste du texte d’en-tête (blanc ou encre, choisi selon la clarté) et du texte sur terminal : ≥ 4,5.
// Clés : en-têtes des rôles ; invite / invite-clair (schémas) ; appli ; cadres de terminal hote-t, invite-t, imbrique-t.
#let palette-projection = (
  notion: rgb("#1F63C9"), pratique: rgb("#1E7A46"), question: rgb("#9BCCA9"), reponse: rgb("#004D1D"), retenir: rgb("#14213D"),
  precaution: rgb("#F2C94C"), avertissement: rgb("#B4530F"), danger: rgb("#B3123C"),
  invite: rgb("#7B3FB0"), invite-clair: rgb("#DDC4F5"), appli: rgb("#D3E4FB"),
  hote-t: rgb("#7DB4FF"), invite-t: rgb("#C9A7F5"), imbrique-t: rgb("#FF9EC4"),
)
// Dichromasies rouge-vert : seuls l’axe bleu/jaune et la clarté restent. Le vert passe au bleu-vert, le rouge
// s’assombrit, l’invité (violet, vu comme du bleu) devient ocre. Écart minimal entre rôles : 28 (deutéranopie),
// 23 (protanopie), contre 9 et 12 avec la palette de projection.
#let rouge-vert = (pratique: rgb("#006E7A"), question: rgb("#9CC9D0"), reponse: rgb("#004955"), danger: rgb("#7A0F2A"), invite: rgb("#7A5A00"),
  invite-clair: rgb("#EEDC9A"), invite-t: rgb("#E8C95A"), imbrique-t: rgb("#E8E8E8"))
#let palettes = (
  deuteranopie: rouge-vert,
  protanopie: rouge-vert,
  // Confusion bleu/vert et jaune/violet : le vert tire vers l’olive. Écart minimal : 18 → 28.
  tritanopie: (pratique: rgb("#6B6B00"), question: rgb("#C9C389"), reponse: rgb("#414300"), danger: rgb("#C2002F"), invite: rgb("#8E2C8C"),
    invite-clair: rgb("#F4C6E6"), invite-t: rgb("#F29ACB"), imbrique-t: rgb("#E9E39A")),
  // Sans couleur : une échelle de clarté L* (en-têtes retenir 8, danger 18, notion 28, pratique 38,
  // avertissement 48 ; en-têtes clairs à texte foncé : réponse 60, question 74, précaution 90 ; cadres 58/76/91).
  achromatopsie: (retenir: rgb("#10172A"), danger: rgb("#620019"), notion: rgb("#1A4082"),
    avertissement: rgb("#A76034"), pratique: rgb("#2D6441"), question: rgb("#90C19E"), reponse: rgb("#729A7D"), precaution: rgb("#FFDF8A"),
    invite: rgb("#714793"), invite-clair: rgb("#CCBADC"), appli: rgb("#E0ECFC"),
    hote-t: rgb("#6C8DBF"), invite-t: rgb("#CAB1E8"), imbrique-t: rgb("#FFDAF4")),
)
#let variantes = ("projection", "dyslexie") + palettes.keys()
#let variante = sys.inputs.at("variante", default: "projection")
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
  notion: rgb("#E8EFFA"), pratique: rgb("#E4F2E9"), question: rgb("#F0F8F2"), reponse: rgb("#DDEBE1"), retenir: rgb("#E6E9F0"),
  precaution: rgb("#FFF6D9"), avertissement: rgb("#FBE9DA"), danger: rgb("#FBE3E8"),
)
#let roles = roles-def.keys().map(r => {
  let entete = pal.at(r)
  let fond = if variante in palettes { color.mix((entete, 14%), (c.fond, 86%)) } else { fonds-projection.at(r) }
  // accent : texte coloré sur le fond clair du rôle (le jaune, trop clair, est assombri)
  let accent = if clarte(entete) > 0.3 { entete.darken(60%) } else { entete }
  (r, (entete: entete, fond: fond, texte: texte-sur(entete), accent: accent))
}).to-dict()

// Pictogramme d’un rôle : cerveau pour « à retenir », coureur en sueur pour pratique, question et réponse
// (dessins Tabler Icons, MIT, dans pictos/), triangle « ! » pour les trois niveaux d’alerte ; rien pour une notion.
// Dans les variantes seulement, le triangle est suivi d’un feu tricolore (précaution : feu du bas,
// avertissement : milieu, danger : haut) qui porte le niveau par la position, sans la couleur.
// Les dessins au trait paraissent plus petits qu’une forme pleine : on les agrandit d’un quart.
#let icone(fichier, couleur, t) = box(width: t * 1.25, height: t * 1.25, baseline: 24%,
  image(bytes(read(fichier).replace("currentColor", couleur.to-hex())), format: "svg", width: t * 1.25, height: t * 1.25))
#let picto(role, forme, glyphe, t: px(30)) = {
  if role == "retenir" { return icone("pictos/cerveau.svg", forme, t) }
  // le coureur signale un effort des étudiants : seulement sur les questions (« À vous »)
  if role == "question" { return icone("pictos/coureur.svg", forme, t) }
  let niveaux = ("danger", "avertissement", "precaution")  // de haut en bas
  if role not in niveaux { return none }
  let triangle = box(width: t, height: t, baseline: 18%, {
    polygon(fill: forme, (t * 0.5, 0pt), (t, t * 0.95), (0pt, t * 0.95))
    place(top + left, dy: t * 0.2, box(width: t, height: t * 0.8,
      align(center + horizon, text(size: t * 0.62, weight: 700, fill: glyphe, top-edge: "cap-height", bottom-edge: "baseline", "!"))))
  })
  let d = t * 0.27
  let feu = box(baseline: 18%, height: t, stroke: t * 0.06 + forme, radius: t * 0.2,
    inset: (x: t * 0.07, y: t * 0.04),
    stack(spacing: t * 0.04, ..niveaux.map(n => circle(radius: d / 2,
      fill: if n == role { forme } else { none }, stroke: t * 0.05 + forme))))
  if variante == "projection" { return triangle }
  triangle; h(t * 0.15); feu
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
  // le code d'un titre prend la couleur du titre (sinon : code bleu sur en-tête bleu)
  show raw: set text(fill: r.texte)
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
// Avec uncover (diapo animée), la ligne i apparaît au clic debut + i.
#let lignes(largeur: px(260), taille-cle: px(36), taille: px(30), uncover: none, debut: 1, ..paires) = {
  let ps = paires.pos()
  let montre(i, x) = if uncover == none { x } else { uncover(str(debut + i) + "-", x) }
  grid(columns: (largeur, 1fr), align: horizon,
    inset: (x, y) => (y: px(12), left: if x == 1 { px(40) } else { 0pt }),
    stroke: (x, y) => if y < ps.len() - 1 { (bottom: px(1) + c.filet) },
    ..ps.enumerate().map(((i, (k, v))) => (montre(i, text(size: taille-cle, weight: 600, fill: c.bleu, k)),
      montre(i, text(size: taille, v)))).flatten())
}

// Plan du cours : numéro, titre de partie, description.
#let plan-cours(uncover: none, ..parties) = {
  let ps = parties.pos()
  let montre(i, x) = if uncover == none { x } else { uncover(str(i + 1) + "-", x) }
  grid(columns: (px(96), 1fr), align: horizon, column-gutter: px(40),
    inset: (y: px(16)),
    stroke: (x, y) => if y < ps.len() - 1 { (bottom: px(1) + c.filet) },
    ..ps.enumerate().map(((i, (t, d))) => (
      montre(i, text(size: px(64), weight: 600, fill: c.bleu, str(i + 1))),
      montre(i, { text(size: px(40), weight: 600, t); linebreak(); text(size: px(32), fill: c.ardoise, d) }),
    )).flatten())
}

// ---------- Corrigé de TP ----------
// La question porte le vert clair du rôle « question » ; la réponse, une barre vert foncé.
#let question(n, corps) = grid(columns: (auto, 1fr), column-gutter: px(12),
  box(fill: roles.question.entete, radius: px(6), inset: (x: px(10), y: px(2)),
    text(size: px(22), weight: 600, fill: roles.question.texte, str(n))),
  text(size: px(26), fill: c.ardoise, corps))
#let reponse(corps) = block(width: 100%, stroke: (left: px(8) + roles.reponse.entete), inset: (left: px(16)), corps)

#let filet-corrige = line(length: 100%, stroke: px(2) + rgb("#C9D6EA"))

// La réponse s’écrit reponse(...) dans le cours, à l’intérieur de son uncover : la barre apparaît avec elle.
#let corrige(n, q, rep) = grid(columns: (px(700), 1fr), column-gutter: px(32),
  question(n, q), rep)

// Plusieurs questions et leurs réponses sur une diapo : la question reste visible, chaque réponse apparaît
// à son clic. items : (n, [question], reponse[…]) ; la réponse s’écrit avec reponse(…).
#let corriges(note: none, ..items) = {
  let qa = items.pos()
  slide(repeat: qa.len() + 1, self => {
    let (uncover,) = utils.methods(self)
    for (i, it) in qa.enumerate() {
      corrige(it.at(0), it.at(1), uncover(str(i + 2) + "-", it.at(2)))
      if i < qa.len() - 1 { v(px(16)) }
    }
    if note != none { utils.speaker-note(self: self, note) }
  })
}

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
// Illustrations de couverture : « vm » (trois VM sur un hyperviseur, sur le matériel) ou
// « couches » (les couches d’une image : trois en lecture seule, une en lecture/écriture au sommet).
#let illustrations = (
  vm: stack(spacing: px(16),
    grid(columns: (px(176),) * 3, column-gutter: px(16),
      ..range(3).map(_ => box(width: px(176), height: px(96), fill: c.invite-t, radius: px(12)))),
    box(width: px(560), height: px(56), fill: c.hote-t, radius: px(12)),
    box(width: px(560), height: px(56), fill: c.gris, radius: px(12)),
  ),
  // couches d'image en lecture seule : un dégradé de bleus, du plus sombre (base) au plus clair ;
  // au sommet, la couche du conteneur en lecture/écriture, claire et bordée de tirets
  couches: stack(spacing: px(14),
    box(width: px(560), height: px(56), radius: px(12), fill: c.hote-t.transparentize(80%),
      stroke: (paint: c.hote-t, thickness: px(3), dash: "dashed")),
    ..(70%, 45%, 20%).map(p => box(width: px(560), height: px(56), radius: px(12),
      fill: color.mix((c.hote-t, p), (c.nuit, 100% - p)))),
  ),
)

#let page-titre(titre, sous-titre, auteur, date, surtitre: "Cours · LERIA", illustration: "vm") = touying-slide-wrapper(self => {
  self = utils.merge-dicts(self,
    config-common(subslide-preamble: none),
    config-page(fill: c.nuit, footer: none, margin: px(128)))
  touying-slide(self: self, {
    place(top + left, dx: px(1104), dy: px(184), illustrations.at(illustration))
    text(size: px(24), weight: 600, tracking: px(2), fill: c.prompt, maj(surtitre))
    v(1fr)
    block(width: px(1040), {
      // un titre trop long pour sa place (1040 px) est réduit pour ne pas chevaucher l'illustration
      context {
        let w = measure(text(size: px(144), weight: 600, titre)).width
        let k = calc.min(1, px(1040) / w)
        text(size: px(144) * k, weight: 600, fill: c.fond, titre)
      }
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
    v(px(12), weak: true)
    text(size: px(52), weight: 600)[Lire les couleurs de ce rendu]
    v(px(16))
    grid(columns: (1fr, 1fr), column-gutter: px(32), row-gutter: px(14),
      ..roles-def.pairs().map(((r, d)) => block(width: 100%, radius: px(12), clip: true, fill: roles.at(r).fond, stack(
        block(width: 100%, fill: roles.at(r).entete, inset: (x: px(24), y: px(8)), entete-role(r, d.nom, px(26))),
        block(width: 100%, inset: (x: px(24), y: px(8)), text(size: px(22))[
          #d.sens. En projection : *#d.projection*.]),
      ))))
    v(px(16))
    grid(columns: (1fr, 1fr, 1fr), column-gutter: px(24),
      ..((0, [Hôte], [bleu, trait plein]), (1, [VM invitée], [violet, tirets]), (2, [VM imbriquée], [rose, pointillés]))
        .map(((n, nom, proj)) => block(width: 100%, fill: c.nuit, radius: px(12), inset: px(12),
          cadre([#nom], niveau: n)[#text(size: px(20), fill: c.texte-term)[En projection : #proj]])))
  })
})

#let couverture(..args) = {
  page-titre(..args)
  if variante != "projection" { legende }
}

// Page de clôture, dans le même design que la couverture :
// #cloture(illustration: …)[Merci][Des questions ?][auteur][contact ou lien]
#let cloture(..args) = page-titre(..args)

// ---------- Animation : bloc par bloc, puis puce par puce ----------
// Les apparitions passent par uncover (le contenu caché garde sa place) : seules des apparitions,
// exportables en PDF. Un bloc apparaît avec sa première puce, chaque puce suivante au clic suivant.
#let _morceaux(corps) = if corps.func() == [].func() { corps.children } else { (corps,) }
#let _puce(e) = e.func() in (list.item, enum.item)
// Nombre de clics d’un bloc : un par puce, au moins un.
#let etapes-bloc(b) = calc.max(1, _morceaux(b.corps).filter(_puce).len())

#let _corps-anime(corps, debut, uncover) = {
  show list: set block(spacing: 0.5em)
  show enum: set block(spacing: 0.5em)
  let k = 0
  for e in _morceaux(corps) {
    if e.func() == list.item { uncover(str(debut + k) + "-", list(e)); k += 1 }
    else if e.func() == enum.item { uncover(str(debut + k) + "-", enum(start: k + 1, e.body)); k += 1 }
    else { e }
  }
}

// Un bloc animé à partir du clic `debut`.
#let bloc-anime(b, debut, uncover, hauteur: auto) = uncover(str(debut) + "-",
  rendre-bloc((..b, corps: _corps-anime(b.corps, debut, uncover)), hauteur: hauteur))

// Une rangée de blocs côte à côte, à hauteur égale, pour anime().
#let rang(gouttiere: px(32), ..blocs) = (rang: blocs.pos(), gouttiere: gouttiere)

// Source d’un fait, en bas de diapo.
#let source(corps) = place(bottom + left, dy: px(56),
  text(size: px(18), fill: c.gris)[Source : #corps])

// Diapo animée : les éléments (rangées de blocs, ou contenu quelconque) apparaissent dans l’ordre,
// bloc par bloc puis puce par puce ; un contenu quelconque (bandeau, schéma) compte pour un clic.
#let anime(espacement: px(24), note: none, source-de: none, ..elements) = {
  let plan = ()
  let s = 1
  for e in elements.pos() {
    if type(e) == dictionary and "rang" in e {
      let debuts = ()
      for b in e.rang { debuts.push(s); s += etapes-bloc(b) }
      plan.push((e, debuts))
    } else if type(e) == dictionary and "etapes" in e {
      plan.push((e, s)); s += e.etapes
    } else { plan.push((e, s)); s += 1 }
  }
  slide(repeat: s - 1, self => {
    let (uncover,) = utils.methods(self)
    for (i, (e, d)) in plan.enumerate() {
      if i > 0 { v(espacement) }
      if type(e) == dictionary and "rang" in e {
        rangee(gouttiere: e.gouttiere, poids: e.rang.map(b => b.poids),
          ..e.rang.zip(d).map(((b, db)) => h => bloc-anime(b, db, uncover, hauteur: h)))
      } else if type(e) == dictionary and "etapes" in e { (e.rendu)(uncover, d) }
      else { uncover(str(d) + "-", e) }
    }
    if source-de != none { source(source-de) }
    if note != none { utils.speaker-note(self: self, note) }
  })
}

// Éléments à plusieurs clics, pour anime() : `pas(n, (uncover, debut) => …)` occupe n clics à partir de debut.
#let pas(n, rendu) = (etapes: n, rendu: rendu)
// Une ligne de `lignes` par clic.
#let lignes-anime(..args) = pas(args.pos().len(), (u, d) => lignes(uncover: u, debut: d, ..args))
// Terminal dont les morceaux apparaissent un par clic : terminal-etapes([```…```], [```…```], titre: …).
#let terminal-etapes(titre: "Terminal", taille: px(20), ..morceaux) = pas(morceaux.pos().len(), (u, d) =>
  terminal(titre: titre, taille: taille, morceaux.pos().enumerate().map(((i, m)) => u(str(d + i) + "-", m)).join()))
// Plan du cours, une partie par clic.
#let plan-anime(..parties) = pas(parties.pos().len(), (u, d) => plan-cours(uncover: (v, x) => u(str(d - 1 + int(v.split("-").at(0))) + "-", x), ..parties))
