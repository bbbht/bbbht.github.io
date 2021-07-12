---
title: 使用dumb-init来实现docker中运行多个进程并处理SIGTERM信号
date: 2021-07-09 10:17:18
tags: 
    - docker
categories: docker
---

最近重构一些老项目，为此实现了一个基于etcd的grpc服务注册、发现及负载均衡的中间件  
服务注册嘛，无论docker还是k8s部署，都需要服务在监听到系统信号 `SIGTERM` ，实现标准的`优雅停机`，摘除注册  
之前的服务启动命令是一个脚本，看似实现了，但没有完全实现
<!-- more -->
Linux中 ，pid 为 1 的进程，有着特殊的使命：
- 传递信号，确保子进程完全退出
- 等待子进程退出

容器化环境中，往往直接运行应用程序，而缺少初始化系统（如 systemd、sysvinit 等）。这可能需要应用程序来处理系统信号，接管子进程，进而导致容器无法停止、产生僵尸进程等问题。Yelp 开发的 dumb-init ，旨在模拟初始化系统功能，向子进程代理发送信号和接管子进程。  
```sh
#!/usr/bin/dumb-init /bin/sh
/init.sh
# 还有一大堆其它乱七八糟的，省略
a=$1
nohup fluentd&
/app/main ${a}
```
其中基础镜像是alpine，/init.sh 的脚本内容为 ``nohup crond -f & ``，目的是运行crontab  
fluentd是收集日志的，定时任务也是给它用的，定期清理日志文件。。  
真正的服务则是要依赖 `/app/main` 这个二进制运行，真实的进程情况  
```sh
/app # ps -eo pid,ppid,args
PID   PPID  COMMAND
    1     0 {start.sh} /usr/bin/dumb-init /bin/sh /bin/start.sh
    8     1 /bin/sh /bin/start.sh
   10     1 crond -f
   11     8 {fluentd} /usr/bin/ruby /usr/bin/fluentd
   12     8 /app/main
   27    11 /usr/bin/ruby -Eascii-8bit:ascii-8bit /usr/bin/fluentd --under-supervisor
   32     0 sh
   43    32 ps -eo pid,ppid,args
/app # pstree
start.sh-+-crond
         `-sh-+-fluentd---ruby
              `-main
```
可见，shebang中添加 `/usr/bin/dumb-init` 起作用了但没有完全起作用。脚本中的第一行脚本执行后，其ppid确实为1  
再之后运行的命令，则隶属于脚本之下的进程id了  
## 原因
进程树可以清晰的看到，main的ppid并非1，所以无法接收到`dumb-init`传递的信号，所以无法真正实现优雅停机  
dumb-init的原理就是其作为pid为1的进程，接收到的信号会向其子进程传递  
**但其有个配置环境变量 `DUMB_INIT_SETSID`，如果设为0则只向直接子进程发送信号，即子进程的ppid必须为1才能接收到传递的信号**  
问题则就是出现在这个配置上，基础镜像被添加了环境变量并且值为0  
## 验证
使用go写一些demo来模拟程序并监听信号退出，通过修改timeout来控制程序自动退出时间
```go
const timeout = 600
func main() {
	signals := make(chan os.Signal)
	signal.Notify(signals, syscall.SIGINT, syscall.SIGTERM)
	ticker := time.NewTicker(time.Second * 3)
	defer ticker.Stop()
	timer := time.NewTimer(time.Second * timeout)
	defer timer.Stop()

	for {
		select {
		case <-signals:
			fmt.Println(timeout, "signal")
			return
		case <-timer.C:
			fmt.Println(timeout, "timeout")
			return
		case <-ticker.C:
			fmt.Println(timeout, "ticker")
		}
	}
}
```
```sh
# 编译三个不同时间的二进制程序
go build -o app_30s
go build -o app_60s
go build -o app_600s
```

```dockerfile
FROM alpine:latest

RUN sed -i "s/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g" /etc/apk/repositories \
	&& apk update \
	&& apk add --no-cache dumb-init \
	&& rm -rf /var/cache/apk/*

COPY app* /app/
COPY *.sh /

# 控制dumb-init信号传递
ENV DUMB_INIT_SETSID=0

# dumb-init的另一种使用方式
ENTRYPOINT [ "/usr/bin/dumb-init", "--" ]

CMD [ "/start.sh" ]
```
启动脚本
`#!/usr/bin/dumb-init /bin/sh`
```sh
#! /bin/sh
/app/app_30s &
/app/app_600s &
/app/app_60s
```
### 结果
|      | 条件                                      | 进程树                                                       | log                                                          | 备注                                                         |
| ---- | ----------------------------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ | ------------------------------------------------------------ |
| 1    | 不使用dumb-init                           | / # pstree && ps -eo pid,ppid,args<br/> start.sh-+-app_30s---6*[{app_30s}]<br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\|-app_600s---6*[{app_600s}]<br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`-app_60s---6*[{app_60s}]<br/> PID   PPID  COMMAND<br/> 1&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;0 {start.sh} /bin/sh /start.sh<br/> 6&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1 /app/app_30s<br/> 7&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1 /app/app_600s<br/> 8&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1 /app/app_60s<br/> 27&nbsp;&nbsp;&nbsp;&nbsp;0 sh<br/> 33&nbsp;&nbsp;&nbsp;&nbsp;27 ps -eo pid,ppid,args<br/> | $ docker logs -f  dumb<br/>600 ticker<br/>60 ticker<br/>30 ticker<br/># 执行 docker stop dumb<br/>600 ticker<br/>30 ticker<br/>60 ticker<br/>... | 执行`docker stop dumb`后容器并没有停止<br />且log中也没有信号接收的输出，<br />直到docker默认的等待时间（10s）被强杀 |
| 2    | ENTRYPOINT + DUMB_INIT_SETSID=            | / # pstree && ps -eo pid,ppid,args<br/> dumb-init---start.sh-+-app_30s---6*[{app_30s}]<br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\|-app_600s---6*[{app_600s}]<br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`-app_60s---6*[{app_60s}]<br/> PID   PPID  COMMAND<br/> 1&nbsp;&nbsp;&nbsp;&nbsp;0 /usr/bin/dumb-init -- /start.sh<br/> 6&nbsp;&nbsp;&nbsp;&nbsp;1 {start.sh} /bin/sh /start.sh<br/> 7&nbsp;&nbsp;&nbsp;&nbsp;6 /app/app_30s<br/> 8&nbsp;&nbsp;&nbsp;&nbsp;6 /app/app_600s<br/> 9&nbsp;&nbsp;&nbsp;&nbsp;6 /app/app_60s<br/> 28&nbsp;&nbsp;0 sh<br/> 34&nbsp;&nbsp;28 ps -eo pid,ppid,args<br/> | $ docker logs -f dumb<br/>60 ticker<br/>30 ticker<br/>600 ticker<br/>600 ticker<br/>60 ticker<br/>30 ticker<br/># 执行 docker stop dumb<br/>600 signal<br/>60 signal | 执行`docker stop dumb`后，<br />log中出现了两个程序接收到信号的日志输出<br />多次运行后，信号输出未1-3个不等，<br />start.sh是dumb-int的直接子进程<br />但start.sh并未等待它所有子进程推出后再退出 |
| 3    | ENTRYPOINT + DUMB_INIT_SETSID=0           | 同2                                                          | 同1                                                          | 执行`docker stop dumb`后容器立即退出<br />原因同2            |
| 4    | ENTRYPOINT + shebang + DUMB_INIT_SETSID=0 | / # pstree && ps -eo pid,ppid,args<br/> dumb-init---start.sh---sh-+-app_30s---5*[{app_30s}]<br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\|-app_600s---6*[{app_600s}]<br/>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;`-app_60s---6*[{app_60s}]<br/> PID   PPID  COMMAND<br/> 1&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;0 /usr/bin/dumb-init -- /start.sh<br/> 6&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1 {start.sh} /usr/bin/dumb-init /bin/sh /start.sh<br/> 7&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;6 /bin/sh /start.sh<br/> 8&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;7 /app/app_30s<br/> 9&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;7 /app/app_600s<br/> 10&nbsp;&nbsp;&nbsp;7 /app/app_60s<br/> 28&nbsp;&nbsp;&nbsp;0 sh<br/> 34&nbsp;&nbsp;&nbsp;28 ps -eo pid,ppid,args<br/> | 同1                                                          | 执行`docker stop dumb`后容器立即退出<br />原因同2<br />直接子进程分别是start.sh 以及 shebang中的 sh |
| 5    | ENTRYPOINT + shebang + DUMB_INIT_SETSID=  | 同4                                                          | $ docker logs -f dumb<br/>60 ticker<br/>30 ticker<br/>600 ticker<br/>60 ticker<br/>30 ticker<br/>600 ticker<br/># 执行 docker stop dumb<br/>60 signal<br/>600 signal<br/>30 signal | 执行`docker stop dumb`后<br />容器等待所有子进程退出后才退出。<br />实现预期目标<br />原因是脚本shebang中设置`/usr/bin/dumb-init`，<br />其pid为6，ppid为1，接收到pid1传递的信号后再传递<br />同时等待所有子进程退出后才退出 |


## 解决方法
### 如果多程序中只有一个程序需要获取到信号，则通过exec提升子进程
> exec 命令用于调用并执行指定的命令。
> 通常用在 Shell 脚本程序中，可以调用其他的命令。如果在当前终端中使用命令，则当指定的命令执行完毕后会立即退出终端。


#### 补充信息，使用exec后，DUMB_INIT_SETSID配置无影响
具体原因看进程树就明白了  

##### ENTRYPOINT
此时有且只有app_60s接收到了信号，具体看进程树  
start.sh
```sh
#! /bin/sh
/app/app_30s &
/app/app_600s &
exec /app/app_60s
```
```sh
/ # pstree && ps -eo pid,ppid,args
dumb-init---app_60s-+-app_30s---6*[{app_30s}]
                    |-app_600s---7*[{app_600s}]
                    `-6*[{app_60s}]
PID   PPID  COMMAND
    1     0 /usr/bin/dumb-init -- /start.sh
    6     1 /app/app_60s
    7     6 /app/app_30s
    8     6 /app/app_600s
   28     0 sh
   34    28 ps -eo pid,ppid,args
```

##### ENTRYPOINT + shebang  
此时有且只有app_60s接收到了信号，具体看进程树  
此处可发现，dumb-init多层是可以的，会一直向下传递
```sh
/ # pstree && ps -eo pid,ppid,args
dumb-init---start.sh---app_60s-+-app_30s---6*[{app_30s}]
                               |-app_600s---6*[{app_600s}]
                               `-6*[{app_60s}]
PID   PPID  COMMAND
    1     0 /usr/bin/dumb-init -- /start.sh
    6     1 {start.sh} /usr/bin/dumb-init /bin/sh /start.sh
    7     6 /app/app_60s
    8     7 /app/app_30s
    9     7 /app/app_600s
   28     0 sh
   34    28 ps -eo pid,ppid,args
```
### 如果多个程序都需要获取到信号，则 ENTRYPOINT + shebang + DUMB_INIT_SETSID=
子进程都能从dumb-init获取到信号，并等待其退出  


## 参考连接
[dumb-init](https://github.com/Yelp/dumb-init)
[exec](https://www.google.com/search?q=Linux+exec&oq=Linux+exec+&aqs=edge.0.69i59l2j0i10i12l2j69i60l3.3164j0j9&sourceid=chrome&ie=UTF-8)