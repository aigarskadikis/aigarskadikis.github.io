--how many user groups has debug mode 1. Zabbix 5.0, 5.2
SELECT COUNT(*) FROM usrgrp WHERE debug_mode=1;

--active problems, including Zabbix internal problems (item unsupported, trigger unsupported). works on Zabbix 4.0, 5.0, 6.0, 6,2
SELECT COUNT(*),source,object,severity FROM problem GROUP BY 2,3,4 ORDER BY severity;

--hosts having problems with passive checks. Zabbix 4.0, 4.2, 4.4, 5.0, 5.2
SELECT proxy.host AS proxy,hosts.host,hosts.error FROM hosts LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid) WHERE LENGTH(hosts.error)>0;

--hosts having problems with passive checks. Zabbix 6.0
SELECT proxy.host AS proxy,hosts.host,interface.error
FROM hosts LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
JOIN interface ON (interface.hostid=hosts.hostid)
WHERE LENGTH(interface.error)>0;

--check Zabbix 6.0, 6.2 native HA heartbeat. When was the last time the node reported back. Good way to ensure if DB replication is responsive
SELECT * FROM ha_node;

--show items by proxy. works from Zabbix 3.0, 3.2, 3.4, 4.0, 4.2, 4.4, 5.0, 5.2, 5.4, 6.0, 6.2
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
END as type,COUNT(*) 
FROM items 
JOIN hosts ON (hosts.hostid=items.hostid) 
WHERE hosts.status=0 
AND items.status=0 
GROUP BY items.type 
ORDER BY COUNT(*) DESC;

--enabled items behind proxy on enabled hosts
SELECT proxy.host AS proxy, CASE items.type 
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
END as type,COUNT(*) 
FROM items 
JOIN hosts ON (hosts.hostid=items.hostid)
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE hosts.status=0 
AND items.status=0 
GROUP BY proxy.host, items.type 
ORDER BY 1,2,3 DESC;

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

--Zabbix 6.2. Host behind proxy 'z62prx' where interface is not healthy. Host is down
SELECT hosts.host, interface.error
FROM interface
JOIN hosts ON (hosts.hostid=interface.hostid)
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE interface.available=2 AND hosts.status=0 AND proxy.host='z62prx';

--Zabbix 6.2. Host/interface errors per all hosts behind proxy
SELECT proxy.host, hosts.host, interface.error
FROM interface
JOIN hosts ON (hosts.hostid=interface.hostid)
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE interface.available=2 AND proxy.host IS NOT NULL
ORDER BY 1,2,3;

