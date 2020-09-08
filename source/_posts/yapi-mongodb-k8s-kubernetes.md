---
title: kubernetes内网部署yapi使用mongodb并启用LDAP
date: 2020-09-07 11:44:10
tags: 
    - yapi
    - kubernetes
categories: yapi
---
技术选型选择了 yapi 作为内部接口管理系统，由于测试环境都部署在 kubernetes 集群中，所以官网提供的docker镜像还需要修改才能使用  
同时，还需要启用并配置 LDAP 实现内网统一认证  
<!-- more -->
完成的内容，分享出来  

## Dockerfile
```dockerfile
FROM node:14.4.0-alpine3.12 as builder

MAINTAINER plateau.loess@gmail.com

ARG NPM_REGISTRY="http://registry.npm.taobao.org/"
ARG YAPI_VERSION="1.9.2"

WORKDIR /app/yapi

#ADD https://github.com/YMFE/yapi/archive/v${YAPI_VERSION}.tar.gz .
# 也可以预下载后，直接使用
ADD v${YAPI_VERSION}.tar.gz ./

# 适当精简镜像内容
RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
    && mv yapi-${YAPI_VERSION}/* . \
    && rm -r yapi-${YAPI_VERSION} ./docs \
    && apk add --virtual .build-dep git python3 make \
    && npm install --production --registry ${NPM_REGISTRY} \
    && apk del .build-dep

FROM node:14.4.0-alpine3.12

ARG NPM_REGISTRY="http://registry.npm.taobao.org/"

WORKDIR /app/yapi

COPY --from=builder /app/yapi .
COPY docker-entrypoint.sh /app/
COPY config.json /app/

RUN  sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
     && apk add --no-cache bash \
     && chmod +x /app/docker-entrypoint.sh \
     && npm install -g yapi-cli --registry ${NPM_REGISTRY} \
     && rm -rf /var/cache/apk/* ~/.npm/

EXPOSE 3000

CMD [ "/app/docker-entrypoint.sh" ]
```

## docker-entrypoint.sh
```bash
#!/bin/bash

set -eo pipefail
shopt -s nullglob

PS4='+ $(date +"%F %T%z") ${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

YAPI_DEBUG="${YAPI_DEBUG:=}"
YAPI_CLOSE_REGISTER="${YAPI_CLOSE_REGISTER:=true}"
YAPI_DELAY="${YAPI_DELAY:=3}"
YAPI_DIR="${YAPI_DIR:=/app/yapi}"

YAPI_PORT="${YAPI_PORT:=3000}"
YAPI_ACOUNT="${YAPI_ACOUNT:=yapi@admin.cn}"
YAPI_INIT="${YAPI_INIT:=false}"

YAPI_DB_CONNECT_STRING="${YAPI_DB_CONNECT_STRING:=}"

YAPI_DB_HOST="${YAPI_DB_HOST:=127.0.0.1}"
YAPI_DB_NAME="${YAPI_DB_NAME:=yapi}"
YAPI_DB_PORT="${YAPI_DB_PORT:=27017}"
YAPI_DB_USER="${YAPI_DB_USER:=}"
YAPI_DB_PASS="${YAPI_DB_PASS:=}"
YAPI_DB_AUTH="${YAPI_DB_AUTH:=}"

YAPI_MAIL_ENABLE="${YAPI_MAIL_ENABLE:=false}"
YAPI_MAIL_HOST="${YAPI_MAIL_HOST:=smtpdm.aliyun.com}"
YAPI_MAIL_PORT="${YAPI_MAIL_PORT:=465}"
YAPI_MAIL_FROM="${YAPI_MAIL_FROM:=}"
YAPI_MAIL_USER="${YAPI_MAIL_USER:=${YAPI_MAIL_FROM}}"
YAPI_MAIL_PASS="${YAPI_MAIL_PASS:=}"

YAPI_LDAP_ENABLE="${YAPI_LDAP_ENABLE:=false}"
YAPI_LDAP_SERVER="${YAPI_LDAP_SERVER:=}"
YAPI_LDAP_BASE_DN="${YAPI_LDAP_BASE_DN:=}"
YAPI_LDAP_BIND_PASSWORD="${YAPI_LDAP_BIND_PASSWORD:=}"
YAPI_LDAP_SEARCH_DN="${YAPI_LDAP_SEARCH_DN:=}"
YAPI_LDAP_SEARCH_STANDARD="${YAPI_LDAP_SEARCH_STANDARD:=mail}"
YAPI_LDAP_EMAIL_POSTFIX="${YAPI_LDAP_EMAIL_POSTFIX:=@xxxxxxxxxxxxxx.com}"
YAPI_LDAP_EMAIL_KEY="${YAPI_LDAP_EMAIL_KEY:=mail}"
YAPI_LDAP_USERNAME_KEY="${YAPI_LDAP_USERNAME_KEY:=name}"

yapi_debug() {
    if [ "${YAPI_DEBUG}" == 1 ]; then
        set -xe
        PS4='+ $(date +"%F %T%z") ${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
    fi
    if [ "${YAPI_DELAY}" -gt 0 ]; then
        echo ""
        echo "Yapi will start in ${YAPI_DELAY} seconds..."
        echo ""
        sleep ${YAPI_DELAY}
    fi

    sed -i "s#\"YAPI_CLOSE_REGISTER\"#${YAPI_CLOSE_REGISTER}#g" /app/config.json
}
yapi_mail_config() {
    local holder
    if [ "${YAPI_MAIL_ENABLE}" == "true" ]; then
        for envar in YAPI_MAIL_ENABLE YAPI_MAIL_HOST YAPI_MAIL_FROM YAPI_MAIL_USER YAPI_MAIL_PASS
        do
            local holder=$(eval echo '$'${envar})
            sed -i "s#${envar}#${holder}#g"       /app/config.json
        done
        sed -i "s#YAPI_MAIL_PORT#${YAPI_MAIL_PORT}#g" /app/config.json
    fi
}

yapi_ldap_config() {
    local holder
    if [ "${YAPI_LDAP_ENABLE}" == "true" ]; then
        for envar in YAPI_LDAP_ENABLE YAPI_LDAP_SERVER YAPI_LDAP_BASE_DN YAPI_LDAP_BIND_PASSWORD YAPI_LDAP_SEARCH_DN YAPI_LDAP_SEARCH_STANDARD YAPI_LDAP_EMAIL_POSTFIX YAPI_LDAP_EMAIL_KEY YAPI_LDAP_USERNAME_KEY
        do
            local holder=$(eval echo '$'${envar})
            sed -i "s#${envar}#${holder}#g"       /app/config.json
        done
    fi
}

yapi_db_check() {
    set +e
    local retry=0
    while (:;)
    do
        nc -zv ${YAPI_DB_HOST} ${YAPI_DB_PORT}
        if [ $? -ne 0 ]; then
            echo "[$(date '+%F %T%z')] [error] Failed to connect mongodb $(hostname)->${YAPI_DB_HOST}:${YAPI_DB_PORT}, retrying ${retry} ..."
            retry=$[ retry + 1 ]
            sleep 1
            continue
        else
            echo "[$(date '+%F %T%z')] [info] Sucessfully connect mongodb $(hostname)->${YAPI_DB_HOST}:${YAPI_DB_PORT}, retry ${retry} times."
            break
        fi
    done
    set +e
}
yapi_db_config() {
    for envar in YAPI_ACOUNT YAPI_DB_HOST YAPI_DB_NAME YAPI_DB_PORT YAPI_DB_USER YAPI_DB_PASS YAPI_DB_AUTH YAPI_DB_CONNECT_STRING
    do
        local holder=$(eval echo '$'${envar})
        sed -i "s#${envar}#${holder}#g"   /app/config.json
    done

    sed -i "s#YAPI_PORT#${YAPI_PORT}#g" /app/config.json
    sed -i "s#YAPI_DB_PORT#${YAPI_DB_PORT}#g" /app/config.json
}


yapi_debug
yapi_mail_config
yapi_ldap_config
yapi_db_config
yapi_db_check

#初始化账号判断，在脚本同层，未设置lock文件且开启init才执行
if [ ! -e "init.lock" ] && [ "${YAPI_INIT}" == "true" ]; then
    node ${YAPI_DIR}/server/install.js
fi

exec node ${YAPI_DIR}/server/app.js "${@}"

```
## config.json
```json
{
  "port": "YAPI_PORT",
  "closeRegister":"YAPI_CLOSE_REGISTER",
  "adminAccount": "YAPI_ACOUNT",
  "db": {
    "connectString":"YAPI_DB_CONNECT_STRING",
    "servername": "YAPI_DB_HOST",
    "DATABASE": "YAPI_DB_NAME",
    "port": "YAPI_DB_PORT",
    "user": "YAPI_DB_USER",
    "pass": "YAPI_DB_PASS",
    "authSource": "YAPI_DB_AUTH"
  },
  "mail": {
    "enable": "YAPI_MAIL_ENABLE",
    "host": "YAPI_MAIL_HOST",
    "port": "YAPI_MAIL_PORT",
    "from": "YAPI_MAIL_FROM",
    "auth": {
      "user": "YAPI_MAIL_FROM",
      "pass": "YAPI_MAIL_PASS"
    }
  },
  "ldapLogin": {
    "enable": "YAPI_LDAP_ENABLE",
    "server": "YAPI_LDAP_SERVER",
    "baseDn": "YAPI_LDAP_BASE_DN",
    "bindPassword": "YAPI_LDAP_BIND_PASSWORD",
    "searchDn": "YAPI_LDAP_SEARCH_DN",
    "searchStandard": "YAPI_LDAP_SEARCH_STANDARD",
    "emailPostfix": "YAPI_LDAP_EMAIL_POSTFIX",
    "emailKey": "YAPI_LDAP_EMAIL_KEY",
    "usernameKey": "YAPI_LDAP_USERNAME_KEY"
  }
}

```
## mongodb
由于线上是购买的云数据库，只在测试时通过docker部署运行了mongodb，命令如下
```bash
# 启用了权限认证
docker run -d -p 27017:27017 -v /data/yapi-mongo:/data/db --name mongo-server mongo --auth
```
然后进入容器，添加管理员，yapi所需的db及用户
```bash
mongo

use admin

# 增加一个超级管理员
db.createUser({
    user: "adminname",
    pwd: "password",
    roles:[
       {
           role:"userAdminAnyDatabase",
           db:"admin"
       }
    ]
})

# 创建yapi的db，名字固定yapi
use yapi
# 为其增加一个用户
db.createUser({
    user: "yapi-admin",
    pwd: "123456",
    roles:[
       {
           role:"readWrite",
           db:"yapi"
       }
    ]
})

```

## LDAP验证
通过修改填充下面的命令来测试ldap服务器搜索制定邮箱  
具体命令请参考链接，下面的值请对应config.json的设置  
```bash
ldapsearch -x -LLL -H "YAPI_LDAP_SERVER" -D "YAPI_LDAP_BASE_DN" -w "YAPI_LDAP_BIND_PASSWORD" -b"YAPI_LDAP_SEARCH_DN" YAPI_LDAP_EMAIL_KEY=要搜索的邮箱 YAPI_LDAP_USERNAME_KEY
```

## 使用注意
1. 各项配置请参考官方文档
2. DOckerfile编译的镜像，也可用于docker部署允许
3. kubernetes部署，要记得设置 启动命令为 ``/app/docker-entrypoint.sh``
4. kubernetes部署的配置文件不再赘述，重点在于设置所需的环境变量
5. 1.9.2版本为此时最新版，很久不更新了，如果后续版本再更新，dockerfile的部署方式有可能发生变化
6. 使用LDAP登录时，不需要数据库中有对应用户，会自动注册生成。同时如果已存在，也可无缝对接使用

## 参考链接
[Yapi官方文档LDAP配置说明](https://hellosean1025.github.io/yapi/devops/index.html#%e9%85%8d%e7%bd%aeldap%e7%99%bb%e5%bd%95)   
[ldapsearch使用](https://blog.csdn.net/liumiaocn/article/details/83990918)    