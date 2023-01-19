#!/bin/bash

#### Required variables
# WWW_HOME: Web app home directory
# WWW_USER: Web app execution user
# GITHUB_DIRECTORY: git directory name
# GITHUB_ACCOUNT: github account
# GITHUB_REPOSITORY: github repository
# GITHUB_BRANCH: github branch

SOURCE_CODE_DIR=${WWW_HOME}/${GITHUB_DIRECTORY}
sudo mkdir -p ${SOURCE_CODE_DIR}
cd ${SOURCE_CODE_DIR}

sudo git -C ${SOURCE_CODE_DIR} status > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo 'Start git init.'
    sudo git -C ${SOURCE_CODE_DIR} init
    sudo tee ${SOURCE_CODE_DIR}/.git/config << _EOF_ > /dev/null
[core]
    repositoryformatversion = 0
    filemode = true
    bare = false
    logallrefupdates = true
    symlinks = false
    ignorecase = true
    sparsecheckout = true
_EOF_

    sudo git -C ${SOURCE_CODE_DIR} remote add origin git@github.com:$GITHUB_ACCOUNT/$GITHUB_REPOSITORY.git

    sudo tee ${SOURCE_CODE_DIR}/.git/info/sparse-checkout << _EOF_ > /dev/null
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

    sudo git -C ${SOURCE_CODE_DIR} fetch --depth 1
    sudo git -C ${SOURCE_CODE_DIR} switch ${GITHUB_BRANCH}

fi

echo 'Start git pull.'
sudo git -C ${SOURCE_CODE_DIR} pull
TAG=`sudo git -C ${SOURCE_CODE_DIR} tag --sort=-taggerdate | head -1`
DOCUMENT_ROOT=`find ${SOURCE_CODE_DIR} -name 'index.php' | grep 'public/index.php' | sed -e 's/public\/index.php$//'`

cd ${WWW_HOME}
if [ -n "$TAG" ]; then
    sudo ln -nfs ${DOCUMENT_ROOT} ${TAG}
    sudo ln -nfs ${TAG} current
else
    sudo ln -nfs ${DOCUMENT_ROOT} current
fi

sudo mkdir -p ${WWW_HOME}/current/storage/app/tmp/
sudo mv -f ${WWW_HOME}/current/.env ${WWW_HOME}/current/.env.1
sudo cp ${WWW_HOME}/env_file ${WWW_HOME}/current/.env
sudo chown -R ${WWW_USER}. ${WWW_HOME}/current

# Execute house keeping
OLD_DIRECTORYS=`ls -td */ | awk '{if(NR>4){print}}'`
for OLD_DIRECTORY in $OLD_DIRECTORYS; do
    if [ -n "$OLD_DIRECTORY" ]; then
        rm -rf $OLD_DIRECTORY
    fi
done
find . -xtype l -print0 | xargs -0 rm -f