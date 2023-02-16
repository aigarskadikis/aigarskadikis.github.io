# switch to SQL mode
\sql

# change global variable in order to allow MySQL work with external directories:
set global local_infile = 'on';

# switch to JavaScript mode
\js

# set DB name
DBname="zabbix"

# set destination directory
DBdumpath="/tmp"

# download schema
util.dumpSchemas([DBname],DBdumpath+"/zabbix_schema.dump", {ddlOnly: true, threads: 8, showProgress: true});

# dump all
DBname="zabbix"
DBdumpath="/tmp"
util.dumpTables(DBname, [], DBdumpath + DBname, {"all": true,"threads": 4,"bytesPerChunk": "256M"});

# download configuration
util.dumpSchemas(
[DBname],
DBdumpath+"/zabbix_configuration.dump", {
excludeTables:[
DBname+".history",
DBname+".history_uint",
DBname+".history_log",
DBname+".history_text",
DBname+".history_str",
DBname+".trends",
DBname+".trends_uint"
], threads: 8, showProgress: true}
);

# download configuration with zstd compression
util.dumpSchemas(
[DBname],
DBdumpath+"/zabbix_configuration.dump.zstd", {
excludeTables:[
DBname+".history",
DBname+".history_uint",
DBname+".history_log",
DBname+".history_text",
DBname+".history_str",
DBname+".trends",
DBname+".trends_uint"
], threads: 8, compression: "zstd", showProgress: true}
);

# download configuration with gzip compression
util.dumpSchemas(
[DBname],
DBdumpath+"/zabbix_configuration.dump.gzip", {
excludeTables:[
DBname+".history",
DBname+".history_uint",
DBname+".history_log",
DBname+".history_text",
DBname+".history_str",
DBname+".trends",
DBname+".trends_uint"
], threads: 8, compression: "gzip", showProgress: true}
);

