--long running queries. postgres. PostgreSQL
SELECT pid, user, pg_stat_activity.query_start,
NOW() - pg_stat_activity.query_start AS query_time, query, state, wait_event_type, wait_event
FROM pg_stat_activity
WHERE (NOW() - pg_stat_activity.query_start) > interval '3 seconds';

--monitor process. postgres. PostgreSQL
SELECT * FROM pg_stat_activity WHERE state != 'idle';

--what is minor version of Zabbix
SELECT * FROM dbversion;

