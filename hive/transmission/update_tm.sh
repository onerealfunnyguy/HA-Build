docker run -d --name=transmission \
--restart=always \
-v /home/$USER/transmission/config:/config \
-v /home/$USER/transmission/downloads:/downloads \
-v /home/$USER/transmission/watch:/watch \
-e PGID=1000 -e PUID=1000 \
-e TZ=America/Los_Angeles \
-p 9091:9091 -p 51413:51413 \
-p 51413:51413/udp \
linuxserver/transmission
