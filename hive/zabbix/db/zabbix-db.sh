# zabbix-db

docker run \
    -d \
    --restart always \
    -v /home/$USER/zabbix/data:/var/lib/mysql \
    --name zabbix-db \
    --env="MARIADB_USER=zabbix" \
    --env="MARIADB_PASS=password" \
    monitoringartist/zabbix-db-mariadb
