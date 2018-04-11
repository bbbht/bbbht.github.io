---
title: trasn cli linux
date: 2018-04-11 14:23:33
tags: 
    - trash-cli
    - bash
categories: linux
---
``rm -rf /``的故事屡见不鲜
已习惯使用``trash``代替了``rm``命令
防患于未然吧

<!-- more -->

## 安装
```bash
sudo apt-get install -y python-pip
sudo pip install trash-cli
```

## 使用
| command       | description                                |
| ------------- | ------------------------------------------ |
| trash-put     | trash files and directories.               |
| trash-empty   | empty the trashcan(s).                     |
| trash-list    | list trashed files.                        |
| trash-restore | restore a trashed file.                    |
| trash-rm      | remove individual files from the trashcan. |

### rm别名
设置rm别名，加入~/.bashrc 或 ~/.zshrc
```bash
alias rm='echo "This is not the command you are looking for."; false'
```
一定要使用``rm``的时候
```bash
\rm file-without-hope
```

## 参考链接
[trash-cli - Command Line Interface to FreeDesktop.org Trash](https://github.com/andreafrancia/trash-cli)
