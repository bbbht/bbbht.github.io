---
title: go包依赖管理工具dep
date: 2018-04-28 10:29:53
tags:
    - go
    - dep
categories: go
---
PHP有依赖管理工具Composer，写Go项目的时候也会依赖很多的包
目前使用``dep``来进行依赖管理
简单的使用只需要几个命令就可以
- 生成依赖配置文件（init）
- 安装更新依赖（ensure）

<!-- more -->

## 安装
如果安装了Go语言环境
```sh
go get -u github.com/golang/dep/cmd/dep
```
```
dep version
dep:
 version     : devel
 build date  :
 git hash    :
 go version  : go1.10.1
 go compiler : gc
 platform    : windows/amd64
 features    : ImportDuringSolve=false
```
其他安装方法查阅[参考文档](https://golang.github.io/dep/docs/installation.html)
## 使用
### 初始化
在项目根目录运行，需要**互联网**
```
dep init
```
将生成两个文件，及一个目录
Gopkg.toml Gopkg.lock vendor/
Gopkg.toml Gopkg.lock要加入版本控制
vender/就看实际需要了，比如没有**互联网**

### 安装依赖
在项目根目录
```
dep ensure
```
#### 添加依赖
```
dep ensure -add github.com/foo/bar github.com/baz/quux
```
#### 移除依赖
通过执行命令
```
dep ensure
```
在输出中会提示代码中未使用的依赖（此时Gopkg.lock文件中已移除相应项）
```
Warning: the following project(s) have [[constraint]] stanzas in Gopkg.toml:

  ✗  github.com/sirupsen/logrus

However, these projects are not direct dependencies of the current project:
they are not imported in any .go files, nor are they in the 'required' list in
Gopkg.toml. Dep only applies [[constraint]] rules to direct dependencies, so
these rules will have no effect.

...
```
然后手动从Gopkg.toml文件中移除列出的包即可
```
[[constraint]]
  name = "github.com/go-sql-driver/mysql"
  version = "1.3.0"

[[constraint]]
  name = "github.com/sirupsen/logrus"
  version = "1.0.5"

[[constraint]]
  name = "github.com/nsqio/go-nsq"
  version = "1.0.7"
```

## 参考链接
[dep documentation.](https://golang.github.io/dep/docs/introduction.html)
