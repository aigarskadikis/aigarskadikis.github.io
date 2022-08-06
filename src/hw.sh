# disk long term throughput, how fast we can create 64GB file
time dd if=/dev/urandom of=/var/lib/mysql/64GB.file bs=1M count=65536 oflag=direct

# activity for each block device, pretty-print  device  names, report task creation and system switching activity.
sar -d -p -w 1

