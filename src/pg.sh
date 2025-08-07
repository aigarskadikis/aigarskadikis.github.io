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

# backup trends
psql nameOfZabbixDB -c "COPY (SELECT * FROM trends) TO stdout DELIMITER ',' CSV" | lz4 > /tmp/nameOfZabbixDB.trends.csv.lz4
psql nameOfZabbixDB -c "COPY (SELECT * FROM trends_uint) TO stdout DELIMITER ',' CSV" | lz4 > /tmp/nameOfZabbixDB.trends_uint.csv.lz4

# restore trends
psql nameOfZabbixDB -c "\COPY trends FROM PROGRAM 'lz4cat /tmp/nameOfZabbixDB.trends.csv.lz4' DELIMITER ',' CSV"
psql nameOfZabbixDB -c "\COPY trends_uint FROM PROGRAM 'lz4cat /tmp/nameOfZabbixDB.trends_uint.csv.lz4' DELIMITER ',' CSV"

# backup history
psql nameOfZabbixDB -c "COPY (SELECT * FROM history) TO stdout DELIMITER ',' CSV" | lz4 > /tmp/nameOfZabbixDB.history.csv.lz4
psql nameOfZabbixDB -c "COPY (SELECT * FROM history_uint) TO stdout DELIMITER ',' CSV" | lz4 > /tmp/nameOfZabbixDB.history_uint.csv.lz4

# restore history
psql nameOfZabbixDB -c "\COPY history FROM PROGRAM 'lz4cat /tmp/nameOfZabbixDB.history.csv.lz4' DELIMITER ',' CSV"
psql nameOfZabbixDB -c "\COPY history_uint FROM PROGRAM 'lz4cat /tmp/nameOfZabbixDB.history_uint.csv.lz4' DELIMITER ',' CSV"

# restore historical data in background
psql zabbix -c "\COPY trends_old FROM PROGRAM 'lz4cat /tmp/z64.trends_old.tsv.lz4' DELIMITER E'\t' CSV"
psql zabbix -c "\COPY trends_uint_old FROM PROGRAM 'lz4cat /tmp/z64.trends_uint_old.tsv.lz4' DELIMITER E'\t' CSV"
psql zabbix -c "\COPY history_old FROM PROGRAM 'lz4cat /tmp/z64.history_old.tsv.lz4' DELIMITER E'\t' CSV"
psql zabbix -c "\COPY history_uint_old FROM PROGRAM 'lz4cat /tmp/z64.history_uint_old.tsv.lz4' DELIMITER E'\t' CSV"
psql zabbix -c "\COPY history_str_old FROM PROGRAM 'lz4cat /tmp/z64.history_str_old.tsv.lz4' DELIMITER E'\t' CSV"
psql zabbix -c "\COPY history_text_old FROM PROGRAM 'lz4cat /tmp/z64.history_text_old.tsv.lz4' DELIMITER E'\t' CSV"
psql zabbix -c "\COPY history_log_old FROM PROGRAM 'lz4cat /tmp/z64.history_log_old.tsv.lz4' DELIMITER E'\t' CSV"

# PostgreSQL rename operations
ALTER TABLE trends_uint RENAME TO trends_uint_tmp; ALTER TABLE trends_uint_old RENAME TO trends_uint; INSERT INTO trends_uint SELECT * FROM trends_uint_tmp ON CONFLICT DO NOTHING;
ALTER TABLE trends RENAME TO trends_tmp; ALTER TABLE trends_old RENAME TO trends; INSERT INTO trends SELECT * FROM trends_tmp ON CONFLICT DO NOTHING;
ALTER TABLE history_uint RENAME TO history_uint_tmp; ALTER TABLE history_uint_old RENAME TO history_uint; INSERT INTO history_uint SELECT * FROM  history_uint_tmp ON CONFLICT DO NOTHING;
ALTER TABLE history RENAME TO history_tmp; ALTER TABLE history_old RENAME TO history; INSERT INTO history SELECT * FROM history_tmp ON CONFLICT DO NOTHING;
ALTER TABLE history_str RENAME TO history_str_tmp; ALTER TABLE history_str_old RENAME TO history_str; INSERT INTO history_str SELECT * FROM history_str_tmp ON CONFLICT DO NOTHING;
ALTER TABLE history_text RENAME TO history_text_tmp; ALTER TABLE history_text_old RENAME TO history_text; INSERT INTO history_text SELECT * FROM history_text_tmp ON CONFLICT DO NOTHING;
ALTER TABLE history_log RENAME TO history_log_tmp; ALTER TABLE history_log_old RENAME TO history_log; INSERT INTO history_log SELECT * FROM history_log_tmp ON CONFLICT DO NOTHING;

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

