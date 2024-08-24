#!/bin/bash
DATABASE=zabbix
SLEEP=0.01
DEFAULTS_FILE=/root/.my.cnf

echo "Discard unchanged 'history_text' for all item IDs"
mysql \
--defaults-file=$DEFAULTS_FILE \
--database=$DATABASE \
--silent \
--skip-column-names \
--batch \
--execute="
SELECT items.itemid
FROM items, hosts
WHERE hosts.hostid=items.hostid
AND hosts.status IN (0,1)
AND items.value_type=4
AND items.flags IN (0,4)
ORDER BY 1
" | \
while IFS= read -r ITEMID
do {
echo $ITEMID
sleep $SLEEP
echo "
DELETE FROM history_text WHERE itemid=$ITEMID AND clock IN (
SELECT clock from (
SELECT clock, value, r, v2 FROM (
SELECT clock, value, LEAD(value,1) OVER (order by clock) AS v2,
CASE
WHEN value <> LEAD(value,1) OVER (order by clock)
THEN value
ELSE 'zero'
END AS r
FROM history_text WHERE itemid=$ITEMID
) x2
where r = 'zero'
) x3
WHERE v2 IS NOT NULL
)
" | mysql --defaults-file=$DEFAULTS_FILE --database=$DATABASE
} done

echo "Discard unchanged 'history_str' for all item IDs"
mysql \
--defaults-file=$DEFAULTS_FILE \
--database=$DATABASE \
--silent \
--skip-column-names \
--batch \
--execute="
SELECT items.itemid
FROM items, hosts
WHERE hosts.hostid=items.hostid
AND hosts.status IN (0,1)
AND items.value_type=1
AND items.flags IN (0,4)
ORDER BY 1
" | \
while IFS= read -r ITEMID
do {
echo $ITEMID
sleep $SLEEP
echo "
DELETE FROM history_str WHERE itemid=$ITEMID AND clock IN (
SELECT clock from (
SELECT clock, value, r, v2 FROM (
SELECT clock, value, LEAD(value,1) OVER (order by clock) AS v2,
CASE
WHEN value <> LEAD(value,1) OVER (order by clock)
THEN value
ELSE 'zero'
END AS r
FROM history_str WHERE itemid=$ITEMID
) x2
where r = 'zero'
) x3
WHERE v2 IS NOT NULL
)
" | mysql --defaults-file=$DEFAULTS_FILE --database=$DATABASE
} done
