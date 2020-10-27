---
title: 移除chrome/edge download all with free download manager的右键菜单
date: 2020-10-27 09:11:12
tags: chrome
categories: other
---

Windows系统安装了 FDM（Free Download Manager）后，浏览器右键始终存在一个菜单“Download all with Free Download Manager”  
其它扩展都有关闭右键菜单的配置选项，这个扩展没有，于是只能用特殊手段了  
PS. 扩展升级后可能会被覆盖，重新操作即可

<!-- more -->

## 原因
没啥，就是强迫症，按需使用，不需要这么强存在感

## 解决方法
1. 打开浏览器的扩展管理列表
2. 页面上的开发人员选项，选中
3. 找到对应的扩展 FDM，打开详细信息
4. 找到ID
   1. **来源** Chrome Web Store **ID** ahmpjcflkgiildlgicmcieglgoilbfdp
5. 使用 Everything 搜索这个ID，进入对应目录
   1. 进入对应版本目录 > _locales > en > messages.json
6. "menuAll" 属性即为此全局菜单，按需修改message或移除
7. 重启浏览器或扩展即可
