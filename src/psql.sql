--long running queries. postgres. PostgreSQL
SELECT pid, user, pg_stat_activity.query_start,
NOW() - pg_stat_activity.query_start AS query_time, query, state, wait_event_type, wait_event
FROM pg_stat_activity
WHERE (NOW() - pg_stat_activity.query_start) > interval '3 seconds';

--PostgreSQL, queries more than 100 seconds, process list
SELECT pid, user, pg_stat_activity.query_start,
NOW() - pg_stat_activity.query_start AS query_time, query, state, wait_event_type, wait_event
FROM pg_stat_activity
WHERE (NOW() - pg_stat_activity.query_start) > interval '100 seconds';

--cancel frontend PIDs which run longer than 30 seconds
SELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE (NOW() - pg_stat_activity.query_start) > interval '30 seconds' AND query like 'SELECT%';

--validate if chunk size is alligned with the TimescaleDB recommendation
WITH chunk_sizes AS ( SELECT chunk_schema || '.' || chunk_name AS chunk, hypertable_schema || '.' || hypertable_name AS hypertable, pg_table_size(quote_ident(chunk_schema) || '.' || quote_ident(chunk_name)) AS size_bytes FROM timescaledb_information.chunks ), ranked_chunks AS ( SELECT chunk, hypertable, pg_size_pretty(size_bytes) AS total_size, size_bytes, ROW_NUMBER() OVER (PARTITION BY hypertable ORDER BY size_bytes DESC) AS rn FROM chunk_sizes ), top_chunks AS ( SELECT hypertable, chunk, total_size, size_bytes FROM ranked_chunks WHERE rn = 1 ), sum_row AS ( SELECT 'TOTAL' AS hypertable, NULL AS chunk, pg_size_pretty(SUM(size_bytes)) AS total_size, SUM(size_bytes) AS size_bytes FROM top_chunks ) SELECT hypertable, chunk, total_size FROM top_chunks UNION ALL SELECT hypertable, chunk, total_size FROM sum_row;

--PostgreSQL, current state of currently running vacuum
SELECT * FROM pg_stat_progress_vacuum ;

--PostgreSQL, queries more than 300 seconds, process list
SELECT pid, user, pg_stat_activity.query_start,
NOW() - pg_stat_activity.query_start AS query_time, query, state, wait_event_type, wait_event
FROM pg_stat_activity
WHERE (NOW() - pg_stat_activity.query_start) > interval '300 seconds';

--PostgreSQL, vacuum, autovacuum situation
SELECT schemaname, relname, n_live_tup, n_dead_tup, last_autovacuum
FROM pg_stat_all_tables WHERE n_dead_tup > 0
ORDER BY n_dead_tup DESC;

--PostgreSQL, size of hypertables
SELECT table_name, pg_size_pretty(pg_total_relation_size(quote_ident(table_name))), pg_total_relation_size(quote_ident(table_name))
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY 3 DESC;

--reset owner
ALTER TABLE history OWNER TO zabbix;
ALTER TABLE history_uint OWNER TO zabbix;
ALTER TABLE history_str OWNER TO zabbix;
ALTER TABLE history_log OWNER TO zabbix;
ALTER TABLE history_text OWNER TO zabbix;
ALTER TABLE trends OWNER TO zabbix;
ALTER TABLE trends_uint OWNER TO zabbix;
ALTER TABLE history_bin OWNER TO zabbix;

--update eventlog entries
WITH deleted_rows AS (
DELETE FROM history_log
WHERE itemid IN (
SELECT history_log.itemid
FROM history_log
JOIN items ON history_log.itemid = items.itemid
JOIN hosts ON items.hostid = hosts.hostid
WHERE items.key_ LIKE 'eventlog%'
AND items.status = 0 AND items.flags IN (0,4) AND hosts.status = 0 AND hosts.flags IN (0,4)
)
RETURNING itemid, timestamp, source, severity, value, logeventid, ns
)
INSERT INTO history_log (itemid, clock, timestamp, source, severity, value, logeventid, ns)
SELECT itemid, timestamp, timestamp, source, severity, value, logeventid, ns
FROM deleted_rows;

--monitor process. postgres. PostgreSQL
SELECT * FROM pg_stat_activity WHERE state != 'idle';

--what is minor version of Zabbix
SELECT * FROM dbversion;

--remove old sessions in PostgreSQL. Zabbix 7.0
DELETE FROM sessions WHERE lastaccess < EXTRACT(EPOCH FROM NOW() - INTERVAL '24 hours');

--crear PostgreSQL queries
SELECT pg_cancel_backend(pid) FROM pg_stat_activity WHERE state = 'active' and pid <> pg_backend_pid();

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

--relation between hyper table and table
select * from _timescaledb_catalog.hypertable;

--version of extension
SELECT * FROM pg_extension;

