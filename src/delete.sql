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

--delete dublicate values in table, keep the newest one. this is NOT discard and unchanged!
DELETE t1 FROM history_text t1
INNER JOIN history_text t2
WHERE t1.itemid=382198 AND
t1.clock < t2.clock AND
t1.value = t2.value AND
t1.itemid = t2.itemid;

