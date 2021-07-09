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
dumb-init的原理就是其作为pid为1的进程，接收到的信号会向其子进程传递，所以非直接子进程是无法接收到信号的（DUMB_INIT_SETSID=0）  
## 解决方法
### 通过exec提升子进程
```sh
#!/usr/bin/dumb-init /bin/sh
/init.sh
# 还有一大堆其它乱七八糟的，省略
a=$1
nohup fluentd&
exec /app/main ${a}
```
修改之后
```sh
/app # ps -eo pid,ppid,args
PID   PPID  COMMAND
    1     0 {start.sh} /usr/bin/dumb-init /bin/sh /bin/start.sh
    8     1 /app/main
   10     1 crond -f
   11     8 {fluentd} /usr/bin/ruby /usr/bin/fluentd
   26    11 /usr/bin/ruby -Eascii-8bit:ascii-8bit /usr/bin/fluentd --under-supervisor
   31     0 sh
   38    31 ps -eo pid,ppid,args
/app # pstree
start.sh-+-crond
         `-main---fluentd---ruby
```
此时`/app/main`即可接收到`SIGTERM`信号  

### ENTRYPOINT ["/usr/bin/dumb-init", "--"]
如果不想在每个脚本中修改，则可以在基础镜像中添加  
```sh
ENTRYPOINT ["/usr/bin/dumb-init", "--"]
```
当然，可以同时使用，但会造成某些程序的ppid并非1，而是dumb-init的pid，因为其可以多层传递

## 参考连接
[dumb-init](https://github.com/Yelp/dumb-init)