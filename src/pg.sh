# extract configuration dump from old server
pg_dump \
--dbname=DATABASE \
--host=HOST \
--username=USER \
--file=zabbix.dump \
--format=custom \
--blobs \
--verbose \
--exclude-table-data '*.history*' \
--exclude-table-data '*.trends*'

# restore
pg_restore \
--dbname=<database> \
--host=<host> \
zabbix.dump

# backup individual historical table
PGHOST=127.0.0.1 \
PGPORT=5432 \
PGUSER=postgres \
PGPASSWORD=zabbix \
psql --dbname=zabbix \
-c "COPY (SELECT * FROM history_uint) TO stdout DELIMITER ',' CSV" | \
xz > /tmp/history_uint.csv.xz

# restore
psql zabbix -c "\COPY history_uint FROM PROGRAM 'xzcat /tmp/history_uint.csv.xz' DELIMITER ',' CSV"

