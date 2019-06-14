---
title: mysql on duplicate key update deadlock
date: 2019-06-14 09:33:45
tags: mysql
categories: mysql
---
前天解决了mysql的索引合并(using intersect)造成的死锁后，变刘鑫观察死锁信息  
于是又发现一个造成死锁的常规语句
```sql
insert into xxx(x,y,z) values(a,b,c) on duplicate key update z = c;
```
<!-- more -->
话说业务中死锁之前都没有引起重视的。。

## 原因
首先，5.6版本好像并没有这个问题，现在使用的是5.7版本，至于后续版本并未测试  
其次，发生死锁的原因  
执行insert into ... on duplicate key语句顺序  
1. innodb引擎会先判断插入的行是否产生重复key错误
2. 如果存在，对该记录加上S锁（共享锁）
3. 返回记录
4. 继续执行duplicate后的update语句，对该记录加上X锁（排他锁）
5. 进行update写入
所以问题应该在于S锁和X锁互斥，造成两个事务中都获取到了S锁，但要等待随访释放后获取X锁，死锁

## 解决方法
1. 调整事务级别？这个好像不太合适
2. 分拆语句，先查，再插入或更新，而且on duplicate key 还会造成自增主键的疯狂增长

## 参考链接
[MySQL bug 58637](https://bugs.mysql.com/bug.php?id=58637)