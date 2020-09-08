---
title: PHP中Iframe的Cookie属性Samesite
date: 2020-09-08 14:57:23
tags: 
    - cookie
    - php
categories: cookie

---

近期有需求要将系统页面完整嵌入到其它平台，测试中发现cookie异常，无法完成设置。  
response中，`Set-Cookie` 有黄色感叹号标记   
之前也了解过chrome 80+ 之后的安全策略调整导致跨域问题，但没想到系统中对cookie的使用过于泛滥  

<!-- more -->
chrome 80 及之后版本，修改了Cookie 的`SameSite`熟悉的默认配置，以强制提升安全等级防御`CSRF`，具体请参考参考链接  

## 原因
- chrome 80之前
	`SameSite`默认值为 `None`，Cookie 将在所有上下文中发送，即允许跨域发送  
- chrome 80及之后
	`SameSite`默认值为`Lax`，允许部分（下列三种情况）第三方网站发起的GET请求一起发送Cookie  
	GET表单 ``<form method="GET" action="...">``  
	预加载 ``<link rel="prerender" href="..."/>``  
	链接 ``<a href="..."></a>``

可见80之后的版本，默认情况下，AJAX及POST表单、图片加载等，均不会携带cookie，从而导致一些问题发生

## 解决方法
### 代码设置Cookie
以PHP举例，设置cookie时设置SameSite属性为None，同时设置secure  
#### 7.3 以上，可直接设置
`setcookie`函数支持数组设置  
```php
setcookie($name, $value, [
    'expires' => time() + 86400,
    'path' => '/',
    'domain' => 'domain.com',
    'secure' => true,
    'httponly' => true,
    'samesite' => 'None',
]);
```
#### 7.3以下，通过hack方式实现
```php
setcookie('sessionKey', $sessionKey, $expired, '/; secure; SameSite=none;');
```

#### 注意点
1. 部分浏览器（IOS12safari等）特殊行为（未验证）
	会将 `SameSite=none` 识别成 `SameSite=Strict`，所以可能需要对UA判断后再设置 
2. 设置 `SameSite=None`有个前提，即必须同时设置 Secure 属性（只通过https发送）
    如果非https页面接收该设置，同样会收获黄色感叹号，无法完成设置

> this set-cookie was blocked because it was not sent over a secure connection

### Nginx设置Cookie属性
```
location ^/abc/ {
    proxy_cookie_path / "/; secure; SameSite=None";
}
```
问题同代码设置的第二点，且更严重，因为全局设置，如果有其它属性，可能被覆盖

### 使用LocalStorage
要注意的是， LocalStorage 在安全性上差于 cookie，如面对XSS时，如果cookie设置了httponly，则较难被获取cookie，但localstorage一锅端  

## 参考链接
[SameSIte Cookies](https://developer.mozilla.org/zh-CN/docs/Web/HTTP/Headers/Set-Cookie/SameSite)   
[PHP SetCookie](https://stackoverflow.com/questions/39750906/php-setcookie-samesite-strict)  
