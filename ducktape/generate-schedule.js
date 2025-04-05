var params = JSON.parse(value);

var request = new HttpRequest();
request.addHeader('Content-Type: application/json');
request.addHeader('Authorization: Bearer ' + params.token);

// fetch all host group IDs
var hostGroups = JSON.parse(request.post(params.url,
    '{"jsonrpc":"2.0","method":"hostgroup.get","params":{"output":["name","groupid"]},"id":1}'
)).result;

// locate ID of "father"
var groupID = 0;
for (var n = 0; n < hostGroups.length; n++) {
    if (hostGroups[n].name === 'PIDs/' + params.father) {
        groupid = hostGroups[n].groupid;
    }
}

Zabbix.Log(3, "Webhook Install scheduling, group id: " + groupid);

// observe insatalled macros per host group
var installedMacros = JSON.parse(request.post(params.url,
    '{"jsonrpc":"2.0","method":"usermacro.get","params":{"output":["macro","value"],"groupids":"' + groupid + '"},"id":1}'
)).result;

// installed bundle
var bundle = [];
for (var n = 0; n < installedMacros.length; n++) {
    if (installedMacros[n].macro === '{$' + 'ITS.TIME}') {
        bundle.push(installedMacros[n].value);
    }
}

Zabbix.Log(3, "Webhook Install scheduling, existing collection: " + JSON.stringify(bundle));

// generate all possible timestamps
function generateSchedule(batchDelay, offset) {
    // the perfect second
    var perfectSecond = offset % 60;
    // jump
    var jump = Math.floor(batchDelay / 60);
    // first minute to kick in
    var firstkick = Math.floor(offset / 60);
    var times = [];
    for (var m = firstkick; m < 60; m += jump) { times.push(m); }
    return "m" + times.join(',') + "s" + perfectSecond;
}


var all = [];
for (var n = 0; n < params.delay; n++) { all.push(generateSchedule(params.delay, n)); }



// find first slot which is not in use
var takeThis = '';
var inUse = 0;

for (var n = 0; n < all.length; n++) {

    // reset "slot" to not be in use
    var inUse = 0;

    for (var m = 0; m < bundle.length; m++) {
        Zabbix.Log(3, "Webhook Install scheduling, all: " + all[n] + ", bundle: " +bundle[m]);
        if (all[n] === bundle[m]) { inUse = 1; }
    }
    
    // if slot not taken then use it
    if (inUse === 0) { takeThis = all[n]; break; }
}

Zabbix.Log(3, "Webhook Install scheduling, takeThis: " + takeThis);


Zabbix.Log(3, "Webhook Install scheduling, new host macro: " + JSON.stringify(
    JSON.parse(request.post(params.url,
        '{"jsonrpc":"2.0","method":"usermacro.create","params":{"hostid":"' + params.hostid + '","macro":"{$' + 'ITS.TIME}","value":"'+takeThis+'"},"id":1}'
    )).result
)
);

return params.hostid;
