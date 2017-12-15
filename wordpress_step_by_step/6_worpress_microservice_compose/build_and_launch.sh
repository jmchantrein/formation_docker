#!/bin/bash

docker build apache_wordpress -t my_apache_wordpress_image
docker build mysql_wordpress -t my_mysql_image

docker container rm -f my_mysql_container 
docker container rm -f my_apache_wordpress_container

docker run -d --name my_mysql_container --hostname my_mysql_container -v data_wordpress:/var/lib/mysql my_mysql_image
docker run -d --name my_apache_wordpress_container --hostname my_apache_wordpress_container -p 80:80 -v src_wordpress:/var/www/html --link my_mysql_container:db my_apache_wordpress_image

echo "Lors de l'installation de wordpress, vous pourrez spécifier comme hôte pour votre base de donnée"
echo " * my_mysql_container"
echo " * db"
