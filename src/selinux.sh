# list existing context
ls -lZ /etc/zabbix

# install context
sudo chcon system_u:object_r:etc_t:s0 /etc/zabbix/another.conf

# make it persistent across relabels (like restorecon or policy reloads):
sudo semanage fcontext -a -t etc_t "/etc/zabbix/another.conf"
sudo restorecon -v /etc/zabbix/another.conf

# replicate context from another file
sudo chcon --reference=/etc/zabbix/zabbix_java_gateway.conf /etc/zabbix/another.conf

