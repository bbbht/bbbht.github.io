---
title: nginx对url添加斜杠并301跳转
date: 2018-07-12 12:28:39
tags: nginx
categories: nginx
---

用不同的端口来模拟多个测试环境，结果发现非80端口的链接总会跳转到80端口  
通过开发者工具记录网络请求发现发生了301跳转  
且链接末尾会被加上``/``  
``127.0.0.1:82/action`` -> ``127.0.0.1/action/``

<!-- more -->

## 原因
由nginx所引发的问题  
当处理不以``/``结尾的请求，如果``nginx配置的root``目录下没有对应的文件，nginx会重定向到该目录，即结果是自动添加结尾的``/``  

## 解决方法

1. port_in_redirect
当配置为on，即开启状态，重定向时会将当前nginx监听端口号带入，关闭即可，配置为off  
相似的还有``server_name_in_redirect``配置
```
port_in_redirect off;
```

2. 在链接结尾加上``/``
