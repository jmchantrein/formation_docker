% Conteneurisation d'un service wordpress
% Jean-Mathieu Chantrein, IGE LERIA, Université d'Angers
% Novembre 2017

# Introduction

> Aux lecteurs avertis: la manière dont est traité notre première section ne correspond pas à une bonne méthode de travail. Cette section présente néanmoins l’avantage de bien comprendre certains mécanismes de docker et les différents usages possibles et problématiques rencontrées. Cette section nous permettra également de comprendre pourquoi, lorsque l’on utilise docker, il vaut mieux réaliser une architecture de microservice plutôt qu’une architecture monolithique.

> Tout d’abord, la section DOCKERFILE vise à nous emmener étape par étape vers l’utilisation de docker-compose. Nous installerons tout un service wordpress dans une seule image. Cela nous permettra de prendre en main la rédaction d’un Dockerfile. Nous nous interrogerons au fur et à mesure sur la mise en place de bonnes pratique à la rédaction de Dockerfile. Nous pointerons du doigt les problèmes qui sont engendrés lorsque plusieurs processus sont exécutés dans un seul conteneur et nous proposerons une architecture de micro service permettant de palier à ces problèmes. Cet aboutissement se fera étape par étape. **Il est tout à fait inutile de vouloir griller une étape, chaque étape supérieure repose sur la compréhension et la réalisation des étapes inférieures.**

> Ensuite, dans la section DOCKER-COMPOSE, nous verrons les méthodes de travail plus adapté et plus simple pour mettre en place un service docker en production sur un serveur. En l’occurrence, il s’agira toujours d’un service wordpress.

> Enfin, dans la section DOCKER-SWARM, nous verrons comment fonctionne docker-swarm de manière générale, nous présenterons brièvement les fonctionnalités de répartitions de charges et de mise à l’échelle et enfin nous orchestrerons notre architecture de micro-service wordpress dans un cluster de machine docker.

# DOCKERFILE: de dockerfile à dockercomposefile par l'exemple

## Etape 1: Création basique d'un Dockerfile

> Lors de la réalisation de cette étape, n’hésitez pas à user et à abuser de la notion de contexte que nous fournit docker build (notion de cache). Pour cela, pensez bien à rédiger les instructions les plus couteuses en début de dockerfile (i.e.: les couches les plus basses), et les instructions les plus souvent amenés à être changé en fin de Dockerfile (i.e: les couches les plus hautes). De cette manière, tout changement dans les couches hautes n’affectera pas les couches basses qui seront réutilisés par le cache de docker build. De plus, vous ne chercherez pas à minimiser le nombre d’image intermédiaire pour l’instant, nous le ferons lors de la prochaine étape.

Vous travaillerez dans un répertoire nommé 1_worpress_multiservice_dirty

Pensez à tester votre conteneur à l'adresse [http://localhost:80/wordpress](http://localhost:80/wordpress)

### Quelques contraintes:

 * L'image de base est l'image officiel ubuntu:16.04
 * Il est interdit d'installer le paquet wordpress
 * Il faut installer les paquets nécéssaires à l'utilisation de wordpress (on remplacera mysql-server par mariadb-server)
 * Il faut télécharger les [sources](https://wordpress.org/latest.zip) au format zip
 * Les sources seront placées dans le répertoire /var/www/html
 * Le mot de passe, le nom de l'administrateur mysql et le nom de la base de donnée doivent être définis dans des variables d'environnement (mot clef ENV en une seule instruction)
 * L'utilisateur mysql aura l'identifiant "admin", le mot de passe "tempo" et tous les droits sur une base "wordpress"
 * La commande par défaut doit exécuter apache et mysql
 * L'image sera taguée mon_image_wordpress et le conteneur exécuté sera nommé mon_conteneur_wordpress
 * La fin du fichier Dockerfile contiendra en commentaires les instructions de constructions et d'instanciation de l'image

### Quelques astuces, pistes de réflexions:

 * apt-get install -s ou apt install -s permet de simuler l'installation d'un paquet
 * apt depends permet de savoir quelles sont les dépendances d'un paquet
 * Contrairement à ce que l'on peut voir partout, y compris dans mon cours :-O , il ne faut pas déclarer une variable d'environnement DEBIAN_FRONTEND=noninteractive mais plutôt:
```bash
RUN DEBIAN_FRONTEND=noninteractive apt install package1 package2 ... 
```
[voir ticket github](https://github.com/moby/moby/issues/4032)

 * Si vous avez besoin de changer de chemin que pour une/des commande(s), n'utilisez pas le mot clef WORKDIR (cela ajouterai une image intermédiare inutile). Préférez l'utilisation de :

```bash
RUN cd /mon/chemin && mes_commandes
```

 * Création d'un utilisateur mysql "username" avec mot de passe "userpassword" ayant tous les droits et création d'une base "userbase":

```bash
mysql -u root --execute="CREATE USER 'username'@'%' IDENTIFIED BY 'userpassword'"
mysql -u root --execute="GRANT ALL PRIVILEGES ON *.* TO 'username'@'%' WITH GRANT OPTION"
mysql -u root --execute="FLUSH PRIVILEGES"
mysql --user=username --password=userpassword --execute="CREATE DATABASE userbase" 
```

 * N'oubliez pas que les instructions sont effectuées par l'utilisateur root par défaut. Cela pourrait poser des problèmes de droits par la suite. :-D
 * Vous allez exécuter un conteneur contenenant plusieurs services: je vous propose de lire cet <span style=color:blue> [article](https://docs.docker.com/engine/admin/multi-service_container/)</span>.
 * Lorsque vous allez exécuter votre conteneur, il va falloir que celui ci communique depuis son réseau (par défaut, le réseau bridge qui "NAT" le trafic des conteneurs vers l'extérieur) vers le réseau de l'hôte. Vous allez donc devoir mapper/associer un port de l'hôte avec un port du conteneur. Cela se fait via l'option -p de docker run. Par exemple, la commande suivante permet de mapper le port 8000 de l'hôte au port 80 du conteneur de l'image nginx:
 
```bash
docker run -p 8000:80 nginx
# Vous pourrez observer les logs ici lorsque vous vous connecterez à l'adresse http://localhost:8000
```

### Quelques questions, remarques 

 * Ici, vous exécutez plusieurs processus dans un conteneur. La philosophie de docker veut que l'on ne conteneurise que 1 processus. C'est un choix discutable, mais, si l'on souhaite vraiment utiliser plus d'un processus dans un conteneur en production, il faudrait alors se servir de [supervisord](http://supervisord.org/). Nous ne nous en servirons pas dans le cadre de ce cours.
 * Comment fait on pour lancer le conteneur en mode détaché (-d à la place de -it) ? Essayez les différentes commandes suivantes pour comprendre: 

> * On instancie maintenant un conteneur ubuntu en mode interactif et on exécute la commande /bin/bash
>
>```.bash
>jmc@laptop ~ $ docker run -it --rm --hostname test --name test ubuntu /bin/bash
>root@test:/# exit
>jmc@laptop ~ $ 
>```
> * On a le résultat attendu
> * On instancie un conteneur ubuntu en mode interactif et on exécute la commande /bin/bash -c "sleep infinity"
>
>```.bash
>jmc@laptop ~ $ docker run -it --rm --hostname test --name test ubuntu /bin/bash -c "sleep infinity"
>```
>  * On a le comportement attendu, le conteneur ne rend pas la main puisque la commande sleep infinity est en mode foreground
>  * Depuis un autre terminal, faire
>
>```.bash
>docker container rm -f test 
>```
> * On instancie un conteneur ubuntu en mode interactif et on exécute la commande /bin/bash -c "sleep infinity & ps -eflH"
>
>```.bash
>jmc@laptop ~ $ docker run -it --rm --hostname test --name test ubuntu /bin/bash -c "sleep infinity & ps -eflH"
>F S UID        PID  PPID  C PRI  NI ADDR SZ WCHAN  STIME TTY          TIME CMD
>4 S root         1     0  0  80   0 -  4507 wait   15:51 pts/0    00:00:00 /bin/
>0 S root         7     1  0  80   0 -  1096 hrtime 15:51 pts/0    00:00:00   sle
>0 R root         8     1  0  80   0 -  8607 -      15:51 pts/0    00:00:00   ps 
>jmc@laptop ~ $
>```
> * Le conteneur s'arrête alors même que l'on souhaiterait qu'il exécute la commande sleep infinity
> * Cela s'explique par le fait que la commande sleep infinity est exécuté en tâche de fond (utilisation de &)
> * Puis la commande ps -eflH s'exécute ...
> * ... et il n'y a plus de tâche en mode foreground.
> * Or les conteneurs sont conçus pour qu'il y ait une [tâche en mode foreground qui soit exécutée](https://docs.docker.com/engine/reference/run/#detached-vs-foreground)
> * Lorsque vous exécutez un conteneur en mode détaché (--detach -d), il n'y a pas d'interaction avec le conteneur: /bin/bash ne peut donc pas rester en mode foreground
>```.bash
>jmc@laptop ~ $ docker run -d --rm --hostname test --name test ubuntu /bin/bash
>6e15d2da91b77de6dea905f00b14877352d50e0fdd3e747e99147a923037e63d
>jmc@laptop ~ $ docker container ls -a
>CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
>```
> * /bin/bash n'ayant pas d'interaction, est passé en mode background, le conteneur test est devenu inactif et il a été supprimé puisque l'option --rm a été activé
> * Pour conserver le conteneur actif, il faut absolument une tâche en mode foreground dans le conteneur
> * Or c'est rarement le cas des démons de serveurs (apache2, mysql, nginx, ...) a qui on demande d'habitude de justement fonctionner en mode background !
> * De fait, il faut trouver les options nécessaires à l'utilisation de nos serveurs en mode foreground (par exemple: nginx -g 'daemon off;'
> * Quid lors de l'exécution de plusieurs serveurs dans un conteneur: il faut alors des serveurs en mode background et un serveur en mode foreground, ce qui n'est pas ni homogène, ni pratique. De plus, la commande docker logs, ne nous fournira que les logs du serveur en mode foreground et pas les logs des serveurs en mode background.
> * Dernier point: On peut obtenir de l'interaction avec un conteneur en mode détaché de la manière suivante
>```.bash
>jmc@laptop ~ $ docker run -d --rm --hostname test --name test ubuntu /bin/bash -c "sleep infinity"
>c08701adde66f6316399989fd37d83e71acec35e7564444f1afbdf675a76c08b
>jmc@laptop ~ $ docker container exec -it test /bin/bash
>root@test:/# exit
>jmc@laptop ~ $ docker container stop test
>```

 * Est-ce que l'on peut avoir une rédaction plus propre ? Quelles sont les bonnes pratiques de rédaction d'un Dockerfile ? C'est justement ce que nous allons voir dans la prochaine étape.


## Etape 2: Mise en place des bonnes pratiques

### Quelques contraintes

 * Copiez votre répertoire 1_worpress_multiservice_dirty en 2_wordpress_multiservice_better
 * Modifiez votre Dockerfile de manière à ce que celui-ci respecte les [bonnes pratiques](https://docs.docker.com/engine/userguide/eng-image/dockerfile_best-practices/)
 * Effectuez une construction sans cache du Dockerfile que vous avez modidié.
 * Vérifiez que votre service wordpress fonctionne correctement 

### Quelques astuces, pistes de réflexions

 * Dans l'instruction FROM : l'utilisation du tag latest peut-être utile si vous projetez un mécanisme de mise à jour automatique de votre image et des conteneurs qui en découlent. Cette option n'est raisonnable que si c'est vous qui êtes maître de la mise à jour de l'image en question.
 * Dans les autres cas, pour une image de production, on spécifiera toujours un tag explicite permettant de versionner l'image, ou mieux encore, la signature sha256 du descriptif de l'image. 

### Quelques questions, remarques
 * Quel utilisateur est à l'origine de l'exécution d' apache2, mysql et de la commande qui sera éxécuté au lancement du conteneur ?
    * Est-ce que c'est un problème pour apache2 ?
    * Est-ce que c'est un problème pour mysql ?
    * Est-ce que c'est un problème pour la commande qui sera exécuté au lancement du conteneur ?
        * De quelle commande s'agit-il ? 
        * En êtes-vous sûr ?
    * Si c'est un problème pour au moins l'un des trois processus, que proposez-vous ?

## Etape 3: Le problème de l'utilisateur root

Tout d'abord, un peu de [lecture](https://docs.docker.com/engine/security/security) sur la sécurité lorsque on utilise un environnement docker ou bien directement la [conclusion](https://docs.docker.com/engine/security/security/#conclusions)

### Quelques contraintes

 * Copiez votre répertoire 2_wordpress_multiservice_better en 3_wordpress_multiservice_noroot
 * Modifier votre Dockerfile de manière à ce que l'utilisateur dans le conteneur soit l'utilisateur mysql (et pas root)
 * Il faudra pour cela trouver un mécanisme pour exécuter le serveur apache2 avec l'utilisateur mysql

### Quelques astuces, pistes de reflexions

 * Connaissez-vous le mécanisme de [setuid](https://fr.wikipedia.org/wiki/Setuid)

### Quelques questions, remarques

 * Sachant que lorsque l'on exécute apache2 nativement sur un serveur, il est aussi exécuté en premier lieu par root. Doit-on strictement interdire un processus lancé par l'utilisateur root dans un conteneur ?
 * Dans notre cas, après modification du setuid, qui est l'utilisateur qui exécute apache ?


 * Ne pourrait-on pas plutôt faire une image lamp (Linux Apache Mysql Php) et monter le code source web (php,html,css,...) par un volume présent sur l'hôte ? Ne serait ce pas plus générique ?
En effet, notre image ne peut convenir que pour un site wordpress, alors que l'on devrait pouvoir faire une image capable de gérer n'importe quel site web php/html/css classique. On pourrait, mais ce ne serait pas forcément une meilleure méthode: ce serait juste une autre méthode. En fait, tout dépend des besoins que l'on a. Par exemple, est-ce que l'on doit fournir N instances de wordpress ou N instances de serveur LAMP ? En fonction de la réponse, on doit choisir l'architecture la plus adaptée à notre besoin.

 * Toutes vos données importantes sont dans le conteneur, quid de leurs pérennités ? Quelles solutions proposez-vous pour palier à cette problématique ?

## Etape 4: Pérennisation des données

### Quelques contraintes
 * Copiez votre répertoire 3_wordpress_multiservice_noroot en 4_wordpress_multiservice_persistant
 * Modifiez votre Dockerfile et/ou votre commande de lancement de conteneur, de manière à pouvoir faire persister les données présentent dans /var/lib/mysql et /var/www/html
 * Modifiez explicitement votre Dockerfile pour exposer le port 80 des futurs conteneurs

### Quelques astuces, pistes de réflexions

 * Nous utiliserons ici l'instruction VOLUME dans notre Dockerfile 

### Quelques questions, remarques

#### Méthode pour la pérennisation des données #

1. Nous avons trouvé une méthode pour pérenniser nos donnés dans un volume. Lorsque ce volume est dans l'arborescence su système de fichier de docker (docker a son propre [backend de storage (device-mapper, aufs, ou autres)](https://docs.docker.com/storage/storagedriver/select-storage-driver/), les données initialement contenues dans l'image sont copiées lors du premier lancement dans le volume. Ensuite les données sont ajoutées dans le volume.

2. Nous pourrions faire un point de montage de /var/lib/mysql dans notre propre système de fichier (par exemple: /data). Cependant, lors du premier montage, toutes les données contenues dans /var/lib/mysql de l'image sont inaccessibles, car le dossier /data monté est initialement vide. => Le conteneur serait inutilisable car mysql n'aurait même plus les informations concernant ses propres utilisateurs. On peut contourner ce problème en lançant un script au démarrage du conteneur, qui regarde si le point de montage /data est vide ou non. S' il est vide, on initialise mysql sinon on ne fait rien. L'initialisation se fait donc 1 seul fois lors du premier démarrage du conteneur et elle ne se fait pas dans l'image. Vous pouvez voir cet [exemple](http://txt.fliglio.com/2013/11/creating-a-mysql-docker-container/). Peut-être trouvez vous cela bien compliqué et contraignant ? Cependant, un énorme avantage de cette méthode, en plus de localiser ses données ou on le souhaite, c'est la possibilité de passer ses propres variables d'environnement à l'instanciation du conteneur: par exemple, on choisit quel est le mot de passe utilisateur au lancement du conteneur et non de manière figée dans l'image. Cette méthode nous apporte donc beaucoup plus de souplesse dans la gestion de nos conteneurs. On ne mettra pas en œuvre cette méthode dans cette partie. Mais garder à l'esprit que ce type de mécanisme peut-être inclus dans des images dont vous pourriez vous servir. Ce sera d'ailleurs le cas du micro-service officiel mysql dont nous nous servirons dans la prochaine partie.

On pourrait remarquer aussi que la mise en place d'une telle complexité ne peut-être envisageable que pour une instanciation massive de conteneur wordpress et non pas pour quelques instances. C'est vrai, mais gardez à l'esprit que nous sommes dans le cadre d'un tp de compréhension des mécanismes de docker: les images officielles implémentent elles mêmes ce type de mécanisme, et de manière bien plus efficace que ce que nous faisons ici. Ainsi, un micro-service devrait pouvoir être déployé tout aussi bien sporadiquement que massivement.

3. Une autre alternative consisterait à faire un point de montage adhoc. On monte un répertoire /backup de l'hôte sur un repertoire /backup dans le conteneur. Un cron sur l'hôte réalise régulièrement des dump de la base de donnée via une commande du style:

```bash
docker exec -it my_wordpress_container mysqldump --all-databases > /backup/$(date)_dump.sql
```

Notez que le cron se ferait sur l'hôte, et pas dans le conteneur: minimisation du nombre de processus dans le conteneur.

4. Nous pourrions aussi pérenniser les sources (/var/www/html) avec un montage sur l'hôte. Dans le cas d'un montage hors du système de fichiers de docker, confère notre solution numéro 2, cela nécessiterait l'écriture d'un bootstrap sur lequel on mettrait un bit setuid, le bootstrap modifierai le propriétaire du répertoire monté par www-data:www-data avec chown, il faut dont être root pour cette exécution (d'où l'usage du setuid). 

##### Conclusion
La méthode 1 est la plus facile à mettre en œuvre. C'est la méthode officielle recommandé par docker, mais elle nous ôtes la liberté de choisir ou nous stockons nos données. La méthode 2 est la plus difficile à mettre en œuvre mais offre plus de souplesse dans la gestion de nos services, cependant, contrairement à la méthode 1, nous ne pouvons pas gérer les données via le CLI de docker (docker volume cmd). Les méthodes 3 et 4 sont, à mon avis, à proscrire. Vous trouverez plus d'informations sur la méthode 1 [ici](https://docs.docker.com/engine/admin/volumes/volumes/) et sur la méthode 2 [ici](https://docs.docker.com/storage/bind-mounts/)

Attention: Lorsque vous utilisez la méthode 1, faîtes très attention à [nommé vos volumes](https://docs.docker.com/storage/volumes/#remove-volumes). En effet, les volumes anonymes sont supprimés à la suppression du conteneur ou lors de l'utilisation de la commande docker volume prune.

N.B.: Si vous devez gérer des données temporaires, il vaut mieux utiliser la directive [--tmpfs](https://docs.docker.com/storage/tmpfs/) plutôt que d'utiliser la couche en écriture de votre conteneur.

## Etape 5: Vers une architecture de micro-services

### Quelques contraintes
 * Copiez votre répertoire 4_wordpress_multiservice_persistant en 5_wordpress_microservice_persistant
 * Créez 2 sous répertoires apache_wordpress et mysql_wordpress
 * À partir de votre Dockerfile initiale, créez 2 nouveaux Dockerfile dans chacun des nouveaux sous répertoires
 * Rédigez vos 2 nouveaux Dockerfile de manière à obtenir 2 microservices: un microservice apache, qui contiendra les sources wordpress et un microservice mysql qui gérera la base de donnée qui doit toujours être persistante
 * Rédigez un script bash "build_and_launch.sh" qui exécute les commandes nécessaires à la création et à l'exécution des 2 microservices
 * Vérifiez que votre service wordpress (composé de 2 microservices) fonctionne bien.
 
### Quelques astuces, pistes de réflexions
 * Bien que déprécié, vous utiliserez ici l'options historique --link pour lier vos 2 conteneurs
 * Avec les nouvelles fonctionnalités du réseau docker, il nous  faudrait plutôt créer notre propre réseau pour notre service. Et cela nous montre qu'il est tout à fait possible d'avoir un réseau dédié pour chaque service ! Plus d'informations [ici (link)](https://docs.docker.com/engine/userguide/networking/default_network/dockerlinks/) et [ici (network](https://docs.docker.com/engine/tutorials/networkingcontainers/)

### Quelques questions, remarques
 * En production, on évitera l'usage de l'option --link qui est certainement voué à disparaitre
 * Notez que l'on a pas exposé le port du conteneur mysql à l'extérieur, seul le conteneur apache y a accès
 * Nous sommes en présence d'une architecture de 2 microservices, que pensez-vous du mécanisme de script build_and_launch ?
 * Et si nous étions en présence d'une architecture de 25 microservices, que penseriez-vous du mécanisme de script build_and_launch ?
 * Docker va plus loin que la simple rédaction de Dockerfile, Docker nous permet aussi de gérer la façon dont interagissent les conteneurs entre eux. Pour cela Docker met à notre disposition l'outil docker-compose. C'est l'objet de notre prochaine partie.


# DOCKER-COMPOSE, ou l'art d'orchestrer nos conteneurs sur une seule machine

> Installation de docker-compose:
> ```bash
> sudo curl -L https://github.com/docker/compose/releases/download/1.17.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
> sudo chmod +x /usr/local/bin/docker-compose
> ```

## Etape 6: Une architecture de micro-services décrite dans un docker-compose file

### Quelques contraintes
 * Lisez la documentation présentant un [aperçu des fonctionnalités de docker-compose](https://docs.docker.com/compose/overview/)
 * Copiez votre répertoire 5_wordpress_microservice_persistant en 6_wordpress_microservice_compose
 * Remplacer votre script "build_and_launch.sh" par un fichier docker-compose en version 3 qui vous permette d'avoir une configuration équivalente au script
 * Il y aura un service (microservice) nommé apache_wordpress et un service (microservice) mysql_wordpress 
 * Vérifiez que votre service fonctionne correctement
 
### Quelques questions, remarques
 * Listez les réseaux avec docker network ls. Que constatez-vous ?
 * Essayons d'enlever l'option link.  Pourquoi cela fonctionne-t-il ?
 * Avez-vous remarqué que lors de l'installation de wordpress, vous pouviez adresser le nom du service de la base de donnée à la place du hostname ? Comment est ce possible ? Allez regarder du côté de la commande docker container inspect nom_du_conteneur_mysql
 * Observez bien tout les [paramètres](https://docs.docker.com/compose/compose-file/) que vous pouvez fixer pour vos conteneurs dans le fichier docker-compose, parmit les plus intéressant:
restart_policy, update_config, depends_on, restart, dns, ... Parmi ces options, deux retiennent mon attention, il s'agit de deploy et d' overlay qui ne fonctionne que avec l'usage de docker swarm, nous verrons ces deux commande plus tard dans la partie docker swarm.

Vous êtes arrivé au bout de votre chemin d'apprentissage des fondamentaux de docker. Ce fût peut-être long et difficile. Il est maintenant temps pour vous de savoir que tout ce que nous avons fait là à la main, d'autres personnes l'ont déjà fait, en beaucoup mieux, et pour notre usage. Nous allons donc maintenant nous servir de leurs travaux, mais, nous savons maintenant quels sont les mécanismes qui seront employés par les images officielles dont nous allons nous servir (variables d'environnement, fichier de bootstrap, setuid, volume). Il n'y a plus aucune ombre de magie dans docker, nous savons désormais globalement comment tout cela s'articule.


## Etape 7: Une architecture de micro-services décrite dans un docker-compose file fournit par la communauté

### Quelques contraintes
 * Créer un répertoire nommez 7_wordpress_official_stack
 * Créer un fichier stack_wordpress.yml avec ce contenu:

```yaml
version: '3.1'

services:

        wordpress:
                image: wordpress
                restart: always
                ports:
                        - 8080:80
                environment:
                        WORDPRESS_DB_PASSWORD: example

        mysql:
                image: mysql:5.7
                restart: always
                environment:
                        MYSQL_ROOT_PASSWORD: example
```

 * Exécutez le service, observez les logs, testez le service.


### Quelques questions, remarques
 * Vous n'avez pas eu à rédiger le moindre Dockerfile
 * Par défaut, vous n'avez aucune persistance de donnée, notre prochaine étape consistera à voir si l'on peut effectuer cette persistance sur un répertoire dans notre home (et non pas les volumes par défaut de docker)

## Etape 8: Une architecture de micro-services décrite dans un docker-compose file fournit par la communauté et que vous allez adapter à votre besoin

### Quelques contraintes
 * Copiez le répertoire  7_wordpress_official_stack en 8_my_final_wordpress
 * Assurez-vous d'avoir la persistance de la base de donnée
 * Vérifiez que votre service fonctionne correctement
   * Modifiez la localisation de la persistance de la base de donnée en plaçant celle-ci dans /home/$USER/data_wordpress
   * Profitez en pour effectuer la persistance du code source de /var/www/html dans /home/$USER/source_code_wordpress
   * Effectuez la mise à jour de wordpress via l'interface d'administration
   * Supprimez le service
   * Reconstruisez le même service
   * Regardez la version de wordpress


### Quelques questions, remarques
 * Vous n'avez toujours pas eu à rédiger le moindre Dockerfile
 * Combien de temps cela vous a-t-il prit ?
 * Si vous aviez eu à rédiger un Dockerfile, celui ne comporterait que d'infimes modifications, car vous partiriez de l'image de base officielle
 * La persistance de la base de donnée et du code source est très bien géré par l'image officielle alors même qu'il vous aurait été très compliqué de la réaliser vous-même de cette façon ! 

#### Conclusions
C'est fini ! Vous pouvez vous arrêter là. Toutefois:
 * Si vous êtes administrateur systèmes et/ou réseaux alors la prochaine et dernière partie devrait aussi vous intéresser. 
 * Si vous êtes développeur, vous avez tout ce dont vous avez besoin pour fournir une application et ses dépendances à n'importe qui sachant écrire "docker-compose up" dans un terminal.
 * Si vous êtes chercheur, vous avez ici un mécanisme qui permet d'inscrire vos travaux dans une démarche de recherche reproductible: vous voulez tester mon algorithme révolutionnaire ? Bien sûr, faites "docker run super-chercheur/super-algo". Et voilà ! 

Nous n'avons pas fait mention ici de la possibilité et de l'efficacité de docker en ce qui concerne les techniques d'intégration continue et d'usine logicielle. Docker n'est pas en mesure de fournir à lui tout seul cette fonctionnalité. Pour des tests simples, sachez simplement que l'on peut déjà faire des merveilles avec un gitlab et un repository github. Cerise sur le gâteaux, vous pouvez vous servir des images officielles de ces services pour mettre en œuvre vos tests.

Pour aller plus loin, je vous conseille de suivre les cours officiels de docker sur l'excellent site [training.playwithdocker.com](http://training.play-with-docker.com/). Que vous soyez administrateur système ou bien développeur, vous y trouverez votre compte et un excellent complément à ce que nous venons de faire ici.

# DOCKER-SWARM, ou l'art d'orchestrer nos conteneurs sur un cluster de machine docker

> Il vous faut un [compte docker](https://cloud.docker.com/) pour pouvoir réaliser cette partie.

## Introduction

Docker swarm est un orchestrateur. C'est un outil permettant de gérer vos images, conteneurs, réseaux virtuels sur un ensemble de machine utilisant le docker (cluster ou grappe). Voici les principales fonctionnalités de docker swarm:

 * Gestion d'un cluster de démons docker
 * Décentralisation d'exécution (un conteneur a sur une machine A peut communiquer avec un conteneur b sur une machine B)
 * Utilisation d'un fichier au format dockercompose pour le déploiement (modèle déclaratif)
 * Passage à l'échelle: pour chaque service, vous pouvez déclarer le nombre de conteneurs que vous souhaitez exécuter. Lorsque vous augmentez ou réduisez ce nombre de conteneurs, docker swarm s'adapte automatiquement en ajoutant ou en supprimant des conteneurs pour maintenir l'état souhaité. Cela nécéssite toutefois d'avoir pensé une architecture de micro-service pour son service.
 * Adaptation de l'état général du cluster: si un des nœuds du cluster tombe, swarm redéploie automatiquement les conteneurs perdus sur les nœuds restants et actifs.
 * Réseaux virtuels partagés entre plusieurs machines (overlay network)
 * Équilibrage de charge: chaque service de l'essaim a un nom DNS unique et docker swarm répartit la charge entre les conteneurs en cours d'exécution. Vous pouvez interroger chaque conteneur qui s'exécute dans le cluster via un serveur DNS intégré. Vous pouvez aussi exposer les ports pour les services à un équilibreur de charge externe. Mais en interne, docker-swarm permet de spécifier comment distribuer les conteneurs d'un service entre les noeuds du cluster
 * Communication entre les nœuds sécurisé par défaut via TLS.
 * Mise à jour en cours d'exécution et retour arrière: lorsque vous devez faire une mise à jour d'un service, vous pouvez appliquer ces mises à jour de service aux nœuds de manière incrémentielle. Si quelque chose ne va pas, vous pouvez restaurer un service vers une version précédente.

> Dans swarm, nous allons introduire un nouveau terme, la pile (stack). La pile correspond à ce que nous appelons le service dans sa globalité (dans notre précédent exemple, on parlerai de pile wordpress), le service correspond à ce que nous appelions le micro-service, les conteneurs quant à eux sont appelés des tâches (task). Un microservice répliquer n fois correspond à l'instanciation de n conteneurs.

> Il existe un concurrent très sérieux à swarm: il s'agit de l'orchestrateur [kubernetes](https://kubernetes.io/). Celui-ci est plus mature, plus stable et offre plus de fonctionnalités que docker-swarm. En outre, il a été adopté massivement par le monde de l'industrie. Docker swarm présente l'avantage d'être plus facile à prendre en main, mais les fonctionnalités présenté ici sont également présentes dans kubernetes. 

## Gestion native du load balancing d'un service

 * Rendez-vous sur le site [play-with-docker](https://labs.play-with-docker.com)
 * Ajoutez 3 instances: ces 3 instances correspondent à 3 serveurs alpine dans lesquels docker est installé.
 * Nous allons maintenant créer un cluster de serveur docker (swarm ou essaim)

```.bash
docker swarm init --advertise-addr $(hostname -i)
```

 * Avec la sortie de la commande ci-dessus, copiez la commande join (* attention aux retours à la ligne *) et collez-la dans les terminaux des 2 autres instances.
 * Voila notre cluster de serveur docker réalisé ! Vous doutez ? Placez-vous dans votre première instance (manager) et faites la commande suivante:

```.bash
docker node ls
```
 * node 2 et 3 sont considéré comme des travailleurs (worker). La commande ci-dessus ne fonctionne pas sur des workers.
 * Placez-vous dans la première instance
 * Effectuez la commande suivante

```bash
for ((i=1;i<10;i++)); do docker service create --name service_${i} --replicas 1 alpine ping localhost; done
```

 * Observons maintenant où sont exécutés ces différents services:

```bash
for ((i=1;i<10;i++)); do docker service ps service_${i}; done
```

 * Voilà !

## Une introduction à docker-swarm

La partie ci-dessous est une introduction à docker swarm présente sous forme de cours sur le dépot github [play-with-docker](https://github.com/play-with-docker/play-with-docker.github.io/blob/master/_posts/2017-01-28-swarm-stack-intro.markdown). Ce cours étant sous licence [apache2](https://github.com/play-with-docker/play-with-docker.github.io/blob/master/LICENSE) et afin de ne pas réinventer la roue, je présente ici une traduction du cours original. Pour mettre en application ce cours, le plus simple est soit d'utiliser la version officiel et en anglais en [ligne](http://training.play-with-docker.com/swarm-stack-intro/), soit de suivre cette version en utilisant le site [play-with-docker](https://labs.play-with-docker.com). 


## Objectif

Déployer une pile (stack) d'une application de vote (voting app) avec docker swarm
Le but de ce TP est d'illustrer comment déployer une pile (application multi (micro) services) avec swarm et à partir d'un fichier docker-compose.

## L'application

L'application de vote est une application multi-conteneurs très pratique, souvent utilisée à des fins de démonstration au cours de meetup et de conférences.

Elle permet essentiellement aux utilisateurs de voter entre chat et chien (mais cela pourrait aussi être "espace" ou "tabulation" si vous en avez envie).

Cette application est disponible sur Github et mise à jour très fréquemment lorsque de nouvelles fonctionnalités sont développées.

## Initialisation de docker swarm

Tout d'abord, nous allons créer un cluster de docker (docker swarm aussi appelé essaim)

```.bash
docker swarm init --advertise-addr $(hostname -i)
```

Depuis la sortie ci-dessus, copiez la commande join (* attention aux retours à la ligne *) et collez-la dans le terminal d'une autre instance.

## Montrer les membres de l'essaim

À partir du premier terminal, vérifiez le nombre de nœuds dans l'essaim (l'exécution de cette commande à partir du deuxième terminal (worker) échouera, car des commandes liées à l'essaim doivent être émises par un gestionnaire d'essaim (manager)).

```.bash
docker node ls
```

La commande ci-dessus devrait lister 2 nœuds, le premier étant le gestionnaire (manager), et le second un ouvrier (worker).

## Cloner l'application de vote

Récupérons le code de l'application de vote de Github et allons dans le dossier de l'application.

Assurez-vous que vous êtes dans le premier terminal et faites ce qui suit:

```.bash
git clone https://github.com/docker/example-voting-app
cd example-voting-app
```

## Déployer une pile

Une pile est un groupe de (micro) services déployés ensemble.
Le fichier docker-stack.yml du dossier actuel sera utilisé pour déployer l'application de vote (le service) en tant que pile.
(NdT: Prenez le temp de lire les instructions de ce fichier.)

Assurez-vous que vous êtes dans le premier terminal et faites ce qui suit:

```.bash
docker stack deploy --compose-file=docker-stack.yml voting_stack
```

Note: être capable de déployer une pile à partir d'un fichier docker-compose est une fonctionnalité intéressante ajoutée dans Docker 1.13.

Vérifiez la pile déployée depuis le premier terminal

```.bash
docker stack ls
```

La sortie devrait être la suivante. Elle indique que les 6 services de la pile de l'application de vote (appelée voting_stack) ont été déployés.

```
NAME          SERVICES
voting_stack  6
```

Vérifions le service dans la pile

```.bash
docker stack services voting_stack
```

La sortie devrait être similaire à celle-ci: (modulo l'ID bien sûr).

```
ID            NAME                     MODE        REPLICAS  IMAGE
10rt1wczotze  voting_stack_visualizer  replicated  1/1       dockersamples/visualizer:stable
8lqj31k3q5ek  voting_stack_redis       replicated  2/2       redis:alpine
nhb4igkkyg4y  voting_stack_result      replicated  2/2       dockersamples/examplevotingapp_result:before
nv8d2z2qhlx4  voting_stack_db          replicated  1/1       postgres:9.4
ou47zdyf6cd0  voting_stack_vote        replicated  2/2       dockersamples/examplevotingapp_vote:before
rpnxwmoipagq  voting_stack_worker      replicated  1/1       dockersamples/examplevotingapp_worker:latest
```

Listez les tâches (conteneurs)(NdT: et donc les microservices) du service de vote.

```.bash
docker service ps voting_stack_vote
```

Vous devriez obtenir une sortie similaire à celle ci-dessous où les 2 tâches (réplicas) du service sont listées.

```
ID            NAME                 IMAGE 				       NODE   DESIRED 	     STATE   CURRENT STATE           ERROR  PORTS
my7jqgze7pgg  voting_stack_vote.1  dockersamples/examplevotingapp_vote:before  node1  Running        Running 56 seconds ago
3jzgk39dyr6d  voting_stack_vote.2  dockersamples/examplevotingapp_vote:before  node2  Running        Running 58 seconds ago
```

Dans la colonne NODE, nous pouvons voir qu'une tâche est en cours d'exécution sur chaque noeud.

(NdT: vous devriez pouvoir vérifier que votre service est actif en cliquant sur le lien indiquant le port ouvert (8080 normalement) en début de page.)

## Conclusion

L'utilisation de seulement quelques commandes permet de déployer une pile de services sur un Docker Swarm en utilisant le très bon format de fichier Docker Compose.

## Bonus du traducteur: mise à l'échelle et mise à jour

Une fonctionnalité très intéressante est le passage à l'échelle de notre application. Imaginons que tout d'un coup le flux de visiteur deviennent très important pour notre application de vote, alors nous pouvons faire:

```.bash
docker service scale voting_stack_vote=6
# Observons ce qu'il se passe
docker service ps voting_stack_vote
ID                  NAME                  IMAGE                                        NODE                DESIRED STATE       CURRENT STATE            ERROR               PORTS
zjg727lj1t6j        voting_stack_vote.1   dockersamples/examplevotingapp_vote:before   node1               Running             Running 6 minutes ago
pwf7797wj68h        voting_stack_vote.2   dockersamples/examplevotingapp_vote:before   node2               Running             Running 6 minutes ago
s7ns1nk6fz2d        voting_stack_vote.3   dockersamples/examplevotingapp_vote:before   node2               Running             Running 43 seconds ago
iw5yja1o5s27        voting_stack_vote.4   dockersamples/examplevotingapp_vote:before   node1               Running             Running 43 seconds ago
gf2bb9vl60mv        voting_stack_vote.5   dockersamples/examplevotingapp_vote:before   node2               Running             Running 42 seconds ago
9csix895fldt        voting_stack_vote.6   dockersamples/examplevotingapp_vote:before   node1               Running             Running 43 seconds ago

```

> Notez que s'il y avait eu plus de nœuds, la charge se serait automatiquement répartie sur l'ensemble des nœuds.

Imaginons maintenant que le flux de visiteur baisse:

```.bash
docker service scale voting_stack_vote=3
# Observons ce qu'il se passe
docker service ps voting_stack_vote
ID                  NAME                  IMAGE                                        NODE                DESIRED STATE       CURRENT STATE            ERROR               PORTS
iw5yja1o5s27        voting_stack_vote.4   dockersamples/examplevotingapp_vote:before   node1               Running             Running 54 seconds ago
gf2bb9vl60mv        voting_stack_vote.5   dockersamples/examplevotingapp_vote:before   node2               Running             Running 53 seconds ago
9csix895fldt        voting_stack_vote.6   dockersamples/examplevotingapp_vote:before   node1               Running             Running 54 seconds ago
```

Vous pouvez modifier le nombre de réplica en mettant à jour votre (micro) service:

```.bash
docker service update --replicas 2 voting_stack_vote
# Si jamais vous souhaitez revenir en arrière
docker service rollback voting_stack_vote
```
En fonction de qui a été définis dans le fichier docker-compose et des éventuelles mise à jour disponible, vous pouvez  mettre à jour la pile (le service dans sa globalité) de cette manière:

```.bash
docker stack deploy --compose-file docker-stack.yml

```

Vous pourriez essayer en modifiant le mapping du port 5000 en 6000 si vous souhaitez voir un changement. Avec la commande:

```.bash
docker service ps voting_stack_vote
ID                  NAME                      IMAGE                                        NODE                DESIRED STATE       CURRENT STATEERROR               PORTS
xb0xbq451yh5        voting_stack_vote.4       dockersamples/examplevotingapp_vote:before   node2               Running             Running 2 seconds ago
5szo5dbt4zeu         \_ voting_stack_vote.4   dockersamples/examplevotingapp_vote:before   node1               Shutdown            Shutdown 4 seconds ago
tdicx6w98ugk        voting_stack_vote.8       dockersamples/examplevotingapp_vote:before   node1               Running             Running 2 seconds ago
e7l8luq3zfoc         \_ voting_stack_vote.8   dockersamples/examplevotingapp_vote:before   node2               Shutdown            Shutdown 4 seconds ago
```

On remarque qu'il y a eu une interruption de ce micro-service pendant 2 secondes et qu'il y a des reliquats. Ces reliquats peuvent permettre de revenir en arrière en cas de problème.
L'interruption de service peut-être évité en utilisant le mot clé delay dans le fichier docker-compose qui spécifie un délay entre les mises à jour de chaque conteneur: cela signifie que l'espace d'un instant, il y a aura 2 versions différentes du même microservice en ligne. Vous trouverez plus d'informations [ici](https://docs.docker.com/engine/swarm/swarm-tutorial/rolling-update/)


## Etape 9: Une architecture de micro-services wordpress déployé dans un cluster swarm

### Quelques contraintes
 * Copiez le répertoire  8_my_final_wordpress dans une instance [play-with-docker](http://playwithdocker.com)
 * Déployez  votre architecture de micro-service avec docker stack
 * Effectuez une mise à l'échelle de votre micro-service apache (2 replicas)
 * Vérifiez que votre service fonctionne correctement

### Quelques questions, remarques
 * Observez bien votre instance play-with-docker. Avez vous remarquez que c'était un conteneur docker ? ;-)
 * [dind](https://sreeninet.wordpress.com/2016/12/23/docker-in-docker-and-play-with-docker/)
