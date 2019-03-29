---
title: go 自定义Json序列化方法，处理字符串时的引号问题
date: 2019-03-29 17:11:17
tags: go
categories: go
---

由于数据要进行hash处理，所以输入输出处的使用处都需要进行修改  
一个方案是输入处进行decode，输出进行encode，改动幅度相当可观  
最终决定是定义一个新类型，并通过定义`UnmarshalJSON`和`MarshalJSON`方法来实现自动序列化/反序列化  

<!-- more -->
简单的demo
```golang
// HashIntID ...
type HashIntID int

// UnmarshalJSON ...
func (h *HashIntID) UnmarshalJSON(data []byte) (err error) {
	*h = HashIntID(funcA(data))
	return
}

// MarshalJSON ...
func (h HashIntID) MarshalJSON() ([]byte, error) {
	return []byte(funcB(h)), nil
}
```
结果 两个方法都失败  
通过断电调试，发现`UnmarshalJSON`参数`data`在数组的头尾都是`34`，即`"`双引号的十进制ASCII码  
所以问题是传入的参数是双引号包含的，需要去除后再使用`data`的数据  
```golang
if data[0] == '"' && data[len(data)-1] == '"' {
    data = data[1 : len(data)-1]
}
```
解决了反序列化后，序列化的错误也有了头绪，那就是缺少了`"`双引号包含，需要手动在返回值两端添加
```golang
[]byte(`"` + funcB(h) + `"`)
```
完整代码如下 
```golang
// HashIntID ...
type HashIntID int

// UnmarshalJSON ...
func (h *HashIntID) UnmarshalJSON(data []byte) (err error) {
    if data[0] == '"' && data[len(data)-1] == '"' {
        data = data[1 : len(data)-1]
    }
    // something todo ...
    *h = HashIntID(funcA(data))
    return
}

// MarshalJSON ...
func (h HashIntID) MarshalJSON() ([]byte, error) {
    // something todo ...
	return []byte(`"` + funcB(h) + `"`), nil
}
```

之前使用自定义序列化方法时，一般方法直接接受或返回了`[]byte`类型数据，这次hash处理的函数接收和返回的都是`string`类型，大意了  