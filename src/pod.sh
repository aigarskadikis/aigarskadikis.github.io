# snmpsim
docker run -v /usr/share/snmpsim/data:/usr/local/snmpsim/data -p 1024:161/udp tandrup/snmpsim

# postgresql 17 with timescaledb
podman pull timescale/timescaledb:2.18.1-pg17
mkdir -p ${HOME}/postgresql/17
podman run --name pg17ts2181 -t \
-e PGDATA=/var/lib/postgresql/data/pgdata \
-v ${HOME}/postgresql/17:/var/lib/postgresql/data \
-e POSTGRES_PASSWORD="zabbix" \
-e POSTGRES_DB="dummy_db" \
-p 7417:5432 \
-d timescale/timescaledb:2.18.1-pg17

