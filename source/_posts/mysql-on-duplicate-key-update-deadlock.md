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
2. 如果不存在，则忽略duplicate后的update语句，返回
3. 如果存在，对该记录加上S锁（共享锁）
4. 继续执行duplicate后的update语句，对该记录加上X锁（排他锁）
5. 进行update写入


所以问题发生的场景为：
1. S锁和X锁互斥，造成两个事务中都获取到了S锁，但都要等待S锁释放后获取X锁，死锁
2. t1、t2两个同时执行
3. 表中已存在重复键值的记录，导致会话先后尝试INSERT失败
4. 会话t1尝试获取记录的S锁(步骤3)，该记录未被其他会话加锁，获取S锁成功。
5. 会话t2尝试获取记录的S锁(步骤3)，该记录上被加持S锁，但由于S锁与S锁兼容，获取S锁成功
6. 会话t1尝试获取记录的X锁(步骤4)，由于会话t2也持有该记录的S锁，S锁与X锁不兼容，获取X锁失败，会话t1被阻塞
7. 会话t2尝试获取记录的X锁(步骤4)，由于会话t1对该记录持有S锁，S锁与X锁不兼容，获取X锁失败，会话t2被阻塞
8. 会话t2被阻塞后进入死锁检查环节，发现阻塞t1->t2和t2->t1形成死锁环路，触发死锁机制强制回滚t1或t2事务


## 解决方法
1. 调整事务级别？这个好像不太合适
2. 生产环境还是要尽量避免使用INSERT INTO ON DUPLICATE UPDATE语句
3. 对Insert语句错误进行校验，重复记录时触发执行update
4. 分拆语句，先查，再插入或更新，而且on duplicate key 还会造成自增主键的疯狂增长

## 参考链接
[MySQL bug 58637](https://bugs.mysql.com/bug.php?id=58637)