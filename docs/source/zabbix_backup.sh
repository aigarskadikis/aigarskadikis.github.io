#!/bin/bash

# zabbix server or zabbix proxy for zabbix sender
contact=127.0.0.1

year=$(date +%Y)
month=$(date +%m)
day=$(date +%d)
clock=$(date +%H%M)
volume=/backup
mysql=$volume/mysql/zabbix/$year/$month/$day/$clock
filesystem=$volume/filesystem/$year/$month/$day/$clock
if [ ! -d "$mysql" ]; then
  mkdir -p "$mysql"
fi

if [ ! -d "$filesystem" ]; then
  mkdir -p "$filesystem"
fi

echo -e "\nDelete itemid which do not exist anymore for an INTERNAL event"
mysql zabbix -e "
DELETE 
FROM events
WHERE events.source = 3 
AND events.object = 4 
AND events.objectid NOT IN (
SELECT itemid FROM items)
"

echo -e "\nDelete trigger event where triggerid do not exist anymore"
mysql zabbix -e "
DELETE
FROM events
WHERE source = 0
AND object = 0
AND objectid NOT IN
(SELECT triggerid FROM triggers)
"

echo -e "\nExtracting schema"
/usr/bin/zabbix_sender --zabbix-server $contact --host $(hostname -s).gnt.lan -k backup.status -o 1
mysqldump \
--set-gtid-purged=OFF \
--flush-logs \
--single-transaction \
--create-options \
--no-data \
zabbix > $mysql/schema.sql && \
xz $mysql/schema.sql

if [ ${PIPESTATUS[0]} -ne 0 ]; then
/usr/bin/zabbix_sender --zabbix-server $contact --host $(hostname -s).gnt.lan -k backup.status -o 1
echo "mysqldump executed with error !!"
else
/usr/bin/zabbix_sender --zabbix-server $contact --host $(hostname -s).gnt.lan -k backup.status -o 0
echo content of $mysql
ls -lh $mysql
fi

sleep 1

echo -e "\nBackup in one file. Useful to quickly bring back older configuration. while still keeping history"
mysqldump \
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
zabbix > $mysql/quick.restore.sql && \
xz $mysql/quick.restore.sql

sleep 1
echo -e "\nData backup except raw metrics"
/usr/bin/zabbix_sender --zabbix-server $contact --host $(hostname -s).gnt.lan -k backup.status -o 2
mysqldump \
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
zabbix > $mysql/data.sql && \
xz $mysql/data.sql

if [ ${PIPESTATUS[0]} -ne 0 ]; then
/usr/bin/zabbix_sender --zabbix-server $contact --host $(hostname -s).gnt.lan -k backup.status -o 2
echo "mysqldump executed with error !!"
else
/usr/bin/zabbix_sender --zabbix-server $contact --host $(hostname -s).gnt.lan -k backup.status -o 0
echo content of $mysql
ls -lh $mysql
fi

/usr/bin/zabbix_sender --zabbix-server $contact --host $(hostname -s).gnt.lan -k backup.sql.data.size -o $(ls -s --block-size=1 $mysql/data.sql.xz | grep -Eo "^[0-9]+")

sleep 1
echo -e "\nArchiving important directories and files"
/usr/bin/zabbix_sender --zabbix-server $contact --host $(hostname -s).gnt.lan -k backup.status -o 3

sudo tar -czvf $filesystem/fs.conf.zabbix.tar.gz \
--files-from "/etc/zabbix/backup_zabbix_files.list" \
--files-from "/etc/zabbix/backup_zabbix_directories.list" \
/usr/bin/zabbix_* \
$(grep zabbix /etc/passwd|cut -d: -f6) \
/var/lib/grafana 

/usr/bin/zabbix_sender --zabbix-server $contact --host $(hostname -s).gnt.lan -k backup.status -o $?

/usr/bin/zabbix_sender --zabbix-server $contact --host $(hostname -s).gnt.lan -k backup.filesystem.size -o $(ls -s --block-size=1 $filesystem/fs.conf.zabbix.tar.xz | grep -Eo "^[0-9]+")

# remove older files than 30 days
echo -e "\nThese files will be deleted:"
find /backup -type f -mtime +30
# delete files
find /backup -type f -mtime +30 -delete

echo -e "\nRemoving empty directories:"
find /backup -type d -empty -print
# delete empty directories
find /backup -type d -empty -print -delete

echo -e "\nUploading sql backup to google drive"
/usr/bin/zabbix_sender --zabbix-server $contact --host $(hostname -s).gnt.lan -k backup.status -o 4
rclone -vv sync $volume/mysql BackupMySQL:mysql

/usr/bin/zabbix_sender --zabbix-server $contact --host $(hostname -s).gnt.lan -k backup.status -o $?

echo -e "\nUploading filesystem backup to google drive"
/usr/bin/zabbix_sender --zabbix-server $contact --host $(hostname -s).gnt.lan -k backup.status -o 5
rclone -vv sync $volume/filesystem BackupFileSystem:filesystem

/usr/bin/zabbix_sender --zabbix-server $contact --host $(hostname -s).gnt.lan -k backup.status -o $?

