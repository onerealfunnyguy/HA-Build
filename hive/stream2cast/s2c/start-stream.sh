#! /bin/bash
cd /root/s2c/stream2chromecast/
./stream2chromecast.py  \
-devicename 192.168.42.17 \
-transcoder avconv \
-transcode https://onerealfunnyguy.com/mister_little_kitty.mp4
