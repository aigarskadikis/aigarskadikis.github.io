--items in use
SELECT CASE items.type
WHEN 0 THEN 'Zabbix agent'
WHEN 2 THEN 'Zabbix trapper'
WHEN 3 THEN 'Simple check'
WHEN 5 THEN 'Zabbix internal'
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
END as type,COUNT(*)
FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE hosts.status=0
AND items.status=0
GROUP BY items.type
ORDER BY COUNT(*) DESC;

--determine which items report unsupported state:
SELECT COUNT(items.key_),
hosts.host,
items.key_,
item_rtdata.error
FROM events
JOIN items ON (items.itemid=events.objectid)
JOIN hosts ON (hosts.hostid=items.hostid)
JOIN item_rtdata ON (item_rtdata.itemid=items.itemid)
WHERE source=3
AND object=4
AND items.status=0
AND items.flags IN (0,1,4)
AND LENGTH(item_rtdata.error)>0
GROUP BY hosts.host,items.key_,
item_rtdata.error
ORDER BY COUNT(items.key_);

--list all function names together with arguments
SELECT functions.name, functions.parameter, COUNT(*)
FROM functions
JOIN items ON (items.itemid = functions.itemid)
JOIN hosts ON (items.hostid = hosts.hostid)
JOIN triggers ON (triggers.triggerid=functions.triggerid)
WHERE hosts.status=0
AND items.status=0
AND triggers.status=0
GROUP BY 1,2
ORDER BY 1;

--Sumarize DB permissions
SELECT CONCAT("'",user,"'@'",host,"'") FROM mysql.user;

--session concat limit
SET SESSION group_concat_max_len = 1000000;

--catter host inventory
SELECT host_inventory.macaddress_a,GROUP_CONCAT(hosts.host) FROM host_inventory
JOIN hosts ON (hosts.hostid=host_inventory.hostid)
WHERE hosts.status=0 AND host_inventory.macaddress_a LIKE '%enterprises%'
GROUP BY host_inventory.macaddress_a;

