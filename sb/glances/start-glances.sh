docker run -d \
--name="glances" \
--restart="always" \
--privileged \
-p 61208-61209:61208-61209 \
-e GLANCES_OPT="-w" \
-v /var/run/docker.sock:/var/run/docker.sock:ro \
--pid host \
docker.io/nicolargo/glances
