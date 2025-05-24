#!/bin/sh
set -e

if [ -n "$LOCAL_USER_ID" ] && [ -n "$LOCAL_GROUP_ID" ]; then
	echo "Creating host user with UID=$LOCAL_USER_ID and GID=$LOCAL_GROUP_ID"

	if ! getent group hostgroup >/dev/null 2>&1; then
		addgroup -g "$LOCAL_GROUP_ID" hostgroup
	fi

	if ! id hostuser >/dev/null 2>&1; then
		adduser -u "$LOCAL_USER_ID" -G hostgroup -D hostuser
	fi

	echo "Updating permissions on /data/foundryvtt and /opt/foundryvtt..."
	chown -R hostuser:hostgroup /data/foundryvtt /opt/foundryvtt

	echo "Dropping privileges to hostuser and starting run-server.sh..."
	exec su-exec hostuser /opt/foundryvtt/run-server.sh "$@"
fi

exec /opt/foundryvtt/run-server.sh "$@"
