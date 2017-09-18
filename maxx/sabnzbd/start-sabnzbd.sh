docker run -d \
--name=sabnzbd \
-v /home/$USER/sabnzbd/config:/config \
-v /home/$USER/nas/presorted_media/downloads:/downloads \
-v /home/$USER/nas/presorted_media/watch:/watch \
-e PGID=1000 -e PUID=1000 \
-e TZ=America/Los_Angeles \
-p 8085:8080 \
-p 9092:9090 \
linuxserver/sabnzbd

#docker run -d \
#--name=sabnzbd \
#-v /home/$USER/sabnzbd/config:/config \
#-v /home/$USER/nas/presorted_media/downloads:/downloads \
#-v /home/$USER/nas/presorted_media/watch:/watch \
#-e PGID=1000 -e PUID=1000 \
#-e TZ=America/Los_Angeles \
#-p 8081:8080 \
#-p 9092:9090 \
#linuxserver/sabnzbd

#docker run -d \
#--name=sabnzbd \
#-v /home/$USER/sabnzbd/config:/config \
#-v /home/$USER/nas/presorted_media/downloads:/downloads \
#-v /home/$USER/nas/presorted_media/watch:/watch \
#-e PGID=1000 -e PUID=1000 \
#-e TZ=America/Los_Angeles \
#-p 8080:8080 -p 9092:9090 \
#linuxserver/sabnzbd

#docker run -d \
#--name=sabnzbd \
#-v /home/$USER/sabnzbd/config:/config \
#-v /home/$USER/nas/presorted_media/downloads:/downloads \
#-v /home/$USER/nas/presorted_media/watch:/watch \
#-e PGID=1000 -e PUID=1000 \
#-e TZ=America/Los_Angeles \
#-p 8080:8080 -p 9091:9090 \
#linuxserver/sabnzbd

#docker run -d \
#--name=sabnzbd \
#-v /home/$USER/sabnzbd/config:/config \
#-v /home/$USER/nas/transmission/downloads:/downloads \
#-v /home/$USER/nas/transmission/watch:/watch \
#-e PGID=1000 -e PUID=1000 \
#-e TZ=America/Los_Angeles \
#-p 8080:8080 -p 9091:9090 \
#linuxserver/sabnzbd
