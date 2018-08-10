---
title: git log -S -G 根据内容变化查找
date: 2018-08-10 17:01:42
tags: git
categories: git
---

``git log``用的非常频繁，指定分支，指定文件等等  
不过``-G``和``-S``参数的差异没搞清楚，导致查找特定提交时废了不少时间

<!-- more -->

## 使用场景
查找包含特定字符的某处代码被修改的记录时，很合适，比如某个函数什么时候添加和修改的，等等    

## 对比
``-G``是查正则的。查文本用``-S``，但``-S``可以使用``–pickaxe-regex``修改为接受正则表达式  

> To illustrate the difference between -S<regex> --pickaxe-regex and -G<regex>, consider a commit with the following diff in the same file:
> ```
> +    return !regexec(regexp, two->ptr, 1, &regmatch, 0);
> ...
> -    hit = !regexec(regexp, mf2.ptr, 1, &regmatch, 0);
> ```
> While git log -G"regexec\(regexp" will show this commit, git log -S"regexec\(regexp" --pickaxe-regex will not (because the number of occurrences of that string did not change).

### ``-S``
查找的结果，是匹配的 **字符串出现的次数发生变化** 的提交  
比如，出现，被删除等  
某次提交将``abcdef``,修改为``abcd``, 使用``git log -Sabc``将不会查找出此提交，使用``git log -Sabcde``可以查找出
### ``-G``
没有次数变化的限制，只要变化就会查找出对应的提交

当然，如果是要查找commit msg中包含特定信息的提交而非内容，则应使用``git log --grep='穿山甲说的是'``

## 参考链接
[How to grep Git commit diffs or contents for a certain word?](https://stackoverflow.com/questions/1337320/how-to-grep-git-commit-diffs-or-contents-for-a-certain-word)
[Git - git-log Documentation](https://git-scm.com/docs/git-log)
