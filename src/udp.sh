# print all UPD traffic for eth0
tcpdump -i eth0 -nn udp

# print all UDP traffic. second column is EngineID
tshark -i any -Y '(udp.srcport == 161)' -T fields -e ip.src -e snmp.msgAuthoritativeEngineID -e snmp.msgAuthoritativeEngineTime -e snmp.msgAuthoritativeEngineBoots -e frame.time

# query one particular engineID
tshark -i any -Y '(udp.srcport == 161) && (snmp.msgAuthoritativeEngineID == 80:00:3a:8c:04)' -T fields -e ip.src -e snmp.msgAuthoritativeEngineID -e snmp.msgAuthoritativeEngineTime -e snmp.msgAuthoritativeEngineBoots -e frame.time

