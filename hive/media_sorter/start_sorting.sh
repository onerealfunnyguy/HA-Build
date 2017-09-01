docker run -d \
--name=sorttv \
--rm \
-v /home/$USER/media_sorter/sort:/root/sort \
-v /home/$USER/nas/transmission/downloads/complete:/root/done \
-v /home/$USER/nas/plex_media:/root/media \
-e TZ=America/Los_Angeles \
onerealfunnyguy/sorttv
