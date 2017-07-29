docker run -d \
    --name="grafana" \
    -p 3000:3000 \
    -v /home/$USER/grafana/db/:/var/lib/grafana/ \
    -v /home/$USER/grafana/config/:/etc/grafana/ \
     grafana/grafana
