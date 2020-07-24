---
title: VirtualBox使用共享目录及安装增强功能失败的解决方案
date: 2018-03-19 07:31:53
tags: virtualbox
categories: 虚拟机
---
因为想要在主机和虚拟机之间共享目录，所以要安装增强功能
但是直接点击 设备->安装增强功能 的操作是失败的
失败提示**未能加载虚拟光盘 ... vboxguestadditions.iso ...**
使用的环境如下：
- virtubox：版本 5.2.8
- 虚拟机：Ubuntu server 14.04
- 主机系统：win10 版本1079

最终是通过虚拟机内直接安装来解决
<!-- more -->

## 安装增强功能
### 问题描述
在virtualbox界面安装guest additions增强功能失败
提示无法加载vboxguestadditions.iso

### 原因
可能的原因：
- 软件版本问题
- iso文件损坏
- 虚拟机是server版本而非desktop

### 解决方法
虚拟机内手动安装
在对应的虚拟机->设置->存储->控制器IDE 中加载VBox自带的增强文件，在安装路径下`C:\Program Files\Oracle\VirtualBox\VBoxGuestAdditions.iso`  
然后打开虚拟机
```sh
sudo apt-get update
sudo mkdir /media/cdrom
sudo mount /dev/sr0 /media/cdrom
# reboot
# 进入 /media/cdrom
cd /media/cdrom
sudo sh ./VBoxLinuxAdditions.run
# reboot
```

## 自动挂载共享目录并设置权限
并没有使用virtualbox的自动挂载功能，只是选择了固定分配
### 手动挂载
```sh
# 目标文件夹需提前创建
sudo mount -t vboxsf <共享目录配置的名称> <目标路径>
```
### 自动挂载并设置权限
```sh
# 修改系统文件
sudo vim /etc/rc.local
# 在最后加入一行
mount -o umask=002,gid=bbbht,uid=bbbht -t vboxsf <共享目录配置的名称> <目标路径>
```
uid，gid，umask按需修改即可
