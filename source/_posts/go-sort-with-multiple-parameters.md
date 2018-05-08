---
title: Go自定义结构体多参数排序
date: 2018-05-07 17:34:58
tags: go
categories: go
---
用Go重构PHP代码
碰到了用``array_multisort``根据多个参数对数组排序的场景
于是写了个Demo来使用Go``sort``包进行测试
<!-- more -->

## 单一参数排序
单独以Order正序进行排序
```go
package main

import (
	"fmt"
	"sort"
)

type ItemT struct {
	Order int
	Age   int
	Name  string
}

type ItemsT []ItemT

func (p ItemsT) Len() int {
	return len(p)
}

func (p ItemsT) Less(i, j int) bool {
	return p[i].Order < p[j].Order
}

func (p ItemsT) Swap(i, j int) {
	p[i], p[j] = p[j], p[i]
}

func (p *ItemsT) Sort() {
	sort.Sort(p)
}

// 主函数
func main() {
	tmp := ItemsT{
		{
			Order: 10,
			Name:  "A",
			Age:   28,
		},
		{
			Order: 5,
			Name:  "B",
			Age:   57,
		},
		{
			Order: 5,
			Name:  "C",
			Age:   43,
		},
		{
			Order: 20,
			Name:  "D",
			Age:   16,
		},
		{
			Order: 1,
			Name:  "E",
			Age:   31,
		},
	}
	tmp.Sort()
	fmt.Printf("%+v", tmp)
}
```
输出（做了换行处理）
```
[
    {Order:1  Age:31 Name:E}
    {Order:5  Age:57 Name:B}
    {Order:5  Age:43 Name:C}
    {Order:10 Age:28 Name:A}
    {Order:20 Age:16 Name:D}
]
```

## 多参数排序
以Order参数正序排序，Age参数倒序排序
修改比较方法``Less``的逻辑
```go
func (p ItemsT) Less(i, j int) bool {
	if p[i].Order < p[j].Order {
		return true
	}
	if p[i].Order > p[j].Order {
		return false
	}

	return p[i].Age > p[j].Age
}
```

输出
```
[
    {Order:1  Age:31 Name:E}
    {Order:5  Age:57 Name:B}
    {Order:5  Age:43 Name:C}
    {Order:10 Age:28 Name:A}
    {Order:20 Age:16 Name:D}
]
```

## 参考链接
[Go Package -sort](https://golang.org/pkg/sort/#pkg-examples)
