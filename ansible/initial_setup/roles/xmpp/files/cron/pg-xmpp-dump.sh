#!/bin/bash

set -e

source /opt/cronjobs/postgres/bin/job_logger.source.sh

export USER=$(id -un)

SYSLOG_TAG="[CRON-$USER: DB_Slave ${$}]"

THIS_SCRIPT="$(realpath $0)"

#From $HOME/.local/share/cron/ to $HOME/.local/bin/
LOGROTATE_USER_WRAPPER="$(realpath $(dirname $THIS_SCRIPT)/../bin/logrotate_user_wrapper.sh)"
LOGROTATE_USER_CONF="$(realpath $(dirname $THIS_SCRIPT)/../etc/pg_dump_logrotate.conf)"

if [ "$(id -un)" != "postgres" ]; then
  if [ "$(id -u)" != "0" ]; then
    this_logger cron error "Not \`\`postgres'' user, neither root; exiting."
    exit 1
  else
    this_logger cron notice "Run as root; becoming \`\`postgres'' user. Please run this job as user \`\`postgres'' instead."
    exec su postgres -c "$THIS_SCRIPT"
  fi
fi

PG_BACKUP_DIR=/var/backups/postgres
DUMP_DIR=$PG_BACKUP_DIR
DB_NAME=prosody_db

if [ ! -d "$DUMP_DIR" ]; then
  mkdir -p "$DUMP_DIR"
fi

cd "$DUMP_DIR"
DUMP_NAME="${DB_NAME}-dump-$(date +%s).pgz"

# '.pgz' ext named after the custom compressed psql format
# (which allows discriminated restoration by table)
/usr/bin/pg_dump -Fc "$DB_NAME" > "$DUMP_NAME"

if [ ! -f "$DUMP_NAME" ]; then
    this_logger cron error "The new dump is missing !"
    exit 1
fi

ROTATABLE_NAME="prosody_db-dump.pgz"

if [ -f "$ROTATABLE_NAME" ]; then
    this_logger cron notice "Found previous dump. Force-rotating..."
    $LOGROTATE_USER_WRAPPER --force $LOGROTATE_USER_CONF
fi

mv "$DUMP_NAME" "$ROTATABLE_NAME"
