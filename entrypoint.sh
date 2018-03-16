#!/bin/bash
set -x
HEXO_DIR=/hexo
if [ ! -d $HEXO_DIR/.git ]; then
    git clone https://github.com/bbbht/bbbht.github.io.git --branch hexo $HEXO_DIR
else
    echo $HEXO_DIR" is not empty"
fi
cd $HEXO_DIR
git config user.name bbbht
git config user.email plateau.loess@gmail.com
git config core.fileMode false
npm install --no-optional --no-bin-links

exec "$@"
