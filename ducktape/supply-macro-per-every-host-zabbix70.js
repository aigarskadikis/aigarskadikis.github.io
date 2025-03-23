var params = JSON.parse(value);

// new http request
var req = new HttpRequest();

// header
req.addHeader('Content-Type: application/json');
req.addHeader('Authorization: Bearer ' + params.token);


var el = JSON.parse(req.post(params.url,
  '{"jsonrpc":"2.0","method":"host.get","params":{"output":["hostid","host","macros","flags"],"selectMacros":"extend"},"id":1}'
)).result;

var madeNewMacro = [];
var updatedExistingMacro = [];

// iterate through all host objects one by one
for (i = 0; i < el.length; i++) {
  if (el[i].flags == 0) {
    // host is not prototype
    var macroHostIdExists = 0;
    var macroHostHostExists = 0;
    // if there are some macros installed, then investigate for analytics
    if (el[i].macros.length > 0) {
      var macrosExpanded = el[i].macros;
      var amountOfMacrosInstalledOnHost = macrosExpanded.length;
      // Zabbix.Log(3,"MACROMAINTAIN: "+JSON.stringify(macrosExpanded));
      // analyze every single macro which is installed on current host object
      for (m = 0; m < amountOfMacrosInstalledOnHost; m++) {
        // Zabbix.Log(3,"MACROMAINTAIN: macro: "+macrosExpanded[m].macro);
        // iterate through all macros
        // take every macro and check if the macro is HOSTID
        if (macrosExpanded[m].macro == '{$' + 'HOST.ID}') {
          // let's check if the value match the actual hostid
          // this is possible because the macro belong to hostid
          if (macrosExpanded[m].hostid == macrosExpanded[m].value) {
            // if value already match then do nothing
            // Zabbix.Log(3,"MACROMAINTAIN: host: \""+el[i].host+"\" HOSTID value istalled correctly");
            macroHostIdExists = 1;
          } else {
            // now need to launch update operation to replace the value
            // since we know the macro ID then there is a dedicated API method to do that
            var usermacroUpdate = JSON.parse(req.post(params.url,
              '{"jsonrpc":"2.0","method":"usermacro.update","params":{"hostmacroid":"' + macrosExpanded[m].hostmacroid + '","value":"' + macrosExpanded[m].hostid + '"},"id":1}'
            ));
            Zabbix.Log(3, "MACROMAINTAIN: host: \"" + el[i].host + "\" macro exists but value is wrong. Reinstalling value. Api response: " + JSON.stringify(usermacroUpdate));
            updatedExistingMacro.push(usermacroUpdate);
            macroHostIdExists = 1;
          }
        }

        if (macrosExpanded[m].macro == '{$' + 'HOST.HOST}') {
          // let's check if the value match the actual hostid
          // this is possible because the macro belong to hostid
          if (el[i].host == macrosExpanded[m].value) {
            // if value already match then do nothing
            // Zabbix.Log(3,"MACROMAINTAIN: host: \""+el[i].host+"\" HOSTID value istalled correctly");
            macroHostHostExists = 1;
          } else {
            // now need to launch update operation to replace the value
            // since we know the macro ID then there is a dedicated API method to do that

            var usermacroUpdate = JSON.parse(req.post(params.url,
              '{"jsonrpc":"2.0","method":"usermacro.update","params":{"hostmacroid":"' + macrosExpanded[m].hostmacroid + '","value":"' + el[i].host + '"},"id":1}'
            ));
            Zabbix.Log(3, "MACROMAINTAIN: host: \"" + el[i].host + "\" macro exists but value is wrong. Reinstalling value. Api response: " + JSON.stringify(usermacroUpdate));
            updatedExistingMacro.push(usermacroUpdate);
            macroHostHostExists = 1;
          }
        }
      }

    }
    // if macro does not exist then install it
    if (macroHostIdExists == 0) {
      var userMacroCreate = JSON.parse(req.post(params.url,
        '{"jsonrpc":"2.0","method":"usermacro.create","params":{"hostid":"' + el[i].hostid + '","macro":"' + '{$' + 'HOST.ID}' + '","value":"' + el[i].hostid + '"},"id":1}'
      ));
      Zabbix.Log(3, "MACROMAINTAIN: HOST.ID macro on host \"" + el[i].host + "\" does not exist. Installing now. Api response: " + JSON.stringify(userMacroCreate));
      madeNewMacro.push(userMacroCreate);
    }


    if (macroHostHostExists == 0) {
      var userMacroCreate = JSON.parse(req.post(params.url,
        '{"jsonrpc":"2.0","method":"usermacro.create","params":{"hostid":"' + el[i].hostid + '","macro":"' + '{$' + 'HOST.HOST}' + '","value":"' + el[i].host + '"},"id":1}'
      ));
      Zabbix.Log(3, "MACROMAINTAIN: HOST.HOST macro on host \"" + el[i].host + "\" does not exist. Installing now. Api response: " + JSON.stringify(userMacroCreate));
      madeNewMacro.push(userMacroCreate);
    }

    //host is not prototype
  }
  // end of iteration
}

return JSON.stringify({
  'totalHosts': el.length,
  'installedNew': madeNewMacro,
  'updatedExisting': updatedExistingMacro
});
