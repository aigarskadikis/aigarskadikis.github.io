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

# debug snmp
snmpwalk -v'2c' -c'public' -Dsnmp IP OID

# debug snmp transport
snmpwalk -v'2c' -c'public' -Dtransport IP OID

# debug in hex format
snmpwalk -v'2c' -c'public' -dd IP OID

# poller busy
watch -n1 'ps auxww | grep -Eo "[:] poller #.*"'

# slow query
awk -F'slow query: | sec, "' '{ if (NF == 3) printf "%.6f\t%s...\n", $2, substr($3, 1, 160) }' /var/log/zabbix/zabbix_server.log | sort -nr | head -n 20

# slow housekeeper
awk -F'in | sec,' '/housekeeper/ && NF >= 2 { split($0, a, ":"); timestamp = a[2] ":" a[3]; printf "%.6f\t%s\n", $2, timestamp }' /var/log/zabbix/zabbix_server.log | sort -nr | head -n 10

# watch backlog
watch -n1 'zabbix_server -R diaginfo=historycache | grep -A1 "history cache diagnostic information"'

# memory usage for agentd
ps_mem --total -p $(pidof zabbix_agentd | sed 's| |,|g')

# memory usage for agent2
ps_mem --total -p $(pidof zabbix_agent2 | sed 's| |,|g')

# memory usage for agentd in MB
echo "$(($(ps_mem --total -p $(pidof zabbix_agentd | sed 's| |,|g')) / 1024 / 1024))"

# received traffic which originated only from remote host
tcpdump -e -i any -c 1000 -nn -tt -q -l 'ip and inbound and tcp[tcpflags] & tcp-syn != 0 and tcp[tcpflags] & tcp-ack == 0'

# convert to readable date
tail -99f /var/log/zabbix/zabbix_proxy.log | sed 's/\([0-9]\+\):\(....\)\(..\)\(..\):\(..\)\(..\)\(..\)/\2-\3-\4 \5:\6:\7/'

# convert to readable date including PID
tail -99f /var/log/zabbix/zabbix_proxy.log | sed 's/\([0-9]\+\):\(....\)\(..\)\(..\):\(..\)\(..\)\(......\)/\2-\3-\4 \5:\6:\7 PID:\1/'

# look for 2nd match between "start pattern" and "end pattern"
cat /var/log/zabbix/zabbix_proxy.log |\
awk '
/start pattern/ {
found++
}
found == 2
/end pattern/ && found == 2 {
exit
}'

# prometheus pattern capture
cat /var/log/zabbix/zabbix_proxy.log |\
awk '
/Prometheus raw data start/ {
found++
}
found == 2
/Prometheus raw data end/ && found == 2 {
exit
}' | grep –v 'Prometheus raw data' > /tmp/prom.input.txt

# backup whole etc
DATE=`date '+%Y.%m.%d.%H.%M'` && cd /etc && mkdir -p ~/backup${DATE}${PWD} && cp -a * ~/backup${DATE}${PWD}

# extract creation of tables. remove break line, show printable characters add _new at the end
cat schema.sql | \
tr -d '\n' | \
sed 's|;|;\n|g' | \
grep -E "^CREATE TABLE (history|trends).*" | \
sed -E '
s|\s+| |g;
s|CREATE TABLE (history[^ (,]*)|CREATE TABLE \1_new|;
s|CREATE TABLE (trends[^ (,]*)|CREATE TABLE \1_new|' > /tmp/create_new.sql

# create fork of timescaledb
cat schema.sql | \
sed 's|^.UPDATE config.*||' | \
sed "s|', 'clock', chunk_time_i
nterval|_new', 'clock', chunk_time_interval|"

# remaster timescaledb create script to work with _new tables
cat schema.sql | \
sed 's|^.UPDATE config.*||' | \
sed "s|', 'clock', chunk_time_interval|_new', 'clock', chunk_time_interval|" > /tmp/enable.for.new.sql

# prepare temporary tables
DB=sample6023
OLD=_old
NEW=_new
echo "
history
history_uint
history_str
history_log
history_text
trends
trends_uint
" | \
grep -v "^$" | \
while IFS= read -r TABLE
do {
psql $DB --command="
ALTER TABLE $TABLE RENAME TO $TABLE$OLD;
ALTER TABLE $TABLE$NEW RENAME TO $TABLE;
ALTER TABLE $TABLE OWNER TO zabbix;
CREATE TABLE $TABLE$NEW (LIKE $TABLE INCLUDING ALL);
ALTER TABLE $TABLE$NEW OWNER TO zabbix;
"
} done

# Convert the biggest data into hyper tables. This process will take multiple hours/days
DB=sample6023
OLD=_old
NEW=_new
echo "
trends
trends_uint
history
history_uint
history_str
history_log
history_text
" | \
grep -v "^$" | \
while IFS= read -r TABLE
do {
echo "converting $TABLE$OLD into hyper tables started at $(date)"
psql $DB --command="
INSERT INTO $TABLE$NEW SELECT * FROM $TABLE$OLD ON CONFLICT DO NOTHING;
"
} done

# merga data together
DB=sample6023
OLD=_old
NEW=_new
TMP=_tmp
echo "
trends
trends_uint
history
history_uint
history_str
history_log
history_text
" | \
grep -v "^$" | \
while IFS= read -r TABLE
do {
echo "merging all data together for $TABLE started at $(date)"
psql $DB --command="
ALTER TABLE $TABLE RENAME TO $TABLE$TMP;
ALTER TABLE $TABLE$NEW RENAME TO $TABLE;
INSERT INTO $TABLE SELECT * FROM $TABLE$TMP ON CONFLICT DO NOTHING;
"
} done

# drop unnecary tables. print sensitive statements
OLD=_old
TMP=_tmp
echo "
trends
trends_uint
history
history_uint
history_str
history_log
history_text
" | \
grep -v "^$" | \
while IFS= read -r TABLE
do {
echo "DROP TABLE $TABLE$TMP;"
echo "DROP TABLE $TABLE$OLD;"
} done

# oracle connection test
cd /opt/oracle/instantclient_23_7 && ./sqlplus "system/oracle@(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(Host=10.10.6.26)(Port=49161))(CONNECT_DATA=(SID=xe)))"

# postgresql connection test
PGHOST=10.10.6.23 PGPORT=5432 PGUSER=zbx_monitor PGPASSWORD='passwordGoesHere' psql

# MSSQL connection test. '-C' means Trust Server Certificate
sqlcmd --server '10.10.4.21' --user-name 'zbx_monitor' --password 'passwordGoesHere' -C

# memory situation in megabytes
ps -eo rss,pid,user,command --sort -size | awk '{ hr=$1/1024 ; printf("%13.2f Mb ",hr) } { for ( x=4 ; x<=NF ; x++ ) { printf("%s ",$x) } print "" }' | cut -d "" -f2 | cut -d "-" -f1

# interface unavailable
grep :20250124:01 /var/log/zabbix/zabbix_server.log | grep -Eo "\S+ interface unavailable" | sort | uniq -c
grep :20250124:03 /var/log/zabbix/zabbix_server.log | grep -Eo "\S+ interface unavailable" | sort | uniq -c

# target second appierence of block
awk '/Prometheus raw data start/{found++} found==2; /Prometheus raw data end/ && found==2{exit}' /var/log/zabbix/zabbix_proxy.log

# merge back
cat frontend.config.and.logs.tar.xz_* > together.tar.xz

# yt-dlp best audio and video 
yt-dlp -f "bv[ext!=webm]+ba/b[ext!=webm]" --download-archive archive.log

# delete line with sed
sed -i '/^Hostname=Zabbix proxy$/d' /etc/zabbix/zabbix_proxy.conf
sed -i '/^Hostname=Zabbix server$/d' /etc/zabbix/zabbix_agentd.conf
sed -i '/^Hostname=Zabbix server$/d' /etc/zabbix/zabbix_agent2.conf

# use rdesktop with 150 dpi scalling
rdesktop -u 'Administrator' -p 'Passw0rd' -g 1920x1080@150 -a 32 -x 1 -b ip.address.of.client -x 0x80

# list files inside package rpm
rpm -ql package_name

# convert short IPv6 format to long
python3 -c "import ipaddress; print(ipaddress.IPv6Address('2001:db8::1').exploded)"

# test port
nc -zv ip 10050

# crop video from 1920x1200 to 1920x1080p
ffmpeg -i input.mkv -vf "crop=1920:1080:0:60" -c:v libx264 -crf 18 -preset veryfast -c:a copy output.mkv

# screen with logging enabled
screen -L -Logfile /tmp/screen.log

# avoid asking for service restarts on Ubuntu 22/24
echo "\$nrconf{restart} = 'a';" | sudo tee /etc/needrestart/conf.d/no-prompt.conf

# check what exactly perform write
iotop --kilobytes --delay=3 --iter=5

# history syncer running
watch -n1 "ps auxww | grep -Eo '[:] history syncer.*'"

# see the origin of data collection
strace -s 2048 -f -v -o /tmp/sar.log sar 1 1
cat /tmp/sar.log | grep '/proc/stat'

# volume configuration
lvm lvs -o+lv_layout,stripes > /tmp/volume.conf.txt

# CPU information
lscpu > /tmp/lscpu.txt

# 2 snapshots of busyest CPU processes
top -b -o +%CPU -n 2 2>&1 1> /tmp/top.cpu.txt

# install iperf3, iostat fio
dnf install sysstat fio iperf3

# test disk speed
cd /var/lib/mysql
fio --name TEST --eta-newline=5s --filename=test.img --rw=randwrite --size=500m --io_size=10g --blocksize=4k --ioengine=libaio --fsync=1 --iodepth=32 --direct=1 --numjobs=1 --runtime=60 --group_reporting

# QD1 4k Random Write - IO performance/IOPS: >= 3000 IOPS
fio --name TEST --eta-newline=5s --filename=test.img --rw=randwrite --size=500m --io_size=10g --blocksize=4k --ioengine=libaio --fsync=1 --iodepth=1 --direct=1 --numjobs=1 --runtime=60 --group_reporting

# QD32 4k Random Write - "multithread" IO performance/IOPS: >= 10000 IOPS
fio --name TEST --eta-newline=5s --filename=test.img --rw=randwrite --size=500m --io_size=10g --blocksize=4k --ioengine=libaio --fsync=1 --iodepth=32 --direct=1 --numjobs=1 --runtime=60 --group_reporting

# QD32 2048kb - bandwidth test/Throughput bound: > 250-300 MByte/s
fio --name TEST --eta-newline=5s --filename=test.img --rw=randwrite --size=500m --io_size=10g --blocksize=2048kb --ioengine=libaio --fsync=1 --iodepth=32 --direct=1 --numjobs=1 --runtime=60 --group_reporting

# process list for 120 (24x5) seconds
for i in `seq 1 24`; do echo $(date) >> /tmp/process.list.txt && ps auxww >> /tmp/process.list.txt && echo "=======" >> /tmp/process.list.txt && sleep 5; done

# size of table partitions
du -lah /var/lib/mysql | awk '{ print $2,"",$1 }' | grep "#" | sort

# TCP state statistics for 2 minutes
for i in `seq 1 120`; do echo $(date) | tee -a /tmp/tcp.state.txt && awk '{print $4}' /proc/net/tcp /proc/net/tcp6 | grep -v st | sort | uniq -c | tee -a /tmp/tcp.state.txt && wc -l /proc/net/tcp | tee -a /tmp/tcp.state.txt && wc -l /proc/net/tcp6 | tee -a /tmp/tcp.state.txt && echo "=======" | tee -a /tmp/tcp.state.txt && sleep 1; done

# discovere processes
watch -n1 "ps auxww | grep -Eo '[:] discoverer #.*'"

# set iperf3 on listening port
iperf3 -s -p 10050

# send data
iperf3 -c address.of.agent.server -p 10050 -t 10

# disk utilisation
iostat -x 1

# remove txt extension
for f in *.txt; do mv -- "$f" "${f%.txt}"; done

# remove leading and trailing space with sed
sed 's/^[\t ]*//g;s/[\t ]*$//g'

# snmptranslate MIB
snmptranslate -Tz -m ./MIKROTIK-MIB

# version history of proxy
find /var/log/zabbix -name 'zabbix_proxy*.gz' -exec zcat {} \; | grep Starting
find /var/log/zabbix -regex '.*zabbix_proxy.log.[0-9]+' -exec grep Starting {} \;
grep Starting /var/log/zabbix/zabbix_proxy.log

# endless loop to deliver metric
while true; do zabbix_sender -z 127.0.0.1 -s $(hostname) -k agent.ping -o 1; sleep 30; done

# ask queue
zabbix_get -s 127.0.0.1 -p 30051 -P plaintext -k '{"request":"status.get","type":"ping","sid":"TOKEN"}'

# statistics per history write cache
while true; do echo "$(date '+%Y-%m-%d %H:%M:%S') $(zabbix_server -R diaginfo=historycache | grep -A1 "Top.values" | grep "[i]temid")" >> /tmp/top.itemid.log; sleep 1; done

# test disk throughput
cd /var/lib/mysql
dd if=/dev/urandom of=512M bs=1M count=512 oflag=direct
rm 512M
dd if=/dev/urandom of=5GB bs=1M count=5120 oflag=direct
rm 5GB
dd if=/dev/urandom of=50GB bs=1M count=51200 oflag=direct
rm 50GB

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

# suggestions based on OS
cat /etc/*release* > /tmp/$(hostname).os.txt
df -m > /tmp/$(hostname).disk.txt
free -m > /tmp/$(hostname).memory.usage.txt
cat /proc/meminfo > /tmp/$(hostname).meminfo.txt
cat /proc/cpuinfo > /tmp/$(hostname).cpuinfo.txt
mysql -e "show variables" > /tmp/$(hostname).mysql.variables.txt
sysctl -a > /tmp/$(hostname).kernel.settings.txt
ps -xafuww > /tmp/$(hostname).process.list.tree.txt

# stats about MySQL data directory
du -lah /var/lib/mysql | awk '{ print $2,"",$1 }' | sort > /tmp/mysql.files.human.readable.txt
du -lab /var/lib/mysql | awk '{ print $2,"",$1 }' | sort > /tmp/mysql.files.size.in.bytes.txt
du -lab /var/lib/mysql | sort -n > /tmp/biggest.mysql.files.txt

# follow unreachable poller with 2 digits. print IP address
tail -999f /var/log/zabbix/zabbix_proxy.log | grep $(ps auxww|grep "[u]nreachable poller #99" | awk '{ print $2 }'): | grep -E "\[[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+\]"

# screenshot
google-chrome --no-sandbox --headless --print-to-pdf=/tmp/zabbix-https.pdf yourfrontendlink
chrome --no-sandbox --headless --print-to-pdf=/tmp/zabbix-https.pdf yourfrontendlink

# restore
rm /var/lib/mysql/* -rf
tar xvf /tmp/var.lib.mysql.tar.gz --directory=/var/lib/mysql

# backup /etc
tar --create --verbose --use-compress-program='gzip --best' --file=/tmp/etc.tar.gz /etc

# backup /etc with maximum compression
tar --create --verbose --use-compress-program='xz' --file=/tmp/etc.tar.xz /etc

# show printable charactars
cat file.html | tr -d '\n' | tr -cd '[:print:]'

# show printable characters on windows
cat file.html | tr -cd '[:print:]'

# "sid" in the web server log is half (the end of) of the "sessionid" in the database. Zabbix 6.0, NGINX
tail -9999f /var/log/nginx/access.log | grep -Eo "sid.*dashboardid=\S+"

# sum together 5th column
ls -lb /var/lib/mysql/zabbix | grep '#p2024_10_08' | awk '{sum += $5} END {print sum}'

# show how much data generate in a specific date
ls -lb /var/lib/mysql/zabbix | grep '#p2024_10_08' | awk '{sum += $5} END {print sum / (1024^3) " GB"}'

# backup etc to home directory in deadable format
cd /etc && mkdir -p ~/backup${PWD} && cp -a * ~/backup${PWD}

# list biggest partitions
ls --sort=size -lh | grep '#' | tac

# send all UDP 162 traffic into a human readable log
tcpdump -l -i any udp dst port 162 -x -vv 1>&2 >/tmp/udp162.log

# transport data. on destination server go to directory where files must be places. set to listen on port 1234
nc -l 1234 | tar -xvf -

# transport data. on source server. start sending. replace x.y.z.w with real IP address
tar cf - . | nc x.y.z.w 1234

# compress /var/lib/mysql by using lz4
dnf install lz4
tar --create --verbose --use-compress-program='lz4' --file=/tmp/var.lib.mysql.tar.lz4 /var/lib/mysql

# restore
rm /var/lib/mysql/* -rf
cd /
unlz4 /tmp/var.lib.mysql.tar.lz4 | tar xvf -

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

# active checks failing
grep -Eo "cannot send list of active checks.*" /var/log/zabbix/zabbix_proxy.log | sort | uniq -c

# outgoing ports, persistent connection
ss --tcp --numeric --processes | grep zabbix_server

# process list with parents
ps -xafuww > /tmp/process.list.$(hostname).txt

# top memory processes
ps -eo time,start_time,pcpu,pmem,user,args --sort pmem > /tmp/top.mem.txt

# hungry CPU processes
ps -eo time,start_time,pcpu,pmem,user,args --sort time > /tmp/top.cpu.txt

# all socket statistics
ss --all --numeric --processes > /tmp/$(hostname).socket.statistics.txt

# only listening ports and explanation
ss --tcp --numeric --listen --processes > /tmp/$(hostname).listening.ports.txt

# all installed package names
rpm -qa > /tmp/$(hostname).installed.rpms.txt

# generate random password by using bash tools
< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-20};echo;
< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-24};echo;
< /dev/urandom tr -dc A-Za-z0-9 | head -c${1:-32};echo;
< /dev/urandom tr -dc 'A-Za-z0-9~!@#$%^&*()-+<>.,/\"' | head -c${1:-20};echo;

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

# history_text discard unchanged (value_type=4)
echo "polishing history_text (value_type=4)"
PGHOST=pg16 PGPORT=7416 psql z70 --tuples-only --no-align --command="
SELECT items.itemid
FROM items, hosts
WHERE hosts.hostid=items.hostid
AND hosts.status IN (0,1)
AND items.value_type=4
AND items.flags IN (0,4)
" | \
while IFS= read -r ITEMID
do {
echo -n "$ITEMID "
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
)" | PGHOST=pg16 PGPORT=7416 psql z70
} done

# history_str discard unchanged
echo "polishing history_str (value_type=1)"
PGHOST=pg16 PGPORT=7416 psql z70 --tuples-only --no-align --command="
SELECT items.itemid
FROM items, hosts
WHERE hosts.hostid=items.hostid
AND hosts.status IN (0,1)
AND items.value_type=1
AND items.flags IN (0,4)
" | \
while IFS= read -r ITEMID
do {
echo -n "$ITEMID "
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
)" | PGHOST=pg16 PGPORT=7416 psql z70
} done

# maintain timescaledb partitions
PGHOST=pg16 PGPORT=7416 psql z70 -c "
SELECT drop_chunks(relation=>'history_log', older_than=>extract(epoch from now()::DATE - 5)::integer);
SELECT drop_chunks(relation=>'history_uint', older_than=>extract(epoch from now()::DATE - 9)::integer);
SELECT drop_chunks(relation=>'history', older_than=>extract(epoch from now()::DATE - 9)::integer);
SELECT drop_chunks(relation=>'history_bin', older_than=>extract(epoch from now()::DATE - 3)::integer);
"

