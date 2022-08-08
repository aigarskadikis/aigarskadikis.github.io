--create an empty database with name 'zabbix'. Zabbix 6.0 LTS
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;

--DB1. user for replication
CREATE USER 'repl'@'192.168.88.101' IDENTIFIED WITH mysql_native_password BY 'PasswordForDBReplication';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'192.168.88.101';

--DB2. user for replication
CREATE USER 'repl'@'192.168.88.102' IDENTIFIED WITH mysql_native_password BY 'PasswordForDBReplication';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'192.168.88.102';

--APP1. user for 'zabbix-server'
CREATE USER 'zbx_srv'@'192.168.88.111' IDENTIFIED WITH mysql_native_password BY 'PasswordForApplicationServer';

--APP2. user for 'zabbix-server'
CREATE USER 'zbx_srv'@'192.168.88.112' IDENTIFIED WITH mysql_native_password BY 'PasswordForApplicationServer';

--bare minumum permissions for 'zabbix-server'. Command suitable for 6.0
CREATE ROLE 'zbx_srv_role';
GRANT SELECT, UPDATE, DELETE, INSERT, CREATE, DROP, ALTER, INDEX, REFERENCES ON zabbix.* TO 'zbx_srv_role';

--APP1. Assign role
GRANT 'zbx_srv_role' TO 'zbx_srv'@'192.168.88.111';
SET DEFAULT ROLE 'zbx_srv_role' TO 'zbx_srv'@'192.168.88.111';

--APP2. Assign role
GRANT 'zbx_srv_role' TO 'zbx_srv'@'192.168.88.112';
SET DEFAULT ROLE 'zbx_srv_role' TO 'zbx_srv'@'192.168.88.112';

--GUI1. user for 'nginx'
CREATE USER 'zbx_web'@'192.168.88.121' IDENTIFIED WITH mysql_native_password BY 'PasswordForFrontendNode';

--GUI2. user for 'nginx'
CREATE USER 'zbx_web'@'192.168.88.122' IDENTIFIED WITH mysql_native_password BY 'PasswordForFrontendNode';

--install bare minimum permissions for frontend
CREATE ROLE 'zbx_web_role';
GRANT SELECT, UPDATE, DELETE, INSERT ON zabbix.* TO 'zbx_web_role';

--GUI1. Assign role
GRANT 'zbx_web_role' TO 'zbx_web'@'192.168.88.121';
SET DEFAULT ROLE 'zbx_web_role' TO 'zbx_web'@'192.168.88.121';

--GUI2. Assign role
GRANT 'zbx_web_role' TO 'zbx_web'@'192.168.88.122';
SET DEFAULT ROLE 'zbx_web_role' TO 'zbx_web'@'192.168.88.122';

--user for DB partitioning script
CREATE USER 'zbx_part'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY 'PasswordForDBPartitioning';
GRANT ALL PRIVILEGES ON *.* to 'zbx_part'@'127.0.0.1';

--User to monitor the health of MySQL server via local Zabbix agent 2. Not suitable for RDS.
CREATE USER 'zbx_monitor'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY 'PasswordForAgent2ActiveMonitoring';
GRANT REPLICATION CLIENT,PROCESS,SHOW DATABASES,SHOW VIEW ON *.* TO 'zbx_monitor'@'127.0.0.1';

--APP1. user to monitor RDS database
CREATE USER 'zbx_monitor'@'192.168.88.111' IDENTIFIED WITH mysql_native_password BY 'PasswordForAgent2PassiveMonitoring';
GRANT REPLICATION CLIENT,PROCESS,SHOW DATABASES,SHOW VIEW ON *.* TO 'zbx_monitor'@'192.168.88.111';

--APP2. user to monitor RDS database
CREATE USER 'zbx_monitor'@'192.168.88.112' IDENTIFIED WITH mysql_native_password BY 'PasswordForAgent2PassiveMonitoring';
GRANT REPLICATION CLIENT,PROCESS,SHOW DATABASES,SHOW VIEW ON *.* TO 'zbx_monitor'@'192.168.88.112';

--backup user for 'mysqldump'
CREATE USER 'zbx_backup'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY 'PassfordForMySQLDUmp';
GRANT SELECT, LOCK TABLES, SHOW VIEW, RELOAD ON *.* TO 'zbx_backup'@'127.0.0.1';

--Read only user for reporting
CREATE USER 'zbx_read_only'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY 'PasswordForReadOnlyUser';
GRANT SELECT ON zabbix.* TO 'zbx_backup'@'127.0.0.1';

--User for grafana which runs in docker
CREATE USER 'grafana'@'%' IDENTIFIED WITH mysql_native_password BY 'PasswordForReadOnlyGrafanaUser';
GRANT SELECT ON zabbix.* TO 'grafana'@'%';

