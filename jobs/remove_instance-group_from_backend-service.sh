#!/bin/bash

#### Required variables
# GOOGLE_CLOUD_PROJECT_ID: GCP project ID
# BACKEND_SERVICE_NAME: Target backend service name
# INSTANCE_GROUP: Target instance group

##!include include_GoogleCloudSDK

gcloud compute backend-services remove-backend $BACKEND_SERVICE_NAME \
    --instance-group=$INSTANCE_GROUP \
    --instance-group-zone=`gcloud compute instance-groups list --filter="name=($INSTANCE_GROUP)" --format="value(zone.basename())" --project=$GOOGLE_CLOUD_PROJECT_ID` \
    --global \
    --project=$GOOGLE_CLOUD_PROJECT_ID

exit $?