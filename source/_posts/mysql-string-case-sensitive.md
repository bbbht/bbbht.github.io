---
title: mysql字符串比较查询时的大小写敏感问题
date: 2020-08-14 09:40:13
tags: mysql
categories: mysql
---
继上篇空格引发问题后，大小写也在排查过程中引发了问题  
由于COLLATE的设置，导致MySQL不区分大小写进行了匹配  
<!-- more -->

```sql
CREATE TABLE `test2` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `str_ci` varchar(64) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL,
  `str_bin` varchar(64) CHARACTER SET utf8 COLLATE utf8_bin NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_str_ci` (`str_ci`)
) ENGINE=InnoDB;

INSERT INTO `cdn`.`test2`(`id`, `str_ci`, `str_bin`) VALUES (1, 'abc', 'abc');

INSERT INTO `cdn`.`test2`(`id`, `str_ci`, `str_bin`) VALUES (2, 'ABC', 'ABC');
```

```
mysql> SELECT * FROM `test2` WHERE `str_ci` = 'abc';
+----+--------+---------+
| id | str_ci | str_bin |
+----+--------+---------+
|  1 | abc    | abc     |
|  2 | ABC    | ABC     |
+----+--------+---------+
2 rows in set (0.02 sec)

mysql> SELECT * FROM `test2` WHERE `str_bin` = 'abc';
+----+--------+---------+
| id | str_ci | str_bin |
+----+--------+---------+
|  1 | abc    | abc     |
+----+--------+---------+
1 row in set (0.02 sec)

mysql> SELECT * FROM `test2` WHERE `str_ci` = BINARY 'abc';
+----+--------+---------+
| id | str_ci | str_bin |
+----+--------+---------+
|  1 | abc    | abc     |
+----+--------+---------+
1 row in set (0.02 sec)

```

注意binary对索引的影响
```
mysql> EXPLAIN SELECT * FROM `test2` WHERE `str_ci` = 'abc';
+----+-------------+-------+------+---------------+------------+---------+-------+------+-----------------------+
| id | select_type | table | type | possible_keys | key        | key_len | ref   | rows | Extra                 |
+----+-------------+-------+------+---------------+------------+---------+-------+------+-----------------------+
|  1 | SIMPLE      | test2 | ref  | idx_str_ci    | idx_str_ci | 194     | const |    2 | Using index condition |
+----+-------------+-------+------+---------------+------------+---------+-------+------+-----------------------+
1 row in set (0.05 sec)

mysql> EXPLAIN SELECT * FROM `test2` WHERE `str_ci` = BINARY 'abc';
+----+-------------+-------+-------+---------------+------------+---------+------+------+-----------------------+
| id | select_type | table | type  | possible_keys | key        | key_len | ref  | rows | Extra                 |
+----+-------------+-------+-------+---------------+------------+---------+------+------+-----------------------+
|  1 | SIMPLE      | test2 | range | idx_str_ci    | idx_str_ci | 194     | NULL |    2 | Using index condition |
+----+-------------+-------+-------+---------------+------------+---------+------+------+-----------------------+
1 row in set (0.06 sec)

mysql> EXPLAIN SELECT * FROM `test2` WHERE BINARY `str_ci` = 'abc';
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
| id | select_type | table | type | possible_keys | key  | key_len | ref  | rows | Extra       |
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
|  1 | SIMPLE      | test2 | ALL  | NULL          | NULL | NULL    | NULL |    2 | Using where |
+----+-------------+-------+------+---------------+------+---------+------+------+-------------+
1 row in set (0.07 sec)

```
## 原因
默认情况下字符串字段的内容是不区分大小写的，所以相同字母不同大小写规则的数据会被当做相等数据查出  

从上面测试中也能看到，当binary关键字放到字段名前时，不适用索引，将导致性能问题，原因可简化理解是对字段使用了函数  
所以使用时还是建议将关键字加在条件值前  
另外，在join关联表查询时，如果关联字段为字符串，且字符集、字符序不对应，也将导致验证的性能问题   

关于字符序的说明：
1. *_ci
    case sensitive  
    不区分大小写  
2. *_bin
    每个字符串用二进制编码存储，区分大小写  

## 解决方法
1. 使用binary关键字
    注意索引性能  
2. 修改表库或字段的字符序规则为*_bin
3. 如果业务运行，存储时使用`lower/upper`，同时查询时预先对条件值使用`lower/upper`

最好是在设计表结构时就预考虑字段是否需要保持大小写敏感，预防为主  