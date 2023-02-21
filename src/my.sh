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

# schema backup for MySQL 8. credentials embeded in command
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

