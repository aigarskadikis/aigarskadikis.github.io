--how many user groups has debug mode 1
SELECT COUNT(*) FROM usrgrp WHERE debug_mode=1;

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

--nested objects and macro overrides
SELECT
hm1.macro AS Macro,
child.host AS owner,
hm2.value AS defaultValue,
parent.host AS OverrideInstalled,
hm1.value AS OverrideValue
FROM hosts parent, hosts child, hosts_templates rel, hostmacro hm1, hostmacro hm2
WHERE parent.hostid=rel.hostid
AND child.hostid=rel.templateid
AND hm1.hostid=parent.hostid
AND hm2.hostid=child.hostid
AND hm1.macro=hm2.macro
AND parent.flags=0
AND child.flags=0
AND hm1.value <> hm2.value;

--difference between template macro and host macro
SELECT
b.host,
hm2.macro,
hm2.value AS templateValue,
h.host,
hm1.macro,
hm1.value AS hostValue
FROM hosts_templates, hosts h, hosts b, hostmacro hm1, hostmacro hm2, interface
WHERE hosts_templates.hostid=h.hostid
AND hosts_templates.templateid=b.hostid
AND interface.hostid=h.hostid
AND hm1.hostid=h.hostid
AND hm2.hostid=hosts_templates.templateid
AND hm1.macro=hm2.macro
AND hm1.value <> hm2.value;

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

--exceptions in update interval
SELECT
h1.host AS exceptionInstalled,
i1.name,
i1.key_,
i1.delay,
h2.host AS differesFromTemplate,
i2.name,
i2.key_,
i2.delay AS delay
FROM items i1
JOIN items i2 ON (i2.itemid=i1.templateid)
JOIN hosts h1 ON (h1.hostid=i1.hostid)
JOIN hosts h2 ON (h2.hostid=i2.hostid)
WHERE i1.delay <> i2.delay;

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

--which dashboard has been using host group
SELECT
DISTINCT dashboard.name,
hstgrp.name
FROM widget_field
JOIN widget ON (widget.widgetid=widget_field.widgetid)
JOIN dashboard ON (dashboard.dashboardid=widget.dashboardid)
JOIN hstgrp ON (hstgrp.groupid=widget_field.value_groupid)
WHERE widget_field.value_groupid IN (2);

--Zabbix agent auto-registration probes
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

--items without a template
SELECT
hosts.host,
items.key_
FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE hosts.status=0
AND hosts.flags=0
AND items.status=0
AND items.templateid IS NULL
AND items.flags=0;

--hosts with multiple interfaces
SELECT
hosts.host
FROM interface
JOIN hosts ON (hosts.hostid=interface.hostid)
WHERE hosts.flags=0
GROUP BY hosts.host
HAVING COUNT(interface.interfaceid) > 1;

--linked template objects PostgreSQL
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

--linked templates objects MySQL
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

--which action is responsible
SELECT
FROM_UNIXTIME(events.clock) AS 'time',
CASE events.severity
WHEN 0 THEN 'NOT_CLASSIFIED'
WHEN 1 THEN 'INFORMATION'
WHEN 2 THEN 'WARNING'
WHEN 3 THEN 'AVERAGE'
WHEN 4 THEN 'HIGH'
WHEN 5 THEN 'DISASTER'
END AS severity,
CASE events.acknowledged
WHEN 0 THEN 'NO'
WHEN 1 THEN 'YES'
END AS acknowledged,
CASE events.value
WHEN 0 THEN 'OK'
WHEN 1 THEN 'PROBLEM '
END AS trigger_status,
events.name AS 'event',
actions.name AS 'action'
FROM events
JOIN alerts ON (alerts.eventid=events.eventid)
JOIN actions ON (actions.actionid=alerts.actionid)
WHERE events.source=0
AND events.object=0
ORDER BY events.clock DESC
LIMIT 10;

--non-working LLD rules
SELECT
hosts.name AS hostName,
items.key_ AS itemKey,
problem.name AS LLDerror,
CONCAT('host_discovery.php?form=update&itemid=', problem.objectid) AS goTo
FROM problem
JOIN items ON (items.itemid=problem.objectid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE problem.source > 0
AND problem.object=5;

--non-working data collector items
SELECT
hosts.name AS hostName,
items.key_ AS itemKey,
problem.name AS DataCollectorError,
CONCAT('items.php?form=update&itemid=', problem.objectid) AS goTo
FROM problem
JOIN items ON (items.itemid=problem.objectid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE problem.source > 0
AND problem.object=4;

--trigger evaluation problems
SELECT
DISTINCT CONCAT('triggers.php?form=update&triggerid=', problem.objectid) AS goTo,
hosts.name AS hostName,
triggers.description AS triggerTitle,
problem.name AS TriggerEvaluationError
FROM problem
JOIN triggers ON (triggers.triggerid=problem.objectid)
JOIN functions ON (functions.triggerid=triggers.triggerid)
JOIN items ON (items.itemid=functions.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE problem.source > 0
AND problem.object=0;

--user sessions
SELECT
COUNT(*),
users.alias
FROM sessions
JOIN users ON (users.userid=sessions.userid)
GROUP BY 2 ORDER BY 1 ASC;

--open problems
SELECT
COUNT(*) AS count,
CASE
WHEN source=0 THEN 'surface'
WHEN source > 0 THEN 'internal'
END AS level,
CASE
WHEN source=0 AND object=0 THEN 'trigger in a problem state'
WHEN source=3 AND object=0 THEN 'cannot evaluate trigger expression'
WHEN source=3 AND object=4 THEN 'data collection not working'
WHEN source=3 AND object=5 THEN 'low level discovery not perfect'
END AS problemCategory
FROM problem GROUP BY 2,3
ORDER BY 2 DESC;

--item update frequency
SELECT
h2.host AS Source,
i2.name AS itemName,
i2.key_ AS itemKey,
i2.delay AS OriginalUpdateFrequency,
h1.host AS exceptionInstalledOn,
i1.delay AS FrequencyChild,
CASE
WHEN i1.flags=1 THEN 'LLD rule'
WHEN i1.flags IN (0,4) THEN 'data collection'
END AS itemCategory,
CASE
WHEN i1.flags=1 THEN CONCAT('host_discovery.php?form=update&context=host&itemid=', i1.itemid)
WHEN i1.flags IN (0,4) THEN CONCAT('items.php?form=update&context=host&hostid=', h1.hostid, '&itemid=',i1.itemid)
END AS goTo
FROM items i1
JOIN items i2 ON (i2.itemid=i1.templateid)
JOIN hosts h1 ON (h1.hostid=i1.hostid)
JOIN hosts h2 ON (h2.hostid=i2.hostid)
WHERE i1.delay <> i2.delay;

--unsupported items and LLD rules
SELECT
DISTINCT i.key_,COALESCE(ir.error,'') AS error
FROM hosts h, items i
LEFT JOIN item_rtdata ir ON i.itemid=ir.itemid
WHERE i.type<>9
AND i.flags IN (0,1,4)
AND h.hostid=i.hostid
AND h.status<>3
AND i.status=0
AND ir.state=1
LIMIT 5001;

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

--show host object and proxy the item belongs to
SELECT
proxy.host AS proxy,
hosts.host,
items.name,
items.key_,
items.delay
FROM items
JOIN hosts ON (items.hostid=hosts.hostid)
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE hosts.status=0
AND items.status=0;

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

