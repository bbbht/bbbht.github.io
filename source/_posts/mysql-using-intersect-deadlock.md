---
title: mysql使用索引合并(using intersect)导致死锁(deadlock)
date: 2019-06-12 16:24:27
tags: mysql
categories: mysql
---

线上日志报警，出现大量死锁
```
Error 1213: Deadlock found when trying to get lock; try restarting transaction 
```
排查后发现是使用了索引合并，从而在并发较高时触发了死锁
<!-- more -->
## 现象
表结构简化如下
```sql
CREATE TABLE `t` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `a` int(11),
  `b` int(11),
  `c` int(11),
  `key` VARCHAR(120),
  PRIMARY KEY (`id`),
  KEY `idx_a` (`a`),
  KEY `idx_b` (`b`),
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
```
查询语句简化为
```sql
UPDATE `t` SET `c` = 1 WHERE `a` = 1 AND `b` = 2; 
```

报错信息为
```
Error 1213: Deadlock found when trying to get lock; try restarting transaction 
```
查询数据库死锁日志
```sql
SHOW ENGINE INNODB STATUS;
```
获取到的关键信息如下
```
--- LATEST DETECTED DEADLOCK 
--- 2019-06-12 15:15:27 0x7f15ffc99700 

*** (1) TRANSACTION: TRANSACTION 3173924399, query id 39485215503 192.168.1.149 root updating UPDATE `t` SET `c` = 0 WHERE `a` in (861194) AND `b` = 12971 AND `key` = 'abcdefg' 
*** (1) WAITING FOR THIS LOCK TO BE GRANTED: RECORD LOCKS space id 3791 page no 5461 n bits 272 index idx_b of table `test_database`.`t` trx id 3173924399 lock_mode X waiting Record lock, heap no 26 PHYSICAL RECORD: n_fields 2;

*** (2) TRANSACTION: TRANSACTION 3173924396, query id 39485215477 192.168.1.149 root updating UPDATE `t` SET `c` = 0 WHERE `a` in (861200) AND `b` = 12971 AND `key` = 'lkjsdf' 
*** (2) HOLDS THE LOCK(S): RECORD LOCKS space id 3791 page no 5461 n bits 272 index idx_b of table `test_database`.`t` trx id 3173924396 lock_mode X Record lock, heap no 1 PHYSICAL RECORD: n_fields 1;

*** (2) WAITING FOR THIS LOCK TO BE GRANTED: RECORD LOCKS space id 3791 page no 19918 n bits 376 index PRIMARY of table `test_database`.`t` trx id 3173924396 lock_mode X locks rec but not gap waiting Record lock, heap no 297 PHYSICAL RECORD: n_fields 7;

*** WE ROLL BACK TRANSACTION (1) 
```

可见是（2）通过索引idx_b 锁住了记录，且在等待PRIMARY记录的锁。而（1）则在等待该锁的释放。  
而原因很可能是二级索引和主键的枷锁顺序并不相同导致的？？毕竟二级索引是要找到主键id然后（额）   

执行explain结果

| id  | select_type | table | type        | possible_keys | key         | key_len | ref | rows | Extra                                     |
| --- | ----------- | ----- | ----------- | ------------- | ----------- | ------- | --- | ---- | ----------------------------------------- |
| 1   | SIMPLE      | tag   | index_merge | idx_b,idx_a   | idx_a,idx_b | 4,4     | 1   | 10   | Using intersect(idx_a,idx_b); Using where |


## 解决方法
1. 建立联合索引，避免使用索引合并 INDEX(b,a)
2. 可以视业务情况关掉优化器的index merge优化  
关闭方法  
```sql
SET [GLOBAL|SESSION] optimizer_switch="index_merge_intersection=off";
```
1. 这是个bug，升级版本？好像并未修复

## 参考链接
[MySQL Bug 77209](https://bugs.mysql.com/bug.php?id=77209)
