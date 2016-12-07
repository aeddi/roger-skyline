#!/bin/bash

set -e

source /home/git/.local/bin/job_logger.source.sh

# $USER env var is not set when run by cron(8).
# GoGS seems to be checking the "runuser" (from env)
# vs the name matching the current R/EUID
export USER=$(id -un)

SYSLOG_TAG="[CRON-$USER: GoGS-Dump ${$}]"

THIS_SCRIPT="$(realpath $0)"

#From $HOME/.local/share/cron/ to $HOME/.local/bin/
LOGROTATE_USER_WRAPPER="$(realpath $(dirname $THIS_SCRIPT)/../bin/logrotate_user_wrapper.sh)"
LOGROTATE_USER_CONF="$(realpath $(dirname $THIS_SCRIPT)/../etc/gogs_dump_logrotate.conf)"

if [ "$(id -un)" != "git" ]; then
  if [ "$(id -u)" != "0" ]; then
    this_logger cron error "Not \`\`git'' user, neither root; exiting."
    exit 1
  else
    this_logger cron notice "Run as root; becoming \`\`git'' user. Please run this job as user \`\`git'' instead."
    exec su git -c "$THIS_SCRIPT"
  fi
fi

GITUSER_HOME=/home/git
DUMP_DIR=$GITUSER_HOME/gogs-dumps

if [ ! -d "$DUMP_DIR" ]; then
  mkdir -p "$DUMP_DIR"
fi

cd "$DUMP_DIR"

(
    IFS=$'\n'
    for l in $( "$GITUSER_HOME/link-gogs/gogs" dump 2>&1 ); do
        this_logger cron info "$l"
    done
)
NEW_DUMP=$( ls -1t | egrep 'gogs-dump-[0-9]+\.zip' | head -n1 )

ROTATABLE_NAME="gogs-dump.zip"

if [ -f "$ROTATABLE_NAME" ]; then
    this_logger cron notice "Found previous dump. Force-rotating..."
    $LOGROTATE_USER_WRAPPER --force $LOGROTATE_USER_CONF
fi

mv "$NEW_DUMP" "$ROTATABLE_NAME"

if [ -z "$NEW_DUMP" ] || [ "$NEW_DUMP" == "$LAST_DUMP" ]; then
    this_logger cron error "The new dump is missing !"
    exit 1
fi
