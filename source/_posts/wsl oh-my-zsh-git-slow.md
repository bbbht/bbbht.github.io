---
title: WSL2使用oh-my-zsh在git仓库中响应缓慢的问题
date: 2021-01-11 13:42:55
tags: 
    - wsl
    - oh-my-zsh
categories: zsh
---
WSL2使用起来很方便，但有个问题一直都在  
那就是在git仓库中，命令行会卡住，执行git相关命令也会等待很久  
最近有同事来问解决方案，记录分享下  
<!-- more -->
oh-my-zsh主题带有git相关信息，导致git相关的命令响应缓慢
## 原因
具体原因就不分析了，还是文件系统的问题吧，  
## 解决方法
1. 禁用相关插件或展示  
禁用后命令行讲不展示git相关信息，如果不需要，那就禁用，或者更换主题也是不错的选择
```sh
# 禁用 git_prompt_info()
git config --add oh-my-zsh.hide-status 1
# 禁用 parse_git_dirty()
git config --add oh-my-zsh.hide-dirty 1
```
2. 调用Windows中的Git
在`$ZSH/oh-my-zsh.sh`文件中，增加所需的函数  
原理为当处于`/mnt/`（外挂Windows目录，按需修改）时，调用Windows下的git命令，绕过文件系统的差异  
```sh
function git() {
  if $(pwd -P | grep -q "^\/mnt\/*"); then
    git.exe "$@"
  else
    command git "$@"
  fi
}
```
