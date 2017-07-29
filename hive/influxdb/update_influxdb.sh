docker run -d \
--name="influxdb" \
-p 8086:8086 \
-p 8083:8083 \
-e INFLUXDB_ADMIN_ENABLED=true \
-v /home/$USER/influxdb/config:/var/lib/influxdb \
influxdb
