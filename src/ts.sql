--list all chunks. pg 14.5, ts 2.8.1
SELECT show_chunks('history');

--list version
SELECT extversion FROM pg_extension WHERE extname='timescaledb'\gx

--compress manually one chunk. pg 14.5, ts 2.8.1
SELECT compress_chunk('_timescaledb_internal._hyper_1_489_chunk');

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

