--how many user groups has debug mode 1
SELECT COUNT(*) FROM usrgrp WHERE debug_mode=1;

--active problems, including Zabbix internal problems (item unsupported, trigger unsupported). works on Zabbix 4.0, 5.0, 6.0, 6,2
SELECT COUNT(*),source,object,severity FROM problem GROUP BY 2,3,4 ORDER BY severity;

--hosts having problems with passive checks. Zabbix 4.0 till 5.2
SELECT proxy.host AS proxy,hosts.host,hosts.error FROM hosts LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid) WHERE LENGTH(hosts.error)>0;

--check Zabbix 6.0 native HA heartbeat. When was the last time the node reported back. Good way to ensure if DB replication is responsive
SELECT * FROM ha_node;

--count of events. All version of Zabbix
SELECT COUNT(*),source FROM events GROUP BY source;

--show items by proxy. works from Zabbix 3.0 till 6.2
SELECT COUNT(*),proxy.host AS proxy,items.type
FROM items
JOIN hosts ON (items.hostid=hosts.hostid)
JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE hosts.status = 0
AND items.status = 0
AND proxy.status IN (5,6)
GROUP BY 2,3
ORDER BY 2,3;

--which internal event is spamming database, Zabbix 4.0, Zabbix 5.0. Do not work with 3.4
SELECT
CASE object
WHEN 0 THEN 'Trigger expression'
WHEN 4 THEN 'Data collection'
WHEN 5 THEN 'LLD rule'
END AS object,
objectid,value,name,COUNT(*) FROM events
WHERE source=3 AND LENGTH(name)>0
AND clock > UNIX_TIMESTAMP(NOW()-INTERVAL 10 DAY)
GROUP BY 1,2,3,4 ORDER BY 5 DESC LIMIT 20;

--difference between installed macros between host VS template VS nested/child templates
SELECT parent.host AS 'Parent', hm1.macro,hm1.value,child.host AS 'Child',hm2.macro,hm2.value
FROM hosts parent, hosts child, hosts_templates rel, hostmacro hm1, hostmacro hm2
WHERE parent.hostid=rel.hostid AND child.hostid=rel.templateid
AND hm1.hostid = parent.hostid AND hm2.hostid = child.hostid
AND hm1.macro = hm2.macro
AND hm1.value <> hm2.value;

--detect if there is difference between template macro and host macro. this is surface level detection. it does not take care of values between nested templates
SELECT b.host,
hm2.macro,
hm2.value AS 'template value',
h.host,
hm1.macro,
hm1.value AS 'host value'
FROM hosts_templates,
hosts h,
hosts b,
hostmacro hm1,
hostmacro hm2,
interface
WHERE hosts_templates.hostid = h.hostid
AND hosts_templates.templateid = b.hostid
AND interface.hostid = h.hostid
AND hm1.hostid = h.hostid
AND hm2.hostid = hosts_templates.templateid
AND hm1.macro = hm2.macro
AND hm1.value <> hm2.value;

--devices and it's status. Works from Zabbix 3.0 till 5.2
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

--exceptions in update interval. when a user install a custom update frequency in a host level and the frequency differs from template level. This query also detects difference between nested templates
SELECT h1.host AS exceptionInstalled,
i1.name,
i1.key_,
i1.delay,
h2.host AS differesFromTemplate,
i2.name,
i2.key_,
i2.delay
FROM items i1
JOIN items i2 ON (i2.itemid=i1.templateid)
JOIN hosts h1 ON (h1.hostid=i1.hostid)
JOIN hosts h2 ON (h2.hostid=i2.hostid)
WHERE i1.delay<>i2.delay;

--all events closed by global correlation rule. Zabbix 4.0, 5.0, 6.0
SELECT
repercussion.clock,
repercussion.name,
rootCause.clock,
rootCause.name
FROM events repercussion
JOIN event_recovery ON (event_recovery.eventid=repercussion.eventid)
JOIN events rootCause ON (rootCause.eventid=event_recovery.c_eventid)
WHERE event_recovery.c_eventid IS NOT NULL
ORDER BY repercussion.clock ASC;

--all active data collector items on enabled hosts. Zabbix 3.0, 4.0, 5.0, 6.0
SELECT
hosts.host,
items.name,
items.type,
items.key_,
items.delay
FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE hosts.status=0
AND items.status=0
ORDER BY 1,2,3,4,5;

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

--owner of LLD dependent item. What is interval for owner. Zabbix 4.0 => 6.2
SELECT master_itemid.key_,master_itemid.delay,COUNT(*) FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
JOIN items master_itemid ON (master_itemid.itemid=items.master_itemid)
WHERE items.flags=1 AND hosts.status=0 AND items.status=0 AND master_itemid.status=0 AND items.type=18
GROUP BY 1,2 ORDER BY 3 DESC;

--frequency of LLD rule for enabled hosts and enabled items discoveries for only monitored hosts. Zabbix 4.0 => 6.2
SELECT type,delay,COUNT(*) FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE items.flags=1 AND hosts.status=0 AND items.status=0
GROUP BY 1,2 ORDER BY 1,2;

--host inventory
SELECT host_inventory.macaddress_a,GROUP_CONCAT(hosts.host) FROM host_inventory
JOIN hosts ON (hosts.hostid=host_inventory.hostid)
WHERE hosts.status=0 AND host_inventory.macaddress_a LIKE '%enterprises%'
GROUP BY host_inventory.macaddress_a;

--remove metrics where there are no item definition anymore
DELETE FROM trends WHERE itemid NOT IN (SELECT itemid FROM items);
DELETE FROM trends_uint WHERE itemid NOT IN (SELECT itemid FROM items);
DELETE FROM history_text WHERE itemid NOT IN (SELECT itemid FROM items);
DELETE FROM history_str WHERE itemid NOT IN (SELECT itemid FROM items);
DELETE FROM history_log WHERE itemid NOT IN (SELECT itemid FROM items);
DELETE FROM history WHERE itemid NOT IN (SELECT itemid FROM items);

