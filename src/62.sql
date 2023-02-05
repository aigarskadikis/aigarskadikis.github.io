--active problems including internal
SELECT COUNT(*), source, object, severity FROM problem GROUP BY 2,3,4 ORDER BY severity;

--non-working external scripts
SELECT
hosts.host,
items.key_,
item_rtdata.error
FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
JOIN item_rtdata ON (items.itemid=item_rtdata.itemid)
WHERE hosts.status=0
AND items.status=0
AND items.type=10
AND LENGTH(item_rtdata.error) > 0;

--Check native HA heartbeat
SELECT * FROM ha_node;

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

--Host behind proxy 'z62prx' where interface is not healthy. Host is down
SELECT
hosts.host,
interface.error
FROM interface
JOIN hosts ON (hosts.hostid=interface.hostid)
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE interface.available=2
AND hosts.status=0
AND proxy.host='z62prx';

--Host/interface errors per all hosts behind proxy
SELECT
proxy.host,
hosts.host,
interface.error
FROM interface
JOIN hosts ON (hosts.hostid=interface.hostid)
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE interface.available=2
AND proxy.host IS NOT NULL
ORDER BY 1,2,3;

--clear error message for disabled items
UPDATE item_rtdata
SET error=''
WHERE state=1
AND itemid IN (
SELECT items.itemid
FROM items, hosts
WHERE hosts.hostid=items.hostid
AND hosts.status=0
AND items.status=1
);

--set state as supported for disabled items
UPDATE item_rtdata
SET state=0
WHERE state=1
AND itemid IN (
SELECT items.itemid
FROM items, hosts
WHERE hosts.hostid=items.hostid
AND hosts.status=0
AND items.status=1
);

--print error active data collector items
SELECT
hosts.host,
items.name,
item_rtdata.error AS error
FROM items, item_rtdata, hosts
WHERE item_rtdata.state=1
AND hosts.status=0
AND items.status=0
AND item_rtdata.itemid=items.itemid
AND hosts.hostid=items.hostid;

--unique items keys behind proxy
SELECT
proxy.host AS proxy,
items.key_,
COUNT(*) AS count
FROM hosts
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
JOIN items ON (items.hostid=hosts.hostid)
WHERE hosts.status=0
AND items.status=0
AND items.flags<>2
GROUP BY 1,2
ORDER BY 3 ASC;

--discard all users which is using frontend
DELETE FROM session;

--scan 'history_text' table and accidentally stored integers, decimal numbers, log entries and short strings
DELETE FROM history_text WHERE itemid NOT IN (SELECT itemid FROM items WHERE value_type=4);
DELETE FROM history_text WHERE itemid IN (SELECT itemid FROM items WHERE value_type<>4);

--scan 'history_str' table and accidentally stored integers, decimal numbers, log entries and long text strings
DELETE FROM history_str WHERE itemid NOT IN (SELECT itemid FROM items WHERE value_type=1);
DELETE FROM history_str WHERE itemid IN (SELECT itemid FROM items WHERE value_type<>1);

