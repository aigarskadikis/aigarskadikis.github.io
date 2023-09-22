#!/bin/bash

# variables
SERVER=165.232.80.109
PORT=16051
HOSTNAME=hostName
ITEMKEY=itemKey
INPUT=$1
WORKDIR=/tmp
TMPFILE=csv.input.base64.zabbix_sender

# create an empty file. overwrite content from previous session
# there is an intention space after $ITEMKEY
echo -n "$HOSTNAME $ITEMKEY " > "$WORKDIR/$TMPFILE"

# encode data in base64. to have data in one line
base64 -w0 "$INPUT" >> "$WORKDIR/$TMPFILE"

# deliver data
zabbix_sender \
	--zabbix-server="$SERVER" \
	--port="$PORT" \
	--input-file="$WORKDIR/$TMPFILE"

# remove the data inside for security concerns
truncate --size=0 "$WORKDIR/$TMPFILE"

