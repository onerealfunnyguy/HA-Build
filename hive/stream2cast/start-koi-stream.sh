#! /bin/bash
./stream2chromecast/stream2chromecast.py  \
-devicename 192.168.42.17 \
-transcoder avconv \
-transcode http://koicam:8080/video
