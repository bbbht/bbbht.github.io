---
title: 修改已提交的git仓库中commit作者信息（name,email）
date: 2018-02-27 15:10:57
tags: git
categories: 版本控制
---

## 问题描述
通过``hexo deploy``推送到github pages上的文章，访问正常，没来得及高兴就发现了问题。  
因为仓库中的commit信息是公司项目中配置的信息！

<!-- more -->

## 原因
没有为项目做git上的配置，于是使用了全局的git配置。

## 解决方法
将所有错误的name，email修改为正确的配置。
发现两种方案

a. 通过`` git rebase -i `` 命令 重写历史
```sh
# 选择修改范围
git rebase -i HEAD~n
```
输出如下
```
pick 208d348 XXX
pick c99c75e CCC
pick 35c4d4c FFF

# Rebase 02097a2..35c4d4c onto 02097a2 (3 commands)
#
# Commands:

```
将要修改的提交所在行 pick 改为 e 保存退出
```sh
# 通过命令一条一条修改
git commit --amend --author "username <abcdef@gmail.com>"
git rebase --continue
```
直至
```sh
git rebase --continue
Successfully rebased and updated refs/heads/master.
```
当修改条目过多时并不方便，且尝试中发现第一条提交（First commit）无法修改，因此并未使用

b. 通过`` git filter-branch ``命令 配合脚本完成
从网上找到脚本如下

```sh
#!/bin/sh

git filter-branch --env-filter '
OLD_EMAIL="your-old-email@example.com"
CORRECT_NAME="Your Correct Name"
CORRECT_EMAIL="your-correct-email@example.com"

if [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_COMMITTER_NAME="$CORRECT_NAME"
    export GIT_COMMITTER_EMAIL="$CORRECT_EMAIL"
fi
if [ "$GIT_AUTHOR_EMAIL" = "$OLD_EMAIL" ]
then
    export GIT_AUTHOR_NAME="$CORRECT_NAME"
    export GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
fi
' --tag-name-filter cat -- --branches --tags

# Rewrite 35c4d4c3e8b675d7b4b555dce3cff975366f5cf8 (3/4) (1 seconds passed, remaining 0 predicted)
# Ref 'refs/heads/master' was rewritten
```
简单直接，最终使用此方案完成了修改
然后push即可
```
git push --force --tags
# 也可指定远程仓库
# git push --force --tags origin 'refs/heads/*'

# Everything up-to-date
```

## 预防措施
1. 在_config.yml中显式地增加配置
```yml
deploy:
  type: git
  repository: git@github.com:bbbht/bbbht.github.io.git
  branch: master
  name: bbbht
  email: plateau.loess@gmail.com
```

2. 在git仓库中进行设置
```sh
git config user.name bbbht
git config user.email plateau.loess@gmail.com
```

## 参考链接
[Git Tools - Rewriting History](https://git-scm.com/book/en/v2/Git-Tools-Rewriting-History)
[hexo-deployer-git配置](https://github.com/hexojs/hexo-deployer-git)
