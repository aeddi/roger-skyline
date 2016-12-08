#!/bin/bash

set -e

BACKUPAGENT_HOME=/home/backup-agent
source $BACKUPAGENT_HOME/cronjobs/bin/job_logger.source.sh

# $USER env var is not set when run by cron(8).
# For commands trying to use $USER
export USER=$(id -un)

SYSLOG_TAG="[CRON-BackupAgent ${$}]"

THIS_SCRIPT="$(realpath $0)"

if [ "$USER" != "backup-agent" ]; then
  if [ "$(id -u)" != "0" ]; then
    this_logger cron error "Not \`\`backup-agent'' user, neither root; exiting."
    exit 1
  else
    this_logger cron notice "Run as root; becoming \`\`backup-agent'' user. Please run this job as user \`\`backup-agent'' instead."
    exec su backup-agent -c "$THIS_SCRIPT"
  fi
fi

cd $BACKUPAGENT_HOME
export HOME=$BACKUPAGENT_HOME

PULL_DIR=$BACKUPAGENT_HOME/pull

if [ ! -d "$PULL_DIR" ]; then
  mkdir -p "$PULL_DIR"
fi

BACKUPAGENT_HOSTSFILE="$HOME/backup-agent-hosts"
BACKUPAGENT_PLAYBOOK="$HOME/backup-agent-playbook.yml"

/usr/bin/ansible-playbook -i $BACKUPAGENT_HOSTSFILE $BACKUPAGENT_PLAYBOOK
