---
title: git pull issues - The following untracked working tree files would be overwritten by checkout
date: 2018-05-30 17:04:20
tags: git
categories: git
---

pull代码的时候突然疯狂aborting
```
error: The following untracked working tree files would be overwritten by checkout:
        api/origin/abc123ABC.md
Please move or remove them before you switch branches.
Aborting
could not detach HEAD
```
然而并没有改动这个文件，所以应该并不是冲突  
事情并没有那么简单
<!-- more -->

## 原因
最终的原因是有人修改了这个文件  
并且还修改了文件名的大小写  
问题就出在Windows以系统对文件名大小写不敏感，而Linux是大小写敏感的

## 解决方法
网上一堆通过``git clean -d -fx``命令来解决问题的
然而，在尝试之后，损失严重
```
$ git clean -d -fx
Removing .vscode/
Removing assets/cache/
Removing assets/log/
Removing assets/upload/
Removing config.php
```
丢失了全部的日志，本地测试上传文件，以及各种配置文件
所以还是那句话 **有备无患**

最终的解决方案是修改git配置
```
git config core.ignorecase false
```
然后正常pull即可


## 参考链接
[git config Documentation](https://git-scm.com/docs/git-config)
