---
title: etcd实现分布式锁的基础原理
date: 2021-01-20 09:57:56
tags: etcd
categories: etcd
---
最近在优化架构，其中有一部分系统依赖 etcd，业务上体现为任务调度和分布式锁  
先不说用etcd做任务调度是否能力匹配（用出来一地坑）  
之前未关注过etcd本身分布式锁的实现，还是很有意思的，借此机会简单整理下  

<!-- more -->

并非要事无巨细的翻源码来看其具体的实现逻辑，而是简单的记录下当前（V3版本）实现的原理。  
因为其具体实现使用了大量的etcd的基础功能，所以空中楼阁并不能起什么作用，需要详细了解还需要大量篇幅介绍相关内容  
业务中使用的时候

## 依赖
### Revision
revision是MVCC（Multi-version Cocurrent Control）中的概念，是etcd中cluster级别的计数器，每次修改操作都会让其自增，可以认为是全局逻辑时钟(global logical clock)  
即每次的delete、put等修改性操作，都会让其自增  
每个key都会与其相关，体现在`create_revision`(创建key时的reversion)，`mod_revision`（最后修改时的reversion）  
通过比较 Revision 的大小就可以知道进行写操作的顺序
### Watch
即监听机制  
支持 Watch 某个固定的 key，也支持 Watch 一个目录（Prefix机制）  
当被 Watch 的 key 或 目录 发生变化，客户端将收到通知
### Lease
etcd的租约机制（TTL，Time To Live）  
可以为 key 设置租约，当租约到期时，key 将被删除  
当然，还可以续约，即在租约到期之前延长租约  
此机制的引入可以保证分布式锁的安全性，即便锁未被正确释放，也会受租约的限制而释放  
当一个客户端持有锁期间，其它客户端只能等待，为了避免等待期间租约失效， 客户端需创建一个定时任务作为“心跳”进行续约
### Prefix
即前缀或目录机制  
如 `/a/b` 是 `/a/b/c`,`/a/b/def` 的前缀，建议使用分隔符 `/`   
而在分布式锁的使用中，每个竞争锁的会话都会写入一个具有相同 `Prefix` 但又保证唯一的key，如 `/etcd/lockkey-a/leaseId-1`，`/etcd/lockkey-a/leaseId-2`  


## 流程
1. 各客户端准备
   1. 建立连接，包含租约，其中NewSession时会启动keeplive协程，不断续约
   2. 创建唯一key，规则为使用 leaseId 进行key拼接
2. 执行Lock操作
   1. 各客户端 put 各自的唯一 key
   2. 各自获得响应的 Reversion
   3. 传参的context可控制时间，防止无限等待
3. 各客户端判断是否获得锁
   1. 根据前缀获取 key 列表，如果自己获得的 Reversion 是列表中最小的，则认定自己获得了锁
4. 执行后续逻辑
   1. 获得锁的执行业务
   2. 未获得锁的客户端等待获得锁后执行业务
      1. 根据自己的[Reversion-1]作为 MaxCreateReversion，监听（Watch）比自己小且最近的key的删除事件，一旦监听到则判定自己获得了锁，再执行后续逻辑
5. 释放锁
   1. Delete

## 代码
源码中key的拼接规则，将用户的lockkey作为目录前缀，并以leaseid作为唯一性保证
```go
package concurrency

import (
	"context"
	"fmt"
	"sync"

	v3 "go.etcd.io/etcd/clientv3"
	pb "go.etcd.io/etcd/etcdserver/etcdserverpb"
)

// Mutex implements the sync Locker interface with etcd
type Mutex struct {
	s *Session

	pfx   string
	myKey string
	myRev int64
	hdr   *pb.ResponseHeader
}

func NewMutex(s *Session, pfx string) *Mutex {
    // 将用户自定义的lockkey，定位为目录前缀
	return &Mutex{s, pfx + "/", "", -1, nil}
}

// Lock locks the mutex with a cancelable context. If the context is canceled
// while trying to acquire the lock, the mutex tries to clean its stale lock entry.
// Lock，即锁的竞争应该有事件限制，非必需无限等待的场景下应传入超时控制的上下文
func (m *Mutex) Lock(ctx context.Context) error {
	s := m.s
	client := m.s.Client()

    // 将 LeaseId 作为唯一性的保证，拼接出一个具有相同前缀又全局唯一的key
	m.myKey = fmt.Sprintf("%s%x", m.pfx, s.Lease())
	cmp := v3.Compare(v3.CreateRevision(m.myKey), "=", 0)
	// put self in lock waiters via myKey; oldest waiter holds lock
	put := v3.OpPut(m.myKey, "", v3.WithLease(s.Lease()))
	// reuse key in case this session already holds the lock
	get := v3.OpGet(m.myKey)
	// fetch current holder to complete uncontended path with only one RPC
	getOwner := v3.OpGet(m.pfx, v3.WithFirstCreate()...)
	resp, err := client.Txn(ctx).If(cmp).Then(put, getOwner).Else(get, getOwner).Commit()
	if err != nil {
		return err
	}
	m.myRev = resp.Header.Revision
	if !resp.Succeeded {
		m.myRev = resp.Responses[0].GetResponseRange().Kvs[0].CreateRevision
    }
    // 锁的判断逻辑
	// if no key on prefix / the minimum rev is key, already hold the lock
	ownerKey := resp.Responses[1].GetResponseRange().Kvs
	if len(ownerKey) == 0 || ownerKey[0].CreateRevision == m.myRev {
		m.hdr = resp.Header
		return nil
	}

	// wait for deletion revisions prior to myKey
	hdr, werr := waitDeletes(ctx, client, m.pfx, m.myRev-1)
	// release lock key if wait failed
	if werr != nil {
		m.Unlock(client.Ctx())
	} else {
		m.hdr = hdr
	}
	return werr
}

func (m *Mutex) Unlock(ctx context.Context) error {
	client := m.s.Client()
	if _, err := client.Delete(ctx, m.myKey); err != nil {
		return err
	}
	m.myKey = "\x00"
	m.myRev = -1
	return nil
}

func (m *Mutex) IsOwner() v3.Cmp {
	return v3.Compare(v3.CreateRevision(m.myKey), "=", m.myRev)
}

func (m *Mutex) Key() string { return m.myKey }

// Header is the response header received from etcd on acquiring the lock.
func (m *Mutex) Header() *pb.ResponseHeader { return m.hdr }

type lockerMutex struct{ *Mutex }

func (lm *lockerMutex) Lock() {
	client := lm.s.Client()
	if err := lm.Mutex.Lock(client.Ctx()); err != nil {
		panic(err)
	}
}
func (lm *lockerMutex) Unlock() {
	client := lm.s.Client()
	if err := lm.Mutex.Unlock(client.Ctx()); err != nil {
		panic(err)
	}
}

// NewLocker creates a sync.Locker backed by an etcd mutex.
func NewLocker(s *Session, pfx string) sync.Locker {
	return &lockerMutex{NewMutex(s, pfx)}
}

```
未获得锁的情况下，监听以获得锁的逻辑  
其中`WithMaxCreateRev`的作用就是过滤最大的创建reversion值（create_revision），以确保监听比自己小但又最接近的reversion时创建的key
```go
package concurrency

import (
	"context"
	"fmt"

	v3 "go.etcd.io/etcd/clientv3"
	pb "go.etcd.io/etcd/etcdserver/etcdserverpb"
	"go.etcd.io/etcd/mvcc/mvccpb"
)

func waitDelete(ctx context.Context, client *v3.Client, key string, rev int64) error {
	cctx, cancel := context.WithCancel(ctx)
	defer cancel()

	var wr v3.WatchResponse
	wch := client.Watch(cctx, key, v3.WithRev(rev))
	for wr = range wch {
		for _, ev := range wr.Events {
            // 监听到删除事件即意味着，此客户端获得了锁
			if ev.Type == mvccpb.DELETE {
				return nil
			}
		}
	}
	if err := wr.Err(); err != nil {
		return err
	}
	if err := ctx.Err(); err != nil {
		return err
	}
	return fmt.Errorf("lost watcher waiting for delete")
}

// waitDeletes efficiently waits until all keys matching the prefix and no greater
// than the create revision.
func waitDeletes(ctx context.Context, client *v3.Client, pfx string, maxCreateRev int64) (*pb.ResponseHeader, error) {
	getOpts := append(v3.WithLastCreate(), v3.WithMaxCreateRev(maxCreateRev))
	for {
		resp, err := client.Get(ctx, pfx, getOpts...)
		if err != nil {
			return nil, err
		}
		if len(resp.Kvs) == 0 {
			return resp.Header, nil
        }
        // 查询到了距离自己的Reversion最近的key，并监听其删除事件
		lastKey := string(resp.Kvs[0].Key)
		if err = waitDelete(ctx, client, lastKey, resp.Header.Revision); err != nil {
			return nil, err
		}
	}
}
```