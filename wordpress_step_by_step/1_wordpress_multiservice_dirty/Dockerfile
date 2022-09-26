# Un dockerfile de développement
# Ce Dockerfile ne respecte pas les bonnes pratiques de rédaction d'un Dockerfile
# Ces bonnes pratiques seront abordées dans les prochaines étapes

FROM debian:latest

# Notez que l'on ne fait pas d'upgrade (voir bonnes pratiques Dockerfile)
RUN apt-get -yq update

# Installation des paquets
RUN DEBIAN_FRONTEND=noninteractive apt-get install -yq apache2 libapache2-mod-php libjs-cropper libjs-mediaelement libphp-phpmailer mariadb-server mariadb-client php-getid3 php php-gd php-mysql php-opcache php-readline

# Installation de nouveau paquet en utilisant le mécanisme de cache (évite de retélécharger les paquets ci-dessus, à ne faire que lors de la phase de développement d'un dockerfile)
RUN DEBIAN_FRONTEND=noninteractive apt-get -yq install vim wget unzip

# Téléchargement des sources
RUN cd /var/www/html && wget https://wordpress.org/latest.zip

RUN cd /var/www/html && unzip latest.zip

# Définitions des variables d'environnements
ENV MYSQL_PASSWORD=tempo \
	MYSQL_USER=admin \
	MYSQL_DB=wordpress

# Création du répertoire permettant la création d'un fichier de socket et attribution des bons droits
RUN mkdir /run/mysqld && \
    chown -R mysql:root /run/mysqld

# Configuration de la base de donnée
RUN /etc/init.d/mariadb start && mysql -u root --execute="CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD'"
RUN /etc/init.d/mariadb start && mysql -u root --execute="GRANT ALL PRIVILEGES ON *.* TO 'admin'@'%' WITH GRANT OPTION" && mysql -u root --execute="FLUSH PRIVILEGES"
RUN /etc/init.d/mariadb start && mysql --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --execute="CREATE DATABASE ${MYSQL_DB}" 

# Droits sur les sources
RUN chown -R www-data:www-data /var/www/html/wordpress

# Un lancement en mode interactif
#RUN echo "/etc/init.d/apache2 start && /etc/init.d/mariadb start && /bin/bash" > /run.sh

# Un lancement en mode détaché
RUN echo "/etc/init.d/apache2 start && /etc/init.d/mariadb start && sleep infinity" > /run.sh
RUN chmod u+x /run.sh

# On privilégie cette syntaxe de CMD (Exec form, sous forme de tableau json)
CMD ["/bin/bash","-c","/run.sh"]

# Pour information, voici l'autre syntaxe possible (Shell form)
# CMD /run.sh

# INSTRUCTIONS DE CONSTRUCTIONS
# docker build . -t mon_image_wordpress:v1
# docker run -it --name mon_conteneur_wordpress --rm -p 80:80 mon_image_wordpress:v1

