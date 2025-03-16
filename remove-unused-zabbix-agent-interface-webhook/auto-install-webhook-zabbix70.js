// load all variables into memory
var params = JSON.parse(value);

var request = new HttpRequest();
request.addHeader('Content-Type: application/json');
request.addHeader('Authorization: Bearer ' + params.token);

// script names
var scriptNames = JSON.parse(request.post(params.url,
    '{"jsonrpc":"2.0","method":"script.get","params":{"output":["name"]},"id":1}'
)).result;

// return JSON.stringify(scriptNames);

// lets assume by default script must be installed
var needToInstall = 1;

// iterate through all scripts
for (var script = 0; script < scriptNames.length; script++) {

    // check if one of script names match the one which is about to be installed
    if (scriptNames[script].name == params.name) {
        needToInstall = 0;
    }
}

// if need to install
if (needToInstall > 0) {

    var host_value = "{HOST.HOST"+"}";
    var url_value = "{$ZABBIX.URL"+"}/api_jsonrpc.php";
    var token_value = "{$Z_API_SESSIONID"+"}";

    var raw = JSON.stringify({
        "jsonrpc": "2.0",
        "method": "script.create",
        "params": {
            "name": params.name,
            "command": "// load all variables into memory\r\nvar params = JSON.parse(value);\r\n\r\nvar request = new HttpRequest();\r\nrequest.addHeader('Content-Type: application/json');\r\nrequest.addHeader('Authorization: Bearer ' + params.token);\r\n\r\n// pick up hostid\r\nvar hostid = JSON.parse(request.post(params.url,\r\n    '{\"jsonrpc\":\"2.0\",\"method\":\"host.get\",\"params\":{\"output\":[\"hostid\"],\"filter\":{\"host\":[\"' + params.host + '\"]}},\"id\":1}'\r\n)).result[0].hostid;\r\n\r\n// extract all passive zabbix agent interfaces\r\nvar all_zbx_interfaces = JSON.parse(request.post(params.url,\r\n    '{\"jsonrpc\":\"2.0\",\"method\":\"hostinterface.get\",\"params\":{\"output\":[\"interfaceid\",\"main\"],\"filter\":{\"type\":\"1\"},\"hostids\":\"' + hostid + '\"},\"id\":1}'\r\n)).result;\r\n\r\n// if any ZBX interface was found then proceed fetching all items because need to find out if any items use an interface\r\nif (all_zbx_interfaces.length > 0) {\r\n    // fetch all items which are defined at host level and ask which item use passive ZBX agent interface\r\n    // simple check items (like icmpping) also can use zabbix agent interface\r\n    var items_with_int = JSON.parse(request.post(params.url,\r\n        '{\"jsonrpc\":\"2.0\",\"method\":\"item.get\",\"params\":{\"output\":[\"type\",\"interfaces\"],\"hostids\":\"' + hostid + '\",\"selectInterfaces\":\"query\"},\"id\":1}'\r\n    )).result;\r\n}\r\n\r\n// define an interface array. this is required if more than one ZBX interface exists on host level\r\nvar interfacesInUse = [];\r\n\r\n// iterate through all ZBX interfaces\r\nfor (var zbx = 0; zbx < all_zbx_interfaces.length; zbx++) {\r\n\r\n    // go through all items which is defined at host level\r\n    for (var int = 0; int < items_with_int.length; int++) {\r\n\r\n        // there are many items which does not need interface. specifically analyze the ones which has an interface defined\r\n        if (items_with_int[int].interfaces.length > 0) {\r\n\r\n            // there is an interface found for the item\r\n            if (items_with_int[int].interfaces[0].interfaceid == all_zbx_interfaces[zbx].interfaceid) {\r\n                // put this item in list which use an interface\r\n                var row = {};\r\n                row[\"itemid\"] = items_with_int[int].itemid;\r\n                row[\"interfaceid\"] = all_zbx_interfaces[zbx].interfaceid;\r\n                row[\"main\"] = all_zbx_interfaces[zbx].main;\r\n                interfacesInUse.push(row);\r\n            }\r\n        }\r\n    }\r\n}\r\n\r\n// final scan to identify if any interface is wasted\r\nvar needToDelete = 1;\r\nvar deleteEvidence = [];\r\nvar mainNotUsed = 0;\r\nfor (var defined = 0; defined < all_zbx_interfaces.length; defined++) {\r\n    // scan all items\r\n\r\n    needToDelete = 1;\r\n    for (var used = 0; used < interfacesInUse.length; used++) {\r\n        if (all_zbx_interfaces[defined].interfaceid == interfacesInUse[used].interfaceid) {\r\n            needToDelete = 0;\r\n        }\r\n    }\r\n\r\n    // if flag was not turned off, then no items with this interface were found. no items are using this interface. safe to delete\r\n    // delete all slaves first\r\n    if (needToDelete == 1 && all_zbx_interfaces[defined].main == 0) {\r\n        var deleteInt = JSON.parse(request.post(params.url,\r\n            '{\"jsonrpc\":\"2.0\",\"method\":\"hostinterface.delete\",\"params\":[\"' + all_zbx_interfaces[defined].interfaceid + '\"],\"id\":1}'\r\n        ));\r\n        var row = {};\r\n        row[\"deleted\"] = deleteInt;\r\n        deleteEvidence.push(row);\r\n    }\r\n\r\n    if (needToDelete == 1 && all_zbx_interfaces[defined].main == 1) {\r\n        var mainNotUsed = all_zbx_interfaces[defined].interfaceid;\r\n    }\r\n\r\n}\r\n\r\n// delete main interface at the end\r\nif (mainNotUsed > 0) {\r\n    var deleteInt = JSON.parse(request.post(params.url,\r\n        '{\"jsonrpc\":\"2.0\",\"method\":\"hostinterface.delete\",\"params\":[\"' + mainNotUsed + '\"],\"id\":1}'\r\n    ));\r\n    var row = {};\r\n    row[\"deleted\"] = deleteInt;\r\n    deleteEvidence.push(row);\r\n}\r\n\r\nvar output = JSON.stringify({\r\n    \"all_zbx_interfaces\": all_zbx_interfaces,\r\n    \"interfacesInUse\": interfacesInUse,\r\n    \"deleteEvidence\": deleteEvidence\r\n});\r\n\r\nZabbix.Log(4, 'Auto remove unsused ZBX agent passive interfaces: ' + output)\r\n\r\nreturn 0;",
            "host_access": "2",
            "usrgrpid": "0",
            "groupid": "0",
            "description": "",
            "confirmation": "",
            "type": "5",
            "execute_on": "2",
            "timeout": "30s",
            "scope": "1",
            "port": "",
            "authtype": "0",
            "username": "",
            "password": "",
            "publickey": "",
            "privatekey": "",
            "menu_path": "",
            "url": "",
            "new_window": "1",
            "manualinput": "0",
            "manualinput_prompt": "",
            "manualinput_validator": "",
            "manualinput_validator_type": "0",
            "manualinput_default_value": "",
            "parameters": [
                {
                    "name": "host",
                    "value": host_value
                },
                {
                    "name": "url",
                    "value": url_value
                },
                {
                    "name": "token",
                    "value": token_value
                }
            ]
        },
        "id": 1
    });

    var installNew = JSON.parse(request.post(params.url, raw)).result;
    return JSON.stringify(installNew);
}

return 0;