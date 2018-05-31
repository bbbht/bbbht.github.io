---
title: linux下指定程序或版本——update-alternatives
date: 2018-05-31 14:23:17
tags: linux
categories: linux
---
系统为Ubuntu16.04
使用fabric编写自动部署脚本，想使用python3
而系统中安装了``2.7``、``3.5``等多个版本，而python命令默认是``2.7``
为了使默认python版本为``3.5``，使用了``update-alternatives``命令来实现
Debian系的发行版自带？
功能大概就是windows的“打开方式”吧
<!-- more -->
## 用法
照例，先是文档
```
$ update-alternatives --help
Usage: update-alternatives [<option> ...] <command>

Commands:
  --install <link> <name> <path> <priority>
    [--slave <link> <name> <path>] ...
                           add a group of alternatives to the system.
  --remove <name> <path>   remove <path> from the <name> group alternative.
  --remove-all <name>      remove <name> group from the alternatives system.
  --auto <name>            switch the master link <name> to automatic mode.
  --display <name>         display information about the <name> group.
  --query <name>           machine parseable version of --display <name>.
  --list <name>            display all targets of the <name> group.
  --get-selections         list master alternative names and their status.
  --set-selections         read alternative status from standard input.
  --config <name>          show alternatives for the <name> group and ask the
                           user to select which one to use.
  --set <name> <path>      set <path> as alternative for <name>.
  --all                    call --config on all alternatives.

<link> is the symlink pointing to /etc/alternatives/<name>.
  (e.g. /usr/bin/pager)
<name> is the master name for this link group.
  (e.g. pager)
<path> is the location of one of the alternative target files.
  (e.g. /usr/bin/less)
<priority> is an integer; options with higher numbers have higher priority in
  automatic mode.
```
显然，需要通过``--install``参数建立一个组，包含同功能的不同程序或不同的版本，从该组中选择默认程序即可
即相当于建立了一个中间层，通过软链接来指定到最终的程序

## 实例
1. 找到要管理的所有程序
```
$ which python 
/usr/bin/python

$ which python3
/usr/bin/python3
```

2. 选定默认方式
很显然，是``python``，即``/usr/bin/python``

3. 创建alternatives group
组名为python
```
$ sudo update-alternatives --install /usr/bin/python python /usr/bin/python2 100

$ sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 200
update-alternatives: using /usr/bin/python3 to provide /usr/bin/python (python) in auto mode

# 由于python3的优先级更高，所以当前执行``python``，就是python3了
$ python -V
Python 3.5.2
```
4. 手动指定程序
```
$ update-alternatives --config python
There are 2 choices for the alternative python (providing /usr/bin/python).

  Selection    Path              Priority   Status
------------------------------------------------------------
* 0            /usr/bin/python3   200       auto mode
  1            /usr/bin/python2   100       manual mode
  2            /usr/bin/python3   200       manual mode

Press <enter> to keep the current choice[*], or type selection number: 
```
输入对应数字即可完成自定义
