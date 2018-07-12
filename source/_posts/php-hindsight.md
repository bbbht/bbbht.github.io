---
title: 新Get的PHP使用方式
date: 2018-05-09 14:47:29
tags: php
categories: php
---
接触PHP也有四五年了，但仍不时有一些新鲜的用法被发现
当然了，肯定是因为文档没读好才会这样
<!-- more -->

## array_column
日常使用就是从多维数组中取出一列
而如下的使用方式则不一样
```php
<?php
$arr = [
    ["id"=>1,"name"=>"A"],
    ["id"=>7,"name"=>"D"],
];
$arr = array_column($arr, null, "id");
var_export($arr);
```
输出
```
array (
  1 => 
  array (
    'id' => 1,
    'name' => 'A',
  ),
  7 => 
  array (
    'id' => 7,
    'name' => 'D',
  ),
)
```
例如数据库中取出的数据，要重置键值为某列的值时，就派上用场了
之前一直是使用``foreach``来解决此类需求

#### 参考链接
[array_column Manual](http://php.net/manual/zh/function.array-column.php)

## mb_strwidth
用于中英文混合字符串的长度计算，
由于各种需求的变更，有时候中文（UTF-8）算一个字符，有时候算两个，对应的解决方案如下

1. 中文算一个字符
```php
echo mb_strlen("赵钱孙李a"), PHP_EOL;
// 5
```
1. 中文算两个字符
```php
echo mb_strwidth("赵钱孙李a"), PHP_EOL;
// 9
```
1. 中文算三个字符
```php
echo strlen("赵钱孙李a"), PHP_EOL;
// 13
```

#### 参考链接
[mb_strwidth Manual](http://php.net/manual/zh/function.mb-strwidth.php)

## glob
寻找与模式匹配的文件路径，返回一个包含有匹配文件／目录的数组。如果出错返回 FALSE。  
简化了文件夹遍历方式，可使用正则匹配  
部分系统不支持，参照文档  

文档示例
```
<?php
foreach (glob("*.txt") as $filename) {
    echo "$filename size " . filesize($filename) . "\n";
}
```

#### 
[glob Manual](http://php.net/manual/zh/function.glob.php)
