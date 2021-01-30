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

[ "$MYSQL" -eq "1" ] && SQL_CLIENT="mysql $DBNAME -B -N -e"

[ "$POSTGRES" -eq "1" ] && SQL_CLIENT="psql $DBNAME -t -c"

# test database connection
$SQL_CLIENT "
SELECT VERSION();
" > /dev/null 2>&1
exit_code=$?
if [ $exit_code -ne 0 ]; then
echo $exit_code. cannot connect to DB engine or database does not exist
exit $exit_code
fi

echo POSTGRES=$POSTGRES
echo MYSQL=$MYSQL
echo

echo ######## VERSION OF ZABBIX DATABASE ########
$SQL_CLIENT "
SELECT mandatory FROM dbversion;
"

echo
