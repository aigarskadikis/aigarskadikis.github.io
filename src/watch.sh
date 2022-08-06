# zabbix_server trapper processes
watch -n1 "ps auxww|grep '[z]abbix_server: trapper'"

# zabbix_server history syncer
watch -n1 "ps auxww|grep '[z]abbix_server: history syncer'"

# What is progress of OPTIMIZE TABLE
watch -n1 "ls -Rltr /var/lib/mysql/zabbix | grep '#sql'"

