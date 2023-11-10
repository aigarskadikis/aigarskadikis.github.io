#!/bin/bash

AUTH=$(cat ~/z64.api)
URL=$(cat ~/z64.url)

curl -s -k -X POST -H 'Content-Type: application/json-rpc' -d '
{
    "jsonrpc": "2.0",
    "method": "trigger.get",
    "params": {
        "output": ["triggerid","status"],
        "filter":{
        "status":0
        }
    },
    "id": 1,
    "auth":"'$AUTH'"
}
' "$URL" | jq -r .result > /tmp/all.active.triggers.$(date '+%Y.%m.%d').json

