#docker run -d --name="home-assistant" -v /home/shortbus/home-assistant:/config -v /etc/localtime:/etc/localtime:ro --net=host homeassistant/home-assistant
#docker run -d --name="home-assistant" -v /home/shortbus/home-assistant/config:/config -v /etc/localtime:/etc/localtime:ro --net=host homeassistant/home-assistant
docker run  -d --name="garden-assistant" --restart always -v /home/shortbus/garden-assistant/config:/config -v /etc/localtime:/etc/localtime:ro --net=host homeassistant/home-assistant
