SELECT COUNT(*),clock FROM history_uint WHERE clock > (SELECT MAX(lastaccess)-600 FROM sessions) GROUP BY 2 ORDER BY 1 DESC LIMIT 10;
SELECT COUNT(*),clock FROM history_log WHERE clock > (SELECT MAX(lastaccess)-600 FROM sessions) GROUP BY 2 ORDER BY 1 DESC LIMIT 10;
SELECT COUNT(*),clock FROM history_str WHERE clock > (SELECT MAX(lastaccess)-600 FROM sessions) GROUP BY 2 ORDER BY 1 DESC LIMIT 10;
SELECT COUNT(*),clock FROM history_text WHERE clock > (SELECT MAX(lastaccess)-600 FROM sessions) GROUP BY 2 ORDER BY 1 DESC LIMIT 10;
SELECT COUNT(*),clock FROM history WHERE clock > (SELECT MAX(lastaccess)-600 FROM sessions) GROUP BY 2 ORDER BY 1 DESC LIMIT 10;

SELECT hosts.host, items.key_ FROM history_uint,items,hosts
WHERE hosts.hostid=items.hostid
AND items.itemid=history_uint.itemid
AND clock=1756405202;
