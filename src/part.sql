--swap tables. this will allow to see oldest data. but the most recent data will be missing
RENAME TABLE history TO history_tmp; RENAME TABLE history_old TO history;
RENAME TABLE history_uint TO history_uint_tmp; RENAME TABLE history_uint_old TO history_uint;
RENAME TABLE history_str TO history_str_tmp; RENAME TABLE history_str_old TO history_str; 
RENAME TABLE history_log TO history_log_tmp; RENAME TABLE history_log_old TO history_log;
RENAME TABLE history_text TO history_text_tmp; RENAME TABLE history_text_old TO history_text; 
RENAME TABLE trends TO trends_tmp; RENAME TABLE trends_old TO trends; 
RENAME TABLE trends_uint TO trends_uint_tmp; RENAME TABLE trends_uint_old TO trends_uint;

--create dedicated user for MySQL 8
DROP USER IF EXISTS 'zbx_part'@'127.0.0.1';
CREATE USER 'zbx_part'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY '';
GRANT SELECT, ALTER, DROP ON zabbix.history TO 'zbx_part'@'127.0.0.1';
GRANT SELECT, ALTER, DROP ON zabbix.history_uint TO 'zbx_part'@'127.0.0.1';
GRANT SELECT, ALTER, DROP ON zabbix.history_str TO 'zbx_part'@'127.0.0.1';
GRANT SELECT, ALTER, DROP ON zabbix.history_text TO 'zbx_part'@'127.0.0.1';
GRANT SELECT, ALTER, DROP ON zabbix.history_log TO 'zbx_part'@'127.0.0.1';
GRANT SELECT, ALTER, DROP ON zabbix.history_bin TO 'zbx_part'@'127.0.0.1';
GRANT SELECT, ALTER, DROP ON zabbix.trends TO 'zbx_part'@'127.0.0.1';
GRANT SELECT, ALTER, DROP ON zabbix.trends_uint TO 'zbx_part'@'127.0.0.1';
GRANT SELECT, ALTER, DROP ON zabbix.auditlog TO 'zbx_part'@'127.0.0.1';
GRANT SELECT ON zabbix.dbversion TO 'zbx_part'@'127.0.0.1';
GRANT SELECT,DELETE ON zabbix.housekeeper TO 'zbx_part'@'127.0.0.1';
FLUSH PRIVILEGES;

--restore back most recent data
INSERT IGNORE INTO history SELECT * FROM history_tmp;
INSERT IGNORE INTO history_uint SELECT * FROM history_uint_tmp;
INSERT IGNORE INTO history_str SELECT * FROM history_str_tmp;
INSERT IGNORE INTO history_log SELECT * FROM history_log_tmp;
INSERT IGNORE INTO history_text SELECT * FROM history_text_tmp;
INSERT IGNORE INTO trends SELECT * FROM trends_tmp;
INSERT IGNORE INTO trends_uint SELECT * FROM trends_uint_tmp;

--check all graphs, it should be completed. If graphs are perfect:
DROP TABLE history_tmp;
DROP TABLE history_uint_tmp;
DROP TABLE history_str_tmp;
DROP TABLE history_log_tmp;
DROP TABLE history_text_tmp;
DROP TABLE trends_tmp;
DROP TABLE trends_uint_tmp;

--drop old
DROP TABLE history_uint_old;
DROP TABLE trends_uint_old;
DROP TABLE history_old;
DROP TABLE trends_old;
DROP TABLE history_text_old;
DROP TABLE history_str_old;
DROP TABLE history_log_old;

--put back all data/graphs together (accessible in frontend):
RENAME TABLE trends_uint TO trends_uint_tmp; RENAME TABLE trends_uint_old TO trends_uint; INSERT IGNORE INTO trends_uint SELECT * FROM trends_uint_tmp;
RENAME TABLE trends TO trends_tmp; RENAME TABLE trends_old TO trends; INSERT IGNORE INTO trends SELECT * FROM trends_tmp;
RENAME TABLE history_uint TO history_uint_tmp; RENAME TABLE history_uint_old TO history_uint; INSERT IGNORE INTO history_uint SELECT * FROM history_uint_tmp;
RENAME TABLE history TO history_tmp; RENAME TABLE history_old TO history; INSERT IGNORE INTO history SELECT * FROM history_tmp;
RENAME TABLE history_str TO history_str_tmp; RENAME TABLE history_str_old TO history_str; INSERT IGNORE INTO history_str SELECT * FROM history_str_tmp;
RENAME TABLE history_text TO history_text_tmp; RENAME TABLE history_text_old TO history_text; INSERT IGNORE INTO history_text SELECT * FROM history_text_tmp;
RENAME TABLE history_log TO history_log_tmp; RENAME TABLE history_log_old TO history_log; INSERT IGNORE INTO history_log SELECT * FROM history_log_tmp;

--validate if there are 10 new tables
SHOW CREATE TABLE history_new\G
SHOW CREATE TABLE history_uint_new\G
SHOW CREATE TABLE history_str_new\G
SHOW CREATE TABLE history_log_new\G
SHOW CREATE TABLE history_text_new\G
SHOW CREATE TABLE history_part\G
SHOW CREATE TABLE history_uint_part\G
SHOW CREATE TABLE history_str_part\G
SHOW CREATE TABLE history_log_part\G
SHOW CREATE TABLE history_text_part\G

--detach the current "history" tables from the application and set new/empty tables in place
RENAME TABLE history_uint TO history_uint_old; RENAME TABLE history_uint_new TO history_uint;
RENAME TABLE history TO history_old; RENAME TABLE history_new TO history;
RENAME TABLE history_str TO history_str_old; RENAME TABLE history_str_new TO history_str;
RENAME TABLE history_text TO history_text_old; RENAME TABLE history_text_new TO history_text;
RENAME TABLE history_log TO history_log_old; RENAME TABLE history_log_new TO history_log;

--open "tmux" and migrate the data from an unpartitioned table space to a partitioned table space
SET SESSION SQL_LOG_BIN=0;
INSERT IGNORE INTO history_str_part SELECT * FROM history_str_old;
INSERT IGNORE INTO history_text_part SELECT * FROM history_text_old;
INSERT IGNORE INTO history_log_part SELECT * FROM history_log_old;
INSERT IGNORE INTO history_uint_part SELECT * FROM history_uint_old;
INSERT IGNORE INTO history_part SELECT * FROM history_old;

--attach/swap the partitioned tables to the application later
RENAME TABLE history_uint TO history_uint_tmp; RENAME TABLE history_uint_part TO history_uint;
RENAME TABLE history TO history_tmp; RENAME TABLE history_part TO history;
RENAME TABLE history_str TO history_str_tmp; RENAME TABLE history_str_part TO history_str;
RENAME TABLE history_text TO history_text_tmp; RENAME TABLE history_text_part TO history_text;
RENAME TABLE history_log TO history_log_tmp; RENAME TABLE history_log_part TO history_log;

--transfer back data which was collected during the migration
INSERT IGNORE INTO history_uint SELECT * FROM history_uint_tmp;
INSERT IGNORE INTO history SELECT * FROM history_tmp;
INSERT IGNORE INTO history_str SELECT * FROM history_str_tmp;
INSERT IGNORE INTO history_text SELECT * FROM history_text_tmp;
INSERT IGNORE INTO history_log SELECT * FROM history_log_tmp;

--drop unnecessary tables
DROP TABLE history_uint_tmp;
DROP TABLE history_tmp;
DROP TABLE history_str_tmp;
DROP TABLE history_text_tmp;
DROP TABLE history_log_tmp;
DROP TABLE history_str_old;
DROP TABLE history_text_old;
DROP TABLE history_log_old;
DROP TABLE history_uint_old;
DROP TABLE history_old;

