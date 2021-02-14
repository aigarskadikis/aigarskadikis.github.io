#!/bin/bash
# =================================================================
# Purpose of this script is to:
# determine a problem faster;
# prevent a human error!
# =================================================================

if [[ "$1" == "--help" || "$1" == "-h" || -z "$1" ]]; then
clear
    cat <<EOF

PREREQUESITES:

This script requires access credentials located at:
~/.my.cnf
~/.pgpass

OPTIONS:

  -d DATABASENAME
  -e DBENGINE
  -l URLGUI

SAMPLE USAGE:

./check.sh -d z44 -e postgres -l "'http://z44.catonrug.net:144/'"
./check.sh -d zabbix -e mysql "'https://zbx.catonrug.net/'"
   
EOF
    exit 1
fi


while getopts ":d:e:l:0qx" opt; do
    case $opt in
        d)  DBNAME="$OPTARG" ;;
        e)  DBENGINE="$OPTARG" ;;
        l)  URL="$OPTARG" ;;
        0)  BOOLEAN1="1" ;;
        q)  BOOLEAN2="0" ;;
        x)  BOOLEAN3="1" ;;
        \?) echo "Invalid option: -$OPTARG" >&2; exit 1 ;;
        :)  echo "Option -$OPTARG requires an argument" >&2; exit 1 ;;
    esac
done



# define variables suitable for different unixtime situations. this is required:
# so the script can use the same SQL query for MySQL and PostgreSQL
NOW=$(date "+%s")
AGO5M=$((NOW-300))
AGO10M=$((NOW-600))
AGO30M=$((NOW-1800))
AGO1H=$((NOW-3600))
AGO1D=$((NOW-86400))
AGO5D=$((NOW-432000))
AGO7D=$((NOW-604800))
AGO28D=$((NOW-2419200))


# detect MySQL passwordless file
[ -f ~/.my.cnf ] && MYSQL=1

# detect PostreSQL passwordless file
[ -f ~/.pgpass ] && POSTGRES=1

# if second argument is explicitly postgres then ignore mysql
[ "$DBENGINE" == "postgres" ] && MYSQL=0

# if second argument is explicitly mysql then ignore postgres
[ "$DBENGINE" == "mysql" ] && POSTGRES=0

#URL="$3"

# special syntax rules for MySQL
if [ "$MYSQL" -eq "1" ];then
SQL_CLIENT="mysql $DBNAME -B -N -e"
SQL_CLIENT_H="mysql $DBNAME -B -e"
NUMERIC=""
EXPANDED_PG=""
EXPANDED_MY='\G'
fi

# special syntax rules for PostgrSQL
if [ "$POSTGRES" -eq "1" ];then
SQL_CLIENT="psql $DBNAME --no-align -t -c"
SQL_CLIENT_H="psql $DBNAME --no-align -t -c"
#NUMERIC="::NUMERIC(12,10)"
EXPANDED_PG="--expanded"
EXPANDED_MY=""
fi

# test database connection
$SQL_CLIENT "
SELECT VERSION();
" > /dev/null 2>&1
exit_code=$?
if [ $exit_code -ne 0 ]; then
echo $exit_code. cannot connect to DB engine or database does not exist
exit $exit_code
fi

clear

DBENGINE=$($SQL_CLIENT "
SELECT VERSION();
") && echo "$DBENGINE"
echo

VERSION=$($SQL_CLIENT "
SELECT mandatory FROM dbversion;
") && printf "%15d | version of zabbix\n" "$VERSION"

ALL_EVENTS_1H=$($SQL_CLIENT "
SELECT COUNT(*) FROM events WHERE clock > $AGO1H;
") && printf "%15d | events from last 1h\n" "$ALL_EVENTS_1H"

ALL_EVENTS_1D=$($SQL_CLIENT "
SELECT COUNT(*) FROM events WHERE clock > $AGO1D;
") && printf "%15d | events from last 1d\n" "$ALL_EVENTS_1D"

COUNT_OF_ALL_EVENTS=$($SQL_CLIENT "
SELECT COUNT(*) FROM events;
") && printf "%15d | count of event records\n" "$COUNT_OF_ALL_EVENTS"

COUNT_OF_SESSIONS=$($SQL_CLIENT "
SELECT COUNT(*) FROM sessions;
") && printf "%15d | count of sessions\n" "$COUNT_OF_SESSIONS"

ACTIVE_PROXIES=$($SQL_CLIENT "
SELECT COUNT(*) FROM hosts WHERE status=5;
") && printf "%15d | active proxies\n" "$ACTIVE_PROXIES"

OPEN_PROBLEM_EVENTS=$($SQL_CLIENT "
SELECT COUNT(*) FROM problem;
") && printf "%15d | open problem events\n" "$OPEN_PROBLEM_EVENTS"

echo

echo -n "looking for orphaned data"

# MySQL loves to enclose columns with `comlumn_name`, PostgreSQL don't like that
if [ "$MYSQL" -eq "0" ]; then
ORPHANED=$(sed "s|\`||g" $VERSION.sql)
else
ORPHANED=$(cat $VERSION.sql)
fi

echo "$ORPHANED" | while IFS= read -r SQLSELECT
do {
echo -n "."
OUT=$($SQL_CLIENT "
$SQLSELECT
")
[ ! -z "$OUT" ] && echo -e "\npossibly orphaned data:\n$SQLSELECT\n"
} done
echo -e "\n"


EVENTS=$($SQL_CLIENT "
SELECT source,COUNT(*) FROM events GROUP BY source;
") && echo -e "events:\n$EVENTS\n"

LLD_FREQUENCY=$($SQL_CLIENT "
SELECT COUNT(*),delay FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE items.flags=1 AND hosts.status=0 GROUP BY delay;
") && echo -e "LLD frequency for monitored hosts:\n$LLD_FREQUENCY\n"

# next 5 selects only for MySQL
if [ "$POSTGRES" -eq "0" ]; then

BIG_HISTORY_TEXT_HOST=$($SQL_CLIENT_H "
SELECT ho.name, ho.hostid, count(*) AS records, 
(count(*)* (SELECT AVG_ROW_LENGTH FROM information_schema.tables 
WHERE TABLE_NAME = 'history_text' and TABLE_SCHEMA = 'zabbix')/1024/1024) AS 'Total size average (Mb)', 
sum(length(history_text.value))/1024/1024 + 
sum(length(history_text.clock))/1024/1024 +
sum(length(history_text.ns))/1024/1024 + 
sum(length(history_text.itemid))/1024/1024 AS 'history_text Column Size (Mb)'
FROM history_text
LEFT OUTER JOIN items i on history_text.itemid = i.itemid 
LEFT OUTER JOIN hosts ho on i.hostid = ho.hostid 
WHERE ho.status IN (0,1)
AND history_text.clock > $AGO1D
GROUP BY ho.hostid
ORDER BY 4 DESC
LIMIT 1
$EXPANDED_MY
" $EXPANDED_PG) && [ ! -z "$BIG_HISTORY_TEXT_HOST" ] && \
echo -e "HOST consuming history_text table most:\n$BIG_HISTORY_TEXT_HOST\n"

BIG_HISTORY_LOG_HOST=$($SQL_CLIENT_H "
SELECT ho.name, ho.hostid, count(*) AS records, 
(count(*)* (SELECT AVG_ROW_LENGTH FROM information_schema.tables 
WHERE TABLE_NAME = 'history_log' and TABLE_SCHEMA = 'zabbix')/1024/1024) AS 'Total size average (Mb)', 
sum(length(history_log.value))/1024/1024 + 
sum(length(history_log.clock))/1024/1024 +
sum(length(history_log.ns))/1024/1024 + 
sum(length(history_log.itemid))/1024/1024 AS 'history_log Column Size (Mb)'
FROM history_log
LEFT OUTER JOIN items i on history_log.itemid = i.itemid 
LEFT OUTER JOIN hosts ho on i.hostid = ho.hostid 
WHERE ho.status IN (0,1)
AND history_log.clock > $AGO1D
GROUP BY ho.hostid
ORDER BY 4 DESC
LIMIT 1
$EXPANDED_MY
" $EXPANDED_PG) && [ ! -z "$BIG_HISTORY_LOG_HOST" ] && \
echo -e "HOST consuming history_log table most:\n$BIG_HISTORY_LOG_HOST\n"

BIG_HISTORY_STR_HOST=$($SQL_CLIENT_H "
SELECT ho.name, ho.hostid, count(*) AS records, 
(count(*)* (SELECT AVG_ROW_LENGTH FROM information_schema.tables 
WHERE TABLE_NAME = 'history_str' and TABLE_SCHEMA = 'zabbix')/1024/1024) AS 'Total size average (Mb)', 
sum(length(history_str.value))/1024/1024 + 
sum(length(history_str.clock))/1024/1024 +
sum(length(history_str.ns))/1024/1024 + 
sum(length(history_str.itemid))/1024/1024 AS 'history_str Column Size (Mb)'
FROM history_str
LEFT OUTER JOIN items i on history_str.itemid = i.itemid 
LEFT OUTER JOIN hosts ho on i.hostid = ho.hostid 
WHERE ho.status IN (0,1)
AND history_str.clock > $AGO1D
GROUP BY ho.hostid
ORDER BY 4 DESC
LIMIT 1
$EXPANDED_MY
" $EXPANDED_PG) && [ ! -z "$BIG_HISTORY_STR_HOST" ] && \
echo -e "HOST consuming history_str table most:\n$BIG_HISTORY_STR_HOST\n"

BIG_HISTORY_UINT_HOST=$($SQL_CLIENT_H "
SELECT ho.name, ho.hostid, count(*) AS records, 
(count(*)* (SELECT AVG_ROW_LENGTH FROM information_schema.tables 
WHERE TABLE_NAME = 'history_uint' and TABLE_SCHEMA = 'zabbix')/1024/1024) AS 'Total size average (Mb)', 
sum(length(history_uint.value))/1024/1024 + 
sum(length(history_uint.clock))/1024/1024 +
sum(length(history_uint.ns))/1024/1024 + 
sum(length(history_uint.itemid))/1024/1024 AS 'history_uint Column Size (Mb)'
FROM history_uint
LEFT OUTER JOIN items i on history_uint.itemid = i.itemid 
LEFT OUTER JOIN hosts ho on i.hostid = ho.hostid 
WHERE ho.status IN (0,1)
AND history_uint.clock > $AGO1D
GROUP BY ho.hostid
ORDER BY 4 DESC
LIMIT 1
$EXPANDED_MY
" $EXPANDED_PG) && [ ! -z "$BIG_HISTORY_UINT_HOST" ] && \
echo -e "HOST consuming history_uint table most:\n$BIG_HISTORY_UINT_HOST\n"

BIG_HISTORY_HOST=$($SQL_CLIENT_H "
SELECT ho.name, ho.hostid, count(*) AS records, 
(count(*)* (SELECT AVG_ROW_LENGTH FROM information_schema.tables 
WHERE TABLE_NAME = 'history' and TABLE_SCHEMA = 'zabbix')/1024/1024) AS 'Total size average (Mb)', 
sum(length(history.value))/1024/1024 + 
sum(length(history.clock))/1024/1024 +
sum(length(history.ns))/1024/1024 + 
sum(length(history.itemid))/1024/1024 AS 'history Column Size (Mb)'
FROM history
LEFT OUTER JOIN items i on history.itemid = i.itemid 
LEFT OUTER JOIN hosts ho on i.hostid = ho.hostid 
WHERE ho.status IN (0,1)
AND history.clock > $AGO1D
GROUP BY ho.hostid
ORDER BY 4 DESC
LIMIT 1
$EXPANDED_MY
" $EXPANDED_PG) && [ ! -z "$BIG_HISTORY_HOST" ] && \
echo -e "HOST consuming history table most:\n$BIG_HISTORY_HOST\n"

fi


BIG_HISTORY_LOG=$($SQL_CLIENT_H "
SELECT
CONCAT( $URL, 'history.php?itemids%5B0%5D=', history_log.itemid, '&action=showlatest' ) AS \"check data\",
CONCAT( $URL, 'items.php?form=update&hostid=', hosts.hostid, '&itemid=', history_log.itemid ) AS \"open item\",
hosts.host,
hosts.hostid,
history_log.itemid,
items.key_,
COUNT(history_log.itemid) AS \"count\", AVG(LENGTH(history_log.value))$NUMERIC AS \"avg size\",
(COUNT(history_log.itemid) * AVG(LENGTH(history_log.value)))$NUMERIC AS \"Count x AVG\"
FROM history_log
JOIN items ON (items.itemid=history_log.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE clock > $AGO1D
GROUP BY hosts.host,hosts.hostid,history_log.itemid,items.key_
ORDER BY \"Count x AVG\" DESC
LIMIT 1
$EXPANDED_MY
" $EXPANDED_PG) && [ ! -z "$BIG_HISTORY_LOG" ] && echo -e "ITEM consuming history_log table most:\n$BIG_HISTORY_LOG\n"

BIG_HISTORY_TEXT=$($SQL_CLIENT_H "
SELECT
CONCAT( $URL, 'history.php?itemids%5B0%5D=', history_text.itemid, '&action=showlatest' ) AS \"check data\",
CONCAT( $URL, 'items.php?form=update&hostid=', hosts.hostid, '&itemid=', history_text.itemid ) AS \"open item\",
hosts.host,
hosts.hostid,
history_text.itemid,
items.key_,
COUNT(history_text.itemid) AS \"count\", AVG(LENGTH(history_text.value))$NUMERIC AS \"avg size\",
(COUNT(history_text.itemid) * AVG(LENGTH(history_text.value)))$NUMERIC AS \"Count x AVG\"
FROM history_text
JOIN items ON (items.itemid=history_text.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE clock > $AGO1D
GROUP BY hosts.host,hosts.hostid,history_text.itemid,items.key_
ORDER BY \"Count x AVG\" DESC
LIMIT 1
$EXPANDED_MY
" $EXPANDED_PG) && [ ! -z "$BIG_HISTORY_TEXT" ] && echo -e "ITEM consuming history_text table most:\n$BIG_HISTORY_TEXT\n"

BIG_HISTORY_STR=$($SQL_CLIENT_H "
SELECT
CONCAT( $URL, 'history.php?itemids%5B0%5D=', history_str.itemid, '&action=showlatest' ) AS \"check data\",
CONCAT( $URL, 'items.php?form=update&hostid=', hosts.hostid, '&itemid=', history_str.itemid ) AS \"open item\",
hosts.host,
hosts.hostid,
history_str.itemid,
items.key_,
COUNT(history_str.itemid) AS \"count\", AVG(LENGTH(history_str.value))$NUMERIC AS \"avg size\",
(COUNT(history_str.itemid) * AVG(LENGTH(history_str.value)))$NUMERIC AS \"Count x AVG\"
FROM history_str
JOIN items ON (items.itemid=history_str.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE clock > $AGO1D
GROUP BY hosts.host,hosts.hostid,history_str.itemid,items.key_
ORDER BY \"Count x AVG\" DESC
LIMIT 1
$EXPANDED_MY
" $EXPANDED_PG) && [ ! -z "$BIG_HISTORY_STR" ] && echo -e "ITEM consuming history_str table most:\n$BIG_HISTORY_STR\n"

BIG_HISTORY_UINT=$($SQL_CLIENT_H "
SELECT
CONCAT( $URL, 'history.php?itemids%5B0%5D=', history_uint.itemid, '&action=showlatest' ) AS \"check data\",
CONCAT( $URL, 'items.php?form=update&hostid=', hosts.hostid, '&itemid=', history_uint.itemid ) AS \"open item\",
hosts.host,
hosts.hostid,
history_uint.itemid,
items.key_,
COUNT(history_uint.itemid) AS \"count\", AVG(history_uint.value)$NUMERIC AS \"avg size\",
(COUNT(history_uint.itemid) * AVG(history_uint.value))$NUMERIC AS \"Count x AVG\"
FROM history_uint
JOIN items ON (items.itemid=history_uint.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE clock > $AGO1D
GROUP BY hosts.host,hosts.hostid,history_uint.itemid,items.key_
ORDER BY \"Count x AVG\" DESC
LIMIT 1
$EXPANDED_MY
" $EXPANDED_PG) && [ ! -z "$BIG_HISTORY_UINT" ] && echo -e "ITEM consuming history_uint table most:\n$BIG_HISTORY_UINT\n"

BIG_HISTORY=$($SQL_CLIENT_H "
SELECT
CONCAT( $URL, 'history.php?itemids%5B0%5D=', history.itemid, '&action=showlatest' ) AS \"check data\",
CONCAT( $URL, 'items.php?form=update&hostid=', hosts.hostid, '&itemid=', history.itemid ) AS \"open item\",
hosts.host,
hosts.hostid,
history.itemid,
items.key_,
COUNT(history.itemid) AS \"count\", AVG(history.value)$NUMERIC AS \"avg size\",
(COUNT(history.itemid) * AVG(history.value))$NUMERIC AS \"Count x AVG\"
FROM history
JOIN items ON (items.itemid=history.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE clock > $AGO1D
GROUP BY hosts.host,hosts.hostid,history.itemid,items.key_
ORDER BY \"Count x AVG\" DESC
LIMIT 1
$EXPANDED_MY
" $EXPANDED_PG) && [ ! -z "$BIG_HISTORY" ] && echo -e "ITEM consuming history table most:\n$BIG_HISTORY\n"


PLAIN_ITEMS_AT_HOST_LEVEL=$($SQL_CLIENT_H "
SELECT hosts.host,
items.key_,
CONCAT( $URL, 'history.php?itemids%5B0%5D=', items.itemid, '&action=showlatest' ) AS \"check data\",
CONCAT( $URL, 'items.php?form=update&hostid=', hosts.hostid, '&itemid=', items.itemid ) AS \"open item\"
FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE hosts.status=0
AND items.templateid IS NULL
AND items.flags NOT IN (4,1)
AND items.status=0
LIMIT 1
$EXPANDED_MY
" $EXPANDED_PG) && [ ! -z "$PLAIN_ITEMS_AT_HOST_LEVEL" ] && echo -e "Plain items at host level:\n$PLAIN_ITEMS_AT_HOST_LEVEL\n"


UNREACHABLE_HOSTS=$($SQL_CLIENT_H "
SELECT hosts.host, interface.ip, interface.dns, interface.useip,
CASE interface.type WHEN 1 THEN 'ZBX' WHEN 2 THEN 'SNMP'
WHEN 3 THEN 'IPMI' WHEN 4 THEN 'JMX' END AS \"type\",
hosts.error FROM hosts
JOIN interface ON interface.hostid=hosts.hostid
WHERE hosts.available=2 AND interface.main=1 AND hosts.status=0
LIMIT 1
$EXPANDED_MY
" $EXPANDED_PG) && [ ! -z "$UNREACHABLE_HOSTS" ] && echo -e "Unreachable host:\n$UNREACHABLE_HOSTS\n"

STATUS_OF_ALERTS=$($SQL_CLIENT_H "
SELECT COUNT(*),CASE alerts.status
WHEN 0 THEN 'NOT_SENT'
WHEN 1 THEN 'SENT'
WHEN 2 THEN 'FAILED'
WHEN 3 THEN 'NEW'
END AS \"status\",
actions.name
FROM alerts
JOIN actions ON (alerts.actionid=actions.actionid)
WHERE alerts.clock > $AGO1H
GROUP BY alerts.status,actions.name;
" $EXPANDED_PG) && [ ! -z "$STATUS_OF_ALERTS" ] && echo -e "Status of alerts in last 1h:\n$STATUS_OF_ALERTS\n"

TRIGGER_EVAL_PROBLEM=$($SQL_CLIENT_H "
SELECT DISTINCT hosts.name, COUNT(hosts.name) AS \"count\", items.key_ AS \"key\", triggers.error
FROM events
JOIN triggers ON (events.objectid=triggers.triggerid)
JOIN functions ON (functions.triggerid = triggers.triggerid)
JOIN items ON (items.itemid = functions.itemid)
JOIN hosts ON (items.hostid = hosts.hostid)
WHERE events.source=3 AND events.object=0 AND triggers.flags IN (0,4) AND triggers.state=1
AND events.clock > $AGO1D
GROUP BY hosts.name,items.key_,triggers.error
ORDER BY COUNT(hosts.name) ASC, hosts.name, items.key_, triggers.error
LIMIT 1
$EXPANDED_MY
" $EXPANDED_PG) && [ ! -z "$TRIGGER_EVAL_PROBLEM" ] && echo -e "Top trigger eveluation problem in last 1d:\n$TRIGGER_EVAL_PROBLEM\n"

[ "$VERSION" -lt "4040000" ] && UNSUPPORTED_ITEMS=$($SQL_CLIENT "
SELECT hosts.host AS \"host\",
       events.objectid AS \"itemid\",
       items.key_ AS \"key\",
       events.name AS \"error\",
       count(events.objectid) AS \"occurrence\"
FROM events
JOIN items ON (items.itemid=events.objectid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE events.source = 3
  AND events.object = 4
  AND LENGTH(events.name)>0
GROUP BY hosts.host,
events.objectid,
items.key_,
events.name
ORDER BY COUNT(*) DESC
LIMIT 1
$EXPANDED_MY
" $EXPANDED_PG) && echo -e "Top unsupported item:\n$UNSUPPORTED_ITEMS\n"

[ "$VERSION" -gt "4020000" ] && UNSUPPORTED_ITEMS2=$($SQL_CLIENT "
SELECT hosts.host,COUNT(*)
FROM items
JOIN hosts ON (items.hostid=hosts.hostid)
JOIN item_rtdata ON (item_rtdata.itemid=items.itemid)
WHERE hosts.status=0
AND LENGTH(item_rtdata.error) > 0
GROUP BY hosts.host
ORDER BY COUNT(*) DESC
LIMIT 1;
") && echo -e "Top unsupported item:\n$UNSUPPORTED_ITEMS2\n"

echo

