FROM debian:11

ENV VERSION=4

LABEL maintainer="Prénom Nom" \
	maintainer_email="prenom.nom@example.com" \
	version="${VERSION}"

# Installation des paquets
RUN apt-get -yq update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -yq \
	apache2 \
	libapache2-mod-php \
	libjs-cropper \
	libjs-mediaelement \
	libphp-phpmailer \
	mariadb-server \
	mariadb-client \
	php-getid3 \
	php \
	php-gd \
	php-mysql \
	php-opcache \
	php-readline \
	unzip \
	vim \
	wget && \
	rm -rf /var/lib/apt/lists/*

# Téléchargement, desarchivage et droits des sources de wordpress à la racine du serveur
RUN cd /tmp && \
	wget https://wordpress.org/latest.zip && \
	unzip latest.zip && \
	rm -rf /var/www/html/* && \
	mv wordpress/* /var/www/html/ && \
	chown -R www-data:www-data /var/www/html && \
	rm latest.zip

ENV MYSQL_PASSWORD=tempo \
	MYSQL_USER=admin \
	MYSQL_DB=wordpress

# Configuration de la base de donnée et de apache2 
# Ajout d'un Setuid sur apache2 qui a besoin d'être lancé en root lorsque on utilise le port standard 80
RUN /etc/init.d/mariadb start && \
        mysql -u root --execute="CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD'" && \
	mysql -u root --execute="GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION" && \
	mysql -u root --execute="FLUSH PRIVILEGES" && \
	mysql --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --execute="CREATE DATABASE ${MYSQL_DB}" && \
	echo "ServerName localhost" >> /etc/apache2/conf-available/servername.conf && \
	a2enconf servername && \
	chmod u+s /usr/sbin/apache2


# Changement des droits du script pour que l'utilisateur mysql puisse l'exécuter
# Nota bene: mysqld_safe peut être éxécuté par l'utilisateur mysql et non root (port > 1024)
RUN echo "#!/bin/bash \n /etc/init.d/apache2 start && mysqld_safe" > /run.sh && \
	chmod +x /run.sh

# Après cette instruction, tout les commandes seront effectuées en tant que utilisateur mysql
USER mysql

# Exposition explicite du port 80
# Notez que le serveur de base de donnée n'est pas exposé
EXPOSE 80

VOLUME ["/var/lib/mysql","/var/www/html"]

CMD ["/bin/bash","-c","/run.sh"]

# INSTRUCTIONS DE CONSTRUCTIONS
# docker build . -t mon_image_wordpress:v4
# docker volume ls
# docker run -it --name mon_conteneur_wordpress -p 80:80 mon_image_wordpress:v4 
# docker run -d --name mon_conteneur_wordpress -v data_wordpress:/var/lib/mysql -v src_wordpress:/var/wwww/html: --rm -p 80:80 mon_image_wordpress:v4
# docker volume ls
# docker container stop mon_conteneur_wordpress
# docker volume ls
# /!\ docker volume prune
# docker volume ls
# Attention: si le volume n'est pas nommé, il n'est pas persistant lors de l'utilisation de l'options --rm !

