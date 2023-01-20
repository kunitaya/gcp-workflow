#!/bin/bash

#### Required variables
# GOOGLE_CLOUD_PROJECT_ID: GCP project ID
# INSTANCE_GROUP_PREFIX: Target instance group prefix
# NAME: Image source instance name
# GITHUB_REPOSITORY: Name of Github repository for CI
# GITHUB_BRANCH: Name of Github branch for CI

##!include include_GoogleCloudSDK

gcloud config set project $GOOGLE_CLOUD_PROJECT_ID
[ $? -ne 0 ] && exit 1

HASH=`cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 4 | head -1`
DATE=`date '+%Y%m%d'`

NAME1=`echo $GITHUB_REPOSITORY | sed -e 's/[^a-zA-Z0-9]//g'`
NAME2=`echo $GITHUB_BRANCH | sed -e 's/[^a-zA-Z0-9]//g'`
IMAGE_NAME="${NAME1}-${NAME2}-$DATE$HASH"
TEMPLATE_NAME="${NAME1}-${NAME2}-$DATE$HASH"
echo "image_name=$IMAGE_NAME" >> $JS7_RETURN_VALUES
echo "template_name=$TEMPLATE_NAME" >> $JS7_RETURN_VALUES

WWW_HOME="/var/www/${GITHUB_REPOSITORY}"
echo "www_home=$WWW_HOME" >> $JS7_RETURN_VALUES

GITHUB_DIRECTORY=${GITHUB_BRANCH}-$DATE$HASH
echo "github_directory=$GITHUB_DIRECTORY" >> $JS7_RETURN_VALUES

INSTANCE_GROUPS=`gcloud compute instance-groups list --format='get(name)' --project=$GOOGLE_CLOUD_PROJECT_ID | grep $INSTANCE_GROUP_PREFIX`
INSTANCE_GROUP_LIST=()
for i in $INSTANCE_GROUPS; do
    INSTANCE_GROUP_LIST+=($i)
done
echo "instance_groups=${INSTANCE_GROUP_LIST[@]}" >> $JS7_RETURN_VALUES

ZONE=`gcloud compute instances list --filter="name=($NAME)" --format="value(zone.basename())" --project=$GOOGLE_CLOUD_PROJECT_ID`
STATUS=`gcloud compute instances list --filter="name=($NAME)" --format="value(status)" --project=$GOOGLE_CLOUD_PROJECT_ID`

if [ $STATUS = "TERMINATED" ]; then
    gcloud compute instances start $NAME --zone=$ZONE --project=$GOOGLE_CLOUD_PROJECT_ID
    RET=$?
    [ $RET -ne 0 ] && exit $RET
fi

for i in `seq 1 60`; do
    if [ $STATUS != "RUNNING" ]; then
        sleep 1
    else
        break
    fi
done

sleep 10
exit 0