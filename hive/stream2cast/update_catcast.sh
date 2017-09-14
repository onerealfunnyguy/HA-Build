docker stop $(docker ps -a | grep cast | awk "{print \$1}")
sleep  3
docker run  -d \
--rm \
--privileged \
--name="catcast" \
-v /home/$USER/stream2cast/cats2c:/root/s2c \
--net=host \
onerealfunnyguy/stream2cast

#docker run  -d \
#--rm \
#--privileged \
#--name="doorcast" \
#-v /home/$USER/stream2cast/s2c:/root/s2c \
#--net=host \
#stream2cast
###fea7c1c475fb

#docker run  -d \
#--privileged \
#--name="doorcast" \
#-v /home/$USER/stream2cast/s2c:/root/s2c \
#--net=host \
#stream2cast
###fea7c1c475fb
