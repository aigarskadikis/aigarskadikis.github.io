var data = JSON.parse(value);
if ( data.one < 20 && data.two > 0 ) {
return 0;
} else {
return 1;
}
// zabbix_js -s script.js -p '{"one":"11","two":"22"}'

