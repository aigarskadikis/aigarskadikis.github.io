--How many values is in the backlog. does not work on oracle proxy becuase of LIMIT. Zabbix 4.0, 5.0, 6.0
SELECT MAX(id)-(SELECT nextid FROM ids WHERE table_name='proxy_history' LIMIT 1) FROM proxy_history;

--skip all cached LLD rules
DELETE FROM proxy_history WHERE itemid IN (SELECT itemid FROM items WHERE flags=1);

--delete data which has been sent already
DELETE FROM proxy_history WHERE id < (SELECT nextid FROM ids WHERE table_name = "proxy_history" LIMIT 1);

--show LLD JSON data
SELECT items.hostid, items.hostid, items.key_, proxy_history.value FROM proxy_history, items WHERE proxy_history.itemid=items.itemid AND items.flags=1 ORDER BY clock ASC;

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

