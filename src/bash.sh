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
while true; do zabbix_sender  -z 127.0.0.1 -s $(hostname) -k agent.ping -o 1; sleep 30; done

# test disk throughput
dd if=/dev/urandom of=/db/mount/point/512M bs=1M count=512 oflag=direct
dd if=/dev/urandom of=/db/mount/point/5GB bs=1M count=5120 oflag=direct
dd if=/dev/urandom of=/db/mount/point/50GB bs=1M count=51200 oflag=direct
dd if=/dev/urandom of=/db/mount/point/65GB bs=1M count=65536 oflag=direct

# erase dublicate data in table history_text
mysql --database='zabbix' --silent --skip-column-names --batch --execute="SELECT itemid FROM items WHERE value_type=4 AND templateid" | \
while IFS= read -r ITEMID
do {
echo $ITEMID
sleep 0.01
echo "
DELETE t1 FROM history_text t1
INNER JOIN history_text t2
WHERE
t1.clock < t2.clock AND
t1.value = t2.value AND
t1.itemid = t2.itemid AND
t1.itemid=$ITEMID;
" | mysql zabbix
} done

# erase dublicate data in table history_str
mysql --database='zabbix' --silent --skip-column-names --batch --execute="SELECT itemid FROM items WHERE value_type=1 AND templateid" | \
while IFS= read -r ITEMID
do {
echo $ITEMID
sleep 0.01
echo "
DELETE t1 FROM history_str t1
INNER JOIN history_str t2
WHERE
t1.clock < t2.clock AND
t1.value = t2.value AND
t1.itemid = t2.itemid AND
t1.itemid=$ITEMID;
" | mysql zabbix
} done

