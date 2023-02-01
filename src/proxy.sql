--How many values is in the backlog. does not work on oracle proxy becuase of LIMIT
SELECT MAX(id)-(SELECT nextid FROM ids WHERE table_name="proxy_history" LIMIT 1) FROM proxy_history;

--Optimal query to identify data overload
SELECT itemid,
COUNT(*),
AVG(LENGTH(value))
FROM proxy_history 
WHERE proxy_history.clock > UNIX_TIMESTAMP(NOW()-INTERVAL 1 HOUR)
GROUP BY 1 ORDER BY 2,3 DESC;

--proxy with MySQL. print URLs for latest data page for the incomming big data
SELECT LENGTH(value),
CONCAT('history.php?itemids%5B0%5D=',proxy_history.itemid,'&action=showlatest' ) AS 'URL'
FROM proxy_history
JOIN items ON (items.itemid=proxy_history.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE LENGTH(value) > 60000;

--check big LLD rules and its frequency based on clock
SELECT clock, hosts.host, items.key_,
LENGTH(value)
FROM proxy_history
JOIN items ON (items.itemid=proxy_history.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE items.flags=1
AND LENGTH(value) > 6000;

--LLD rules
SELECT items.key_,
COUNT(*),
AVG(LENGTH(value))
FROM proxy_history, items
WHERE proxy_history.itemid=items.itemid
AND items.flags=1
GROUP BY 1 ORDER BY 3,2;

