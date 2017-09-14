docker stop $(docker ps -a | grep cast | awk "{print \$1}")
sleep  3
docker run  -d \
--rm \
--privileged \
--name="orfgcast" \
-v /home/$USER/stream2cast/s2c:/root/s2c \
--net=host \
onerealfunnyguy/stream2cast
