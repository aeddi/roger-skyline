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
    mkdir -m 755 -p "$PULL_DIR"
fi

BACKUPAGENT_HOSTSFILE="$HOME/backup-agent-hosts"
BACKUPAGENT_PLAYBOOK="$HOME/backup-agent-playbook.yml"

# If stdout is not a terminal, devnull it
# when calling ansible-playbook.
FD1_TARGET=$(readlink /proc/$$/fd/1)
if grep -q pts <<< "$FD1_TARGET"
then
    true
else
    exec 1> /dev/null
fi

# Run in parallel
TASK_TAGS=(versioning syslog prod_db mail monitoring)
TASK_PIDS=()
i=0
while ((i < ${#TASK_TAGS[@]} ))
do
# Ensure pull subdirs are not world-readable !
  if [ ! -d "${PULL_DIR}/${TASK_TAGS[${i}]}" ]; then
      mkdir -m 700 -p "${PULL_DIR}/${TASK_TAGS[${i}]}"
  else
      pullsubdir_mode=$(stat -c %a "${PULL_DIR}/${TASK_TAGS[${i}]}")
      if [ ! "$pullsubdir_mode" == "700"  ]; then
          chmod 700 "${PULL_DIR}/${TASK_TAGS[${i}]}"
      fi
  fi
# If the ansible fetch job succeeds, ``touch'' the associated
# folder, so that monitoring may determine the backup
# routine went well.
  (
    /usr/bin/ansible-playbook \
      -i $BACKUPAGENT_HOSTSFILE $BACKUPAGENT_PLAYBOOK \
      --tags ${TASK_TAGS[${i}]} \
      && touch "${PULL_DIR}/${TASK_TAGS[${i}]}"
  ) & \
  TASK_PIDS[${i}]=$!
  let i+=1
done

if grep -q pts <<< "$FD1_TARGET"
then
  true
else
  exec 1>> "$FD1_TARGET"
fi
wait ${TASK_PIDS[@]}
