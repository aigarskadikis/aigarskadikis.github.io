# hog processes, hog
ps -eo pcpu,pmem,pid,ppid,user,stat,args | sort -k 1 -r | head -6 | sed 's/$/\n/'

# rotate between values
echo "
one
two
" | grep -v "^$" | while IFS= read -r LINE
do {
echo $LINE
} done

# remove leading and trailing space with sed
sed 's/^[\t ]*//g;s/[\t ]*$//g'

# endless loop to deliver metric
while true; do zabbix_sender -z 127.0.0.1 -s $(hostname) -k agent.ping -o 1; sleep 30; done

# test disk throughput
dd if=/dev/urandom of=/db/mount/point/512M bs=1M count=512 oflag=direct
dd if=/dev/urandom of=/db/mount/point/5GB bs=1M count=5120 oflag=direct
dd if=/dev/urandom of=/db/mount/point/50GB bs=1M count=51200 oflag=direct
dd if=/dev/urandom of=/db/mount/point/65GB bs=1M count=65536 oflag=direct

# simulate javascript code without placing file in filesystem
zabbix_js --script <(echo 'return 1;') --param '' --loglevel 4 --timeout 60

# feed the output of file into javascript program
zabbix_js --script <(echo 'return value;') --loglevel 3 --timeout 60 --input <(grep -v "^$\|#" /etc/zabbix/zabbix_agentd.conf | sort)

# erase dublicate data in table 'history_text'. this does NOT work like discard unchanged
mysql \
--database='zabbix' \
--silent \
--skip-column-names \
--batch \
--execute="
SELECT items.itemid
FROM items, hosts
WHERE hosts.hostid=items.hostid
AND hosts.status IN (0,1)
AND items.value_type=4
AND items.flags IN (0,4)
" | \
while IFS= read -r ITEMID
do {
echo $ITEMID
sleep 0.01
echo "
DELETE t1 FROM history_text t1
INNER JOIN history_text t2
WHERE t1.clock < t2.clock
AND t1.value=t2.value
AND t1.itemid=t2.itemid
AND t1.itemid=$ITEMID
" | mysql zabbix
} done

# print metrics on screen
while true; do
echo -n 'total: ' && zabbix_get -s 127.0.0.1 -k system.cpu.util[];
echo -n 'user: ' && zabbix_get -s 127.0.0.1 -k system.cpu.util[,user];
echo -n 'system: '&& zabbix_get -s 127.0.0.1 -k system.cpu.util[,system];
echo -n 'guest: ' && zabbix_get -s 127.0.0.1 -k system.cpu.util[,guest];
echo -n 'guest_nice: ' && zabbix_get -s 127.0.0.1 -k system.cpu.util[,guest_nice];
echo '------------'
sleep 1; done;

# compress /var/lib/mysql by using gzip
tar --create --verbose --use-compress-program='gzip --fast' --file=/tmp/var.lib.mysql.tar.gz /var/lib/mysql

# compress /var/lib/mysql by using lz4
dnf install lz4
tar --create --verbose --use-compress-program='lz4' --file=/tmp/var.lib.mysql.tar.lz4 /var/lib/mysql

# track when trends are completed
watch -n.2 'mysql -e "show full processlist;" | grep insert'

# take poller #11, increase log level to 5 and stream live situation of what kind of items are fetched and how fast. Zabbix 6.0, 6.2, 6.4
zabbix_proxy -R log_level_increase="poller",11
zabbix_proxy -R log_level_increase="poller",11
tail -999f /var/log/zabbix/zabbix_proxy.log | grep "$(ps auxww | grep ":[ ]poller #11 " | awk '{ print $2 }')" | grep -E 'interfaceid:\S+ itemid:\S+ type:\S+|zbx_setproctitle.*idle'

# take poller #11, increase log level to 5 and stream live situation of what kind of items are fetched and how fast. Zabbix 5.0
zabbix_proxy -R log_level_increase="poller",1
zabbix_proxy -R log_level_increase="poller",1
tail -999f /var/log/zabbix/zabbix_proxy.log | grep "$(ps auxww | grep ":[ ]poller #1 " | awk '{ print $2 }')" | grep -E 'hostid:\S+ itemid:\S+ type:\S+|zbx_setproctitle.*idle'
tail -99f /var/log/zabbix/zabbix_proxy.log | grep "$(ps auxww | grep ":[ ]poller #1 " | awk '{ print $2 }')" | grep -Eo 'hostid:\S+ itemid:\S+ type:\S+|got.*sec.*idle'

# outgoing ports, persistent connection
ss --tcp --numeric --processes | grep zabbix_server

# process list with parents
ps -xafuww > /tmp/process.list.$(hostname).txt

# top memory processes
ps -eo pcpu,pmem,user,stat,args --sort -rss > /tmp/$(hostname).top.memory.processes.txt

# hungry CPU processes
ps -eo pcpu,pmem,user,stat,args --sort -time > /tmp/$(hostname).hungry.cpu.processes.txt

# all socket statistics
ss --tcp --numeric --processes > /tmp/$(hostname).socket.statistics.txt

# only listening ports and explanation
ss --tcp --numeric --listen --processes > /tmp/$(hostname).listening.ports.txt

# all installed package names
rpm -qa > /tmp/$(hostname).installed.rpms.txt

# generate random password by using bash tools
< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-20};echo;

# php official memory setting
find /etc -name zabbix.conf -exec grep --with-filename memory {} \;

# a sum per column
ls -lb | grep "history_str#" | awk '{ print $5 }' | python -c "import sys; print(sum(int(l) for l in sys.stdin))"

# test item key
zabbix_agent2 -t 'web.certificate.get[www.linkedin.com,443,]'
su zabbix --shell /bin/bash --command "zabbix_agent2 -t 'web.certificate.get[www.linkedin.com,443,]'"

# backup
psql z50 -c "COPY (SELECT * FROM trends) TO stdout DELIMITER ',' CSV" | lz4 > /tmp/z50.trends.csv.lz4
psql z50 -c "COPY (SELECT * FROM trends_uint) TO stdout DELIMITER ',' CSV" | lz4 > /tmp/z50.trends_uint.csv.lz4

# restore
psql z50 -c "\COPY trends FROM PROGRAM 'lz4cat /tmp/z50.trends.csv.lz4' DELIMITER ',' CSV"
psql z50 -c "\COPY trends_uint FROM PROGRAM 'lz4cat /tmp/z50.trends_uint.csv.lz4' DELIMITER ',' CSV"

# erase dublicate data in table 'history_str'. this does NOT work like discard unchanged
mysql \
--database='zabbix' \
--silent \
--skip-column-names \
--batch \
--execute="
SELECT items.itemid
FROM items, hosts
WHERE hosts.hostid=items.hostid
AND hosts.status IN (0,1)
AND items.value_type=1
AND items.flags IN (0,4)
" | \
while IFS= read -r ITEMID
do {
echo $ITEMID
sleep 0.01
echo "
DELETE t1 FROM history_str t1
INNER JOIN history_str t2
WHERE t1.clock < t2.clock
AND t1.value=t2.value
AND t1.itemid=t2.itemid
AND t1.itemid=$ITEMID
" | mysql zabbix
} done

# discard unchanged 'history_text' for all item IDs
mysql \
--database='zabbix' \
--silent \
--skip-column-names \
--batch \
--execute="
SELECT items.itemid
FROM items, hosts
WHERE hosts.hostid=items.hostid
AND hosts.status IN (0,1)
AND items.value_type=4
AND items.flags IN (0,4)
" | \
while IFS= read -r ITEMID
do {
echo $ITEMID
sleep 0.01
echo "
DELETE FROM history_text WHERE itemid=$ITEMID AND clock IN (
SELECT clock from (
SELECT clock, value, r, v2 FROM (
SELECT clock, value, LEAD(value,1) OVER (order by clock) AS v2,
CASE
WHEN value <> LEAD(value,1) OVER (order by clock)
THEN value
ELSE 'zero'
END AS r
FROM history_text WHERE itemid=$ITEMID
) x2
where r = 'zero'
) x3
WHERE v2 IS NOT NULL
)
" | mysql zabbix
} done

# discard unchanged 'history_str' for all item IDs
mysql \
--database='zabbix' \
--silent \
--skip-column-names \
--batch \
--execute="
SELECT items.itemid
FROM items, hosts
WHERE hosts.hostid=items.hostid
AND hosts.status IN (0,1)
AND items.value_type=1
AND items.flags IN (0,4)
" | \
while IFS= read -r ITEMID
do {
echo $ITEMID
sleep 0.01
echo "
DELETE FROM history_str WHERE itemid=$ITEMID AND clock IN (
SELECT clock from (
SELECT clock, value, r, v2 FROM (
SELECT clock, value, LEAD(value,1) OVER (order by clock) AS v2,
CASE
WHEN value <> LEAD(value,1) OVER (order by clock)
THEN value
ELSE 'zero'
END AS r
FROM history_str WHERE itemid=$ITEMID
) x2
where r = 'zero'
) x3
WHERE v2 IS NOT NULL
)
" | mysql zabbix
} done

# before starting service 'zabbix-proxy' truncate all data tables
DB=zabbix_proxy
CREDENTIALS=/root/.my.cnf
mysql \
--defaults-file=$CREDENTIALS \
--database=$DB \
--silent \
--skip-column-names \
--batch \
--execute="SELECT COUNT(*) FROM hosts WHERE status=3;" | \
grep -E "^0$" && mysql \
--defaults-file=$CREDENTIALS \
--database=$DB \
--silent \
--skip-column-names \
--batch \
--execute="SELECT table_name FROM ids" | while IFS= read -r TABLE
do {
echo mysql --defaults-file=$CREDENTIALS --database=$DB --execute="TRUNCATE TABLE $TABLE"
} done || echo "this seems like a central zabbix server, because there are template objects in database"

