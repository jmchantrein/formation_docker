FROM debian:11

ENV VERSION=1 

LABEL maintainer="Prénom Nom" \
	maintainer_email="prenom.nom@example.com" \
	version="${VERSION}"

# Installation des paquets
RUN apt-get -yq update && \
	DEBIAN_FRONTEND=noninteractive apt-get install -yq \
	mariadb-server && \
	rm -rf /var/lib/apt/lists/*

ENV MYSQL_PASSWORD="tempo" \
	MYSQL_USER="admin" \
	MYSQL_DATABASE_NAME="wordpress"

RUN /etc/init.d/mariadb start && \
	mysql -u root --execute="CREATE USER '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}'" && \
	mysql -u root --execute="GRANT ALL PRIVILEGES ON *.* TO '${MYSQL_USER}'@'%' WITH GRANT OPTION" && \
	mysql -u root --execute="FLUSH PRIVILEGES" && \
	mysql --user=${MYSQL_USER} --password=${MYSQL_PASSWORD} --execute="CREATE DATABASE ${MYSQL_DATABASE_NAME}" 

# Autoriser les connexions externe (via le port 3306)
RUN sed -i "s/bind-address/#bind-address/g" /etc/mysql/mariadb.conf.d/50-server.cnf 

# Après cette instruction, tout les commandes seront effectué en tant que utilisateur mysql
USER mysql

# On a maintenant besoin d'exposer le port 3306, mais uniquement dans le sous réseau
EXPOSE 3306

# docker build . -t my_mysql_image
# docker run -d --name my_mysql_container -v mysql_wordpress:/var/lib/mysql my_mysql_image

# L'utilisateur courant est mysql
CMD ["/usr/bin/mysqld_safe"]
