# listening TCP ports
ss --tcp --listen --numeric

# trouble simple
tail -1000000 /var/log/messages > /tmp/messages.txt
free -h > /tmp/memory.txt
df -h > /tmp/disk.txt
dmesg > /tmp/dmesg.txt
ps -xafuww > /tmp/process.list.tree.txt

# process saturation and diag info
while true; do  echo $(date) >> /tmp/process.list.txt && ps -xafuww >> /tmp/process.list.txt && zabbix_server -R diaginfo >> /tmp/process.list.txt && echo "=======" >> /tmp/process.list.txt ; sleep 60; done

# listening TCP ports with process identification
ss --tcp --listen --numeric --process

# ensure service is listening on UDP 162
ss --udp --listen --numeric --process | grep 162

# check if tcp port listens. make sure it really listens on destination server before checking
nc -v servername 3306

# check if port is open without external tools. if it reports 0, the port is reachable and in the listening state
{ echo >/dev/tcp/127.0.0.1/3306 ; } 2>/dev/null; echo $?

# capture all SNMP traps traffic
tcpdump -i any udp dst port 162 >> /var/log/zabbix/zabbix_traps.tcpdump

# SNMP traffic and ICMP ping probles
tcpdump -i any 'port 161 or icmp' -w /tmp/out.pcap

# replace 127.0.0.1 with real IP
tcpdump -i any 'port 10051 and (dst 127.0.0.1 and src 127.0.0.1)' -w /tmp/out.pcap

# UDP traffic
tcpdump -i any port 161 -w /tmp/out.pcap

# activity for each block device, pretty-print  device  names, report task creation and system switching activity.
sar -d -p -w 1

# 10 seconds of disk usage
sar -d -wp 1 10 >> /tmp/disk.activity.txt

# installed packages on EL7 or EL8 system
rpm -qa > /tmp/installed.packages.txt

# installed packages on Ubuntu/Debian
apt list --installed > /tmp/apt.installed.txt

# OS information
cat /etc/*release* > /tmp/os.info.txt

# disk space
df -h > /tmp/disk.space.txt

# OS, Memory, CPU, Disk characteristics
cat /etc/*release* > /tmp/$(hostname).characteristics.txt
cat /proc/meminfo >> /tmp/$(hostname).characteristics.txt
free -h >> /tmp/$(hostname).characteristics.txt
cat /proc/cpuinfo >> /tmp/$(hostname).characteristics.txt
df -h >> /tmp/$(hostname).characteristics.txt

# Usage of swap:
for file in /proc/*/status ; do awk '/VmSwap|Name/{printf $2 " " $3}END{ print ""}' $file; done >> /tmp/$(hostname).swap.usage.txt

# process list. top memory. top CPU
ps auxww > /tmp/process.list.txt
ps auxww --sort -%mem > /tmp/top.mem.processes.txt
ps auxww --sort -%cpu > /tmp/top.cpu.processes.txt

# shared memory segments and semaphore arrays
ipcs -a > /tmp/shared.memory.segments.and.semaphore.arrays.txt

# last 1 million lines from messages
tail -1000000 /var/log/messages > /tmp/messages.txt

# display all messages from the kernel ring buffer
dmesg > /tmp/dmesg.txt

# live kernel settings
sysctl -a > /tmp/.live.kernel.settings.txt

# last 1 million lines from /var/log/zabbix/zabbix_proxy.log
tail -1000000 /var/log/zabbix/zabbix_proxy.log | gzip --best > /tmp/zabbix_proxy.$(date +%Y%m%d.%H%M).log.gz

# last 1 million lines from /var/log/zabbix/zabbix_server.log
tail -1000000 /var/log/zabbix/zabbix_server.log | gzip --best > /tmp/zabbix_server.$(date +%Y%m%d.%H%M).log.gz

# all trapper processes
watch -n1 'ps auxww | grep -Eo "[:] trapper #.*"'

# free trapper processes
watch -n1 'ps auxww | grep -Eo "[:] trapper #.*waiting for connection"'

# service not booting up
journalctl -u sshd | tail -100 > /tmp/sshd.txt

# list of open files:
lsof > /tmp/list.open.files.txt

# disk long term throughput, how fast we can create 64GB file
time dd if=/dev/urandom of=/var/lib/mysql/64GB.file bs=1M count=65536 oflag=direct

