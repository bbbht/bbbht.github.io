---
title: php-fpm slow log
date: 2020-03-16 13:14:45
tags: php
categories: php
---

网站并发上升后，页面响应变慢，甚至出现504  
由于网站主入口还是php处理，本地压测也无法复现，所以排查一番后决定通过php-fpm的slowlog来快速定位问题

<!-- more -->

响应慢，大量502,504
## 检测服务器配置
8核16G配置，带宽峰值无限制
### CPU
高并发时均值50%，nginx占比很高  
平时10%左右
### 内存
始终较低，20%左右
### TCP连接数
出问题阶段，服务器监控显示tcp连接数达到了65000左右，然后在65000阶段小幅波动  
怀疑是负载均衡转过来的QPS达到上限(后确认确实占大头)  
网关与真实服务器之间TCP连接由（源IP，目的IP，源端口，目的端口）四元组组成，由此，只有源端口可变  
但实际情况网关后有多台服务器，所以应该非此限制  
但是在真实的业务服务器中，nginx转发到php-fpm的过程中，同样会有这个限制  
### 文件句柄数
正常范围
## 检查PHP相关配置
### php.ini配置
```
root@b616d73bd037:/# cat /etc/php/7.0/fpm/php.ini  | grep -v '^;' | grep -v '^$'
[PHP]
engine = On
short_open_tag = Off
precision = 14
output_buffering = 4096
...
```

### php-fpm配置
```
root@b616d73bd037:/# cat /etc/php/7.0/fpm/pool.d/www.conf | grep -v '^;' | grep -v '^$'
[www]
user = www-data
group = www-data
listen = /run/php/php7.0-fpm.sock
listen.owner = www-data
listen.group = www-data
listen.allowed_clients = 127.0.0.1
;主要是static（静态）或者dynamic（动态）
pm = static
;静态方式下开启的php-fpm进程数量
;在动态方式下，限定php-fpm的最大进程数
;要注意pm.max_spare_servers的值只能小于等于pm.max_children
pm.max_children = 40
;动态方式下的起始php-fpm进程数量
pm.start_servers = 2
;动态方式空闲状态下的最小php-fpm进程数量
pm.min_spare_servers = 1
;动态方式空闲状态下的最大php-fpm进程数量
pm.max_spare_servers = 3
;children 处理多少个请求后被关闭，关闭时会有notice日志产生
;[12-Feb-2020 15:45:24] NOTICE: [pool www] child 30032 exited with code 0 after 2590.928501 seconds from start
pm.max_requests = 20000
pm.status_path = /status
slowlog = /var/log/$pool.log.slow
catch_workers_output = yes
php_admin_value[error_log] = /var/log/fpm-php.www.log
php_admin_flag[log_errors] = on
php_value[session.save_handler] = memcached
php_value[session.save_path]    = cdd400d84eec4b3c.m.cnhzalicm10pub001.ocs.aliyuncs.com:11211
php_value[soap.wsdl_cache_dir]  = /var/lib/php/wsdlcache
```
## 关键配置排查

### php.ini
#### max_execution_time
当前设置30s，触发会返回500  
这个字面意思，即脚本执行时间，所以sleep、curl等待响应一类耗时是不计入的  
### php-fpm
#### max_children
达到上限返回502？
每个按20M内存使用来计算，但静态由于长时间运行可按照每个30M来计算  
当前40，参考配置来说，太低

#### request_terminate_timeout
执行超时触发502？  
当前未设置

## 开启php-fpm慢日志
### 慢日志相关内容
; The log file for slow requests
; Default Value: not set
; Note: slowlog is mandatory if request_slowlog_timeout is set
;slowlog = log/$pool.log.slow

; The timeout for serving a single request after which a PHP backtrace will be
; dumped to the 'slowlog' file. A value of '0s' means 'off'.
; Available units: s(econds)(default), m(inutes), h(ours), or d(ays)
; Default Value: 0
;request_slowlog_timeout = 0

### 配置文件地址
```
root@ubuntu:/home/tb# ps -ef |grep php-fpm | grep master
root      3484     1  0 10:17 ?        00:00:01 php-fpm: master process (/etc/php/7.0/fpm/php-fpm.conf)

最终配置文件路径
include=/etc/php/7.0/fpm/pool.d/*.conf
```

### 修改配置，开启PHP慢日志
#### docker支持
1. docker run 添加参数
```
--cap-add=SYS_PTRACE
```

2. 改运行中容器的docker配置文件
```bash
# 停止docker服务 
systemctl stop docker
# 修改docker配置，先找到容器id
sudo vim /var/lib/docker/containers/container_id/hostconfig.json
# 手动添加修改CapAdd内容
"CapAdd":["SYS_PTRACE"],"CapDrop":null,
# 启动docker服务
systemctl start docker
```

#### php-fpm支持
```bash
# 修改php-fpm配置，不一定相同路径
vim /etc/php/7.0/fpm/pool.d/www.conf
slowlog = /var/log/$pool.log.slow 修改为 slowlog = /var/log/php.slow.log
;request_slowlog_timeout = 0 修改为 request_slowlog_timeout = 2s
# 重启php-fpm
kill -USR2 pid
```

#### 其它
报错处理
**ERROR: Unable to set php_value 'soap.wsdl_cache_dir'.**
```bash
# 注释掉，因为未使用
;php_value[soap.wsdl_cache_dir]  = /var/lib/php/wsdlcache
```
```bash
# 修改php-fpm的日志记录等级，默认notice
vim /etc/php/7.0/fpm/php-fpm.conf
;log_level = notice 修改为 log_level = warning
```

## 参考链接
[链接1](https://serverfault.com/questions/704007/php-slowlog-causing-ptrace-error-in-docker-container/706982#706982)  
[链接2](https://www.jianshu.com/p/967b2f37d8af)
