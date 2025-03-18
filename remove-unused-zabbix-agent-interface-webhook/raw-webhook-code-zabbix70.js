// load all variables into memory
var params = JSON.parse(value);

var request = new HttpRequest();
request.addHeader('Content-Type: application/json');
request.addHeader('Authorization: Bearer ' + params.token);

// pick up hostid
var hostid = JSON.parse(request.post(params.url,
    '{"jsonrpc":"2.0","method":"host.get","params":{"output":["hostid"],"filter":{"host":["' + params.host + '"]}},"id":1}'
)).result[0].hostid;

// extract all passive zabbix agent interfaces
var all_zbx_interfaces = JSON.parse(request.post(params.url,
    '{"jsonrpc":"2.0","method":"hostinterface.get","params":{"output":["interfaceid","main"],"filter":{"type":"1"},"hostids":"' + hostid + '"},"id":1}'
)).result;

// if any ZBX interface was found then proceed fetching all items because need to find out if any items use an interface
if (all_zbx_interfaces.length > 0) {
    // fetch all items which are defined at host level and ask which item use passive ZBX agent interface
    // simple check items (like icmpping) also can use zabbix agent interface
    var items_with_int = JSON.parse(request.post(params.url,
        '{"jsonrpc":"2.0","method":"item.get","params":{"output":["type","interfaces"],"hostids":"' + hostid + '","selectInterfaces":"query"},"id":1}'
    )).result;
}

// define an interface array. this is required if more than one ZBX interface exists on host level
var interfacesInUse = [];

// iterate through all ZBX interfaces
for (var zbx = 0; zbx < all_zbx_interfaces.length; zbx++) {

    // go through all items which is defined at host level
    for (var int = 0; int < items_with_int.length; int++) {

        // there are many items which does not need interface. specifically analyze the ones which has an interface defined
        if (items_with_int[int].interfaces.length > 0) {

            // there is an interface found for the item
            if (items_with_int[int].interfaces[0].interfaceid == all_zbx_interfaces[zbx].interfaceid) {
                // put this item in list which use an interface
                var row = {};
                row["itemid"] = items_with_int[int].itemid;
                row["interfaceid"] = all_zbx_interfaces[zbx].interfaceid;
                row["main"] = all_zbx_interfaces[zbx].main;
                interfacesInUse.push(row);
            }
        }
    }
}

// final scan to identify if any interface is wasted
var needToDelete = 1;
var deleteEvidence = [];
var mainNotUsed = 0;
for (var defined = 0; defined < all_zbx_interfaces.length; defined++) {
    // scan all items

    needToDelete = 1;
    for (var used = 0; used < interfacesInUse.length; used++) {
        if (all_zbx_interfaces[defined].interfaceid == interfacesInUse[used].interfaceid) {
            needToDelete = 0;
        }
    }

    // if flag was not turned off, then no items with this interface were found. no items are using this interface. safe to delete
    // delete all slaves first
    if (needToDelete == 1 && all_zbx_interfaces[defined].main == 0) {
        var deleteInt = JSON.parse(request.post(params.url,
            '{"jsonrpc":"2.0","method":"hostinterface.delete","params":["' + all_zbx_interfaces[defined].interfaceid + '"],"id":1}'
        ));
        var row = {};
        row["deleted"] = deleteInt;
        deleteEvidence.push(row);
    }

    if (needToDelete == 1 && all_zbx_interfaces[defined].main == 1) {
        var mainNotUsed = all_zbx_interfaces[defined].interfaceid;
    }

}

// delete main interface at the end
if (mainNotUsed > 0) {
    var deleteInt = JSON.parse(request.post(params.url,
        '{"jsonrpc":"2.0","method":"hostinterface.delete","params":["' + mainNotUsed + '"],"id":1}'
    ));
    var row = {};
    row["deleted"] = deleteInt;
    deleteEvidence.push(row);
}

var output = JSON.stringify({
    "all_zbx_interfaces": all_zbx_interfaces,
    "interfacesInUse": interfacesInUse,
    "deleteEvidence": deleteEvidence
});

Zabbix.Log(4, 'Auto remove unsused ZBX agent passive interfaces: ' + output)

return 0;