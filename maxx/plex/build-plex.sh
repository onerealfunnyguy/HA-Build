docker run -d \
--name plex \
--network=host \
--privileged \
--restart unless-stopped \
-e TZ="America/Los_Angeles" \
-e PLEX_CLAIM="snVtpzwNpc7ZzZgY19NP" \
-v /home/$USER/plex/config:/config \
-v /home/$USER/plex/transcode:/transcode \
-v /home/$USER/nas/plex_media:/data \
plexinc/pms-docker:plexpass
