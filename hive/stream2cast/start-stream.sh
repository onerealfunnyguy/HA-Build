#! /bin/bash
cd home/$USER/stream2cast/stream2chromecast/ \
./stream2chromecast.py  \
-devicename 192.168.42.17 \
-transcoder avconv \
-transcode http://192.168.42.33:8080/video
