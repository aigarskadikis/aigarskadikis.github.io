# install dependencies on ubuntu 22
apt install snmp snmptrapd libsnmp-perl snmptt snmp-mibs-downloader -y

# mimic SNMP traps
echo "$(date +%Y%m%d.%H%M%S) ZBXTRAP 10.10.10.10
2nd line
3rd line
4rt line" | tee --append /tmp/zabbix_traps.tmp

# snmptrapd in foreground
strace -s 1024 -o /tmp/snmptrapd.strace.log snmptrapd -f -C -Le -Dusm -c /etc/snmp/snmptrapd.conf

# capture traps traffic
tcpdump -npi any -s 0 -w /tmp/udp162.pcap udp and host 10.133.112.87

# send test trap SNMPv3
snmptrap -v 3 -n "" -a SHA -A testtest -x AES -X testtest -l authPriv -u SNMPv3username -e 0x80000634b210008894719abe08 10.133.80.228 0 1.2.3

# turn down 'snmpd'. this was installed to solve dependencies
systemctl stop snmpd && systemctl disable snmpd

# turn down 'snmptrapd' to reconfigure service
systemctl stop snmptrapd

# make a backup of old config, install new
mv /etc/snmp/snmptrapd.conf /etc/snmp/original.snmptrapd.conf

# install example config to catpur SNMPv2 traps and SNMPv3 traps
cd / && echo "/Td6WFoAAATm1rRGAgAhARwAAAAQz1jM4Cf/AhVdADKdCIYUyy9sMvNjsbbzalh2a+CieFE1VBk12M+iJ9k2na4QOO9Ofnui3QKfd3E/1VgKRwkM3Epl5SMnZfJ+Cco4JO/AyUapb6yMjEt3XsUk7BjRRaUGM0uAlufs91DZkXRkomCIZcsUZrGk8QVyxc1g+OrLpcr1Gg25NNexih87iDdzxxXIVJgzVqeurca2iV8PwHaIeBXGVdbKgnDrACTAfUmxOg07Y1YRNqNGilYXa4zP6mlr2G8L/KlkUmJf6ubOEorh1eMX1zWVeyRK1XBCx+6WKTsxTijP20A7rttOg7s/+Z7PVXRdghD91fIRWVby9K35SKcjkn1B7BUNwC4X586M6S04Pqgb+PamryiP9Ct2w7IgMiIUcCrzC4LZuRRpzbOKzLL5NbYeeM5QOxK6/PvsM1MlZwNf+5F3ubEr4eObU517xhW+bSvntYwetQTJm+5bcOTnu+HkJaVinw58QEIsCjOOtAJmqcKkrlvo2nYuobkRW64ME3nA2TdcqJ2BZQ2o5/rKwn7ZKmCKNgxffdMELcji4pRjALX1lC8g/hyEi+ysu34iA/ciq1HJVEO9ulGVAmrr9OdmqbZXWiPs7pg7Epcjr9CKQjsORS3R/3Gsf7umyWtWnCKpex48gClLRQPv2bI2WtGG6V6uXyPyBLUPiHKj6u74SAQJ/235xmovoLNuGl5bQ9DSrp0bzRi7qhc+AAAAALkbuP45VSNNAAGxBIBQAABGKqZmscRn+wIAAAAABFla" | base64 --decode | unxz | tar -xv

# install example config to catpur SNMPv2 traps and SNMPv3 traps fro Ubuntu 22
cd / && echo "/Td6WFoAAATm1rRGAgAhARwAAAAQz1jM4Cf/AYNdADKdCIYUyy9sMvNjsbbzalh2a+CieFE1VBk116qSpEChzLfeNm/VMSFs0glXd1kGmtWdaahiXsCj/lmFbJdNPBKh2MwwBi9c7ONuSaWL+cEZOEGH3966HOgmoL6XtkTd0ilQ4in/LDfhRuwL4659LqCUDqASYem/P0OmvYVnLyAIIrIgRl+QwqRYQyGtU8YrjfRJMuGU4djjwWSC2Elx8WEIr1Q12VTLcNoeXeMkOaonxhmtWgZ5mzTedKf+Bydc+lnUQjCe/aDIw2CL3Z89BKaYLh7LlqqdQEEZhzQQhLkfZBx/zsjiZ4hGZFqG+/HOuJ0uKiCSeySmAoTZT/ASHBpWW391kPZsefEjx3ScD6qwVoO7aDC+1i9FnuBNeD/EvLMYhYHlBP2nn4QNd/4RiYE2CYohgf3wATTuzMkQC0PeHq5rojWkOQam7pZIPy395Rahm0fhoyrTGasibCWPNIT0MyBPE9pFOXraL1F9PYoSM+T2a/ZEb0k74EjQwEHZKlYNQAAAtCgAjNz6fkQAAZ8DgFAAABCSIOmxxGf7AgAAAAAEWVo=" | base64 --decode | unxz | tar -xv

# backup /etc/snmp/snmptrpad.conf
tar --create --verbose --use-compress-program='xz -9' /etc/snmp/snmptrapd.conf | base64 -w0 | sed 's|^|cd / \&\& echo "|' | sed 's%$%" | base64 --decode | unxz | tar -xv%' && echo

# start SNMP trap listening service and enable at startup
systemctl start snmptrapd && systemctl enable snmptrapd

# check if it listens on UDP 162
ss --udp --listen --numeric --process | grep 162

# install official parser from git.zabbix.com
curl https://git.zabbix.com/projects/ZBX/repos/zabbix/raw/misc/snmptrap/zabbix_trap_receiver.pl?at=refs%2Fheads%2Fmaster -o /usr/local/bin/zabbix_trap_receiver.pl

# install official parser from gitgub.com
curl https://raw.githubusercontent.com/zabbix/zabbix/master/misc/snmptrap/zabbix_trap_receiver.pl -o /usr/local/bin/zabbix_trap_receiver.pl

# install without internet access
cd / && echo "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" | base64 --decode | unxz | tar -xv

# non-official with variable binding
cd / && echo "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" | base64 --decode | unxz | tar -xv

# bash parser
cd / && echo "/Td6WFoAAATm1rRGAgAhARwAAAAQz1jM4Cf/AiddADqcyosJgONiHFxK21FYsOmcVPjGP4X64Cl0bFy0Sxh6dQDRjk6f8dQ1bOCTQt37h4nPN7dqU5XiljBY1ISkB57iky9OaCllx2Pvw7ADF5H5hz2M/woIhS5kB6SZzGLqiZ/L4ObszSmHD/zqU/EptJXvrKiRxNPL3vREPA/bxK/iefk//ici0J76T5Pgu6B5JySWc9UrDRuOwLJH8gF+ac4z1dKxDWCbIjxuS28RZQlunU1OAlIr/CyCfBfC1Pp5b+H1lMr4yeBne7oOVqx5ytStJs+J/X+S3ck3O115oqn6NvsvaamKz6hnaSG91RKb+A8fUXoXwpXvTI8fmeOCsi9v9d1XDStnvix0EOqLqRFE9JrRiuKUHlSfkrtd1YAjr+Ab8+SpyXoxkYvt5qIsdJkT7uLhAiEcxHr2xtaZrVus3qsvA9pQ+uMtk9YIIG8auFD6ImlPI/52vUID9uBDVIv5x/1D5fhmBPRE8c9holuN9pWksYmlqewZ2deiPvfKNxpJNGp7ReBDjSh9/koaB8TWMcOKdARr52F498EGjzMeB6P7XNtUoi/gmHjgjpxDLLApKtZyENPXehKqMCUlTCKH03YuyiCezmurGbkkFAPQHKfDKSFJuahsOR/qAHOO7UwvzMluzaQFlIzUq9xpCvZjTLwpfpUnhIVxgY/GZw+9c6gweJWVUnfehDrKGqhvXFmAyjHtgTzjlpry2jgLBP72Dgt3PRLCAACEWwpFaPLuqgABwwSAUAAAjIZMILHEZ/sCAAAAAARZWg==" | base64 --decode | unxz | tar -xv

# send incorrect SNMPv3 engineID
snmptrap -v 3 -n "" -a SHA -A testtest -x AES -X testtest -l authPriv -u SNMPv3username -e 0x80000634b210008894719abe07 127.0.0.1 0 1.2.3
ls /tmp

# send incorrect SNMPv2 community
snmptrap -v 1 -c moon 127.0.0.1 '.1.3.6.1.6.3.1.1.5.3' '0.0.0.0' 6 33 '55' .1.3.6.1.6.3.1.1.5.3 s "eth0"
ls /tmp

# correct SNMPv3 engineID
snmptrap -v 3 -n "" -a SHA -A testtest -x AES -X testtest -l authPriv -u SNMPv3username -e 0x80000634b210008894719abe08 127.0.0.1 0 1.2.3
ls /tmp
cat /tmp/zabbix_traps.tmp
rm -rf /tmp/zabbix_traps.tmp

# correct SNMPv2 community
snmptrap -v 1 -c earth 127.0.0.1 '.1.3.6.1.6.3.1.1.5.3' '0.0.0.0' 6 33 '55' .1.3.6.1.6.3.1.1.5.3 s "eth0"
ls /tmp
cat /tmp/zabbix_traps.tmp
rm -rf /tmp/zabbix_traps.tmp

