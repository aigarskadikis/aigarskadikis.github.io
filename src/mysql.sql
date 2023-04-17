--ssl connection information for MySQL
SELECT sbt.variable_value AS tls_version, t2.variable_value AS cipher,
processlist_user AS user, processlist_host AS host
FROM performance_schema.status_by_thread AS sbt
JOIN performance_schema.threads AS t ON t.thread_id = sbt.thread_id
JOIN performance_schema.status_by_thread AS t2 ON t2.thread_id = t.thread_id
WHERE sbt.variable_name = 'Ssl_version' and t2.variable_name = 'Ssl_cipher' ORDER BY tls_version;

