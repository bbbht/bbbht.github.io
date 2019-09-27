---
title: go1.13 使用 GOPROXY
date: 2019-09-27 13:49:45
tags: go
categories: go
---
go更新到了1.13版本，期待已久的goproxy支持私有库特性终于来了  
一次配置，告别代理  

<!-- more -->
## 安装、升级GO
```bash
sudo add-apt-repository ppa:longsleep/golang-backports
sudo apt-get update
sudo apt-get install golang-go
```

安装完后检查版本
```bash
go versino
go version go1.12.7 linux/amd64
```
好像是之前手动安装造成的，修改下PATH  
同时要修改GOROOT，GOTOOLDIR，不修改的话，会造成`missing dot in first path element`的报错问题  
```bash
go version
go version go1.13 linux/amd64
```
## 配置

执行`go env`，会发多了几个配置
```
GOPROXY="https://proxy.golang.org,direct"
GOSUMDB="sum.golang.org"
GOPRIVATE=""
GONOSUMDB=""
GONOPROXY=""
```

### GOPROXY
有了默认值，不过并不能用。。。  
设置可用的GOPROXY  
```bash
go env -w GOPROXY=https://goproxy.cn,direct
```
`goproxy.cn`是七牛维护的，很稳定  
`direct`是此版本新增的，作用是在拉取仓库遇到`404`时，直接拉取源代码，比如私有仓库  

### GONOPROXY
用来配置哪些module path下的模块需要忽略`GOPROXY`，直接回源拉取  
```bash
go env -w GONOPROXY="*.abc.com,*.def.com"
```

### GOSUMDB
用来防止从公共模块代理中抓取的模块被篡改  
其原理是通过制定一个可信任的模块校验和数据库地址，当从公共模块代理中抓取模块之后，对其进行hash校验  
校验结果一致则认为没有被篡改

### GONOSUMDB
同`GONOPROXY`,用来配置忽略校验制定module path下的模块

### GOPRIVATE
设置私有仓库地址  
它的作用相当于同时设置`GONOPROXY`和`GONOSUMDB`  
```bash
go env -w GOPRIVATE="*.abc.com,*.def.com"
```

## 参考链接
[goproxy.cn](https://github.com/goproxy/goproxy.cn)
[go1.13](http://docs.studygolang.com/doc/go1.13)