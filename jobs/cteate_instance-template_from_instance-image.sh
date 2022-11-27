#!/bin/bash

#### Required variables
# GOOGLE_CLOUD_PROJECT_ID: GCP project ID
# IMAGE_NAME: the name of the instance image
# MACHINE_TYPE: Instance machine type
# SERVICE_ACCOUNT: Service account for running instances
# TEMPLATE_NAME: Target instance template name
# VERSION: Instance image version number

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/usr/local/src/google-cloud-sdk/path.bash.inc' ]; then
    . '/usr/local/src/google-cloud-sdk/path.bash.inc'
fi

# The next line enables shell command completion for gcloud.
if [ -f '/usr/local/src/google-cloud-sdk/completion.bash.inc' ]; then
    . '/usr/local/src/google-cloud-sdk/completion.bash.inc'
fi

LABELS="version=$VERSION"
TAGS="http-server"

# scopes
SCOPE_TARGETS=(
    "https://www.googleapis.com/auth/pubsub"
    "https://www.googleapis.com/auth/sqlservice.admin"
    "https://www.googleapis.com/auth/logging.write"
    "https://www.googleapis.com/auth/monitoring.write"
    "https://www.googleapis.com/auth/trace.append"
    "https://www.googleapis.com/auth/servicecontrol"
    "https://www.googleapis.com/auth/service.management.readonly"
    "https://www.googleapis.com/auth/devstorage.read_write"
)
IFS_BK=$IFS
SCOPES="$(IFS=,; echo "${SCOPE_TARGETS[*]}")"
IFS=$IFS_BK


## Create MetaData
# ssh keys
SSH_KEYS=$(cat << EOS
${PUBKEY_0##*\ }:${PUBKEY_0}
${PUBKEY_1##*\ }:${PUBKEY_1}
${PUBKEY_2##*\ }:${PUBKEY_2}
${PUBKEY_3##*\ }:${PUBKEY_3}
${PUBKEY_4##*\ }:${PUBKEY_4}
${PUBKEY_7##*\ }:${PUBKEY_7}
EOS
)
# startup script
STARTUP_SCRIPT=$(cat << 'EOS'
#!/bin/bash
systemctl status google-cloud-ops-agent
if [ $? -ne 0 ]; then
    cd /var/tmp
    curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
    chmod +x add-google-cloud-ops-agent-repo.sh
    ./add-google-cloud-ops-agent-repo.sh --also-install

    if [ -f /etc/google-cloud-ops-agent/config.yaml.rpmorig ]; then
        sudo mv -f /etc/google-cloud-ops-agent/config.yaml.rpmorig /etc/google-cloud-ops-agent/config.yaml
        sudo systemctl restart google-cloud-ops-agent
    fi
fi
systemctl enable --now nginx
EOS
)
# create metadata
METADATA="ssh-keys=$SSH_KEYS,startup-script=$STARTUP_SCRIPT"


## Create disk settings
DISK_IMAGE=`gcloud compute images list --filter="name=($IMAGE_NAME)" --format="value(selfLink.scope(v1))" --project=$GOOGLE_CLOUD_PROJECT_ID`
DISK_SETTINGS=(
    "auto-delete=yes"
    "boot=yes"
    "device-name=$TEMPLATE_NAME"
    "image=$DISK_IMAGE"
    "mode=rw"
    "size=20"
    "type=pd-balanced"
)
IFS_BK=$IFS
CREATE_DISK="$(IFS=,; echo "${DISK_SETTINGS[*]}")"
IFS=$IFS_BK


gcloud compute instance-templates \
    create "$TEMPLATE_NAME" \
    --machine-type="$MACHINE_TYPE" \
    --network-interface=network=default,network-tier=PREMIUM,address='' \
    --metadata="$METADATA" \
    --maintenance-policy=MIGRATE \
    --provisioning-model=STANDARD \
    --service-account="$SERVICE_ACCOUNT" \
    --scopes="$SCOPES" \
    --create-disk="$CREATE_DISK" \
    --no-shielded-secure-boot \
    --shielded-vtpm \
    --shielded-integrity-monitoring \
    --labels="$LABELS" \
    --tags="$TAGS" \
    --reservation-affinity=any \
    --project="$GOOGLE_CLOUD_PROJECT_ID"

exit $?