// pick up Zabbix API session token

params = JSON.parse(value);

var auth = params.auth;
var json_rpc = params.json_rpc;

Zabbix.Log(4, 'auth=',auth);
Zabbix.Log(4, 'json_rpc=',json_rpc);

// new http request
var req = new CurlHttpRequest();
req.AddHeader('Content-Type: application/json');


var output = JSON.parse(req.Post(json_rpc,
    '{"jsonrpc":"2.0","method":"hostgroup.get","params":{"output":"extend"},"auth":"' + auth + '","id":1}'
)).result;


var listOfHostGroups = [];
var lines_num = output.length;
for (i = 0; i < lines_num; i++)
{
  
if (output[i].name.match(/zs/)) {
listOfHostGroups.push(output[i].name);
}

}



//return JSON.stringify(output);
return listOfHostGroups
