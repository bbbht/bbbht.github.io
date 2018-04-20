---
title: Go本地编译后，服务器运行报错“no such file or directory”
date: 2018-04-20 16:03:37
tags: 
    - go
    - alpine
categories: go
---
写了Go代码，本地编译成二进制可运行文件
本地运行正常，但是，移动到服务器运行时报错
-bash: xxxxxx: No such file or directory
而文件是存在的，也有执行权限
有人说是因为32位程序在64位系统运行造成的
但通过``uname -a``及``file xxxx``对比，系统和文件，均是64位，所以不是此原因
其实是编译环境的锅，具体来说，是自己不熟悉build配置导致的
<!-- more -->

## 问题描述
### 环境
- golang的docker镜像 
- 版本
1.10.1-alpine3.7
- 命令 
```
go build -o xxxx main.go
```

## 原因
alpine作为基础镜像
应该是alpine使用了**musl libc**，而非通常用的glibc
当然这也是其镜像能小到**5M**的原因之一

## 解决方法
### 换编译环境
重新pull了golang的镜像，不使用精简系统alpine
```
docker pull golang:1.10.1
```
毕竟存储空间不值钱
```
$ docker images                                                         
REPOSITORY    TAG        IMAGE ID            CREATED       SIZE
golang        alpine     41bf3e9b9f3c        2 weeks ago   376MB
golang        1.10.1     6fe15d4cbc64        2 weeks ago   780MB
```
重新build后，在其他服务器上运行正常

### 编译时修改环境变量
设置CGO_ENABLED=0
```
CGO_ENABLED=0 go build -o xxxx main.go
```
涉及到跨平台交叉编译配置

## 参考链接
[go cgo](https://golang.org/cmd/cgo/)
