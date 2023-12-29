// usage
// zabbix_js -s z60-delete-host.js -p '{"url":"https://contoso.zabbix.com:44360/","auth":"a48d0091248d9ea1f6e7699e4f244757","host":"samba.gnt1.dietpi.x86_64.riga"}'

var params = JSON.parse(value),
    req = new CurlHttpRequest(),
    json_rpc=params.url+'/api_jsonrpc.php';

req.AddHeader('Content-Type: application/json');
var selectItems = JSON.parse(req.Post(json_rpc,
'{"jsonrpc":"2.0","method":"host.get","params":{"filter":{"host":"'+params.host+'"},"selectItems":["flags","master_itemid","itemid"]},"auth":"'+params.auth+'","id":1}'
)).result[0].items;

var flag4 = [];

var lines = selectItems;
var lines_num = lines.length;
for (i = 0; i < lines_num; i++) {
if (lines[i].flags == 4 ) {
  var row = {};
  row["itemid"] = lines[i].itemid;
  flag4.push(row);
}
}

return JSON.stringify({
    'selectItems': selectItems,
    'flag4': flag4
});


