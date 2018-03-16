# 使用
将Dockerfile，entrypoint.sh存为文件，放在在同一目录下
执行命令
```sh
docker build -t hexo:alpine .
docker run -d --name hexo-server -p 4000:4000 -v /hexo:/hexo hexo:alpine hexo s -w
#  配置别名，方便本地化使用hexo命令
alias hexo="docker exec hexo-server hexo"
```
