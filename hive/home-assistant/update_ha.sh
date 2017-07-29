docker run  -d \
--name="home-assistant" \
--restart always \
-v /home/$USER/home-assistant/config:/config \
-v /etc/localtime:/etc/localtime:ro \
--net=host \
homeassistant/home-assistant
