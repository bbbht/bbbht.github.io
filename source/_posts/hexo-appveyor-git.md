---
title: 使用Appveyor管理hexo源码并实现自动发布
date: 2018-03-01 17:01:27
tags: hexo
categories:
---
之前hexo的环境是在公司电脑上部署的，考虑到源码的安全备份，以及换电脑操作的不可避免，所以需要一个方案来解决
大致是三种成熟方案：
1. Dropbox，百度云盘等直接同步
需要安装配置额外的软件，嫌麻烦了
2. VPS部署环境
是个好方法，云端操作，然而手上并没有VPS可用
3. 对资源文件也进行版本控制
即最终所采用的方案，并配合[Appveyor](https://www.appveyor.com/)完成一键自动部署
<!-- more -->

## Appveyor配置
github账号登陆，选择对应的github page repo，简单配置即可，不再赘述
详见[如何更好地对hexo博客管理](http://feg.netease.com/archives/634.html)
> 注：注意node版本

## 拉取仓库
```sh
git clone git@github.com:bbbht/bbbht.github.io.git hexo --branch hexo
```

## hexo环境初始化
前提是系统中已存在git及nodejs环境
```sh
# 进入博客资源根目录
cd hexo
# 安装hexo
npm install -g hexo-cli
# 运行hexo server
hexo s -p 4000
```
接下来即可完成本地部署，换电脑什么的也无妨了

## 发布
文章完成之后，直接在hexo分支push
```sh
git add .
git commit -am "commit msg"
git pull --rebase
git push origin hexo:hexo
```
然后等待自动发布完成，预览即可
本文即为测试效果而写

## 参考链接
[如何更好地对hexo博客管理](http://feg.netease.com/archives/634.html)
