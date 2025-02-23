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

# Pod podman unqualified-search. did not resolve to an alias and no unqualified-search registries are defined in "/etc/containers/registries.conf"
echo 'unqualified-search-registries = ["docker.io"]' | sudo tee /etc/containers/registries.conf

# reinstall version of zabbix monitoring proxy
sed -i 's|alpine-7.0.*$|alpine-7.0.9|g' values.yaml
helm uninstall my-release && helm install my-release -f values.yaml ./
kubectl get secret zabbix-service-account -n default -o jsonpath={.data.token} | base64 -d

# restart pod (by deleting it)
kubectl get pods | grep -Eo "zabbix-proxy\S+" | xargs kubectl delete pod

