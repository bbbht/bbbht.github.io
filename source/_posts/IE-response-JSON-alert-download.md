---
title: IE9 接口返回json数据，提示下载
date: 2018-10-19 14:08:47
tags: ie
categories: other
---

给前端提供的上传接口，反馈说IE9中上传失败，其他浏览器都OK  
其实是成功了，只是响应没有被正确处理，被浏览器当做下载文件处理了  


<!-- more -->
接口方法为`POST`，`Content-Type: multipart/form-data;`  
响应为`Content-Type: application/json; charset=UTF-8`

## 原因
问题出在服务器的响应头的`Content-Type`，  
IE9及以下版本，好像不能处理json类型，  
然后未知类型都被当做下载处理了，于是就造成接口失败的现象了

## 解决方法
修改响应头的`Content-Type`  
根据请求的`userAgent`判断，如果包含`MSIE 9.0`（IE9）,`MSIE 8.0`（IE8），则将`Content-Type`修改为`Content-Type: application/text/html; charset=UTF-8`即可  
不会对前端造成影响  

