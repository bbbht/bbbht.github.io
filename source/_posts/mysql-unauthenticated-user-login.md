---
title: mysql unauthenticated user login
date: 2019-06-17 11:07:12
tags: mysql
categories: mysql
---

继续关注数据库问题，access记录中有大量超时请求，但慢日志却并没有记录。  
随即通过``show full processlist``发现线上数据库出现大量（数百）的非正常process  

| Server       | Id         | User                 | Host            | db  | Command | Time | State | Info |
| ------------ | ---------- | -------------------- | --------------- | --- | ------- | ---- | ----- | ---- |
| svc_database | 1076500670 | unauthenticated user | connecting host |     | Connect | 29   | login |      |

<!-- more -->
对完整的process分析后，筛选出了以下有效内容


| Server       | Id         | User                 | Host               | db  | Command     | Time   | State                                                         | Info                                                                                                                                                                                                                                                                                                                                                                                                                         |
| ------------ | ---------- | -------------------- | ------------------ | --- | ----------- | ------ | ------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| svc_database | 1072733149 | unauthenticated user | connecting host    |     | Connect     | 8      | login                                                         |                                                                                                                                                                                                                                                                                                                                                                                                                              |
| svc_database | 1072733085 | unauthenticated user | connecting host    |     | Connect     | 10     | login                                                         |                                                                                                                                                                                                                                                                                                                                                                                                                              |
| svc_database | 1072733021 | unauthenticated user | connecting host    |     | Connect     | 10     | login                                                         |                                                                                                                                                                                                                                                                                                                                                                                                                              |
| svc_database | 1072732957 | unauthenticated user | connecting host    |     | Connect     | 12     | login                                                         |                                                                                                                                                                                                                                                                                                                                                                                                                              |
| svc_database | 1072732893 | unauthenticated user | connecting host    |     | Connect     | 14     | login                                                         |                                                                                                                                                                                                                                                                                                                                                                                                                              |
| svc_database | 1072732829 | unauthenticated user | connecting host    |     | Connect     | 15     | login                                                         |                                                                                                                                                                                                                                                                                                                                                                                                                              |
| svc_database | 1062235623 | root                 | 192.168.1.25:56926 |     | Binlog Dump | 333003 | Master has sent all binlog to slave; waiting for more updates |                                                                                                                                                                                                                                                                                                                                                                                                                              |
| svc_database | 1072731869 | root                 | 192.168.1.25:59566 |     | Query       | 37     | executing                                                     | SELECT t_info.TABLE_SCHEMA,t_info.TABLE_NAME, t_info.TABLE_ROWS from information_schema.TABLES t_info where exists (select SCHEMA_NAME from information_schema.schemata where SCHEMA_NAME=t_info.TABLE_SCHEMA and SCHEMA_NAME !='information_schema' and SCHEMA_NAME !='mysql' and SCHEMA_NAME !='performance_schema' and SCHEMA_NAME !='sys') and t_info.TABLE_TYPE = 'BASE TABLE' ORDER BY t_info.TABLE_NAME limit 1000000 |

MySQL线程池（Thread Pool）根据参数thread_pool_size设为若干个group,每个group都负责维护客户端所发起的connections,  
当建立 connection 时, MySQL根据connection的thread id 对thread_pool_size取模,  
将connection交由对应的group处理。  
而每个group的最大worker数量为thread_pool_oversubscribe+1，listener线程不包含在内  
如果worker达到最大值后还是不足以处理请求,则后续connection将等待,从而导致了大量的unauthenticated user的login状态连接  

再看到最后那条，问题基本就清楚了    
是某云商的RDS数据库主从同步的一个查询超级慢所引发的  
结合数据库线程池相关配置  


| key                      | value |
| ------------------------ | ----- |
| threadpool_oversubscribe | 1     |
| threadpool_size          | 64    |


1072731869 % 64 = 29
1072733149 % 64 = 29
1072733085 % 64 = 29
。。。

都属于29号group

## 原因
threadpool_oversubscribe的值设置的不合理（1）导致一旦有大的查询，其它的连接就会一直处于连接状态，即在连接过程就耗费了过长的时间

## 解决方法
1. 最简单的是增大threadpool_oversubscribe配置，不至于一条查询阻塞其它的，然而，某云商并未提供修改途径。。。
2. 无解