// where Zabbix API endpoint is located
var json_rpc = 'http://127.0.0.1/api_jsonrpc.php';

// static token
var token = 'tokenHere';

// everything needed for "curl"
var req = new HttpRequest();
req.addHeader('Content-Type: application/json');

// run API method
var existingHostList = JSON.parse(req.post(json_rpc,
    '{"jsonrpc":"2.0","method":"host.get","params":{"output":["host","hostid"]},"auth":"' + token + '","id": 1}'
)).result;

var interfaceList = JSON.parse(req.post(json_rpc,
'{"jsonrpc":"2.0","method":"hostinterface.get","params":{"output":["dns","main","useip","hostid","type","port","ip"]},"auth":"'+token+'","id":1}'
)).result;

// merge together a hostname with interface
// this will allow later to check if such IP is already registred
var allTogether = [];
for (i in interfaceList) {

    var row = {};
    row = interfaceList[i];

    // iterate through host array to find the matching host title
    for (h in existingHostList) {

        // check if there is a match between the hostid which belongs at item level and the host array
        if (interfaceList[i].hostid === existingHostList[h].hostid) {

            row["host"] = existingHostList[h].host;

            break;
        }

    }


    allTogether.push(row);

}


var host, ip, hostname = '';
var needToCreate = 1;
var lines = value.split("\n");
var lines_num = lines.length;
for (i = 0; i < lines_num; i++) {
    // check if line is having ',' symbol. this means not an empty line
    if (lines[i].match(/,/gm) && lines[i].length > 1) {

        // cut numbers, spaces, dash, dot from the end of line. remove special characters
        host = lines[i]
            .replace(/\"/gm, '')
            .replace(/\&/gm, 'and')
            .replace(/\'/gm, '')
            .replace(/,\S+$/, '')
            .replace(/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/, '')
            .replace(/[\[\]\(\)#{}]/gm, '')
            .replace(/\\/gm, ' ')
            .replace(/~/gm, ' ')
            .replace(/\//gm, ' ')
            .replace(/:/gm, ' ')
            .replace(/,/gm, '')
            .replace(/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$/, '')
            .replace(/[ -]+$/gm, '');

ip = lines[i].match(/[0-9a-z\.]+$/gm)[0];

        // check if host exists
        needToCreate = 1;
        for (h = 0; h < allTogether.length; h++) {
                hostname=host+' - '+ip;
            if (allTogether[h].host === hostname) {
                needToCreate = 0;
                break;
            }
        }

        if (needToCreate === 1) {

            Zabbix.Log(3, 'host: ' + host);

            // extract the IP address
            Zabbix.Log(3, 'IP: ' + ip);


            // groupid 25 => Master Device List
            // groupid 26 => Routers
            // groupid 27 => WIRELESS BACKHAUL
            // groupid 28 => SWITCHES
            // groupid 29 => UPS
            groupid = 25;

            // check if IP field is a normal IP address

            if (ip.match(/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/)) {

                Zabbix.Log(3, JSON.stringify(
                    JSON.parse(req.post(json_rpc,
                        '{"jsonrpc":"2.0","method":"host.create","params":{"host":"' + host + ' - '+ ip +'","interfaces":[{"type":2,"dns":"","main":1,"ip":"' + ip + '","port":161,"useip":1,"details":{"version":"2","bulk":"1","community":"{$SNMP_COMMUNITY}"}}],"groups":[{"groupid":"' + groupid + '"}],"templates":[{"templateid":"10615"}]},"auth":"' + token + '","id": 1}'
                    )).result
                )
                )

            } else {
                // IP field holds textual data like DNS entry
                Zabbix.Log(3, JSON.stringify(
                    JSON.parse(req.post(json_rpc,
                        '{"jsonrpc":"2.0","method":"host.create","params":{"host":"' + host + ' - '+ ip +'","interfaces":[{"type":2,"dns":"' + ip + '","main":1,"ip":"","port":161,"useip":0,"details":{"version":"2","bulk":"1","community":"{$SNMP_COMMUNITY}"}}],"groups":[{"groupid":"' + groupid + '"}],"templates":[{"templateid":"10615"}]},"auth":"' + token + '","id": 1}'
                    )).result
                )
                )
            }

            // end of needToCreate
        }

    }
}

// run API method
var hostList = JSON.parse(req.post(json_rpc,
    '{"jsonrpc":"2.0","method":"host.get","params":{"output":["host","hostid"]},"auth":"' + token + '","id": 1}'
)).result;

return hostList.length;

