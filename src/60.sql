--active problems, including Zabbix internal problems (item unsupported, trigger unsupported)
SELECT COUNT(*),source,object,severity FROM problem GROUP BY 2,3,4 ORDER BY severity;

--ZBX hosts unreachable
SELECT proxy.host AS proxy, hosts.host, interface.error,
CONCAT('zabbix.php?action=host.edit&hostid=',hosts.hostid) AS goTo
FROM hosts
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
JOIN interface ON (interface.hostid=hosts.hostid)
WHERE LENGTH(interface.error) > 0
AND interface.type=1;

--SNMP hosts unreachable
SELECT proxy.host AS proxy, hosts.host, interface.error,
CONCAT('zabbix.php?action=host.edit&hostid=',hosts.hostid) AS goTo
FROM hosts
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
JOIN interface ON (interface.hostid=hosts.hostid)
WHERE LENGTH(interface.error) > 0
AND interface.type=2;

--non-working external scripts
SELECT hosts.host,items.key_,item_rtdata.error FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
JOIN item_rtdata ON (items.itemid=item_rtdata.itemid)
WHERE hosts.status=0 AND items.status=0 AND items.type=10
AND LENGTH(item_rtdata.error) > 0;

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
SELECT hm1.macro AS Macro, child.host AS owner, hm2.value AS defaultValue,
parent.host AS OverrideInstalled, hm1.value AS OverrideValue
FROM hosts parent, hosts child, hosts_templates rel, hostmacro hm1, hostmacro hm2
WHERE parent.hostid=rel.hostid
AND child.hostid=rel.templateid
AND hm1.hostid = parent.hostid
AND hm2.hostid = child.hostid
AND hm1.macro = hm2.macro
AND parent.flags=0
AND child.flags=0
AND hm1.value <> hm2.value;

--detect if there is difference between template macro and host macro. this is surface level detection. it does not take care of values between nested templates
SELECT b.host, hm2.macro, hm2.value AS templateValue, h.host, hm1.macro, hm1.value AS hostValue
FROM hosts_templates, hosts h, hosts b, hostmacro hm1, hostmacro hm2, interface
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
SELECT repercussion.clock, repercussion.name, rootCause.clock, rootCause.name
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
SELECT items.type,items.key_,items.delay,items.status,COUNT(*) FROM items
JOIN hosts ON (hosts.hostid=items.hostid) WHERE items.flags=1 AND hosts.status=0
GROUP BY 1,2,3,4 ORDER BY 1,2,3,4;

--which dashboard has been using host group id:2 for the input
SELECT DISTINCT dashboard.name,hstgrp.name FROM widget_field
JOIN widget ON (widget.widgetid=widget_field.widgetid)
JOIN dashboard_page ON (dashboard_page.dashboard_pageid=widget.dashboard_pageid)
JOIN dashboard ON (dashboard.dashboardid=dashboard_page.dashboardid)
JOIN hstgrp ON (hstgrp.groupid=widget_field.value_groupid)
WHERE widget_field.value_groupid IN (2);

--Zabbix agent hitting the central server
SELECT hosts.host AS proxy,
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
SELECT hosts.host, items.key_ FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE hosts.status=0 AND hosts.flags=0
AND items.status=0 AND items.templateid IS NULL AND items.flags=0;

--hosts with multiple interfaces
SELECT hosts.host FROM interface
JOIN hosts ON (hosts.hostid=interface.hostid)
WHERE hosts.flags=0
GROUP BY hosts.host
HAVING COUNT(interface.interfaceid) > 1;

--PostgreSQL
SELECT proxy.host AS proxy, hosts.host, ARRAY_TO_STRING(ARRAY_AGG(template.host),', ') AS templates FROM hosts JOIN hosts_templates ON (hosts_templates.hostid=hosts.hostid) LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid) LEFT JOIN hosts template ON (hosts_templates.templateid=template.hostid) WHERE hosts.status IN (0,1) AND hosts.flags=0 GROUP BY 1,2 ORDER BY 1,3,2;

--MySQL
SELECT proxy.host AS proxy, hosts.host,
GROUP_CONCAT(template.host SEPARATOR ', ') AS templates
FROM hosts
JOIN hosts_templates ON (hosts_templates.hostid=hosts.hostid)
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
LEFT JOIN hosts template ON (hosts_templates.templateid=template.hostid)
WHERE hosts.status IN (0,1)
AND hosts.flags=0
GROUP BY 1,2
ORDER BY 1,3,2;

--non-working LLD rules
SELECT hosts.name AS hostName, items.key_ AS itemKey, problem.name AS LLDerror,
CONCAT('host_discovery.php?form=update&itemid=',problem.objectid) AS goTo
FROM problem
JOIN items ON (items.itemid=problem.objectid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE problem.source > 0 AND problem.object=5;

--non-working data collector items
SELECT hosts.name AS hostName, items.key_ AS itemKey, problem.name AS DataCollectorError,
CONCAT('items.php?form=update&itemid=',problem.objectid) AS goTo
FROM problem
JOIN items ON (items.itemid=problem.objectid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE problem.source > 0
AND problem.object=4;

--trigger evaluation problems
SELECT
DISTINCT CONCAT('triggers.php?form=update&triggerid=',problem.objectid) AS goTo,
hosts.name AS hostName, triggers.description AS triggerTitle, problem.name AS TriggerEvaluationError
FROM problem
JOIN triggers ON (triggers.triggerid=problem.objectid)
JOIN functions ON (functions.triggerid=triggers.triggerid)
JOIN items ON (items.itemid=functions.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE problem.source > 0
AND problem.object=0;

--user sessions
SELECT COUNT(*), users.username
FROM sessions
JOIN users ON (users.userid=sessions.userid)
GROUP BY 2 ORDER BY 1 ASC;

--open problems
SELECT COUNT(*) AS count,
CASE
WHEN source = 0 THEN 'surface'
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
SELECT h2.host AS Source, i2.name AS itemName, i2.key_ AS itemKey, i2.delay AS OriginalUpdateFrequency, h1.host AS exceptionInstalledOn, i1.delay AS FrequencyChild,
CASE
WHEN i1.flags=1 THEN 'LLD rule'
WHEN i1.flags IN (0,4) THEN 'data collection'
END AS itemCategory,
CASE
WHEN i1.flags=1 THEN CONCAT('host_discovery.php?form=update&context=host&itemid=',i1.itemid)
WHEN i1.flags IN (0,4) THEN CONCAT('items.php?form=update&context=host&hostid=',h1.hostid,'&itemid=',i1.itemid)
END AS goTo
FROM items i1
JOIN items i2 ON (i2.itemid=i1.templateid)
JOIN hosts h1 ON (h1.hostid=i1.hostid)
JOIN hosts h2 ON (h2.hostid=i2.hostid)
WHERE i1.delay <> i2.delay;

--which dashboard widgets are using wildcards
SELECT value_str AS pattern, widget.name AS widgetName, dashboard.name AS dashboardName
FROM widget_field, widget, dashboard_page, dashboard
WHERE widget_field.value_str like '%*%'
AND widget.widgetid=widget_field.widgetid
AND dashboard_page.dashboard_pageid=widget.dashboard_pageid
AND dashboard.dashboardid=dashboard_page.dashboard_pageid
ORDER BY 3,2,1;

--remove user refresh overrides in user level
DELETE FROM profiles WHERE idx='web.dashboard.widget.rf_rate';

--print all online users with rights group ID: 13
SELECT users.username, CASE
WHEN permission=0 THEN 'DENY'
WHEN permission=2 THEN 'READ_ONLY'
WHEN permission=3 THEN 'READ_WRITE'
END AS permission,
hstgrp.name
FROM users, users_groups, sessions, usrgrp, rights, hstgrp
WHERE sessions.status=0
AND rights.groupid=13
AND users.userid=users_groups.userid
AND users.userid=sessions.userid
AND users_groups.usrgrpid=usrgrp.usrgrpid
AND users_groups.userid=users.userid
AND usrgrp.usrgrpid=rights.groupid
AND rights.id=hstgrp.groupid;

--For items which are currently disabled, clean the error message in database. This will help to locate what really is not working and why
UPDATE item_rtdata SET error='' WHERE itemid IN (
SELECT items.itemid FROM item_rtdata, items, hosts
WHERE item_rtdata.state=1 AND hosts.status=0 AND items.status=1
AND item_rtdata.itemid=items.itemid
AND hosts.hostid=items.hostid
);

--For items which are currently disabled, reset the state as supported. This will help to locate what really is not working and why. Item will remain disabled
UPDATE item_rtdata SET state=0 WHERE itemid IN (
SELECT items.itemid FROM item_rtdata, items, hosts
WHERE item_rtdata.state=1 AND hosts.status=0 AND items.status=1
AND item_rtdata.itemid=items.itemid
AND hosts.hostid=items.hostid
);

--print error message for enabled hosts and enabled data collector items
SELECT hosts.host, items.name, item_rtdata.error FROM item_rtdata, items, hosts
WHERE item_rtdata.state=1 AND hosts.status=0 AND items.status=0
AND item_rtdata.itemid=items.itemid
AND hosts.hostid=items.hostid;

--identify item membership. usefull if that is master item
SELECT proxy.host AS proxy, hosts.host, items.name, items.key_, items.delay
FROM hosts
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
JOIN items ON (items.hostid=hosts.hostid)
WHERE items.itemid IN (12345,5678);

