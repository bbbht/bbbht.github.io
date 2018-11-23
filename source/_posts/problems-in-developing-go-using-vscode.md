---
title: 使用vscode开发Go过程中遇到的问题
date: 2018-11-23 16:49:27
tags: 
    - go
    - vscode
categories: vscode
---

最近做Go开发还是使用vscode作为主力开发工具  
感觉碰到的一些问题需要整理记录下  
有些问题每次都鼓捣半天，虽能解决，却也无确切解释

<!-- more -->
## Vscode Go相关的配置
```json
{
  "go.formatTool": "goreturns",
  "go.buildOnSave": "off",
  "go.vetOnSave": "package",
  "go.inferGopath": true,
  "go.useCodeSnippetsOnFunctionSuggest": true,
  "go.useCodeSnippetsOnFunctionSuggestWithoutType": false,
  "go.lintTool": "gometalinter",
  "go.lintOnSave": "package",
  "go.lintFlags": [
    "--fast",
    //"--debug",
    "-Dgotype",
    "-Dgas",
    "--exclude=should be",
    "--exclude=declaration of \"err",
    "--exclude=should have comment"
  ],
  "go.liveErrors": {
    "enabled": true,
    "delay": 500
  },
  "go.addTags": {
    "tags": "json",
    "options": "",
    "promptForTags": true,
    "transform": "snakecase"
  },
  "go.autocompleteUnimportedPackages": true,
  "go.editorContextMenuCommands": {
    "toggleTestFile": true,
    "addTags": true,
    "removeTags": false,
    "testAtCursor": true,
    "testFile": true,
    "testPackage": false,
    "generateTestForFunction": false,
    "generateTestForFile": false,
    "generateTestForPackage": false,
    "addImport": false,
    "testCoverage": true,
    "playground": false
  }
}
```
## 自动完成/自动提示很慢
### 现象
自动提示很慢，延时会有四五秒左右  
尤其外部依赖包，甚至无法提示

### 原因
应该是`GOPATH`造成的，尤其是项目多，又没有独立设置`GOPATH`，造成大量的包冗余  
当并未验证

### 解决方案

设置`"go.inferGopath": true`
这项设置会覆盖`go.gopath`  
会自动包含全局的`GOPATH`，以及项目上层目录  

## gotype can't find import
### 现象
开启了动态检查配置
```json
  "go.liveErrors": {
    "enabled": true,
    "delay": 500
  }
```
然后会有一些import内容报错
```
could not import git.xxx.tv/xxx/web/model (can't find import: "git.xxx.tv/xxx/web/model")
```
其实是本项目内的相对路径  

### 原因
在`vscode`项目的issues中，挖掘到了一个相似的问题，vendor中的包报错  
但并未发现原因  
> ramya-rao-a commented on 5 Dec 2017  
> Closing this as this is an upstream issue with gotype and we there is nothing much we can do from the extension's perspective.

### 解决方案
issues讨论列表中，有提到
> I ran gotype-live -a ./, it showed the exact errors

运行`gotype-live -a ./`后，报出了准确的错误所在，所以应该并非不能找到包，而是其他错误导致的  
但运行后并无报错  
1. 开启`"go.vetOnSave": "package"`后，问题解决，会出现import错误，但vet运行后自动消失    
2. 开启保存自动编译，`"go.buildOnSave": "on"`，代替liveErrors

### 参考链接
[Live error reporting says can't find import:](https://github.com/Microsoft/vscode-go/issues/1239)