# Discard (rename) current data tables from the application layer. Set back an empty table
DB=zabbix
OLD=_old
MIGRATE=_migrate
echo "
history
history_uint
history_str
history_log
history_text
trends
trends_uint
" | \
grep -v "^$" | \
while IFS= read -r TABLE
do {
psql $DB --command="
ALTER TABLE $TABLE RENAME TO $TABLE$OLD;
CREATE TABLE $TABLE (LIKE $TABLE$OLD INCLUDING ALL);
ALTER TABLE $TABLE OWNER TO zabbix;
CREATE TABLE $TABLE$MIGRATE (LIKE $TABLE$OLD INCLUDING ALL);
ALTER TABLE $TABLE$MIGRATE OWNER TO zabbix;
"
} done

# download historical data
DB=zabbix
date
echo "
history_old
history_uint_old
history_str_old
history_log_old
history_text_old
trends_old
trends_uint_old
" | \
grep -v "^$" | \
while IFS= read -r TABLE
do {
date
echo $TABLE
PGUSER=postgres \
psql --dbname=$DB \
--command="COPY (SELECT * FROM $TABLE) TO stdout DELIMITER E'\t' CSV" |\
lz4 > /tmp/$DB.$TABLE.tsv.lz4
} done
date
ls -lh /tmp/$DB.*
cd

# validate if some data is stored
DB=zabbix
echo "
history_old
history_uint_old
history_str_old
history_log_old
history_text_old
trends_old
trends_uint_old
" | \
grep -v "^$" | \
while IFS= read -r TABLE
do {
echo $TABLE
ls -lh /tmp/$DB.$TABLE.tsv.lz4
lz4cat /tmp/$DB.$TABLE.tsv.lz4 | head -1
} done
cd

# download current
DB=zabbix
date
echo "
history
history_uint
history_str
history_log
history_text
trends
trends_uint
" | \
grep -v "^$" | \
while IFS= read -r TABLE
do {
date
echo $TABLE
PGUSER=postgres \
psql --dbname=$DB \
--command="COPY (SELECT * FROM $TABLE) TO stdout DELIMITER E'\t' CSV" |\
lz4 > /tmp/$DB.$TABLE.tsv.lz4
} done
ls -lh /tmp/$DB.*
date
cd

# restore all graphs in background
DB=zabbix
date
OLD=_old
MIGRATE=_migrate
echo "
trends
trends_uint
history
history_uint
history_str
history_log
history_text
" | \
grep -v "^$" | \
while IFS= read -r TABLE
do {
date
echo "big upload per ${TABLE}${OLD}"
psql $DB --command="\COPY ${TABLE}${OLD} FROM PROGRAM 'lz4cat /tmp/${DB}.${TABLE}${OLD}.tsv.lz4' DELIMITER E'\t' CSV"
date
echo "upload data per ${TABLE}${MIGRATE} during migration"
psql $DB --command="\COPY ${TABLE}${MIGRATE} FROM PROGRAM 'lz4cat /tmp/${DB}.${TABLE}.tsv.lz4' DELIMITER E'\t' CSV"
date
echo "merging all data together inside ${TABLE}${OLD}"
psql $DB --command="INSERT INTO ${TABLE}${OLD} SELECT * FROM ${TABLE}${MIGRATE} ON CONFLICT DO NOTHING;"
} done
date
cd

