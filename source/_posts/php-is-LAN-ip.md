---
title: PHP判断是否为局域网IP
date: 2019-09-11 12:32:48
tags: php
categories: php
---
有些老接口要限制内网访问，选择最简单的方式，由PHP执行时进行判断
<!-- more -->
## 根据ip段判断
判断常规的192、172、10、127 IP段
```php
function is_internal_ip(string $ip = '') {
    if ($ip == '') {
        return false;
    }
    $ip = ip2long($ip);

    // 0xc0a80000 192.168.0.0/16
    // 0xac100000 172.16.0.0/12
    // 0xa0000000 10.0.0.0/8
    // 0x7f000000 127.0.0.0/8
    return ($ip & 0xffff0000) == 0xc0a80000 
    || ($ip & 0xfff00000) == 0xac100000
    || ($ip & 0xff000000) == 0xa0000000
    || ($ip & 0xff000000) == 0x7f000000;
}
```
## 使用PHP内置方法
`filter_var`是个很棒的方法，能完成各种类型（url、email等）的判断  
此处用到的两个flag如下，其余flag请点击参考链接  
此方法会将保留ip也识别为内网ip
> FILTER_FLAG_NO_PRIV_RANGE （非私有ip，即非专有网络）

> Fails validation for the following private IPv4 ranges: 10.0.0.0/8, 172.16.0.0/12 and 192.168.0.0/16.
> Fails validation for the IPv6 addresses starting with FD or FC.

> FILTER_FLAG_NO_RES_RANGE （非保留ip）

> Fails validation for the following reserved IPv4 ranges: 0.0.0.0/8, 169.254.0.0/16, 127.0.0.0/8 and 240.0.0.0/4.
> Fails validation for the following reserved IPv6 ranges: ::1/128, ::/128, ::ffff:0:0/96 and fe80::/10.

```php
function is_internal_ip(string $ip = '') {
    return filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE) === false;
}
```

## 参考链接
[PHP filter_var](https://www.php.net/manual/zh/function.filter-var.php)
[PHP Filter flages](https://www.php.net/manual/zh/filter.filters.flags.php)
[专用网络](https://zh.wikipedia.org/wiki/%E4%B8%93%E7%94%A8%E7%BD%91%E7%BB%9C)
[保留IP地址](https://zh.wikipedia.org/wiki/%E4%BF%9D%E7%95%99IP%E5%9C%B0%E5%9D%80)