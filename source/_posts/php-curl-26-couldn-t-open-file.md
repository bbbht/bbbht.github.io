---
title: php curl 上传文件报错 26 couldn't open file
date: 2018-11-09 11:55:26
tags: curl
categories: php
---
用PHP的curl进行文件中转上传，发生了错误
> curl: (26) couldn't open file

<!-- more -->

## 原因
POST 方法上传文件，文件上传方式
```php
$file = new \CurlFile($filpath);
```
其中``$filepath``使用了相对路径
## 解决方法
调用``CurlFile``时，使用文件的绝对路径
## 参考链接
[stackoverflow.com](https://stackoverflow.com/questions/23730283/curl-26-couldnt-open-file)
