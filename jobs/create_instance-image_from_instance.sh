#!/bin/bash

#### Required variables
# GOOGLE_CLOUD_PROJECT_ID: GCP project ID
# IMAGE_NAME: the name of the instance image
# NAME: Image source instance name
# LOCATION: Specifies a Cloud Storage location

##!include include_GoogleCloudSDK

SOURCE_DISK=`gcloud compute instances list --filter="name=($NAME)" --format="value(disks.source.basename())" --project=$GOOGLE_CLOUD_PROJECT_ID`
SOURCE_DISK_ZONE=`gcloud compute disks list --filter="name=($SOURCE_DISK)" --format="value(zone.basename())" --project=$GOOGLE_CLOUD_PROJECT_ID`


# terminate the base instance
STATUS=`gcloud compute instances list --filter="name=($NAME)" --format="value(status)" --project=$GOOGLE_CLOUD_PROJECT_ID`
if [ $STATUS != "TERMINATED" ]; then
    ZONE=`gcloud compute instances list --filter="name=($NAME)" --format="value(zone.basename())" --project=$GOOGLE_CLOUD_PROJECT_ID`
    gcloud compute instances stop $NAME --zone=$ZONE --project=$GOOGLE_CLOUD_PROJECT_ID
    RET=$?
    [ $RET -ne 0 ]&& exit $RET

    for i in `seq 1 60`; do
        STATUS=`gcloud compute instances list --filter="name=($NAME)" --format="value(status)" --project=$GOOGLE_CLOUD_PROJECT_ID`
        if [ $STATUS != "TERMINATED" ]; then
            sleep 1
        else
            break
        fi
    done
fi


gcloud compute images \
    create $IMAGE_NAME \
    --source-disk=$SOURCE_DISK \
    --source-disk-zone=$SOURCE_DISK_ZONE \
    --storage-location=$LOCATION \
    --project=$GOOGLE_CLOUD_PROJECT_ID

exit $?