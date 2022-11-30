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
