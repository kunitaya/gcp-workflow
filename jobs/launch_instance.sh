#!/bin/bash

#### Required variables
# GOOGLE_CLOUD_PROJECT_ID: GCP project ID
# NAME: Image source instance name

##!include include_GoogleCloudSDK

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