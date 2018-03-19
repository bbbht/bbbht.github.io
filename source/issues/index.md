---
title: issues
comments: true
date: 2018-03-19 09:40:29
---
## 尚未解决的问题
#### docker中的hexo无法监测文件改动
hexo部署在docker中，通过数据卷使用虚拟机中的数据，而虚拟机中的数据又是来自virtualbox，共享win10中的文件夹
问题在于，在docker中运行``hexo s``，并win中修改hexo源文件后刷新页面，内容未改变
而在虚拟机中对修改过的文件使用``touch``命令后，再刷新页面，就显示修改后的内容了
