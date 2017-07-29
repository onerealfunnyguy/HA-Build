docker run -d \
--name plex \
--network=host \
--restart unless-stopped \
-e TZ="America/Los_Angeles" \
-e PLEX_CLAIM="YOUR CLAIM" \
-v /home/$USER/plex/config:/config \
-v /home/$USER/plex/transcode:/transcode \
-v /home/$USER/plex/data:/data \
plexinc/pms-docker:plexpass
