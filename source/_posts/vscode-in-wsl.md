---
title: 在WSL中使用VSCode
date: 2019-01-28 09:43:40
tags: 
    - vscode
    - wsl
categories: vscode
---
当前编辑器是在windows环境使用，但go开发过程中，一些项目的依赖如`libkafka`等，很难在win下安装  
所以需要在linux下配置临时开发环境来解决  
当前win10版本的wsl，配合X-Server已经可以胜任  
<!-- more -->
## 1. 安装wsl
无需多言，安装就是了

## 2. 安装X-Server
选择了XcXsrv，免费  
1. windows那边，全部默认选项即可
2. wsl中配置安装
    - 因为使用的是zsh，所以`echo 'export DISPLAY=:0.0' >> ~/.zshrc`
    - `sudo apt install x11-apps -y`
    - `xeyes` 然后应该会有一双盯着鼠标的大眼睛出现

## 3. 安装VSCode
1. 安装VScode，使用官方dep
    - `sudo dpkg -i /path/to/code/deb`
    - `sudo apt install -f`

2. 配置同步，通过Sync Setting 扩展

3. 如果之前没安装过中文字体，VSCode中中文会显示为方块
    - `sudo apt-get install fonts-droid-fallback ttf-wqy-zenhei ttf-wqy-microhei fonts-arphic-ukai fonts-arphic-uming`
    - `sudo fc-cache -f -v`
    - 需要的话，注销一下

## 4. Go环境配置
1. 安装go
2. 修改环境变量
    - GOPATH最好跟win下配置一致，通过软连接处理就好

3. 安装libkafka等依赖
```sh
git clone https://github.com/edenhill/librdkafka.git /tmp/librdkafka && \
    cd /tmp/librdkafka && \
    ./configure  --prefix /usr && \
    make && make install
```

## 4. 启动
1. 启动XcXsrv
2. 进入wsl，输入`code`
3. 也可以配置XcXsrv菜单，配合remoteexec.vbs自动启动，不折腾了

## 参考链接
[XcXsrv](https://sourceforge.net/projects/vcxsrv/)