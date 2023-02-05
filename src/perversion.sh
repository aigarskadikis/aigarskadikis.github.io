#!/bin/bash

echo "
3.0
3.2
3.4
4.0
4.2
4.4
5.0
5.2
5.4
6.0
6.2
" | grep -v "^$" | while IFS= read -r VER
do {
VERINT=$(echo $VER | sed 's|\.||')
echo $VERINT
touch "$VERINT.sql"
> "$VERINT.sql"
cat server.sql proxy.sql delete.sql | while IFS= read -r LINE
do {

# check empty line
echo "$LINE" | grep "^$" > /dev/null

if [ $? -eq 0 ]; then

# this is start of new/next block
# need to empty variable
echo "$BLOCK" | grep "Zabbix.* $VER" > /dev/null && echo "$BLOCK" | sed 's|\. Zabbix .*$||' >> $VERINT.sql


BLOCK=""

else

# the block is in progress
BLOCK+="$LINE"$'\n'

fi


} done

} done
