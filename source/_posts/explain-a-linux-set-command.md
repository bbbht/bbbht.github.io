---
title: linux命令'set -- $@'的解释
date: 2018-02-28 10:12:52
tags: bash
categories: Linux
---

看某项目的Dockerfile时，遇到一条命令
``set -- $@ 80``
不甚理解，于是查找资料，发现并没有那么复杂

<!-- more -->

## set的用法
用法很丰富，参考``man set``即可
### ``set -x``
指令执行后先输出该指令及其参数，再输出执行结果
```sh
#!/bin/bash
set -x
echo `date`

# 输出
# ++ date
# + echo 2018年02月27日 17:32:11
# 2018年02月27日 17:32:11
```

## ``--`` （double bash）用法
``--`` （double bash）其实是bash内置命令，在OPTIONS一节中
> \-\-    A \-\- signals the end of options and disables further option processing.  Any arguments after the \-\- are treated as filenames and arguments.  An argument of - is equivalent to \-\-.

即 ``--``表示选项的结束，其后的任何参数都被视为文件名和参数，可以做一些特殊操作，比如新建名为"-p"的文件夹
但是关于``-``相当于``--``，测试并没有成功，也许是我立即错误了吧
```
# root in /tmp [11:01:36] 
$ mkdir tmpdir 

# root in /tmp [11:01:39] 
$ cd tmpdir   

# root in /tmp/tmpdir [11:01:44] 
$ mkdir -v -p  
mkdir: 缺少操作数
Try 'mkdir --help' for more information.

# root in /tmp/tmpdir [11:01:57] C:1
$ mkdir -v - -p
mkdir: 已创建目录 "-"

# root in /tmp/tmpdir [11:02:04] 
$ mkdir -v -- -p
mkdir: 已创建目录 "-p"

# root in /tmp/tmpdir [11:02:09] 
$ ll
总用量 8.0K
drwxr-xr-x 2 root root 4.0K 2月  28 11:02 -
drwxr-xr-x 2 root root 4.0K 2月  28 11:02 -p
```
删除同理
```
# root in /tmp/tmpdir [11:04:48] 
$ rm -v -r -p   
Usage: trash-put [OPTION]... FILE...

trash-put: error: no such option: -p

# root in /tmp/tmpdir [11:04:55] C:2
$ rm -v -r -- -p
trash-put: Volume of file: /
trash-put: Trash-dir: /root/.local/share/Trash from volume: /
trash-put: '-p' trashed in ~/.local/share/Trash
```
trash是安装来模拟回收站的
<!-- [trash-cli](https://github.com/andreafrancia/trash-cli) -->    

## ``$@``用法
同样参考``man bash``中Special Parameters一节内容即可
- $*
以一个单字符串显示所有向脚本传递的参数，与位置变量不同，参数可超过9个
- $@
传给脚本的所有参数的列表
- $#
添加到Shell的参数个数
- $$
脚本运行的当前进程ID号
- $?
显示最后命令的退出状态，0表示没有错误，其他表示有错误
- $!
Shell最后运行的后台Process的PID
- $0
脚本本身的名字
- $1($2,$3...)
传递给该shell脚本的第N个参数，不能超过9

## 关于``set -- $@ 80``

执行`` man set ``查找关于``--``和``-``的内容
> --  If no arguments follow this option, then the positional parameters are unset.  Otherwise, the positional parameters are set to the args, even if some of them begin with a -.
\- Signal the end of options, cause all remaining args to be assigned to the positional parameters.  The -x and -v options are turned off.   If  there  are  no  args,  the  positional  parameters  remain unchanged.

其作用就是将``--``后的参数覆盖原位置参数，即使以``-``开头也不再作为选项
联系上文``$@``的解释，此命令即为添加追加一个位置参数
test.sh
```sh
#!/bin/bash
set -- a b c
echo "\$1=$1"
echo "\$2=$2"
echo "\$3=$3"
```
```sh
# 无参数执行test.sh
test.sh
# 输出
# $1=a
# $2=b
# $3=c

# 带参数执行test.sh
test.sh 1 2 3
# 输出
# $1=a
# $2=b
# $3=c
```

test2.sh
```sh
#!/bin/bash
set -- $@ a b
echo "\$1=$1"
echo "\$2=$2"
echo "\$3=$3"
echo "\$4=$4"
```
```sh
test2.sh 1 2
# 输出
# $1=1
# $2=2
# $3=a
# $4=b
```
还是很实用的
