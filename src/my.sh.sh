# Backup data directory. Fastest way time-wise
systemctl stop mysqld && GZIP=--fast tar cvzf /tmp/var.lib.mysql.tar.gz /var/lib/mysql

# Observe credentials how zabbix-server-mysql connects to database
grep ^DB /etc/zabbix/zabbix_server.conf

# Authorize in MySQL
mysql --host=127.0.0.1 --database=zabbixDB --user=zbx_srv --password='zabbix' --port=3306

# Track how DB table partitions grow
cd /var/lib/mysql/zabbix && watch -n1 'ls -Rltr | tail -10'

# List of MySQL tables by size
du -ab /var/lib/mysql > /tmp/size.of.tables.txt
du -ah /var/lib/mysql > /tmp/size.of.tables.human.readable.txt

# How much data is generated daily
du -lah /var/lib/mysql/zabbix | grep "$(date '+p%Y_%m_%d')"

# schema backup for MySQL 8. useful for scripts
mysqldump \
--defaults-file=/root/.my.cnf \
--flush-logs \
--single-transaction \
--set-gtid-purged=OFF \
--create-options \
--no-data \
zabbix | gzip --fast > schema.sql.gz

# data backup. gz compression
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

# data backup. xz compression
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

# schema backup for MySQL 8. credentials in the command
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

