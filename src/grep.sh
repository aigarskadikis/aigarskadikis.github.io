# check if master processes is runnign from server, proxy or agent
ps auxww | grep "[z]abbix.*conf"

# how long takes one configuration synchronization cycle. command suitable for "zabbix_server" and "zabbix_proxy"
ps auxww | grep "[c]onfiguration.*synced"

# Zabbix server configuration file
grep -v "^$\|#" /etc/zabbix/zabbix_server.conf | sort

# Observe credentials how zabbix-server-mysql connects to database
grep ^DB /etc/zabbix/zabbix_server.conf
grep "DB\|Include" /etc/zabbix/zabbix_server.conf | grep -v '#'

# "trapper" processes of zabbix_server or zabbix_proxy
ps auxww | grep '[:] trapper'

# "history syncer" of zabbix_server or zabbix_proxy
ps auxww | grep '[:] history syncer'

# All restarts. gracefull restarts
grep "Starting Zabbix Server\|Zabbix Server stopped" /var/log/zabbix/zabbix_server.log
zcat /var/log/zabbix/zabbix_server*gz | grep "Starting Zabbix Server\|Zabbix Server stopped"

# check slow queries
grep "slow query" /var/log/zabbix/zabbix_server.log

# differences between backend nodes
grep -r '=' /etc/zabbix/zabbix_server.d/*

# how much time take for housekeeper process to complete
grep housekeeper /var/log/zabbix/zabbix_server.log

