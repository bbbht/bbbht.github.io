---
title: go debug requests is already registered
date: 2018-12-03 20:19:31
tags: go
categories: go
---

本地Go开发时，依赖了别的项目RPC接口，由于虚拟机因网卡故障正罢工，只得在win下通过debug来运行，然而多个项目无法同时启动，报错
```
panic: /debug/requests is already registered. You may have two independent copies golang.org/x/net/trace in your binary...
```

<!-- more -->

## 原因
如报错的字面意思，问题出在``golang.org/x/net/trace``这个依赖上  
在``trace.go``文件中的``init()``方法中
```go
func init() {
	_, pat := http.DefaultServeMux.Handler(&http.Request{URL: &url.URL{Path: "/debug/requests"}})
	if pat != "" {
		panic("/debug/requests is already registered. You may have two independent copies of " +
			"golang.org/x/net/trace in your binary, trying to maintain separate state. This may " +
			"involve a vendored copy of golang.org/x/net/trace.")
	}

	// TODO(jbd): Serve Traces from /debug/traces in the future?
	// There is no requirement for a request to be present to have traces.
	http.HandleFunc("/debug/requests", Traces)
	http.HandleFunc("/debug/events", Events)
}
```
可见是以固定代码的形式使用了`/debug/requests`，所以如果多个项目同时使用，就会造成冲突了，无法启动调试
## 解决方法
1. 每个项目独立环境
   当然，最好的方法还是一个项目一个环境，比如独立docker，之前也一直是这么做，所以没碰到这个问题
2. 只留一份`golang.org/x/net/trace`
   删除项目`vendor`中的`golang.org/x/net/trace`，让所有项目使用同一份代码即可，比如只在系统的`GOPATH`中保留一份