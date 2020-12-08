---
title: go中跳出多层循环continue、break、goto示例
date: 2020-12-08 19:15:32
tags: go
categories: go
---
维护代码时发现发现前人艺高人胆大，GOTO满天飞，着实费了力气才勉强理清了逻辑  
由于未曾在生产中使用过GOTO及break、continue来实现多层跳出，所以写个demo记录学习下
<!-- more -->

## 示例代码
```go
func main() {
	fmt.Println("start")
LOOP1:
	for j := 0; j < 10; j++ {
		fmt.Println("leve 1: in ", j)
	LOOP2:
		for i := 0; i < 10; i++ {
			time.Sleep(time.Second)
			fmt.Println("level 2: in ", i, j)
			if i == 1 {
				fmt.Println("continue LOOP2")
				continue LOOP2
			}
			if i == 3 {
				fmt.Println("continue LOOP1")
				continue LOOP1
			}
			if j == 1 {
				fmt.Println("break LOOP2")
				break LOOP2
			}
			if j == 2 {
				fmt.Println("goto GOTO1")
				goto GOTO1
			}
			if j == 3 {
				fmt.Println("goto GOTO2")
				goto GOTO2
			}
			fmt.Println("level 2: over ", i, j)
		}
GOTO1:
		fmt.Println("leve 1: out ", j)
	}
	fmt.Println("before GOTO2")
GOTO2:
	fmt.Println("over")
}
```

## 输出
```
start
leve 1: in  0
level 2: in  0 0
level 2: over  0 0
level 2: in  1 0
continue LOOP2
level 2: in  2 0
level 2: over  2 0
level 2: in  3 0
continue LOOP1
leve 1: in  1
level 2: in  0 1
break LOOP2
leve 1: out  1
leve 1: in  2
level 2: in  0 2
goto GOTO1
leve 1: out  2
leve 1: in  3
level 2: in  0 3
goto GOTO2
over

Process finished with exit code 0
```

## 捎带
### break label 
- label必须写在代码块的前面
- 直接跳出循环，即不再执行label所标记的循环
  - `break LOOP2` 之后 输出 `leve 1: out  1`，即是跳出了内部的for循环
### goto label
- 直接跳到label处执行，中间环境忽略
  - `before GOTO2` 并未打印，被跳过不执行
### continue label
- label必须写在代码块的前面
- 继续执行下一次的循环，忽略本次循环后续的所有逻辑