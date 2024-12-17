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

# restore historical data in background
psql zabbix -c "\COPY trends_old FROM PROGRAM 'lz4cat /tmp/z64.trends_old.tsv.lz4' DELIMITER E'\t' CSV"
psql zabbix -c "\COPY trends_uint_old FROM PROGRAM 'lz4cat /tmp/z64.trends_uint_old.tsv.lz4' DELIMITER E'\t' CSV"
psql zabbix -c "\COPY history_old FROM PROGRAM 'lz4cat /tmp/z64.history_old.tsv.lz4' DELIMITER E'\t' CSV"
psql zabbix -c "\COPY history_uint_old FROM PROGRAM 'lz4cat /tmp/z64.history_uint_old.tsv.lz4' DELIMITER E'\t' CSV"
psql zabbix -c "\COPY history_str_old FROM PROGRAM 'lz4cat /tmp/z64.history_str_old.tsv.lz4' DELIMITER E'\t' CSV"
psql zabbix -c "\COPY history_text_old FROM PROGRAM 'lz4cat /tmp/z64.history_text_old.tsv.lz4' DELIMITER E'\t' CSV"
psql zabbix -c "\COPY history_log_old FROM PROGRAM 'lz4cat /tmp/z64.history_log_old.tsv.lz4' DELIMITER E'\t' CSV"

# restore
pg_restore \
--dbname=DATABASE \
--host=HOST \
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

