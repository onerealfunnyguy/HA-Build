docker run  -d \
--name="home-assistant" \
--restart always \
--privileged \
-v /home/$USER/home-assistant/config:/config \
-v /etc/localtime:/etc/localtime:ro \
-v /etc/letsencrypt:/etc/letsencrypt:ro \
--net=host \
homeassistant/home-assistant
