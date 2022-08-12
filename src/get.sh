# MySQL monitoring through Zabbix agent 2
zabbix_get -s 127.0.0.1 -k 'mysql.get_status_variables["tcp://127.0.0.1:3306","zbx_monitor","zabbix"]'

# PostgreSQL monitoring through Zabbix agent 2
zabbix_get -s 127.0.0.1 -k 'pgsql.dbstat["tcp://127.0.0.1:5432","zbx_monitor","zabbix"]'

# Oracle 19c monitoring through Zabbix agent 2
zabbix_get -s 127.0.0.1 -k 'oracle.instance.info["tcp://127.0.0.1:1521","zabbix_mon","zabbix","ORCLPDB1"]'

