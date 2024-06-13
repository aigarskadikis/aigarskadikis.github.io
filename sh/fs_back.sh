#!/bin/bash
YEAR="$(date +%Y)"
MONTH="$(date +%m)"
DAY="$(date +%d)"
HOUR="$(date +%H)"
MINUTE="$(date +%M)"
BACKUP="/zbackup"
HOSTNAME="$(hostname -s)"
DEST="$BACKUP/$HOSTNAME/$YEAR.$MONTH.$DAY.$HOUR$MINUTE"
echo "
/etc/zabbix/zabbix_agent2.conf
/etc/zabbix/zabbix_proxy.conf
/etc/zabbix/zabbix_server.conf
/etc/cron.d/zabbix_backup
/etc/cron.d/zabbix_partitioning
/usr/local/bin/zabbix_backup.sh
/usr/local/bin/zabbix_partitioning.py
/etc/zabbix/zabbix_partitioning.conf
/etc/zabbix/zabbix_backup.cnf
/etc/zabbix/zabbix_agent2.d/ServerActive.conf
/etc/zabbix/zabbix_agent2.d/Server.conf
/etc/zabbix/web/zabbix.conf.php
/etc/mysql/mysql.conf.d/zabbix.cnf
/etc/fstab
/etc/exports
/etc/zabbix/zabbix_proxy.d/Hostname.conf
/etc/nginx/conf.d/zabbix.conf
/zbackup/fs_back.sh
" | grep -v "^$" | while IFS= read -r LINE
do {
if [ -f "$LINE" ]; then
DIRNAME="$(dirname "$LINE")"
BASENAME="$(basename "$LINE")"
mkdir --mode=770 --parents "$DEST/$DIRNAME"
cp "$LINE" "$DEST/$DIRNAME"
fi
} done
