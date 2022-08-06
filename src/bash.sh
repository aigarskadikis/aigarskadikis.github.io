# Zabbix server configuration file
grep -v "^$\|#" /etc/zabbix/zabbix_server.conf | sort

# differences between backend nodes
grep -r '=' /etc/zabbix/zabbix_server.d/*

# listening TCP ports
ss --tcp --listen --numeric

# listening TCP ports with process identification
ss --tcp --listen --numeric --process

# check if tcp port listens. make sure it really listens on destination server before checking
nc -v servername 3306

