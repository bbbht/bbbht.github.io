---
title: 释放win10子系统WSL2的磁盘空间
date: 2021-01-27 11:20:56
tags: wsl
categories: wsl
---
C盘空间100G，如今只剩不到15G，通过`WinDirStat`软件查看，有个`ext4.vhdx`占用了近20G空间  

<!-- more -->

## 原因
此文件产生的原因是主机上安装了WSL2，且安装了docker，日积月累的，内部积压了特别多版本的镜像和容器  
WSL2本质上来说还是虚拟机，Windows会创建vhdx后缀的磁盘镜像文件，作为存储，特点是支持自动扩容，但是一般不会自动缩容，如VBox创建虚拟机时的动态存储卷  
由于Docker安装了Kafka、Apollo、XXL-JOB、ETCD等一堆还包含多个版本的系统组件，镜像和容器所占空间可观    
其实都是本地验证测试之类的用途，使用时通过docker-compose创建，完成应该删除  

## 解决方法

```sh
# 删除无用的镜像和容器及构建缓存
docker system prune
# WARNING! This will remove:
#   - all stopped containers
#   - all networks not used by at least one container
#   - all dangling images
#   - all dangling build cache
# 删除不需要的镜像
docker images
docker rmi xxx
```
搜索找到 `ext4.vhdx`文件，位置一般在 `C:\Users\用户名\AppData\Local\Packages\应用名\LocalState\ext4.vhdx`
```powershell
# powershell中执行
wsl --shutdown
diskpart

# 打开新命令行窗口操作

# Microsoft DiskPart 版本 10.0.19041.610

# Copyright (C) Microsoft Corporation.
# 在计算机上: xxx

DISKPART> select C:\Users\用户名\AppData\Local\Packages\CanonicalGroupLimited.Ubuntu18.04onWindows_79rhkp1fndgsc\LocalState\ext4.vhdx
# DiskPart 已成功选择虚拟磁盘文件。

DISKPART> compact vdisk

#   100 百分比已完成

# DiskPart 已成功压缩虚拟磁盘文件。
```
完成后`ext4.vhdx`文件体积不到8个G了，释放了十几个G  
当然，还可以在`设置-> 系统 -> 存储 -> 更改新内容的保存位置`来设置新应用的存储移出C盘  
不过WSL应该需要借助其它的工具来迁移，游戏一类的还是可以的