---
title: 从 win10 资源管理器左侧移除坚果云/OneDrive
date: 2021-01-19 11:00:30
tags: windows
categories: windows
---
其实一直在用坚果云，但仅仅是自动同步一些文件和文件夹，并不需要在我的资源管理器里有那么强的存在感  
同时现在用 **库** 功能比较多，汇总各类相同属性/用途的文件或文件夹不要太方便。所以它在那儿占着位置看着碍眼了  
但网上一堆方法都无效，只能自己上，搞定之后记录下  
<!-- more -->
首先是通过全局搜索`坚果云`，找到了N个条目，然后尝试修改其名称（默认项），如改为`坚果云云`。最终在下面这个路径下找到了真身  
`HKEY_LOCAL_MACHINE\SOFTWARE\Classes\CLSID\{C18463BF-812E-4BA5-ABD3-C5EA6C473AE2}`  

## 解决方法
修改方法也很简单，编辑其下 `System.IsPinnedToNamespaceTree` 的值。默认为 `1`，改为 `0` 即可。  
不需要重启资源管理器，即时生效  

顺带的，把`OneDrive` 也隐藏了，方法相同，具体位置在  
`HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}`  

### 提示
不同电脑的 ID 可能不同，定位到具体目录即可，或者使用搜索，记得搜索时选择 `全字匹配`，并确保输入的字符串正确

### WindowsTerminal
每次更新`Windows Terminal`，都会在右键菜单增加一个`Open in Windows Terminal`，已自定义了其它打开方式（主要这个太长，右键菜单不美观），故有需要将其移除  
一劳永逸的方式为在如下注册表路径中添加一项，值为WindowsTerminal，作为标记即可
```
HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked\{9F156763-7844-4DC4-B2B1-901F640F5155}
```