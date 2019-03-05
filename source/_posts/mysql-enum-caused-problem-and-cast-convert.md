---
title: enum字段数据迁移出错
date: 2019-03-05 10:24:46
tags: mysql
categories: mysql
---
功能重构后的数据迁移，有一张被拆分的表，迁移时直接使用了``insert into(xxx) select xxx from``的方式，简单高效  
然而，实则是挖了个坑，还好发现的早，不然就是严重事故了  
都是因为一个``ENUM``字段
<!-- more -->
简化的表结构如下
```sql
CREATE TABLE `old` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `status` enum('0','1') NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;

CREATE TABLE `new` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `status` tinyint(2) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB;
```
old表
| id  | status |
| --- | ------ |
| 2   | 0      |
| 3   | 1      |
迁移语句简化如下
```sql
TRUNCATE TABLE `new`;
INSERT INTO `new` ( `id`, `status` ) SELECT `id`,`status` FROM `old`;
```
结果，new表
| id  | status |
| --- | ------ |
| 2   | 1      |
| 3   | 2      |
## 原因
重构时未仔细比对新旧数据结构，想当然的把``status``字段当成了``tinyint``类型  
然而，前辈们为了性能做“优化”，选择了ENUM字段来存储**0,1**两个状态，即各种失败0，成功1  
而新结构中定义了N种可能的失败状态，这也造成在出现0，1外数字时，刚开始并未重视  
本次问题在于目标``new``表对应的字段类型为数字类型，所以存入的为enum字段的索引值  
而enum字段索引从1开始，所以存入`new`的内容都是**1,2**  

## ENUM的坑
- ENUM字段内部应该是使用数字索引的，所以这种用来存储数字的使用方式简直是灾难
    对应本次问题，字符串'0'
- 非严格模式下插入错误数据将会成功，但显示为空白，索引为数字0
- 非追加ENUM的字段内容时代价高昂

## 解决方法
转换字段类型  
强制取出字符串类型存储的数据，再转换成整型
```sql
TRUNCATE TABLE new;
INSERT INTO `new` ( `id`, `status` ) SELECT `id`, CONVERT ( CONVERT ( `status`, CHAR ), UNSIGNED ) AS `status` FROM `old`;
```
结果如下
| id  | status |
| --- | ------ |
| 2   | 0      |
| 3   | 1      |

## CAST vs. CONVERT
语法
```sql
CAST(expr AS type)
CONVERT(expr,type)
CONVERT(expr USING transcoding_name) 
```
CONVERT使用 USING子句可以转换字符集
>  SELECT CONVERT(latin1_column USING utf8) FROM latin1_table;

在不使用USING子句的情况想，和CAST一样，可以转换成以下字段类型  
- BINARY[(N)]
- CHAR[(N)]
- DATE
- DATETIME
- DECIMAL
- SIGNED   [INTEGER]
- TIME
- UNSIGNED   [INTEGER]

当然，两者都可以在不使用USING的情况下进行转换字符集
```sql
CONVERT(string, CHAR[(N)] CHARACTER SET charset_name)
CAST(string AS CHAR[(N)] CHARACTER SET charset_name)
```
## 参考链接
[Cast Functions and Operators](https://dev.mysql.com/doc/refman/8.0/en/cast-functions.html#function_convert)  
[The ENUM Type](https://dev.mysql.com/doc/refman/8.0/en/enum.html)