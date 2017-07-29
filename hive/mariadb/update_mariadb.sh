docker run -d \
--net=host \
--restart=always \
--name mariadb \
-v /home/$USER/mariadb/data:/var/lib/mysql \
 -e 'MYSQL_ROOT_PASSWORD=password' \
 -e 'MARIADB_USER=hass' \
 -e 'MARIADB_PASS=password' \
 -e 'MARIADB_NAME=homeassistant' \
  mariadb:latest
## DB need to be added manually ##
