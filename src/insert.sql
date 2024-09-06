--copy data from one table to another
INSERT INTO history_uint SELECT 88656,clock,value,ns FROM history_uint WHERE itemid=88641;

