--long running queries. postgres. PostgreSQL
SELECT pid, user, pg_stat_activity.query_start,
NOW() - pg_stat_activity.query_start AS query_time, query, state, wait_event_type, wait_event
FROM pg_stat_activity
WHERE (NOW() - pg_stat_activity.query_start) > interval '3 seconds';

--monitor process. postgres. PostgreSQL
SELECT * FROM pg_stat_activity WHERE state != 'idle';

--what is minor version of Zabbix
SELECT * FROM dbversion;

--process list without any condition. PostgreSQL
SELECT datid,datname,pid,usesysid,usename,client_addr,client_port,backend_start,query_start,state_change,wait_event_type,wait_event,state,query_id FROM pg_stat_activity;

--size of hyper tables. size of biggest tables
SELECT *, pg_size_pretty(total_bytes) AS total, pg_size_pretty(index_bytes) AS index, pg_size_pretty(toast_bytes) AS toast, pg_size_pretty(table_bytes) AS table
FROM (SELECT *, total_bytes-index_bytes-coalesce(toast_bytes, 0) AS table_bytes
FROM (SELECT c.oid, nspname AS table_schema, relname AS table_name, c.reltuples AS row_estimate, pg_total_relation_size(c.oid) AS total_bytes, pg_indexes_size(c.oid) AS index_bytes, pg_total_relation_size(reltoastrelid) AS toast_bytes
FROM pg_class c
LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE relkind = 'r' ) a) a
ORDER BY 5 DESC LIMIT 500;

-- biggest tables
SELECT relname AS table_name, pg_size_pretty(pg_total_relation_size(relid)) AS total_size
FROM pg_catalog.pg_stat_user_tables
ORDER BY pg_total_relation_size(relid) DESC LIMIT 10;

