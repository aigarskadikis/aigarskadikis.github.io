#!/bin/bash
# =================================================================
# Purpose of this script is to determine a problem faster and
# prevent a human error. Never use it without a presence of author!
# =================================================================

# define variables suitable for different unixtime situations
NOW=$(date "+%s")
AGO5M=$((NOW-300))
AGO10M=$((NOW-600))
AGO30M=$((NOW-1800))
AGO1H=$((NOW-3600))
AGO1D=$((NOW-86400))
AGO5D=$((NOW-432000))
AGO7D=$((NOW-604800))
AGO28D=$((NOW-2419200))


echo $1 = DB name
echo $2 = DB engine
echo

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

# test mysql connection
if [ "$MYSQL" -eq "1" ];then
mysql $DBNAME -e "SELECT VERSION()" > /dev/null 2>&1
exit_code=$?
if [ $exit_code -ne 0 ]; then
echo $exit_code. cannot connect to DB engine or database does not exist
exit $exit_code
fi
fi

echo POSTGRES=$POSTGRES
echo MYSQL=$MYSQL
echo

# test postgres connection
[ "$POSTGRES" -eq "1" ] && psql $DBNAME -t -c 'SELECT VERSION()' 

echo ######## VERSION OF ZABBIX DATABASE ########
[ "$MYSQL" -eq "1" ] && DBVESRION=$(mysql $DBNAME -B -N -e "
SELECT mandatory FROM dbversion;
")
[ "$POSTGRES" -eq "1" ] && DBVESRION=$(psql $DBNAME -t -c "
SELECT mandatory FROM dbversion;
")
echo "$DBVESRION = version of zabbix database"

echo EVENTS
[ "$MYSQL" -eq "1" ] && EVENTS=$(mysql $DBNAME -e "
SELECT source,COUNT(*) FROM events GROUP BY source;
")
[ "$POSTGRES" -eq "1" ] && EVENTS=$(psql $DBNAME -c "
SELECT source,COUNT(*) FROM events GROUP BY source;
")
echo "$EVENTS"

echo EVENTS IN LAST 1 HOUR
[ "$MYSQL" -eq "1" ] && EVENTS=$(mysql $DBNAME -e "
SELECT COUNT(*) FROM events WHERE clock > UNIX_TIMESTAMP(NOW()-INTERVAL 1 HOUR);
")
[ "$POSTGRES" -eq "1" ] && EVENTS=$(psql $DBNAME -c "
SELECT COUNT(*) FROM events WHERE clock > EXTRACT(EPOCH FROM (NOW() - INTERVAL '1 HOUR'));
")
echo "$EVENTS"

echo EVENTS IN LAST 1 HOUR
[ "$MYSQL" -eq "1" ] && SESSIONS=$(mysql $DBNAME -B -N -e "
SELECT COUNT(*) FROM sessions;
")
[ "$POSTGRES" -eq "1" ] && SESSIONS=$(psql $DBNAME -t -c "
SELECT COUNT(*) FROM sessions;
")
echo "$SESSIONS"



echo ALERTS IN LAST 8 HOURS
[ "$MYSQL" -eq "1" ] && ALERTS=$(mysql $DBNAME -e "
SELECT COUNT(*),
CASE alerts.status
WHEN 0 THEN 'NOT_SENT'
WHEN 1 THEN 'SENT'
WHEN 2 THEN 'FAILED'
WHEN 3 THEN 'NEW'
END AS status
FROM alerts
WHERE alerts.clock > UNIX_TIMESTAMP (NOW()-INTERVAL 8 HOUR)
GROUP BY alerts.status;
")
[ "$POSTGRES" -eq "1" ] && ALERTS=$(psql $DBNAME -t -c "
SELECT COUNT(*),
CASE alerts.status
WHEN 0 THEN 'NOT_SENT'
WHEN 1 THEN 'SENT'
WHEN 2 THEN 'FAILED'
WHEN 3 THEN 'NEW'
END AS status
FROM alerts
WHERE alerts.clock > EXTRACT(EPOCH FROM (NOW() - INTERVAL '8 HOUR'))
GROUP BY alerts.status;
")
echo "$ALERTS"


echo
