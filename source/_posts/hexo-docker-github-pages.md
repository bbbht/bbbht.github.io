---
title: 在docker中部署hexo
date: 2018-03-16 08:49:53
tags: 
    - hexo
    - docker
categories: hexo
---
开发机软件环境比较复杂，为避免无谓的干扰，所以将hexo环境放入docker中
于是写了个Dockfile
只用来本地预览，发布还是由appveyor完成
顺手够用就好
<!-- more -->
参考
[VSCode 配合sftp同步编辑远程代码](/2018/03/30/vscode-sftp/)
## 源码
### Dockerfile
Dockerfile
```dockerfile
FROM node:lts-alpine

WORKDIR /hexo
ENV LANG C.UTF-8

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories && \
    apk update && \
    apk add --no-cache git tzdata && \
    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    echo "Asia/Shanghai" > /etc/timezone && \
    npm config set registry https://registry.npm.taobao.org && \
    npm install hexo-cli -g --no-optional && \
    npm install hexo-tag-plantuml --save && \
    rm -rf /var/cache/apk/* /tmp/*

COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN hexo version

# 注意命令执行顺序
ENTRYPOINT ["/docker-entrypoint.sh"]
```

### 容器运行初始化脚本
entrypoint.sh
```sh
#!/bin/sh
set -x

HEXO_DIR=/hexo

cd $HEXO_DIR 

npm install --no-optional --no-bin-links 

exec "$@"
```

## 使用
将Dockerfile，entrypoint.sh存为文件，放在在同一目录下
执行命令
```sh
docker build -t hexo:node-lts-alpine .
docker run -d --restart=always --name hexo-server -p 4000:4000 -v /path-to-hexo:/hexo hexo:node-lts-alpine hexo s

#  配置别名，方便本地化使用hexo命令
alias hexo="docker exec hexo-server hexo"
```
