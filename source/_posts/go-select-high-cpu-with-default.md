---
title: go使用for select时CPU占用高的问题的简单解决
date: 2021-04-08 11:42:58
tags: go
categories: go
---
某个服务时不时报警cpu飙升，通过pprof工具查看是`sync.(*Mutex).Unlock/sync.(*Mutex).Lock`占用cpu  
那就很明显是锁竞争导致的问题了
<!-- more -->
其中Go版本为 `1.13.4`  
pprof的数据（top）简略如下：  
```
----------------------------------------------------------+-------------
      flat  flat%   sum%        cum   cum%   calls calls% + context 	 	 
----------------------------------------------------------+-------------
                                            21.53s   100% |   context.(*cancelCtx).Done \usr\local\go\src\context\context.go:330
    21.53s 36.82% 36.82%     21.53s 36.82%                | sync.(*Mutex).Unlock \usr\local\go\src\sync\mutex.go:186
----------------------------------------------------------+-------------
                                            16.51s   100% |   context.(*cancelCtx).Done \usr\local\go\src\context\context.go:325
    16.51s 28.23% 65.05%     16.51s 28.23%                | sync.(*Mutex).Lock \usr\local\go\src\sync\mutex.go:74
----------------------------------------------------------+-------------
                                            57.34s   100% |   xxx.go:916
                    3.54s  6.05% 71.10%     57.34s 98.05% |   xxx.go:567
                                            21.55s 37.58% |   context.(*cancelCtx).Done \usr\local\go\src\context\context.go:330
                                            18.38s 32.05% |   context.(*cancelCtx).Done \usr\local\go\src\context\context.go:325
                                             7.88s 13.74% |   runtime.selectnbrecv \usr\local\go\src\runtime\chan.go:636
                                             2.30s  4.01% |   runtime.selectnbrecv \usr\local\go\src\runtime\chan.go:635
                                             0.99s  1.73% |   context.(*cancelCtx).Done \usr\local\go\src\context\context.go:331
                                             0.93s  1.62% |   context.(*cancelCtx).Done \usr\local\go\src\context\context.go:329
                                             0.92s  1.60% |   runtime.selectnbrecv \usr\local\go\src\runtime\chan.go:637
                                             0.84s  1.46% |   context.(*cancelCtx).Done \usr\local\go\src\context\context.go:324
                                             0.01s 0.017% |   context.(*cancelCtx).Done \usr\local\go\src\context\context.go:326
```

## 原因
对应版本查看 [源码](https://github.com/golang/go/blob/go1.13.4/src/context/context.go#L324)   
```go
func (c *cancelCtx) Done() <-chan struct{} {
	c.mu.Lock()
	if c.done == nil {
		c.done = make(chan struct{})
	}
	d := c.done
	c.mu.Unlock()
	return d
}
```
对应pprof top所显示的Lock与Unlock代码位置  
业务代码简化为：  
```go
for {
		select {
		case <-dt.ctx.Done():
            // do something 
		default:
			if dt.isPause() {
				continue
			}

            // do something 
		}
	}
```
查看源码后问题就很清晰了，Done的频繁执行导致了锁的竞争，引发CPU飙升  
而具体原因则是default分支并非阻塞操作，如果dt.isPause() 判断为true，则直接进入下一个循环，执行Done  
而isPause方法实现也是简单的比较操作结果（资源是否足够，不足则暂停处理，所以资源吃紧时才会发生），整个 for select 相当于死循环高频执行，从而占满所有的CPU  

## 解决方法
问题其实很简单，当case的条件不满足时，循环将会走default，然后执行下一个循环，这就造成了死循环，写代码时就应当考虑每个分支的执行情况，以避免此类问题。  

1. 去掉default，改为其它channel的 case 分支，正确使用 for-select
2. isPause 为 true 时，sleep一个较短时间，如10ms，降低循环执行的频率

当然，sleep比较low，但最终选择了它，因为简单，够用  

## 参考链接
[基于select的多路复用· Go语言圣经](https://hypc-pub.github.io/gopl-zh/ch8/ch8-07.html)