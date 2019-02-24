---
title: go redis can't marshal xxx (implement encoding.BinaryMarshaler)
date: 2019-02-24 15:16:37
tags: 
    - go
    - redis
categories: go
---

在go项目中使用redis时，难免要使用`Get/Set`存取一些复杂的数据结构  
直接缓存会报错  
```
redis: can't marshal xxx (implement encoding.BinaryMarshaler)
```
xxx为对应的数据结构  
此时就要自定义一些方法来解决了

<!-- more -->
当前使用的redis客户端为 [go-redis](https://github.com/go-redis/redis) v6  
需要为缓存的对象添加两个方法，`go-redis`会自动应用  
```
MarshalBinary() ([]byte, error)
UnmarshalBinary(data []byte) error
```
在其中实现序列化与反序列化的方法即可，一般使用json库  
当然为了性能考虑，也可以使用其它更高效的库，如msgpack，benchmark有5-10倍提升  
```
BenchmarkStructVmihailencoMsgpack-4   	  200000	     12814 ns/op	    2128 B/op	      26 allocs/op 
BenchmarkStructUgorjiGoMsgpack-4      	  100000	     17678 ns/op	    3616 B/op	      70 allocs/op 
BenchmarkStructUgorjiGoCodec-4        	  100000	     19053 ns/op	    7346 B/op	      23 allocs/op 
BenchmarkStructJSON-4                 	   20000	     69438 ns/op	    7864 B/op	      26 allocs/op 
BenchmarkStructGOB-4                  	   10000	    104331 ns/op	   14664 B/op	     278 allocs/op 
```
## Example
```golang
package main

import (
    "fmt"
    "time"
    "github.com/go-redis/redis"
    "github.com/vmihailenco/msgpack"
)

func main() {
    client := redis.NewClient(&redis.Options{
        Addr:     "192.168.0.1:6379",
        Password: "kljsdfslkdfj",    // password 
        DB:       0,                // use default DB
    })

    pong, err := client.Ping().Result()
    fmt.Println(pong, err)
    
    fmt.Println(client.Set("cache1", &something{100, "101"}, time.Second*1).Result())
    fmt.Println(client.Get("cache1").Result())
}

type something struct {
    ID      int
    Name    string
}

func (s *something) MarshalBinary() ([]byte, error) {
	return msgpack.Marshal(s)
}

func (s *something) UnmarshalBinary(data []byte) error {
	return msgpack.Unmarshal(data, s)
}
```
还有复杂对象取地址传参，不然还是会报错
```
 redis: can't marshal xxx (implement encoding.BinaryMarshaler)
```

## 参考链接
[go-redis](https://github.com/go-redis/redis)  
[go-redis issues](https://github.com/go-redis/redis/issues/16)  
[msgpack](https://github.com/vmihailenco/msgpack)  