# reinstall values which have been already customized
sed -i 's|^CacheUpdateFrequency=.*|CacheUpdateFrequency=120|' /etc/zabbix/zabbix_server.conf && grep ^CacheUpdateFrequency /etc/zabbix/zabbix_server.conf
sed -i 's|^ValueCacheSize=.*|ValueCacheSize=768M|' /etc/zabbix/zabbix_server.conf && grep ^ValueCacheSize /etc/zabbix/zabbix_server.conf
sed -i 's|^TrendCacheSize=.*|TrendCacheSize=256M|' /etc/zabbix/zabbix_server.conf && grep ^TrendCacheSize /etc/zabbix/zabbix_server.conf
sed -i 's|^StartDiscoverers=.*|StartDiscoverers=20|' /etc/zabbix/zabbix_server.conf && grep ^StartDiscoverers /etc/zabbix/zabbix_server.conf

# summarize configuration file
grep -v "^$\|#" /etc/zabbix/zabbix_server.conf | sort

# restart and follow log
systemctl restart zabbix-server && tail -f /var/log/zabbix/zabbix_server.log

