# Un dockerfile de développement
# Ce Dockerfile ne respecte pas les bonnes pratiques de rédaction d'un Dockerfile
# Ces bonnes pratiques seront abordées dans les prochaines étapes

FROM ubuntu:16.04

# Notez que l'on ne fait pas d'upgrade (voir bonnes pratiques Dockerfile)
RUN apt-get -yq update

# Installation des paquets
RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq apache2 libapache2-mod-php7.0 libjs-cropper libjs-mediaelement libphp-phpmailer mariadb-server-10.0 mariadb-client-10.0 php-getid3 php7.0 php7.0-gd php7.0-mysql php7.0-opcache php7.0-readline

# Installation de nouveau paquet en utilisant le mécanisme de cache (évite de retélécharger les paquets ci-dessus, à ne faire que lors de la phase de développement d'un dockerfile)
RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install vim wget unzip

# Téléchargement des sources
RUN cd /var/www/html && wget https://wordpress.org/latest.zip

RUN cd /var/www/html && unzip latest.zip

# Définitions des variables d'environnements
ENV MYSQL_PASSWORD=tempo \
	MYSQL_USER=admin \
	MYSQL_DB=wordpress

# Configuration de la base de donnée
RUN service mysql start && mysql -u root --execute="CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD'"
RUN service mysql start && mysql -u root --execute="GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION" && mysql -u root --execute="FLUSH PRIVILEGES"
RUN service mysql start && mysql --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --execute="CREATE DATABASE ${MYSQL_DB}" 

# Droits sur les sources
RUN chown -R www-data:www-data /var/www/html/wordpress

# Un lancement en mode interactif
#RUN echo "service apache2 start && service mysql start && /bin/bash" > /run.sh

# Un lancement en mode détaché
RUN echo "service apache2 start && service mysql start && sleep infinity" > /run.sh
RUN chmod u+x /run.sh

# On privilégie cette syntaxe de CMD (Exec form, sous forme de tableau json)
CMD ["/bin/bash","-c","/run.sh"]

# Pour information, voici l'autre syntaxe possible (Shell form)
# CMD /run.sh

# INSTRUCTIONS DE CONSTRUCTIONS
# docker build . -t mon_image_wordpress:v1
# docker run -it --name mon_conteneur_wordpress --rm -p 80:80 mon_image_wordpress:v1

