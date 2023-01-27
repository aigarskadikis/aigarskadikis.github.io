--discard all users which is using frontend
DELETE FROM session;

--delete all events comming from specific trigger id. only execute if trigger is not in problem state
DELETE FROM events WHERE events.source=0 AND events.object=0 AND events.objectid=987654321;

--delete discovery, autoregistration and internal events
DELETE FROM events WHERE source IN (1,2,3) LIMIT 1;
DELETE FROM events WHERE source IN (1,2,3) LIMIT 10;
DELETE FROM events WHERE source IN (1,2,3) LIMIT 100;

--delete child events which was closed by global correlation
DELETE e FROM events e
LEFT JOIN event_recovery ON (event_recovery.eventid=e.eventid)
WHERE event_recovery.c_eventid IS NOT NULL
AND e.clock < 1234;

--delete dublicate values per itemid. keep the newest one. this is NOT discard and unchanged!
DELETE t1 FROM history_text t1
INNER JOIN history_text t2
WHERE t1.itemid=382198 AND
t1.clock < t2.clock AND
t1.value = t2.value AND
t1.itemid = t2.itemid;

--delete all dublicate metrics in history. useful if table used for backups
DELETE t1 FROM history_text t1
INNER JOIN history_text t2
WHERE t1.clock < t2.clock AND
t1.value = t2.value AND
t1.itemid = t2.itemid;

--delete all dublicate metrics in history. useful if table used for backups
DELETE t1 FROM history_str t1
INNER JOIN history_str t2
WHERE t1.clock < t2.clock AND
t1.value = t2.value AND
t1.itemid = t2.itemid;

--remove data for 'history_text' for items where 'Do not keep history' is configred later than initially
DELETE FROM history_text WHERE itemid IN (
SELECT items.itemid FROM items, hosts
WHERE hosts.hostid=items.hostid
AND hosts.status IN (0,1)
AND items.value_type=4
AND items.flags IN (0,4)
AND items.history IN ('0')
);

--remove data for 'history_str' for items where 'Do not keep history' is configred later than initially
DELETE FROM history_str WHERE itemid IN (
SELECT items.itemid FROM items, hosts
WHERE hosts.hostid=items.hostid
AND hosts.status IN (0,1)
AND items.value_type=1
AND items.flags IN (0,4)
AND items.history IN ('0')
);

--scan 'history_text' table and accidentally stored integers, decimal numbers, log entries and short strings
DELETE FROM history_text WHERE itemid NOT IN (SELECT itemid FROM items WHERE value_type=4);
DELETE FROM history_text WHERE itemid IN (SELECT itemid FROM items WHERE value_type<>4);

--scan 'history_str' table and accidentally stored integers, decimal numbers, log entries and long text strings
DELETE FROM history_str WHERE itemid NOT IN (SELECT itemid FROM items WHERE value_type=1);
DELETE FROM history_str WHERE itemid IN (SELECT itemid FROM items WHERE value_type<>1);

