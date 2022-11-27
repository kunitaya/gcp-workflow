#!/bin/bash

#### Required variables
# GOOGLE_CLOUD_PROJECT_ID: GCP project ID
# INSTANCE_GROUP_PREFIX: Target instance group prefix
# RESULT: workflow result
# SLACK_WEBHOOK_URL: Slack webhook URLs

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/usr/local/src/google-cloud-sdk/path.bash.inc' ]; then
    . '/usr/local/src/google-cloud-sdk/path.bash.inc'
fi

# The next line enables shell command completion for gcloud.
if [ -f '/usr/local/src/google-cloud-sdk/completion.bash.inc' ]; then
    . '/usr/local/src/google-cloud-sdk/completion.bash.inc'
fi

INSTANCE_GROUPS="`gcloud compute instance-groups list --format='get(name)' --project=$GOOGLE_CLOUD_PROJECT_ID | grep $INSTANCE_GROUP_PREFIX`"

IP_ADDRESS_LIST=()
for GROUP in $INSTANCE_GROUPS; do
    ZONE=`gcloud compute instance-groups list --filter="name=($GROUP)" --format='value(zone.basename())' --project=$GOOGLE_CLOUD_PROJECT_ID`
    INSTANCES=`gcloud compute instance-groups list-instances $GROUP --zone=$ZONE --format='value(instance.basename())' --project=$GOOGLE_CLOUD_PROJECT_ID`
    for I in $INSTANCES; do
        IP_ADDRESS_LIST+=(`gcloud compute instances list --filter="name=($I)" --format="get(networkInterfaces[0].accessConfigs[0].natIP)" --project=$GOOGLE_CLOUD_PROJECT_ID`)
    done
done

IFS_BK=$IFS
IP_ADDRESSES="$(IFS='#'; echo "${IP_ADDRESS_LIST[*]}")"
IFS=$IFS_BK
IP_ADDRESS=`echo "$IP_ADDRESSES" | sed -e 's/#/\\\\n/g'`

JSON=`cat << _EOS_
{
	"blocks": [
		{
			"type": "header",
			"text": {
				"type": "plain_text",
				"text": "Deployment result",
				"emoji": true
			}
		},
		{
			"type": "section",
			"fields": [
				{
					"type": "mrkdwn",
					"text": "*GCP Project id*"
				},
				{
					"type": "mrkdwn",
					"text": "$GOOGLE_CLOUD_PROJECT_ID"
				}
			]
		},
		{
			"type": "section",
			"fields": [
				{
					"type": "mrkdwn",
					"text": "*Result*"
				},
				{
					"type": "mrkdwn",
					"text": "$RESULT"
				}
			]
		},
		{
			"type": "section",
			"fields": [
				{
					"type": "mrkdwn",
					"text": "*IP Addresses*"
				},
				{
					"type": "mrkdwn",
					"text": "$IP_ADDRESS"
				}
			]
		}
	]
}
_EOS_
`
JSON=`echo "$JSON" | jq -rc .`
PAYLOAD="payload=$JSON"

curl --silent -XPOST --data-urlencode "${PAYLOAD}" "$SLACK_WEBHOOK_URL"
exit $?