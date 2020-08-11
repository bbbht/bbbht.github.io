---
title: golang程序profileruntime.futex占用大量 cpu 资源
date: 2020-08-05 18:05:43
tags: go
categories: go
---
线上数据库CPU100%，纯粹的查询量过大导致，放下不表  
但排查过程中，业务系统（Go）运行还正常，于是看了一下pprof的profile和heap、block等数据  
在profile中发现了异常，`runtime.futex`占比高达50%，相当异常了  
<!-- more -->
> futex 即 “Fast user space mutex” 快速用户空间互斥


![火焰图](/images/Snipaste_2020-08-06_14-20-05.png)
## 原因 

### pprof profile top 部分数据
| Flat  | Flat%  | Sum%   | Cum   | Cum%   | Name                              | Inlined? |
| ----- | ------ | ------ | ----- | ------ | --------------------------------- | -------- |
| 7.82s | 50.58% | 50.58% | 7.82s | 50.58% | runtime.futex                     |          |
| 0.05s | 0.32%  | 50.91% | 4.15s | 26.84% | runtime.futexsleep                |          |
| 0     | 0.00%  | 50.91% | 4.03s | 26.07% | runtime.timerproc                 |          |
| 0.01s | 0.06%  | 50.97% | 3.73s | 24.13% | runtime.futexwakeup               |          |
| 0     | 0.00%  | 50.97% | 3.72s | 24.06% | runtime.notewakeup                |          |
| 0     | 0.00%  | 50.97% | 3.39s | 21.93% | runtime.notetsleepg               |          |
| 0     | 0.00%  | 50.97% | 2.32s | 15.01% | runtime.systemstack               |          |
| 0     | 0.00%  | 50.97% | 2.21s | 14.29% | runtime.startm                    |          |
| 0     | 0.00%  | 50.97% | 2.20s | 14.23% | runtime.mcall                     |          |
| 0     | 0.00%  | 50.97% | 2.19s | 14.17% | runtime.schedule                  |          |
| 0     | 0.00%  | 50.97% | 2.14s | 13.84% | runtime.notesleep                 |          |
| 0     | 0.00%  | 50.97% | 2.12s | 13.71% | runtime.findrunnable              |          |
| 0     | 0.00%  | 50.97% | 2.12s | 13.71% | runtime.park_m                    |          |
| 0     | 0.00%  | 50.97% | 2.11s | 13.65% | runtime.stopm                     |          |
| 0     | 0.00%  | 50.97% | 2.01s | 13.00% | runtime.notetsleep_internal       |          |
| 0     | 0.00%  | 50.97% | 1.47s | 9.51%  | runtime.entersyscallblock         |          |
| 0     | 0.00%  | 50.97% | 1.47s | 9.51%  | runtime.entersyscallblock_handoff |          | 
| 0     | 0.00%  | 50.97% | 1.47s | 9.51%  | runtime.handoffp                  |          |
| 0     | 0.00%  | 50.97% | 1.35s | 8.73%  | 业务代码打码.KafkaConsumerHandler |          |
| 0     | 0.00%  | 50.97% | 1.35s | 8.73%  | main.messageRun                   |          |
| 0     | 0.00%  | 50.97% | 1.35s | 8.73%  | runtime.addtimerLocked            |          |
| 0     | 0.00%  | 50.97% | 1.35s | 8.73%  | time.Sleep                        |          |
| 0     | 0.00%  | 50.97% | 0.72s | 4.66%  | runtime.wakep                     |          |
| 0     | 0.00%  | 50.97% | 0.66s | 4.27%  | runtime.goready                   |          |
| 0     | 0.00%  | 50.97% | 0.66s | 4.27%  | runtime.goready.func1             |          |
| 0     | 0.00%  | 50.97% | 0.66s | 4.27%  | runtime.ready                     |          |

从上述数据看出，大部分实际消耗在了`runtime.futex`上，但直接查询它是很难找到是什么调用的，因为在火焰图上是找不到它的调用者的  
从网上搜索，找到了知乎上的一篇相关文章，见参考链接。  
虽然没有直接解决我的问题，但至少验证了一些问题，即从火焰图上看到几个点  
    - `runtime.timerproc`（time）
    - `time.Sleep`（time）
    - `runtime.mcall > runtime.park_m`（goroutine）

所以根据业务代码倒推，很快定位到了问题代码，简化如下  
精准还原代码，槽点轻喷u😹   
加入了http pprof来方便展示  

```golang
package main

import (
	"log"
	"net/http"
	_ "net/http/pprof"
	"os"
	"os/signal"
	"runtime"
	"syscall"
	"time"
)

var count = 5

func main() {
	go func() {
		log.Println(http.ListenAndServe(":88", nil))
	}()

	tc := time.NewTicker(time.Millisecond * 10)

	sigchan := make(chan os.Signal, 1)
	signal.Notify(sigchan, syscall.SIGINT, syscall.SIGTERM)

	for {
		select {
		case sig := <-sigchan:
			log.Printf("Caught signal %v: terminating\n", sig)
            return
        // 实际情况是default，然后内部逻辑拉取kafka消息消费，为简化代码用定时器模拟了
		case <-tc.C:
			for true {
				if runtime.NumGoroutine() > count {
					time.Sleep(time.Microsecond * 5)
				} else {
					break
				}
			}

			go func() {
				time.Sleep(100 * time.Millisecond)
			}()
		}
	}
}
```

### 还原现象
以上代码本地运行后，并未出现futex占用cpu时间的问题，一度怀疑人生遍寻其它可能  
排除所有其他可能后，最终是差异在go版本，线上是1.9，而本地是1.14，而现在1.15已有预览版本发布。。。  
但两者的pprof参数基本一致  
```
/debug/pprof/

Types of profiles available:
Count	Profile
0	allocs
0	block
0	cmdline
7	goroutine
0	heap
0	mutex
0	profile
9	threadcreate
0	trace
```

#### go 1.14.1
cpu消耗1%以内

![火焰图](/images/Snipaste_2020-08-06_15-26-13.png)

| Flat  | Flat%  | Sum%    | Cum   | Cum%   | Name                                       | Inlined? |
|-------|--------|---------|-------|--------|--------------------------------------------|----------|
| 0.01s | 0.68%  | 0.68%   | 1.26s | 86.30% | runtime.mcall                              |          |
| 0.02s | 1.37%  | 2.05%   | 1.25s | 85.62% | runtime.park_m                             |          |
| 0.03s | 2.05%  | 4.11%   | 1.11s | 76.03% | runtime.schedule                           |          |
| 0.09s | 6.16%  | 10.27%  | 0.83s | 56.85% | runtime.findrunnable                       |          |
| 0     | 0.00%  | 10.27%  | 0.30s | 20.55% | runtime.netpollBreak                       |          |
| 0.30s | 20.55% | 30.82%  | 0.30s | 20.55% | runtime.stdcall4                           |          |
| 0.02s | 1.37%  | 32.19%  | 0.25s | 17.12% | runtime.resetspinning                      |          |
| 0     | 0.00%  | 32.19%  | 0.23s | 15.75% | runtime.startm                             |          |
| 0     | 0.00%  | 32.19%  | 0.23s | 15.75% | runtime.wakep                              | (inline) |
| 0.01s | 0.68%  | 32.88%  | 0.23s | 15.75% | runtime.notewakeup                         |          |
| 0     | 0.00%  | 32.88%  | 0.22s | 15.07% | runtime.semawakeup                         |          |
| 0.22s | 15.07% | 47.95%  | 0.22s | 15.07% | runtime.stdcall1                           |          |
| 0.01s | 0.68%  | 48.63%  | 0.16s | 10.96% | runtime.netpoll                            |          |
| 0.15s | 10.27% | 58.90%  | 0.15s | 10.27% | runtime.stdcall6                           |          |
| 0     | 0.00%  | 58.90%  | 0.14s | 9.59%  | main.main                                  |          |
| 0     | 0.00%  | 58.90%  | 0.14s | 9.59%  | runtime.main                               |          |
| 0     | 0.00%  | 58.90%  | 0.12s | 8.22%  | runtime.resetForSleep                      |          |
| 0     | 0.00%  | 58.90%  | 0.12s | 8.22%  | runtime.resettimer                         | (inline) |
| 0.03s | 2.05%  | 60.96%  | 0.12s | 8.22%  | runtime.modtimer                           |          |
| 0.01s | 0.68%  | 61.64%  | 0.09s | 6.16%  | runtime.addInitializedTimer                |          |
| 0.02s | 1.37%  | 63.01%  | 0.09s | 6.16%  | time.Sleep                                 |          |

#### go 1.13.4
cpu消耗在15%
| Flat | Flat%  | Sum%    | Cum  | Cum%   | Name                                   | Inlined? |
|------|--------|---------|------|--------|----------------------------------------|----------|
| 90ms | 64.29% | 64.29%  | 90ms | 64.29% | runtime.futex                          |          |
| 20ms | 14.29% | 78.57%  | 20ms | 14.29% | runtime.usleep                         |          |
| 10ms | 7.14%  | 85.71%  | 40ms | 28.57% | runtime.notetsleep_internal            |          |
| 10ms | 7.14%  | 92.86%  | 10ms | 7.14%  | runtime.goready                        |          |
| 10ms | 7.14%  | 100.00% | 10ms | 7.14%  | runtime.casgstatus                     |          |
| 0    | 0.00%  | 100.00% | 10ms | 7.14%  | time.Sleep                             |          |
| 0    | 0.00%  | 100.00% | 60ms | 42.86% | runtime.timerproc                      |          |
| 0    | 0.00%  | 100.00% | 20ms | 14.29% | runtime.systemstack                    |          |
| 0    | 0.00%  | 100.00% | 30ms | 21.43% | runtime.sysmon                         |          |
| 0    | 0.00%  | 100.00% | 30ms | 21.43% | runtime.stopm                          |          |
| 0    | 0.00%  | 100.00% | 20ms | 14.29% | runtime.startm                         |          |
| 0    | 0.00%  | 100.00% | 30ms | 21.43% | runtime.schedule                       |          |
| 0    | 0.00%  | 100.00% | 30ms | 21.43% | runtime.park_m                         |          |
| 0    | 0.00%  | 100.00% | 30ms | 21.43% | runtime.notewakeup                     |          |
| 0    | 0.00%  | 100.00% | 50ms | 35.71% | runtime.notetsleepg                    |          |
| 0    | 0.00%  | 100.00% | 10ms | 7.14%  | runtime.notetsleep                     |          |
| 0    | 0.00%  | 100.00% | 30ms | 21.43% | runtime.notesleep                      |          |
| 0    | 0.00%  | 100.00% | 30ms | 21.43% | runtime.mstart1                        |          |
| 0    | 0.00%  | 100.00% | 30ms | 21.43% | runtime.mstart                         |          |
| 0    | 0.00%  | 100.00% | 30ms | 21.43% | runtime.mcall                          |          |
| 0    | 0.00%  | 100.00% | 10ms | 7.14%  | runtime.main                           |          |
| 0    | 0.00%  | 100.00% | 20ms | 14.29% | runtime.handoffp                       |          |
| 0    | 0.00%  | 100.00% | 10ms | 7.14%  | runtime.goroutineReady                 |          |
| 0    | 0.00%  | 100.00% | 30ms | 21.43% | runtime.futexwakeup                    |          |
| 0    | 0.00%  | 100.00% | 60ms | 42.86% | runtime.futexsleep                     |          |
| 0    | 0.00%  | 100.00% | 30ms | 21.43% | runtime.findrunnable                   |          |
| 0    | 0.00%  | 100.00% | 10ms | 7.14%  | runtime.exitsyscall                    |          |
| 0    | 0.00%  | 100.00% | 20ms | 14.29% | runtime.entersyscallblock_handoff      |          |
| 0    | 0.00%  | 100.00% | 20ms | 14.29% | runtime.entersyscallblock              |          |
| 0    | 0.00%  | 100.00% | 10ms | 7.14%  | runtime.(*timersBucket).addtimerLocked |          |
| 0    | 0.00%  | 100.00% | 10ms | 7.14%  | main.main                              |          |


#### go 1.9.1
cpu消耗在15%

![火焰图](/images/Snipaste_2020-08-06_15-34-56.png)

| Flat | Flat%  | Sum%    | Cum  | Cum%   | Name                              | Inlined? |
|------|--------|---------|------|--------|-----------------------------------|----------|
| 50ms | 62.50% | 62.50%  | 50ms | 62.50% | runtime.futex                     |          |
| 20ms | 25.00% | 87.50%  | 20ms | 25.00% | runtime.usleep                    |          |
| 10ms | 12.50% | 100.00% | 10ms | 12.50% | runtime._ExternalCode             |          |
| 0    | 0.00%  | 100.00% | 40ms | 50.00% | runtime.timerproc                 |          |
| 0    | 0.00%  | 100.00% | 20ms | 25.00% | runtime.systemstack               |          |
| 0    | 0.00%  | 100.00% | 20ms | 25.00% | runtime.sysmon                    |          |
| 0    | 0.00%  | 100.00% | 10ms | 12.50% | runtime.stopm                     |          |
| 0    | 0.00%  | 100.00% | 20ms | 25.00% | runtime.startm                    |          |
| 0    | 0.00%  | 100.00% | 10ms | 12.50% | runtime.schedule                  |          |
| 0    | 0.00%  | 100.00% | 10ms | 12.50% | runtime.park_m                    |          |
| 0    | 0.00%  | 100.00% | 20ms | 25.00% | runtime.notewakeup                |          |
| 0    | 0.00%  | 100.00% | 40ms | 50.00% | runtime.notetsleepg               |          |
| 0    | 0.00%  | 100.00% | 20ms | 25.00% | runtime.notetsleep_internal       |          |
| 0    | 0.00%  | 100.00% | 10ms | 12.50% | runtime.notesleep                 |          |
| 0    | 0.00%  | 100.00% | 20ms | 25.00% | runtime.mstart1                   |          |
| 0    | 0.00%  | 100.00% | 20ms | 25.00% | runtime.mstart                    |          |
| 0    | 0.00%  | 100.00% | 10ms | 12.50% | runtime.mcall                     |          |
| 0    | 0.00%  | 100.00% | 20ms | 25.00% | runtime.handoffp                  |          |
| 0    | 0.00%  | 100.00% | 20ms | 25.00% | runtime.futexwakeup               |          |
| 0    | 0.00%  | 100.00% | 30ms | 37.50% | runtime.futexsleep                |          |
| 0    | 0.00%  | 100.00% | 10ms | 12.50% | runtime.findrunnable              |          |
| 0    | 0.00%  | 100.00% | 20ms | 25.00% | runtime.entersyscallblock_handoff |          |
| 0    | 0.00%  | 100.00% | 20ms | 25.00% | runtime.entersyscallblock         |          |
| 0    | 0.00%  | 100.00% | 10ms | 12.50% | runtime._System                   |          |

#### 分析
基本是一目了然了，go1.14版本对此的优化是很明显的  
是 `低版本 + 低效代码` 导致了问题

## 解决方法
现在来看一下解决方案，只在1.9版本验证  

1. `time.Sleep(time.Microsecond * 5)`
   1. sleep间隔过小
2. 从简略代码上也能看出，本意是想持续的消费kafka消息，且参考了confluent-kafka-go的示例代码，但策略不好
      1. 使用了`runtime.NumGoroutine()`控制任务协程数量，把系统想象的太单一
      2. 依赖sleep进行阻塞

所以，要合理调整定时器间隔，小间隔考虑其他方案如时间轮等统一处理代替  
针对协程数量控制及阻塞操作，有更多好的方案可用，如channel、select、sync、、协程池等等  
而引发`runtime.futex`高占比的原因也就是空间竞争，无论协程还是线程，操作对象总是存在竞争，竞争就会有锁，就有消耗  
针对锁竞争，也有各种方案，原则就是小  
另外，语言工具的升级迭代也要关注，吭哧吭哧的去优化，有时候不如升级带来的提升明显

## 参考链接
[谁占了该CPU核的30% - 一个较意外的Go性能问题](https://zhuanlan.zhihu.com/p/45959147)
[confluent-kafka-go examples](https://github.com/confluentinc/confluent-kafka-go/blob/master/examples/consumer_example/consumer_example.go)