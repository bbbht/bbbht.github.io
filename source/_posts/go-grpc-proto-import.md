---
title: 通过import的方式复用proto来使用grpc
date: 2021-07-16 17:30:11
tags: 
    - go
    - grpc
categories: go
---
需求是多个后端服务提供grpc接口及proto文件，之前上层服务各自调用，分散且难以管理  
所以选择重构，后端服务据说没有人手，不会做任何改动，但目标是实现故障转移、服务注册发现、负载均衡、任务泄露检测等  
其中就涉及要复用proto的要求，本来简单的事由于掉进前人坑中，也只好记录下，增加点教训  
<!-- more -->
整体方案简述：以slidecar模式给后端服务提供一个容器，主要负责服务注册，增加一个中间层，负责服务发现，然后通过rpc接口进行实际访问，并记录任务在哪台机器  
上层服务直接调用中间层，中间层记录、处理，确认有足够资源后，转发上层服务的请求到后端服务，上层不需要关心任务被分配到了哪台机器  
问题出在上层访问中间层的方式，要尽量保持请求方接口、参数、方式的不变以减少开发量。故提出一个方案，即复用proto，上层请求中间层时就使用后端服务的消息定义  
方案很简单，但使用起来是出了点问题  
1. proto文件定义老旧，没有任何option，当前protobuf版本1.27必须设置`option go_package`才能使用import功能
2. package命名空间冲突，之前全部都是定义`package proto`完全没有区分度，导致消息定义冲突，直接panic，导致无法使用，必须修改package定义

## 解决方法
由于有多个后端服务，故有多个proto文件，所以使用循环方式来生成，结构如下   
其中 mix就是混合复用的proto了
```
├── go.mod
├── go.sum
├── main.go
├── ........
└── proto
    ├── mix
    │   └── mix.pb.go
    ├── mix.proto
    ├── a
    │   └── a.pb.go
    ├── a.proto
    ├── ........
    ├── c
    │   └── c.pb.go
    └── c.proto
```
mix.proto格式  
增加A、B前缀是为了增加区分度，将所有的方法定义整合到一个service中
```proto
syntax = "proto3";

package mix;
option go_package = "xxx/xxx/proto/mix";

import "a.proto";
import "b.proto";
import "c.proto";
import ....

service Dispatch {
    rpc Arpc_1 (a.In_1) returns (a.Out_1) {}
    rpc Arpc_2 (a.In_2) returns (a.Out_2) {}

    rpc Brpc_1 (b.In_1) returns (b.Out_1) {}
    rpc Brpc_2 (b.In_2) returns (b.Out_2) {}

    ......
}
```

举例a.proto格式
```
syntax = "proto3";

package a;
option go_package = "xxx/xxx/proto/a";

service A {
    rpc rpc_1 (In_1) returns (Out_1) {}
    rpc rpc_2 (In_2) returns (Out_2) {}

    .......
}
```
这样就只需要将之前直接调用方法加上前缀，再去掉一些由中间层处理的逻辑即可，做减法了，工作量大幅减少  

使用的是makefile来生成，`@`是为了屏蔽命令回显，无视即可  
其中由个重要配置项 `paths=source_relative`，配合 `go_package`才能实现proto复用的目标  
实际上 paths 参数有两个可选项，`import`（默认值）/`source_relative`   
import则代表按照生成的 go 代码的包的全路径去创建目录层级，会造成生成很深的层级目录；source_relative 则是按照 proto 源文件的目录层级去创建 pb.go 代码的目录层级，如果目录不存在需要手动创建。
```makefile
PROTO_PATH=proto/
PROTO_FILES=$(shell find ${PROTO_PATH} -maxdepth 1 -type f -name '*.proto')

genprotos:
	@for proto_file in ${PROTO_FILES}; do \
 		echo "Generating protobuf for" $$proto_file; \
 		proto_name=`basename $$proto_file .proto`; \
#  		echo $$proto_name; \
 		mkdir -p ${PROTO_PATH}$$proto_name; \
		protoc -I${PROTO_PATH} --go_out=plugins=grpc,paths=source_relative:${PROTO_PATH}$$proto_name $$proto_file; \
	done;
```

## 题外话
IDE是goland，本来已经安装了插件`Protocol Buffer Editor`，本来好好的，但加入import语句后，就一致报错 `Cannot resolve import 'xxx.proto'`  
实际上是IDE默认的配置导致的无法找到proto路径，需要改为手动配置proto文件目录  
具体路径为 `进入settings -> Languages & Frameworks -> Protocol Buffers`，取消勾选 `Configure automatically` ，然后手动添加proto文件所在的目录即可