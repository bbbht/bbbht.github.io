---
title: 使用Xdebug分析PHP性能问题
date: 2018-11-16 15:14:24
tags: php
categories: php
---

最近应用首页终于到了不得不优化的地步  
由于只是响应慢，所以决定使用日常的xdebug的profiler功能来分析  
记录一下使用的工具及配置，毕竟不是经常使用  
优化虽好，可不能痴迷啊
<!-- more -->

Xdebug的安装配置无需多言，这次这是在配置中增加了profiler的内容  
```ini
xdebug.profiler_enable = 0
xdebug.profiler_enable_trigger = 1
xdebug.profiler_output_dir = "/debug/php/profile"
xdebug.profiler_output_name = "cachegrind.out.%t"
```
具体的配置可参考xdebug文档  
使用了默认的``XDEBUG_PROFILE``参数来触发profile记录  
只是输出目录要确保有权限写文件  
输出文件格式为``cachegrind.out.时间戳``，若分析的页面或接口多的话，应该使用脚本路径或query_uri来标志，以便于区分   
重启``php-fpm``后，正常访问，加上XDEBUG_PROFILE参数即可  
问题在于生成的文件是不可读的，要要工具，在windos下使用了``QCacheGrind(Kcachegrind)``  
盗一张管网图
![效果图](http://kcachegrind.sourceforge.net/html/pics/KcgShot3.gif)

有很清晰的每个函数的调用时间及所占比例，以及直观的调用栈，哪个地方需要优化一目了然  

## 参考链接
[KCachegrind](http://kcachegrind.sourceforge.net/html/Home.html)
[Tips](http://kcachegrind.sourceforge.net/html/Tips.html)