// Cours « Fondements de la virtualisation de machines » — Typst + Touying.
// Compilation : typst compile --font-path fonts virtualisation.typ
// Une diapo = un titre `==` ; une section (surtitre bleu) = un titre `=`.

#import "theme-cours.typ": *

#show: cours-theme.with(
  auteur: [Jean-Mathieu Chantrein],
  titre-court: [Fondements de la virtualisation de machines],
)

#couverture[Virtualisation][Fondements de la virtualisation de machines][Jean-Mathieu Chantrein][12 novembre 2026]
#speaker-note[À droite : trois VM (orange) sur un hyperviseur (bleu), lui-même sur le matériel (gris). Cours compagnon : Docker, fondements de la conteneurisation.]

// ======================================================================
= Sommaire

== Plan du cours

#plan-cours(
  ([Introduction], [Machine physique et système d’exploitation]),
  ([Concepts], [Émulation et virtualisation, assistance matérielle, types d’hyperviseur, paravirtualisation, QEMU et KVM]),
  ([Usages], [Architecture et bilan, migration à chaud, virtualisation imbriquée, ISO et sommes de contrôle, KVM en pratique, mini TP, outils de gestion, Qubes OS]),
  ([Pour aller plus loin], [MicroVM, et les conteneurs ?]),
)

// ======================================================================
= Introduction

== Machine physique et système d’exploitation

#colonnes(
  bloc(taille: px(32))[Machine physique][
    - L’ordinateur : serveur, PC, Mac…
    - Fabriquée avec des composants électroniques
    - Programmable : on peut lui faire exécuter des programmes
    - Très puissante en calcul binaire, mais elle ne sait faire que cela
  ],
  bloc(taille: px(32))[Système d’exploitation (OS)][
    - Un programme qui assure la communication entre les logiciels et les composants (RAM, disque, carte réseau…)
    - Organise et planifie l’exécution des autres programmes
    - Son noyau seul accède directement au matériel (mode privilégié)
  ],
)

// ======================================================================
= Concepts

== Émuler ou virtualiser ?

#colonnes(
  bloc[Émulation][
    - Le logiciel interprète ou traduit chaque instruction d’un autre processeur
    - Universel : du code ARM sur un PC x86
    - Lent : chaque instruction coûte plusieurs instructions réelles
  ],
  bloc[Virtualisation][
    - Les instructions de la VM s’exécutent directement sur le vrai processeur
    - Seules les opérations privilégiées sont interceptées par l’hyperviseur
    - Proche du natif, mais même architecture que l’hôte
  ],
)
#espace
#colonnes(bloc[À retenir][
  Une VM n’est pas, en général, une machine émulée. *QEMU* (_Quick EMUlator_, « émulateur rapide », Fabrice Bellard, 2003) sait pourtant faire les deux : exemple à la diapositive suivante.
])

#speaker-note[QEMU sait faire les deux : sans KVM, il émule le processeur (TCG, traduction binaire dynamique) ; avec -enable-kvm, il délègue l’exécution au processeur réel et n’émule plus que les périphériques.]

== Émuler ou virtualiser : l’exemple de QEMU

#colonnes(
  bloc(taille: px(25))[Émulation : une machine ARM sur un PC x86][
    #terminal(taille: px(24))[
      ```
      # le processeur invité est émulé (TCG)
      $ qemu-system-aarch64 -M virt -cpu cortex-a57 …
      ```
    ]
    - *`qemu-system-aarch64`* : émule une machine complète à processeur ARM 64 bits (un binaire qemu-system-\* par architecture invitée)
    - *`-M virt`* : type de machine (alias de -machine) ; « virt » est une carte générique, sans équivalent matériel réel
    - *`-cpu cortex-a57`* : modèle de processeur présenté à l’invité : ARM Cortex-A57, architecture ARMv8-A, 64 bits (AArch64)
    - *`…`* : reste de la commande : mémoire, disque, noyau ou firmware
  ],
  bloc(entete: c.vert, fond: c.vert-clair, taille: px(25))[Virtualisation : une machine x86 sur un PC x86][
    #terminal(taille: px(24))[
      ```
      # le processeur invité est le vrai processeur
      $ qemu-system-x86_64 -enable-kvm -m 2048 …
      ```
    ]
    - *`qemu-system-x86_64`* : fournit une machine PC à processeur x86 64 bits, la même architecture que l’hôte
    - *`-enable-kvm`* : confie l’exécution du code invité à KVM (équivaut à -accel kvm) ; sans cette option, QEMU émule le processeur avec *TCG* (_Tiny Code Generator_, son traducteur binaire)
    - *`-m 2048`* : mémoire vive de la VM, en mébioctets par défaut : ici 2 Gio
    - *`…`* : reste de la commande : disque, réseau, affichage
  ],
)

#speaker-note[Le même logiciel fait les deux. À gauche, l’hôte x86 ne sait pas exécuter du code ARM : QEMU traduit chaque bloc d’instructions (TCG, Tiny Code Generator). Le Cortex-A57 (2012) est un des premiers cœurs ARMv8-A 64 bits ; -cpu max donne toutes les fonctions émulables. À droite, -enable-kvm exige /dev/kvm et une architecture invitée identique à celle de l’hôte. -m accepte un suffixe : -m 2G. Commandes non rejouées ici (pas de QEMU/KVM dans l’environnement de vérification).]

== Virtualiser le x86 : une longue histoire

#lignes(
  ([1974], [Popek et Goldberg : conditions pour qu’une architecture soit virtualisable]),
  ([1999], [VMware : le x86 ne les remplit pas, traduction binaire des instructions sensibles]),
  ([2003], [Xen : paravirtualisation, le noyau invité est modifié pour coopérer]),
  ([2005–2006], [Intel VT-x, puis AMD-V : extensions matérielles de virtualisation]),
  ([2007], [KVM intégré au noyau Linux (2.6.20) : Linux devient hyperviseur]),
  ([2007–2008], [AMD RVI (NPT) puis Intel EPT : la traduction d’adresses de la VM aussi en matériel]),
)

== Deux types d’hyperviseur

#colonnes(
  bloc[Type 1 : natif (bare metal)][
    - S’exécute directement sur le matériel
    - Xen, VMware ESXi, Microsoft Hyper-V
    - KVM : un module qui fait du noyau Linux l’hyperviseur ; Proxmox VE = Debian + KVM
  ],
  bloc[Type 2 : hébergé (hosted)][
    - Application lancée sur un OS hôte
    - VirtualBox, VMware Workstation, Parallels Desktop
    - Pratique sur un poste de travail ; même VT-x, mais ressources et entrées-sorties partagées avec l’OS hôte
  ],
)
#espace
#colonnes(bloc(entete: c.orange, fond: c.orange-clair)[Ce qu’il faut bien comprendre][
  - La frontière entre les deux types est floue : KVM et Hyper-V sont classés en type 1, alors qu’ils s’appuient sur un système d’exploitation complet (Linux pour KVM, Windows pour Hyper-V)
  - Le type d’hyperviseur ne dit pas si le système invité sait qu’il tourne dans une VM : c’est une autre question, celle de la paravirtualisation, traitée deux diapositives plus loin
])

== KVM ou Xen : deux architectures

#grid(columns: (1fr, 1fr), column-gutter: px(64),
  pile-archi([KVM : Linux est l’hyperviseur], [Espace utilisateur de l’hôte],
    [*Gestion* (crée, démarre, arrête) : libvirt],
    (vm[VM 1 : QEMU], vm[VM 2 : QEMU]),
    [Noyau Linux de l’hôte], ([module kvm],), [Matériel (VT-x / AMD-V)]),
  pile-archi([Xen : l’hyperviseur sous Linux], [Domaines (VM)],
    [Toutes les VM, dom0 compris, sont au-dessus de Xen],
    (vm(couleur: c.bleu, haut: [Gestion : xl], bas: [Linux + pilotes], taille: px(26))[dom0 (privilégié)],
     vm[domU 1 : VM], vm[domU 2 : VM]),
    [Hyperviseur Xen (type 1)], ([processeurs], [mémoire]),
    [Matériel (VT-x / AMD-V pour HVM et PVH)]),
)

#speaker-note[KVM : le noyau Linux devient l’hyperviseur ; chaque VM est un processus QEMU de l’hôte, gérée par libvirt. Xen : l’hyperviseur démarre en premier, directement sur le matériel, et ne gère que les processeurs et la mémoire. Linux tourne au-dessus, dans dom0, une VM privilégiée qui porte les pilotes de périphériques et les outils de gestion (xl, ou libvirt). Les VM ordinaires sont des domU. Xen peut faire tourner des VM paravirtualisées classiques (PV) sans VT-x / AMD-V ; les VM complètes (HVM) et le mode PVH, recommandé aujourd’hui, en ont besoin : en pratique un hôte Xen actuel les utilise. Exemples : XCP-ng et XenServer (ex-Citrix Hypervisor) reposent sur Xen ; AWS a utilisé Xen avant de passer à son hyperviseur Nitro, fondé sur KVM (à partir de 2017) ; Proxmox VE et OpenStack reposent le plus souvent sur KVM.]

== Virtualisation complète ou paravirtualisation

#colonnes(
  bloc[Virtualisation complète][
    - Le système invité n’est pas modifié : il croit tourner sur une vraie machine et ignore qu’il est virtualisé
    - Périphériques émulés (carte réseau e1000, disque IDE) : compatibles mais lents
  ],
  bloc[Paravirtualisation][
    - Le système invité sait qu’il est virtualisé : il coopère en appelant directement l’hyperviseur (hypercalls)
    - Xen PV : noyau invité modifié
    - Aujourd’hui : pilotes paravirtualisés (virtio) dans des VM complètes
  ],
)
#espace
#colonnes(bloc(entete: c.orange, fond: c.orange-clair)[Ce qu’il faut bien comprendre][
  Que le système invité sache ou non qu’il est virtualisé ne dépend pas du type d’hyperviseur : une VM sous KVM (type 1) comme sous VirtualBox (type 2) peut utiliser des pilotes virtio.
])

#speaker-note[Correction par rapport à l’ancienne version du cours, qui associait « VM aware » au type 1 et « no aware » au type 2.]

== QEMU et KVM : deux rôles complémentaires

#grid(columns: (1fr, 1.3fr), column-gutter: px(40),
  stack(spacing: px(8),
    block(width: 100%, stroke: px(3) + c.orange, radius: px(12), inset: px(12), stack(spacing: px(8),
      align(center, text(size: px(24), weight: 600, fill: c.orange)[Processus QEMU (espace utilisateur)]),
      block(width: 100%, height: px(72), fill: c.os, radius: px(8),
        align(center + horizon, text(weight: 600)[VM : OS invité et applis])),
      block(width: 100%, height: px(72), fill: c.appli, radius: px(8),
        align(center + horizon, text(size: px(26), weight: 600)[Périphériques émulés, mémoire])),
    )),
    align(center, text(size: px(24), weight: 600, fill: c.gris)[appels à /dev/kvm]),
    couche([Noyau Linux : module kvm], taille: px(28)),
    couche([Processeur avec VT-x / AMD-V], fond: c.ardoise, taille: px(28)),
  ),
  stack(spacing: px(20),
    rendre-bloc(bloc(taille: px(26))[QEMU][
      - Espace utilisateur : fournit la machine (périphériques, mémoire, BIOS/UEFI)
      - Seul, il émule aussi le processeur (TCG) : lent, toute architecture
    ]),
    rendre-bloc(bloc(taille: px(26))[KVM][
      - Module du noyau (2007) : le processeur exécute le code de la VM
      - Aucun périphérique : il faut un programme comme QEMU
    ]),
    rendre-bloc(bloc(entete: c.orange, fond: c.orange-clair, taille: px(26))[Ensemble][
      QEMU pour la machine, KVM pour la vitesse.
    ]),
  ),
)

#speaker-note[Une VM sous Linux, c’est un processus QEMU : ps sur l’hôte la montre (qemu-system-x86\_64). QEMU demande au module kvm, via /dev/kvm, d’exécuter le code de la VM directement sur le processeur ; le processeur rend la main au noyau (sortie de VM) pour les opérations privilégiées et les accès aux périphériques, que QEMU émule (ou que des pilotes virtio rendent rapides). KVM sert aussi sans QEMU : Firecracker (AWS Lambda), crosvm (ChromeOS), Cloud Hypervisor.]

// ======================================================================
= Usages

== Architecture simplifiée et bilan

// 10 étapes : schéma seul, puis un point par clic (5 avantages, 4 inconvénients).
#slide(repeat: 10, self => {
  let (uncover,) = utils.methods(self)
  grid(columns: (px(800), 1fr), column-gutter: px(72),
    stack(spacing: px(8),
      grid(columns: (1fr,) * 3, column-gutter: px(16),
        ..range(1, 4).map(i => vm(haut: [Applis], case: px(64))[VM #i])),
      couche[Hyperviseur],
      couche(fond: c.ardoise)[Machine physique],
    ),
    {
      uncover("2-", colonnes(bloc[Avantages][
        #utils.item-by-item(self: self, start: 2)[
          - Portabilité des VM
          - Isolation forte des applications
          - Mutualisation des ressources, à la demande
          - Snapshots et migration à chaud
          - Démarrage plus rapide qu’une machine réelle
        ]
      ]))
      espace
      uncover("7-", colonnes(bloc(entete: c.orange, fond: c.orange-clair)[Inconvénients][
        #utils.item-by-item(self: self, start: 7)[
          - Performance inférieure à l’exécution native
          - Forte consommation de mémoire vive
          - Forte consommation de disque
          - Démarrage plus lent qu’un conteneur
        ]
      ]))
    },
  )
  utils.speaker-note(self: self)[Comme dans le cours d’origine, les avantages puis les inconvénients apparaissent un par un (un clic par point).]
})

== La migration à chaud

#let hote(nom) = block(width: px(600), height: px(408), fill: rgb("#FCFCFA"),
  stroke: px(1) + rgb("#DDE1E6"), radius: px(16), inset: px(24), text(size: px(32), weight: 600, nom))
#let mvm(nom, fond: c.appli, couleur: c.encre, bas: [OS + appli], trait: none) = block(
  width: px(176), height: px(100), fill: fond, stroke: trait, radius: px(12),
  align(center + horizon, stack(spacing: px(6),
    text(size: px(28), weight: 600, fill: couleur, nom), text(size: px(24), fill: couleur, bas))))
#let barre(t, fond) = block(width: px(552), height: px(80), fill: fond, radius: px(12),
  align(center + horizon, text(size: px(32), weight: 600, fill: c.fond, t)))
#let etape(n, t) = block(width: px(440),
  align(center, text(size: px(28))[#text(weight: 600, fill: c.orange)[#n.] #t]))
#let fleche = polygon(fill: c.ambre, (0pt, px(27)), (px(156), px(27)), (px(156), 0pt),
  (px(240), px(45)), (px(156), px(90)), (px(156), px(63)), (0pt, px(63)))

// 8 étapes, comme le schéma au tableau : hôte A, hôte B, stockage, pré-copie,
// pages modifiées, bascule, puis l'encadré final. Coordonnées en px de la maquette.
#slide(repeat: 8, self => {
  let (uncover,) = utils.methods(self)
  // Canevas un peu moins haut que son contenu : les éléments posés peuvent déborder
  // dans la marge basse, comme dans le deck HTML, sans créer de page supplémentaire.
  block(width: 100%, height: px(640), {
    uncover("2-", {
      pose(0, 0, hote[Hôte A])
      pose(24, 88, mvm[VM 1])
      pose(212, 88, mvm[VM 2])
      pose(24, 212, barre([Hyperviseur], c.nuit))
      pose(24, 304, barre([Matériel (CPU, RAM)], c.ardoise))
    })
    uncover("2-6", pose(400, 88, mvm(fond: c.os)[VM 3]))
    uncover("3-", {
      pose(1064, 0, hote[Hôte B])
      pose(1088, 88, mvm[VM 4])
      pose(1464, 88, mvm[VM 5])
      pose(1088, 212, barre([Hyperviseur], c.nuit))
      pose(1088, 304, barre([Matériel (CPU, RAM)], c.ardoise))
    })
    uncover("4-", {
      pose(297, 408, rect(width: px(6), height: px(80), fill: c.gris))
      pose(1361, 408, rect(width: px(6), height: px(80), fill: c.gris))
      pose(0, 488, block(width: px(1664), height: px(100), fill: c.nuit, radius: px(16),
        align(center + horizon, text(size: px(32), weight: 600, fill: c.fond)[Stockage partagé (SAN, NFS, Ceph) : le disque de la VM reste en place])))
    })
    uncover("5-", pose(612, 28, etape(1)[Copie de la mémoire, la VM continue de tourner]))
    uncover("5-6", {
      pose(712, 318, fleche)
      pose(1276, 88, mvm(fond: none, couleur: c.orange, bas: [copie],
        trait: (paint: c.orange, thickness: px(2), dash: "dashed"))[VM 3])
    })
    uncover("6-", pose(612, 124, etape(2)[Recopie des pages modifiées entre-temps]))
    uncover("7-", {
      pose(612, 220, etape(3)[Bascule : pause très brève, reprise sur B])
      pose(1276, 88, mvm(fond: c.os)[VM 3])
    })
    uncover("8-", pose(0, 612, block(width: px(1664), rangee(gouttiere: px(28), poids: (1, 1.35),
      h => block(width: 100%, height: h, fill: c.bleu-clair, radius: px(12), inset: (x: px(20), y: px(12)),
        align(horizon, text(size: px(22), weight: 600, fill: c.bleu)[Intérêt : maintenir ou rééquilibrer un hôte sans coupure de service.])),
      h => block(width: 100%, height: h, fill: c.orange-clair, radius: px(12), inset: (x: px(20), y: px(12)),
        align(horizon, text(size: px(22))[#text(weight: 600, fill: c.orange)[En vrai :] un cluster fait au moins *3 hôtes* (quorum → pas de _split-brain_ si un hôte tombe). #text(weight: 600, fill: c.orange)[Avant de basculer], vérifier que l’hôte cible a assez de *CPU/RAM libres*.])),
    ))))
  })
  utils.speaker-note(self: self)[Schéma dessiné pas à pas, un clic par étape (comme au tableau). 1. Hôte A : matériel, hyperviseur, trois VM. 2. Hôte B. 3. Stockage partagé : le disque de la VM n’a pas à être copié (sans stockage partagé, il faut aussi migrer les disques). 4. Pré-copie : la mémoire de VM 3 est envoyée vers B pendant que la VM continue de tourner. 5. Les pages modifiées entre-temps sont recopiées, en boucle, jusqu’à ce qu’il en reste très peu. 6. Bascule : la VM est brièvement suspendue, son dernier état est transféré, elle reprend sur B et disparaît de A. 7. Usage : maintenance ou équilibrage de charge sans coupure. Réalité d’un cluster : au moins 3 hôtes pour le quorum (Proxmox VE, vSphere HA : une majorité de nœuds doit rester jointe pour éviter le split-brain et relancer les VM d’un hôte défaillant). La migration à chaud elle-même ne demande que 2 hôtes, mais la haute disponibilité qui l’entoure en demande 3. Avant chaque bascule (manuelle ou automatique via DRS/HA), l’ordonnanceur vérifie que l’hôte cible a les ressources CPU/RAM libres ; on garde donc une marge sur chaque hôte pour absorber la panne d’un autre. Côté conteneurs : le conteneur est sans état et jetable, on le recrée ailleurs plutôt que de le migrer ; le checkpoint/restore (CRIU) existe mais reste un cas particulier.]
})

== Virtualisation imbriquée (nested)

#colonnes(
  bloc(taille: px(26))[Une VM dans une VM][
    - L’hyperviseur expose les extensions VT-x / AMD-V à la VM, qui peut à son tour lancer des VM
    - Usages : formation, laboratoires, intégration continue, cloud
    - Coût : chaque niveau ajoute des passages par l’hyperviseur
    - On imbrique aussi des conteneurs dans une VM : très courant (Docker Desktop, cloud)
  ],
  bloc(entete: c.vert, fond: c.vert-clair, poids: 1.25)[Avec KVM : trois niveaux][
    #terminal(titre: none)[
      #cadre([Hôte (niveau 0)], c.prompt)[
        ```
        $ cat /sys/module/kvm_intel/parameters/nested
        Y
        $ qemu-system-x86_64 -enable-kvm -cpu host …
        ```
        #cadre([VM (niveau 1)], c.ambre)[
          ```
          $ ls /dev/kvm
          /dev/kvm
          $ qemu-system-x86_64 -enable-kvm …
          ```
          #cadre([VM imbriquée (niveau 2)], c.menthe)[
            ```
            $ systemd-detect-virt
            kvm
            ```
          ]
        ]
      ]
    ]
    #text(size: px(22))[Chaque cadre est une machine lancée par la commande `qemu` juste au-dessus.]
  ],
)

#speaker-note[Lecture des couleurs : bleu = terminal de l’hôte physique (niveau 0) ; orange = terminal de la VM lancée par la première commande qemu (niveau 1) ; vert = terminal de la VM lancée depuis cette VM (niveau 2). -cpu host transmet les extensions vmx/svm à la VM, d’où la présence de /dev/kvm au niveau 1. Sur AMD : /sys/module/kvm\_amd/parameters/nested (affiche 1). Sorties typiques, non rejouées (pas de KVM dans l’environnement de préparation).]

== Prérequis : quelle image Debian prendre

#colonnes(
  bloc(taille: px(26))[Où la trouver, quoi prendre][
    - *Source officielle uniquement* : debian.org/download, qui renvoie vers cdimage.debian.org
    - Image *netinst amd64* (756 Mio) : installateur minimal, les paquets viennent ensuite du réseau
    - Le dossier « current » suit la dernière version (13.7.0 en novembre 2026) : le nom du fichier change à chaque mise à jour
  ],
  bloc(entete: c.vert, fond: c.vert-clair, taille: px(24))[Trois fichiers à télécharger][
    - *debian-13.7.0-amd64-netinst.iso* : l’image elle-même
    - *SHA256SUMS* : les sommes de contrôle des images
    - *SHA256SUMS.sign* : la signature de ce fichier par Debian
  ],
)
#espace
#colonnes(bloc(entete: c.orange, fond: c.orange-clair, taille: px(26))[Attention : une image téléchargée se vérifie avant usage][
  - *Intégrité* : le fichier est-il arrivé intact (téléchargement interrompu, disque, miroir défaillant) ? → somme de contrôle
  - *Authenticité* : est-ce bien l’image publiée par Debian, et pas une image piégée ? → signature
])

#speaker-note[Les trois fichiers — image, SHA256SUMS, SHA256SUMS.sign — sont dans le même dossier du dépôt, d’où le préfixe \$URL\_BASE commun ; on les met dans un répertoire local dédié (ici \~/iso-debian). Le mini TP installe une VM Debian : il faut d’abord l’image d’installation. debian.org/download pointe vers l’image netinst amd64 et vers SHA256SUMS et SHA256SUMS.sign. Téléchargement rejoué le 16 novembre 2026 : image de 792 723 456 octets (756 Mio). Une image piégée installe un système compromis dès le départ : exemple réel, le site de Linux Mint a distribué une ISO modifiée en février 2016. La diapositive suivante définit la somme de contrôle ; le téléchargement et la vérification sont regroupés sur la diapositive « Télécharger et vérifier l’ISO ».]

== Somme de contrôle : définition

#colonnes(
  bloc(taille: px(26))[Définition][
    - Une *fonction de hachage* calcule, à partir d’un fichier de taille quelconque, une *empreinte* de taille fixe
    - SHA-256 : 256 bits, soit 64 chiffres hexadécimaux (128 pour SHA-512)
    - Même contenu : toujours la même empreinte
    - Un seul bit modifié : une empreinte complètement différente
  ],
  bloc(entete: c.vert, fond: c.vert-clair, poids: 1.1, taille: px(24))[Démonstration][
    #terminal[
      ```
      $ echo bonjour | sha256sum
      9cec0af545144159bac85c7b908d5e0b9b0ef961…  -
      $ echo Bonjour | sha256sum
      8dc2a6966f1be1644ec6b1f7223f47e53de5ad05…  -
      $ sha256sum debian-13.7.0-amd64-netinst.iso
      a7ef94ac2fb9a7fec454552abd629b7cc9d5155c…  debian-…
      ```
    ]
    Une lettre change, toute l’empreinte change. 756 Mio ou 8 octets : même longueur d’empreinte.
  ],
)
#espace
#colonnes(bloc(taille: px(26))[À quoi ça sert][
  On calcule l’empreinte du fichier reçu et on la compare à l’empreinte publiée par l’éditeur. Identiques : le fichier est *intact*. Somme de contrôle, empreinte, condensat, hash : synonymes ici.
])

#speaker-note[Sorties réelles (coreutils), tronquées à 40 chiffres hexadécimaux pour tenir sur la diapositive ; le « … » marque la coupe. Le tiret final signifie « entrée standard ». Empreintes complètes : bonjour = 9cec0af545144159bac85c7b908d5e0b9b0ef961497401c5ad8da26f065ad926 ; Bonjour = 8dc2a6966f1be1644ec6b1f7223f47e53de5ad05e1c976736d948e7977a13dd3 ; ISO 13.7.0 = a7ef94ac2fb9a7fec454552abd629b7cc9d5155c886165a45649f5ce6167e355. Deux fichiers différents peuvent en théorie avoir la même empreinte (collision) ; une fonction cryptographique rend cette recherche impraticable.]

== Télécharger et vérifier l’ISO, en une fois

#rangee(poids: (1.35, 1),
  h => terminal(titre: [Terminal — télécharger, puis vérifier], taille: px(19), hauteur: h)[
    ```
    # 1. un répertoire dédié, tout au même endroit
    $ mkdir -p ~/iso-debian && cd ~/iso-debian
    $ URL_BASE=https://cdimage.debian.org/debian-cd/current/amd64/iso-cd
    $ wget $URL_BASE/debian-13.7.0-amd64-netinst.iso
    $ wget $URL_BASE/SHA256SUMS
    $ wget $URL_BASE/SHA256SUMS.sign
    # 2. authenticité : ces empreintes viennent-elles de Debian ?
    $ sudo apt install debian-keyring
    $ gpgv --keyring /usr/share/keyrings/debian-role-keys.pgp \
           SHA256SUMS.sign SHA256SUMS
    gpgv: Good signature from "Debian CD signing key"
    # 3. intégrité : l’image correspond-elle à son empreinte ?
    $ sha256sum -c --ignore-missing SHA256SUMS
    debian-13.7.0-amd64-netinst.iso: OK
    ```
  ],
  h => block(height: h, stack(spacing: px(20),
    rendre-bloc(bloc(taille: px(22), taille-titre: px(24))[Deux contrôles, deux fichiers][
      - *Intégrité* → `SHA256SUMS` : l’image est-elle intacte ?
      - *Authenticité* → `SHA256SUMS.sign` : vient-elle bien de Debian ?
    ]),
    rendre-bloc(bloc(entete: c.orange, fond: c.orange-clair, taille: px(22), taille-titre: px(24))[Quel algorithme d’empreinte ?][
      - *MD5, SHA-1* : cassés — on sait fabriquer deux fichiers de même empreinte (collisions). À éviter.
      - *SHA-256 / SHA-512* (SHA-2) : standard actuel, aucune collision connue. Debian publie les deux.
      - Corruption accidentelle : n’importe quel hachage suffit. Contre une image *substituée*, il faut la résistance aux collisions → SHA-2.
    ]),
    note[Ordre logique : *signature d’abord*. En une ligne : `gpgv … && sha256sum -c …` — `&&` ne vérifie les empreintes que si la signature est bonne.],
  )),
)

#speaker-note[Tout rejoué le 18 novembre 2026 sur l’image 13.7.0 réellement téléchargée (792 723 456 octets) : gpgv → Good signature (clé DF9B 9C49 EAA9 2984 3258 9D76 DA87 E80D 6294 BE9B, trousseau debian-role-keys.pgp du paquet debian-keyring) ; sha256sum -c → OK, puis FAILED après modification d’un seul octet. Les trois fichiers partent du même \$URL\_BASE : image, sommes et signature sont au même endroit du dépôt. --ignore-missing : SHA256SUMS liste aussi d’autres images non téléchargées. Sur le choix de l’algorithme : MD5 (collisions pratiques depuis \~2008) et SHA-1 (collision « SHAttered », Google 2017) sont cassés ; SHA-256/512 (famille SHA-2) n’ont pas de collision connue. La résistance aux collisions importe face à un attaquant qui voudrait faire passer une autre image pour l’officielle ; pour une simple corruption de transfert, même un hachage faible suffirait. L’anti-falsification vient en dernier ressort de la signature GPG, qui protège le fichier d’empreintes lui-même. Sans machine Debian : gpg --verify SHA256SUMS.sign SHA256SUMS après import de la clé, puis comparer son empreinte à celle de debian.org/CD/verify.]

== KVM en pratique

#colonnes(
  bloc(entete: c.vert, fond: c.vert-clair, poids: 1.2)[À vous][
    #terminal(taille: px(24))[
      ```
      $ grep -cE 'vmx|svm' /proc/cpuinfo
      8
      $ lsmod | grep kvm
      kvm_intel   …
      kvm         …
      $ sudo apt install qemu-system-x86 \
        libvirt-daemon-system virtinst virt-viewer
      $ virt-install --name test --memory 2048 \
        --vcpus 2 --disk size=10 --osinfo detect=on \
        --cdrom debian-13.7.0-amd64-netinst.iso
      # virt-viewer ouvre la console : on y fait l’install
      $ virsh list --all
      ```
    ]
  ],
  bloc[À retenir][
    - vmx (Intel VT-x) ou svm (AMD-V) : extensions présentes
    - KVM : module du noyau qui exécute les VM
    - QEMU : émule les périphériques de la VM
    - libvirt : gestion (virsh, virt-manager)
    - virt-viewer : console graphique, indispensable pour voir l’installateur
    - Proxmox VE, OpenStack, oVirt s’appuient sur KVM
  ],
)

#speaker-note[L’ISO est celle téléchargée et vérifiée aux diapositives précédentes. grep -c compte une ligne par processeur logique : un nombre non nul indique que les extensions sont exposées. Commandes pour Debian/Ubuntu ; --osinfo existe depuis virt-install 4.0 ; detect=on identifie l’OS à partir de l’ISO. Par défaut virt-install choisit un affichage graphique (SPICE/VNC) et lance virt-viewer (--autoconsole graphical) pour interagir avec l’installateur ; sans virt-viewer, aucune console ne s’ouvre et l’installation interactive est impossible. Alternative en mode texte : --graphics none avec une console série (virsh console) (non rejoué ici, pas de KVM dans l’environnement de préparation).]

== Mini TP : votre première VM

#colonnes(bloc(entete: c.vert, fond: c.vert-clair)[À vous][
  + Votre processeur expose-t-il les extensions de virtualisation (VT-x ou AMD-V) ?
  + KVM est-il utilisable sur votre hôte ?
  + Démarrez une VM sur l’ISO Debian avec QEMU et KVM, puis montrez que cette VM est un *processus de l’hôte*
  + Relancez-la *sans KVM* : que constatez-vous ? Comment le vérifier depuis le moniteur QEMU ?
  + Dans l’invité : l’OS sait-il qu’il est virtualisé ?
])

#speaker-note[À faire en direct sur un poste Linux (Debian ou Ubuntu) avec qemu-system-x86 installé et une image ISO Debian (netinst) téléchargée au préalable. Laisser chercher avant de passer au corrigé. Aide : man qemu-system-x86\_64, Ctrl+Alt+2 ouvre le moniteur QEMU.]

== Mini TP : corrigé (1/2)

// Les questions restent affichées ; une réponse par clic.
#slide(repeat: 4, self => {
  let (uncover,) = utils.methods(self)
  corrige(1, [Votre processeur expose-t-il les extensions de virtualisation (VT-x ou AMD-V) ?],
    uncover("2-", terminal(titre: none, taille: px(22))[
      ```
      $ lscpu | grep -E 'Virtualization|Virtualisation'
      Virtualisation :    VT-x
      $ grep -cE 'vmx|svm' /proc/cpuinfo
      8
      ```
    ]))
  v(px(4)); filet-corrige; v(px(4))
  corrige(2, [KVM est-il utilisable sur votre hôte ?],
    uncover("3-", terminal(titre: none, taille: px(22))[
      ```
      $ lsmod | grep kvm
      kvm_intel   …
      kvm         …
      $ ls -l /dev/kvm
      crw-rw---- 1 root kvm 10, 232 … /dev/kvm
      ```
    ]))
  v(px(4)); filet-corrige; v(px(4))
  corrige(3, [Démarrez une VM sur l’ISO Debian avec QEMU et KVM, puis montrez que cette VM est un *processus de l’hôte*],
    uncover("4-", terminal(titre: none, taille: px(22))[
      ```
      $ qemu-system-x86_64 -enable-kvm -m 1024 \
        -cdrom debian-13.7.0-amd64-netinst.iso &
      $ ps -o pid,user,args -C qemu-system-x86_64
        PID USER  COMMAND
       4242 jmc   qemu-system-x86_64 -enable-kvm -m 1024 …
      ```
    ]))
  utils.speaker-note(self: self)[Question 1 : un résultat 0 signifie extensions absentes ou désactivées dans l’UEFI. Question 2 : il faut être membre du groupe kvm pour utiliser /dev/kvm. Sorties types, non rejouées dans l’environnement de préparation (pas de KVM disponible) : à vérifier sur le poste de démonstration. lscpu affiche « Virtualization » ou « Virtualisation » selon la langue. /dev/kvm : périphérique caractère 10, 232, groupe kvm. Le processus QEMU porte le nom de l’utilisateur qui l’a lancé. Un clic par réponse.]
})

== Mini TP : corrigé (2/2)

#slide(repeat: 3, self => {
  let (uncover,) = utils.methods(self)
  corrige(4, [Relancez-la *sans KVM* : que constatez-vous ? Comment le vérifier depuis le moniteur QEMU ?],
    uncover("2-", terminal(titre: none, taille: px(22))[
      ```
      $ qemu-system-x86_64 -m 1024 \
        -cdrom debian-13.7.0-amd64-netinst.iso
      # sans KVM : processeur émulé (TCG), démarrage bien plus lent
      ```
      #encart[Moniteur QEMU (Ctrl+Alt+2)][
        ```
        (qemu) info kvm
        kvm support: disabled
        ```
      ]
    ]))
  v(px(8)); filet-corrige; v(px(8))
  corrige(5, [Dans l’invité : l’OS sait-il qu’il est virtualisé ?],
    uncover("3-", terminal(titre: none, taille: px(22))[
      #encart[Invité][
        ```
        $ systemd-detect-virt
        kvm
        # « qemu » si la VM est émulée (sans KVM)
        $ lspci | grep -i virtio
        # périphériques virtio : pilotes paravirtualisés
        ```
      ]
    ]))
  utils.speaker-note(self: self)[Question 4 : sans -enable-kvm, QEMU émule le processeur avec TCG ; le démarrage de l’installateur est nettement plus lent. Dans le moniteur QEMU (Ctrl+Alt+2, retour à l’affichage par Ctrl+Alt+1), info kvm affiche « kvm support: disabled ». Question 5 : elle suppose un système Debian installé dans la VM (l’installateur seul ne fournit pas systemd-detect-virt). systemd-detect-virt renvoie kvm sous KVM, qemu en émulation pure. Attention : lspci ne montre des périphériques virtio que si la VM en utilise ; la commande qemu du TP garde les périphériques par défaut (carte réseau e1000, lecteur IDE), alors que virt-install (diapositive « KVM en pratique ») choisit virtio. Sorties types, non rejouées dans l’environnement de préparation (pas de KVM) : à vérifier sur le poste de démonstration. Un clic par réponse.]
})

== Gérer ses VM : virt-manager

#colonnes(
  bloc(taille: px(27))[Ce que c’est][
    - L’*interface graphique de libvirt* : même moteur que la ligne de commande `virsh`
    - Créer, démarrer, arrêter, cloner une VM ; console graphique (VNC/SPICE) intégrée
    - Gère l’hôte local, ou un hôte distant via SSH : `qemu+ssh://serveur/system`
  ],
  bloc(entete: c.vert, fond: c.vert-clair, taille: px(27))[Bon à savoir][
    - Application de *bureau, mono-poste* : ni cluster, ni haute disponibilité, ni multi-utilisateur
    - Sur Debian/Ubuntu : paquet `virt-manager`, l’outil graphique de référence
    - Sous Red Hat, déprécié au profit de la console web *Cockpit* (`cockpit-machines`)
  ],
)
#espace
#bandeau[*Origine* : projet *libvirt / virt-manager*, développé par *Red Hat* et sa communauté · logiciel libre (GPL) · pilote KVM/QEMU au travers de libvirt]

#speaker-note[Suite directe de « KVM en pratique » : après virsh en ligne de commande, l’équivalent graphique. virt-manager (Virtual Machine Manager) et virsh s’appuient tous deux sur libvirt ; ce qui est fait dans l’un se retrouve dans l’autre. Console distante via SSH : virt-manager -c qemu+ssh:\/\/user\@hote/system. Statut (vérifié le 18 novembre 2026) : toujours maintenu en amont et standard sur Debian/Ubuntu ; Red Hat l’a déprécié dans RHEL (déjà annoncé pour RHEL 8) et pousse la console web Cockpit avec le module cockpit-machines. Non rejoué ici (pas d’environnement graphique ni de KVM).]

== Incus : conteneurs système et VM

#colonnes(
  bloc(taille: px(27))[Ce que c’est][
    - Un gestionnaire *unique* pour des *conteneurs système* (LXC) *et* des *machines virtuelles* (QEMU/KVM), via une seule CLI et API (`incus`)
    - Conteneur « système » : un OS complet avec son init, persistant — à distinguer des conteneurs *applicatifs* de Docker
    - Fondé sur des *images*, API REST, instantanés, migration à chaud
  ],
  bloc(entete: c.vert, fond: c.vert-clair, taille: px(27))[Bon à savoir][
    - *Cluster* de plusieurs nœuds, projets et profils, quotas de ressources
    - Une VM : `incus launch images:debian/13 v1 --vm`
    - Un conteneur : la même commande *sans* `--vm`
  ],
)
#espace
#bandeau[*Incus 6.x* : fork communautaire de *LXD* (créé par *Canonical*, éditeur d’Ubuntu), passé sous le projet *Linux Containers* (Stéphane Graber) · Apache-2.0 · paquet `incus` dans Debian 13]

#speaker-note[Incus prolonge la logique de virtualisation vers les conteneurs système, pont naturel vers le cours Docker (conteneurs applicatifs). Faits vérifiés le 18 novembre 2026 : Incus est un fork de LXD lancé par Stéphane Graber en 2023 sous le projet Linux Containers (dépôt lxc/incus) ; il gère conteneurs LXC et VM QEMU/KVM par une même CLI/API ; licence Apache-2.0 ; empaqueté dans Debian 13 (paquet incus). Version 6.21 fin 2025 / début 2026. Non rejoué ici (pas d’environnement Incus). Conteneur système ≠ conteneur applicatif : le premier fait tourner un OS complet (comme une VM légère, partage du noyau hôte), le second un seul processus applicatif.]

== Proxmox VE : la virtualisation clé en main

#colonnes(
  bloc(taille: px(27))[Ce que c’est][
    - Une *distribution complète* (basée sur Debian) : hyperviseur + interface web, installée directement sur le serveur
    - *KVM* pour les machines virtuelles, *LXC* pour les conteneurs système
    - Tout se pilote depuis l’interface web : création, console, modèles, sauvegardes
  ],
  bloc(entete: c.vert, fond: c.vert-clair, taille: px(27))[Pour la production][
    - Cluster de plusieurs nœuds, *haute disponibilité*, migration à chaud
    - Stockage et réseau définis par logiciel : *Ceph* intégré, SDN
    - Sauvegardes avec Proxmox Backup Server
  ],
)
#espace
#bandeau[*Proxmox VE 9.2* (2026) : édité par *Proxmox Server Solutions GmbH* (Vienne, Autriche) · base Debian 13, noyau 7.0 · open source AGPL, abonnement entreprise payant · s’appuie sur KVM et LXC]

#speaker-note[Déjà cité à la diapositive « KVM en pratique » comme utilisateur de KVM. À la différence de virt-manager (application de bureau sur un poste), Proxmox s’installe sur le serveur lui-même (bare metal) et fournit l’hyperviseur ET son interface. Positionné comme alternative à VMware vSphere/ESXi. Faits vérifiés le 18 novembre 2026 : Proxmox VE 9.2, base Debian 13, noyau 7.0 (sources Proxmox). Licence AGPLv3 ; le logiciel est gratuit, l’abonnement donne accès au dépôt entreprise (mises à jour stabilisées) et au support. Non rejoué ici.]

== oVirt : gérer un datacenter KVM

#colonnes(
  bloc(taille: px(27))[Ce que c’est][
    - Plateforme *web* de gestion de la virtualisation *KVM* à l’échelle d’un *datacenter* (moteur _oVirt Engine_)
    - Pilote un *cluster d’hôtes* KVM/libvirt : création de VM, *migration à chaud*, haute disponibilité
    - Stockage, réseaux, modèles et instantanés depuis une seule interface — alternative libre à VMware vSphere
  ],
  bloc(entete: c.vert, fond: c.vert-clair, taille: px(27))[Statut aujourd’hui][
    - Était l’*amont* de Red Hat Virtualization (RHV)
    - Red Hat a *arrêté RHV* et bascule vers *OpenShift Virtualization* (KubeVirt)
    - oVirt continue surtout en *communautaire* ; *Oracle Linux Virtualization Manager* (OLVM) en est un dérivé maintenu
  ],
)
#espace
#bandeau[Projet *oVirt*, lancé par *Red Hat* (2012) comme amont de RHV · Apache-2.0 · fondé sur *KVM/libvirt* · depuis l’arrêt de RHV, projet surtout communautaire, poursuivi par *Oracle* (OLVM)]

#speaker-note[Même famille que virt-manager et Proxmox (tous fondés sur KVM/libvirt), mais à l’échelle datacenter avec un moteur de gestion centralisé (oVirt Engine, en Java) et des hôtes exécutant KVM via l’agent VDSM. Positionné comme alternative libre à VMware vSphere. Faits vérifiés le 18 novembre 2026 : oVirt lancé par Red Hat vers 2011-2012 comme amont de Red Hat Virtualization (RHV/RHEV) ; licence Apache-2.0 ; fondé sur KVM et libvirt. Red Hat a mis fin à RHV et oriente ses clients vers OpenShift Virtualization (fondée sur KubeVirt) : oVirt est donc devenu surtout communautaire, avec une sortie 4.5.7 après environ deux ans ; Oracle maintient un dérivé, Oracle Linux Virtualization Manager (OLVM). Non rejoué ici. Fil conducteur : la gestion de VM KVM « datacenter » de Red Hat est passée d’oVirt/RHV à OpenShift Virtualization.]

== OpenShift : Kubernetes d’entreprise

#colonnes(
  bloc(taille: px(27))[Ce que c’est][
    - Distribution *Kubernetes* de Red Hat pour orchestrer des *conteneurs applicatifs* sur un cluster de serveurs
    - Ajoute à Kubernetes : console web, CI/CD intégrée, registre d’images, build _source-to-image_, Operators, sécurité renforcée (RBAC, SCC)
    - Tourne sur un socle Red Hat (RHEL CoreOS) ; *OKD* en est la version communautaire libre
  ],
  bloc(entete: c.vert, fond: c.vert-clair, taille: px(27))[Place dans le cours][
    - On change d’échelle : non plus gérer *un hôte*, mais un *cluster* qui ordonnance les conteneurs
    - *OpenShift Virtualization* (KubeVirt) fait tourner des VM *à côté* des conteneurs, sur la même plateforme
    - La marche d’après : la conteneurisation (cours suivant) industrialisée en production
  ],
)
#espace
#bandeau[*OpenShift 4.20* (nov. 2025) : édité par *Red Hat* (groupe IBM), bâti sur *Kubernetes* (créé par Google en 2014, aujourd’hui projet *CNCF* / Linux Foundation) · VM + conteneurs via KubeVirt · *OKD* en amont libre]

#speaker-note[OpenShift illustre l’aboutissement « gestion » : orchestration de conteneurs à l’échelle d’un cluster, loin de la VM d’un poste. Faits vérifiés le 18 novembre 2026 : OpenShift 4.20 en disponibilité générale depuis le 11 novembre 2025 (Red Hat) ; plateforme bâtie sur Kubernetes ; OpenShift Virtualization (fondé sur le projet KubeVirt) exécute des machines virtuelles aux côtés des conteneurs ; socle RHEL CoreOS ; OKD est la distribution communautaire en amont. Non rejoué ici. Lien avec le cours : les conteneurs applicatifs sont le sujet du cours Docker qui suit ; OpenShift en est une mise en œuvre d’entreprise.]

== Xen Orchestra : gérer XCP-ng

#colonnes(
  bloc(taille: px(27))[Ce que c’est][
    - L’*interface web de gestion de XCP-ng* (et de XenServer), hyperviseur de *type 1* fondé sur Xen
    - Développé par *Vates*, l’éditeur de XCP-ng
    - Gère un ou plusieurs *pools* de serveurs depuis une seule interface
  ],
  bloc(entete: c.vert, fond: c.vert-clair, taille: px(27))[Fonctions][
    - Sauvegarde et réplication des VM, migration à chaud
    - Ordonnancement des tâches, statistiques
    - Multi-utilisateur : rôles et délégation de droits
  ],
)
#espace
#bandeau(taille: px(24))[Édités par *Vates* (France) : *XCP-ng* (l’hyperviseur) et *Xen Orchestra* (sa console web), fondés sur *Xen* — créé à l’université de Cambridge (2003), aujourd’hui Xen Project / Linux Foundation. XCP-ng est un fork libre de Citrix *XenServer* · cœur open source, édition XOA payante]

#speaker-note[Après KVM (virt-manager, Proxmox, oVirt), l’écosystème Xen. Lien avec la diapositive « KVM ou Xen : deux architectures » : XCP-ng est une distribution hyperviseur fondée sur Xen (type 1), Xen Orchestra en est la console web. Vates, éditeur français de XCP-ng et Xen Orchestra, positionne l’ensemble (Vates VMS, Virtualization Management Stack) comme alternative à VMware vSphere. Xen Orchestra : cœur open source, édition commerciale XOA (Xen Orchestra Appliance) avec support et fonctions avancées. On peut aussi le construire soi-même depuis les sources. Faits vérifiés le 18 novembre 2026 (documentation Vates). Non rejoué ici.]

== Qubes OS : la sécurité par compartimentage

#colonnes(
  bloc(taille: px(27))[Ce que c’est][
    - Un *système de bureau* qui applique la *sécurité par compartimentage* : chaque activité tourne dans sa propre VM, un « *qube* »
    - Repose sur l’hyperviseur *Xen* (type 1) : c’est tout le *poste de travail* qui est virtualisé, pas un serveur
    - Fenêtres *bordées de couleur* selon le niveau de confiance (travail, perso, non fiable)
  ],
  bloc(entete: c.vert, fond: c.vert-clair, taille: px(27))[Comment ça marche][
    - *dom0* administrateur, sans réseau ; réseau et USB isolés dans des qubes dédiés (`sys-net`, `sys-usb`)
    - *Qubes jetables* : ouvrir une pièce jointe douteuse, puis tout détruire
    - VM dérivées de *modèles* (Fedora, Debian, Whonix/Tor) : mises à jour centralisées
  ],
)
#espace
#bandeau[Projet *Qubes OS*, lancé en 2010 par *Joanna Rutkowska* (Invisible Things Lab) · logiciel libre (GPL) · bâti sur l’hyperviseur *Xen* · ici la virtualisation sert la *sécurité*, pas la consolidation de serveurs]

#speaker-note[Exemple marquant d’usage de la virtualisation de type 1 côté poste de travail, pour la sécurité et non la consolidation. Chaque qube est une VM Xen ; le compromis d’une application reste confiné à son qube. dom0 (le domaine d’administration Xen) n’a pas d’accès réseau ; des qubes de service dédiés portent le réseau (sys-net), le pare-feu (sys-firewall) et l’USB (sys-usb). Les VM applicatives dérivent de modèles en lecture seule (Fedora, Debian, Whonix pour Tor), ce qui centralise les mises à jour. Les qubes jetables (DisposableVM) servent à ouvrir un fichier à risque puis disparaissent. Faits vérifiés le 18 novembre 2026 : projet fondé par Joanna Rutkowska (Invisible Things Lab), première version stable 1.0 en 2012 ; série stable 4.2 depuis fin 2023 ; licence GPL ; fondé sur Xen. Rendu célèbre notamment par le soutien public d’Edward Snowden. Non rejoué ici.]

// ======================================================================
= Pour aller plus loin

== MicroVM : une VM réduite à l’essentiel

#colonnes(bloc(taille: px(26))[L’idée][
  - Une vraie VM, exécutée par KVM : son propre noyau, l’isolation du matériel
  - Une machine virtuelle minimale : quelques périphériques virtio, ni BIOS ni matériel hérité (USB, carte graphique…)
  - Démarrage direct du noyau invité : rapide, peu de mémoire, donc des milliers de microVM par hôte
])
#espace
#colonnes(bloc(entete: c.gris, fond: c.espace, taille: px(24))[Où se place la microVM ?][
  #table(columns: (1fr, 1.2fr, 1.2fr, 1.2fr), stroke: none, inset: (x: px(8), y: px(6)),
    fill: (x, y) => if y == 0 or calc.even(y) { rgb("#DCE5F3") } else { c.fond },
    table.header([], ..([VM classique], [MicroVM], [Conteneur]).map(t => align(center, strong(t)))),
    ..(
      ([Noyau], [le sien], [le sien], [celui de l’hôte]),
      ([Isolation], [matérielle (VT-x)], [matérielle (VT-x)], [par le noyau de l’hôte]),
      ([Machine], [complète, émulée], [minimale, virtio], [aucune]),
      ([Démarrage], [secondes], [fraction de seconde], [fraction de seconde]),
    ).map(((k, ..v)) => (text(fill: c.bleu, k), ..v)).flatten(),
  )
])

#speaker-note[La microVM répond au besoin du cloud multi-locataire : exécuter le code de clients différents sur un même hôte avec l’isolation d’une VM, au rythme et à la densité des conteneurs (fonctions serverless, bacs à sable). Le tableau est qualitatif : les temps dépendent du noyau invité et de la charge. Les conteneurs sont détaillés à la dernière diapositive et dans le cours Docker.]

== MicroVM : les technologies

#lignes(largeur: px(420), taille: px(26),
  ([Firecracker], [AWS, 2018, écrit en Rust : derrière Lambda et Fargate ; annonce moins de 125 ms de démarrage et moins de 5 Mio de surcoût par microVM]),
  ([Cloud Hypervisor], [2019, en Rust, projet de la Linux Foundation : charges cloud, plus de périphériques que Firecracker]),
  ([QEMU microvm], [Le type de machine « microvm » de QEMU (depuis la 4.2) : le même QEMU, sans le matériel hérité]),
  ([Kata Containers], [Chaque conteneur dans sa microVM : s’utilise comme runtime avec containerd et Kubernetes]),
)
#espace
#colonnes(bloc(entete: c.orange, fond: c.orange-clair)[À ne pas confondre][
  gVisor n’est pas une microVM : c’est un noyau réécrit en espace utilisateur, qui intercepte les appels système du conteneur.
])

#speaker-note[Tous s’appuient sur KVM (rappel : KVM exécute, un programme en espace utilisateur fournit la machine ; ici ce programme remplace QEMU ou l’allège). Firecracker : publié en open source par AWS en novembre 2018 ; les chiffres de démarrage et de mémoire sont ceux annoncés par le projet (firecracker-microvm.github.io). Cloud Hypervisor : lancé par Intel en 2019. QEMU : machine microvm introduite en version 4.2 (décembre 2019). Kata Containers : fusion d’Intel Clear Containers et de Hyper runV (2017), fondation OpenInfra (rattachée à la Linux Foundation depuis 2025) ; peut utiliser QEMU, Cloud Hypervisor ou Firecracker comme hyperviseur. crosvm (Google, ChromeOS et Android) est de la même famille.]

== Et les conteneurs ?

#grid(columns: (1fr, 1fr), column-gutter: px(64),
  pile-archi([Machines virtuelles (KVM)], [Espace utilisateur de l’hôte],
    [*Gestion* (crée, démarre, arrête) : libvirt],
    range(1, 4).map(i => vm[VM #i : QEMU]),
    [Noyau Linux de l’hôte], ([module kvm],), [Matériel (VT-x / AMD-V)]),
  pile-archi([Conteneurs], [Espace utilisateur de l’hôte],
    [*Gestion* (crée, démarre, arrête) : dockerd, containerd, runc],
    range(1, 4).map(i => vm(bas: [Bibliothèques], fond-bas: rgb("#FBFBF8"))[Conteneur #i]),
    [Noyau Linux de l’hôte], ([namespaces], [cgroups], [capabilities], [seccomp], [AppArmor]),
    [Matériel]),
)

#speaker-note[Représentation fidèle (cas KVM). Une VM est un processus QEMU de l’hôte qui contient un OS invité complet, noyau compris : son code s’exécute directement sur le processeur (mode VT-x / AMD-V), le module kvm du noyau n’intervient que sur les opérations privilégiées, QEMU émule les périphériques. Un conteneur est un ensemble de processus ordinaires de l’hôte : ils appellent directement le noyau de l’hôte, qui les isole (namespaces), les limite (cgroups) et restreint leurs droits (capabilities, seccomp, AppArmor : le module de sécurité actif par défaut sur Debian et Ubuntu). Le moteur (dockerd, containerd, runc) et libvirt sont à côté : ils créent et gèrent, ils ne sont pas traversés. Un hyperviseur de type 1 comme ESXi ou Xen se place, lui, directement sur le matériel (cours Virtualisation). Suite : cours Docker, fondements de la conteneurisation.]
