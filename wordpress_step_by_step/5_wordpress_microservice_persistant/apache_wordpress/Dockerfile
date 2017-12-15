FROM ubuntu:16.04

ENV VERSION=1 

LABEL maintainer="Prénom Nom" \
	maintainer_email="prenom.nom@example.com" \
	version="${VERSION}"

RUN apt update && \
	DEBIAN_FRONTEND=noninteractive apt -yq install \
	apache2 \
	libapache2-mod-php7.0 \
	libjs-cropper \
	libjs-mediaelement \
	libphp-phpmailer \
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

# Téléchargement, desarchivage et droits des sources de wordpress à la racine du serveur
RUN cd /tmp && \
	wget https://wordpress.org/latest.zip && \
	unzip latest.zip && \
	rm -rf /var/www/html/* && \
	mv wordpress/* /var/www/html/ && \
	chown -R www-data:www-data /var/www/html && \
	rm latest.zip

# Une autre façon de lançer apache (en root) mais en limitant la surface d'attaque
ENV APACHE_RUN_USER www-data \
	APACHE_RUN_GROUP www-data \
	APACHE_LOG_DIR /var/log/apache2

# On sait que l'on va exposer le port 80
EXPOSE 80 

RUN chmod u+s /usr/sbin/apache2ctl && \
	chmod u+s /usr/sbin/apache2

USER www-data

CMD ["/usr/sbin/apache2ctl","-D","FOREGROUND"]

# INSTRUCTIONS DE CONSTRUCTIONS
# docker build . -t my_apache_wordpress_image
# docker run -d --name my_mysql_container --hostname my_mysql_container -v mysql_wordpress:/var/lib/mysql my_mysql_image <-- Il faut d'abord lancer le microservice mysql car notre microservice apache en dépend.
# docker run -d --name my_apache_wordpress_container --hostname my_apache_wordpress_container -p 80:80 -v my_src_wordpress:/var/www/html --link my_mysql_container:db my_apache_wordpress_image

