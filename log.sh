# last 1 million lines from /var/log/zabbix/zabbix_proxy.log
tail -1000000 /var/log/zabbix/zabbix_proxy.log | gzip --best > /tmp/zabbix_proxy.$(date +%Y%m%d.%H%M).log.gz
tail -1000000 /var/log/zabbix/zabbix_proxy.log | xz > /tmp/zabbix_proxy.$(date +%Y%m%d.%H%M).log.xz

# last 1 million lines from /var/log/zabbix/zabbix_server.log
tail -1000000 /var/log/zabbix/zabbix_server.log | gzip --best > /tmp/zabbix_server.$(date +%Y%m%d.%H%M).log.gz
tail -1000000 /var/log/zabbix/zabbix_server.log | xz > /tmp/zabbix_server.$(date +%Y%m%d.%H%M).log.xz

# Which devices are sending SNMP traps and are not yet registred in Zabbix
grep -Eo "unmatched trap received from \S+" /var/log/zabbix/zabbix_server.log | sort | uniq

# query failed
grep "query failed" /var/log/zabbix/zabbix_server.log

# all restarts
grep " Zabbix Server" /var/log/zabbix/zabbix_server.log
zcat /var/log/zabbix/zabbix_server*gz | grep " Zabbix Server" | sort | tail -20

# need to increase some parameters
grep "please increase" /var/log/zabbix/zabbix_server.log
zcat /var/log/zabbix/zabbix_server*gz | grep "please increase" | sort | tail -20

