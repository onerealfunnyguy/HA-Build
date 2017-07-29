docker run -d \
--name="Zoneminder-1.29" \
--privileged=true \
-v /home/$USER/zoneminder/config:/config:rw \
-v /etc/localtime:/etc/localtime:ro \
-p 80:80 \
aptalca/zoneminder-1.29
