#!/bin/bash
# 30 days configuration backup if MySQL 8
DBNAME=zabbix
DATE=$(date +%Y%m%d.%H%M)
echo "schema"
mysqldump \
--defaults-file=/etc/zabbix/zabbix_backup.cnf \
--set-gtid-purged=OFF \
--flush-logs \
--single-transaction \
--create-options \
--no-data \
$DBNAME > "/backups/schema.$DATE.sql" && \
echo "data" && mysqldump \
--defaults-file=/etc/zabbix/zabbix_backup.cnf \
--flush-logs \
--single-transaction \
--no-tablespaces \
--set-gtid-purged=OFF \
--ignore-table=$DBNAME.history \
--ignore-table=$DBNAME.history_bin \
--ignore-table=$DBNAME.history_log \
--ignore-table=$DBNAME.history_str \
--ignore-table=$DBNAME.history_text \
--ignore-table=$DBNAME.history_uint \
--ignore-table=$DBNAME.trends \
--ignore-table=$DBNAME.trends_uint \
$DBNAME | lz4 > "/backups/data.$DATE.sql.lz4" && \
echo "snapshot" && mysqldump \
--defaults-file=/etc/zabbix/zabbix_backup.cnf \
--flush-logs \
--single-transaction \
--ignore-table=$DBNAME.history \
--ignore-table=$DBNAME.history_bin \
--ignore-table=$DBNAME.history_log \
--ignore-table=$DBNAME.history_str \
--ignore-table=$DBNAME.history_text \
--ignore-table=$DBNAME.history_uint \
--ignore-table=$DBNAME.trends \
--ignore-table=$DBNAME.trends_uint \
$DBNAME | lz4 > "/backups/snapshot.$DATE.sql.lz4"
ls -lh /backups/* | grep "$DATE"
find /backups -type f -mtime +30
find /backups -type f -mtime +30 -delete
