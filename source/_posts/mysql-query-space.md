---
title: mysql中varchar与char对结尾空格的不同处理逻辑
date: 2020-08-13 18:43:00
tags: mysql
categories: mysql
---
根据某个字段a的条件查询，查询到的结果却验证失败，一切都是空格的错  
之前已经发生过字符串开头不可见特殊字符引发的类似问题  
太久不碰到允许存储空格的业务，还是掉坑了  

<!-- more -->

测试表
```sql
CREATE TABLE `test` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `varchar_str` varchar(64) NOT NULL,
  `char_str` char(64) CHARACTER SET utf8mb4 NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB;
```
测试数据
```sql
INSERT INTO `test`(`id`, `varchar_str`, `char_str`) VALUES (1, ' a', ' a');
INSERT INTO `test`(`id`, `varchar_str`, `char_str`) VALUES (2, 'a ', 'a ');
INSERT INTO `test`(`id`, `varchar_str`, `char_str`) VALUES (3, ' a ', ' a ');
INSERT INTO `test`(`id`, `varchar_str`, `char_str`) VALUES (4, 'a', 'a');
```

```
mysql> select id, CONCAT('"', varchar_str, '"') as v, CONCAT('"', char_str, '"') as c from test  where `varchar_str`='a';
+----+------+-----+
| id | v    | c   |
+----+------+-----+
|  2 | "a " | "a" |
|  4 | "a"  | "a" |
+----+------+-----+
2 rows in set (0.03 sec)


mysql> select id, CONCAT('"', varchar_str, '"') as v, CONCAT('"', char_str, '"') as c from test  where `varchar_str`='a ';
+----+------+-----+
| id | v    | c   |
+----+------+-----+
|  2 | "a " | "a" |
|  4 | "a"  | "a" |
+----+------+-----+
2 rows in set (0.04 sec)

mysql> select id, CONCAT('"', varchar_str, '"') as v, CONCAT('"', char_str, '"') as c from test  where `varchar_str`=' a';
+----+-------+------+
| id | v     | c    |
+----+-------+------+
|  1 | " a"  | " a" |
|  3 | " a " | " a" |
+----+-------+------+
2 rows in set (0.04 sec)

mysql> select id, CONCAT('"', varchar_str, '"') as v, CONCAT('"', char_str, '"') as c from test  where `char_str`=  'a ';
+----+------+-----+
| id | v    | c   |
+----+------+-----+
|  2 | "a " | "a" |
|  4 | "a"  | "a" |
+----+------+-----+
2 rows in set (0.04 sec)

mysql> select id, CONCAT('"', varchar_str, '"') as v, CONCAT('"', char_str, '"') as c from test  where `varchar_str`= binary ' a';
+----+------+------+
| id | v    | c    |
+----+------+------+
|  1 | " a" | " a" |
+----+------+------+
1 row in set (0.04 sec)

mysql> select id, CONCAT('"', varchar_str, '"') as v, CONCAT('"', char_str, '"') as c from test  where `varchar_str`= binary 'a';
+----+-----+-----+
| id | v   | c   |
+----+-----+-----+
|  4 | "a" | "a" |
+----+-----+-----+
1 row in set (0.03 sec)

mysql> select id, CONCAT('"', varchar_str, '"') as v, CONCAT('"', char_str, '"') as c from test  where `char_str`= binary 'a ';
Empty set


```
## 原因
从上述的查询案例中应该已经可以说明  
如果字段类型为`char`或`varchar`，MySQL在进行字符串比较的时候，会使用`PADSPACE`规则，即忽视末尾空格  
另外要注意一点，`char`类型的字段，存储的数据取出时已经没有了结尾的空格了，所以查询时结尾的空格也是无意义的  

> The length of a CHAR column is fixed to the length that you declare when you create the table. The length can be any value from 0 to 255. When CHAR values are stored, they are right-padded with spaces to the specified length. When CHAR values are retrieved, trailing spaces are removed unless the PAD_CHAR_TO_FULL_LENGTH SQL mode is enabled.
> For nonbinary strings (CHAR, VARCHAR, and TEXT values), the string collation pad attribute determines treatment in comparisons of trailing spaces at the end of strings. NO PAD collations treat trailing spaces as significant in comparisons, like any other character. PAD SPACE collations treat trailing spaces as insignificant in comparisons; strings are compared without regard to trailing spaces. See Trailing Space Handling in Comparisons. The server SQL mode has no effect on comparison behavior with respect to trailing spaces.

## 解决方法
1. 使用`binary`
2. 使用like （不推荐）
3. 同时比较字符串的长度（不推荐）

## 参考连接
[MySQL文档](https://dev.mysql.com/doc/refman/8.0/en/char.html)