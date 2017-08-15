docker run -d \
--name=mistserver \
-v /etc/localtime:/etc/localtime:ro \
-v /home/$USER/mistserver/config:/config \
-v /home/$USER/mistserver/media:/media \
-p 4242:4242 \
-p 1935:1935 \
-p 554:554 \
-p 8080:8080 \
r0gger/mistserver
