docker run  -d \
--name="garden-assistant" \
--restart always \
-v /home/$USER/garden-assistant/config:/config \
-v /etc/localtime:/etc/localtime:ro \
--net=host \
homeassistant/home-assistant
