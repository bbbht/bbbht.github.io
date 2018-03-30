---
title: VSCode 配合sftp同步编辑远程代码
date: 2018-03-30 13:49:10
tags: vscode
categories: 开发工具
---
之前有碰到使用虚拟机共享文件夹的文件同步问题
发现一种新方案，直接将文件置于docker镜像中，然后配置ssh，通过sftp协议访问即可
当然，sftp默认使用有一定的安全性问题，暂不考虑
本地使用vscode，配合sftp插件来使用
demo为hexo开发环境，与上次的版本比较，在使用上有了很大的精简
<!-- more -->

### Dockerfile
```dockerfile
FROM node:6-alpine
MAINTAINER bbbht <plateau.loess@gmail.com>
WORKDIR /hexo
ENV LANG C.UTF-8

RUN apk update && \
    apk add --no-cache openrc openssh git tzdata && \
    rc-update add sshd && \
    rc-status && \
    touch /run/openrc/softlevel && \
    echo -e root:root | chpasswd && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    npm install hexo-cli -g --no-optional && \
    echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    git clone https://github.com/bbbht/bbbht.github.io.git --branch hexo /hexo && \
    cd /hexo && \
    git config user.name bbbht && \
    git config user.email plateau.loess@gmail.com && \
    git config core.fileMode false && \
    npm install --no-optional --no-bin-links && \
    rm -rf /var/cache/apk/* /tmp/*


CMD ['hexo', 's']
```
通过``echo -e root:root | chpasswd``方式设置root密码
通过安装tzdata，修改了时区为 UTC+0800
安装openrc，设置ssh开机启动
其中``rc-status``为必要步骤
然后编辑更新等工作在主机系统中完成即可
### 运行docker
```
# 构建镜像
docker build -t hexo:alpine .
# 运行容器
docker run -d --name hexo-server -p 4000:4000 -p 4022:22 hexo:alpine hexo s
```

### 配置sftp插件
安装插件
打开指定的空目录
``Ctrl + Shift + P``输入 ``sftp:config``
编辑生成的sftp.json文件
```json
{
    "protocol": "sftp",
    "host": "192.168.3.144",
    "username": "root",
    "password": "root",
    "port": 4022,
    "uploadOnSave": false,
    "downloadOnOpen": false,
    "watcher": {
        "files": "**/*",
        "autoUpload": true,
        "autoDelete": true
    },
    "ignore": [
        "node_modules",
        ".vscode",
        ".idea",
        ".DS_Store"
    ],
    "remotePath": "/hexo"
}
```
然后``Ctrl + Shift + P``输入 ``sftp:Download``即可获取远程代码，并保持同步
不再有文件修改状态的问题
具体使用及配置说明，请移步参考链接

### 参考链接
[sftp sync extension for VS Code](https://marketplace.visualstudio.com/items?itemName=liximomo.sftp)
