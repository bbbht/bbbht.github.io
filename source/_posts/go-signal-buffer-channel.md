---
title: golang使用有缓冲的channel来接收signal
date: 2021-05-23 18:24:20
tags: go
categories: go
---
go代码中为了实现优雅关机，一般会通过监听系统信号的方式  
但简单的信号监听使用不当也会出问题，使得优雅关机失败
<!-- more -->
以下是有问题的代码示例
```go
	signals := make(chan os.Signal)
	signal.Notify(signals, syscall.SIGINT, syscall.SIGTERM)

	for {
		select {
		case sig := <-signals:
			fmt.Println(sig.String())
		default:
			fmt.Println("default", time.Now())
		}
		time.Sleep(time.Second)
	}
```
实际代码中并没有for，而是在一些关键位置通过select来判断  
但本地运行此代码，即便多次按下CTRL+C，也无法打印出信号，而是一直打印default  

按照正常逻辑，一个无缓冲channel只有在同时有接收者和发送者时才会传递成功，否则将会阻塞  
即没有接收方，发送方阻塞；没有发送方发送消息，接收方将阻塞  
上面的错误示例代码逻辑也很简单，通过利用select-case的能力，如果能接受成功，则说明有退出信号了，否则就执行正常逻辑，那么问题出在哪儿了呢？

## 原因
原因也很简单，没有了解信号接收的实现，从而使用无缓冲channel造成问题   
主要原因在源码``$GOPATH/src/os/signal/signal.go:232``中（当前版本为 1.16.2）：
```go
func process(sig os.Signal) {
	n := signum(sig)
	if n < 0 {
		return
	}

	handlers.Lock()
	defer handlers.Unlock()

	for c, h := range handlers.m {
		if h.want(n) {
			// send but do not block for it
			select {
			case c <- sig:
			default:
			}
		}
	}

	// Avoid the race mentioned in Stop.
	for _, d := range handlers.stopping {
		if d.h.want(n) {
			select {
			case d.c <- sig:
			default:
			}
		}
	}
}
```
重点在 **send but do not block for it**，同样是select-case结构，如果channel无接收方，则丢弃信号  
所以多次按下`CTRL+C`时，由于极小概率刚好是select执行判断时发送，故发送方与接收方都执行了default分支的逻辑，从而造成代码执行结果不符合预期  
## 解决方法
### 1. 使用有缓冲的channel
代码如下：
```go
	signals := make(chan os.Signal, 1)
	signal.Notify(signals, syscall.SIGINT, syscall.SIGTERM)

	for {
		select {
		case sig := <-signals:
			fmt.Println(sig.String())
			return
		default:
			fmt.Println("default", time.Now())
		}
		time.Sleep(time.Second)
	}
```
由于channel有buffer，故`process`能够发送成功，从而case也能够接收到这个信号
### 2. 使用阻塞性的channel接收信号
```go
	signals := make(chan os.Signal)
	signal.Notify(signals, syscall.SIGINT, syscall.SIGTERM)

	ctx, cancel := context.WithCancel(context.TODO())
	go func() {
		<-signals
		cancel()
	}()

	// for {
	// 	select {
	// 	case <-ctx.Done():
	// 		fmt.Println(ctx.Err())
	// 		return
	// 	default:
	// 		fmt.Println("default", time.Now())
	// 	}
	// 	time.Sleep(time.Second)
	// }
	for  {
		if ctx.Err() != nil {
			fmt.Println(ctx.Err())
			return
		}
		time.Sleep(time.Second)
	}
```
通过协程中同步阻塞的方式接收信号，接收方在线，不收buffer影响，从而保证消息不丢失  
然后通过context来控制退出，同时还更符合go的风格  

“优雅”