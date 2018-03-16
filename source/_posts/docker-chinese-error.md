---
title: docker中不能显示或输入中文
date: 2018-03-15 09:32:18
tags:
    - docker
categories: docker
---
在公司项目的某个容器内，想要查看某个中文名的文件内容，结果连文件名都不能输入
于是只能先解决屡次出现的中文问题了
<!-- more -->

## 问题描述
ssh进入docker容器内，命令行中不能显示，也不能输入中文
## 原因
系统语言设置导致
```sh
root@298b22751598:/# locale
LANG=
LANGUAGE=
LC_CTYPE="POSIX"
LC_NUMERIC="POSIX"
LC_TIME="POSIX"
LC_COLLATE="POSIX"
LC_MONETARY="POSIX"
LC_MESSAGES="POSIX"
LC_PAPER="POSIX"
LC_NAME="POSIX"
LC_ADDRESS="POSIX"
LC_TELEPHONE="POSIX"
LC_MEASUREMENT="POSIX"
LC_IDENTIFICATION="POSIX"
LC_ALL=

root@298b22751598:/# locale -a
C
C.UTF-8
POSIX
```
所以需要修改配置

## 解决方法
两种方案：
### 1. 临时
重启或注销后问题依旧
```sh
echo "export LANG=C.UTF-8" >> /etc/profile
source /etc/profile
```
### 2. 修改Dockerfile，一劳永逸
在Dockerfile中添加一行，设置环境变量
```dockerfile
ENV LANG C.UTF-8
```
重新制作docker镜像，然后重新运行容器
