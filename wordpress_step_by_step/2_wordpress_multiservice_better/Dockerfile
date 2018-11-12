# Dockerfile avec les bonnes pratiques de rédaction pour une meilleur lisibilité et gestion du cache
# Ce dockerfile souffre toujours de quelques défauts, notamment la gestion des utilisateurs non root
# Nous verrons ce point lors de la prochaine étape

# De manière générale: 
# Sur le fond, on minimise le nombre d'instruction dans le Dockerfile (car 1 instruction => 1 image supplémentaire => 1 couche supplémentaire) mais on différencie les usages des instructions (i.e.: on ne mélange pas installation et configuration de paquet dans la même instruction RUN par exemple)
# Sur la forme, on passe à la ligne dès que possible pour améliorer la visibilité

# Il faut quasiment toujours utiliser un tag définit et non pas le tag par défaut latest
FROM ubuntu:16.04

# Versionner son Dockerfile
ENV VERSION=2 

# Ajouter des métadonnées à l'image
LABEL maintainer="Prénom Nom" \
	maintainer_email="prenom.nom@example.com" \
	version="${VERSION}"

# Un bloc d'installation en début de Dockerfile
# Package par ordre alphabétique, on préfére l'utilisation du package-version plutôt que package seul
# Par exemple: mariadb-server-10.0 plutôt que mariadb-server
# Suppresion du cache apt après l'installation des paquets (gain d'espace)
# Notez que l'on ne fait pas d'upgrade (voir bonnes pratiques Dockerfile)
RUN apt-get -yq update && \
	DEBIAN_FRONTEND=noninteractive apt install -yq \
	apache2 \
	libapache2-mod-php7.0 \
	libjs-cropper \
	libjs-mediaelement \
	libphp-phpmailer \
	mariadb-server-10.0 \
	mariadb-client-10.0 \
	php-getid3 \
	php7.0 \
	php7.0-gd \
	php7.0-mysql \
	php7.0-opcache \
	php7.0-readline \
	unzip \
	vim \
	wget && \
	rm -rf /var/lib/apt/lists/*

# Téléchargement, desarchivage et droits des sources en 1 seule instruction
# Site wordpress à la racine du serveur
RUN cd /tmp && \
	wget https://wordpress.org/latest.zip && \
	unzip latest.zip && \
	rm -rf /var/www/html/* && \
	mv wordpress/* /var/www/html/ && \
	chown -R www-data:www-data /var/www/html && \
	rm latest.zip

# Les variables d'environnement sont instanciées juste avant leurs usages afin d'utiliser le mécanisme de cache de docker build
# En effet, si ces variables étaient en début de fichier, vous reconstruiriez toutes les couches à chaque fois que vous changeriez le contenu des variables
ENV MYSQL_PASSWORD=tempo \
	MYSQL_USER=admin \
	MYSQL_DB=wordpress

# Configuration de la base de donnée et de apache2 en 1 seule instruction
RUN service mysql start && mysql -u root --execute="CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD'" && \
	service mysql start && mysql -u root --execute="GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION" && \
	mysql -u root --execute="FLUSH PRIVILEGES" && \
	service mysql start && mysql --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --execute="CREATE DATABASE ${MYSQL_DB}" && \
	echo "ServerName localhost" >> /etc/apache2/conf-available/servername.conf && \
	a2enconf servername

# Pour que le conteneur reste actif après son démarrage, il faut impérativement une tâche en foreground

# Pour une exécution en mode interractif
#RUN echo "service apache2 start && service mysql start && /bin/bash" > /run.sh

# Pour une exécution en mode détaché
RUN echo "#!/bin/bash \n service apache2 start && mysqld_safe" > /run.sh && \
	chmod u+x /run.sh

# On privilégie cette syntaxe de CMD (Exec form, sous forme de tableau json)
CMD ["/bin/bash","-c","/run.sh"]

# Pour information, voici l'autre syntaxe possible (Shell form)
# CMD /run.sh

# INSTRUCTIONS DE CONSTRUCTIONS
# docker build . -t mon_image_wordpress:v2
# docker run -it --name mon_conteneur_wordpress --rm -p 80:80 mon_image_wordpress:v2
