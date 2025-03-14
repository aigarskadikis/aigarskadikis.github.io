--discard all users which is using frontend. Zabbix 3.0, 3.2, 3.4, 4.0, 4.2, 4.4, 5.0, 5.2, 5.4, 6.0, 6.2
DELETE FROM session;

--delete all events comming from specific trigger id. Zabbix 4.0, 5.0
DELETE
FROM events
WHERE events.source=0
AND events.object=0
AND events.objectid=987654321;

--delete old sessions. PostgreSQL. Zabbix 6.0
DELETE FROM sessions WHERE lastaccess < EXTRACT(EPOCH FROM NOW() - INTERVAL '10 days');

--delete discovery, autoregistration and internal events
DELETE FROM events WHERE source IN (1,2,3) LIMIT 1;
DELETE FROM events WHERE source IN (1,2,3) LIMIT 10;
DELETE FROM events WHERE source IN (1,2,3) LIMIT 100;

--delete child events which was closed by global correlation. Zabbix 5.0
DELETE e
FROM events e
LEFT JOIN event_recovery ON (event_recovery.eventid=e.eventid)
WHERE event_recovery.c_eventid IS NOT NULL
AND e.clock < 1234;

--delete dublicate values per itemid. Zabbix 5.0
DELETE t1
FROM history_text t1
INNER JOIN history_text t2
WHERE t1.itemid=382198
AND t1.clock < t2.clock
AND t1.value=t2.value
AND t1.itemid=t2.itemid;

--remove evidence about all failed actions. Zabbix 5.0
DELETE FROM alerts WHERE status=2;

--delete all dublicate metrics in history_text. Zabbix 5.0
DELETE t1
FROM history_text t1
INNER JOIN history_text t2
WHERE t1.clock < t2.clock
AND t1.value=t2.value
AND t1.itemid=t2.itemid;

--delete all dublicate metrics in history. Zabbix 5.0
DELETE t1
FROM history_str t1
INNER JOIN history_str t2
WHERE t1.clock < t2.clock
AND t1.value=t2.value
AND t1.itemid=t2.itemid;

--remove data for 'history_text' where 'Do not keep history'. Zabbix 5.0
DELETE
FROM history_text WHERE itemid IN (
SELECT items.itemid FROM items, hosts
WHERE hosts.hostid=items.hostid
AND hosts.status IN (0,1)
AND items.value_type=4
AND items.flags IN (0,4)
AND items.history IN ('0')
);

--remove data for 'history_str' where 'Do not keep history'. Zabbix 5.0
DELETE FROM history_str WHERE itemid IN (
SELECT items.itemid FROM items, hosts
WHERE hosts.hostid=items.hostid
AND hosts.status IN (0,1)
AND items.value_type=1
AND items.flags IN (0,4)
AND items.history IN ('0')
);

--scan 'history_text' table and accidentally stored integers, decimal numbers, log entries and short strings. Zabbix 3.0, 3.2, 3.4, 4.0, 4.2, 4.4, 5.0, 5.2, 5.4, 6.0, 6.2
DELETE FROM history_text WHERE itemid NOT IN (SELECT itemid FROM items WHERE value_type=4);
DELETE FROM history_text WHERE itemid IN (SELECT itemid FROM items WHERE value_type<>4);

--scan 'history_str' table and accidentally stored integers, decimal numbers, log entries and long text strings. Zabbix 3.0, 3.2, 3.4, 4.0, 4.2, 4.4, 5.0, 5.2, 5.4, 6.0, 6.2
DELETE FROM history_str WHERE itemid NOT IN (SELECT itemid FROM items WHERE value_type=1);
DELETE FROM history_str WHERE itemid IN (SELECT itemid FROM items WHERE value_type<>1);

--remove repeated values per one itemid in 'history_str'. discard unchanded. Zabbix 5.0, 6.0
DELETE FROM history_str WHERE itemid=343812 AND clock IN (
SELECT clock FROM (
SELECT clock, value, r, v2 FROM (
SELECT clock, value, LEAD(value,1) OVER (order by clock) AS v2,
CASE
WHEN value <> LEAD(value,1) OVER (order by clock)
THEN value
ELSE 'zero'
END AS r
FROM history_str WHERE itemid=343812
) x2
WHERE r='zero'
) x3
WHERE v2 IS NOT NULL
);

--remove repeated values per one itemid in 'history_text'. discard unchanded. Zabbix 5.0, 6.0
DELETE FROM history_text WHERE itemid=42702 AND clock IN (
SELECT clock from (
SELECT clock, value, r, v2 FROM (
SELECT clock, value, LEAD(value,1) OVER (order by clock) AS v2,
CASE
WHEN value <> LEAD(value,1) OVER (order by clock)
THEN value
ELSE 'zero'
END AS r
FROM history_text WHERE itemid=42702
) x2
WHERE r='zero'
) x3
WHERE v2 IS NOT NULL
);

