#!/bin/bash

#### Required variables
# GOOGLE_CLOUD_PROJECT_ID: GCP project ID
# BACKEND_SERVICE_NAME: Target backend service name
# INSTANCE_GROUP: Target instance group

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/usr/local/src/google-cloud-sdk/path.bash.inc' ]; then
    . '/usr/local/src/google-cloud-sdk/path.bash.inc'
fi

# The next line enables shell command completion for gcloud.
if [ -f '/usr/local/src/google-cloud-sdk/completion.bash.inc' ]; then
    . '/usr/local/src/google-cloud-sdk/completion.bash.inc'
fi


gcloud compute backend-services remove-backend $BACKEND_SERVICE_NAME \
    --instance-group=$INSTANCE_GROUP \
    --instance-group-zone=`gcloud compute instance-groups list --filter="name=($INSTANCE_GROUP)" --format="value(zone.basename())" --project=$GOOGLE_CLOUD_PROJECT_ID` \
    --global \
    --project=$GOOGLE_CLOUD_PROJECT_ID

exit $?