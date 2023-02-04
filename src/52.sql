--how many user groups has debug mode 1
SELECT COUNT(*) FROM usrgrp WHERE debug_mode=1;

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

--owner of LLD dependent item. What is interval for owner
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

--enabled and disabled LLD items, its key
SELECT
items.type,
items.key_,
items.delay,
items.status,
COUNT(*) AS count
FROM items, hosts
WHERE hosts.hostid=items.hostid
AND items.flags=1
AND hosts.status=0
GROUP BY 1,2,3,4 ORDER BY 1,2,3,4;

--Zabbix agent hitting the central server
SELECT
hosts.host AS proxy,
CASE autoreg_host.flags
WHEN 0 THEN 'IP address, do not update host interface'
WHEN 1 THEN 'IP address, update default host interface'
WHEN 2 THEN 'DNS name, update default host interface'
END AS "connect using",
CASE autoreg_host.tls_accepted
WHEN 1 THEN 'Unencrypted'
WHEN 2 THEN 'TLS with PSK'
END AS "Encryption",
COUNT(*) AS "amount of hosts"
FROM autoreg_host
JOIN hosts ON (hosts.hostid=autoreg_host.proxy_hostid)
GROUP BY 1,2,3 ORDER BY 1,2,3;

--PostgreSQL
SELECT
proxy.host AS proxy,
hosts.host,
ARRAY_TO_STRING(ARRAY_AGG(template.host),', ') AS templates
FROM hosts
JOIN hosts_templates ON (hosts_templates.hostid=hosts.hostid)
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
LEFT JOIN hosts template ON (hosts_templates.templateid=template.hostid)
WHERE hosts.status IN (0,1)
AND hosts.flags=0
GROUP BY 1,2 ORDER BY 1,3,2;

--MySQL
SELECT
proxy.host AS proxy,
hosts.host,
GROUP_CONCAT(template.host SEPARATOR ', ') AS templates
FROM hosts
JOIN hosts_templates ON (hosts_templates.hostid=hosts.hostid)
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
LEFT JOIN hosts template ON (hosts_templates.templateid=template.hostid)
WHERE hosts.status IN (0,1)
AND hosts.flags=0
GROUP BY 1,2 ORDER BY 1,3,2;

--For items which are currently disabled, clean the error message in database. This will help to locate what really is not working and why
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

--For items which are currently disabled, reset the state as supported. This will help to locate what really is not working and why. Item will remain disabled
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

--print error message for enabled hosts and enabled data collector items
SELECT
hosts.host,
items.name,
item_rtdata.error AS error
FROM item_rtdata, items, hosts
WHERE item_rtdata.state=1
AND hosts.status=0
AND items.status=0
AND item_rtdata.itemid=items.itemid
AND hosts.hostid=items.hostid;

--identify item membership. usefull if that is master item
SELECT
proxy.host AS proxy,
hosts.host,
items.name,
items.key_,
items.delay AS delay
FROM hosts
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
JOIN items ON (items.hostid=hosts.hostid)
WHERE items.itemid IN (12345,5678);

