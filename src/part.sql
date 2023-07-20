--swap tables. this will allow to see oldest data. but the most recent data will be missing
RENAME TABLE history TO history_tmp; RENAME TABLE history_old TO history;
RENAME TABLE history_uint TO history_uint_tmp; RENAME TABLE history_uint_old TO history_uint;
RENAME TABLE history_str TO history_str_tmp; RENAME TABLE history_str_old TO history_str; 
RENAME TABLE history_log TO history_log_tmp; RENAME TABLE history_log_old TO history_log;
RENAME TABLE history_text TO history_text_tmp; RENAME TABLE history_text_old TO history_text; 
RENAME TABLE trends TO trends_tmp; RENAME TABLE trends_old TO trends; 
RENAME TABLE trends_uint TO trends_uint_tmp; RENAME TABLE trends_uint_old TO trends_uint; 

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

