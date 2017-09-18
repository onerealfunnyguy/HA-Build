# docker run -d \
# --name="Zoneminder-1.30" \
# --privileged=true \
# -v /home/$USER/nas/zoneminder/config:/config:rw \
# -v /etc/localtime:/etc/localtime:ro \
# -p 80:80 \
# magicalyak/docker-zoneminder
docker run -d \
--name="Zoneminder-1.29" \
--restart always \
--privileged=true \
-v /home/$USER/zoneminder/config:/config:rw \
-v /etc/localtime:/etc/localtime:ro \
-p 80:80 \
aptalca/zoneminder-1.29
