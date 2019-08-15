---
title: mysql的io与索引使用分析
date: 2019-08-15 14:19:29
tags: mysql
categories: mysql
---
项目中很多表由于接手人很多，所以管生不管养的建立了大量索引。  
造成索引比数据大很多的奇葩现象，于是要找一找什么方式能方便的统计到索引的使用情况。  
于是发现了``performance_schema``库中的表``table_io_waits_summary_by_index_usage``。  
它聚合了所有表索引I / O等待事件
<!-- more -->
从网上找到了不少可用的SQL语句来解决问题，同时还关注到了这几张表。  
看描述就是系统优化的利器，虽然如今各种云RDS，能了解一些原生方式也是不错的。  
尴尬的是阿里云RDS下面的表默认情况下是空的，所以只能用他们的性能分析优化工具了

> table_io_waits_summary_by_index_usage: Table I/O waits per index  
> table_io_waits_summary_by_table: Table I/O waits per table  
> table_lock_waits_summary_by_table: Table lock waits per table

## 一些使用栗子
其实只用了第一个查询就满足了需求，其他的只是好奇玩玩，`Ctrl + C`而来  
具体的可查询MySQL文档，如参考链接
### 查询具体库/表的索引使用情况
index_name为NULL则表示未使用索引，文档中提到插入语句被计入此项  
`TRUNCATE TABLE`操作会重置表的值，更改表结构也可能会影响到统计  
```sql
SELECT
	object_type,
	object_schema,
	object_name,
	index_name,
	count_star,
	count_read,
	COUNT_FETCH 
FROM
	`performance_schema`.table_io_waits_summary_by_index_usage 
WHERE
    object_schema = 'database_name' AND
	object_name ='table_name'
```

### 反映表的读写压力
```sql
SELECT file_name AS file,
    count_read,
    sum_number_of_bytes_read AS total_read,
    count_write,
    sum_number_of_bytes_write AS total_written,
    (sum_number_of_bytes_read + sum_number_of_bytes_write) AS total
 FROM `performance_schema`.file_summary_by_instance
ORDER BY sum_number_of_bytes_read+ sum_number_of_bytes_write DESC;
```

### 反映文件的延迟
```sql
SELECT (file_name) AS file,
    count_star AS total,
    CONCAT(ROUND(sum_timer_wait / 3600000000000000, 2), 'h') AS total_latency,
    count_read,
    CONCAT(ROUND(sum_timer_read / 1000000000000, 2), 's') AS read_latency,
    count_write,
    CONCAT(ROUND(sum_timer_write / 3600000000000000, 2), 'h')AS write_latency
 FROM `performance_schema`.file_summary_by_instance
ORDER BY sum_timer_wait DESC;
```

### table 的读写延迟
```sql
SELECT object_schema AS table_schema,
       object_name AS table_name,
       count_star AS total,
       CONCAT(ROUND(sum_timer_wait / 3600000000000000, 2), 'h') as total_latency,
       CONCAT(ROUND((sum_timer_wait / count_star) / 1000000, 2), 'us') AS avg_latency,
       CONCAT(ROUND(max_timer_wait / 1000000000, 2), 'ms') AS max_latency
 FROM `performance_schema`.objects_summary_global_by_type
    ORDER BY sum_timer_wait DESC;
```

### 查看表操作频度

```sql
SELECT object_schema AS table_schema,
      object_name AS table_name,
      count_star AS rows_io_total,
      count_read AS rows_read,
      count_write AS rows_write,
      count_fetch AS rows_fetchs,
      count_insert AS rows_inserts,
      count_update AS rows_updates,
      count_delete AS rows_deletes,
       CONCAT(ROUND(sum_timer_fetch / 3600000000000000, 2), 'h') AS fetch_latency,
       CONCAT(ROUND(sum_timer_insert / 3600000000000000, 2), 'h') AS insert_latency,
       CONCAT(ROUND(sum_timer_update / 3600000000000000, 2), 'h') AS update_latency,
       CONCAT(ROUND(sum_timer_delete / 3600000000000000, 2), 'h') AS delete_latency
   FROM `performance_schema`.table_io_waits_summary_by_table
    ORDER BY sum_timer_wait DESC ;
```

### 索引状况
```sql
SELECT OBJECT_SCHEMA AS table_schema,
        OBJECT_NAME AS table_name,
        INDEX_NAME as index_name,
        COUNT_FETCH AS rows_fetched,
        CONCAT(ROUND(SUM_TIMER_FETCH / 3600000000000000, 2), 'h') AS select_latency,
        COUNT_INSERT AS rows_inserted,
        CONCAT(ROUND(SUM_TIMER_INSERT / 3600000000000000, 2), 'h') AS insert_latency,
        COUNT_UPDATE AS rows_updated,
        CONCAT(ROUND(SUM_TIMER_UPDATE / 3600000000000000, 2), 'h') AS update_latency,
        COUNT_DELETE AS rows_deleted,
        CONCAT(ROUND(SUM_TIMER_DELETE / 3600000000000000, 2), 'h')AS delete_latency
FROM `performance_schema`.table_io_waits_summary_by_index_usage
WHERE index_name IS NOT NULL
ORDER BY sum_timer_wait DESC;
```

### 全表扫描情况
```sql
SELECT object_schema,
    object_name,
    count_read AS rows_full_scanned
 FROM `performance_schema`.table_io_waits_summary_by_index_usage
WHERE index_name IS NULL
  AND count_read > 0
ORDER BY count_read DESC;
```

### 没有使用的index
```sql
SELECT object_schema,
    object_name,
    index_name
  FROM `performance_schema`.table_io_waits_summary_by_index_usage
 WHERE index_name IS NOT NULL
  AND count_star = 0
  AND object_schema not in ('mysql','v_monitor')
  AND index_name <> 'PRIMARY'
 ORDER BY object_schema, object_name;
```

### 糟糕的sql问题摘要
```sql
SELECT (DIGEST_TEXT) AS query,
    SCHEMA_NAME AS db,
    IF(SUM_NO_GOOD_INDEX_USED > 0 OR SUM_NO_INDEX_USED > 0, '*', '') AS full_scan,
    COUNT_STAR AS exec_count,
    SUM_ERRORS AS err_count,
    SUM_WARNINGS AS warn_count,
    (SUM_TIMER_WAIT) AS total_latency,
    (MAX_TIMER_WAIT) AS max_latency,
    (AVG_TIMER_WAIT) AS avg_latency,
    (SUM_LOCK_TIME) AS lock_latency,
    format(SUM_ROWS_SENT,0) AS rows_sent,
    ROUND(IFNULL(SUM_ROWS_SENT / NULLIF(COUNT_STAR, 0), 0)) AS rows_sent_avg,
    SUM_ROWS_EXAMINED AS rows_examined,
    ROUND(IFNULL(SUM_ROWS_EXAMINED / NULLIF(COUNT_STAR, 0), 0)) AS rows_examined_avg,
    SUM_CREATED_TMP_TABLES AS tmp_tables,
    SUM_CREATED_TMP_DISK_TABLES AS tmp_disk_tables,
    SUM_SORT_ROWS AS rows_sorted,
    SUM_SORT_MERGE_PASSES AS sort_merge_passes,
    DIGEST AS digest,
    FIRST_SEEN AS first_seen,
    LAST_SEEN as last_seen
  FROM `performance_schema`.events_statements_summary_by_digest d
where d
ORDER BY SUM_TIMER_WAIT DESC
limit 20;
```
## 参考链接
[Table I/O and Lock Wait Summary Tables](https://dev.mysql.com/doc/refman/5.6/en/table-waits-summary-tables.html#table-io-waits-summary-by-index-usage-table)