// install correct session token and API endpoint
// sed 's|SID|9cfdda12eb693d0640d0f51b3afd66d9|g;s|JSON_RPC|http://127.0.0.1/api_jsonrpc.php|g' convert-zabbix_agentd.conf-into-global-macros.js > ~/convert-zabbix_agentd.conf-into-global-macros.js

// usage:
// zabbix_js --script convert-zabbix_agentd.conf-into-global-macros.js --timeout 60 --input <(grep -v "^$\|#" /etc/zabbix/zabbix_agentd.conf) --loglevel 3

// pattern to use with configuration
var pattern='ZA.CONF';

// pick up Zabbix API session token
var sid = 'SID';
var json_rpc = 'JSON_RPC';

// new http request
var req = new CurlHttpRequest();
req.AddHeader('Content-Type: application/json');

var varName = '';
var varValue = '';

var output = 'echo "';

var allGlobalMacros = JSON.parse(req.Post(json_rpc,
    '{"jsonrpc":"2.0","method":"usermacro.get","params":{"globalmacro":"true","output":["globalmacroid","macro","value"]},"auth":"' + sid + '","id":1}'
)).result;
var allGlobalMacrosLength = allGlobalMacros.length;

Zabbix.Log(4, JSON.stringify(allGlobalMacros));

//var lines = value.split("\n");
var lines = value.match(/.*=.*/gm);
var lines_num = lines.length;
for (i = 0; i < lines_num; i++) {
    varName = lines[i].match(/(.*)=/)[1];
    varValue = lines[i].match(/=(.*)/)[1];

    // let assume by default we need to create new macro. If we found an existing, we will turn the flag OFF
    var needToCreateNewMacro = 1;

    // analyze each global macro and check if this macro exists
    for (gm = 0; gm < allGlobalMacrosLength; gm++) {

	// look for pattern
        if (allGlobalMacros[gm].macro === '{$'+pattern+':' + varName + '}') {

            // check if installed value is NOT correct
            if (allGlobalMacros[gm].value !== varValue) {
                Zabbix.Log(4,
                    JSON.stringify(
                        JSON.parse(req.Post(json_rpc,
                            '{"jsonrpc":"2.0","method":"usermacro.updateglobal","params":{"globalmacroid":"' + allGlobalMacros[gm].globalmacroid + '","value":"' + varValue + '"},"auth":"' + sid + '","id":1}'
                        ))));

            }

            // if we get this far with the checking, this means macro exists and we do not create new
            needToCreateNewMacro = 0;

        }

    }

    if (needToCreateNewMacro === 1) {
        var el = JSON.parse(req.Post(json_rpc,
            '{"jsonrpc":"2.0","method":"usermacro.createglobal","params":{"macro":"{$'+pattern+':' + varName + '}","value":"' + varValue + '"},"auth":"' + sid + '","id":1}'
        )).result;
    }

    // put new line character only if this is not last line in array
    if (i < lines_num - 1) {
        output += varName + '={$'+pattern+':' + varName + '}\n'
    } else {
        output += varName + '={$'+pattern+':' + varName + '}'
    }

    Zabbix.Log(4, JSON.stringify(el));

    Zabbix.Log(4, varName + ' is ' + varValue);
}


output += '" | tee /etc/zabbix/zabbix_agentd.conf'
return output;
