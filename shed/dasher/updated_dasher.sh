# dasher-docker load
docker run  -d \
--name="dasher" \
--restart always \
-v /home/$USER/dasher/config:/root/dasher/config \
-v /etc/localtime:/etc/localtime:ro \
--net=host \
clemenstyp/dasher-docker
