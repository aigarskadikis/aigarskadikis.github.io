# Backup directories which can be related to Zabbix
cd /usr/share/zabbix && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}
cd /etc/zabbix && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}
cd /usr/lib/zabbix && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}
cd /etc/cron.d && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}
cd /usr/local/bin && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}
cd /etc/nginx/conf.d && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}
cd /etc/php-fpm.d && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}

# Backup and compress zabbix server config with a purpose to restore it on other machine
tar --create --verbose --use-compress-program='gzip -9' /etc/zabbix/zabbix_server.conf | base64 -w0 | sed 's|^|cd / \&\& echo "|' | sed 's%$%" | base64 --decode | gunzip | tar -xv%' && echo

# Backup and compress Zabbix agent 2 config with a purpose to restore it on other machine
tar --create --verbose --use-compress-program='gzip -9' /etc/zabbix/zabbix_agent2.conf | base64 -w0 | sed 's|^|cd / \&\& echo "|' | sed 's%$%" | base64 --decode | gunzip | tar -xv%' && echo

# Backup and compress partitioning script and configuration files
tar --create --verbose --use-compress-program='gzip -9' /etc/zabbix/zabbix_partitioning.conf /usr/local/bin/zabbix_partitioning.py /etc/cron.d/zabbix_partitioning | base64 --decode | gunzip | tar -xv%' && echo

