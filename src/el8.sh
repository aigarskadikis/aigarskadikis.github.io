# Zabbix 6.0 LTS repository
rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/8/x86_64/zabbix-release-6.0-2.el8.noarch.rpm

# familiar utilities
dnf -y install strace vim tmux jq zabbix-get zabbix-sender zabbix-js

# SNMP trap dependencies. snmptrap (net-snmp-utils), snmpwalk (net-snmp-utils), snmptrapd (net-snmp), dependencies for zabbix_trap_receiver.pl (net-snmp-perl)
dnf -y install net-snmp-utils net-snmp-perl net-snmp

# Python 3 with YAML and MySQL connector support
dnf -y install python3 python3-PyMySQL python3-PyYAML

# Install MySQL server on Oracle Linux 8, RHEL 8, Rocky Linux 8
dnf -y install mysql-server

# work with Zabbix source
dnf -y install git automake gcc

