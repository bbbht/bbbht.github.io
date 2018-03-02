---
title: 使用hexo时遇到的问题
date: 2018-02-27 12:37:19
tags: hexo
---
初次使用hexo，对各种配置还不熟悉
尽量使用了默认配置，并参考别人的经验，然而还是遇到了些小问题
比如运行`` hexo server ``，``hexo deploy ``等命令时报错
慢慢完善吧，后期再丰富功能

<!-- more -->

## 运行`` hexo server ``命令时报错

### 问题描述
```
INFO  Start processing
ERROR Process failed: tags/index.md
TypeError: Cannot read property 'utcOffset' of null
    at Object.exports.timezone ...
    ...
```

### 原因
主题的timezone配置为空导致
```
timeZone:
```

### 解决方法
设置主题的timezone，并与全局配置保持一致
```
timeZone: Asia/Shanghai
```

## 运行``hexo deploy ``命令失败

### 问题描述
_config.yml配置如下
```yml
deploy:
  type: git
  repository: git@github.com:bbbht/bbbht.github.io.git
  branch: master
```
报错信息
```
ERROR Deployer not found: git
```

### 原因
功能缺失

### 解决方法
```sh
npm install hexo-deployer-git --save
```

## disqus评论无法使用

### 问题描述
同事进入博客文章页后，发现disqus评论插件并未正常加载

### 原因
你懂的

### 解决方法
使用gitment替代disqus，毕竟目前部署在github pages上
教程很多，自行搜索即可
[Google 搜索 hexo next gitment](https://www.google.com/search?q=hexo+next+Gitment)
不同主题可能不同，next主题已集成，很方便
> 注： 在主题配置文件中 github_repo 填写仓库名即可，并非仓库地址
另外，配置完成后需登陆账号手动初始化方可使用

### 参考链接
[Gitment：使用 GitHub Issues 搭建评论系统](https://imsun.net/posts/gitment-introduction/)
