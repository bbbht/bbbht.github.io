---
title: Go查询MySQLdatetime列，设置时区
date: 2018-11-27 14:02:50
tags: 
    - go
    - mysql
categories: go
---

Go操作MySQL数据库，插入`datetime`列的数据都是UTC时间  
Go中对应的类型为`time.Time`，即便设置了时区也是一样的结果  
所以要改变`mysql`包的默认行为，设置时区  

<!-- more -->

## 原因
Go操作`datetime`类型时会默认UTC时间，所以如果Go对应的类型为`time.Time`，会被转成UTC时间，然后插入

## 解决方法
1. 使用字符串类型插入  
   查询，以及为`null`的情况尴尬
2. 连接数据库时进行设置
拼接DSN时，加入配置
```go
dsnStr := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true&charset=utf8mb4&collation=utf8mb4_general_ci&loc=%s",
    Config.DBUser,
    Config.DBPass,
    Config.DBHost,
    Config.DBPort,
    Config.DBName,
    url.QueryEscape("Asia/Shanghai"))
```
其中`parseTime`，`loc`为相关配置，且`loc`包含特殊字符，需转义    

### parseTime
> Type:           bool
> Valid Values:   true, false
> Default:        false
> parseTime=true changes the output type of DATE and DATETIME values to time.Time instead of []byte / string The date or datetime like 0000-00-00 00:00:00 is converted into zero value of time.Time.

### loc
> Type:           string
> Valid Values:   <escaped name>
> Default:        UTC
> Sets the location for time.Time values (when using parseTime=true). "Local" sets the system's location. See time.LoadLocation for details.

> Note that this sets the location for time.Time values but does not change MySQL's time_zone setting. For that see the time_zone system variable, which can also be set as a DSN parameter.

> Please keep in mind, that param values must be url.QueryEscape'ed. Alternatively you can manually replace the / with %2F. For example US/Pacific would be loc=US%2FPacific.

## 参考链接
[go-sql-driver/mysql](https://github.com/go-sql-driver/mysql)