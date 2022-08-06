# allow to reload cache from Zabbix frontend
cd /etc/sudoers.d
echo 'zabbix ALL=(ALL) NOPASSWD: /usr/sbin/zabbix_server -R config_cache_reload' | sudo tee zabbix_server_config_cache_reload
chmod 0440 zabbix_server_config_cache_reload

