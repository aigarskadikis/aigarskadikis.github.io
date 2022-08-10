#!/bin/bash

clear
# start from empty space
> ../u/index.html

# put header
cat << 'EOF' >> ../u/index.html
<!DOCTYPE html>
<body>
<div id='config'>

<div id='servers'><table>
<tr><th>node1</th><th>IP</th><th>node2</th><th>IP</th></tr>
<tr>
<td><code>db1</code></td><td><input class='output-replace' name='192.168.88.101' value='192.168.88.101' data-default=''></td>
<td><code>db2</code></td><td><input class='output-replace' name='192.168.88.102' value='192.168.88.102' data-default=''></td>
</tr>
<tr>
<td><code>srv1</code></td><td><input class='output-replace' name='192.168.88.111' value='192.168.88.111' data-default=''></td>
<td><code>srv2</code></td><td><input class='output-replace' name='192.168.88.112' value='192.168.88.112' data-default=''></td>
</tr>
<tr>
<td><code>web1</code></td><td><input class='output-replace' name='192.168.88.121' value='192.168.88.121' data-default=''></td>
<td><code>web2</code></td><td><input class='output-replace' name='192.168.88.122' value='192.168.88.122' data-default=''></td>
</tr>
</table></div>

<div id='primaryUsers'><table>
<tr><th>user</th><th>password</th></tr>
<tr><td><code>zbx_srv</code></td><td><input class='output-replace' name='PasswordForApplicationServer' value='zabbix' data-default=''></td></tr>
<tr><td><code>zbx_web</code></td><td><input class='output-replace' name='PasswordForFrontendNode' value='zabbix' data-default=''></td></tr>
<tr><td><code>zbx_monitor</code></td><td><input class='output-replace' name='PasswordForAgent2MySQLMonitoring' value='zabbix' data-default=''></td></tr>
<tr><td><code>zbx_part</code></td><td><input class='output-replace' name='PasswordForDBPartitioning' value='zabbix' data-default=''></td></tr>
</table></div>

<div id='optionalUsers'><table>
<tr><th>user</th><th>password</th></tr>
<tr><td><code>repl</code></td><td><input class='output-replace' name='PasswordForDBReplication' value='zabbix' data-default=''></td></tr>
<tr><td><code>zbx_backup</code></td><td><input class='output-replace' name='PassfordForMySQLDUmp' value='zabbix' data-default=''></td></tr>
<tr><td><code>zbx_read_only</code></td><td><input class='output-replace' name='PasswordForReadOnlyUser' value='zabbix' data-default=''></td></tr>
<tr><td><code>grafana</code></td><td><input class='output-replace' name='PasswordForReadOnlyGrafanaUser' value='zabbix' data-default=''></td></tr>
</table>
</div>

<div>Name of Zabbix database:<input class='output-replace' name='zbx_db' value='zabbix' data-default=''></div>
</div>
<pre id='output'></pre>


<style>
* { margin:0; padding:0; }
#output { margin:1rem 0 5rem 1rem; min-height: 30vh; background-color:#fff; float:left;width:50%; }
#config { padding: 10px; border: 1px solid silver; float:right;min-width:20%; position:fixed; top:1rem;right:20px}
#config label { display: block; margin-bottom: 3px;}
td:nth-child(1),td:nth-child(3),th:nth-child(1),th:nth-child(3){text-align:right;padding:0 .5rem;}
td:nth-child(2),td:nth-child(4),th:nth-child(2),th:nth-child(4){text-align:left}
table{padding:.5rem 0}

</style>
<script>
let dom = document.getElementById('output');
let messages = [
EOF


cat ./users.sql | while IFS= read -r LINE
do {
	
echo -E "\"$LINE\"," >> ../u/index.html

} done
echo -E "\"\"" >> ../u/index.html


cat << 'EOF' >> ../u/index.html
];
let placeholders = document.querySelectorAll('.output-replace');

document.getElementById('config').addEventListener('change', e => {
    if (!e.target.classList.contains('output-replace')) {
        return;
    }

    updateOuput(dom, messages);
});
document.getElementById('config').addEventListener('keyup', e => {
    console.log('keyup');
    if (!e.target.classList.contains('output-replace')) {
        return;
    }

    updateOuput(dom, messages)
});
updateOuput(dom, messages);

function updateOuput(dom, messages) {
    

    let output = messages.join("\r\n");
    let key, value;

    for (let placeholder of placeholders) {
        key = new RegExp(placeholder.getAttribute('name'), 'g');
        value = placeholder.value;

        if (value == '' && placeholder.hasAttribute('data-default')) {
            value = placeholder.getAttribute('data-default');
        }

        output = output.replace(key, value);
    }

    dom.innerHTML = output;
}
</script>
    </body>
</html>
EOF





