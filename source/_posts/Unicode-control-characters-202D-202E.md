---
title: Unicode不可见控制字符处理
date: 2019-02-28 19:30:55
tags: 
    - unicode
    - regex
categories: regex
---

公司产品有一个功能，通过excel导入手机号白名单  
输入的手机号在白名单中的用户才能进入页面正常使用  
有用户反馈，白名单内的手机号无法识别  
且手动输入不行，从白名单复制却可以  
最终是Unicode不可见字符的问题  
类似``U+202D U+202E``

<!-- more -->
原始字符如下，在0与1之间，正常是不可见字符  
但通过遍历输出字符Unicode嘛，得到特殊字符的Unicode码为``8027``，十六进制`202D`  
于是有了关键字，搜索发现有一种可能是从iPhone通讯录中复制的手机号会存在这种字符  
在神奇的windows 记事本中，空白处右键,选择“显示Unicode控制字符”，即可‭一睹庐山‎真面目
```
0‭138xxxx
```
几年前流行一时的w微信中“xx撤回一条消息并亲了你一口”的玩法，就是这类字符的功劳，只是现在已经被修复  
## 原因
又是对用户输入数据未过滤。。  
数据库是支持这种字符的，所以会被存储，原样输出  
而匹配的时候，手动输入是不包含特殊字符的，所以``=``是无法匹配的，造成白名单失效  

## 解决方法
###  正则提取
只提取用户提交手机号信息中的数字内容，如通过`\d`，但可能会影响业务逻辑，如带区号+的

###  过滤特殊字符
只将此类不可见Unicode控制字符全部过滤掉，不处理别的内容，要使用正则的字符类  
使用的是``\p{C}``，包括 Cc、Cf、Cs、Co 和 Cn 类别，即控制、格式、私用、未赋值的字符  
以下是测试Go代码  
```go
package main

import (
	"fmt"
	"regexp"
)

func main() {
	s := "‭1\n+王"
	for i, r := range s {
		fmt.Printf("%d %d %q \n", i, r, r)
	}
	fmt.Println("= = = = = =")
	re := regexp.MustCompile(`\p{C}`)
	s = re.ReplaceAllString(s, "")
	for i, r := range s {
		fmt.Printf("%d %d %q \n", i, r, r)
	}
}
```
输出
```
0 8237 '\u202d' 
3 49 '1' 
4 10 '\n' 
5 43 '+' 
6 29579 '王' 
= = = = = =
0 49 '1' 
1 43 '+' 
2 29579 '王' 
```
由此可见，``\p{C}``将不可见控制字符都匹配并替换为空字符串了，正常字符并未受影响  
这应该是比较好的解决方案了

## 参考链接
[Unicode控制字符 维基百科](https://zh.wikipedia.org/wiki/Unicode%E6%8E%A7%E5%88%B6%E5%AD%97%E7%AC%A6)  
[Unicode Regular Expressions](https://www.regular-expressions.info/unicode.html)  
[正则 字符类](https://baike.baidu.com/item/%E5%AD%97%E7%AC%A6%E7%B1%BB)