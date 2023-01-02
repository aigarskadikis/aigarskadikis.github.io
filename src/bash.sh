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

