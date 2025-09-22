--How many values is in the backlog. does not work on oracle proxy becuase of LIMIT. Zabbix 4.0, 5.0, 6.0
SELECT MAX(id)-(SELECT nextid FROM ids WHERE table_name='proxy_history' LIMIT 1) FROM proxy_history;

--skip all cached LLD rules
DELETE FROM proxy_history WHERE itemid IN (SELECT itemid FROM items WHERE flags=1);

--bombards zabbix trapper and zabbix_sender
SELECT proxy_history.clock, items.hostid, items.key_, proxy_history.value
FROM proxy_history, items
WHERE items.itemid = proxy_history.itemid
AND items.type = 2
LIMIT 10;

--context in sqlite3 proxy database
SELECT SUM(LENGTH(t1.value)),items.key_,t1.flags,hosts.host FROM (
SELECT * FROM proxy_history LIMIT 9999
) t1
JOIN items ON items.itemid=t1.itemid
JOIN hosts ON hosts.hostid=items.hostid
GROUP BY 2,3,4 ORDER BY 1 DESC LIMIT 10;

--delete data which has been sent already
DELETE FROM proxy_history WHERE id < (SELECT nextid FROM ids WHERE table_name = "proxy_history" LIMIT 1);

--show LLD JSON data
SELECT items.hostid, items.hostid, items.key_, proxy_history.value FROM proxy_history, items WHERE proxy_history.itemid=items.itemid AND items.flags=1 ORDER BY clock ASC;

--which host are giving the biggest values
SELECT h.host,i.key_,max(length(ph.value)) as max_length,count(*)
FROM proxy_history ph
JOIN items i ON ph.itemid = i.itemid
JOIN hosts h ON (h.hostid = i.hostid)
WHERE clock >= UNIX_TIMESTAMP(NOW() - INTERVAL 2 HOUR)
GROUP BY h.host,i.key_ ORDER BY max_length DESC LIMIT 100;

--fastest way to show stats
SELECT SUM(LENGTH(value)),itemid FROM (
SELECT * FROM proxy_history LIMIT 10000
) t1
GROUP BY 2 ORDER BY 1 DESC LIMIT 9;

--stats with URL
SELECT SUM(LENGTH(value)),
CONCAT('history.php?itemids%5B0%5D=',itemid,'&action=showlatest') AS 'URL' FROM (
SELECT * FROM proxy_history WHERE flags<>1 LIMIT 10000
) t1
GROUP BY 2 ORDER BY 1 DESC LIMIT 9;

--biggest values
SELECT itemid,flags,
COUNT(*),
AVG(LENGTH(value))
FROM proxy_history
GROUP BY 1,2 ORDER BY 4 DESC LIMIT 20;

--most occurences
SELECT itemid,flags,
COUNT(*),
AVG(LENGTH(value))
FROM proxy_history
GROUP BY 1,2 ORDER BY 3 DESC LIMIT 20;

--biggest values and occurences
SELECT itemid,flags,COUNT(*) * AVG(LENGTH(value)) FROM proxy_history GROUP BY 1,2 ORDER BY 3 DESC LIMIT 20;

--Optimal query to identify data overload. Zabbix 4.0, 5.0, 6.0
SELECT itemid,
COUNT(*),
AVG(LENGTH(value))
FROM proxy_history 
WHERE proxy_history.clock > UNIX_TIMESTAMP(NOW()-INTERVAL 1 HOUR)
GROUP BY 1 ORDER BY 2,3 DESC;

--proxy with MySQL. print URLs for latest data page for the incomming big data. Zabbix 4.0, 5.0, 6.0
SELECT
LENGTH(value),
CONCAT('history.php?itemids%5B0%5D=', proxy_history.itemid,'&action=showlatest') AS 'URL'
FROM proxy_history
JOIN items ON (items.itemid=proxy_history.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE LENGTH(value) > 60000;

--check big LLD rules and its frequency based on clock. Zabbix 4.0, 5.0, 6.0
SELECT
clock,
hosts.host,
items.key_,
LENGTH(value)
FROM proxy_history
JOIN items ON (items.itemid=proxy_history.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE items.flags=1
AND LENGTH(value) > 6000;

--LLD rules. Zabbix 4.0, 5.0, 6.0
SELECT
items.key_,
COUNT(*),
AVG(LENGTH(value))
FROM proxy_history, items
WHERE proxy_history.itemid=items.itemid
AND items.flags=1
GROUP BY 1 ORDER BY 3,2;

