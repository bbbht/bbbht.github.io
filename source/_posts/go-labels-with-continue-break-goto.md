---
title: go循环控制（break label，continue label，goto label）
date: 2019-02-12 16:09:12
tags: go
categories: go
---

都知道`goto`不可亵玩焉，逻辑跳跃，不易维护云云。  
但存在深层嵌套的场景下，`continue break goto`配合label的合理使用，也不失为简化代码逻辑的好方法  

<!-- more -->

- Goto statements
> A "goto" statement transfers control to the statement with the corresponding label within the same function.

- Continue statements
> A "continue" statement begins the next iteration of the innermost "for" loop at its post statement. The "for" loop must be within the same function.

- Break statements
> A "break" statement terminates execution of the innermost "for", "switch", or "select" statement within the same function.

如果不配合label，直接使用break和continue，则只在终止或跳过当前循环

代码示例
```go
func main() {
LABEL_1:
	for i := 0; i < 10; i++ {
		if i == 8 {
			goto END
		}
		if i%2 == 0 {
			for {
				continue LABEL_1
			}
		}
		index := 0
	LABEL_2:
		for {
			index++
			fmt.Println("index ", index)
			break LABEL_2
		}
		fmt.Println("i ", i)
	}
	fmt.Println("after loop")
END:
	fmt.Println("end")
}
```
break和continue的label必须写在代码块的前面  
其中，break label 将直接跳出循环，即不再执行label所标记的循环  
而continue label 则将继续执行循环，即开始下一次循环
输出
```
index  1
i  1
index  1
i  3
index  1
i  5
index  1
i  7
end
```

## 参考链接
[The Go Programming Language Specification](https://golang.org/ref/spec#Break_statements)