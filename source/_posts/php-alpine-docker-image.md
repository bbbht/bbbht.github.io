---
title: 基于官方alpine php镜像构建php基础运行环境
date: 2020-07-24 10:43:17
tags: 
    - docker
    - php
categories: docker
---
年久失修的线上Docker运行php的环境已经无法维护，且是基于完整Ubuntu16构建，镜像相当庞大  
于是选择使用官方的php镜像（alpine）进行重新构建，输出Dockfile以便后续更新
<!-- more -->


## 准备
先查看官方镜像已包含的扩展
```bash
docker run --rm php:7.1.33-fpm-alpine3.10 php -m
```
> [PHP Modules]
> Core  
> ctype  
> curl  
> date  
> dom  
> fileinfo  
> filter  
> ftp  
> hash  
> iconv  
> json  
> libxml  
> mbstring  
> mysqlnd  
> openssl  
> pcre  
> PDO  
> pdo_sqlite  
> Phar  
> posix  
> readline  
> Reflection  
> session  
> SimpleXML  
> SPL  
> sqlite3  
> standard  
> tokenizer  
> xml  
> xmlreader  
> xmlwriter  
> zlib  

> [Zend Modules]


再看`docker-php-ext-install`可安装的扩展列表，还要辅以pecl安装
```bash
docker run --rm php:7.1.33-fpm-alpine3.10 docker-php-ext-install -h
```
> usage: /usr/local/bin/docker-php-ext-install [-jN] ext-name [ext-name ...]   
>   ie: /usr/local/bin/docker-php-ext-install gd mysqli  
>       /usr/local/bin/docker-php-ext-install pdo pdo_mysql  
>       /usr/local/bin/docker-php-ext-install -j5 gd mbstring mysqli pdo pdo_mysql shmop  

> if custom ./configure arguments are necessary, see docker-php-ext-configure  

> Possible values for ext-name:  
> bcmath bz2 calendar ctype curl dba dom enchant exif fileinfo filter ftp gd gettext gmp hash iconv imap  > interbase intl json ldap mbstring mcrypt mysqli oci8 odbc opcache pcntl pdo pdo_dblib pdo_firebird > pdo_mysql pdo_oci pdo_odbc pdo_pgsql pdo_sqlite pgsql phar posix pspell readline recode reflection > session shmop simplexml snmp soap sockets spl standard sysvmsg sysvsem sysvshm tidy tokenizer wddx xml > xmlreader xmlrpc xmlwriter xsl zip  
> Some of the above modules are already compiled into PHP; please check  
> the output of "php -i" to see which modules are already loaded.  


## 问题
```
PHP Warning:  PHP Startup: Unable to load dynamic library '/usr/local/lib/php/extensions/no-debug-non-zts-20160303/gd.so' - Error loading shared library libpng16.so.16: No such file or directory (needed by /usr/local/lib/php/extensions/no-debug-non-zts-20160303/gd.so) in Unknown on line 0
PHP Warning:  PHP Startup: Unable to load dynamic library '/usr/local/lib/php/extensions/no-debug-non-zts-20160303/imap.so' - Error loading shared library libc-client.so.1: No such file or directory (needed by /usr/local/lib/php/extensions/no-debug-non-zts-20160303/imap.so) in Unknown on line 0
PHP Warning:  PHP Startup: Unable to load dynamic library '/usr/local/lib/php/extensions/no-debug-non-zts-20160303/intl.so' - Error loading shared library libicuio.so.64: No such file or directory (needed by /usr/local/lib/php/extensions/no-debug-non-zts-20160303/intl.so) in Unknown on line 0
PHP Warning:  PHP Startup: Unable to load dynamic library '/usr/local/lib/php/extensions/no-debug-non-zts-20160303/mcrypt.so' - Error loading shared library libmcrypt.so.4: No such file or directory (needed by /usr/local/lib/php/extensions/no-debug-non-zts-20160303/mcrypt.so) in Unknown on line 0
PHP Warning:  PHP Startup: Unable to load dynamic library '/usr/local/lib/php/extensions/no-debug-non-zts-20160303/memcached.so' - Error loading shared library libmemcached.so.11: No such file or directory (needed by /usr/local/lib/php/extensions/no-debug-non-zts-20160303/memcached.so) in Unknown on line 0
PHP Warning:  PHP Startup: Unable to load dynamic library '/usr/local/lib/php/extensions/no-debug-non-zts-20160303/tidy.so' - Error loading shared library libtidy.so.5: No such file or directory (needed by /usr/local/lib/php/extensions/no-debug-non-zts-20160303/tidy.so) in Unknown on line 0
```
上述问题是因为动态库的依赖不存在，仅编译扩展时提供的编译环境会被删除，所以导致依赖缺失  
解决方法是安装所需运行环境 如`libmcrypt`,`c-client`等，详见Dockerfile


## 安装扩展的Dockfile
暂时只包含了扩展安装，这也是比较让人头疼的内容了，作为基础镜像，再从下层继续构建完整运行环境  
当前线上使用7.1，暂时未升级，使用了相同版本
```dockerfile
FROM php:7.1.33-fpm-alpine3.10

LABEL MAINTAINER plateau.loess@gmail.com
LABEL description="基于官方alpine php安装了基础扩展的php-fpm镜像"

ENV TZ "Asia/Shanghai"

# 构建环境依赖项
ENV PHP_INSTALL_EXT_DEPS \
		# for mcrypt
		libmcrypt-dev \
		# for zip
		libzip-dev \
		# for intl
		icu-dev \
		# for imap
		imap-dev openssl-dev \
		# for tidy
		tidyhtml-dev \
		# for gd
		freetype-dev libjpeg-turbo-dev libpng-dev

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories

RUN apk update \
	&& apk add --no-cache \
		libmcrypt \
		libzip \
		icu \
		imap c-client \
		tidyhtml \
		freetype libpng libjpeg-turbo \
	&& apk add --update --no-cache --virtual .build-ext-deps $PHP_INSTALL_EXT_DEPS \
	&& docker-php-ext-configure imap --with-imap --with-imap-ssl \
	&& docker-php-ext-configure opcache --enable-opcache \
	&& docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ --with-png-dir=/usr/include/ \
	&& docker-php-ext-install -j$(nproc) pdo_mysql mcrypt zip intl imap tidy pcntl opcache bcmath gd \
	&& apk del .build-ext-deps

# pecl 安装redis/memcached扩展
RUN apk add --no-cache libmemcached \
	&& apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
		libmemcached-dev zlib-dev \
     && pecl install redis memcached \
     && docker-php-ext-enable redis memcached \
     && rm -rf /tmp/pear \
     && apk del -f .build-deps

# 导入 php.ini
# 导入 www.conf

WORKDIR /var/www

EXPOSE 9000

CMD ["php-fpm"]
```
