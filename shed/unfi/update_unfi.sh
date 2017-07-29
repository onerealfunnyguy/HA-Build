docker run -d \
  --name=unifi \
  --restart=always \
  -v /home/$USER/unfi/config:/config \
  -e PGID=1000 -e PUID=1000  \
  -p 161:161 \
  -p 8080:8080 \
  -p 8081:8081 \
  -p 8443:8443 \
  -p 8843:8843 \
  -p 8880:8880 \
  linuxserver/unifi
