docker run --name=appdaemon -d -p 5050:5050 \
  --restart=always \
  -e HA_URL="http://hive:8123" \
  -e DASH_URL="http://$HOSTNAME:5050" \
  -v /home/$USER/appdaemon/conf:/conf \
  acockburn/appdaemon:latest
