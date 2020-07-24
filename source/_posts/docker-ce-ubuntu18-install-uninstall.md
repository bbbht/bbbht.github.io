---
title: Ubuntu18.04中安装及彻底卸载Docker-CE
date: 2020-04-10 09:32:18
tags:
    - docker
categories: docker
---
装了个新的虚拟机，要安装docker，不停地碰到各种问题，折腾  
官方源太慢，改源又出现Hash Sum mismatch错误，最终是使用阿里的源，记录下，下次少折腾。。
<!-- more -->

## 安装
```sh
sudo apt-get update
sudo apt-get -y install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL http://mirrors.aliyun.com/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] http://mirrors.aliyun.com/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get -y update
sudo apt-get -y install docker-ce
```
当然，如果要指定版本，需要先列出可用版本，然后再指定版本安装
```sh
apt-cache madison docker-ce
#  docker-ce | 5:18.09.0~3-0~ubuntu-bionic | http://mirrors.aliyun.com/docker-ce/linux/ubuntu bionic/stable amd64 Packages
sudo apt-get -y install docker-ce=5:18.09.0~3-0~ubuntu-bionic
```

## 卸载
卸载不彻底的话，安装后各种问题，头大
```sh
sudo apt-get purge -y docker-engine docker docker.io docker-ce  
sudo apt-get autoremove -y --purge docker-engine docker docker.io docker-ce 
# 再看看有没有遗留的
dpkg -l | grep -i docker
# 按输出结果，删除

sudo rm -rf /var/lib/docker /etc/docker
sudo groupdel docker
sudo rm -rf /var/run/docker.sock
sudo rm -rf /var/run/docker/
```