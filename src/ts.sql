--list all chunks. pg 14.5, ts 2.8.1
SELECT show_chunks('history');

--list version
SELECT extversion FROM pg_extension WHERE extname='timescaledb'\gx

--top 50 chunks and their sizes
WITH chunk_sizes AS (
SELECT chunk_schema || '.' || chunk_name AS chunk, hypertable_schema || '.' || hypertable_name AS hypertable, pg_table_size(quote_ident(chunk_schema) || '.' || quote_ident(chunk_name)) AS size_bytes
FROM timescaledb_information.chunks
)
SELECT chunk, hypertable, pg_size_pretty(size_bytes) AS total_size
FROM chunk_sizes
ORDER BY size_bytes DESC
LIMIT 50;

--sum must fit into the buffer
WITH chunk_sizes AS( SELECT chunk_schema || '.' || chunk_name AS chunk , hypertable_schema || '.' || hypertable_name AS hypertable , pg_table_size(quote_ident(chunk_schema) || '.' || quote_ident(chunk_name)) AS size_bytes FROM timescaledb_information.chunks) , ranked_chunks AS ( SELECT chunk , hypertable , pg_size_pretty(size_bytes) AS total_size , size_bytes , ROW_NUMBER() OVER (PARTITION BY hypertable ORDER BY size_bytes DESC) AS rn FROM chunk_sizes ) , top_chunks AS ( SELECT hypertable , chunk , total_size , size_bytes FROM ranked_chunks WHERE rn = 1 ) , sum_row AS ( SELECT 'TOTAL' AS hypertable , NULL AS chunk , pg_size_pretty(SUM(size_bytes)) AS total_size , SUM(size_bytes) AS size_bytes FROM top_chunks ) SELECT hypertable , chunk , total_size FROM top_chunks UNION ALL SELECT hypertable , chunk , total_size FROM sum_row ;

--size of chunks and dates
SELECT hypertable_name,
to_timestamp(range_start_integer) AS range_start,
to_timestamp(range_end_integer) AS range_end,
chunk_name,
(range_end_integer-range_start_integer) AS size
FROM timescaledb_information.chunks
WHERE hypertable_name IN ('history','history_uint','history_str','history_log','history_text','trends_uint','trends')
AND range_start_integer > EXTRACT(EPOCH FROM NOW() - INTERVAL '24 hours')
ORDER BY 1,2;

--compress manually one chunk. pg 14.5, ts 2.8.1
SELECT compress_chunk('_timescaledb_internal._hyper_1_489_chunk');

--drop tables
DROP TABLE trends_tmp;
DROP TABLE trends_old;
DROP TABLE trends_uint_tmp;
DROP TABLE trends_uint_old;
DROP TABLE history_tmp;
DROP TABLE history_old;
DROP TABLE history_uint_tmp;
DROP TABLE history_uint_old;
DROP TABLE history_str_tmp;
DROP TABLE history_str_old;
DROP TABLE history_log_tmp;
DROP TABLE history_log_old;
DROP TABLE history_text_tmp;
DROP TABLE history_text_old;

--Allow the application layer to to drop old chunks by using housekeeper settings in GUI
UPDATE config SET db_extension='timescaledb',hk_history_global=1,hk_trends_global=1;

--explorer how many is compressed and uncompressed. pg 14.5, ts 2.8.1
SELECT chunk_schema,chunk_name,compression_status FROM chunk_compression_stats('history');

--to see if hypertable is compressed. pg 14.5, ts 2.8.1
SELECT chunk_schema,chunk_name,compression_status FROM chunk_compression_stats('history');

--decompress chunk. pg 14.5, ts 2.8.1
SELECT chunk_schema,chunk_name,compression_status FROM chunk_compression_stats('history');

--another way to print chunks per table
select * from _timescaledb_catalog.chunk where hypertable_id = (select id from _timescaledb_catalog.hypertable where table_name = 'history');

--compress all chunks from a time frame. pg 14.5, ts 2.8.1
SELECT compress_chunk(i) from SELECT show_chunks('history',1690372501,0) i;

--decompress all chunks. pg 14.5, ts 2.8.1
SELECT decompress_chunk(c, true) FROM show_chunks('trends_uint') c;
SELECT decompress_chunk(c, true) FROM show_chunks('trends') c;
SELECT decompress_chunk(c, true) FROM show_chunks('history_uint') c;
SELECT decompress_chunk(c, true) FROM show_chunks('history_str') c;
SELECT decompress_chunk(c, true) FROM show_chunks('history_log') c;
SELECT decompress_chunk(c, true) FROM show_chunks('history_text') c;
SELECT decompress_chunk(c, true) FROM show_chunks('history') c;

--list chunk sizes of hypertables
SELECT h.table_name, c.interval_length
FROM _timescaledb_catalog.dimension c
JOIN _timescaledb_catalog.hypertable h
ON h.id = c.hypertable_id;

