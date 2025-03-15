// load all variables into memory
var params = JSON.parse(value);

var request = new HttpRequest();
request.addHeader('Content-Type: application/json');
request.addHeader('Authorization: Bearer ' + params.token);

// pick up hostid
var hostid = JSON.parse(request.post(params.url,
    '{"jsonrpc":"2.0","method":"host.get","params":{"output":["hostid"],"filter":{"host":["' + params.host + '"]}},"id":1}'
)).result[0].hostid;

// extract all passive zabbix agent interfaces. primary (AKA "main") and all other ZBX interfaces
var all_zbx_interfaces = JSON.parse(request.post(params.url,
    '{"jsonrpc":"2.0","method":"hostinterface.get","params":{"output":["interfaceid"],"filter":{"type":"1"},"hostids":"' + hostid + '"},"id":1}'
)).result;

// if any ZBX interface was found then proceed fetching all items
if (all_zbx_interfaces.length > 0) {
    // fetch all items which are defined at host level and ask which item use passive ZBX agent interface
    // simple check items (icmpping) also can use zabbix agent interface
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
                Zabbix.Log(3, 'interface mon: interfaceid in use: ' + items_with_int[int].interfaces[0].interfaceid);
                var row = {};
                row["itemid"] = items_with_int[int].itemid;
                row["interfaceid"] = items_with_int[int].interfaces[0].interfaceid;
                interfacesInUse.push(row);
            }

            // scan if one of items are attached to interface
            Zabbix.Log(3, 'interface mon: interfaceid array: ' + JSON.stringify(items_with_int[int].interfaces));
        }
    }

}

// final scan to recognize if items are in use
var needToDelete = 1;
var deleteEvidence = [];
for (var defined = 0; defined < all_zbx_interfaces.length; defined++) {
    // scan all items


    needToDelete = 1;
    for (var used = 0; used < interfacesInUse.length; used++) {
        if (all_zbx_interfaces[defined].interfaceid == interfacesInUse[used].interfaceid) {
            needToDelete = 0;

        }
    }

    // if flag was not turned off, then no items with this interface were found. no items are using this interface. safe to delete
    if (needToDelete > 0) {
        var deleteInt = JSON.parse(request.post(params.url,
            '{"jsonrpc":"2.0","method":"hostinterface.delete","params":["' + all_zbx_interfaces[defined].interfaceid + '"],"id":1}'
        )).result;
        var row = {};
        row["deleted"] = deleteInt;
        deleteEvidence.push(row);
    }
}


if (all_zbx_interfaces.length > 0) {
    return JSON.stringify({ "all_zbx_interfaces": all_zbx_interfaces, "interfacesInUse": interfacesInUse, "deleteEvidence": deleteEvidence });
} else {
    return 0;
}
