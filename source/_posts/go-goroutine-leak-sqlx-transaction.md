---
title: go通过sqlx使用事务导致的goroutine泄露问题记录
date: 2020-11-25 01:19:34
tags: go
categories: go
---
问题的起因是收到预警，某个服务的请求持续出现504，而服务本身的记录没有504记录，触发的是负载均衡超时  
最终通过pprof定位到了问题并解决  
<!-- more -->
go版本为14  
通过pprof查看，好家伙，goroutine数4W+，如下  

```
goroutine profile: total 40269
30633 @ 0x432aa0 0x44224b 0x9ca93c 0x9cd106 0x9cce51 0x9e349e 0x9e3432 0x9e5d5d 0xa17457 0xa17365 0xa32339 0xaa6c26 0xa9f333 0xa81bea 0xa9bae4 0xa9c42e 0xa7a2e2 0x740254 0x73bbf5 0x45fd51
#	0x9ca93b	database/sql.(*DB).conn+0x7ab									/usr/local/go/src/database/sql/sql.go:1183
#	0x9cd105	database/sql.(*DB).query+0x65									/usr/local/go/src/database/sql/sql.go:1565
#	0x9cce50	database/sql.(*DB).QueryContext+0xd0								/usr/local/go/src/database/sql/sql.go:1547
#	0x9e349d	database/sql.(*DB).Query+0x8d									/usr/local/go/src/database/sql/sql.go:1561
#	0x9e3431	github.com/jmoiron/sqlx.(*DB).QueryRowx+0x21							/go/pkg/mod/github.com/jmoiron/sqlx@v1.2.1-0.20190826204134-d7d95172beb5/sqlx.go:363
#	0x9e5d5c	github.com/jmoiron/sqlx.Get+0x6c								/go/pkg/mod/github.com/jmoiron/sqlx@v1.2.1-0.20190826204134-d7d95172beb5/sqlx.go:685
#	0xa17456	github.com/jmoiron/sqlx.(*DB).Get+0x246								/go/pkg/mod/github.com/jmoiron/sqlx@v1.2.1-0.20190826204134-d7d95172beb5/sqlx.go:328
...业务代码
#	0xa81be9	github.com/labstack/echo.(*Echo).Add.func1+0x89							/go/pkg/mod/github.com/labstack/echo@v3.3.10+incompatible/echo.go:490
#	0xa9bae3	github.com/labstack/echo/middleware.LoggerWithConfig.func2.1+0x123				/go/pkg/mod/github.com/labstack/echo@v3.3.10+incompatible/middleware/logger.go:118
#	0xa9c42d	github.com/labstack/echo/middleware.RecoverWithConfig.func1.1+0x10d				/go/pkg/mod/github.com/labstack/echo@v3.3.10+incompatible/middleware/recover.go:78
#	0xa7a2e1	github.com/labstack/echo.(*Echo).ServeHTTP+0x221						/go/pkg/mod/github.com/labstack/echo@v3.3.10+incompatible/echo.go:593
#	0x740253	net/http.serverHandler.ServeHTTP+0xa3								/usr/local/go/src/net/http/server.go:2802
#	0x73bbf4	net/http.(*conn).serve+0x874									/usr/local/go/src/net/http/server.go:1890
```
pod的内存占用也从200M持续飙升到2G，且持续增加  
其它的协程也都是阻塞在了 /usr/local/go/src/database/sql/sql.go:1183，代码简化如下  
```golang
		select {
		case <-ctx.Done():
            ....
			return nil, ctx.Err()
		case ret, ok := <-req:
            ....
			return ret.conn, ret.err
		}
```
## 原因
1. 次要，事务未设置超时，直接调用 `Beginx()`，未通过上下文设置超时时间
2. 次要，http请求未设置超时时间
3. 次要，连接池设置为
```golang
	db.SetMaxOpenConns(16)
	db.SetMaxIdleConns(8)
```
4. 主要，伪代码如下
```golang
	tx, err := db.Beginx()
	if err != nil {
		return ErrSQLUpdate
	}

    err = callOtherFunc1()
    ...
    err = callOtherFunc2()

	if err != nil {
		tx.Rollback()
		return err
    }
    
    return tx.Commit()
```
其中 callOtherFunc1 和 callOtherFunc2 方法中，通过`db.Exec` 执行了两条语句  
此用法是错误的，应该使用 `tx.Exec`  
原因是开启事务后，tx将绑定并控制一个connection，直到commit或rollback后release  
所以如果不能正确释放连接，将导致连接泄露，资源无法回收  
而导致此次问题的真正原因是`db.Beginx`开启了一个事务，即独控了一个connection，然后向下执行时，其它的语句又重新获取connection，导致一次执行最多同时获取两个connection  
一般状态下不会有什么问题，也就是之前运行几个月没有问题的原因。但当此方法并发执行时，如极端下 16 个同时进行，此时16个事务开启，控制着16个连接，达到了 MaxOpenConns 限制  
下面的方法再执行需要获取新的连接，而连接池的限制将要等待连接释放才能获取连接，此时逻辑死锁已经生成，其它的任何数据库请求都将处于排队状态  

之所以服务没有超时记录，是因为所有的请求都处于等待状态
## 解决方法
1. 给http请求设置超时时间，此为最后的保命手段，其它所有服务都应有合理设置
2. 事务的初始化也要设置超时时间，所有使用事务的方法都应该确保设置有合理的超时时间
3. 事务执行应该独立一个连接池，不与其它查询共用
4. 要好好看**文档**，事务开启后要使用`*Tx`完成所有操作，文档中有明确的说明，当前的用法是无法实现事务控制预期的

## 参考链接
[sqlx使用文档](https://jmoiron.github.io/sqlx/#transactions)