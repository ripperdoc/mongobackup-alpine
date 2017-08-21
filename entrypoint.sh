#!/bin/bash
# Go to executing directory
cd "${0%/*}"
set -e

: ${MMS_SERVER:=api-backup.mongodb.com}

if [ ! "$MMS_API_KEY" ] || [ ! "$MMS_GROUP_ID" ]; then
	{
		echo 'error: MMS_API_KEY or MMS_GROUP_ID was not specified'
		echo 'try something like: docker run -e MMS_API_KEY=... MMS_GROUP_ID=...'
		echo '(see https://mms.mongodb.com/settings/monitoring-agent for your mmsApiKey)'
		echo
		echo 'Other optional variables:'
		echo ' - MMS_SERVER='"$MMS_SERVER"
	} >&2
	exit 1
fi

# "sed -i" can't operate on the file directly, and it tries to make a copy in the same directory, which our user can't do
config_tmp="$(mktemp)"
cat local.config > "$config_tmp"

set_config() {
	key="$1"
	value="$2"
	sed_escaped_value="$(echo "$value" | sed 's/[\/&]/\\&/g')"
	sed -ri "s/^($key)[ ]*=.*$/\1 = $sed_escaped_value/" "$config_tmp"
}

set_config mmsApiKey "$MMS_API_KEY"
set_config mothership "$MMS_SERVER"
set_config mmsGroupId "$MMS_GROUP_ID"

cat "$config_tmp" > local.config
rm "$config_tmp"

exec "$@"