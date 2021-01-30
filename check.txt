#!/bin/bash
# =================================================================
# Purpose of this script is to:
# determine a problem faster;
# prevent a human error!
# =================================================================

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

#echo $1 = DB name
#echo $2 = DB engine
#echo



# if first argument is given then that will be database name
if [ ! -z "$1" ]; then
DBNAME=$1
else

# if argument is not given then pick up database variable from backend configuration file
if [ -f /etc/zabbix/zabbix_server.conf ]; then
DBNAME=$(grep -oP 'DBName=\K\w+' /etc/zabbix/zabbix_server.conf)
fi

# end of first argument
fi

# detect MySQL passwordless file
[ -f ~/.my.cnf ] && MYSQL=1

# detect PostreSQL passwordless file
[ -f ~/.pgpass ] && POSTGRES=1

# if second argument is explicitly postgres then ignore mysql
[ "$2" == "postgres" ] && MYSQL=0

# if second argument is explicitly mysql then ignore postgres
[ "$2" == "mysql" ] && POSTGRES=0

if [ "$MYSQL" -eq "1" ];then
SQL_CLIENT="mysql $DBNAME -B -N -e"
NUMERIC=""
EXPANDED=""
fi

if [ "$POSTGRES" -eq "1" ];then
SQL_CLIENT="psql $DBNAME --no-align -t -c"
NUMERIC="::NUMERIC(10,2)"
EXPANDED="--expanded"
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

#echo POSTGRES=$POSTGRES
#echo MYSQL=$MYSQL
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

EVENTS=$($SQL_CLIENT "
SELECT source,COUNT(*) FROM events GROUP BY source;
") && echo -e "events:\n$EVENTS\n"

LLD_FREQUENCY=$($SQL_CLIENT "
SELECT COUNT(*),delay FROM items
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE items.flags=1 AND hosts.status=0 GROUP BY delay;
") && echo -e "LLD frequency for monitored hosts:\n$LLD_FREQUENCY\n"

BIG_HISTORY_LOG=$($SQL_CLIENT "
SELECT hosts.host,history_log.itemid,items.key_,
COUNT(history_log.itemid) AS \"count\", AVG(LENGTH(history_log.value))$NUMERIC AS \"avg size\",
(COUNT(history_log.itemid) * AVG(LENGTH(history_log.value)))$NUMERIC AS \"Count x AVG\"
FROM history_log 
JOIN items ON (items.itemid=history_log.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE clock > $AGO30M
GROUP BY hosts.host,history_log.itemid,items.key_
ORDER BY 6 DESC
LIMIT 1
" $EXPANDED) && echo -e "Most consuming history_log item:\n$BIG_HISTORY_LOG\n"

BIG_HISTORY_TEXT=$($SQL_CLIENT "
SELECT hosts.host,history_text.itemid,items.key_,
COUNT(history_text.itemid) AS \"count\", AVG(LENGTH(history_text.value))$NUMERIC AS \"avg size\",
(COUNT(history_text.itemid) * AVG(LENGTH(history_text.value)))$NUMERIC AS \"Count x AVG\"
FROM history_text 
JOIN items ON (items.itemid=history_text.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE clock > $AGO1D
GROUP BY hosts.host,history_text.itemid,items.key_
ORDER BY 6 DESC
LIMIT 1
" $EXPANDED) && echo -e "Most consuming history_text item:\n$BIG_HISTORY_TEXT\n"

BIG_HISTORY_STR=$($SQL_CLIENT "
SELECT hosts.host,history_str.itemid,items.key_,
COUNT(history_str.itemid) AS \"count\", AVG(LENGTH(history_str.value))$NUMERIC AS \"avg size\",
(COUNT(history_str.itemid) * AVG(LENGTH(history_str.value)))$NUMERIC AS \"Count x AVG\"
FROM history_str 
JOIN items ON (items.itemid=history_str.itemid)
JOIN hosts ON (hosts.hostid=items.hostid)
WHERE clock > $AGO1D
GROUP BY hosts.host,history_str.itemid,items.key_
ORDER BY 6 DESC
LIMIT 1
" $EXPANDED) && echo -e "Most consuming history_str item:\n$BIG_HISTORY_STR\n"

UNREACHABLE_HOSTS=$($SQL_CLIENT "
SELECT hosts.host, interface.ip, interface.dns, interface.useip,
CASE interface.type WHEN 1 THEN 'ZBX' WHEN 2 THEN 'SNMP'
WHEN 3 THEN 'IPMI' WHEN 4 THEN 'JMX' END AS \"type\",
hosts.error FROM hosts
JOIN interface ON interface.hostid=hosts.hostid
WHERE hosts.available=2 AND interface.main=1 AND hosts.status=0
LIMIT 1
" $EXPANDED) && echo -e "Unreachable host:\n$UNREACHABLE_HOSTS\n"


echo

