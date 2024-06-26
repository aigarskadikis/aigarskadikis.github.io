--ssl connection information for MySQL
SELECT sbt.variable_value AS tls_version, t2.variable_value AS cipher,
processlist_user AS user, processlist_host AS host
FROM performance_schema.status_by_thread AS sbt
JOIN performance_schema.threads AS t ON t.thread_id = sbt.thread_id
JOIN performance_schema.status_by_thread AS t2 ON t2.thread_id = t.thread_id
WHERE sbt.variable_name = 'Ssl_version' and t2.variable_name = 'Ssl_cipher' ORDER BY tls_version;

--list show mysql users and databases, permissions
SELECT host, db, user FROM mysql.db;
SELECT host, user FROM mysql.user;

--disable redo log on global level
ALTER INSTANCE DISABLE INNODB REDO_LOG;

--check status of redo log
show global status like '%redo%';

--remove bin logs logbin binlog log_bin bin_log
PURGE BINARY LOGS BEFORE '2024-03-27 00:00:00';

--enable redo log
ALTER INSTANCE ENABLE INNODB REDO_LOG;

--persistent connections
SELECT * FROM INFORMATION_SCHEMA.processlist WHERE command = 'Sleep';

--create random password for users
UPDATE users SET passwd=substring(MD5(RAND()),1,20) WHERE userid NOT IN (1);

--busy connections
SELECT * FROM INFORMATION_SCHEMA.PROCESSLIST WHERE COMMAND != 'Sleep' AND TIME > 1 AND USER != 'EVENT_SCHEDULER' ORDER BY TIME DESC, ID;

--mimic SHOW SLAVE STATUS
SELECT t.PROCESSLIST_TIME, t.* FROM performance_schema.threads t WHERE NAME IN('thread/sql/slave_io', 'thread/sql/slave_sql');
SELECT t.PROCESSLIST_TIME, t.* FROM performance_schema.threads t;

