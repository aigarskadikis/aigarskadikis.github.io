// where Zabbix API endpoint is located
var json_rpc = 'http://127.0.0.1/api_jsonrpc.php';

// static token
var token = 'tokenHere';

// everything needed for "curl"
var req = new HttpRequest();
req.addHeader('Content-Type: application/json');

// objectID
var objectID = JSON.parse(req.post(json_rpc,
    '{"jsonrpc":"2.0","method":"item.get","params":{"output":["hostid","itemid"],"search":{"key_":"system.objectid[sysObjectID.0]"}},"auth":"' + token + '","id":1}'
)).result;

// run API method
var existingHostList = JSON.parse(req.post(json_rpc,
    '{"jsonrpc":"2.0","method":"host.get","params":{"output":["host","hostid","status"],"selectParentTemplates":["templateid"]},"auth":"' + token + '","id": 1}'
)).result;

var allTogether = [];
for (o in objectID) {

    var row = {};
    row = objectID[o];

    // iterate through host array to find the matching host title
    for (h in existingHostList) {

        // check if there is a match between the hostid which belongs at item level and the host array
        if (objectID[o].hostid === existingHostList[h].hostid) {

            row["hostStatus"] = existingHostList[h].status;
            row["host"] = existingHostList[h].host;

                if (existingHostList[h].parentTemplates) {
                        if (existingHostList[h].parentTemplates.length > 0) {
            row["firstTemplate"] = existingHostList[h].parentTemplates[0].templateid;
                } else {
                        row["firstTemplate"] = "";

                }
                }

            break;
        }

    }
    allTogether.push(row);
}

// extract all real itemIDs which belong to host items not template
var itemIDsWithObject = [];
for (d in allTogether) {

if (allTogether[d].hostStatus === '0') {
itemIDsWithObject.push(allTogether[d].itemid);
}

}


// get latest history
var latestHistory = JSON.parse(req.post(json_rpc,
            '{"jsonrpc":"2.0","method":"history.get","params":{"output":["value","itemid"],"history":1,"itemids":' + JSON.stringify(itemIDsWithObject) + ',"limit":100000},"auth":"' + token + '","id":1}'
        )).result;

//return JSON.stringify(latestHistory);

var old = allTogether;
var allTogether = [];


for (o in old) {

    var row = {};
    row = old[o];

    for (h in latestHistory) {

        if (old[o].itemid === latestHistory[h].itemid) {

            row["objectid"] = latestHistory[h].value;

            break;
        }

    }
    allTogether.push(row);
}


//return JSON.stringify(allTogether);

//var addTemplate = 10395;

// go through latest data page
for (m in allTogether) {

    if (allTogether[m].hostStatus === '0') {

        if (allTogether[m].objectid === 'iso.3.6.1.4.1.9.1.2137' && allTogether[m].firstTemplate !== '10218') {

            // set ObjectID in variable
            var individual = allTogether[m].objectid;

                Zabbix.Log(3, 'found ' + individual + ' at ' + allTogether[m].host+': '+
                        JSON.stringify(
                    JSON.parse(req.post(json_rpc,
                        '{"jsonrpc":"2.0","method":"host.update","params":{"hostid":"' + allTogether[m].hostid + '","templates":[{"templateid":"10218"}]},"auth":"' + token + '","id":1}'
                    )).result

                )
                );

        }

    }


}


return allTogether.length;
