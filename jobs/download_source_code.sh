#!/bin/bash

#### Required variables
# WWW_HOME: Web app home directory
# WWW_USER: Web app execution user
# GITHUB_DIRECTORY: git directory
# GITHUB_ACCOUNT: github account
# GITHUB_REPOSITORY: github repository
# GITHUB_BRANCH: github branch

sudo mkdir -p ${GITHUB_DIRECTORY}
cd ${GITHUB_DIRECTORY}

sudo git -C ${GITHUB_DIRECTORY} status > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo 'Start git init.'
    sudo git -C ${GITHUB_DIRECTORY} init
    sudo tee ${GITHUB_DIRECTORY}/.git/config << _EOF_ > /dev/null
[core]
    repositoryformatversion = 0
    filemode = true
    bare = false
    logallrefupdates = true
    symlinks = false
    ignorecase = true
    sparsecheckout = true
_EOF_

    sudo git -C ${GITHUB_DIRECTORY} remote add origin git@github.com:$GITHUB_ACCOUNT/$GITHUB_REPOSITORY.git

    sudo tee ${GITHUB_DIRECTORY}/.git/info/sparse-checkout << _EOF_ > /dev/null
/*
!/.env*
!/batch
!/docker
!/docker-compose.yml
!/infra
!/postman
!/README.md
!/swagger
_EOF_

    sudo git -C ${GITHUB_DIRECTORY} fetch --depth 1
    sudo git -C ${GITHUB_DIRECTORY} switch ${GITHUB_BRANCH}

fi

echo 'Start git pull.'
sudo git -C ${GITHUB_DIRECTORY} pull
TAG=`sudo git -C ${GITHUB_DIRECTORY} tag --sort=-taggerdate | head -1`
LARAVEL_DIR=`find ${GITHUB_DIRECTORY} -name 'index.php' | grep 'public/index.php' | sed -e 's/public\/index.php$//'`

cd ${WWW_HOME}
if [ -n "$TAG" ]; then
    sudo ln -nfs ${LARAVEL_DIR} ${TAG}
    sudo ln -nfs ${TAG} current
else
    sudo ln -nfs ${LARAVEL_DIR} current
fi

sudo mkdir -p ${WWW_HOME}/current/storage/app/tmp/
sudo echo -e "${ENV_LIST}" > ${WWW_HOME}/current/.env
sudo chown -R ${WWW_USER} ${WWW_HOME}/current