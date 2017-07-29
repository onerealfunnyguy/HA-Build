docker run -d \
--restart=always \
-v /home/$USER/firetv/config:/config \
--name python-firetv \
-p 5556:5556 \
sytone/python-firetv -c /config/house.yaml
