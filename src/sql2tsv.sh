# MySQL
echo "SELECT alias,
attempt_failed,
attempt_ip,
FROM_UNIXTIME(attempt_clock)
FROM users" | mysql \
--host='127.0.0.1' \
--user='zbx_web' \
--password='zabbix' \
--database='zabbix' \
--silent \
--skip-column-names \
--batch > /tmp/queue.tsv

