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

if [ ! -d '.git' ]; then
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

cd ${WWW_HOME}
PROJECT_ROOT=`find ${GITHUB_DIRECTORY} -name 'index.php' | grep 'public/index.php' | sed -e 's/public\/index.php$//'`
if [ -n "$TAG" ]; then
    sudo ln -nfs ${PROJECT_ROOT} ${TAG}
    sudo ln -nfs ${TAG} current
else
    sudo ln -nfs ${PROJECT_ROOT} current
fi

if [ -f "current/.env" ]; then
    sudo mv -f current/.env current/.env.1
fi
sudo cp env_file current/.env
sudo mkdir -p current/storage/app/tmp/
sudo chown -R ${WWW_USER}. current

# Execute house keeping
OLD_DIRECTORYS=`ls -td */ | awk '{if(NR>4){print}}'`
for OLD_DIRECTORY in $OLD_DIRECTORYS; do
    if [ -n "$OLD_DIRECTORY" ]; then
        sudo rm -rf $OLD_DIRECTORY
    fi
done
find . -xtype l -print0 | xargs -0 rm -f