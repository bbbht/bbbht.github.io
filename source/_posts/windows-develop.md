---
title: windows下的开发
date: 2018-03-21 01:32:00
tags: 
    - 快捷键
    - develop
categories: windows
---
开发所依赖的环境虽然是linux，但宿主机依然是Win10
GUI下当然要用快捷键，IDE
但按键组合就有冲突的时候，IDE就需要有配置
每次碰到问题都纠结一番
所以将碰到的做个汇总
<!-- more -->
## 快捷键
### 有趣的组合
#### 屏幕变黑白
其实是``win10 1709+``的**颜色筛选器**功能，默认是灰度，也可选绿色盲红色盲等设置
```
Ctrl + Win + C
```
### 冲突的组合
| 按键              | 作用                | 冲突       | 备注     |
| ----------------- | ------------------- | ---------- | -------- |
| Ctrl+Shift+F      | PHPstorm全局搜索    | Intel显卡  |          |
| Ctrl+Shift+方向键 | PHPstorm鼠标位置切换 | Intel显卡  | 屏幕翻转 |
| Ctrl+Alt+L        | PHPstorm格式化代码  | 网易云音乐 | 喜欢歌曲 |

## 配置

### PHPstorm
虽然大部分是遵循公司规范，但还是有部分个人喜好的
#### 括号包裹选中的内容
选中内容，输入括号，默认是直接被替换，而非是括号包裹选中的内容
``Settings -> Editor -> General -> Smart Keys -> Surround selection on typing quote or brace``
选中即可
#### PHP注释保持缩进
``Crel + /``默认的行注释会在该行第一列插入``\\``
会造成代码折叠出现问题
``Settings -> Editor -> Code Style -> PHP -> Code Generation -> Line comment at first column``
取消选中即可
