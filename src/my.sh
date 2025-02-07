# List of MySQL tables/partitions by size
du -ab /var/lib/mysql > /tmp/size.of.tables.txt
du -ah /var/lib/mysql > /tmp/size.of.tables.human.readable.txt

# Backup data directory. Fastest way time-wise
systemctl stop mysqld
tar --create --verbose --use-compress-program='gzip --fast' --file=/tmp/var.lib.mysql.tar.gz /var/lib/mysql

# check "Max open files" for MySQL daemon. this is important if a lot of DB table partition are used
cat /proc/$(ps auxww | grep "[m]ysqld" | awk '{print $2}')/limits | grep "Max open files"

# Authorize in MySQL
mysql --host=127.0.0.1 --database=zabbixDB --user=zbx_srv --password='zabbix' --port=3306

# Track how DB table partitions grow
cd /var/lib/mysql/zabbix && watch -n1 'ls -Rltr | tail -10'

# list of open files per MySQL server. if tables has a lot of partitions it will be a lot of files
lsof -p $(pidof mysqld) > /tmp/mysqld.list.open.files.txt

# How much data is generated in 24h
du -lah /var/lib/mysql/zabbix | grep "$(date --date='2 days ago' '+p%Y_%m_%d')"
du -lah /var/lib/mysql/zabbix | grep "$(date --date='2 days ago' '+p%Y%m%d0000')"

# extract legacy SNMP agent items in use
mysql -sN --batch --host=127.0.0.1 --user=root --password='zabbix' --database=zabbix --execute="
SELECT DISTINCT templates.name, items.flags, items.name, items.snmp_oid FROM hosts templates, hosts_templates, items
WHERE templates.hostid=items.hostid AND templates.hostid=hosts_templates.templateid AND hosts_templates.hostid IN (
SELECT hostid FROM hosts WHERE status=0
)
AND items.type=20
AND templates.status=3
ORDER BY 1,2,3;
" > /tmp/all.snmp.templates.in.use.with.legacy.snmp.agent.item.tsv

# Track progress of "OPTIMIZE TABLE" in MySQL
watch -n1 "ls -Rltr /var/lib/mysql/zabbix | grep '#sql'"

# schema backup for MySQL 8. useful for scripts
mysqldump \
--defaults-file=/root/.my.cnf \
--flush-logs \
--single-transaction \
--set-gtid-purged=OFF \
--create-options \
--no-data \
zabbix | gzip --fast > schema.sql.gz

# create backup with a purpose to set up master to master replication
mysqldump --source-data --all-databases \
--set-gtid-purged=OFF \
--ignore-table=zabbix.history \
--ignore-table=zabbix.history_uint \
--ignore-table=zabbix.history_str \
--ignore-table=zabbix.history_text \
--ignore-table=zabbix.history_log \
--ignore-table=zabbix.trends \
--ignore-table=zabbix.trends_uint | gzip --fast > /tmp/backup.sql.gz
chmod 777 /tmp/backup.sql.gz

# schema dump for historical tables only. backup schema for 7 historical tables. usefull if need to repair replication as fast as possible
mysqldump --set-gtid-purged=OFF --no-data zabbix history history_uint history_str history_log history_text trends trends_uint > empty.data.tables.with.partitions.sql

# data backup with gz compression
mysqldump \
--defaults-file=/root/.my.cnf \
--set-gtid-purged=OFF \
--flush-logs \
--single-transaction \
--no-create-info \
--ignore-table=zabbix.history \
--ignore-table=zabbix.history_log \
--ignore-table=zabbix.history_str \
--ignore-table=zabbix.history_text \
--ignore-table=zabbix.history_uint \
--ignore-table=zabbix.trends \
--ignore-table=zabbix.trends_uint \
zabbix > data.sql && \
gzip data.sql

# data backup with xz compression
mysqldump \
--defaults-file=/root/.my.cnf \
--set-gtid-purged=OFF \
--flush-logs \
--single-transaction \
--no-create-info \
--ignore-table=zabbix.history \
--ignore-table=zabbix.history_log \
--ignore-table=zabbix.history_str \
--ignore-table=zabbix.history_text \
--ignore-table=zabbix.history_uint \
--ignore-table=zabbix.trends \
--ignore-table=zabbix.trends_uint \
zabbix > data.sql && \
xz data.sql

# passwordless access for read-only user
cd && cat << 'EOF' > .my.cnf
[client]
host=192.168.88.101
user=zbx_ro
password=passwd_ro_zbx
EOF

# extend open_files_limit for service mysqld. Could not increase number of max_open_files to more than
mkdir -p /etc/systemd/system/mysqld.service.d && cd /etc/systemd/system/mysqld.service.d && cat << 'EOF' > override.conf
[Service]
LimitNOFILE=65535
EOF
systemctl --system daemon-reload
mysql_pid=$(ps aux | grep "mysql" | head -n 1 | awk '{print $2}')
cat /proc/$mysql_pid/limits 

# on-the-fly configuration backup. check if this is not the node holding the Virtaul IP address. Do a backup on slave
ip a | grep "192.168.88.55" || mysqldump \
--defaults-file=/root/.my.cnf \
--set-gtid-purged=OFF \
--flush-logs \
--single-transaction \
--ignore-table=zabbix.history \
--ignore-table=zabbix.history_log \
--ignore-table=zabbix.history_str \
--ignore-table=zabbix.history_text \
--ignore-table=zabbix.history_uint \
--ignore-table=zabbix.trends \
--ignore-table=zabbix.trends_uint \
zabbix | gzip > quick.restore.sql.gz

# MySQL 8.0 schema backup for MySQL 8. credentials embeded in command
mysqldump \
--host=127.0.0.1 \
--user=root \
--password='zabbix' \
--set-gtid-purged=OFF \
--flush-logs \
--single-transaction \
--create-options \
--no-data \
zabbix | gzip --fast > schema.sql.gz

# backup "_old" tables with fastest compression possible
DB=zabbix
DEST=/mnt/zabbixtemp
mkdir -p "$DEST"
mysqldump $DB trends_uint_old | lz4 > "$DEST/trends_uint_old.sql.lz4" &
mysqldump $DB trends_old | lz4 > "$DEST/trends_old.sql.lz4" &
mysqldump $DB history_uint_old | lz4 > "$DEST/history_uint_old.sql.lz4" &
mysqldump $DB history_old | lz4 > "$DEST/history_old.sql.lz4" &
mysqldump $DB history_str_old | lz4 > "$DEST/history_str_old.sql.lz4" &
mysqldump $DB history_log_old | lz4 > "$DEST/history_log_old.sql.lz4" &
mysqldump $DB history_text_old | lz4 > "$DEST/history_text_old.sql.lz4" &

# MariaDB 10.3 schema backup
mysqldump \
--defaults-file=/root/.my.cnf \
--flush-logs \
--single-transaction \
--create-options \
--no-data \
zabbix > /root/schema52.sql

# MariaDB 10.3 data backup without history
mysqldump \
--defaults-file=/root/.my.cnf \
--flush-logs \
--single-transaction \
--no-create-info \
--skip-triggers \
--ignore-table=zabbix.history \
--ignore-table=zabbix.history_log \
--ignore-table=zabbix.history_str \
--ignore-table=zabbix.history_text \
--ignore-table=zabbix.history_uint \
--ignore-table=zabbix.trends \
--ignore-table=zabbix.trends_uint \
zabbix | gzip --fast > /root/data52.sql.gz

# backup historical data individualu compress with gzip
tmux
mysqldump --defaults-file=/root/.my.cnf --flush-logs --single-transaction --no-create-info --skip-triggers zabbix trends_uint | gzip --fast > /root/trends_uint.sql.gz
mysqldump --defaults-file=/root/.my.cnf --flush-logs --single-transaction --no-create-info --skip-triggers zabbix trends | gzip --fast > /root/trends.sql.gz
mysqldump --defaults-file=/root/.my.cnf --flush-logs --single-transaction --no-create-info --skip-triggers zabbix history_uint | gzip --fast > /root/history_uint.sql.gz
mysqldump --defaults-file=/root/.my.cnf --flush-logs --single-transaction --no-create-info --skip-triggers zabbix history | gzip --fast > /root/history.sql.gz
mysqldump --defaults-file=/root/.my.cnf --flush-logs --single-transaction --no-create-info --skip-triggers zabbix history_str | gzip --fast > /root/history_str.sql.gz
mysqldump --defaults-file=/root/.my.cnf --flush-logs --single-transaction --no-create-info --skip-triggers zabbix history_text | gzip --fast > /root/history_text.sql.gz
mysqldump --defaults-file=/root/.my.cnf --flush-logs --single-transaction --no-create-info --skip-triggers zabbix history_log | gzip --fast > /root/history_log.sql.gz

# backup historical data individualy. compress with lz4
tmux
mysqldump --defaults-file=/root/.my.cnf --flush-logs --single-transaction --no-create-info --skip-triggers zabbix trends_uint | lz4 > /root/trends_uint.sql.lz4
mysqldump --defaults-file=/root/.my.cnf --flush-logs --single-transaction --no-create-info --skip-triggers zabbix trends | lz4 > /root/trends.sql.lz4
mysqldump --defaults-file=/root/.my.cnf --flush-logs --single-transaction --no-create-info --skip-triggers zabbix history_uint | lz4 > /root/history_uint.sql.lz4
mysqldump --defaults-file=/root/.my.cnf --flush-logs --single-transaction --no-create-info --skip-triggers zabbix history | lz4 > /root/history.sql.lz4
mysqldump --defaults-file=/root/.my.cnf --flush-logs --single-transaction --no-create-info --skip-triggers zabbix history_str | lz4 > /root/history_str.sql.lz4
mysqldump --defaults-file=/root/.my.cnf --flush-logs --single-transaction --no-create-info --skip-triggers zabbix history_text | lz4 > /root/history_text.sql.lz4
mysqldump --defaults-file=/root/.my.cnf --flush-logs --single-transaction --no-create-info --skip-triggers zabbix history_log | lz4 > /root/history_log.sql.lz4

# backup current data tables with fastest compression possible
DB=zabbix
DEST=/mnt/zabbixtemp
mkdir -p "$DEST"
mysqldump $DB trends_uint | lz4 > "$DEST/trends_uint.sql.lz4" &
mysqldump $DB trends | lz4 > "$DEST/trends.sql.lz4" &
mysqldump $DB history_uint | lz4 > "$DEST/history_uint.sql.lz4" &
mysqldump $DB history | lz4 > "$DEST/history.sql.lz4" &
mysqldump $DB history_str | lz4 > "$DEST/history_str.sql.lz4" &
mysqldump $DB history_log | lz4 > "$DEST/history_log.sql.lz4" &
mysqldump $DB history_text | lz4 > "$DEST/history_text.sql.lz4" &

# restore from sql.gz
time zcat /root/trends_uint.sql.gz | sed 's|trends_uint|trends_uint_old|' | mysql --defaults-file=/root/.my.cnf zabbix
time zcat /root/history_uint.sql.gz | sed 's|history_uint|history_uint_old|' | mysql --defaults-file=/root/.my.cnf zabbix
time zcat /root/trends.sql.gz | sed 's|trends|trends_old|' | mysql --defaults-file=/root/.my.cnf zabbix
time zcat /root/history.sql.gz | sed 's|history|history_old|' | mysql --defaults-file=/root/.my.cnf zabbix
time zcat /root/history_str.sql.gz | sed 's|history_str|history_str_old|' | mysql --defaults-file=/root/.my.cnf zabbix
time zcat /root/history_text.sql.gz | sed 's|history_text|history_text_old|' | mysql --defaults-file=/root/.my.cnf zabbix
time zcat /root/history_log.sql.gz | sed 's|history_log|history_log_old|' | mysql --defaults-file=/root/.my.cnf zabbix

# restore from sql.lz4
time unlz4 /root/trends_uint.sql.lz4 | sed 's|trends_uint|trends_uint_old|' | mysql --defaults-file=/root/.my.cnf zabbix
time unlz4 /root/history_uint.sql.lz4 | sed 's|history_uint|history_uint_old|' | mysql --defaults-file=/root/.my.cnf zabbix
time unlz4 /root/trends.sql.lz4 | sed 's|trends|trends_old|' | mysql --defaults-file=/root/.my.cnf zabbix
time unlz4 /root/history.sql.lz4 | sed 's|history|history_old|' | mysql --defaults-file=/root/.my.cnf zabbix
time unlz4 /root/history_str.sql.lz4 | sed 's|history_str|history_str_old|' | mysql --defaults-file=/root/.my.cnf zabbix
time unlz4 /root/history_text.sql.lz4 | sed 's|history_text|history_text_old|' | mysql --defaults-file=/root/.my.cnf zabbix
time unlz4 /root/history_log.sql.lz4 | sed 's|history_log|history_log_old|' | mysql --defaults-file=/root/.my.cnf zabbix

