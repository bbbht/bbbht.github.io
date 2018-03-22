---
title: 使用精简alpine linux系统构建docker镜像
date: 2018-03-22 16:39:58
tags:
    - linux
    - alpine
    - docker
categories: linux
---
> Alpine 操作系统是一个面向安全的轻型 Linux 发行版，由非商业组织维护
> 关注安全，性能和资源效能。是一个优秀的可以适用于生产的基础系统/环境。

作为基础镜像，只有5M的体积非常有优势
其使用上也有一定的区别，尤其是包管理等
具体可前往[Alpine Linux: index](https://alpinelinux.org/)
此处记录下软件安装及使用上的问题
<!-- more -->

## 包管理
alpine linux中使用apk进行包管理
最好的文档就是``--help``
```
# apk --help
apk-tools 2.6.9, compiled for x86_64.

usage: apk COMMAND [-h|--help] [-p|--root DIR]
           [-X|--repository REPO] [-q|--quiet]
           [-v|--verbose] [-i|--interactive]
           [-V|--version] [-f|--force]
           [-U|--update-cache] [--progress]
           [--progress-fd FD] [--no-progress]
           [--purge] [--allow-untrusted]
           [--wait TIME] [--keys-dir KEYSDIR]
           [--repositories-file REPOFILE]
           [--no-network] [--no-cache]
           [--arch ARCH] [--print-arch] [ARGS]...

The following commands are available:
  add       Add PACKAGEs to 'world' and install (or upgrade) them, while ensuring that all dependencies are met
  del       Remove PACKAGEs from 'world' and uninstall them
  fix       Repair package or upgrade it without modifying main dependencies
  update    Update repository indexes from all remote repositories
  info      Give detailed information about PACKAGEs or repositores
  search    Search package by PATTERNs or by indexed dependencies
  upgrade   Upgrade currently installed packages to match repositories
  cache     Download missing PACKAGEs to cache and/or delete unneeded files from cache
  version   Compare package versions (in installed database vs. available) or do tests on literal version strings index     Create repository index file from FILEs
  fetch     Download PACKAGEs from global repositories to a local directory
  audit     Audit the directories for changes
  verify    Verify package integrity and signature
  dot       Generate graphviz graphs
  policy    Show repository policy for packages
  stats     Show statistics about repositories and installations

Global options:
  -h, --help              Show generic help or applet specific help
  -p, --root DIR          Install packages to DIR
  -X, --repository REPO   Use packages from REPO
  -q, --quiet             Print less information
  -v, --verbose           Print more information (can be doubled)
  -i, --interactive       Ask confirmation for certain operations
  -V, --version           Print program version and exit
  -f, --force             Do what was asked even if it looks dangerous
  -U, --update-cache      Update the repository cache
  --progress              Show a progress bar
  --progress-fd FD        Write progress to fd
  --no-progress           Disable progress bar even for TTYs
  --purge                 Delete also modified configuration files (pkg removal) and uninstalled packages from cache (cache clean)
  --allow-untrusted       Install packages with untrusted signature or no signature
  --wait TIME             Wait for TIME seconds to get an exclusive repository lock before failing
  --keys-dir KEYSDIR      Override directory of trusted keys
  --repositories-file REPOFILE Override repositories file
  --no-network            Do not use network (cache is still used)
  --no-cache              Read uncached index from network
  --arch ARCH             Use architecture with --root
  --print-arch            Print default arch and exit

This apk has coffee making abilities.
```
典型的使用情况
```dockerfile
RUN apk update && \
    apk add git && \
    rm -rf /var/cache/apk/*
```
## 时区
由于精简，是没有时区文件的，如需更改则手动安装、设置
```
apk add -U tzdata
cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
```
## Docker使用
同样由于精简，所以是没有``bash``的
如果通过``docker exec -it xxx bash``进入一个未主动安装bash的alpine容器将得到错误信息
```
"exec: \"bash\": executable file not found in $PATH": unknown
```
原因就是bash命令并不存在，需要调用``/bin/sh``
或者构建镜像时安装bash即可
