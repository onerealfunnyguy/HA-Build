#! /bin/bash
./config/stream2chromecast/stream2chromecast.py  \
-devicename 192.168.42.17 \
-transcoder avconv \
-transcode http://fdcam:8080/video
