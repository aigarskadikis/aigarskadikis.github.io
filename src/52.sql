--how many user groups has debug mode 1
SELECT COUNT(*) FROM usrgrp WHERE debug_mode=1;

--hosts having problems with passive checks
SELECT proxy.host AS proxy,hosts.host,hosts.error FROM hosts
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE hosts.status=0 AND LENGTH(hosts.error)>0;

--show items by proxy
SELECT COUNT(*),proxy.host AS proxy,items.type
FROM items
JOIN hosts ON (items.hostid=hosts.hostid)
JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE hosts.status = 0
AND items.status = 0
AND proxy.status IN (5,6)
GROUP BY 2,3
ORDER BY 2,3;

--devices and it's status
SELECT proxy.host AS proxy, hosts.host, interface.ip, interface.dns, interface.useip,
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
END AS "type",
hosts.error
FROM hosts
JOIN interface ON interface.hostid=hosts.hostid
LEFT JOIN hosts proxy ON hosts.proxy_hostid=proxy.hostid
WHERE hosts.status=0
AND interface.main=1;

--items in use
SELECT CASE items.type 
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
END AS type,COUNT(*) 
FROM items 
JOIN hosts ON (hosts.hostid=items.hostid) 
WHERE hosts.status=0 
AND items.status=0 
GROUP BY items.type 
ORDER BY COUNT(*) DESC;

--owner of LLD dependent item. What is interval for owner
SELECT master_itemid.key_,master_itemid.delay,COUNT(*) FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
JOIN items master_itemid ON (master_itemid.itemid=items.master_itemid)
WHERE items.flags=1 AND hosts.status=0 AND items.status=0 AND master_itemid.status=0 AND items.type=18
GROUP BY 1,2 ORDER BY 3 DESC;

--enabled and disabled LLD items, its key
SELECT items.type,items.key_,items.delay,items.status,COUNT(*) FROM items
JOIN hosts ON (hosts.hostid=items.hostid) WHERE items.flags=1 AND hosts.status=0
GROUP BY 1,2,3,4 ORDER BY 1,2,3,4;

