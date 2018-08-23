---
title: go 字符串包含%调用fmt.Sprintf导致错误
date: 2018-08-23 10:25:04
tags: go
categories: go
---
出现错误`'%!s(MISSING)`  
是调用`fmt.Sprintf`时出了错，字符串中包含了`%`  
<!-- more -->

## 原因
原因很简单，调用`fmt.Sprintf`时，未做任何处理  
由于业务中`%`是允许的，会被Go误以为占位符，导致问题出现

## 解决方法
由于不使用转义，所以在调用`fmt.Sprintf`前，多一次处理即可  
```go
template = strings.Replace(template, "%", "%%", -1)
```
将单个的`%`转换为`%%`，而`%%`又会被当做字面`%`打印，避免问题出现
