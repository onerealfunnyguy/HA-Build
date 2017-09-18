docker run -d \
--name sonarr \
-e PUID=1000 \
-e PGID=1000 \
-e TZ="America/Los_Angeles" \
-v /home/$USER/sonarr/config:/config \
-v /home/$USER/nas/plex_media/TV_Shows:/tv \
-v /home/$USER/nas/presorted_media/watch:/downloads \
-p 8989:8989 \
linuxserver/sonarr

#docker run -d \
#--name sonarr \
#-e PUID=1000 \
#-e PGID=1000 \
#-e TZ="America/Los_Angeles" \
#-v /home/$USER/sonarr/config:/config \
#-v /home/$USER/nas/plex_media/TV_Shows:/tv \
#-v /home/$USED/nas/transmission/watch:/downloads \
#-p 8989:8989 \
#linuxserver/sonarr
