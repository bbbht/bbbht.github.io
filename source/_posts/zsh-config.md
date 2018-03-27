---
title: Ubuntu中安装oh-my-zsh使用zsh
date: 2018-03-20 10:19:04
tags: 
    - zsh
    - oh-my-zsh
categories: zsh
---
已经习惯使用zsh来代替bash
zsh提供了大量有用且使用方便的插件和主题
默认情况下就开箱即用，配合oh-my-zsh更有了极大的可折腾性
目前主要使用插件来提供以下功能：
- 自动补全（常规补全及历史提示）
- 语法高亮（错误提示）
- 状态提醒（git以及命令执行错误码）
- 路径跳转

> git 插件会影响终端响应速度，尤其当项目较大

另外像``take``,``d``等命令也很给力

<!-- more -->
### 安装zsh
```sh
sudo apt-get -y install zsh wget
```
### 设置为默认shell
```sh
sudo chsh -s `which zsh`
```
### 安装oh-my-zsh
```sh
wget --no-check-certificate https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | sh
```
### 插件安装
```sh
# autojump
sudo apt-get install -y autojump
# zsh-autosuggestions
git clone git://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/plugins/zsh-autosuggestions
# zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git .oh-my-zsh/plugins/zsh-syntax-highlighting
```
### zsh配置
```sh
# cat ~/.zshrc
```
```sh
# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Enable 256 color
export TERM="xterm-256color"

# Path to your oh-my-zsh installation.
export ZSH=/home/bbbht/.oh-my-zsh

ZSH_THEME="ys"

# Add wisely, as too many plugins slow down shell startup.
plugins=(
gitfast
sudo
autojump
zsh-autosuggestions
zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# User configuration
alias ddnone="docker images | grep none | awk '{print \$3}' |xargs docker rmi"
alias hexo="docker exec hexo-server hexo"
alias glg="git log --graph --date-order --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %C(green)(%cn)%Creset %C(cyan)(%cr)%Creset' --abbrev-commit --date=relative"

# key bindings
bindkey "\e[1~" beginning-of-line
bindkey "\e[4~" end-of-line
bindkey "\e[5~" beginning-of-history
bindkey "\e[6~" end-of-history

# for rxvt
bindkey "\e[8~" end-of-line
bindkey "\e[7~" beginning-of-line
# for non RH/Debian xterm, can't hurt for RH/DEbian xterm
bindkey "\eOH" beginning-of-line
bindkey "\eOF" end-of-line
# for freebsd console
bindkey "\e[H" beginning-of-line
bindkey "\e[F" end-of-line
# completion in the middle of a line
bindkey '^i' expand-or-complete-prefix

# Fix numeric keypad  
# 0 . Enter  
bindkey -s "^[Op" "0"
bindkey -s "^[On" "."
bindkey -s "^[OM" "^M"
# 1 2 3  
bindkey -s "^[Oq" "1"
bindkey -s "^[Or" "2"
bindkey -s "^[Os" "3"
# 4 5 6  
bindkey -s "^[Ot" "4"
bindkey -s "^[Ou" "5"
bindkey -s "^[Ov" "6"
# 7 8 9  
bindkey -s "^[Ow" "7"
bindkey -s "^[Ox" "8"
bindkey -s "^[Oy" "9"
# + - * /  
bindkey -s "^[Ol" "+"
bindkey -s "^[Om" "-"
bindkey -s "^[Oj" "*"
bindkey -s "^[Oo" "/"

# options
unsetopt correct_all

setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first when trimming history.
setopt HIST_IGNORE_DUPS          # Don't record an entry that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.

# color options
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=10'
```

### 参考链接
[oh-my-zsh wiki](https://github.com/robbyrussell/oh-my-zsh/wiki)
