---
title: >-
  mysql connectex: A connection attempt failed because the connected party did
  not properly respond after a period of time, or established connection failed
  because connected host has failed to respond
date: 2019-04-17 13:40:44
tags: 
    - mysql
    - go
categories: mysql
---

有一项MySQL数据迁移的工作，将原表（2000W+数据量）的数据处理后，分表（256张）存储  
是用Go来完成，计划使用相当于表数量的goroutines同时处理  
计划很好，代码也简单，按某个字段F取余决定分到某张表，然后按照字段F分组后，每组交由一个go协程处理  
然而，运行后不久就会报错
```
connectex: A connection attempt failed because the connected party did
  not properly respond after a period of time, or established connection failed
  because connected host has failed to respond
```

<!-- more -->
## 原因
原本以为是链接超时，但报错时间最短的在运行后20秒左右，所以排除  
然后转而关注数据库的连接数限制，毕竟本地测试库，max_connections设置是500，遂增加至800，问题依旧  
于是转而求助Google，但相关的报错搜索结果并没有精确的案例  
于是减少协程数量，通过chan控制协程数量到16，出错，8也出错，直到1个才正常运行，然而这样肯定不行，至少需要两个小时  
然后通过数据库监控查看processlist，发现在出错之前，大量的进程`State`为`Writing to net`于是搜素相关问题得以找到真实的原因  
`max_allowed_packet`参数才是问题的症结所在，当前数据库设置为`16M`而单次查询最多可能有10W+数据，超过1M，同时上百个查询的话，就会造成`Writing to net`  
进而引发上述报错  
之前了解的`max_allowed_packet`是限制单条写（insert/update）大小  
而这次了解到该参数是控制其通信缓冲区的最大长度，当大量结果集很大的查询同时存在时，就会超出其限制，导致报错

**PS**  
后续的迁移测试中，触发了另一个问题
```
[mysql] 2019/04/18 11:20:58 packets.go:36: unexpected EOF
[mysql] 2019/04/18 11:20:58 packets.go:393: busy buffer
```
而它的解决方案是设置最大空闲连接数为0``db.SetMaxIdleConns(0)``  
同时，也意识到A connection attempt failed ...的问题，还有一个重要原因就是服务器的性能太差了。。。  

**PS**
偶然翻开，感觉并没有实际解决掉问题  
于是又用了半个小时进行测试，这次应该是真正有效的解决方案了吧  
思路是，因为是连接时的问题，所以在目标数据库性能较差，连接较多时失败几率增大，只要保持一定量的长连接，减少创建/重连次数  
那就是设置空闲连接数量`db.SetMaxIdleConns(32)`的同时，设置最大生命周期`db.SetConnMaxLifetime(time.Minute * 30)`
## 解决方法
1. 修改my.cnf
添加或修改
```
max_allowed_packet = 128M
```
重启mysql服务器

2. 临时修改
```
set global max_allowed_packet = 128*1024*1024
```
当然，这样的修改重启mysql后就失效了，并且只对之后新创建的连接起作用

3. 修改数据库连接参数
```golang
db.SetMaxIdleConns(32)
db.SetMaxOpenConns(64)
db.SetConnMaxLifetime(time.Minute * 30)
```
首先，所有参数要考虑实际业务限制，具体的参数要视情况调整/尝试  
SetMaxOpenConns不能超过数据库最大连接数限制  
SetMaxIdleConns不能超过SetMaxOpenConns的设置  
SetConnMaxLifetime的时间要小于数据库`wait_timeout`设置的时间

## 参考链接
[unexpected EOF](https://github.com/go-sql-driver/mysql/issues/674)