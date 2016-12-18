#!/bin/bash

set -e

source /opt/cronjobs/postgres/bin/job_logger.source.sh

SYSLOG_TAG="[CRON-${USER}: logrotate ${$}]"

STATE_DIR=/opt/cronjobs/postgres/var/lib/logrotate

if [ ! -d "$STATE_DIR" ]; then
  mkdir -p "$STATE_DIR"
fi

/usr/sbin/logrotate --state $STATE_DIR/status $@
