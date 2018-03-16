---
title: 已停止容器无法通过docker start启动并报错already exists
date: 2018-03-16 09:37:58
tags: docker
categories: docker
---
新装的虚拟机，新安装的docker，启动正常
容器运行也正常，问题出在重启虚拟机后
运行docker start XXX 报错 XXX already exists，而该容器并未运行
最终理解为新版本（18.02）bug，降级docker解决
<!-- more -->

## 问题描述
无法通过start，restart命令启动已停止的容器
均报错already exists
```sh
$ docker start webserver 
Error response from daemon: container "ca9f2b815c64980dd3625870a995b50b7b9a3dca2130b275122a21beef380b9c": already exists
Error: failed to start containers: webserver
$ 
$ docker restart webserver 
Error response from daemon: Cannot restart container webserver: container "ca9f2b815c64980dd3625870a995b50b7b9a3dca2130b275122a21beef380b9c": already exists
$ 
$ docker ps -a
CONTAINER ID        IMAGE                                                   COMMAND             CREATED             STATUS                        PORTS                                                           NAMES
ca9f2b815c64        registry.cn-hangzhou.aliyuncs.com/mudu/mudutv-web-dev   "/start.sh"         5 hours ago         Exited (255) 11 minutes ago   0.0.0.0:80->80/tcp, 0.0.0.0:443->443/tcp, 0.0.0.0:222->22/tcp   webserver
$ docker stop webserver 
webserver
$ docker start webserver 
Error response from daemon: container "ca9f2b815c64980dd3625870a995b50b7b9a3dca2130b275122a21beef380b9c": already exists
Error: failed to start containers: webserver
$ 
$ docker --version
Docker version 18.02.0-ce, build fc4de44
```

## 原因
网上遇到此问题的，基本都是最新版本，即**18.02**
应该是版本bug
## 解决方法
选择降级来尝试解决
#### 查看下可用版本列表
```sh
$ apt-cache policy docker-ce 
docker-ce:
  已安装：  (无)
  候选软件包：18.02.0~ce-0~ubuntu
  版本列表：
     18.02.0~ce-0~ubuntu 0
        500 https://download.docker.com/linux/ubuntu/ trusty/edge amd64 Packages
     18.01.0~ce-0~ubuntu 0
        500 https://download.docker.com/linux/ubuntu/ trusty/edge amd64 Packages
     17.12.1~ce-0~ubuntu 0
        500 https://download.docker.com/linux/ubuntu/ trusty/edge amd64 Packages
     17.12.0~ce-0~ubuntu 0
        500 https://download.docker.com/linux/ubuntu/ trusty/edge amd64 Packages
     17.11.0~ce-0~ubuntu 0
        500 https://download.docker.com/linux/ubuntu/ trusty/edge amd64 Packages
     17.10.0~ce-0~ubuntu 0
        500 https://download.docker.com/linux/ubuntu/ trusty/edge amd64 Packages
     17.09.1~ce-0~ubuntu 0
        500 https://download.docker.com/linux/ubuntu/ trusty/edge amd64 Packages
     .............
```
#### 卸载docker-ce
```sh
$ sudo apt-get purge docker-ce
```

#### 安装指定版本
```sh
$ sudo apt-get install -y docker-ce=17.12.0~ce-0~ubuntu
```

## 参考链接
[github docker issues](https://github.com/docker/for-linux/issues/211)
