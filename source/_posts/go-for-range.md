---
title: golang的for-range的注意点
date: 2019-01-30 20:31:42
tags: go
categories: go
---

年底重构抢公司红包业务代码，解决了不少历史遗产bug  
其中一些是很常见的问题，如并发读写map，for-range中取地址，闭包defer等  
业务结果居然是正确的。。。

<!-- more -->

有并发大触发的并发读写map的致命错误（ fatal error: concurrent map read and map write）  
此bug并未引起关注，因为会自动重启。。。

defer执行闭包的赋值问题也是频频出现，好在鲜有需要执行闭包的错误发生,单独记录  

还有个错误是for循环中取地址的问题，倒是在转换数据结构的时候，也踩进了坑

## 原因
实际上就是对赋值的误解，误以为每次生成新的变量，相应的还有go函数的参数值传递相关的误解  

超级简化版的例子，形如
```go
package main

import "fmt"

func main() {
	bar := []int{1, 2, 3}
	for index, value := range bar {
		fmt.Printf("%d %p %d\n", index, &value, value)
	}
}
```
输出
```
0 0xc00004e080 1
1 0xc00004e080 2
2 0xc00004e080 3
```
所以原因就是value变量并非每次循环生成一个新的变量，而只是重新赋值  
所以如果将``&value``的地址始终不变，如果将地址赋值给别的变量，则最终指向同一个地址  
如果是使用循环外部变量，也存在这个问题，因为都是同一个变量  

## 解决方法
1. 在循环内赋值给一个新变量
```go
for index, value := range bar {
    foo := value
    fmt.Printf("%d %p %d\n", index, &foo, value)
}
```

```
0 0xc00004e080 1
1 0xc00004e098 2
2 0xc00004e0d0 3
```

2. 直接使用索引取值
只是举个栗子，不能这么取址玩
```go
for index, value := range bar {
    fmt.Printf("%d %p %d\n", index, &bar[index], value)
}
```
```
0 0xc00004c0c0 1
1 0xc00004c0c8 2
2 0xc00004c0d0 3
```
