#!/bin/bash

#### Required variables
# GOOGLE_CLOUD_PROJECT_ID: GCP project ID
# INSTANCE_GROUP_PREFIX: Target instance group prefix
# NAME: Image source instance name

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/usr/local/src/google-cloud-sdk/path.bash.inc' ]; then
    . '/usr/local/src/google-cloud-sdk/path.bash.inc'
fi

# The next line enables shell command completion for gcloud.
if [ -f '/usr/local/src/google-cloud-sdk/completion.bash.inc' ]; then
    . '/usr/local/src/google-cloud-sdk/completion.bash.inc'
fi

gcloud config set project $GOOGLE_CLOUD_PROJECT_ID
[ $? -ne 0 ] && exit 1

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