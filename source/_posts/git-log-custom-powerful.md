---
title: 自定义git log的图形化显示
date: 2018-03-27 17:19:29
tags: git
categories: 版本控制
---
习惯用命令行来使用git
使用IDE或者sourcetree等工具，不够轻量化
最常使用的``git log``命令显示的方式过于冗余，翻看起来费时费力
使用``--oneline``虽然是一行一个commit，但是少了太多细节
当然可以选择使用tig，但win下暂不能傻瓜式使用，后面再提
于是可以定制一个命令来满足需求
<!-- more -->

## 方案
```
git config alias.lg="log --pretty=format:'%C(red)%h%Creset %C(white)%s %C(yellow)%d %C(green)%an %C(cyan)%cr%Creset' --graph"
```

git log 常用参数

| 选项              | 说明                                                                                                |
| ----------------- | --------------------------------------------------------------------------------------------------- |
| -p                | 按补丁格式显示每个更新之间的差异                                                                    |
| --stat            | 显示每次更新的文件修改统计信息                                                                      |
| --shortstat       | 只显示 --stat 中最后的行数修改添加移除统计                                                          |
| --name-only       | 仅在提交信息后显示已修改的文件清单                                                                  |
| --name-status     | 显示新增、修改、删除的文件清单                                                                      |
| --abbrev-commit   | 仅显示 SHA-1 的前几个字符，而非所有的 40 个字符                                                     |
| --relative-date   | 使用较短的相对时间显示（比如，“2 weeks ago”）                                                     |
| --graph           | 显示 ASCII 图形表示的分支合并历史                                                                   |
| --pretty          | 使用其他格式显示历史提交信息。可用的选项包括 oneline，short，full，fuller 和 format（后跟指定格式） |
| -(n)              | 仅显示最近的 n 条提交                                                                               |
| --since, --after  | 仅显示指定时间之后的提交                                                                            |
| --until, --before | 仅显示指定时间之前的提交                                                                            |
| --author          | 仅显示指定作者相关的提交                                                                            |
| --committer       | 仅显示指定提交者相关的提交                                                                          |
| --grep            | 仅显示含指定关键字的提交                                                                            |
| -S                | 仅显示添加或移除了某个关键字的提交                                                                  |
有些是适用于特殊筛选需求的，而非常规列表展示
可用于列表的，固定命令配置的如下
### 定制显示内容``--pretty=format``
>``git log --pretty=format:"%h - %an, %ar : %s"``
> ca82a6d - Scott Chacon, 6 years ago : changed the version number
> 085bb3b - Scott Chacon, 6 years ago : removed unnecessary test
> a11bef0 - Scott Chacon, 6 years ago : first commit

常规选项

| 选项 | 说明                                        |
| ---- | ------------------------------------------- |
| %H   | 提交对象（commit）的完整哈希字串            |
| %h   | 提交对象的简短哈希字串                      |
| %T   | 树对象（tree）的完整哈希字串                |
| %t   | 树对象的简短哈希字串                        |
| %P   | 父对象（parent）的完整哈希字串              |
| %p   | 父对象的简短哈希字串                        |
| %d   | ref名称                                     |
| %an  | 作者（author）的名字                        |
| %ae  | 作者的电子邮件地址                          |
| %ad  | 作者修订日期（可以用 --date= 选项定制格式） |
| %ar  | 作者修订日期，按多久以前的方式显示          |
| %cn  | 提交者(committer)的名字                     |
| %ce  | 提交者的电子邮件地址                        |
| %cd  | 提交日期                                    |
| %cr  | 提交日期，按多久以前的方式显示              |
| %s   | 提交说明                                    |

> 注意提交者与作者的区别

以及``%Cxxx``的颜色控制
可选颜色
- normal
- black
- red
- green
- yellow
- blue
- magenta
- cyan
- white

可选属性
- bold
- dim
- ul
- blink
- reverse

加入自定义颜色配置，突出显示提交
``--pretty=format:'%C(red)%h%Creset %C(white)%s %C(yellow)%d %C(green)%an %C(cyan)%cr%Creset'``

### 展示分支关系``--graph``
显示branch的ascii图例
```
*   0a393e6fa6 
|\
| * 9c1e6222ba 
|/
*   7ddcda31f8 
|\
| * 8410487369 
| * 09cdcd9c0c 
| * b7b35ab996 
```

## 参考链接
[git log 文档](file:///D:/Applications/Git/mingw64/share/doc/git-doc/git-log.html)
[tig](https://github.com/jonas/tig)
