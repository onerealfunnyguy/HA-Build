#! /bin/bash
cd /root/s2c/stream2chromecast/
./stream2chromecast.py  \
-devicename 192.168.42.17 \
-transcoder avconv \
-transcode http://tilapiacam:8080/video
#-transcode http://catcam:8080/video
#-transcode http://192.168.42.33:8080/video
#cd stream2chromecast/ 
#./stream2chromecast.py  \
#-devicename 192.168.42.17 \
#-transcoder avconv \
#-transcode http://192.168.42.33:8080/video
