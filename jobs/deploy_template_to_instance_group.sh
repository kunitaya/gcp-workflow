#!/bin/bash

#### Required variables
# GOOGLE_CLOUD_PROJECT_ID: GCP project ID
# INSTANCE_GROUPS: Target instance groups
# TEMPLATE_NAME: Instance template name

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/usr/local/src/google-cloud-sdk/path.bash.inc' ]; then
    . '/usr/local/src/google-cloud-sdk/path.bash.inc'
fi

# The next line enables shell command completion for gcloud.
if [ -f '/usr/local/src/google-cloud-sdk/completion.bash.inc' ]; then
    . '/usr/local/src/google-cloud-sdk/completion.bash.inc'
fi

INSTANCE_GROUP_LIST=()
for i in $INSTANCE_GROUPS; do
    INSTANCE_GROUP_LIST+=($i)
done
INSTANCE_GROUP="${INSTANCE_GROUP_LIST[0]}"

ZONE=`gcloud compute instance-groups list --filter="name=($INSTANCE_GROUP)" --format="value(zone.basename())" --project=$GOOGLE_CLOUD_PROJECT_ID`
MIN_SIZE=`gcloud compute instance-groups list --filter="name=($INSTANCE_GROUP)" --format='get(size)' --project=$GOOGLE_CLOUD_PROJECT_ID`
TEMPLATE=`gcloud compute instance-templates list --filter="name=($TEMPLATE_NAME)" --format='value(selfLink.scope(v1))' --project=$GOOGLE_CLOUD_PROJECT_ID`

gcloud compute instance-groups managed rolling-action start-update $INSTANCE_GROUP \
    --type='proactive' \
    --max-surge=1 \
    --max-unavailable=1 \
    --minimal-action='refresh' \
    --most-disruptive-allowed-action='replace' \
    --replacement-method='substitute' \
    --zone=$ZONE \
    --version="template=$TEMPLATE" \
    --project=$GOOGLE_CLOUD_PROJECT_ID
[ $? -ne 0 ]&& exit 1

while :; do
    SIZE=`gcloud compute instance-groups list --filter="name=($INSTANCE_GROUP)" --format='get(size)' --project=$GOOGLE_CLOUD_PROJECT_ID`
    [ $SIZE -gt $MIN_SIZE ] && break
    sleep 10
done

while :; do
    SIZE=`gcloud compute instance-groups list --filter="name=($INSTANCE_GROUP)" --format='get(size)' --project=$GOOGLE_CLOUD_PROJECT_ID`
    [ $SIZE -le $MIN_SIZE ] && break
    sleep 10
done

STAT=`gcloud compute instance-groups list-instances $INSTANCE_GROUP --zone=$ZONE --format='get(status)' --project=$GOOGLE_CLOUD_PROJECT_ID | sort | uniq`
if [ $STAT == 'RUNNING' ]; then
    unset INSTANCE_GROUP_LIST[0]
    if [ ${#INSTANCE_GROUP_LIST[@]} -eq 0 ]; then
        echo "instance_groups=" >> $JS7_RETURN_VALUES
        echo "result=Success" >> $JS7_RETURN_VALUES
        exit 0
    fi
fi

echo "instance_groups=${INSTANCE_GROUP_LIST[@]}" >> $JS7_RETURN_VALUES
echo "result=Failure" >> $JS7_RETURN_VALUES
exit 1