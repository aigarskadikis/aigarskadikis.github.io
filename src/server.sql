--how many user groups has debug mode 1. Zabbix 5.0, 5.2
SELECT COUNT(*) FROM usrgrp WHERE debug_mode=1;

--active problems including internal. Zabbix 4.0, 5.0, 6.0, 6.2
SELECT COUNT(*), source, object, severity FROM problem GROUP BY 2,3,4 ORDER BY severity;

--sessions in last day. Zabbix 6.0
SELECT users.username,COUNT(*) FROM sessions, users WHERE
sessions.userid = users.userid
AND sessions.lastaccess > sessions.lastaccess-(3600*24)
GROUP BY 1;

--most profesional way how to erase records from MySQL/MariaDB
CREATE TEMPORARY TABLE tmp_eventids
SELECT eventid
FROM problem p
WHERE NOT EXISTS (SELECT NULL FROM events e WHERE e.eventid = p.eventid);
DELETE FROM problem
WHERE eventid IN (SELECT eventid FROM tmp_eventids);
DROP TEMPORARY TABLE tmp_eventids;

--which userid is disabling triggers. Zabbix 7.0
SELECT DISTINCT auditlog.recordsetid, hosts.host, auditlog.clock, auditlog.userid, triggers.triggerid, auditlog.details
FROM auditlog, triggers, functions, hosts, items
WHERE auditlog.resourcetype = 13
AND auditlog.action = 1
AND triggers.triggerid = auditlog.resourceid
AND functions.triggerid = triggers.triggerid
AND items.itemid = functions.itemid
AND hosts.hostid = items.hostid
ORDER BY auditlog.clock DESC LIMIT 2;

--detect when Keep lost resources period is not installed in danger. Zabbix 5.2
SELECT hosts.host,items.name FROM items, hosts
WHERE hosts.hostid=items.hostid
AND items.status=0
AND hosts.status=0
AND items.flags=1
AND items.lifetime IN ('0','0d','0h','0m','0s');

--a host with most of the dependent items
SELECT hosts.host, COUNT(*) AS amountOfDependentItems
FROM items,hosts
WHERE hosts.hostid=items.hostid
AND hosts.status=0
AND items.status=0
AND items.flags IN (0,4)
AND items.type=18
GROUP BY 1
ORDER BY 2 DESC
LIMIT 20;

--migrate template/host level macros from one host to another. Zabbix 6.4
UPDATE hostmacro SET hostid=34094 WHERE hostid=34098;

--lld rules
SELECT COUNT(*), origin.host AS Template, another.name AS LLD,
CONCAT('host_discovery.php?form=update&itemid=',items.templateid,'&context=template') AS URL
FROM items
JOIN hosts ON hosts.hostid=items.hostid
JOIN items another ON another.itemid=items.templateid
JOIN hosts origin ON origin.hostid=another.hostid
WHERE hosts.status=0 AND items.status=0
AND hosts.flags IN (0,4)
AND items.flags=1
GROUP BY 2,3,4
ORDER BY 1 ASC;

--aggressive hosts
SELECT COUNT(*), items.key_, items.delay, GROUP_CONCAT(hosts.host) FROM items, hosts
WHERE hosts.hostid=items.hostid
AND hosts.status=0 AND hosts.flags IN (0,4)
AND items.status=0 AND items.flags=1
AND items.delay not like '%d'
AND items.delay not like '%h'
GROUP BY 2,3
ORDER BY 1;

--triggerid generates problems in time order
SELECT clock, ns, eventid, name,
CASE value
WHEN 0 THEN 'resolved'
WHEN 1 THEN 'starts'
END AS "problem"
FROM events
WHERE objectid=27375 AND clock BETWEEN 0 AND 1734517730
ORDER BY clock DESC, ns DESC;

--triggerid generates problems in time order, sort by eventid
SELECT clock, ns, eventid, name,
CASE value
WHEN 0 THEN 'resolved'
WHEN 1 THEN 'starts'
END AS "problem"
FROM events
WHERE objectid=27375 AND clock BETWEEN 0 AND 1734517730
ORDER BY eventid DESC;

--active and inactive sessions. Zabbix 6.0
SELECT users.username, CASE sessions.status
WHEN 0 THEN 'active'
WHEN 1 THEN 'not active'
END AS "status", COUNT(*) FROM sessions, users WHERE sessions.userid=users.userid GROUP BY 1,2 ORDER BY 3 DESC;

--notification stats. Zabbix 6.0
SELECT actions.name AS actionName, users.username AS sendTo, media_type.name AS mediaName,
CASE alerts.status
WHEN 0 THEN 'NOT_SENT'
WHEN 1 THEN 'SENT'
WHEN 2 THEN 'FAILED'
WHEN 3 THEN 'NEW'
END AS "alertStatus",
COUNT(*) AS count
FROM alerts
JOIN actions ON (actions.actionid=alerts.actionid)
JOIN media_type ON (media_type.mediatypeid=alerts.mediatypeid)
LEFT JOIN users ON (users.userid=alerts.userid)
WHERE clock > UNIX_TIMESTAMP(NOW()-INTERVAL 7 DAY)
GROUP BY 1,2,3,4
ORDER BY 5 ASC;

--which item consumes the space the most
SELECT SUM(LENGTH(value)),hosts.host,items.key_ FROM (
SELECT * FROM history_text LIMIT 1000
) t1
JOIN items ON t1.itemid=items.itemid
JOIN hosts ON hosts.hostid=items.hostid
GROUP BY 2,3 ORDER BY 1 DESC LIMIT 9;

--print URL to visit which host consumes a lot of data. MySQL. Zabbix 5.0, 6.0, 7.0
SELECT SUM(LENGTH(value)) AS Size,
CONCAT('history.php?itemids%5B0%5D=',t1.itemid,'&action=showlatest') AS 'URL' FROM (
SELECT * FROM history_text LIMIT 1000
) t1
GROUP BY 2 ORDER BY 1 DESC LIMIT 9;

--open problems by origin
SELECT COUNT(*), source, object FROM problem GROUP BY 2,3 ORDER BY 1 DESC;

--open problems by objectid
SELECT COUNT(*), source, object, objectid FROM problem GROUP BY 2,3,4 ORDER BY 1 DESC LIMIT 20;

--online users. Zabbix 6.0
SELECT users.name, lastaccess, sessionid
FROM sessions,users
WHERE users.userid=sessions.userid
ORDER BY lastaccess DESC
LIMIT 20;

--PostgreSQL copy data from one table to another. Zabbix 7.0
INSERT INTO trends SELECT * FROM trends_old ON CONFLICT (clock, itemid) DO NOTHING;
INSERT INTO trends_uint SELECT * FROM trends_uint_old ON CONFLICT (clock, itemid) DO NOTHING;

--show refresh rate. Zabbix 5.0
SELECT users.alias, profiles.value_int AS refreshIntensity, dashboard.name AS dashboardName, widget.name AS widgetName
FROM profiles,users,widget,dashboard
WHERE users.userid=profiles.userid
AND profiles.idx2=widget.widgetid
AND dashboard.dashboardid=widget.dashboardid
AND idx='web.dashbrd.widget.rf_rate';

--reset refresh rate
UPDATE profiles SET value_int=900 WHERE idx='web.dashbrd.widget.rf_rate';

--duplicate IP addresses. Hosts with same IP addres. Zabbix 7.0
SELECT interface.ip,GROUP_CONCAT(hosts.host),COUNT(*) FROM interface, hosts
WHERE hosts.hostid=interface.hostid
AND hosts.status=0
AND hosts.flags=0
GROUP BY 1
HAVING COUNT(*) > 1;

--most of items at host level
SELECT hosts.host, COUNT(*) FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE hosts.status IN (0,1) AND hosts.flags IN (0,4)
GROUP BY 1
ORDER BY 2 ASC;

--error messages by category. Zabbix 7.0
SELECT DISTINCT item_rtdata.error, GROUP_CONCAT(hosts.host) AS hosts, COUNT(*) AS count FROM item_rtdata,items,hosts
WHERE item_rtdata.itemid=items.itemid
AND hosts.hostid=items.hostid
AND hosts.status=0
AND item_rtdata.error NOT IN ('')
GROUP BY 1
ORDER BY 3 ASC;

--query host and interface details. Zabbix 5.0
SELECT proxy.host AS proxy, hosts.host,
hosts.hostid,
interface.interfaceid,
interface.main,
interface.type,
interface.useip,
interface.ip,
interface.dns,
interface.port,
interface_snmp.version,
interface_snmp.bulk,
interface_snmp.community,
interface_snmp.securityname,
interface_snmp.securitylevel,
interface_snmp.authpassphrase,
interface_snmp.privpassphrase,
interface_snmp.authprotocol,
interface_snmp.privprotocol,
interface_snmp.contextname
FROM hosts
LEFT JOIN interface ON (interface.hostid=hosts.hostid)
LEFT JOIN interface_snmp ON (interface.interfaceid=interface_snmp.interfaceid)
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE hosts.status IN (0,1) AND hosts.flags=0;

--show events which got suppressed. query does not shwo the timestamp of start suppress
SELECT FROM_UNIXTIME(events.clock) AS problemTime, FROM_UNIXTIME(event_suppress.suppress_until) AS suppressUntil, events.name
FROM events, event_suppress, triggers
WHERE events.eventid=event_suppress.eventid
AND events.source=0 AND events.object=0
AND triggers.triggerid=events.objectid
AND triggers.priority IN (0,1,2,3,4,5)
AND events.clock >= UNIX_TIMESTAMP("2024-01-01 00:00:00") AND events.clock < UNIX_TIMESTAMP("2025-02-01 00:00:00");

--unreachable ZBX host. Zabbix 4.0, 4.2, 4.4, 5.0, 5.2
SELECT
proxy.host AS proxy,
hosts.host,
hosts.error AS hostError,
CONCAT('hosts.php?form=update&hostid=', hosts.hostid) AS goTo
FROM hosts
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE hosts.status=0
AND LENGTH(hosts.error) > 0;

--unreachable ZBX hosts. Zabbix 6.4, 7.0
SELECT proxy.name,
hosts.host,
interface.error,
CONCAT('zabbix.php?action=host.edit&hostid=',hosts.hostid) AS goTo
FROM hosts
LEFT JOIN hosts proxy ON (hosts.proxyid=proxy.proxyid)
JOIN interface ON (interface.hostid=hosts.hostid)
WHERE LENGTH(interface.error) > 0 AND interface.type=1;

--blindly select metrics from a partition without knowing the total amount. aggregate statistics
SELECT itemid, COUNT(*) FROM (
SELECT itemid FROM history_uint PARTITION (p202310290000) LIMIT 9999
) b GROUP BY 1 ORDER BY 2 DESC;

--which template has JSONPath preprocessing. Zabbix 6.0
SELECT hosts.host, items.name, item_preproc
FROM hosts, items, item_preproc
WHERE hosts.hostid=items.hostid AND items.itemid=item_preproc.itemid
AND item_preproc.type=12
AND item_preproc.params LIKE '%memory.sum%';

--default update frequency for dashboard and dasboard page. If display_period=0 for page, then dashboard refresh is used. Zabbix 6.4
SELECT DISTINCT dashboard.name AS dashBoardName,
dashboard_page.dashboardid,
dashboard.display_period AS dasboardRefresh,
dashboard_page.name AS pageName,
dashboard_page.dashboard_pageid,
dashboard_page.display_period AS pageRefresh
FROM dashboard_page, dashboard
WHERE dashboard_page.dashboardid=dashboard.dashboardid
AND dashboard.templateid IS NULL;

--set all global dashboards to use 5 minute update frequency. Zabbix 6.4
UPDATE dashboard SET display_period=300 WHERE display_period<>300 AND templateid IS NULL;

--set all global dashboard pages to respect the default dashboard update frequency. Zabbix 6.4
UPDATE dashboard_page SET display_period=0 WHERE display_period<>0 AND dashboardid IN (SELECT dashboardid FROM dashboard WHERE templateid IS NULL);

--set maximum refresh rate (15 minutes) for widget where user installed a custom refresh rate. Zabbix 6.4
UPDATE profiles SET value_int=900 WHERE idx='web.dashboard.widget.rf_rate';

--remove any override user made to individual widget. Zabbix 6.4
DELETE FROM profiles WHERE idx='web.dashboard.widget.rf_rate';

--delete orhaned events. use limit in PostgreSQL
DELETE FROM events WHERE eventid IN (
SELECT eventid FROM events WHERE object=0 AND source=0 AND objectid NOT IN (
SELECT triggerid FROM triggers
) LIMIT 10
);

--delete orhnaned events in batches. Works on PosthreSQL, do not work on MySQL
DELETE FROM events WHERE eventid IN (
SELECT eventid FROM events WHERE object = 0 AND source = 0 AND NOT EXISTS (SELECT 1 FROM triggers t WHERE t.triggerid = events.objectid) LIMIT 1000
);

--biggest data per itemid per partition
SELECT SUM(LENGTH(value)) AS total,itemid FROM history_log PARTITION (p202407130000) GROUP BY 2 ORDER BY 1 DESC LIMIT 10;

--faster way to pick up some data for aggregation
SELECT SUM(LENGTH(value)),itemid FROM (
SELECT * FROM history_text PARTITION (p202407130000) LIMIT 10000
) t1
GROUP BY 2 ORDER BY 1 DESC LIMIT 9;

--permissions checks. Zabbix 5.0
SELECT DISTINCT users.alias, FROM_UNIXTIME(sessions.lastaccess)
FROM users, users_groups, sessions, usrgrp, rights, hstgrp
WHERE sessions.status=0
AND users.userid=users_groups.userid
AND users.userid=sessions.userid
AND users_groups.usrgrpid=usrgrp.usrgrpid
AND users_groups.userid=users.userid
AND usrgrp.usrgrpid=rights.groupid
AND rights.id=hstgrp.groupid
AND rights.groupid IN (28)
AND users.type < 3
ORDER BY 2 DESC LIMIT 20;

--consume most space in history_text table. PostgreSQL. Zabbix 7.0
SELECT SUM(LENGTH(history_text.value)) AS length, history_text.itemid
FROM history_text
GROUP BY 2
ORDER BY 1
DESC LIMIT 20;

--consume most space in history_str table. PostgreSQL. Zabbix 7.0
SELECT SUM(LENGTH(history_str.value)) AS length, history_str.itemid
FROM history_str
GROUP BY 2
ORDER BY 1
DESC LIMIT 20;

--mixed SNMPv3 credentials. Zabbix 4.4
SELECT snmpv3_securityname AS user,
CASE snmpv3_securitylevel
WHEN 0 THEN 'noAuthNoPriv'
WHEN 1 THEN 'authNoPriv'
WHEN 2 THEN 'authPriv'
END AS secLev,
CASE snmpv3_authprotocol
WHEN 0 THEN 'MD5'
WHEN 1 THEN 'SHA'
END AS authProto,
snmpv3_authpassphrase AS authPhrase,
CASE snmpv3_privprotocol
WHEN 0 THEN 'DES'
WHEN 1 THEN 'AES'
END AS privProto,
snmpv3_privpassphrase AS privPhrase,
CASE flags
WHEN 0 THEN 'normal'
WHEN 1 THEN 'rule'
WHEN 2 THEN 'prototype'
WHEN 4 THEN 'discovered'
END AS flags,
COUNT(*)
FROM items
WHERE type=6
GROUP BY 1,2,3,4,5,6,7;

--Zabbix agent interface with errors. Zabbix 7.0
SELECT proxy.name, hosts.host, interface.dns, interface.ip, interface.useip, interface.error FROM hosts
LEFT JOIN proxy ON (hosts.proxyid=proxy.proxyid)
JOIN interface ON (interface.hostid=hosts.hostid)
WHERE LENGTH(interface.error) > 0 AND interface.type=1;

--SNMP interface with errors. Zabbix 7.0
SELECT proxy.name, hosts.host, interface.dns, interface.ip, interface.useip, interface.error FROM hosts
LEFT JOIN proxy ON (hosts.proxyid=proxy.proxyid)
JOIN interface ON (interface.hostid=hosts.hostid)
WHERE LENGTH(interface.error) > 0 AND interface.type=2;

--amount of unsupported items on host. Zabbix 7.0
SELECT
hosts.host,
COUNT(*)
FROM items, item_rtdata, hosts
WHERE item_rtdata.state=1
AND hosts.status=0
AND items.status=0
AND item_rtdata.itemid=items.itemid
AND hosts.hostid=items.hostid
GROUP BY 1
ORDER BY 2 ASC;

--hosts having this particula error message at item level. Zabbix 7.0
SELECT DISTINCT hosts.host, proxy.name
FROM items, item_rtdata, hosts
LEFT JOIN proxy ON hosts.proxyid=proxy.proxyid
WHERE item_rtdata.state=1
AND hosts.status=0
AND items.status=0
AND item_rtdata.itemid=items.itemid
AND hosts.hostid=items.hostid
AND item_rtdata.error like '%Unknown user name%';

--store textual garbage. Zabbix 7.0
SELECT SUM(LENGTH(value)) AS total,
CONCAT('history.php?itemids%5B0%5D=',itemid,'&action=showlatest')
FROM history_text PARTITION (p2024_08_19) GROUP BY 2 ORDER BY 1 DESC LIMIT 10;

--store textual garbage without. scan full table. Zabbix 7.0
SELECT SUM(LENGTH(value)) AS total,
CONCAT('history.php?itemids%5B0%5D=',itemid,'&action=showlatest')
FROM history_text GROUP BY 2 ORDER BY 1 DESC LIMIT 10;

--active checks are not reporting back. Zabbix 7.0
SELECT proxy.name,hosts.host FROM hosts
JOIN host_rtdata ON hosts.hostid=host_rtdata.hostid
LEFT JOIN proxy ON hosts.proxyid=proxy.proxyid
WHERE host_rtdata.active_available=2;

--failed actions. Zabbix 5.0, 6.0, 7.0
SELECT FROM_UNIXTIME(alerts.clock) AS clock,
CONCAT('tr_events.php?triggerid=',events.objectid,'&eventid=',alerts.eventid) AS URL,
alerts.error,
actions.name
FROM alerts
JOIN events ON alerts.eventid=events.eventid
JOIN actions ON actions.actionid=alerts.actionid
WHERE alerts.status=2 ORDER BY 1 ASC

--what is host, item name for the item id. usefull to detect if storing data with wrong timestamp. Zabbix 6.0
SELECT proxy.host AS proxy,
hosts.host,
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
items.name
FROM hosts
JOIN items ON items.hostid=hosts.hostid
LEFT JOIN hosts proxy ON hosts.proxy_hostid=proxy.hostid
WHERE hosts.status=0
AND items.status=0
AND items.itemid IN (123,456);

--orphaned events, posthres, Zabbix 6.0
DELETE FROM event_recovery WHERE eventid IN (SELECT eventid FROM event_recovery WHERE eventid NOT IN (SELECT eventid FROM events) LIMIT 100);
DELETE FROM event_recovery WHERE r_eventid IN (SELECT r_eventid FROM event_recovery WHERE r_eventid NOT IN (SELECT eventid FROM events) LIMIT 100);
DELETE FROM event_recovery WHERE c_eventid IN (SELECT c_eventid FROM event_recovery WHERE c_eventid NOT IN (SELECT eventid FROM events) LIMIT 100);
DELETE FROM event_suppress WHERE eventid IN (SELECT eventid FROM event_suppress WHERE eventid NOT IN (SELECT eventid FROM events) LIMIT 100);

--base memory GB
SELECT ( @@key_buffer_size
+ @@innodb_buffer_pool_size
+ @@innodb_log_buffer_size )
/ (1024 * 1024 * 1024) AS BASE_MEMORY_GB;

--max memory GB
SELECT ( @@key_buffer_size
+ @@innodb_buffer_pool_size
+ @@innodb_log_buffer_size
+ @@max_connections * (
@@read_buffer_size
+ @@read_rnd_buffer_size
+ @@sort_buffer_size
+ @@join_buffer_size
+ @@binlog_cache_size
+ @@thread_stack
+ @@max_heap_table_size
)
) / (1024 * 1024 * 1024) AS MAX_MEMORY_GB;

--unreachable SNMP hosts. Zabbix 4.0, 4.2, 4.4, 5.0, 5.2
SELECT
proxy.host AS proxy,
hosts.host,
hosts.snmp_error AS hostError,
CONCAT('hosts.php?form=update&hostid=', hosts.hostid) AS goTo
FROM hosts
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE hosts.status=0
AND LENGTH(hosts.snmp_error) > 0;

--dublicate devices phase1. find duplicate interfaces based on device serial number stored in the "Serial A" field
SELECT host_inventory.serialno_a AS serial, GROUP_CONCAT(interface.interfaceid) AS iID
FROM interface, host_inventory, hosts
WHERE host_inventory.hostid=interface.hostid
AND hosts.hostid=host_inventory.hostid
AND hosts.status=0
AND interface.main=0
AND host_inventory.serialno_a='123456'
GROUP BY host_inventory.serialno_a;

--same host name
SELECT host_inventory.name AS name, GROUP_CONCAT(interface.interfaceid) AS IP, GROUP_CONCAT(hosts.hostid) AS hID
FROM interface, host_inventory, hosts
WHERE host_inventory.hostid=interface.hostid
AND hosts.hostid=host_inventory.hostid
AND hosts.status=0
AND interface.main=0
AND host_inventory.name='idrac'
GROUP BY 1;

--dublicate devices phase2. add the interface to the other device
UPDATE interface SET hostid=10561 WHERE interfaceid IN (28,32,437);

--dublicate devices phase3. summary
SELECT host_inventory.serialno_a AS serial, GROUP_CONCAT(interface.ip) AS IP, GROUP_CONCAT(hosts.hostid) AS hID
FROM interface, host_inventory, hosts
WHERE host_inventory.hostid=interface.hostid
AND hosts.hostid=host_inventory.hostid
AND hosts.status=0
AND LENGTH(host_inventory.serialno_a) > 0
GROUP BY host_inventory.serialno_a
HAVING COUNT(*) > 1;

--order how hosts got discovered. must have global setting on to keep older records. Zabbix 6.0
SELECT FROM_UNIXTIME(clock), name,
CASE value
WHEN 0 THEN 'UP'
WHEN 1 THEN 'DOWN'
WHEN 2 THEN 'discovered'
WHEN 3 THEN 'lost'
END AS "status"
FROM events
WHERE source=1
AND value=2
ORDER BY 1 ASC;

--go directly per unsupported items per host object. Zabbix 6.0
SELECT COUNT(*),proxy.host, hosts.host, CONCAT('items.php?context=host&filter_hostids%5B%5D=',hosts.hostid,'&filter_name=&filter_key=&filter_type=-1&filter_value_type=-1&filter_snmp_oid=&filter_history=&filter_trends=&filter_delay=&filter_evaltype=0&filter_tags%5B0%5D%5Btag%5D=&filter_tags%5B0%5D%5Boperator%5D=0&filter_tags%5B0%5D%5Bvalue%5D=&filter_state=1&filter_with_triggers=-1&filter_inherited=-1&filter_discovered=-1&filter_set=1') AS hostid 
FROM items
JOIN item_rtdata ON (item_rtdata.itemid=items.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE hosts.status=0
AND item_rtdata.state=1
GROUP BY 2,3,4
ORDER BY 1 DESC
LIMIT 10;

--all items which belongs to application 'DR'. Zabbix 5.0
SELECT hosts.host, items.key_
FROM items, hosts, items_applications, applications
WHERE items_applications.itemid=items.itemid
AND applications.applicationid=items_applications.applicationid
AND hosts.hostid=items.hostid
AND hosts.status=0
AND items.status=0
AND items.flags IN (0,4)
AND applications.name='DR';

--clean up trends for items which now does not want to store trends or item is disabled. Zabbix 5.0
SET SESSION SQL_LOG_BIN=0;
DELETE FROM trends WHERE itemid IN (SELECT itemid FROM items WHERE value_type=0 AND trends='0' AND flags IN (0,4));
DELETE FROM trends WHERE itemid IN (SELECT itemid FROM items WHERE value_type=0 AND status=1 AND flags IN (0,4));
DELETE FROM trends_uint WHERE itemid IN (SELECT itemid FROM items WHERE value_type=3 AND trends='0' AND flags IN (0,4));
DELETE FROM trends_uint WHERE itemid IN (SELECT itemid FROM items WHERE value_type=3 AND status=1 AND flags IN (0,4));
DELETE FROM history_text WHERE itemid IN (SELECT itemid FROM items WHERE value_type=4 AND history='0' AND flags IN (0,4));
DELETE FROM history_text WHERE itemid IN (SELECT itemid FROM items WHERE value_type=4 AND status=1 AND flags IN (0,4));
DELETE FROM history_str WHERE itemid IN (SELECT itemid FROM items WHERE value_type=1 AND history='0' AND flags IN (0,4));
DELETE FROM history_str WHERE itemid IN (SELECT itemid FROM items WHERE value_type=1 AND status=1 AND flags IN (0,4));
DELETE FROM history_log WHERE itemid IN (SELECT itemid FROM items WHERE value_type=2 AND history='0' AND flags IN (0,4));
DELETE FROM history_log WHERE itemid IN (SELECT itemid FROM items WHERE value_type=2 AND status=1 AND flags IN (0,4));

--list LLD rules which has an "input" from "Zabbix trapper" item. This is list on what will be about to be disabled.
SELECT hosts.host AS host, master_itemid.key_ AS master, items.key_ AS LLD
FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
JOIN items master_itemid ON (master_itemid.itemid=items.master_itemid)
WHERE items.flags=1
AND hosts.status=0
AND master_itemid.type=2;

--note down exact itemIDs for LLD items which is attached to "Zabbix trapper" item:
SET SESSION group_concat_max_len = 1000000; SELECT GROUP_CONCAT(items.itemid)
FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
JOIN items master_itemid ON (master_itemid.itemid=items.master_itemid)
WHERE items.flags=1
AND hosts.status=0
AND master_itemid.type=2;

--dependency tree for active problems. Zabbix 6.0
SELECT triggerid_down, COUNT(*) FROM trigger_depends WHERE triggerid_up IN (SELECT objectid FROM problem WHERE source=0) GROUP BY 1 HAVING COUNT(*)>1 ORDER BY 2 DESC LIMIT 10;
SELECT triggerid_down, COUNT(*) FROM trigger_depends WHERE triggerid_down IN (SELECT objectid FROM problem WHERE source=0) GROUP BY 1 HAVING COUNT(*)>1 ORDER BY 2 DESC LIMIT 10;
SELECT triggerid_up, COUNT(*) FROM trigger_depends WHERE triggerid_down IN (SELECT objectid FROM problem WHERE source=0) GROUP BY 1 HAVING COUNT(*)>1 ORDER BY 2 DESC LIMIT 10;
SELECT triggerid_up, COUNT(*) FROM trigger_depends WHERE triggerid_up IN (SELECT objectid FROM problem WHERE source=0) GROUP BY 1 HAVING COUNT(*)>1 ORDER BY 2 DESC LIMIT 10;

--usernames, roles and user type. Zabbix 6.0
SELECT
users.username,
role.name AS Role,
CASE role.type
WHEN 1 THEN 'user'
WHEN 2 THEN 'admin'
WHEN 3 THEN 'super admin'
END AS UserType
FROM users
JOIN role ON (users.roleid=role.roleid);

--variety of items key-wise
SELECT DISTINCT items.key_, COUNT(*)
FROM items, hosts
WHERE items.hostid=hosts.hostid
AND items.status=0
AND hosts.status=0
AND items.flags IN (0,1,2)
AND hosts.flags IN (0,4)
GROUP BY 1
ORDER BY 2 ASC;

--active and disabled hosts and items. Zabbix 4.0, 4.2, 4.4, 5.0, 5.2, 5.4, 6.0
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
GROUP BY 1,2,3,4
ORDER BY 1,2,3,4,5 DESC;

--Plain items at the template level which use positional macro. Zabbix 4.0
SELECT items.name, hosts.host AS template, CONCAT('items.php?form=update&itemid=',items.itemid) AS URL
FROM hosts, items
WHERE hosts.hostid=items.hostid
AND hosts.status=3
AND items.flags IN (0)
AND items.name LIKE '%$%' AND items.name NOT LIKE '%{$%';

--Monitoring => Service problem. Zabbix 6.0
SELECT services.name,
service_alarms.clock,
service_alarms.value,
service_alarms.serviceid,
service_alarms.servicealarmid
FROM service_alarms, services
WHERE service_alarms.serviceid=services.serviceid
ORDER BY 1,2,3,4,5;

--statistics per maintenance. Zabbix 6.0
SELECT maintenance_status, maintenance_type, COUNT(*) FROM hosts WHERE flags IN (0,4) AND status=0 GROUP BY 1,2;

--statistics per maintenance including starting time. Zabbix 6.0
SELECT maintenance_status, maintenance_type, maintenance_from, COUNT(*) FROM hosts WHERE flags IN (0,4) AND status=0 GROUP BY 1,2,3;

--start time explained for postgreSQL. Zabbix 6.0
SELECT maintenance_status, maintenance_type, TO_CHAR(DATE(TO_TIMESTAMP(maintenance_from)),'YYYY-MM-DD HH:mm'), COUNT(*) FROM hosts WHERE flags IN (0,4) AND status=0 GROUP BY 1,2,3 ORDER BY 3;

--hosts in the maintenance window and responsible profile. Zabbix 6.0
SELECT maintenances.name, TO_CHAR(DATE(TO_TIMESTAMP(maintenance_from)),'YYYY-MM-DD HH:mm'), COUNT(*)
FROM hosts
JOIN maintenances_hosts ON (maintenances_hosts.hostid=hosts.hostid)
JOIN maintenances ON (maintenances.maintenanceid=maintenances_hosts.maintenanceid)
WHERE hosts.flags IN (0,4) AND hosts.status=0 AND hosts.maintenance_status=1 GROUP BY 1,2 ORDER BY 2;

--alerts
SELECT status, actionid, mediatypeid, COUNT(*) FROM alerts GROUP BY 1,2,3 ORDER BY 4 DESC;

--alerts in last 7 days
SELECT status, actionid, mediatypeid, COUNT(*) FROM alerts WHERE clock > UNIX_TIMESTAMP(NOW()-INTERVAL 7 DAY) GROUP BY 1,2,3 ORDER BY 4 DESC;

--show SNMPv3 devices. Zabbix 5.0
SELECT proxy.host, interface.ip
FROM interface
JOIN hosts ON hosts.hostid=interface.hostid
JOIN interface_snmp ON interface_snmp.interfaceid=interface.interfaceid
JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE interface.main=1
AND interface.type=2
AND interface_snmp.version=3
AND hosts.status=0
ORDER BY 1,2;

--how many 'nodata' functions are applied
SELECT COUNT(*)
FROM triggers
JOIN functions ON functions.triggerid=triggers.triggerid
JOIN items ON items.itemid=functions.itemid
JOIN hosts ON hosts.hostid=items.hostid
WHERE hosts.status=0 AND items.status=0 AND triggers.status=0
AND functions.name='nodata';

--nodata functions per host
SELECT COUNT(*), hosts.name
FROM triggers
JOIN functions ON functions.triggerid=triggers.triggerid
JOIN items ON items.itemid=functions.itemid
JOIN hosts ON hosts.hostid=items.hostid
WHERE hosts.status=0 AND items.status=0 AND triggers.status=0
AND functions.name='nodata'
GROUP BY 2 ORDER BY 1 DESC LIMIT 30;

--If the "items.type" is 2 (Zabbix trapper) or 7 (Zabbix agent active), there's a bigger chance of having this "Duplicate entry" problem because of misconfiguration
SELECT proxy.host, hosts.host, items.type, items.itemid, items.delay, items.key_, items.flags
FROM items
JOIN hosts ON hosts.hostid=items.hostid
LEFT JOIN hosts proxy ON hosts.proxy_hostid=proxy.hostid
WHERE items.itemid IN (12,34,56);

--reconstruct auditlog
CREATE TABLE auditlog_temp LIKE auditlog;
INSERT INTO auditlog_temp SELECT * FROM auditlog WHERE clock > UNIX_TIMESTAMP(NOW() - INTERVAL 5 DAYS);
TRUNCATE TABLE auditlog;
INSERT INTO auditlog SELECT * FROM auditlog_temp;
DROP TABLE auditlog_temp;

--list not discovered triggers
SELECT DISTINCT triggers.triggerid, triggers.description, hosts.host FROM triggers
JOIN functions ON functions.triggerid=triggers.triggerid
JOIN items ON items.itemid=functions.itemid
JOIN hosts ON items.hostid=hosts.hostid
WHERE items.itemid IN (
SELECT
items.itemid
FROM items
JOIN item_discovery ON item_discovery.itemid=items.itemid
JOIN hosts ON hosts.hostid=items.hostid
WHERE item_discovery.ts_delete > 0
);

--delete not discovered triggers
DELETE FROM triggers WHERE triggerid IN (
SELECT DISTINCT triggers.triggerid FROM triggers
JOIN functions ON functions.triggerid=triggers.triggerid
JOIN items ON items.itemid=functions.itemid
JOIN hosts ON items.hostid=hosts.hostid
WHERE items.itemid IN (
SELECT
items.itemid
FROM items
JOIN item_discovery ON item_discovery.itemid=items.itemid
JOIN hosts ON hosts.hostid=items.hostid
WHERE item_discovery.ts_delete > 0
) LIMIT 100
);

--unreachable ZBX hosts with IP and error message. Zabbix 6.0, 6.4
SELECT proxy.host AS proxy, interface.ip, interface.port, hosts.host, interface.error
FROM hosts
LEFT JOIN hosts proxy ON hosts.proxy_hostid=proxy.hostid
JOIN interface ON interface.hostid=hosts.hostid
WHERE LENGTH(interface.error) > 0
AND interface.type=1
AND interface.main=1
ORDER BY 1,2;

--unreachable SNMP hosts with IP and error message. Zabbix 6.0, 6.4
SELECT proxy.host AS proxy, interface.ip, interface.port, hosts.host, interface.error
FROM hosts
LEFT JOIN hosts proxy ON hosts.proxy_hostid=proxy.hostid
JOIN interface ON interface.hostid=hosts.hostid
WHERE LENGTH(interface.error) > 0
AND interface.type=2
AND interface.main=1
ORDER BY 1,2;

--Zabbix queue. Zabbix 6.4
SELECT proxy.host AS proxy, hosts.host,
CASE interface.type
WHEN 0 THEN 'interface'
WHEN 1 THEN 'ZBX'
WHEN 2 THEN 'SNMP'
WHEN 3 THEN 'IPMI'
WHEN 4 THEN 'JMX'
END AS type,
interface.ip, interface.dns, interface.port, interface.error
CONCAT('zabbix.php?action=host.edit&hostid=',hosts.hostid) AS goTo
FROM interface
JOIN hosts ON hosts.hostid=interface.hostid
LEFT JOIN hosts proxy ON hosts.proxy_hostid=proxy.hostid
WHERE interface.main=1 AND interface.available=2 AND LENGTH(interface.error) > 0 AND hosts.status=0;

--set all HA nodes as gracefuly shut down. this must be done after kill -9
UPDATE ha_node SET status=1;

--the occurance of time mased functions
SELECT hosts.host, COUNT(*) FROM functions, items, hosts
WHERE functions.itemid=items.itemid
AND items.hostid=hosts.hostid
AND hosts.status=0 AND items.status=0 AND items.flags IN (0,4) AND hosts.flags IN (0,4)
AND functions.name IN ('nodata','time','fuzzytime','now','date','dayofmonth','dayofweek')
GROUP BY 1
ORDER BY 2 DESC
LIMIT 20;

--statistics of all trigger functions
SELECT COUNT(*), hosts.host FROM hosts, items
WHERE hosts.hostid=items.hostid AND hosts.status=0 AND items.status=0 AND items.flags IN (0,4) AND hosts.flags IN (0,4)
GROUP BY 2 ORDER BY 1 ASC;

--how many active sessions in last 10 minutes. Zabbix 5.0
SELECT COUNT(*)
FROM sessions
WHERE sessions.status=0
AND sessions.lastaccess > UNIX_TIMESTAMP(NOW() - INTERVAL 10 MINUTE);

--if there is any trigger which contains a lot of problems
SELECT COUNT(*),source,object,objectid FROM problem GROUP BY 2,3,4 ORDER BY 1 DESC LIMIT 10;

--print URLs for triggers dominating in escalation
SELECT COUNT(*),CONCAT('triggers.php?form=update&triggerid=', triggerid) AS 'URL' FROM escalations GROUP BY 2 ORDER BY 1 DESC LIMIT 10;

--biggest text metrics
SELECT LENGTH(history_text.value) AS length,
hosts.host,
items.key_,
CONCAT('history.php?itemids%5B0%5D=', history_text.itemid,'&action=showlatest') AS 'URL'
FROM history_text
JOIN items ON items.itemid=history_text.itemid
JOIN hosts ON hosts.hostid=items.hostid
WHERE LENGTH(history_text.value) > 50000 LIMIT 20\G

--increase the height of widget. Zabbix 6.4
UPDATE widget SET height=128 WHERE dashboard_pageid IN (
SELECT dashboard_pageid FROM dashboard_page WHERE dashboardid=327
);

--processes MySQL
SELECT LEFT(info, 140), LENGTH(info), time, state FROM INFORMATION_SCHEMA.PROCESSLIST where time>0 and command<>"Sleep" ORDER BY time;

--heaviest LLD rules. most of items. amount of items per LLD. Zabbix 6.0
SELECT COUNT(discovery.key_),
hosts.host,
discovery.key_,
discovery.delay
FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
JOIN item_discovery ON (item_discovery.itemid=items.itemid)
JOIN items discovery ON (discovery.itemid=item_discovery.parent_itemid)
WHERE items.status=0
AND items.flags=4
GROUP BY discovery.key_,
discovery.delay,
hosts.host
ORDER BY COUNT(discovery.key_) DESC
LIMIT 10;

--backtrack origin of host prototypes. Zabbix 6.0, 6.2, 6.4
SELECT hosts.name,
hosts2.host
FROM hosts
JOIN host_discovery ON (hosts.hostid=host_discovery.hostid)
LEFT JOIN hosts parent ON (parent.hostid=host_discovery.parent_hostid)
JOIN host_discovery host_discovery2 ON (parent.hostid=host_discovery2.hostid)
JOIN items items2 ON (items2.itemid=host_discovery2.parent_itemid)
JOIN hosts hosts2 ON (hosts2.hostid=items2.hostid)
WHERE hosts.flags=4;

--prototype items at template level which use positional macro. Zabbix 4.0
SELECT items.name, hosts.host AS template, CONCAT('disc_prototypes.php?form=update&parent_discoveryid=',item_discovery.parent_itemid,'&itemid=',items.itemid) AS URL FROM hosts, items, item_discovery
WHERE hosts.hostid=items.hostid AND items.itemid=item_discovery.itemid
AND hosts.status=3
AND items.flags IN (2)
AND items.name LIKE '%$%' AND items.name NOT LIKE '%{$%';

--Most recent data collector items. Zabbix 4.2, 4.4, 5.0
SELECT proxy.host AS proxy, hosts.host, items.itemid, items.key_
FROM items, hosts
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE hosts.hostid=items.hostid
ORDER BY items.itemid DESC
LIMIT 10;

--most recent triggers
SELECT DISTINCT triggers.triggerid, triggers.description, hosts.host, proxy.host AS proxy
FROM triggers
JOIN functions ON (functions.triggerid=triggers.triggerid)
JOIN items ON (items.itemid=functions.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE triggers.flags IN (0,4)
ORDER BY triggers.triggerid DESC
LIMIT 10;

--ZBX hosts unreachable. Zabbix 6.0
SELECT
proxy.host AS proxy,
hosts.host,
interface.error,
CONCAT('zabbix.php?action=host.edit&hostid=', hosts.hostid) AS goTo
FROM hosts
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
JOIN interface ON (interface.hostid=hosts.hostid)
WHERE LENGTH(interface.error) > 0
AND interface.type=1;

--SNMP hosts unreachable. Zabbix 6.0
SELECT
proxy.host AS proxy,
hosts.host,
interface.error,
CONCAT('zabbix.php?action=host.edit&hostid=', hosts.hostid) AS goTo
FROM hosts
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
JOIN interface ON (interface.hostid=hosts.hostid)
WHERE LENGTH(interface.error) > 0
AND interface.type=2;

--non-working external scripts. Zabbix 5.4, 6.0, 6.2
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

--Check native HA heartbeat. Zabbix 6.0, 6.2
SELECT * FROM ha_node;

--count of events. All version of Zabbix
SELECT COUNT(*),source FROM events GROUP BY source;

--show items by proxy. Zabbix 3.0, 3.2, 3.4, 4.0, 4.2, 4.4, 5.0, 5.2, 5.4, 6.0, 6.2
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

--which internal event is spamming database. Zabbix 4.0, 5.0
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

--nested objects and macro overrides. Zabbix 5.0, 6.0
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

--difference between template macro and host macro. Zabbix 5.0, 6.0
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

--devices and it's status. Zabbix 3.0, 3.2, 3.4, 4.0, 4.2, 4.4, 5.0, 5.2
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

--items in use. Zabbix 3.0, 3.2, 3.4, 4.0, 4.2, 4.4, 5.0, 5.2, 5.4, 6.0, 6.2
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

--enabled items behind proxy on enabled hosts
SELECT
proxy.host AS proxy,
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
WHERE hosts.status=0 
AND items.status=0 
GROUP BY proxy.host, items.type 
ORDER BY 1,2,3 DESC;

--exceptions in update interval. Zabbix 5.0
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

--all events closed by global correlation rule. Zabbix 4.0, 5.0, 6.0
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

--delete events closed by global correlation:
DELETE FROM events WHERE eventid IN (
SELECT
repercussion.eventid
FROM events repercussion
JOIN event_recovery ON (event_recovery.eventid=repercussion.eventid)
JOIN events rootCause ON (rootCause.eventid=event_recovery.c_eventid)
WHERE event_recovery.c_eventid IS NOT NULL
ORDER BY repercussion.clock ASC
) AND clock < 1682475866;

--hosts with a single template
SELECT proxy.host AS proxy,
hosts.host,
GROUP_CONCAT(template.host SEPARATOR ', ') AS templates,
COUNT(*)
FROM hosts
JOIN hosts_templates ON (hosts_templates.hostid=hosts.hostid)
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
LEFT JOIN hosts template ON (hosts_templates.templateid=template.hostid)
WHERE hosts.status IN (0,1) AND hosts.flags=0 GROUP BY 1,2 HAVING COUNT(*)=1 ORDER BY 1,3,2;

--print host objects which own a lonely template object
SELECT proxy.host AS proxy,
hosts.host,
template.host AS template,
COUNT(*)
FROM hosts
JOIN hosts_templates ON (hosts_templates.hostid=hosts.hostid)
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
LEFT JOIN hosts template ON (hosts_templates.templateid=template.hostid)
WHERE hosts.status IN (0,1) AND hosts.flags=0
AND template.host='write name of template here'
GROUP BY 1,2,3
HAVING COUNT(*)=1
ORDER BY 1,2;

--auditlog spaming database
SELECT action, resourcetype, COUNT(*) FROM auditlog WHERE clock >= UNIX_TIMESTAMP(NOW() - INTERVAL 2 HOUR) GROUP BY 1,2 ORDER BY COUNT(*) ASC;
SELECT action, resourcetype, COUNT(*) FROM auditlog WHERE clock >= UNIX_TIMESTAMP(NOW() - INTERVAL 2 HOUR) GROUP BY 1,2 ORDER BY COUNT(*) ASC;

--list all host and template level tags
SELECT hosts.status, host_tag.tag, host_tag.value, COUNT(*)
FROM hosts, host_tag
WHERE hosts.hostid=host_tag.hostid
AND hosts.status IN (0,3)
AND hosts.flags=0
GROUP BY 1,2,3
ORDER BY 4 DESC LIMIT 30;

--statistics about media types and delivery. Zabbix 4.0
SELECT actions.name AS actionName, users.alias AS sendTo, media_type.description AS mediaName,
CASE alerts.status
WHEN 0 THEN 'NOT_SEN'
WHEN 1 THEN 'SENT'
WHEN 2 THEN 'FAILED'
WHEN 3 THEN 'NEW'
END AS "alertStatus",
COUNT(*) AS count
FROM alerts
JOIN actions ON (actions.actionid=alerts.actionid)
JOIN media_type ON (media_type.mediatypeid=alerts.mediatypeid)
LEFT JOIN users ON (users.userid=alerts.userid)
WHERE alerts.alerttype=0
GROUP BY 1,2,3,4
ORDER BY 5 ASC;

--all active data collector items on enabled hosts. Zabbix 3.0, 4.0, 5.0, 6.0
SELECT hosts.host, items.name, items.type, items.key_, items.delay
FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE hosts.status=0
AND items.status=0
ORDER BY 1,2,3,4,5;

--all recent metrics which are using units 'B'
SELECT hosts.host AS host, items.key_ AS itemKey, items.name AS name, (history_uint.value/1024/1024/1024) AS GB
FROM history_uint
JOIN items ON (items.itemid=history_uint.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
JOIN (SELECT DISTINCT itemid AS id, MAX(history_uint.clock) AS clock
FROM history_uint
WHERE clock > UNIX_TIMESTAMP(NOW()-INTERVAL 65 MINUTE)
GROUP BY 1) t2 ON t2.id=history_uint.itemid
WHERE history_uint.clock=t2.clock
AND items.units='B'
ORDER BY 1,2;

--all recent metrics which are using units '%'
SELECT hosts.host AS host, items.key_ AS itemKey, items.name AS name, history.value AS percentage
FROM history
JOIN items ON (items.itemid=history.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
JOIN (SELECT DISTINCT itemid AS id, MAX(history.clock) AS clock
FROM history
WHERE clock > UNIX_TIMESTAMP(NOW()-INTERVAL 65 MINUTE)
GROUP BY 1) t2 ON t2.id=history.itemid
WHERE history.clock=t2.clock
AND items.units='%'
ORDER BY 1,2;

--PostgreSQL. all recent metrics which are using units 'B'
SELECT hosts.host AS host, items.key_ AS itemKey, items.name AS name, (history_uint.value/1024/1024/1024)::NUMERIC(10,2) AS GB
FROM history_uint
JOIN items ON (items.itemid=history_uint.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
JOIN (SELECT DISTINCT itemid AS id, MAX(history_uint.clock) AS clock
FROM history_uint
WHERE clock > EXTRACT(epoch FROM NOW()-INTERVAL '65 MINUTE')
GROUP BY 1) t2 ON t2.id=history_uint.itemid
WHERE history_uint.clock=t2.clock
AND items.units='B'
ORDER BY 1,2;

--PostgreSQL. delte sessions. Zabbix 6.0
DELETE FROM sessions WHERE sessionid IN (SELECT sessionid FROM sessions WHERE lastaccess < EXTRACT(EPOCH FROM (NOW() - INTERVAL '1 DAY')));

--MySQL. delete sessions older than 1d. Zabbix 5.0, 6.0
DELETE FROM sessions WHERE lastaccess < UNIX_TIMESTAMP(NOW()-INTERVAL 24 HOUR);

--which host, item is fulfiling the history_log table the most
SELECT hosts.host, items.key_, COUNT(*)
FROM history_log
JOIN items ON (items.itemid=history_log.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE history_log.clock > UNIX_TIMESTAMP(NOW()-INTERVAL 24 HOUR)
GROUP BY 1,2
ORDER BY 3 ASC;

--check if different interfaces (ZBX, SNMP) used in host level
SELECT DISTINCT hosts.host FROM interface first
JOIN interface second ON (first.hostid=second.hostid)
JOIN hosts ON (hosts.hostid=first.hostid)
WHERE first.type <> second.type;

--list unused AND secondary interfaces. Zabbix 6.0
SELECT hosts.host,
CASE interface.type
WHEN 0 THEN 'interface'
WHEN 1 THEN 'ZBX'
WHEN 2 THEN 'SNMP'
WHEN 3 THEN 'IPMI'
WHEN 4 THEN 'JMX'
END AS type,
interface.ip,interface.dns,interface.port
FROM interface
JOIN hosts ON (hosts.hostid=interface.hostid)
WHERE main=0 AND interfaceid NOT IN (SELECT DISTINCT interfaceid FROM items WHERE interfaceid IS NOT NULL);

--list unused AND secondary interfaces. Zabbix 6.0
DELETE FROM interface WHERE main=0 AND interfaceid NOT IN (SELECT DISTINCT interfaceid FROM items WHERE interfaceid IS NOT NULL);

--Check if all ZBX hosts are NOT using more than one interface
SELECT DISTINCT hosts.host, COUNT(*) AS interfaces FROM interface
JOIN hosts ON (hosts.hostid=interface.hostid)
WHERE interface.type=1 AND hosts.status=0 AND hosts.flags IN (0,4)
GROUP BY 1
HAVING COUNT(*)>1;

--Check if all SNMP hosts are NOT using more than one interface
SELECT DISTINCT hosts.host, COUNT(*) AS interfaces FROM interface
JOIN hosts ON (hosts.hostid=interface.hostid)
WHERE interface.type=2 AND hosts.status=0 AND hosts.flags IN (0,4)
GROUP BY 1
HAVING COUNT(*)>1;

--ratio between working and non-working JMX items. Zabbix 5.0
SELECT
proxy.host AS proxy,
items.delay,
CASE item_rtdata.state
WHEN 0 THEN 'normal'
WHEN 1 THEN 'unsupported'
END AS state,
COUNT(*)
FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
JOIN item_rtdata ON (item_rtdata.itemid=items.itemid)
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE items.type=16 AND items.status=0 AND hosts.status=0
GROUP BY 1,2,3
ORDER BY 1,4,3,2 ASC;

--PostgreSQL. all recent metrics which are using units '%'
SELECT hosts.host AS host, items.key_ AS itemKey, items.name AS name, history.value::NUMERIC(10,2) AS percentage
FROM history
JOIN items ON (items.itemid=history.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
JOIN (SELECT DISTINCT itemid AS id, MAX(history.clock) AS clock
FROM history
WHERE clock > EXTRACT(epoch FROM NOW()-INTERVAL '65 MINUTE')
GROUP BY 1) t2 ON t2.id=history.itemid
WHERE history.clock=t2.clock
AND items.units='%'
ORDER BY 1,2;

--determine which items report unsupported state:
SELECT COUNT(items.key_), hosts.host, items.key_, item_rtdata.error
FROM events
JOIN items ON (items.itemid=events.objectid)
JOIN hosts ON (hosts.hostid=items.hostid)
JOIN item_rtdata ON (item_rtdata.itemid=items.itemid)
WHERE source=3
AND object=4
AND items.status=0
AND items.flags IN (0,1,4)
AND LENGTH(item_rtdata.error) > 0
GROUP BY hosts.host, items.key_, item_rtdata.error
ORDER BY COUNT(items.key_);

--list all function names together with arguments
SELECT functions.name, functions.parameter, COUNT(*)
FROM functions
JOIN items ON (items.itemid=functions.itemid)
JOIN hosts ON (items.hostid=hosts.hostid)
JOIN triggers ON (triggers.triggerid=functions.triggerid)
WHERE hosts.status=0
AND items.status=0
AND triggers.status=0
GROUP BY 1,2
ORDER BY 1;

--update interval of owner in case LLD rule is dependent item. Zabbix 4.0, 4.2, 4.4, 5.0, 5.2, 5.4, 6.0, 6.2
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
SET SESSION SQL_LOG_BIN=0;
DELETE FROM trends WHERE itemid NOT IN (SELECT itemid FROM items);
DELETE FROM trends_uint WHERE itemid NOT IN (SELECT itemid FROM items);
DELETE FROM history_text WHERE itemid NOT IN (SELECT itemid FROM items);
DELETE FROM history_str WHERE itemid NOT IN (SELECT itemid FROM items);
DELETE FROM history_log WHERE itemid NOT IN (SELECT itemid FROM items);
DELETE FROM history WHERE itemid NOT IN (SELECT itemid FROM items);
DELETE FROM history_uint WHERE itemid NOT IN (SELECT itemid FROM items);

--drop table partition in MySQL
ALTER TABLE history_uint DROP PARTITION p2018_06_06;

--don't replicate transactions to the other servers in pool. don't write to binlog
SET SESSION SQL_LOG_BIN=0;

--Few MySQL key settings
SELECT
@@hostname,
@@version,
@@datadir,
@@innodb_file_per_table,
@@innodb_buffer_pool_size,
@@innodb_buffer_pool_instances,
@@innodb_flush_method,
@@innodb_log_file_size,
@@max_connections,
@@open_files_limit,
@@innodb_flush_log_at_trx_commit,
@@log_bin\G

--Host behind proxy 'z62prx' where interface is not healthy. Host is down. Zabbix 6.2
SELECT
hosts.host,
interface.error
FROM interface
JOIN hosts ON (hosts.hostid=interface.hostid)
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE interface.available=2
AND hosts.status=0
AND proxy.host='z62prx';

--Host/interface errors per all hosts behind proxy. Zabbix 6.2
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

--enabled and disabled LLD items, its key. Zabbix 5.0, 5.2, 5.4, 6.0
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

--item is not discovered anymore and will be deleted in
SELECT
hosts.host,
items.key_
FROM items
JOIN item_discovery ON (item_discovery.itemid=items.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE item_discovery.ts_delete > 0;

--delete items which are not discovered anymore
DELETE FROM items WHERE itemid IN (
SELECT x2.field FROM (
SELECT items.itemid AS field
FROM items, item_discovery, hosts
WHERE item_discovery.itemid=items.itemid
AND hosts.hostid=items.hostid
AND item_discovery.ts_delete > 0
) x2
);

--count of item is not discovered anymore and will be deleted
SELECT
hosts.host,
COUNT(*) AS count
FROM items
JOIN item_discovery ON (item_discovery.itemid=items.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE item_discovery.ts_delete > 0
GROUP BY 1 ORDER BY 2 DESC LIMIT 30;

--which dashboard has been using host group. Zabbix 5.0,5.2
SELECT
DISTINCT dashboard.name,
hstgrp.name
FROM widget_field
JOIN widget ON (widget.widgetid=widget_field.widgetid)
JOIN dashboard ON (dashboard.dashboardid=widget.dashboardid)
JOIN hstgrp ON (hstgrp.groupid=widget_field.value_groupid)
WHERE widget_field.value_groupid IN (2);

--which dashboard has been using host group id:2 for the input. Zabbix 5.4, 6.0
SELECT
DISTINCT dashboard.name,
hstgrp.name
FROM widget_field
JOIN widget ON (widget.widgetid=widget_field.widgetid)
JOIN dashboard_page ON (dashboard_page.dashboard_pageid=widget.dashboard_pageid)
JOIN dashboard ON (dashboard.dashboardid=dashboard_page.dashboardid)
JOIN hstgrp ON (hstgrp.groupid=widget_field.value_groupid)
WHERE widget_field.value_groupid IN (2);

--Zabbix agent auto-registration probes. Zabbix 5.0, 5.2, 5.4, 6.0
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

--items without a template. Zabbix 5.0, 6.0
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

--hosts with multiple interfaces. Zabbix 5.0, 6.0
SELECT
hosts.host
FROM interface
JOIN hosts ON (hosts.hostid=interface.hostid)
WHERE hosts.flags=0
GROUP BY hosts.host
HAVING COUNT(interface.interfaceid) > 1;

--amount of items not discovered anymore
SELECT
hosts.host,
COUNT(*) AS count
FROM items
JOIN item_discovery ON (item_discovery.itemid=items.itemid)
JOIN hosts ON (hosts.hostid=items.hostid) 
WHERE item_discovery.ts_delete > 0
GROUP BY 1 ORDER BY 2 ASC;

--linked template objects PostgreSQL. Zabbix 5.0, 5.2, 5.4, 6.0
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

--linked templates objects MySQL. Zabbix 5.0, 5.2, 5.4, 6.0
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

--which action is responsible. Zabbix 5.0
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

--non-working LLD rules. Zabbix 5.0, 6.0
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

--non-working data collector items. Zabbix 5.0, 6.0
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

--trigger evaluation problems. Zabbix 5.0, 6.0
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

--loneley item
SELECT
hosts.host,
items.key_,
CONCAT('items.php?form=update&itemid=', items.itemid) AS goTo
FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE hosts.status=0
AND hosts.flags=0
AND items.status=0
AND items.templateid IS NULL
AND items.flags=0;

--user sessions. Zabbix 6.0
SELECT
COUNT(*),
users.username
FROM sessions
JOIN users ON (users.userid=sessions.userid)
GROUP BY 2 ORDER BY 1 ASC;

--user sessions. Zabbix 5.0
SELECT
COUNT(*),
users.alias
FROM sessions
JOIN users ON (users.userid=sessions.userid)
GROUP BY 2 ORDER BY 1 ASC;

--open problems. Zabbix 5.0, 6.0
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

--item update frequency. Zabbix 5.0, 6.0
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

--unsupported items and LLD rules. Zabbix 5.0
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

--which dashboard widgets are using wildcards. Zabbix 6.0
SELECT
value_str AS pattern,
widget.name AS widgetName,
dashboard.name AS dashboardName
FROM widget_field, widget, dashboard_page, dashboard
WHERE widget_field.value_str like '%*%'
AND widget.widgetid=widget_field.widgetid
AND dashboard_page.dashboard_pageid=widget.dashboard_pageid
AND dashboard.dashboardid=dashboard_page.dashboard_pageid
ORDER BY 3,2,1;

--remove user refresh overrides in user level. Zabbix 6.0
DELETE FROM profiles WHERE idx='web.dashboard.widget.rf_rate';

--print all online users with rights group ID: 13. Zabbix 6.0
SELECT
users.username,
CASE
WHEN permission=0 THEN 'DENY'
WHEN permission=2 THEN 'READ_ONLY'
WHEN permission=3 THEN 'READ_WRITE'
END AS permission,
hstgrp.name AS name
FROM users, users_groups, sessions, usrgrp, rights, hstgrp
WHERE sessions.status=0
AND rights.groupid=13
AND users.userid=users_groups.userid
AND users.userid=sessions.userid
AND users_groups.usrgrpid=usrgrp.usrgrpid
AND users_groups.userid=users.userid
AND usrgrp.usrgrpid=rights.groupid
AND rights.id=hstgrp.groupid;

--clear error message for disabled items. Zabbix 4.4, 5.0, 5.2, 5.4, 6.0, 6.2
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

--set state as supported for disabled items. Zabbix 4.4, 5.0, 5.2, 5.4, 6.0, 6.2
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

--for hosts which are disable, set all items as supported
UPDATE item_rtdata
SET state=0
WHERE state=1
AND itemid IN (
SELECT items.itemid
FROM items, hosts
WHERE hosts.hostid=items.hostid
AND hosts.status=1
AND items.status=0
);

--most frequent integer numbers
SELECT
COUNT(*),
CONCAT('history.php?action=showlatest&itemids%5B0%5D=', itemid) AS latestData,
CONCAT('items.php?form=update&itemid=', itemid) AS conf
FROM (
SELECT itemid FROM history_uint LIMIT 99999
) b GROUP BY 2,3 ORDER BY 1 DESC LIMIT 10;

--most frequent decimal numbers
SELECT
COUNT(*),
CONCAT('history.php?action=showlatest&itemids%5B0%5D=', itemid) AS latestData,
CONCAT('items.php?form=update&itemid=', itemid) AS conf
FROM (
SELECT itemid FROM history LIMIT 99999
) b GROUP BY 2,3 ORDER BY 1 DESC LIMIT 10;

--how monitoring has been used
SELECT proxy.host AS proxy, CASE items.type WHEN 0 THEN 'Zabbix agent' WHEN 1 THEN 'SNMPv1 agent' WHEN 2 THEN 'Zabbix trapper' WHEN 3 THEN 'Simple check' WHEN 4 THEN 'SNMPv2 agent' WHEN 5 THEN 'Zabbix internal' WHEN 6 THEN 'SNMPv3 agent' WHEN 7 THEN 'Zabbix agent (active) check' WHEN 8 THEN 'Aggregate' WHEN 9 THEN 'HTTP test (web monitoring scenario step)' WHEN 10 THEN 'External check' WHEN 11 THEN 'Database monitor' WHEN 12 THEN 'IPMI agent' WHEN 13 THEN 'SSH agent' WHEN 14 THEN 'TELNET agent' WHEN 15 THEN 'Calculated' WHEN 16 THEN 'JMX agent' WHEN 17 THEN 'SNMP trap' WHEN 18 THEN 'Dependent item' WHEN 19 THEN 'HTTP agent' WHEN 20 THEN 'SNMP agent' WHEN 21 THEN 'Script item' END AS type, COUNT(*) FROM items JOIN hosts ON (hosts.hostid=items.hostid) LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid) WHERE hosts.status IN (0) AND items.status IN (0) GROUP BY 1,2 ORDER BY 1,2,3 DESC;

--show internal events for items which is working right now. Zabbix 5.0
SELECT events.name FROM events
WHERE source=3 AND object=4
AND objectid NOT IN (
SELECT items.itemid
FROM hosts, items, item_rtdata
WHERE items.hostid=hosts.hostid
AND items.itemid=item_rtdata.itemid
AND hosts.status=0
AND items.status=0
AND hosts.flags IN (0,4)
AND LENGTH(item_rtdata.error)=0
);

--mimic information of Zabbix. unsupported, disabled, active items. Zabbix 6.0
SELECT COUNT(*), CASE hosts.status
WHEN 0 THEN 'Active'
WHEN 1 THEN 'Disabled'
END AS hostStatus,
CASE item_rtdata.state
WHEN 0 THEN 'normal'
WHEN 1 THEN 'unsupported'
END AS itemState,
CASE items.status
WHEN 0 THEN 'Active'
WHEN 1 THEN 'Disabled'
END AS itemStatus
FROM items
JOIN item_rtdata ON (item_rtdata.itemid=items.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE hosts.status IN (0,1) AND items.status IN (0,1) AND items.flags IN (0,4)
GROUP BY 2,3,4
ORDER BY 2,3;

--reset scan of network discovery. Zabbix 6.0
SELECT * FROM drules;
UPDATE drules SET nextcheck=0;
SELECT * FROM drules;

--mimic information of Zabbix. extended. including LLD rules Zabbix 6.0
SELECT COUNT(*), CASE hosts.status
WHEN 0 THEN 'Active'
WHEN 1 THEN 'Disabled'
END AS hostStatus,
CASE item_rtdata.state
WHEN 0 THEN 'normal'
WHEN 1 THEN 'unsupported'
END AS itemState,
CASE items.status
WHEN 0 THEN 'Active'
WHEN 1 THEN 'Disabled'
END AS itemStatus,
CASE items.flags
WHEN 0 THEN 'normal item'
WHEN 1 THEN 'LLD rule'
WHEN 2 THEN 'Prototype'
WHEN 4 THEN 'auto created item'
END AS itemFlags
FROM items
JOIN item_rtdata ON (item_rtdata.itemid=items.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE hosts.status IN (0,1) AND items.status IN (0,1) AND items.flags IN (0,1,4)
GROUP BY 2,3,4,5
ORDER BY 2,3;

--detete internal events for items which is working right now. Zabbix 5.0
DELETE FROM events
WHERE source=3 AND object=4
AND objectid NOT IN (
SELECT items.itemid
FROM hosts, items, item_rtdata
WHERE items.hostid=hosts.hostid
AND items.itemid=item_rtdata.itemid
AND hosts.status=0
AND items.status=0
AND hosts.flags IN (0,4)
AND LENGTH(item_rtdata.error)=0
);

--print error active data collector items. Zabbix 4.4, 5.0, 5.2, 5.4, 6.0, 6.2
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

--healthy/active/enabled trigger objects, together with healthy items and healthy/enabled hosts. Zabbix 5.0
SELECT DISTINCT triggers.triggerid, hosts.host
FROM triggers, functions, items, hosts, item_rtdata
WHERE triggers.triggerid=functions.triggerid
AND functions.itemid=items.itemid
AND hosts.hostid=items.hostid
AND item_rtdata.itemid=items.itemid
AND hosts.status=0
AND items.status=0
AND triggers.status=0
AND LENGTH(triggers.error)=0
AND LENGTH(item_rtdata.error)=0;

--select internal trigger events for triggers which where not working some time ago, but triggers is healthy now. Zabbix 5.0
SELECT name FROM events
WHERE source=3 AND object=0
AND objectid NOT IN (
SELECT DISTINCT triggers.triggerid
FROM triggers, functions, items, hosts, item_rtdata
WHERE triggers.triggerid=functions.triggerid
AND functions.itemid=items.itemid
AND hosts.hostid=items.hostid
AND item_rtdata.itemid=items.itemid
AND hosts.status=0
AND hosts.flags IN (0,4)
AND items.status=0
AND triggers.status=0
AND LENGTH(triggers.error)=0
AND LENGTH(item_rtdata.error)=0
);

--delete INTERNAL trigger events for triggers which is healthy at this very second. since it's healthy now, we can remove old evidence why it was not working. this will allow to concentrate more preciselly on what other things is not working right now. Zabbix 5.0
DELETE FROM events
WHERE source=3 AND object=0
AND objectid NOT IN (
SELECT DISTINCT triggers.triggerid
FROM triggers, functions, items, hosts, item_rtdata
WHERE triggers.triggerid=functions.triggerid
AND functions.itemid=items.itemid
AND hosts.hostid=items.hostid
AND item_rtdata.itemid=items.itemid
AND hosts.status=0
AND hosts.flags IN (0,4)
AND items.status=0
AND triggers.status=0
AND LENGTH(triggers.error)=0
AND LENGTH(item_rtdata.error)=0
);

--show host object and proxy the item belongs to. Zabbix 5.0, 5.2, 5.4, 6.0
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

--unique items keys behind proxy. Zabbix 5.0, 5.2, 5.4, 6.0, 6.2
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

--size of MySQL DB. size of biggest tables
SELECT
ENGINE,
TABLE_TYPE,
TABLE_SCHEMA AS `DATABASE`,
TABLE_NAME AS `TABLE`,
ROUND(1.0*(DATA_LENGTH + INDEX_LENGTH) / 1024 / 1024,2) AS `TOTAL SIZE (MB)`,
ROUND(1.0*DATA_LENGTH/1024/1024, 2) AS `DATA SIZE (MB)`,
ROUND(1.0*INDEX_LENGTH/1024/1024, 2) AS `INDEX SIZE (MB)`,
ROUND(1.0*DATA_FREE/1024/1024, 2) AS `FREE SIZE (MB)`,
CURDATE() AS `TODAY`,
ROUND(DATA_FREE/(DATA_LENGTH+INDEX_LENGTH)*100,2) 'FRAGMENTED %',
TABLE_ROWS,
ROW_FORMAT,
TABLE_COLLATION,
VERSION
FROM information_schema.TABLES
WHERE table_schema NOT IN('information_schema', 'mysql','sys', 'performance_schema')
ORDER BY (DATA_LENGTH + INDEX_LENGTH)
DESC;

--show failed actions. Zabbix 5.0
SELECT CONCAT('tr_events.php?triggerid=',events.objectid,'&eventid=',events.eventid) AS OpenEventDetails,
FROM_UNIXTIME(alerts.clock) AS clock, alerts.error AS WhyItFailed,
actions.name AS ActionName,
CONCAT('actionconf.php?form=update&actionid=',actions.actionid) AS OpenAction
FROM alerts, events, actions
WHERE alerts.eventid=events.eventid
AND actions.actionid=alerts.actionid
AND alerts.status=2
ORDER BY alerts.clock DESC LIMIT 10;

--detect parallelity
SELECT
hosts.host,
items.delay,
MOD(items.itemid,table1.inSeconds) AS offset,
GROUP_CONCAT(items.itemid),
COUNT(*)
FROM items
JOIN (
SELECT DISTINCT delay, CASE delay
WHEN '10s' THEN '10'
WHEN '12s' THEN '12'
WHEN '15s' THEN '15'
WHEN '1m' THEN '60'
WHEN '2m' THEN '120'
WHEN '3m' THEN '180'
WHEN '5m' THEN '300'
WHEN '15m' THEN '900'
WHEN '1h' THEN '3600'
WHEN '1d' THEN '86400'
ELSE '0'
END AS inSeconds
FROM items
) table1 ON table1.delay=items.delay
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE hosts.status=0 AND items.status=0
GROUP BY 1,2,3
HAVING COUNT(*) > 1;

--summary of data collection and storage used
SELECT items.delay,
items.history,
items.trends, COUNT(*)
FROM items
JOIN hosts
WHERE hosts.hostid=items.hostid
AND items.status=0
AND hosts.status=0
GROUP BY 1,2,3
ORDER BY 4 ASC;

--statistics per calculated item. Zabbix 6.0
SELECT items.params,COUNT(*) FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE items.type=15
AND items.status=0
AND hosts.status=0
GROUP BY 1 ORDER BY 2 ASC;

--ZBX hosts with errors. Zabbix 6.4
SELECT proxy.host, hosts.host, interface.ip,interface.port,interface.error
FROM interface
JOIN hosts ON (hosts.hostid=interface.hostid)
LEFT JOIN hosts proxy ON (proxy.hostid=hosts.proxy_hostid)
WHERE LENGTH(interface.error)>0
AND interface.type=1
ORDER BY 3 ASC;

--SNMP hosts with errors. Zabbix 6.4
SELECT proxy.host, hosts.host, interface.ip,interface.port,interface.error
FROM interface
JOIN hosts ON (hosts.hostid=interface.hostid)
LEFT JOIN hosts proxy ON (proxy.hostid=hosts.proxy_hostid)
WHERE LENGTH(interface.error)>0
AND interface.type=2
ORDER BY 3 ASC;

--JMX hosts with errors. Zabbix 6.4
SELECT hosts.host, interface.ip,interface.port,interface.error
FROM interface
JOIN hosts ON (hosts.hostid=interface.hostid)
LEFT JOIN hosts proxy ON (proxy.hostid=hosts.proxy_hostid)
WHERE LENGTH(interface.error)>0
AND interface.type=4
ORDER BY 3 ASC;

--interface errors. Zabbix 6.4
SELECT hosts.host, interface.type, interface.error
FROM interface
JOIN hosts ON (hosts.hostid=interface.hostid)
WHERE LENGTH(interface.error)>0
ORDER BY 3 ASC;

--detach current table from application layer and set back another table
RENAME TABLE history TO history_old; CREATE TABLE history LIKE history_old;
RENAME TABLE history_uint TO history_uint_old; CREATE TABLE history_uint LIKE history_uint_old;
RENAME TABLE history_str TO history_str_old; CREATE TABLE history_str LIKE history_str_old;
RENAME TABLE history_log TO history_log_old; CREATE TABLE history_log LIKE history_log_old;
RENAME TABLE history_text TO history_text_old; CREATE TABLE history_text LIKE history_text_old;
RENAME TABLE trends TO trends_old; CREATE TABLE trends LIKE trends_old;
RENAME TABLE trends_uint TO trends_uint_old; CREATE TABLE trends_uint LIKE trends_uint_old;

--create old tables like current
CREATE TABLE history_old LIKE history;
CREATE TABLE history_uint_old LIKE history_uint;
CREATE TABLE history_str_old LIKE history_str;
CREATE TABLE history_log_old LIKE history_log;
CREATE TABLE history_text_old LIKE history_text;
CREATE TABLE trends_old LIKE trends;
CREATE TABLE trends_uint_old LIKE trends_uint;

--create current tables like old
CREATE TABLE history LIKE history_old;
CREATE TABLE history_uint LIKE history_uint_old;
CREATE TABLE history_str LIKE history_str_old;
CREATE TABLE history_log LIKE history_log_old;
CREATE TABLE history_text LIKE history_text_old;
CREATE TABLE trends LIKE trends_old;
CREATE TABLE trends_uint LIKE trends_uint_old;

--truncate old tables
TRUNCATE TABLE history_uint_old;
TRUNCATE TABLE trends_uint_old;
TRUNCATE TABLE history_old;
TRUNCATE TABLE trends_old;
TRUNCATE TABLE history_text_old;
TRUNCATE TABLE history_str_old;
TRUNCATE TABLE history_log_old;

--truncate current tables
TRUNCATE TABLE history_uint;
TRUNCATE TABLE trends_uint;
TRUNCATE TABLE history;
TRUNCATE TABLE trends;
TRUNCATE TABLE history_text;
TRUNCATE TABLE history_str;
TRUNCATE TABLE history_log;

--items which fails with data collection frequently. Zabbix 4.0, 5.0
SELECT
CONCAT('items.php?form=update&itemid=', events.objectid) AS 'URL',
events.name,
COUNT(*)
FROM events
WHERE events.source=3 AND events.object=4 AND LENGTH(events.name)>0
AND clock > UNIX_TIMESTAMP(NOW()-INTERVAL 1 HOUR)
GROUP BY 1,2
ORDER BY 3 DESC LIMIT 10;

--lld rules which fail. Zabbix 4.0, 5.0
SELECT
CONCAT('host_discovery.php?form=update&itemid=', events.objectid) AS 'URL',
events.name,
COUNT(*)
FROM events
WHERE events.source=3 AND events.object=5 AND LENGTH(events.name)>0
AND clock > UNIX_TIMESTAMP(NOW()-INTERVAL 1 HOUR)
GROUP BY 1,2
ORDER BY 3 DESC LIMIT 10;

--unexisting integer numbers
SELECT DISTINCT itemid FROM trends_uint WHERE itemid NOT IN (SELECT itemid FROM items);
DELETE FROM trends_uint WHERE itemid NOT IN (SELECT itemid FROM items);

--unexisting decimal numbers
SELECT DISTINCT itemid FROM trends WHERE itemid NOT IN (SELECT itemid FROM items);
DELETE FROM trends WHERE itemid NOT IN (SELECT itemid FROM items);

--print a part of sid which can be used to backtrack usage of calls in web servers access.log
SELECT RIGHT(sessions.sessionid,16), users.alias FROM sessions, users WHERE sessions.userid=users.userid AND users.alias='api';

--MySQL biggest tables for database 'zabbix'
SELECT table_name, table_rows, data_length, index_length,
ROUND(((data_length + index_length) / 1024 / 1024 / 1024),2) "Size in GB"
FROM information_schema.tables
WHERE table_schema = "zabbix"
ORDER BY ROUND(((data_length + index_length) / 1024 / 1024 / 1024),2) DESC
LIMIT 20;

--items and delay
SELECT items.delay, CASE items.type WHEN 0 THEN 'Zabbix agent' WHEN 1 THEN 'SNMPv1 agent' WHEN 2 THEN 'Zabbix trapper' WHEN 3 THEN 'Simple check' WHEN 4 THEN 'SNMPv2 agent' WHEN 5 THEN 'Zabbix internal' WHEN 6 THEN 'SNMPv3 agent' WHEN 7 THEN 'Zabbix agent (active) check' WHEN 8 THEN 'Aggregate' WHEN 9 THEN 'HTTP test (web monitoring scenario step)' WHEN 10 THEN 'External check' WHEN 11 THEN 'Database monitor' WHEN 12 THEN 'IPMI agent' WHEN 13 THEN 'SSH agent' WHEN 14 THEN 'TELNET agent' WHEN 15 THEN 'Calculated' WHEN 16 THEN 'JMX agent' WHEN 17 THEN 'SNMP trap' WHEN 18 THEN 'Dependent item' WHEN 19 THEN 'HTTP agent' WHEN 20 THEN 'SNMP agent' WHEN 21 THEN 'Script item' END AS type,  COUNT(*)
FROM hosts, items
WHERE hosts.hostid=items.hostid
AND hosts.status=0 AND items.status=0 AND hosts.flags IN (0,4) AND items.flags IN (0,4)
GROUP BY 1,2
ORDER BY 1 ASC;

--ODBC items, database monitor items
SELECT
proxy.host AS proxy,
hosts.host,
COUNT(*)
FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
LEFT JOIN hosts proxy ON (hosts.proxy_hostid=proxy.hostid)
WHERE hosts.status=0 AND items.status=0
AND items.type=11
GROUP BY 1,2
ORDER BY 1,2 DESC;

--profiling
SET profiling = 1;
SELECT * FROM sessions;
SHOW PROFILES;
SHOW PROFILE FOR QUERY 1;
EXPLAIN SELECT * FROM sessions\G
SET profiling = 0;

--special item update frequency
SELECT items.delay, items.params,  COUNT(*)
FROM hosts, items
WHERE hosts.hostid=items.hostid
AND hosts.status=0 AND items.status=0 AND hosts.flags IN (0,4) AND items.flags IN (0,4)
AND items.type=15
GROUP BY 1,2
ORDER BY 1 ASC;

--events daily
SELECT COUNT(*) FROM events WHERE clock >= UNIX_TIMESTAMP("2023-07-20 00:00:00") AND clock < UNIX_TIMESTAMP("2023-07-21 00:00:00");

--all SNMPv3 credentials in use. Zabbix 7.0
SET SESSION group_concat_max_len = 1000000; SELECT interface_snmp.version,
interface_snmp.bulk,
interface_snmp.community,
interface_snmp.securityname,
interface_snmp.securitylevel,
interface_snmp.authpassphrase,
interface_snmp.privpassphrase,
interface_snmp.authprotocol,
interface_snmp.privprotocol,
interface_snmp.contextname,
GROUP_CONCAT(interface.ip) AS hosts
FROM hosts
LEFT JOIN interface ON (interface.hostid=hosts.hostid)
LEFT JOIN interface_snmp ON (interface.interfaceid=interface_snmp.interfaceid)
WHERE hosts.status IN (0,1) AND hosts.flags=0 AND interface.type=2
GROUP BY 1,2,3,4,5,6,7,8,9,10\G

--trigger calculation fail. Zabbix 4.0, 5.0
SELECT
CONCAT('triggers.php?form=update&triggerid=', events.objectid) AS 'URL',
events.name,
COUNT(*)
FROM events
WHERE events.source=3 AND events.object=0 AND LENGTH(events.name)>0
AND clock > UNIX_TIMESTAMP(NOW()-INTERVAL 1 HOUR)
GROUP BY 1,2
ORDER BY 3 DESC LIMIT 10;

--which deciaml number takes the most hits in trends table. Zabbix 4.0, 5.0, 6.0
SELECT hosts.host, items.key_ FROM (
SELECT COUNT(*), itemid FROM trends WHERE itemid IN (
SELECT DISTINCT itemid FROM items WHERE value_type=0
)
GROUP BY 2
ORDER BY 1 DESC
LIMIT 50) table1, items, hosts
WHERE table1.itemid=items.itemid
AND hosts.hostid=items.hostid;

