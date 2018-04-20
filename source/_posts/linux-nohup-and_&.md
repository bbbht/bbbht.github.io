---
title: linux进程后台运行 nohup和&
date: 2018-04-20 14:22:51
tags:
    - linux
    - 后台运行
categories: linux
---
go编译的程序，要求后台持续运行
了解到一种方法，即使用``nohup``配合``&``来实现
当然还有别的实现方法，暂时先使用这种方式
<!-- more -->
### nohup
帮助文档
```
# nohup --help
Usage: nohup COMMAND [ARG]...
  or:  nohup OPTION
Run COMMAND, ignoring hangup signals.
...
```
就是运行指定的命令，然后忽略挂起信号
程序的终端输出也不会显示，所以有需求的话，应当使用``>``
> ``nohup``默认不会后台运行

### &
放在启动参数后面表示设置此进程为后台进程
> 如果终端关闭，程序也就停了

所以二者配合使用，就能够实现后台运行且不会因为退出终端而程序退出了
