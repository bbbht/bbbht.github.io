---
title: wsl memory config
date: 2020-10-27 10:33:58
tags: wsl
categories: wsl
---

WSL2的版本，占用内存有点吃不消，好像是不会主动归还给主机，还是得折腾  
配置文件限制上限加主动释放的命令来解决  

<!-- more -->

## 原因

默认占用过多内存，80%，详细参数见参考链接

## 解决方法
### 配置
找到 `.wslconfig` 文件，一般位于 `C:\Users\Your Username\.wslconfig`  
修改后内容如下  
```ini
[wsl2]
memory=4GB
swap=4GB
localhostForwarding=true
```

### 释放
```
# 内存压缩
24 8-20 * * * sudo sh -c "/bin/echo 1 > /proc/sys/vm/compact_memory"
# 缓存清理
42 8-20 * * * sudo sh -c "/bin/echo 1 > /proc/sys/vm/drop_caches"
```

#### drop_caches
Linux Kernel 2.6.16之后的内核提供了一个设置内核抛弃 页缓存 和/或 目录(dentry)和索引节点（inode）缓存，这样可以释放出大量内存。

```sh
# 释放页缓存
echo 1 > /proc/sys/vm/drop_caches
# 释放目录和索引节点缓存（inode and dentry cache）
echo 2 > /proc/sys/vm/drop_caches
# 同时释放 页、目录、索引节点缓存：
echo 3 > /proc/sys/vm/drop_caches
```

#### compact_memory
当内核编译参数设置了CONFIG_COMPACTION，就会在/proc/sys/vm/compact_memory有入口文件。将1写入到这个文件，则所有的zones就会进行压缩，以便能够尽可能地提供连续内存块。对于需要分配大页的时候这个功能非常重要，不过，进程会在需要时直接进行内存压缩（compact memory）

## 参考链接
[WSL commands and launch configurations](https://docs.microsoft.com/zh-cn/windows/wsl/wsl-config)
