#!/bin/bash

AUTH=$(cat ~/z64.api)
URL=$(cat ~/z64.url)

TRIGGERIDS_TO_DISABLE=$(
sed 's|"0"|"1"|g' "/tmp/all.active.triggers.$(date '+%Y.%m.%d').json"
)

JSON_INPUT='
{
    "jsonrpc": "2.0",
    "method": "trigger.update",
    "params": '$TRIGGERIDS_TO_DISABLE'
    ,
    "id": 1,
    "auth":"'$AUTH'"
}
'

echo "$JSON_INPUT" |\
curl -s -k -X POST -H 'Content-Type: application/json-rpc' -d @- "$URL" | jq .

