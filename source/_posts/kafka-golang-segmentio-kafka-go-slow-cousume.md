---
title: 使用kafka-go导致的消费延时问题
date: 2020-12-28 20:42:57
tags: 
    - kafka
    - go
categories: kafka
---

重新部署了一个项目，其中通过 kafka 来实现异步通知的服务环节变得十分慢，甚至达到 10s，虽说是异步通知，但又对时延要求很低，所以完全是无法使用的一个状态  
问题在于线上完全相同的代码，却没有这么高的延时

<!-- more -->
服务为 Go 所写，kafka的客户端使用的是 [kafka-go](https://github.com/segmentio/kafka-go)，运行有两年了，期间并未有类似反馈。
## 原因
刚开始是怀疑网络有问题，但各个服务器登录之后 ping 或者 curl 直接访问都是毫秒级的，然后在服务中加入了请求耗时的debug日志，也显示耗时是正常的。   
使用其它客户端对同一topic进行 publish consume 测试，也基本正常  
于是排查的重点到了客户端，并且在这里定位到了最终原因  
代码中的 producer 及 consumer，居然全部是 Github 的 demo ！！

```go
w := &kafka.Writer{
	Addr:     kafka.TCP("localhost:9092"),
	Topic:   "topic-A",
	Balancer: &kafka.LeastBytes{},
}

err := w.WriteMessages(context.Background(),
	kafka.Message{
		Key:   []byte("Key-A"),
		Value: []byte("Hello World!"),
	},
	kafka.Message{
		Key:   []byte("Key-B"),
		Value: []byte("One!"),
	},
	kafka.Message{
		Key:   []byte("Key-C"),
		Value: []byte("Two!"),
	},
)
if err != nil {
    log.Fatal("failed to write messages:", err)
}

if err := w.Close(); err != nil {
    log.Fatal("failed to close writer:", err)
}
```

```go
// make a new reader that consumes from topic-A, partition 0, at offset 42
r := kafka.NewReader(kafka.ReaderConfig{
    Brokers:   []string{"localhost:9092"},
    Topic:     "topic-A",
    Partition: 0,
    MinBytes:  10e3, // 10KB
    MaxBytes:  10e6, // 10MB
})
r.SetOffset(42)

for {
    m, err := r.ReadMessage(context.Background())
    if err != nil {
        break
    }
    fmt.Printf("message at offset %d: %s = %s\n", m.Offset, string(m.Key), string(m.Value))
}

if err := r.Close(); err != nil {
    log.Fatal("failed to close reader:", err)
}
```
问题就出在这里了，还是太年轻，没想到公司的生产代码居然是个 demo ！  
在kafka-go的源码中，Writer的配置项 `BatchTimeout` 的默认配置是 1s，也就是每 1s 会批量的发送一次消息到`broker`，此配置结合 `BatchSize` （kafka-go中默认值为 100），整体逻辑就变为：要么达到发送间隔，要么达到发送量才会真正发送到 broker。由于新部署的的项目数据量很小，所以发送环节就会有最大1s的延时了。然而更大的问题在 consumer 端。  
ReaderConfig 配置中，有两个配置影响到了消费速度：`MinBytes`（不设置会使用 MaxBytes，max默认值 1M），`MaxWait`（默认值 10s）。  
简单来说，就是broker根据这两个配置来进行决策，要么是有足够的数据，要么是等待了足够长的时间。  


## 解决方法
kafka-go确实改变了不少 kafka 本身的默认配置，着实让人头大，还需要把其它配置过一遍，否则还是有隐患存在
1. Reader的配置中增加 `BatchTimeout`，`BatchSize`  
BatchSize 保持默认值不变，100条；BatchTimeout 修改为 100ms；
2. Writer的配置中增加 `MaxWait`，配合 `MinBytes`  
MaxWait 调整为500ms，MinBytes 设置为 1 （有消息就返回）

## kafka配置对应关系
1. BatchTimeout
linger.ms  
如果消息的大小一直达不到batch.size设置的值，那么等待多久后任然允许发送消息
2. BatchSize
batch.size   
当多条消息被发送到同一个分区时，生产者会尝试把多条消息变成批量发送。这有助于提高客户端和服务器的性能。  
值设置的太小，可能会降低吞吐量   
参数设置的太大，可能会更浪费内存，并增加消息发送的延迟时间  
配置为消息体积，而非条数，单位为字节
3. MaxWait
fetch.max.wait.ms  
如果没有足够的数据立即满足fetch.min.bytes提供的要求，服务器在响应fetch请求之前将阻塞的最长时间
5. MinBytes
fetch.min.bytes  
服务器应该为获取请求返回的最小数据量。如果没有足够的数据可用，请求将等待那么多数据累积后再响应请求