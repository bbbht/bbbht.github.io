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

## 源码
### Dockerfile
Dockerfile
```dockerfile
FROM node:6-alpine
MAINTAINER bbbht <plateau.loess@gmail.com>
WORKDIR /hexo
VOLUME ['/hexo']
EXPOSE 4000
ENV LANG C.UTF-8

RUN apk add --update git && \
    npm install hexo-cli -g --no-optional

COPY entrypoint.sh /
ENTRYPOINT ["sh", "/entrypoint.sh"]
CMD ['hexo', 's']
```

### 容器运行初始化脚本
entrypoint.sh
```sh
#!/bin/bash
set -x
HEXO_DIR=/hexo
if [ ! -d $HEXO_DIR/.git ]; then
    git clone https://github.com/bbbht/bbbht.github.io.git --branch hexo $HEXO_DIR
else
    echo $HEXO_DIR" is not empty"
fi
cd $HEXO_DIR
git config user.name bbbht
git config user.email plateau.loess@gmail.com
git config core.fileMode false
npm install --no-optional --no-bin-links 

exec "$@"
```

## 使用
将Dockerfile，entrypoint.sh存为文件，放在在同一目录下
执行命令
```sh
docker build -t hexo:alpine .
docker run -d --name hexo-server -p 4000:4000 -v /hexo:/hexo hexo:alpine hexo s -w
#  配置别名，方便本地化使用hexo命令
alias hexo="docker exec hexo-server hexo"
```
