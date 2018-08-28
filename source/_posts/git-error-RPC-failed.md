---
title: git clone 失败 error RPC failed
date: 2018-08-28 16:08:17
tags: git
categories: git
---
最近``go  get``总是失败，报错
```
$ git clone https://github.com/mattn/go-sqlite3.git
Cloning into 'go-sqlite3'...
remote: Counting objects: 2804, done.
remote: Compressing objects: 100% (7/7), done.
error: RPC failed; curl 18 transfer closed with outstanding read data remaining
fatal: The remote end hung up unexpectedly
fatal: early EOF
fatal: index-pack failed
``` 
直接``git clone``也是同样的问题  
当然，访问``github.com``是没问题  


<!-- more -->
只能曲线方案了

## 原因
qiang  
还有原因是项目过大造成的

## 解决方法
针对项目体积过大的解决方法是修改git配置  
```
git config --global http.postBuffer 524288000
```
http.postBuffer单位是字节，``524288000/1024/1024``也就是500M  
然而并未起作用  

---

SO
由于只是go的依赖，并不需要完整的分支列表及提交记录，所以只要有最新的提交就够用了  
使用浅克隆，即clone 时使用depth参数，设定要获取的历史提交的深度  
```
git clone https://github.com/mattn/go-sqlite3.git --depth 1
```
depth 参数值为 1，表示只clone最近的一次提交，即仓库的最新状态  

“正常情况”下，可以通过后续操作完成获取完整的仓库
```
git fetch --unshallow
```
然而
```
git fetch --unshallow
remote: Counting objects: 2246, done.
remote: Compressing objects: 100% (909/909), done.
error: RPC failed; curl 18 transfer closed with outstanding read data remaining
fatal: The remote end hung up unexpectedly
fatal: early EOF
fatal: index-pack failed

```
当然也可以指定分支以减小仓库体积，并未尝试

## 参考链接
[error: RPC failed; curl transfer closed with outstanding read data remaining](https://stackoverflow.com/questions/38618885/error-rpc-failed-curl-transfer-closed-with-outstanding-read-data-remaining)
