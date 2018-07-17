---
title: mysql 1390 prepared statement contains too many placeholders
date: 2018-07-13 14:17:44
tags: mysql
categories: 数据库
---
收到告警邮件，执行mysql出错，如题，代码1390  
虽然问题容易定位，但也是出了问题才了解到  
对mysql各种配置所对应的限制，尤其是默认限制还是要主动了解的
<!-- more -->

mysql版本为5.6

## 原因
报错信息翻译过来就是
> 预处理 SQL语句时使用的占位符数量超过了限制


而限制默认为65535，能不能修改未知  
报错的语句使用了批量插入，总的占位符数量确实超出了65535的限制，导致报错  
另外，还有两个相似的配置，在批量操作或并发较多时较为关键  
- max_prepared_stmt_count
限制了同一时间在mysqld上所有session中prepared 语句的上限。它的取值范围为 0 - 1048576，默认为16382  
经典报错方式为   
``Error Code:1461 Can't create more than max_prepared_stmt_count statements (current value: 16382)``

- max_allowed_packet
设置MySQL服务器和客户端之间通信时可接收数据包的上限（读写），包括主从复制。  
如果一条语句插入数据过多，不触发占位符的限制也会触发此限制  
当然，不止是写操作，查询也受此配置的限制，当查询结果数据量超过此配置，也会触发  
``Error Code:1153 Got a packet bigger than 'max_allowed_packet' byte``

## 解决方法
拆分操作，将单一语句拆分为多条执行

## 参考链接
[MySQL Prepared SQL Statement Syntax](https://dev.mysql.com/doc/refman/5.6/en/sql-syntax-prepared-statements.html)
[MySQL Replication and max_allowed_packet](https://dev.mysql.com/doc/refman/5.6/en/replication-features-max-allowed-packet.html)
