// Cours « Fondements de la virtualisation de machines » — Typst + Touying.
// Compilation (depuis la racine du dépôt) : typst compile --root . --font-path commun/fonts virtualisation/virtualisation.typ build/virtualisation.pdf
// Une diapo = un titre `==` ; une section (surtitre bleu) = un titre `=`.
// Structure : règles de .claude/skills/structurer-diapos-cours ; apparence : charte de commun/.

#import "../commun/theme-cours.typ": *

#show: cours-theme.with(
  auteur: [Jean-Mathieu Chantrein],
  titre-court: [Fondements de la virtualisation de machines],
)

#couverture[Virtualisation][Fondements de la virtualisation de machines][Jean-Mathieu Chantrein][12 novembre 2026]
#speaker-note[À droite : trois VM (violet) sur un hyperviseur (bleu), lui-même sur le matériel (gris). Cours compagnon : Docker, fondements de la conteneurisation.]

// ======================================================================
= Sommaire

== Plan du cours

#plan-cours(
  ([Introduction], [Machine physique, système d’exploitation, machine virtuelle]),
  ([Concepts], [Émulation et virtualisation, assistance matérielle, types d’hyperviseur, paravirtualisation, QEMU et KVM]),
  ([Usages], [Bilan, migration à chaud, virtualisation imbriquée, image ISO et empreintes, créer une VM avec libvirt, mini TP, outils de gestion, Qubes OS]),
  ([Pour aller plus loin], [MicroVM, VM et conteneurs ; pour rappel]),
)

// ======================================================================
= Introduction

== Le vocabulaire : machine, OS, VM, hyperviseur

#anime(
  rang(
    bloc(taille: px(26))[Machine physique][
      - L’ordinateur : serveur, PC, Mac…
      - Programmable : on lui fait exécuter des programmes
      - Très puissante en calcul binaire, mais elle ne sait faire que cela
    ],
    bloc(taille: px(26))[Système d’exploitation (OS, _operating system_)][
      - Le programme qui fait communiquer les logiciels et les composants (mémoire vive ou RAM, disque, carte réseau…)
      - Organise et planifie l’exécution des autres programmes
      - Son noyau seul accède directement au matériel (mode privilégié)
    ],
  ),
  rang(bloc(taille: px(26))[Machine virtuelle (VM, _virtual machine_) et hyperviseur][
    - Une *VM* : un ordinateur simulé par logiciel, avec son propre système d’exploitation, dit *invité*
    - L’*hyperviseur* : le logiciel qui crée et exécute les VM, et leur partage le matériel de la machine physique, dite *hôte*
  ]),
)

// ======================================================================
= Concepts

== Émuler traduit, virtualiser exécute

#anime(
  rang(
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
  ),
  rang(bloc(role: "retenir")[À retenir][
    Une VM n’est pas, en général, une machine émulée. *QEMU* (_Quick EMUlator_, « émulateur rapide », Fabrice Bellard, 2003) sait pourtant faire les deux : exemple à la diapositive suivante.
  ]),
  source-de: link("https://www.qemu.org/docs/master/about/index.html")[qemu.org, documentation de QEMU],
  note: [QEMU sait faire les deux : sans KVM, il émule le processeur (TCG, traduction binaire dynamique) ; avec -accel kvm, il délègue l’exécution au processeur réel et n’émule plus que les périphériques.],
)

== QEMU sait émuler et virtualiser

#anime(
  rang(
    bloc(role: "pratique", taille: px(25))[Émulation : une machine ARM sur un PC x86][
      #terminal(taille: px(24))[
        ```
        # le processeur invité est émulé (TCG)
        $ qemu-system-aarch64 -M virt -cpu cortex-a57 …
        ```
      ]
      - *`qemu-system-aarch64`* : émule une machine complète à processeur ARM 64 bits (un binaire qemu-system-\* par architecture invitée)
      - *`-M virt`* : type de machine (alias de -machine) ; « virt » est une carte générique, sans équivalent matériel réel
      - *`-cpu cortex-a57`* : processeur présenté à l’invité : ARM Cortex-A57, 64 bits (AArch64)
      - *`…`* : reste de la commande : mémoire, disque, noyau ou micrologiciel
    ],
    bloc(role: "pratique", taille: px(25))[Virtualisation : une machine x86 sur un PC x86][
      #terminal(taille: px(24))[
        ```
        # le processeur invité est le vrai processeur
        $ qemu-system-x86_64 -accel kvm -m 2048 …
        ```
      ]
      - *`qemu-system-x86_64`* : fournit une machine PC à processeur x86 64 bits, la même architecture que l’hôte
      - *`-accel kvm`* : confie l’exécution du code invité à *KVM* (_Kernel-based Virtual Machine_, module du noyau Linux, détaillé plus loin) ; ancienne syntaxe : `-enable-kvm`. Sans accélérateur, QEMU émule le processeur avec *TCG* (_Tiny Code Generator_)
      - *`-m 2048`* : mémoire vive de la VM, en Mio par défaut : ici 2 Gio
      - *`…`* : reste de la commande : disque, réseau, affichage
    ],
  ),
  source-de: link("https://www.qemu.org/docs/master/system/invocation.html")[qemu.org, options de qemu-system],
  note: [Le même logiciel fait les deux. À gauche, l’hôte x86 ne sait pas exécuter du code ARM : QEMU traduit chaque bloc d’instructions (TCG, Tiny Code Generator). Le Cortex-A57 (2012) est un des premiers cœurs ARMv8-A 64 bits ; -cpu max donne toutes les fonctions émulables. À droite, -accel kvm exige /dev/kvm et une architecture invitée identique à celle de l’hôte ; -enable-kvm, encore très répandu dans les tutoriels, en est l’ancienne forme. -m accepte un suffixe : -m 2G. Les commandes sont volontairement abrégées (« … ») : seules les options étudiées sont montrées.],
)

== Le x86 virtualisable : de 1974 à 2008

#slide(repeat: 6, self => {
  let (uncover,) = utils.methods(self)
  lignes(uncover: uncover,
    ([1974], [Popek et Goldberg : conditions pour qu’une architecture soit virtualisable]),
    ([1999], [VMware : le x86 ne les remplit pas, traduction binaire des instructions sensibles]),
    ([2003], [Xen : paravirtualisation, le noyau invité est modifié pour coopérer]),
    ([2005–2006], [Intel VT-x, puis AMD-V : extensions matérielles de virtualisation]),
    ([2007], [KVM intégré au noyau Linux (2.6.20) : Linux devient hyperviseur]),
    ([2007–2008], [AMD RVI (_Rapid Virtualization Indexing_) puis Intel EPT (_Extended Page Tables_) : la traduction d’adresses de la VM aussi en matériel]),
  )
  source[G. Popek, R. Goldberg, « Formal Requirements for Virtualizable Third Generation Architectures », _Communications of the ACM_, 1974 · #link("https://kernelnewbies.org/Linux_2_6_20")[kernelnewbies.org, Linux 2.6.20]]
  utils.speaker-note(self: self)[Une date par clic. Popek et Goldberg (1974) définissent les instructions « sensibles » qui doivent être interceptées ; le x86 d’origine en exécute certaines sans piège, d’où la traduction binaire de VMware (1999) puis la paravirtualisation de Xen (2003), avant que VT-x et AMD-V ne règlent le problème en matériel. RVI est aussi appelé NPT (Nested Page Tables).]
})

== Type 1 ou type 2 : une frontière floue

#anime(
  rang(
    bloc[Type 1 : natif (_bare metal_)][
      - S’exécute directement sur le matériel
      - Xen, VMware ESXi, Microsoft Hyper-V
      - KVM : un module qui fait du noyau Linux l’hyperviseur
    ],
    bloc[Type 2 : hébergé (_hosted_)][
      - Application lancée sur un OS hôte
      - VirtualBox, VMware Workstation, Parallels Desktop
      - Pratique sur un poste de travail ; même VT-x, mais ressources et entrées-sorties partagées avec l’OS hôte
    ],
  ),
  rang(bloc(role: "retenir")[Ce qu’il faut bien comprendre][
    - La frontière est floue : KVM et Hyper-V sont classés en type 1, alors qu’ils s’appuient sur un système d’exploitation complet (Linux pour KVM, Windows pour Hyper-V)
    - Le type ne dit pas si l’invité se sait virtualisé : c’est la paravirtualisation, deux diapositives plus loin
  ]),
)

== KVM et Xen : deux places pour l’hyperviseur

#slide(repeat: 2, self => {
  let (uncover,) = utils.methods(self)
  grid(columns: (1fr, 1fr), column-gutter: px(64),
    pile-archi([KVM : Linux est l’hyperviseur], [Espace utilisateur de l’hôte],
      [*Gestion* (crée, démarre, arrête) : libvirt, bibliothèque et service de gestion des VM],
      (vm[VM 1 : QEMU], vm[VM 2 : QEMU]),
      [Noyau Linux de l’hôte], ([module kvm],), [Matériel (VT-x / AMD-V)]),
    uncover("2-", pile-archi([Xen : l’hyperviseur sous Linux], [Domaines (VM)],
      [Toutes les VM, dom0 compris, sont au-dessus de Xen],
      (vm(couleur: c.bleu, haut: [Gestion : xl], bas: [Linux + pilotes], taille: px(26))[dom0 (privilégié)],
       vm[domU 1 : VM], vm[domU 2 : VM]),
      [Hyperviseur Xen (type 1)], ([processeurs], [mémoire]),
      [Matériel (VT-x / AMD-V)])),
  )
  utils.speaker-note(self: self)[KVM : le noyau Linux devient l’hyperviseur ; chaque VM est un processus QEMU de l’hôte, gérée par libvirt. Xen : l’hyperviseur démarre en premier, directement sur le matériel, et ne gère que les processeurs et la mémoire. Linux tourne au-dessus, dans dom0, une VM privilégiée qui porte les pilotes de périphériques et les outils de gestion (xl, ou libvirt). Les VM ordinaires sont des domU. Xen peut faire tourner des VM paravirtualisées classiques (PV) sans VT-x / AMD-V ; les VM complètes (HVM) et le mode PVH, recommandé aujourd’hui, en ont besoin : en pratique un hôte Xen actuel les utilise. Exemples : XCP-ng et XenServer (ex-Citrix Hypervisor) reposent sur Xen ; AWS a utilisé Xen avant de passer à son hyperviseur Nitro, fondé sur KVM (à partir de 2017) ; Proxmox VE et OpenStack reposent le plus souvent sur KVM. Les VM complètes de Xen (HVM, _hardware virtual machine_) et le mode PVH (invité paravirtualisé dans un conteneur HVM) exigent VT-x / AMD-V.]
})

== Paravirtualiser : l’invité coopère

#anime(
  rang(
    bloc[Virtualisation complète][
      - Le système invité n’est pas modifié : il croit tourner sur une vraie machine et ignore qu’il est virtualisé
      - Périphériques émulés (carte réseau e1000, disque IDE) : compatibles mais lents
    ],
    bloc[Paravirtualisation][
      - Le système invité sait qu’il est virtualisé : il coopère en appelant directement l’hyperviseur (_hypercalls_)
      - Xen PV : noyau invité modifié
      - Aujourd’hui : pilotes paravirtualisés (virtio) dans des VM complètes
    ],
  ),
  rang(bloc(role: "retenir")[Ce qu’il faut bien comprendre][
    Que l’invité se sache virtualisé ou non ne dépend pas du type d’hyperviseur : une VM sous KVM (type 1) comme sous VirtualBox (type 2) peut utiliser des pilotes virtio.
  ]),
  source-de: link("https://docs.oasis-open.org/virtio/virtio/v1.2/virtio-v1.2.html")[OASIS, spécification virtio 1.2],
  note: [Correction par rapport à l’ancienne version du cours, qui associait « VM aware » au type 1 et « no aware » au type 2.],
)

== QEMU fournit la machine, KVM la vitesse

#slide(repeat: 6, self => {
  let (uncover,) = utils.methods(self)
  let b-qemu = bloc(taille: px(26))[QEMU][
    - Espace utilisateur : fournit la machine (périphériques, mémoire, micrologiciel de démarrage BIOS/UEFI)
    - Seul, il émule aussi le processeur (TCG) : lent, toute architecture
  ]
  let b-kvm = bloc(taille: px(26))[KVM][
    - Module du noyau : le processeur exécute le code de la VM
    - Aucun périphérique : il faut un programme comme QEMU
  ]
  let b-ens = bloc(role: "retenir", taille: px(26))[Ensemble][
    QEMU pour la machine, KVM pour la vitesse.
  ]
  grid(columns: (1fr, 1.3fr), column-gutter: px(40),
    stack(spacing: px(8),
      block(width: 100%, stroke: px(3) + c.invite, radius: px(12), inset: px(12), stack(spacing: px(8),
        align(center, text(size: px(24), weight: 600, fill: c.invite)[Processus QEMU (espace utilisateur)]),
        block(width: 100%, height: px(72), fill: c.invite-clair, radius: px(8),
          align(center + horizon, text(weight: 600)[VM : OS invité et applis])),
        block(width: 100%, height: px(72), fill: c.appli, radius: px(8),
          align(center + horizon, text(size: px(26), weight: 600)[Périphériques émulés, mémoire])),
      )),
      align(center, text(size: px(24), weight: 600, fill: c.gris)[appels à /dev/kvm]),
      couche([Noyau Linux : module kvm], taille: px(28)),
      couche([Processeur avec VT-x / AMD-V], fond: c.ardoise, taille: px(28)),
    ),
    stack(spacing: px(20),
      bloc-anime(b-qemu, 2, uncover),
      bloc-anime(b-kvm, 4, uncover),
      bloc-anime(b-ens, 6, uncover),
    ),
  )
  source[#link("https://www.linux-kvm.org/page/Main_Page")[linux-kvm.org] · #link("https://www.qemu.org/docs/master/system/introduction.html")[qemu.org, introduction]]
  utils.speaker-note(self: self)[Une VM sous Linux, c’est un processus QEMU : ps sur l’hôte la montre (qemu-system-x86\_64). QEMU demande au module kvm, via /dev/kvm, d’exécuter le code de la VM directement sur le processeur ; le processeur rend la main au noyau (sortie de VM) pour les opérations privilégiées et les accès aux périphériques, que QEMU émule (ou que des pilotes virtio rendent rapides). KVM sert aussi sans QEMU : Firecracker (AWS Lambda), crosvm (ChromeOS), Cloud Hypervisor.]
})

// ======================================================================
= Usages

== Une VM : isolée et portable, mais coûteuse

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
          - Instantanés (_snapshots_) et migration à chaud
          - Démarrage plus rapide qu’une machine réelle
        ]
      ]))
      espace
      uncover("7-", colonnes(bloc(role: "precaution")[Inconvénients][
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

== Migrer une VM à chaud, sans l’arrêter

#let hote(nom) = block(width: px(600), height: px(408), fill: rgb("#FCFCFA"),
  stroke: px(1) + rgb("#DDE1E6"), radius: px(16), inset: px(24), text(size: px(32), weight: 600, nom))
#let mvm(nom, fond: c.appli, couleur: c.encre, bas: [OS + appli], trait: none) = block(
  width: px(176), height: px(100), fill: fond, stroke: trait, radius: px(12),
  align(center + horizon, stack(spacing: px(6),
    text(size: px(28), weight: 600, fill: couleur, nom), text(size: px(24), fill: couleur, bas))))
#let barre(t, fond) = block(width: px(552), height: px(80), fill: fond, radius: px(12),
  align(center + horizon, text(size: px(32), weight: 600, fill: c.fond, t)))
#let etape(n, t) = block(width: px(440),
  align(center, text(size: px(28))[#text(weight: 600, fill: c.invite)[#n.] #t]))
#let fleche = polygon(fill: c.invite, (0pt, px(27)), (px(156), px(27)), (px(156), 0pt),
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
    uncover("2-6", pose(400, 88, mvm(fond: c.invite-clair)[VM 3]))
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
        align(center + horizon, text(size: px(32), weight: 600, fill: c.fond)[Stockage partagé (baie SAN, partage NFS, Ceph) : le disque de la VM reste en place])))
    })
    uncover("5-", pose(612, 28, etape(1)[Copie de la mémoire, la VM continue de tourner]))
    uncover("5-6", {
      pose(712, 318, fleche)
      pose(1276, 88, mvm(fond: none, couleur: c.invite, bas: [copie],
        trait: (paint: c.invite, thickness: px(2), dash: "dashed"))[VM 3])
    })
    uncover("6-", pose(612, 124, etape(2)[Recopie des pages modifiées entre-temps]))
    uncover("7-", {
      pose(612, 220, etape(3)[Bascule : pause très brève, reprise sur B])
      pose(1276, 88, mvm(fond: c.invite-clair)[VM 3])
    })
    uncover("8-", pose(0, 612, block(width: px(1664), rangee(gouttiere: px(28), poids: (1, 1.35),
      h => encadre(role: "retenir", libelle: [Intérêt :], hauteur: h)[maintenir ou rééquilibrer un hôte sans coupure de service.],
      h => encadre(role: "precaution", libelle: [En vrai :], hauteur: h)[un cluster fait au moins *3 hôtes* (quorum → pas de _split-brain_ si un hôte tombe). *Avant de basculer*, vérifier que l’hôte cible a assez de *CPU/RAM libres*.],
    ))))
  })
  utils.speaker-note(self: self)[Schéma dessiné pas à pas, un clic par étape (comme au tableau). 1. Hôte A : matériel, hyperviseur, trois VM. 2. Hôte B. 3. Stockage partagé : le disque de la VM n’a pas à être copié (sans stockage partagé, il faut aussi migrer les disques). 4. Pré-copie : la mémoire de VM 3 est envoyée vers B pendant que la VM continue de tourner. 5. Les pages modifiées entre-temps sont recopiées, en boucle, jusqu’à ce qu’il en reste très peu. 6. Bascule : la VM est brièvement suspendue, son dernier état est transféré, elle reprend sur B et disparaît de A. 7. Usage : maintenance ou équilibrage de charge sans coupure. Réalité d’un cluster : au moins 3 hôtes pour le quorum (Proxmox VE, vSphere HA : une majorité de nœuds doit rester jointe pour éviter le split-brain et relancer les VM d’un hôte défaillant). La migration à chaud elle-même ne demande que 2 hôtes, mais la haute disponibilité qui l’entoure en demande 3. Avant chaque bascule (manuelle ou automatique via DRS/HA), l’ordonnanceur vérifie que l’hôte cible a les ressources CPU/RAM libres ; on garde donc une marge sur chaque hôte pour absorber la panne d’un autre. Côté conteneurs : le conteneur est sans état et jetable, on le recrée ailleurs plutôt que de le migrer ; le checkpoint/restore (CRIU) existe mais reste un cas particulier.]
})


== Virtualisation imbriquée : des VM dans une VM

#slide(repeat: 7, self => {
  let (uncover,) = utils.methods(self)
  let b-gauche = bloc(taille: px(26))[Virtualisation imbriquée (_nested_)][
    - L’hyperviseur expose les extensions VT-x / AMD-V à la VM, qui peut à son tour lancer des VM
    - Usages : formation, laboratoires, intégration continue, cloud
    - Coût : chaque niveau ajoute des passages par l’hyperviseur
    - On imbrique aussi des conteneurs dans une VM : très courant (Docker Desktop, cloud)
  ]
  let b-droite = bloc(role: "pratique", poids: 1.25)[Avec KVM : trois niveaux][
    #terminal(titre: none)[
      #cadre([Hôte (niveau 0)], niveau: 0)[
        ```
        # l’imbrication est-elle permise par le module kvm ?
        $ cat /sys/module/kvm_intel/parameters/nested
        Y
        # -cpu host : la VM reçoit les extensions VT-x
        $ qemu-system-x86_64 -accel kvm -cpu host …
        ```
        #uncover("6-", cadre([VM (niveau 1)], niveau: 1)[
          ```
          # KVM est disponible dans la VM
          $ ls /dev/kvm
          /dev/kvm
          $ qemu-system-x86_64 -accel kvm …
          ```
          #uncover("7-", cadre([VM imbriquée (niveau 2)], niveau: 2)[
            ```
            $ systemd-detect-virt
            kvm
            ```
          ])
        ])
      ]
    ]
    #text(size: px(22))[Chaque cadre est une machine lancée par la commande `qemu` juste au-dessus.]
  ]
  rangee(poids: (1, 1.25),
    h => bloc-anime(b-gauche, 1, uncover, hauteur: h),
    h => bloc-anime(b-droite, 5, uncover, hauteur: h),
  )
  source[#link("https://www.kernel.org/doc/html/latest/virt/kvm/x86/running-nested-guests.html")[kernel.org, Running nested guests with KVM]]
  utils.speaker-note(self: self)[Lecture des cadres : bleu à trait plein = terminal de l’hôte physique (niveau 0) ; violet à tirets = terminal de la VM lancée par la première commande qemu (niveau 1) ; rose à pointillés = terminal de la VM lancée depuis cette VM (niveau 2). -cpu host transmet les extensions vmx/svm à la VM, d’où la présence de /dev/kvm au niveau 1. Sur AMD : /sys/module/kvm\_amd/parameters/nested (affiche 1). Sorties types, à rejouer sur le poste de démonstration avec virtualisation/rejouer-tp.sh, qui note aussi les versions employées.]
})

== Choisir l’image Debian à installer

#anime(
  rang(
    bloc(taille: px(26))[Où la trouver, quoi prendre][
      - *Source officielle uniquement* : debian.org/download, qui renvoie vers cdimage.debian.org
      - Image *netinst amd64* (756 Mio), une image ISO (image de CD ou DVD) : installateur minimal, les paquets viennent ensuite du réseau
      - Le dossier « current » suit la dernière version (13.7.0 en novembre 2026) : le nom du fichier change à chaque mise à jour
    ],
    bloc(role: "pratique", taille: px(24))[Trois fichiers à télécharger][
      - *debian-13.7.0-amd64-netinst.iso* : l’image elle-même
      - *SHA256SUMS* : les empreintes des images
      - *SHA256SUMS.sign* : la signature de ce fichier par Debian
    ],
  ),
  rang(bloc(role: "danger", taille: px(26))[Attention : une image téléchargée se vérifie avant usage][
    - *Intégrité* : le fichier est-il arrivé intact (téléchargement interrompu, disque, miroir défaillant) ? → empreinte
    - *Authenticité* : est-ce bien l’image publiée par Debian, et pas une image piégée ? → signature
  ]),
  source-de: [#link("https://www.debian.org/download")[debian.org/download] · #link("https://www.debian.org/CD/verify")[debian.org/CD/verify]],
  note: [Les trois fichiers — image, SHA256SUMS, SHA256SUMS.sign — sont dans le même dossier du dépôt, d’où le préfixe \$URL\_BASE commun ; on les met dans un répertoire local dédié (ici \~/iso-debian). Le mini TP installe une VM Debian : il faut d’abord l’image d’installation. debian.org/download pointe vers l’image netinst amd64 et vers SHA256SUMS et SHA256SUMS.sign. Le 16 novembre 2026, l’image fait 792 723 456 octets (756 Mio). Une image piégée installe un système compromis dès le départ : exemple réel, le site de Linux Mint a distribué une ISO modifiée en février 2016. La diapositive suivante définit la somme de contrôle ; le téléchargement et la vérification sont regroupés sur la diapositive « Télécharger l’ISO, puis la vérifier ».],
)

== Une empreinte résume un fichier

#anime(
  rang(
    bloc(taille: px(26))[Définition][
      - Une *fonction de hachage* calcule, à partir d’un fichier de taille quelconque, une *empreinte* de taille fixe
      - SHA-256 (_Secure Hash Algorithm_, famille SHA-2) : 256 bits, soit 64 chiffres hexadécimaux (128 pour SHA-512)
      - Même contenu : toujours la même empreinte
      - Un seul bit modifié : une empreinte complètement différente
    ],
    bloc(role: "pratique", poids: 1.1, taille: px(24))[Démonstration][
      #terminal[
        ```
        # … empreintes tronquées à 40 chiffres sur 64
        $ echo bonjour | sha256sum
        9cec0af545144159bac85c7b908d5e0b9b0ef961  -
        $ echo Bonjour | sha256sum
        8dc2a6966f1be1644ec6b1f7223f47e53de5ad05  -
        $ sha256sum debian-13.7.0-amd64-netinst.iso
        a7ef94ac2fb9a7fec454552abd629b7cc9d5155c  debian-…
        ```
      ]
      Une lettre change, toute l’empreinte change. 756 Mio ou 8 octets : même longueur d’empreinte.
    ],
  ),
  rang(bloc(taille: px(26))[À quoi ça sert][
    On calcule l’empreinte du fichier reçu et on la compare à l’empreinte publiée par l’éditeur. Identiques : le fichier est *intact*. Somme de contrôle, empreinte, condensat, _hash_ : synonymes ici.
  ]),
  source-de: link("https://csrc.nist.gov/pubs/fips/180-4/upd1/final")[NIST, FIPS 180-4 (famille SHA-2)],
  note: [Sorties de sha256sum (GNU coreutils 9.4), tronquées à 40 chiffres hexadécimaux pour tenir sur la diapositive, comme l’annonce la première ligne du terminal. Le tiret final signifie « entrée standard ». Empreintes complètes : bonjour = 9cec0af545144159bac85c7b908d5e0b9b0ef961497401c5ad8da26f065ad926 ; Bonjour = 8dc2a6966f1be1644ec6b1f7223f47e53de5ad05e1c976736d948e7977a13dd3 ; ISO 13.7.0 = a7ef94ac2fb9a7fec454552abd629b7cc9d5155c886165a45649f5ce6167e355. Deux fichiers différents peuvent en théorie avoir la même empreinte (collision) ; une fonction cryptographique rend cette recherche impraticable.],
)

== Télécharger l’ISO, puis la vérifier

#slide(repeat: 6, self => {
  let (uncover,) = utils.methods(self)
  let b-deux = bloc(taille: px(22), taille-titre: px(24))[Deux contrôles, deux fichiers][
    - *Intégrité* → `SHA256SUMS` : l’image est-elle intacte ?
    - *Authenticité* → `SHA256SUMS.sign` : vient-elle bien de Debian ?
  ]
  let b-algo = bloc(role: "avertissement", taille: px(22), taille-titre: px(24))[Quel algorithme d’empreinte ?][
    - *MD5* (_Message Digest 5_), *SHA-1* : cassés, on sait fabriquer deux fichiers de même empreinte (collisions)
    - *SHA-256 / SHA-512* (SHA-2) : standard actuel, aucune collision connue ; Debian publie les deux
    - Contre une image *substituée*, il faut la résistance aux collisions → SHA-2
  ]
  rangee(poids: (1.35, 1),
    h => terminal(titre: [Terminal — télécharger, puis vérifier], taille: px(19), hauteur: h)[
      ```
      # 1. un répertoire dédié, tout au même endroit
      $ mkdir -p ~/iso-debian
      $ cd ~/iso-debian
      $ URL_BASE=https://cdimage.debian.org/debian-cd/current/amd64/iso-cd
      $ wget $URL_BASE/debian-13.7.0-amd64-netinst.iso
      $ wget $URL_BASE/SHA256SUMS
      $ wget $URL_BASE/SHA256SUMS.sign
      ```
      #uncover("2-")[
        ```
        # 2. authenticité : ces empreintes viennent-elles de Debian ?
        # (gpgv : vérificateur de signatures de GnuPG)
        $ sudo apt install debian-keyring
        $ gpgv --keyring /usr/share/keyrings/debian-role-keys.pgp \
               SHA256SUMS.sign SHA256SUMS
        gpgv: Good signature from "Debian CD signing key"
        ```
      ]
      #uncover("3-")[
        ```
        # 3. intégrité : l’image correspond-elle à son empreinte ?
        $ sha256sum -c --ignore-missing SHA256SUMS
        debian-13.7.0-amd64-netinst.iso: OK
        ```
      ]
    ],
    h => block(height: h, stack(spacing: px(20),
      bloc-anime(b-deux, 4, uncover),
      bloc-anime(b-algo, 5, uncover),
      uncover("6-", note[Ordre logique : *signature d’abord*, puis empreinte. Si la signature échoue, on s’arrête là.]),
    )),
  )
  source[#link("https://www.debian.org/CD/verify")[debian.org/CD/verify]]
  utils.speaker-note(self: self)[Une phase du terminal par clic, puis les deux encadrés et la note. Le 18 novembre 2026, sur l’image 13.7.0 (792 723 456 octets) : gpgv → Good signature (clé DF9B 9C49 EAA9 2984 3258 9D76 DA87 E80D 6294 BE9B, trousseau debian-role-keys.pgp du paquet debian-keyring) ; sha256sum -c → OK, puis FAILED après modification d’un seul octet. Les trois fichiers partent du même \$URL\_BASE : image, sommes et signature sont au même endroit du dépôt. --ignore-missing : SHA256SUMS liste aussi d’autres images non téléchargées. Sur le choix de l’algorithme : MD5 (collisions pratiques depuis \~2008) et SHA-1 (collision « SHAttered », Google 2017) sont cassés ; SHA-256/512 (famille SHA-2) n’ont pas de collision connue. La résistance aux collisions importe face à un attaquant qui voudrait faire passer une autre image pour l’officielle ; pour une simple corruption de transfert, même un hachage faible suffirait. L’anti-falsification vient en dernier ressort de la signature GPG, qui protège le fichier d’empreintes lui-même. Sans machine Debian : gpg --verify SHA256SUMS.sign SHA256SUMS après import de la clé, puis comparer son empreinte à celle de debian.org/CD/verify.]
})

== Créer une VM : virt-install, puis virsh

#anime(
  rang(
    bloc(role: "pratique", poids: 1.3)[Démonstration][
      #terminal(taille: px(21))[
        ```
        # extensions de virtualisation exposées ?
        $ grep -cE 'vmx|svm' /proc/cpuinfo
        8
        # modules KVM chargés
        $ ls /sys/module | grep kvm
        kvm
        kvm_intel
        $ sudo apt install qemu-system-x86 \
          libvirt-daemon-system virtinst virt-viewer
        # VM : 2 Gio de mémoire, 2 processeurs, disque de 10 Gio
        $ virt-install --name test --memory 2048 \
          --vcpus 2 --disk size=10 --osinfo detect=on \
          --cdrom debian-13.7.0-amd64-netinst.iso
        # virt-viewer ouvre la console : on y fait l’installation
        # toutes les VM, même arrêtées
        $ virsh list --all
        ```
      ]
    ],
    bloc(role: "retenir")[À retenir][
      - virt-install crée la VM, virsh la gère : tous deux passent par libvirt
      - virt-viewer affiche la console graphique de l’installateur
      - Prérequis : être membre des groupes kvm et libvirt
    ],
  ),
  source-de: [#link("https://libvirt.org/docs.html")[libvirt.org] · #link("https://github.com/virt-manager/virt-manager/blob/main/man/virt-install.rst")[virt-install(1)]],
  note: [L’ISO est celle téléchargée et vérifiée aux diapositives précédentes. grep -c compte une ligne par processeur logique : un nombre non nul indique que les extensions sont exposées. Commandes pour Debian/Ubuntu ; --osinfo existe depuis virt-install 4.0 ; detect=on identifie l’OS à partir de l’ISO ; --disk size=10 s’exprime en Gio. Par défaut virt-install choisit un affichage graphique (protocoles SPICE ou VNC) et lance virt-viewer (--autoconsole graphical) pour interagir avec l’installateur ; sans virt-viewer, aucune console ne s’ouvre et l’installation interactive est impossible. Alternative en mode texte : --graphics none avec une console série (virsh console). virsh list --all affiche une ligne par VM : identifiant, nom, état (en cours d’exécution, fermé). Proxmox VE, OpenStack et oVirt s’appuient aussi sur KVM. Sorties types, à rejouer avec virtualisation/rejouer-tp.sh.],
)

== Mini TP : une VM, puis une VM dans la VM

#anime(
  rang(bloc(role: "pratique", taille: px(24))[Prérequis][
    - Un PC Linux (Debian ou Ubuntu) avec VT-x / AMD-V activé dans l’UEFI ; être membre du groupe kvm
    - Paquets `qemu-system-x86` et `qemu-utils` ; l’ISO Debian vérifiée (diapositive « Télécharger l’ISO, puis la vérifier »)
    - Question 6 : l’image Alpine « Virtual » x86\_64 (#link("https://alpinelinux.org/downloads/")[alpinelinux.org/downloads]), téléchargée dans la VM Debian
  ]),
  rang(bloc(role: "question")[À vous][
    + Votre processeur expose-t-il les extensions de virtualisation (VT-x ou AMD-V) ?
    + KVM est-il utilisable sur votre hôte ?
    + Installez Debian dans une VM (QEMU et KVM, ISO + disque, périphériques virtio), puis montrez que cette VM est un *processus de l’hôte*
    + Relancez-la *sans KVM* : que constatez-vous ? Comment le vérifier depuis le moniteur QEMU ?
    + Dans l’invité : l’OS sait-il qu’il est virtualisé ?
    + Virtualisation imbriquée : dans votre VM Debian, lancez une VM Alpine
  ]),
  note: [À faire en direct, une question par clic. Laisser chercher avant de passer au corrigé. Aide : man qemu-system-x86\_64 ; Ctrl+Alt+2 ouvre le moniteur QEMU.],
)

== Mini TP : corrigé (1/4)

// Les questions restent affichées ; une réponse par clic.
#slide(repeat: 3, self => {
  let (uncover,) = utils.methods(self)
  corrige(1, [Votre processeur expose-t-il les extensions de virtualisation (VT-x ou AMD-V) ?],
    uncover("2-", reponse(terminal(titre: none, taille: px(22))[
      ```
      $ lscpu | grep -E 'Virtualization|Virtualisation'
      Virtualisation :    VT-x
      # processeurs logiques qui annoncent vmx (Intel) ou svm (AMD)
      $ grep -cE 'vmx|svm' /proc/cpuinfo
      8
      # → oui : extensions VT-x présentes
      ```
    ])))
  v(px(8)); filet-corrige; v(px(8))
  corrige(2, [KVM est-il utilisable sur votre hôte ?],
    uncover("3-", reponse(terminal(titre: none, taille: px(22))[
      ```
      # modules du noyau chargés pour KVM
      $ ls /sys/module | grep kvm
      kvm
      kvm_intel
      # droits sur le périphérique de KVM
      $ stat -c '%A %U %G %n' /dev/kvm
      crw-rw---- root kvm /dev/kvm
      # → oui, pour les membres du groupe kvm
      ```
    ])))
  utils.speaker-note(self: self)[Question 1 : un résultat 0 signifie extensions absentes ou désactivées dans l’UEFI ; lscpu affiche « Virtualization » ou « Virtualisation » selon la langue. Question 2 : /dev/kvm est un périphérique caractère (c), lisible et inscriptible par root et par le groupe kvm ; sur AMD, le module s’appelle kvm\_amd. Sorties types, à rejouer avec virtualisation/rejouer-tp.sh, qui note aussi les versions.]
})

== Mini TP : corrigé (2/4)

#slide(repeat: 2, self => {
  let (uncover,) = utils.methods(self)
  corrige(3, [Installez Debian dans une VM (QEMU et KVM, ISO + disque, périphériques virtio), puis montrez que cette VM est un *processus de l’hôte*],
    uncover("2-", reponse(terminal(titre: none, taille: px(22))[
      ```
      # disque de 20 Gio, alloué au fil de l’eau
      $ qemu-img create -q -f qcow2 debian.qcow2 20G
      $ ls -sh debian.qcow2
      196K debian.qcow2
      # disque et carte réseau paravirtualisés (virtio)
      $ qemu-system-x86_64 -accel kvm -m 2048 \
        -cdrom debian-13.7.0-amd64-netinst.iso \
        -drive file=debian.qcow2,format=qcow2,if=virtio \
        -nic user,model=virtio-net-pci &
      # nom du processus, tronqué à 15 caractères
      $ pgrep -l qemu
      4242 qemu-system-x86
      # → la VM est le processus 4242 de l’hôte
      ```
    ])))
  utils.speaker-note(self: self)[qemu-img réserve 20 Gio sans les allouer : le fichier ne pèse d’abord que 196 Kio (QEMU 8.2.2) et grossit avec les données écrites. if=virtio et model=virtio-net-pci donnent à l’invité un disque et une carte réseau paravirtualisés, que la question 5 retrouve ; sans eux, QEMU présente un disque IDE et une carte e1000. On installe Debian sur le disque, puis on relance sans -cdrom. pgrep -l affiche le PID et le nom du processus ; ps -o pid,user,args -C qemu-system-x86\_64 montre en plus son propriétaire. Le PID varie d’une machine à l’autre.]
})

== Mini TP : corrigé (3/4)

#slide(repeat: 3, self => {
  let (uncover,) = utils.methods(self)
  corrige(4, [Relancez-la *sans KVM* : que constatez-vous ? Comment le vérifier depuis le moniteur QEMU ?],
    uncover("2-", reponse(terminal(titre: none, taille: px(22))[
      ```
      # tcg : le processeur est émulé, sans KVM
      $ qemu-system-x86_64 -accel tcg -m 2048 \
        -drive file=debian.qcow2,format=qcow2,if=virtio \
        -nic user,model=virtio-net-pci
      # → la VM démarre, mais bien plus lentement
      ```
      #encart[Moniteur QEMU (Ctrl+Alt+2)][
        ```
        (qemu) info kvm
        kvm support: disabled
        ```
      ]
    ])))
  v(px(8)); filet-corrige; v(px(8))
  corrige(5, [Dans l’invité : l’OS sait-il qu’il est virtualisé ?],
    uncover("3-", reponse(terminal(titre: none, taille: px(22))[
      #encart[Invité][
        ```
        $ systemd-detect-virt
        kvm
        # périphériques paravirtualisés vus par l’invité
        $ lspci | grep -i virtio
        # … une ligne par périphérique virtio (disque, réseau)
        # → oui : l’invité sait qu’il tourne sous KVM
        ```
      ]
    ])))
  utils.speaker-note(self: self)[Question 4 : avec -accel tcg (l’accélérateur par défaut quand on n’en précise aucun), QEMU émule le processeur ; la VM est nettement plus lente. Dans le moniteur QEMU (Ctrl+Alt+2, retour à l’affichage par Ctrl+Alt+1), info kvm affiche « kvm support: disabled » (sortie de QEMU 8.2.2). Question 5 : systemd-detect-virt renvoie kvm sous KVM, qemu en émulation pure ; lspci liste le disque et la carte réseau virtio ajoutés à la question 3. Sorties de la question 5 à rejouer sur le poste de démonstration.]
})

== Mini TP : corrigé (4/4)

#slide(repeat: 3, self => {
  let (uncover,) = utils.methods(self)
  corrige(6, [Virtualisation imbriquée : dans votre VM Debian, lancez une VM Alpine],
    reponse(terminal(titre: none, taille: px(20))[
      #cadre([Hôte (niveau 0)], niveau: 0)[
        ```
        $ cat /sys/module/kvm_intel/parameters/nested
        Y
        # -cpu host : transmet VT-x / AMD-V à la VM
        $ qemu-system-x86_64 -accel kvm -cpu host -m 2048 -smp 2 \
          -drive file=debian.qcow2,format=qcow2,if=virtio
        ```
        #uncover("2-", cadre([VM Debian (niveau 1)], niveau: 1)[
          ```
          $ ls /dev/kvm
          /dev/kvm
          $ sudo apt install qemu-system-x86 wget
          # URL_ALPINE : lien « Virtual x86_64 » de alpinelinux.org/downloads
          $ wget "$URL_ALPINE"
          $ qemu-system-x86_64 -accel kvm -cpu host -m 512 \
            -cdrom alpine-virt-*-x86_64.iso
          ```
          #uncover("3-", cadre([VM Alpine (niveau 2)], niveau: 2)[
            ```
            # identifiant root, sans mot de passe
            $ dmesg | grep -i hypervisor
            Hypervisor detected: KVM
            # → la VM Alpine tourne sous le KVM de la VM Debian
            ```
          ])
        ])
      ]
    ]))
  utils.speaker-note(self: self)[Prérequis : la VM Debian installée sur debian.qcow2 à la question 3. Clic 1, hôte : nested doit valoir Y (Intel) ou 1 (AMD, /sys/module/kvm\_amd/parameters/nested) ; sinon, recharger le module avec l’option nested=1. La VM de niveau 1 doit être relancée avec -cpu host : sans cette option, le processeur virtuel n’expose pas vmx/svm, /dev/kvm est absent dans la VM et la VM imbriquée tourne en émulation pure (TCG), très lentement. Prévoir assez de mémoire au niveau 1 pour héberger le niveau 2. Clic 2, niveau 1 : /dev/kvm présent ; on installe QEMU, on télécharge l’image Alpine « Virtual » (quelques dizaines de Mio, nom de fichier versionné, d’où le motif alpine-virt-\*) et on lance l’invité. Clic 3, niveau 2 : Alpine démarre sur l’ISO en mode live, identifiant root sans mot de passe ; dmesg montre l’hyperviseur KVM (ici celui de la VM de niveau 1). Sorties types, à rejouer sur le poste de démonstration.]
})

== virt-manager : libvirt en interface graphique

#anime(
  rang(
    bloc(taille: px(27))[Ce que c’est][
      - L’*interface graphique de libvirt* : même moteur que la ligne de commande `virsh`
      - Créer, démarrer, arrêter, cloner une VM ; console graphique intégrée (protocoles VNC ou SPICE)
      - Gère l’hôte local, ou un hôte distant via SSH : `qemu+ssh://serveur/system`
    ],
    bloc(role: "pratique", taille: px(27))[Bon à savoir][
      - Application de *bureau, mono-poste* : ni cluster, ni haute disponibilité, ni multi-utilisateur
      - Sur Debian/Ubuntu : paquet `virt-manager`, l’outil graphique de référence
      - Sous Red Hat, déprécié au profit de la console web *Cockpit* (`cockpit-machines`)
    ],
  ),
  bandeau[*Origine* : projet *libvirt / virt-manager*, développé par *Red Hat* et sa communauté · logiciel libre (GPL) · pilote KVM/QEMU au travers de libvirt · #link("https://virt-manager.org")[virt-manager.org]],
  note: [Suite directe de la diapositive sur virt-install et virsh : l’équivalent graphique. virt-manager (Virtual Machine Manager) et virsh s’appuient tous deux sur libvirt ; ce qui est fait dans l’un se retrouve dans l’autre. Console distante via SSH : virt-manager -c qemu+ssh:\/\/user\@hote/system. Statut au 18 novembre 2026 : toujours maintenu en amont et standard sur Debian/Ubuntu ; Red Hat l’a déprécié dans RHEL (annoncé dès RHEL 8) et pousse la console web Cockpit avec le module cockpit-machines.],
)

== Incus : conteneurs et VM, un seul outil

#anime(
  rang(
    bloc(taille: px(27))[Ce que c’est][
      - Un gestionnaire *unique* pour des *conteneurs système* (LXC, _Linux Containers_) *et* des *machines virtuelles* (QEMU/KVM), en ligne de commande (`incus`) ou par API
      - Conteneur « système » : un OS complet avec son init, persistant ; à distinguer des conteneurs *applicatifs* de Docker
      - Fondé sur des *images*, API REST, instantanés, migration à chaud
    ],
    bloc(role: "pratique", taille: px(27))[Bon à savoir][
      - *Cluster* de plusieurs nœuds, projets et profils, quotas de ressources
      - Une VM : `incus launch images:debian/13 v1 --vm`
      - Un conteneur : la même commande *sans* `--vm`
    ],
  ),
  bandeau[*Incus* : fork communautaire de *LXD* (créé par *Canonical*, éditeur d’Ubuntu), passé sous le projet *Linux Containers* (Stéphane Graber) · Apache-2.0 · paquet `incus` dans Debian 13 · #link("https://linuxcontainers.org/incus/")[linuxcontainers.org/incus]],
  note: [Incus prolonge la logique de virtualisation vers les conteneurs système, pont naturel vers le cours Docker (conteneurs applicatifs). Au 18 novembre 2026 : Incus est un fork de LXD lancé par Stéphane Graber en 2023 sous le projet Linux Containers (dépôt lxc/incus) ; il gère conteneurs LXC et VM QEMU/KVM par une même ligne de commande et une même API ; licence Apache-2.0 ; empaqueté dans Debian 13 (paquet incus) ; version 6.21 fin 2025 / début 2026. Conteneur système ≠ conteneur applicatif : le premier fait tourner un OS complet (comme une VM légère, en partageant le noyau de l’hôte), le second un seul processus applicatif.],
)

== Proxmox VE : la virtualisation clé en main

#anime(
  rang(
    bloc(taille: px(27))[Ce que c’est][
      - Une *distribution complète* (basée sur Debian) : hyperviseur + interface web, installée directement sur le serveur
      - *KVM* pour les machines virtuelles, *LXC* pour les conteneurs système
      - Tout se pilote depuis l’interface web : création, console, modèles, sauvegardes
    ],
    bloc(role: "pratique", taille: px(27))[Pour la production][
      - Cluster de plusieurs nœuds, *haute disponibilité*, migration à chaud
      - Stockage et réseau définis par logiciel : *Ceph* intégré, réseau SDN (_software-defined networking_)
      - Sauvegardes avec Proxmox Backup Server
    ],
  ),
  bandeau[*Proxmox VE* : édité par *Proxmox Server Solutions GmbH* (Vienne, Autriche) · base Debian · open source AGPL, abonnement entreprise payant · s’appuie sur KVM et LXC · #link("https://pve.proxmox.com/pve-docs/")[pve.proxmox.com]],
  note: [À la différence de virt-manager (application de bureau sur un poste), Proxmox s’installe sur le serveur lui-même (bare metal) et fournit l’hyperviseur ET son interface. Positionné comme alternative à VMware vSphere/ESXi. Au 18 novembre 2026 : Proxmox VE 9.2, base Debian 13, noyau 7.0 (sources Proxmox). Licence AGPLv3 ; le logiciel est gratuit, l’abonnement donne accès au dépôt entreprise (mises à jour stabilisées) et au support.],
)

== oVirt : gérer un datacenter KVM

#anime(
  rang(
    bloc(taille: px(27))[Ce que c’est][
      - Plateforme *web* de gestion de la virtualisation *KVM* à l’échelle d’un *datacenter* (moteur _oVirt Engine_)
      - Pilote un *cluster d’hôtes* KVM/libvirt : création de VM, *migration à chaud*, haute disponibilité
      - Stockage, réseaux, modèles et instantanés depuis une seule interface ; alternative libre à VMware vSphere
    ],
    bloc(role: "pratique", taille: px(27))[Statut aujourd’hui][
      - Était l’*amont* de Red Hat Virtualization (RHV)
      - Red Hat a *arrêté RHV* et bascule vers *OpenShift Virtualization* (KubeVirt)
      - oVirt continue surtout en *communautaire* ; *Oracle Linux Virtualization Manager* (OLVM) en est un dérivé maintenu
    ],
  ),
  bandeau[Projet *oVirt*, lancé par *Red Hat* (2012) comme amont de RHV · Apache-2.0 · fondé sur *KVM/libvirt* · depuis l’arrêt de RHV, projet surtout communautaire, poursuivi par *Oracle* (OLVM) · #link("https://www.ovirt.org")[ovirt.org]],
  note: [Même famille que virt-manager et Proxmox (tous fondés sur KVM/libvirt), mais à l’échelle datacenter avec un moteur de gestion centralisé (oVirt Engine, en Java) et des hôtes exécutant KVM via l’agent VDSM. Au 18 novembre 2026 : oVirt lancé par Red Hat vers 2011-2012 comme amont de Red Hat Virtualization (RHV/RHEV) ; licence Apache-2.0 ; fondé sur KVM et libvirt. Red Hat a mis fin à RHV et oriente ses clients vers OpenShift Virtualization (fondée sur KubeVirt) : oVirt est donc devenu surtout communautaire, avec une sortie 4.5.7 après environ deux ans ; Oracle maintient un dérivé, Oracle Linux Virtualization Manager (OLVM). Fil conducteur : la gestion de VM KVM « datacenter » de Red Hat est passée d’oVirt/RHV à OpenShift Virtualization.],
)

== OpenShift (hors cadre) : Kubernetes

#anime(
  rang(
    bloc(taille: px(27))[Ce que c’est][
      - Distribution *Kubernetes* de Red Hat pour orchestrer des *conteneurs applicatifs* sur un cluster de serveurs
      - Ajoute à Kubernetes : console web, intégration et déploiement continus (CI/CD), registre d’images, contrôle d’accès par rôles (RBAC), contraintes de sécurité des conteneurs (SCC)
      - *OKD* en est la version communautaire libre
    ],
    bloc(role: "precaution", taille: px(27))[Hors cadre][
      - Ce cours s’arrête à la VM sur *un hôte* ; OpenShift gère un *cluster* qui ordonnance des conteneurs
      - Seul lien : *OpenShift Virtualization* (KubeVirt) fait tourner des VM *à côté* des conteneurs
      - La conteneurisation est le sujet du cours suivant
    ],
  ),
  bandeau[*OpenShift* : édité par *Red Hat* (groupe IBM), bâti sur *Kubernetes* (créé par Google en 2014, aujourd’hui projet de la *CNCF*, _Cloud Native Computing Foundation_) · VM + conteneurs via KubeVirt · #link("https://docs.openshift.com")[docs.openshift.com]],
  note: [Diapositive d’ouverture, hors du cadre du cours : elle situe la virtualisation par rapport à l’orchestration de conteneurs. Au 18 novembre 2026 : OpenShift 4.20 en disponibilité générale depuis le 11 novembre 2025 (Red Hat) ; plateforme bâtie sur Kubernetes ; socle RHEL CoreOS ; build source-to-image et Operators ; OpenShift Virtualization (fondé sur le projet KubeVirt) exécute des machines virtuelles aux côtés des conteneurs ; OKD est la distribution communautaire en amont. Les conteneurs applicatifs sont le sujet du cours Docker qui suit.],
)

== Xen Orchestra : la console web de XCP-ng

#anime(
  rang(
    bloc(taille: px(27))[Ce que c’est][
      - L’*interface web de gestion de XCP-ng* (et de XenServer), hyperviseur de *type 1* fondé sur Xen
      - Développé par *Vates*, l’éditeur de XCP-ng
      - Gère un ou plusieurs *pools* de serveurs depuis une seule interface
    ],
    bloc(role: "pratique", taille: px(27))[Fonctions][
      - Sauvegarde et réplication des VM, migration à chaud
      - Ordonnancement des tâches, statistiques
      - Multi-utilisateur : rôles et délégation de droits
    ],
  ),
  bandeau(taille: px(24))[Édités par *Vates* (France) : *XCP-ng* (l’hyperviseur) et *Xen Orchestra* (sa console web), fondés sur *Xen*, créé à l’université de Cambridge (2003), aujourd’hui Xen Project / Linux Foundation · XCP-ng est un fork libre de Citrix *XenServer* · cœur open source, édition commerciale XOA · #link("https://docs.xen-orchestra.com")[docs.xen-orchestra.com]],
  note: [Après KVM (virt-manager, Proxmox, oVirt), l’écosystème Xen. Lien avec la diapositive sur KVM et Xen : XCP-ng est une distribution hyperviseur fondée sur Xen (type 1), Xen Orchestra en est la console web. Vates, éditeur français de XCP-ng et Xen Orchestra, positionne l’ensemble (Vates VMS, Virtualization Management Stack) comme alternative à VMware vSphere. Xen Orchestra : cœur open source, édition commerciale XOA (Xen Orchestra Appliance) avec support et fonctions avancées ; on peut aussi le construire depuis les sources. Source : documentation Vates, au 18 novembre 2026.],
)

== Qubes OS : la sécurité par compartimentage

#anime(
  rang(
    bloc(taille: px(27))[Ce que c’est][
      - Un *système de bureau* qui applique la *sécurité par compartimentage* : chaque activité tourne dans sa propre VM, un « *qube* »
      - Repose sur l’hyperviseur *Xen* (type 1) : c’est tout le *poste de travail* qui est virtualisé, pas un serveur
      - Fenêtres *bordées de couleur* selon le niveau de confiance (travail, perso, non fiable)
    ],
    bloc(role: "pratique", taille: px(27))[Comment ça marche][
      - *dom0* administrateur, sans réseau ; réseau et USB isolés dans des qubes dédiés (`sys-net`, `sys-usb`)
      - *Qubes jetables* : ouvrir une pièce jointe douteuse, puis tout détruire
      - VM dérivées de *modèles* (Fedora, Debian, Whonix/Tor) : mises à jour centralisées
    ],
  ),
  bandeau[Projet *Qubes OS*, lancé en 2010 par *Joanna Rutkowska* (Invisible Things Lab) · logiciel libre (GPL) · bâti sur l’hyperviseur *Xen* · ici la virtualisation sert la *sécurité*, pas la consolidation de serveurs · #link("https://www.qubes-os.org/doc/")[qubes-os.org/doc]],
  note: [Exemple marquant d’usage de la virtualisation de type 1 côté poste de travail, pour la sécurité et non la consolidation. Chaque qube est une VM Xen ; le compromis d’une application reste confiné à son qube. dom0 (le domaine d’administration Xen) n’a pas d’accès réseau ; des qubes de service dédiés portent le réseau (sys-net), le pare-feu (sys-firewall) et l’USB (sys-usb). Les VM applicatives dérivent de modèles en lecture seule (Fedora, Debian, Whonix pour Tor), ce qui centralise les mises à jour. Les qubes jetables (DisposableVM) servent à ouvrir un fichier à risque puis disparaissent. Au 18 novembre 2026 : projet fondé par Joanna Rutkowska (Invisible Things Lab), première version stable 1.0 en 2012 ; série stable 4.2 depuis fin 2023 ; licence GPL ; fondé sur Xen. Rendu célèbre notamment par le soutien public d’Edward Snowden.],
)

// ======================================================================
= Pour aller plus loin

== MicroVM : une VM réduite à l’essentiel

#anime(
  rang(bloc(taille: px(26))[L’idée][
    - Une vraie VM, exécutée par KVM : son propre noyau, l’isolation du matériel
    - Une machine virtuelle minimale : quelques périphériques virtio, ni micrologiciel de démarrage (BIOS) ni matériel hérité (USB, carte graphique…)
    - Démarrage direct du noyau invité : rapide, peu de mémoire, donc des milliers de microVM par hôte
  ]),
  rang(bloc(taille: px(24))[Où se place la microVM ?][
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
  ]),
  note: [La microVM répond au besoin du cloud multi-locataire : exécuter le code de clients différents sur un même hôte avec l’isolation d’une VM, au rythme et à la densité des conteneurs (fonctions serverless, bacs à sable). Le tableau est qualitatif : les temps dépendent du noyau invité et de la charge. Les conteneurs sont détaillés à la dernière diapositive et dans le cours Docker.],
)

== MicroVM : les technologies

#slide(repeat: 5, self => {
  let (uncover,) = utils.methods(self)
  lignes(largeur: px(420), taille: px(26), uncover: uncover,
    ([Firecracker], [AWS, 2018, écrit en Rust : derrière Lambda et Fargate ; annonce moins de 125 ms de démarrage et moins de 5 Mio de surcoût par microVM]),
    ([Cloud Hypervisor], [2019, en Rust, projet de la Linux Foundation : charges cloud, plus de périphériques que Firecracker]),
    ([QEMU microvm], [Le type de machine « microvm » de QEMU (depuis la 4.2) : le même QEMU, sans le matériel hérité]),
    ([Kata Containers], [Chaque conteneur dans sa microVM : s’utilise comme moteur d’exécution avec containerd et Kubernetes]),
  )
  espace
  bloc-anime(bloc(role: "precaution")[À ne pas confondre][
    gVisor n’est pas une microVM : c’est un noyau réécrit en espace utilisateur, qui intercepte les appels système du conteneur.
  ], 5, uncover)
  source[#link("https://firecracker-microvm.github.io")[firecracker-microvm.github.io] · #link("https://www.cloudhypervisor.org")[cloudhypervisor.org] · #link("https://www.qemu.org/docs/master/system/i386/microvm.html")[qemu.org, microvm] · #link("https://katacontainers.io")[katacontainers.io]]
  utils.speaker-note(self: self)[Tous s’appuient sur KVM (rappel : KVM exécute, un programme en espace utilisateur fournit la machine ; ici ce programme remplace QEMU ou l’allège). Firecracker : publié en open source par AWS en novembre 2018 ; les chiffres de démarrage et de mémoire sont ceux annoncés par le projet (firecracker-microvm.github.io). Cloud Hypervisor : lancé par Intel en 2019. QEMU : machine microvm introduite en version 4.2 (décembre 2019). Kata Containers : fusion d’Intel Clear Containers et de Hyper runV (2017), fondation OpenInfra (rattachée à la Linux Foundation depuis 2025) ; peut utiliser QEMU, Cloud Hypervisor ou Firecracker comme hyperviseur. crosvm (Google, ChromeOS et Android) est de la même famille.]
})

== VM et conteneurs : deux façons d’isoler

#slide(repeat: 2, self => {
  let (uncover,) = utils.methods(self)
  grid(columns: (1fr, 1fr), column-gutter: px(64),
    pile-archi([Machines virtuelles (KVM)], [Espace utilisateur de l’hôte],
      [*Gestion* (crée, démarre, arrête) : libvirt],
      range(1, 4).map(i => vm[VM #i : QEMU]),
      [Noyau Linux de l’hôte], ([module kvm],), [Matériel (VT-x / AMD-V)]),
    uncover("2-", pile-archi([Conteneurs], [Espace utilisateur de l’hôte],
      [*Gestion* (crée, démarre, arrête) : dockerd, containerd, runc],
      range(1, 4).map(i => vm(bas: [Bibliothèques], fond-bas: rgb("#FBFBF8"))[Conteneur #i]),
      [Noyau Linux de l’hôte], ([namespaces], [cgroups], [capabilities], [seccomp], [AppArmor]),
      [Matériel])),
  )
  utils.speaker-note(self: self)[Représentation fidèle (cas KVM). Une VM est un processus QEMU de l’hôte qui contient un OS invité complet, noyau compris : son code s’exécute directement sur le processeur (mode VT-x / AMD-V), le module kvm du noyau n’intervient que sur les opérations privilégiées, QEMU émule les périphériques. Un conteneur est un ensemble de processus ordinaires de l’hôte : ils appellent directement le noyau de l’hôte, qui les isole (namespaces), les limite (cgroups) et restreint leurs droits (capabilities, seccomp, AppArmor : le module de sécurité actif par défaut sur Debian et Ubuntu). Le moteur (dockerd, containerd, runc) et libvirt sont à côté : ils créent et gèrent, ils ne sont pas traversés. Un hyperviseur de type 1 comme ESXi ou Xen se place, lui, directement sur le matériel (cours Virtualisation). Suite : cours Docker, fondements de la conteneurisation.]
})

// ======================================================================
= Pour rappel

== Pour rappel · liste non exhaustive

#anime(
  rang(bloc(role: "retenir", taille: px(28))[L’essentiel du cours][
    - Émuler traduit les instructions ; virtualiser les exécute sur le vrai processeur, grâce à VT-x / AMD-V
    - Sous Linux : KVM exécute, QEMU fournit la machine, libvirt gère (virsh, virt-install, virt-manager)
    - Type 1 ou type 2 : une frontière floue ; la paravirtualisation (virtio) est une autre question
    - Une image téléchargée se vérifie : signature (authenticité), puis empreinte SHA-256 (intégrité)
    - Une VM est un processus de l’hôte ; avec `-cpu host`, elle peut à son tour lancer des VM
    - MicroVM et conteneurs isolent plus légèrement : machine minimale pour l’une, noyau partagé pour les autres
  ]),
  note: [Récapitulatif, une idée par clic, dans l’ordre du cours.],
)
