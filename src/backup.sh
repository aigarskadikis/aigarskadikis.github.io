# Backup directories which can be related to Zabbix
cd /usr/share/zabbix && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}
cd /etc/zabbix && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}
cd /usr/lib/zabbix && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}
cd /etc/cron.d && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}
cd /usr/local/bin && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}
cd /etc/nginx/conf.d && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}
cd /etc/php-fpm.d && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}

# 30 days configuration backup if MySQL 8
BACKUP_DIR=/home/zabbix/backup
mkdir -p "$BACKUP_DIR"
mysqldump \
--defaults-file=/etc/zabbix/zabbix_backup.cnf \
--flush-logs \
--single-transaction \
--no-tablespaces \
--set-gtid-purged=OFF \
--ignore-table=zabbix.history \
--ignore-table=zabbix.history_log \
--ignore-table=zabbix.history_str \
--ignore-table=zabbix.history_text \
--ignore-table=zabbix.history_uint \
--ignore-table=zabbix.trends \
--ignore-table=zabbix.trends_uint \
zabbix > "$BACKUP_DIR/backup.sql" && \
gzip --best "$BACKUP_DIR/backup.sql" && \
mv "$BACKUP_DIR/backup.sql.gz" "$BACKUP_DIR/quick.restore.$(date +%Y%m%d.%H%M).sql.gz"
find /home/zabbix/backup -type f -mtime +30
find /home/zabbix/backup -type f -mtime +30 -delete

# Backup and compress zabbix server config with a purpose to restore it on other machine
tar --create --verbose --use-compress-program='gzip -9' /etc/zabbix/zabbix_server.conf | base64 -w0 | sed 's|^|cd / \&\& echo "|' | sed 's%$%" | base64 --decode | gunzip | tar -xv%' && echo

# Backup and compress Zabbix agent 2 config with a purpose to restore it on other machine
tar --create --verbose --use-compress-program='gzip -9' /etc/zabbix/zabbix_agent2.conf | base64 -w0 | sed 's|^|cd / \&\& echo "|' | sed 's%$%" | base64 --decode | gunzip | tar -xv%' && echo

# Backup and compress partitioning script and configuration files
tar --create --verbose --use-compress-program='gzip -9' /etc/zabbix/zabbix_partitioning.conf /usr/local/bin/zabbix_partitioning.py /etc/cron.d/zabbix_partitioning | base64 -w0 | sed 's|^|cd / \&\& echo "|' | sed 's%$%" | base64 --decode | gunzip | tar -xv%' && echo

# Backup all frontend modules with 'xz' compression
tar --create --verbose --use-compress-program='xz -9' /usr/share/zabbix/modules | base64 -w0 | sed 's|^|cd / \&\& echo "|' | sed 's%$%" | base64 --decode | unxz | tar -xv%' && echo

