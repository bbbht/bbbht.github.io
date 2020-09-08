---
title: windows的使用
date: 2020-08-19 17:14:11
tags: windows
categories: windows
---
今天解决了一个困扰许久的问题，小问题带来意外的惊喜  
关于Windows的多显示器不同分辨率导致的程序缩放异常问题  
同时也记录下常用的window软件，以便换机重装  
<!-- more -->
## 常用软件列表
### Hack字体
这是一款个人偏爱的字体，用于编程也舒服
### 优效日历
[链接](http://www.youxiao.cn/index.php/yxcalendar/)  
可以在任务栏中设置自定义格式的日历、时间，之前 用软媒魔方  
> 优效日历是一款具有 Win10 风格的桌面日历软件，在 Win10 系统自带的日历之上做出了改良和创新，保留了它界面简洁，显示全面的特点，另外新增了超过 20 余种实用功能。

### FastStone Capture
看重它的滚动截屏功能  
[链接](https://www.faststone.org/FSCaptureDownload.htm)
### Snipaste
使用的是Microsoft Store版本  
当作系统日常截图，设置`Alt + A`的QQ截图习惯热键  
> Snipaste 是一个简单但强大的截图工具，也可以让你将截图贴回到屏幕上

[链接](https://zh.snipaste.com/)
### v2rayN
玩具  
[链接](https://github.com/2dust/v2rayN/releases)
### TrafficMonitor
> Traffic Monitor是一款用于Windows平台的网速监控悬浮窗软件，可以显示当前网速、CPU及内存利用率，支持嵌入到任务栏显示，支持更换皮肤、历史流量统计等功能。

[链接](https://github.com/zhongyang219/TrafficMonitor)
### QuickLook
空格预览文件内容  
[链接](https://github.com/QL-Win/QuickLook)  
[插件链接](https://github.com/QL-Win/QuickLook/wiki/Available-Plugins)
### Wox
配合Everything，效率神器  
[链接](http://www.wox.one/)
#### Everything
[链接](https://www.voidtools.com/zh-cn/)
### SumatraPDF
免费的PDF阅读器，界面清爽够用  
[链接](https://www.sumatrapdfreader.org/free-pdf-reader.html)
### GeekUninstaller
卸载软件的好手  
[链接](https://geekuninstaller.com/)
### Unlocker
终止正在使用某文件的进程，或迫使进程停止使用该文件  
[链接](http://emptyloop.com/unlocker/)
### Potplayer
本地、网络视频播放利器  
[链接](https://potplayer.daum.net/)
### Honeyview
清爽图片查看器  
[链接](https://cn.bandisoft.com/honeyview/)
### Typora
Markdown编辑器  
[链接](https://typora.io/)
### Bing Wallpaper
微软出品，bing壁纸，每日自动更新  
[链接](https://www.microsoft.com/en-us/bing/bing-wallpaper)
### PilotEdit Lite
大文件查看、编辑  
[链接](https://www.pilotedit.com/)
### 7 Zip
开源数据压缩程序  
[链接](https://www.7-zip.org/download.html)

## 高 DPI 的适配问题
原因当然是微软以及程序对高DPI、不同屏幕不同缩放比的处理不好导致  
比如笔记本内置显示器分辨率`2560 X 1600`，缩放比`200%` 而外接显示器`1920 X 1080`，缩放比`100%`  
于是，在内置屏显式ok的程序窗口，在移动到外接时，仍然是按`200%`缩放比处理，于是就出现了巨大的窗口，字体图标统统放大  
典型的代表程序为:
- Navicat
- 网易邮箱大师
- Oracle VMVirtualBox

### 解决方法

解决其实很简单，使用Windows的兼容性配置   
1. 找到程序所在位置
2. 在程序文件`右键`，选择`属性`
3. 选择`兼容性`选项
4. 点击`更改高 DPI 设置`
5. 定位到`高 DPI 缩放替代`
6. 勾选`替代高 DPI 缩放行为。 缩放执行`
7. 下拉框按需选择`应用程序`/`系统`/`系统（增强）`
   1. 各个配置效果不同，可以尝试一下
8. 重启程序即可

## 电池状态报告
1. `Win + R` 打开命令提示符
2. 输入`powercfg/batteryreport`
3. 报告文件位于`C:\User\UserName\battery-report.html`
4. 打开查看