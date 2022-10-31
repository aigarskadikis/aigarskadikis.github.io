--active problems, including Zabbix internal problems (item unsupported, trigger unsupported)
SELECT COUNT(*),source,object,severity FROM problem GROUP BY 2,3,4 ORDER BY severity;

--hosts having problems with passive checks
SELECT proxy.host AS proxy,hosts.host,interface.error
FROM hosts LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
JOIN interface ON (interface.hostid=hosts.hostid)
WHERE LENGTH(interface.error)>0;

--non-working external scripts
SELECT hosts.host,items.key_,item_rtdata.error FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
JOIN item_rtdata ON (items.itemid=item_rtdata.itemid)
WHERE hosts.status=0 AND items.status=0 AND items.type=10
AND LENGTH(item_rtdata.error)>0;

--Check native HA heartbeat
SELECT * FROM ha_node;

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

--difference between installed macros between host VS template VS nested/child templates
SELECT parent.host AS Parent, hm1.macro AS macro1, hm1.value AS value1,
child.host AS Child, hm2.macro AS macro2, hm2.value AS value2
FROM hosts parent, hosts child, hosts_templates rel, hostmacro hm1, hostmacro hm2
WHERE parent.hostid=rel.hostid AND child.hostid=rel.templateid
AND hm1.hostid = parent.hostid AND hm2.hostid = child.hostid
AND hm1.macro = hm2.macro
AND hm1.value <> hm2.value;

--detect if there is difference between template macro and host macro. this is surface level detection. it does not take care of values between nested templates
SELECT b.host,
hm2.macro,
hm2.value AS templateValue,
h.host,
hm1.macro,
hm1.value AS hostValue
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

--all events closed by global correlation rule
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

--all active data collector items on enabled hosts
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

