--active problems including internal
SELECT COUNT(*), source, object, severity FROM problem GROUP BY 2,3,4 ORDER BY severity;

--unreachable ZBX host
SELECT
proxy.host AS proxy,
hosts.host,
hosts.error AS hostError,
CONCAT('hosts.php?form=update&hostid=', hosts.hostid) AS goTo
FROM hosts
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE hosts.status=0
AND LENGTH(hosts.error) > 0;

--unreachable SNMP hosts
SELECT
proxy.host AS proxy,
hosts.host,
hosts.snmp_error AS hostError,
CONCAT('hosts.php?form=update&hostid=', hosts.hostid) AS goTo
FROM hosts
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE hosts.status=0
AND LENGTH(hosts.snmp_error) > 0;

--active and disabled hosts and items
SELECT
proxy.host AS proxy,
CASE hosts.status
WHEN 0 THEN 'Active'
WHEN 1 THEN 'Disabled'
END AS host,
CASE items.status
WHEN 0 THEN 'Active'
WHEN 1 THEN 'Disabled'
END AS item,
CASE items.type
WHEN 0 THEN 'Zabbix agent'
WHEN 1 THEN 'SNMPv1 agent'
WHEN 2 THEN 'Zabbix trapper'
WHEN 3 THEN 'Simple check'
WHEN 4 THEN 'SNMPv2 agent'
WHEN 5 THEN 'Zabbix internal'
WHEN 6 THEN 'SNMPv3 agent'
WHEN 7 THEN 'Zabbix agent (active) check'
WHEN 8 THEN 'Aggregate'
WHEN 9 THEN 'HTTP test (web monitoring scenario step)'
WHEN 10 THEN 'External check'
WHEN 11 THEN 'Database monitor'
WHEN 12 THEN 'IPMI agent'
WHEN 13 THEN 'SSH agent'
WHEN 14 THEN 'TELNET agent'
WHEN 15 THEN 'Calculated'
WHEN 16 THEN 'JMX agent'
WHEN 17 THEN 'SNMP trap'
WHEN 18 THEN 'Dependent item'
WHEN 19 THEN 'HTTP agent'
WHEN 20 THEN 'SNMP agent'
WHEN 21 THEN 'Script item'
END AS type,
COUNT(*)
FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE hosts.status IN (0,1) AND items.status IN (0,1)
GROUP BY proxy.host, items.type
ORDER BY 1,2,3,4,5 DESC;

--show items by proxy
SELECT
COUNT(*) AS count,
proxy.host AS proxy,
items.type
FROM items
JOIN hosts ON (items.hostid=hosts.hostid)
JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE hosts.status=0
AND items.status=0
AND proxy.status IN (5,6)
GROUP BY 2,3
ORDER BY 2,3;

--which internal event is spamming database
SELECT
CASE object
WHEN 0 THEN 'Trigger expression'
WHEN 4 THEN 'Data collection'
WHEN 5 THEN 'LLD rule'
END AS object,
objectid,
value,
name,
COUNT(*)
FROM events
WHERE source=3
AND LENGTH(name) > 0
AND clock > UNIX_TIMESTAMP(NOW()-INTERVAL 10 DAY)
GROUP BY 1,2,3,4 ORDER BY 5 DESC LIMIT 20;

--devices and it's status
SELECT
proxy.host AS proxy,
hosts.host,
interface.ip,
interface.dns,
interface.useip,
CASE hosts.available
WHEN 0 THEN 'unknown' 
WHEN 1 THEN 'available'
WHEN 2 THEN 'down'
END AS "status",
CASE interface.type
WHEN 1 THEN 'ZBX'
WHEN 2 THEN 'SNMP'
WHEN 3 THEN 'IPMI'
WHEN 4 THEN 'JMX'
END AS "type", hosts.error
FROM hosts
JOIN interface ON interface.hostid=hosts.hostid
LEFT JOIN hosts proxy ON hosts.proxy_hostid=proxy.hostid
WHERE hosts.status=0
AND interface.main=1;

--items in use
SELECT
CASE items.type 
WHEN 0 THEN 'Zabbix agent' 
WHEN 1 THEN 'SNMPv1 agent' 
WHEN 2 THEN 'Zabbix trapper' 
WHEN 3 THEN 'Simple check' 
WHEN 4 THEN 'SNMPv2 agent' 
WHEN 5 THEN 'Zabbix internal' 
WHEN 6 THEN 'SNMPv3 agent' 
WHEN 7 THEN 'Zabbix agent (active) check' 
WHEN 8 THEN 'Aggregate' 
WHEN 9 THEN 'HTTP test (web monitoring scenario step)' 
WHEN 10 THEN 'External check' 
WHEN 11 THEN 'Database monitor' 
WHEN 12 THEN 'IPMI agent' 
WHEN 13 THEN 'SSH agent' 
WHEN 14 THEN 'TELNET agent' 
WHEN 15 THEN 'Calculated' 
WHEN 16 THEN 'JMX agent' 
WHEN 17 THEN 'SNMP trap' 
WHEN 18 THEN 'Dependent item' 
WHEN 19 THEN 'HTTP agent' 
WHEN 20 THEN 'SNMP agent' 
WHEN 21 THEN 'Script item' 
END AS type,
COUNT(*) 
FROM items 
JOIN hosts ON (hosts.hostid=items.hostid) 
WHERE hosts.status=0 
AND items.status=0 
GROUP BY items.type 
ORDER BY COUNT(*) DESC;

--all events closed by global correlation rule
SELECT
repercussion.clock,
repercussion.name,
rootCause.clock,
rootCause.name AS name
FROM events repercussion
JOIN event_recovery ON (event_recovery.eventid=repercussion.eventid)
JOIN events rootCause ON (rootCause.eventid=event_recovery.c_eventid)
WHERE event_recovery.c_eventid IS NOT NULL
ORDER BY repercussion.clock ASC;

--all active data collector items on enabled hosts
SELECT hosts.host, items.name, items.type, items.key_, items.delay
FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE hosts.status=0
AND items.status=0
ORDER BY 1,2,3,4,5;

--update interval of owner in case LLD rule is dependent item
SELECT master_itemid.key_, master_itemid.delay, COUNT(*)
FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
JOIN items master_itemid ON (master_itemid.itemid=items.master_itemid)
WHERE items.flags=1
AND hosts.status=0
AND items.status=0
AND master_itemid.status=0
AND items.type=18
GROUP BY 1,2 ORDER BY 3 DESC;

--frequency of LLD rule for enabled hosts and enabled items discoveries for only monitored hosts
SELECT type,delay,COUNT(*) FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE items.flags=1 AND hosts.status=0 AND items.status=0
GROUP BY 1,2 ORDER BY 1,2;

--How many values is in the backlog. does not work on oracle proxy becuase of LIMIT
SELECT MAX(id)-(SELECT nextid FROM ids WHERE table_name="proxy_history" LIMIT 1)
FROM proxy_history;

--Optimal query to identify data overload
SELECT itemid,
COUNT(*),
AVG(LENGTH(value))
FROM proxy_history 
WHERE proxy_history.clock > UNIX_TIMESTAMP(NOW()-INTERVAL 1 HOUR)
GROUP BY 1 ORDER BY 2,3 DESC;

--proxy with MySQL. print URLs for latest data page for the incomming big data
SELECT
LENGTH(value),
CONCAT('history.php?itemids%5B0%5D=', proxy_history.itemid,'&action=showlatest') AS 'URL'
FROM proxy_history
JOIN items ON (items.itemid=proxy_history.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE LENGTH(value) > 60000;

--check big LLD rules and its frequency based on clock
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

--LLD rules
SELECT
items.key_,
COUNT(*),
AVG(LENGTH(value))
FROM proxy_history, items
WHERE proxy_history.itemid=items.itemid
AND items.flags=1
GROUP BY 1 ORDER BY 3,2;

--discard all users which is using frontend
DELETE FROM session;

--delete all events comming from specific trigger id
DELETE
FROM events
WHERE events.source=0
AND events.object=0
AND events.objectid=987654321;

--scan 'history_text' table and accidentally stored integers, decimal numbers, log entries and short strings
DELETE FROM history_text WHERE itemid NOT IN (SELECT itemid FROM items WHERE value_type=4);
DELETE FROM history_text WHERE itemid IN (SELECT itemid FROM items WHERE value_type<>4);

--scan 'history_str' table and accidentally stored integers, decimal numbers, log entries and long text strings
DELETE FROM history_str WHERE itemid NOT IN (SELECT itemid FROM items WHERE value_type=1);
DELETE FROM history_str WHERE itemid IN (SELECT itemid FROM items WHERE value_type<>1);

