#!/bin/bash

#### Required variables
# GOOGLE_CLOUD_PROJECT_ID: GCP project ID
# INSTANCE_GROUP: Target instance group

##!include include_GoogleCloudSDK

ZONE=`gcloud compute instance-groups list --filter="name=($INSTANCE_GROUP)" --format="value(zone.basename())" --project=$GOOGLE_CLOUD_PROJECT_ID`
INSTANCES=`gcloud compute instance-groups list-instances $INSTANCE_GROUP --zone=$ZONE --format='value(instance.basename())' --project=$GOOGLE_CLOUD_PROJECT_ID`
IP=()
for i in $INSTANCES; do
    IP+=(`gcloud compute instances list --filter="name=($i)" --format="get(networkInterfaces[0].accessConfigs[0].natIP)" --project=$GOOGLE_CLOUD_PROJECT_ID`)
done

echo "IP_ADDRESS=IP addresses($INSTANCE_GROUP): ${IP[@]}" >> $JS7_RETURN_VALUES