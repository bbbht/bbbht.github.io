---
title: php的session_start锁导致接口超时
date: 2020-11-11 10:56:05
tags: php
categories: php
---
最近遇到了奇怪的问题，一个PHP老系统频频出现异常的超时请求，但代码内部的实际执行实际又从不超时，很妖  
最终定位是 PHP 的 `session_start` 的 lock 导致的   
当然，之前没有发生的原因是MySQL数据少，查询相当快
<!-- more -->
一段与外部系统对接的代码，用户登录后的信息都存储在session中，各个接口有调用`session_start`，而且session是默认配置，高频的调用导致接口排队等待获取锁，然后，就超时了，但内部的执行耗时记录是没有把这个时间计算在内的    
## 原因
首先，一个用户的请求首次触发`session_start`运行后，在默认路径（session.save_path） ` /var/lib/php/session`创建特殊标记文件，如 `session_新的ID`，同时这个新的ID也会被设置到cookie中，SESSEIONID啥的，再次访问携带了cookie则是访问这个文件了  
但默认情况下，在这个PHP脚本执行结束前，这个文件会一直处于加锁阶段，从`sesseion_start`到脚本退出  
所有一般并发请求时，后一个请求如果也调用了，那就必须等上一个脚本退出即锁释放之后才能开始执行，页面的表现也就是傻傻的等着了   

## 解决方法
### 及时释放锁
对于只读的接口，调用`session_write_close`可以马上释放锁，而从PHP7版本开始，可以一步到位，不需要再手动调用`session_write_close`方法：
```php
<?php
session_start(['read_and_close' => true]);
?>
```
最终使用了此方案，原因是改动最小  

### 自定义实现session操作
``session_set_save_handler``方法，自行查看文档吧  

### 使用memcached、redis存储session
需要注意的是，memcached 有个配置 `memcached.sess_locking`，默认为 `on`，与默认文件的行为一致，需要设置为 `off`  
锁的时候还是要基于实际场景的影响  
