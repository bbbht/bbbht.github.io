FROM node:6-alpine
MAINTAINER bbbht <plateau.loess@gmail.com>
WORKDIR /hexo
VOLUME ['/hexo']
EXPOSE 4000
ENV LANG C.UTF-8

RUN apk add --update git && \
    npm install hexo-cli -g --no-optional

COPY entrypoint.sh /
ENTRYPOINT ["sh", "/entrypoint.sh"]
CMD ['hexo', 's']
