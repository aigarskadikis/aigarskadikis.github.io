# process list
mysql \
--host=dns.of.ip \
--user=root \
--password='zabbix' \
--database=zabbix \
--execute="
SHOW FULL PROCESSLIST;
" > /tmp/mysql.process.list.$(date +%Y%m%d.%H%M).txt

# Backup directories which can be related to Zabbix
cd /usr/share/zabbix && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}
cd /etc/zabbix && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}
cd /usr/lib/zabbix && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}
cd /etc/cron.d && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}
cd /usr/local/bin && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}
cd /etc/nginx/conf.d && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}
cd /etc/php-fpm.d && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}

# create a backup user
mysql -e "
CREATE USER 'zbx_backup'@'127.0.0.1' IDENTIFIED BY 'zabbix';
GRANT LOCK TABLES, SELECT ON zabbix.* TO 'zbx_backup'@'127.0.0.1';
GRANT RELOAD ON *.* TO 'zbx_backup'@'127.0.0.1';
FLUSH PRIVILEGES;
"

# install credentials file for read-only backup
cat << 'EOF' > /etc/zabbix/zabbix_backup.cnf
[mysqldump]
host=127.0.0.1
user=zbx_backup
password=zabbix
EOF

# 30 days configuration backup if MySQL 8
BACKUP_DIR=/backup
DBNAME=zabbix
DATE=$(date +%Y%m%d.%H%M)
mkdir -p "$BACKUP_DIR"
echo "schema"
mysqldump \
--defaults-file=/etc/zabbix/zabbix_backup.cnf \
--set-gtid-purged=OFF \
--flush-logs \
--single-transaction \
--create-options \
--no-data \
$DBNAME | gzip --fast > "$BACKUP_DIR/schema.sql.gz" && \
echo "data" && mysqldump \
--defaults-file=/etc/zabbix/zabbix_backup.cnf \
--flush-logs \
--single-transaction \
--no-tablespaces \
--set-gtid-purged=OFF \
--ignore-table=$DBNAME.history \
--ignore-table=$DBNAME.history_log \
--ignore-table=$DBNAME.history_str \
--ignore-table=$DBNAME.history_text \
--ignore-table=$DBNAME.history_uint \
--ignore-table=$DBNAME.trends \
--ignore-table=$DBNAME.trends_uint \
$DBNAME > "$BACKUP_DIR/data.sql" && \
echo "compressing data" && gzip --fast "$BACKUP_DIR/data.sql" && \
echo "quick restore" && mysqldump \
--defaults-file=/etc/zabbix/zabbix_backup.cnf \
--flush-logs \
--single-transaction \
--ignore-table=$DBNAME.history \
--ignore-table=$DBNAME.history_log \
--ignore-table=$DBNAME.history_str \
--ignore-table=$DBNAME.history_text \
--ignore-table=$DBNAME.history_uint \
--ignore-table=$DBNAME.trends \
--ignore-table=$DBNAME.trends_uint \
$DBNAME > "$BACKUP_DIR/quick.restore.sql" && \
echo "compressing quick restore" && gzip --fast "$BACKUP_DIR/quick.restore.sql"
mv "$BACKUP_DIR/schema.sql.gz" "$BACKUP_DIR/schema.$DATE.sql.gz"
mv "$BACKUP_DIR/data.sql.gz" "$BACKUP_DIR/data.$DATE.sql.gz"
mv "$BACKUP_DIR/quick.restore.sql.gz" "$BACKUP_DIR/quick.restore.$DATE.sql.gz"
find /backup -type f -mtime +30
find /backup -type f -mtime +30 -delete

# mariadb backup
BACKUP_DIR=/backup
KEEP_DAYS=90
DBNAME=zabbix
DATE=$(date +%Y%m%d.%H%M)
mkdir -p "$BACKUP_DIR"
echo "schema"
mysqldump \
--defaults-file=~/zabbix_backup.cnf \
--flush-logs \
--single-transaction \
--create-options \
--no-data \
$DBNAME | gzip --fast > "$BACKUP_DIR/schema.sql.gz" && \
echo "data" && \
mysqldump \
--defaults-file=~/zabbix_backup.cnf \
--flush-logs \
--single-transaction \
--no-tablespaces \
--ignore-table=$DBNAME.history \
--ignore-table=$DBNAME.history_log \
--ignore-table=$DBNAME.history_str \
--ignore-table=$DBNAME.history_text \
--ignore-table=$DBNAME.history_uint \
--ignore-table=$DBNAME.trends \
--ignore-table=$DBNAME.trends_uint \
$DBNAME > "$BACKUP_DIR/data.sql" && \
echo "compressing data" && gzip --fast "$BACKUP_DIR/data.sql" && \
echo "snapshot" && mysqldump \
--defaults-file=~/zabbix_backup.cnf \
--flush-logs \
--single-transaction \
--ignore-table=$DBNAME.history \
--ignore-table=$DBNAME.history_log \
--ignore-table=$DBNAME.history_str \
--ignore-table=$DBNAME.history_text \
--ignore-table=$DBNAME.history_uint \
--ignore-table=$DBNAME.trends \
--ignore-table=$DBNAME.trends_uint \
$DBNAME > "$BACKUP_DIR/snapshot.sql" && \
echo "compressing snapshot" && gzip --fast "$BACKUP_DIR/snapshot.sql" && \
mv "$BACKUP_DIR/schema.sql.gz" "$BACKUP_DIR/schema.$DATE.sql.gz" && \
mv "$BACKUP_DIR/data.sql.gz" "$BACKUP_DIR/data.$DATE.sql.gz" && \
mv "$BACKUP_DIR/snapshot.sql.gz" "$BACKUP_DIR/snapshot.$DATE.sql.gz"
if [ -d "$BACKUP_DIR" ]; then
echo "deleting files older than $KEEP_DAYS days:"
find "$BACKUP_DIR" -maxdepth 1 -type f -name '*.gz' -mtime +$KEEP_DAYS
find "$BACKUP_DIR" -maxdepth 1 -type f -name '*.gz' -mtime +$KEEP_DAYS -delete
fi

# rotate backups for 30 days
find /backup -type f -mtime +30
find /backup -type f -mtime +30 -delete

# Backup and compress zabbix server config with a purpose to restore it on other machine
tar --create --verbose --use-compress-program='gzip -9' /etc/zabbix/zabbix_server.conf | base64 -w0 | sed 's|^|cd / \&\& echo "|' | sed 's%$%" | base64 --decode | gunzip | tar -xv%' && echo

# Backup and compress Zabbix agent 2 config with a purpose to restore it on other machine
tar --create --verbose --use-compress-program='gzip -9' /etc/zabbix/zabbix_agent2.conf | base64 -w0 | sed 's|^|cd / \&\& echo "|' | sed 's%$%" | base64 --decode | gunzip | tar -xv%' && echo

# Backup and compress partitioning script and configuration files
tar --create --verbose --use-compress-program='gzip -9' /etc/zabbix/zabbix_partitioning.conf /usr/local/bin/zabbix_partitioning.py /etc/cron.d/zabbix_partitioning | base64 -w0 | sed 's|^|cd / \&\& echo "|' | sed 's%$%" | base64 --decode | gunzip | tar -xv%' && echo

# Backup all frontend modules with 'xz' compression
tar --create --verbose --use-compress-program='xz -9' /usr/share/zabbix/modules | base64 -w0 | sed 's|^|cd / \&\& echo "|' | sed 's%$%" | base64 --decode | unxz | tar -xv%' && echo

