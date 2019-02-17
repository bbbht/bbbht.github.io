---
title: go fmt.Sprintf字符串占位符输出引号
date: 2019-02-15 19:59:45
tags: 
	- fmt
	- go
categories: go
---

发现代码中竟存在大段json数据靠字符串拼接的方式完成，着实尴尬  
通过修改记录追溯，果然是从一个小数据量逐渐增量的  
如今出了bug才暴露问题  
看来’前辈们‘信奉的是**又不是不能用.jpg**

<!-- more -->
有客户反映数据缺失，发现是json格式不规范，数据被直接丢弃，蒸发了  
之前的json数据是字符串拼接而成，发送给另一个服务，然后解析不了，因为数据中存在未转义的双引号`"`  
拼接时字符串的占位符是`%s`   
异常数据的生成过程形如
```go
name := `老"三'家`
postData := fmt.Sprintf("{\"name\":\"%s\"}", name)
```

fmt.Sprintf的部分占位符使用
```
%s 	直接输出原始字符串
%q 	字符串由双引号包裹，字符串中的双引号会带转义符
%#q	字符串由反引号包裹，如果字符串内有反引号，则用双引号包裹
```
示例

```go
package main

import (
	"fmt"
)

func main() {
	var input string
	fmt.Scanln(&input)
	fmt.Printf("%s\n", input)
	fmt.Printf("%q\n", input)
	fmt.Printf("%#q\n", input)
}
```
运行
```
$ go run main.go
"'	// input
"'
"\"'"
`"'`

$ go run main.go
`"'`	// input
`"'`
"`\"'`"
"`\"'`"
```

## 原因
1. 入库数据未转义，直接使用用户输入的数据是个致命伤
2. 编码不规范，json数据靠字符串拼接，除了引号，还有花括号等问题会被暴露，只是时间问题
3. 数据解析错误没有记录日志

编码不规范，程序泪两行。。。

## 解决方法
使用`%q`做占位符只是治标不治本，这个场景不合适  

1. 不能信任用户输入，包括第三方接口提供
2. 编码要规范，应通过对`map struct`或其它自定义类型，调用`json.Marshal`或自定义序列化方法来实现json输出

历史遗留的这些安全问题，目前还是通过解决暴露的bug来排雷，牵涉面还很广，十分尴尬的境地

## 参考链接
[Package fmt](https://golang.org/pkg/fmt/)