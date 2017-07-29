docker run \
-itd \
--name="mqtt" \
--restart always \
-p 1883:1883 \
-p 9001:9001 \
-v /home/$USER/mosquitto/config:/mosquitto/config \
-v /home/$USER/mosquitto/data:/mosquitto/data \
-v /home/$USER/mosquitto/log:/mosquitto/log \
eclipse-mosquitto
