---
title: 经典的无限层级PHP数组转树状分组（非递归）
date: 2018-08-03 16:35:53
tags: php
categories: php
---

项目里有很多多层关联的数据  
系统中现有方法都是递归的，直到最近出现了一次超出递归层数的bug数据  
> Note: 但是要避免递归函数／方法调用超过 100-200 层，因为可能会使堆栈崩溃从而使当前脚本终止。 无限递归可视为编程错误。

于是不再使用递归方式，改用如下的经典方法

<!-- more -->

```php
    /**
     * 非递归的将经典无限层级关系的数组转换为树状分组
     * @param array  $rawArray
     * @param string $idKey  主键
     * @param string $pidKey  父级主键
     * @param string $subKey  层级键
     * @return array
     */
    function array2Tree(array $rawArray, $idKey = 'id', $pidKey = 'pid', $subKey = 'sub')
    {
        $result = [];

        $rawArray = array_column($rawArray, null, $idKey);

        foreach ($rawArray as $item) {
            if (isset($rawArray[$item[$pidKey]])) {
                $rawArray[$item[$pidKey]][$subKey][] = &$rawArray[$item[$idKey]];
            } else {
                $result[] = &$rawArray[$item[$idKey]];
            }
        }

        return $result;
    }
```

历史原因，很多层级关系并不是用经典的id,pid表示，代码中表示下级分组的键值也不统一，就自定义吧  
这个方法使用的前提是数组的key值与此项数组的主键相同，所以先用``array_column``处理  
``&``的引用真的是非常灵活了，一次遍历即可通过引用的方式完成所有层级分组的构建  

## 参考链接
[函数 manual](http://php.net/manual/zh/functions.user-defined.php)
