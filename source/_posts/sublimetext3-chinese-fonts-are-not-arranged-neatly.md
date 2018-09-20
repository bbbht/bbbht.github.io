---
title: SublimeText3中文字体不整齐，上下错位
date: 2018-09-20 16:03:03
tags: sublime
categories: sublime
---

使用sublime text频次虽然减少，但作为编辑器实在是少不了  
最近升级一下，发现中文字体上下错位，犬牙交错，逼死强迫症  
通过搜索加上尝试，得出了个人满意的解决方案  
话说，当年windows的“正在启动”的上下错位问题，也不知道解决了没有啊

<!-- more -->

## 原因
应该是锯齿的问题

## 解决方法
### 1. 使用特定字体
这个方法可以，比如``Yahei Consolas Hybrid``，不知是否开源  
但是作为经常改字体的强迫症，不合适

### 2. 修改配置
在一篇文章中提到添加自定义配置``font_options``如下，即可解决
```json
{
    "font_options": ["gdi"]
}
```

仅仅这样修改确实可以实现字体平齐，但是，字体明显变细，模糊了（可能是字体的原因，Hack字体）  
于是又加入``gray_antialias``配置项，完美解决  
```json
{
    "font_options": ["gray_antialias", "gdi"]
}
```

配置解释
> - "gdi": Use GDI for font rendering
> - "gray_antialias": Uses grayscale antialiasing instead of subpixel