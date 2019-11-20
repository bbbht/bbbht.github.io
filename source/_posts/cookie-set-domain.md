---
title: 设置cookie时的domain与path配置
date: 2018-07-16 14:39:50
tags: cookie
categories: web
---

虽然cookie用了很多年，从第一次面试就有cookie和session的区别相关的问题  
但是，今天却又在cookie上栽了个跟头——cookie注销失败  
而原因则是domain导致    
以此为契机，把cookie的path、domain属性重新了解记录下
<!-- more -->

## 原因
浏览器对cookie的保护造成cookie无法跨域设置，也就是只能操作当前域名以及其父级域名下的cookie

使用php的setcookie举例   
为便于观察与记录，修改本地host，模拟三级域名
- z.com
- y.z.com
- x.y.z.com

在``y.z.com``执行，设置cookie
```php
setcookie('x', 'x', 0, '/', 'x.y.z.com');
setcookie('y', 'y', 0, '/', 'y.z.com');
setcookie('z', 'z', 0, '/', 'z.com');
setcookie('xyz', 'xyz', 0, '/');
```
控制台输出cookie
```js
> document.location.host
< "y.z.com"
> document.cookie
< "y=y; z=z; xyz=xyz"
```

1. 显式设置domain时，当前域名，以及其父级域名下设置的cookie为可见状态  
如``y.z.com``可访问域为``z.com``的cookie，但不能访问``x.y.z.com``下的cookie  
意味着顶级域名下显式设置domain为顶级域名的cookie对所有子域名有效  

> 旧版浏览器仍然在使用废弃的 » RFC 2109， 需要一个前置的点 . 来匹配所有子域名。

2. domain置空，则为代码执行当前域名，且设置的cookie为 **私有**  
``y.z.com``可正常访问，但其父级域``z.com``以及子域``x.y.z.com``下，均不可见

3. 只能为当前域名或者其父级域名设置cookie，否则无效  
如``y.z.com``下无法设置域为``x.y.z.com``的cookie

4. 删除或修改cookie时，指定的key, domain, path 必须与想要删掉的cookie保持一致才能操作  
- 不一致时的修改将创建另一个cookie
    在``y.z.com``执行不对应的删除cookie代码，key为y的cookie将不会被删除
    ```php
    setcookie('y', 'y', time() - 1, '/');
    ```
- 删除时将expires的值设为一个过期值即可
    在``y.z.com``执行不对应的cookie修改代码，将出现两个key为y的cookie
    ```php
    setcookie('y', 'y-update', 0, '/');
    ```
    控制台输出
    ```js
    > document.location.host
    < "y.z.com"
    > document.cookie
    < "y=y; z=z; xyz=xyz; y=y-update"
    ```



## 解决方法
> 无谓的设置cookie只会产生安全隐患以及带宽压力

无法注销的原因就在于删除cookie时未指定domain，而设置时指定了domain  
虽然字面上是用一个域名，但并不能操作成功  
设置与修改、删除时的参数保持一致即可解决问题

## path与domain
只有name，path、domain都相等时，才被认为是同一个cookie  
如果两个cookie的name相同，path不同，那么两个cookie将同时存在，且满足条件时，将同时发送两个cookie  
由此，将出现请求header中携带两个甚至多个同名cookie的问题，服务端取值时将出现混乱  
所以设置cookie时一定要明确指定path，否则会有意想不到的问题发生，不同语言、浏览器可能对默认path设置行为并不相同  

### path
path表示cookie所在的目录，指定一个 URL 路径，这个路径必须出现在要请求的资源的路径中才可以发送 Cookie  
如果设置了path为`/`的cookie1，又设置了path为`/a`的cookie2，path为`/a/b`的cookie3  
当访问`www.example.com`时，将带上cookie1  
当访问`www.example.com/a`时，将带上cookie1、cookie2
当访问`www.example.com/a/b`时，将带上cookie1、cookie2、cookie3
当访问`www.example.com/a/b/c`时，将带上cookie1、cookie2、cookie3

### domain
domain表示的是cookie所在的域，假如没有指定，那么默认值为当前文档访问地址中的主机部分（但是不包含子域名）

## 参考链接
[setcookie manual](http://php.net/manual/zh/function.setcookie.php)
