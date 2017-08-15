FROM debian:jessie

RUN apt-get update && \
  apt-get install -y apt-transport-https && \
  apt-get install -y curl git python python-pip && \
  echo 'deb http://httpredir.debian.org/debian jessie-backports main non-free' >> /etc/apt/sources.list && \
  echo 'deb-src http://httpredir.debian.org/debian jessie-backports main non-free' >> /etc/apt/sources.list && \
  apt-get update && \
  apt-get install -y ffmpeg && \
  apt-get install -y libav-tools && \
  git clone https://github.com/Pat-Carter/stream2chromecast.git

COPY start-stream.sh /usr/local/bin/start-stream.sh
RUN chmod +x /usr/local/bin/start-stream.sh
#ENTRYPOINT ["/usr/local/bin/start-stream.sh"]
#CMD [" ./start-stream.sh bash"]
EXPOSE 8765:8765
CMD ["/bin/bash","/usr/local/bin/start-stream.sh"]
