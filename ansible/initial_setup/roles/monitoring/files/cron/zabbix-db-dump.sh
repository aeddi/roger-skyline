#!/bin/bash

set -e

source /opt/cronjobs/zabbix/bin/job_logger.source.sh

export USER=$(id -un)

SYSLOG_TAG="[CRON-$USER: DB_Slave ${$}]"

THIS_SCRIPT="$(realpath $0)"

#From $HOME/.local/share/cron/ to $HOME/.local/bin/
LOGROTATE_USER_WRAPPER="$(realpath $(dirname $THIS_SCRIPT)/../bin/logrotate_user_wrapper.sh)"
LOGROTATE_USER_CONF="$(realpath $(dirname $THIS_SCRIPT)/../etc/zabbix_dump_logrotate.conf)"
ZABBIX_DB_USER=zabbix
ZABBIX_DB_PASSW=$ZABBIX_DB_USER
DUMP_HELPER_SCRIPT="$(realpath $(dirname $THIS_SCRIPT)/../../../helpers/zabbix/bin/zabbix-mysql-dump)"

if [ "$(id -un)" != "zabbix" ]; then
  if [ "$(id -u)" != "0" ]; then
    this_logger cron error "Not \`\`zabbix'' user, neither root; exiting."
    exit 1
  else
    this_logger cron notice "Run as root; becoming \`\`zabbix'' user. Please run this job as user \`\`zabbix'' instead."
    exec su zabbix -c "$THIS_SCRIPT"
  fi
fi

PG_BACKUP_DIR=/var/backups/zabbix
DUMP_DIR=$PG_BACKUP_DIR

if [ ! -d "$DUMP_DIR" ]; then
  mkdir -p "$DUMP_DIR"
fi

cd "$DUMP_DIR"
DUMP_NAME=$(
    "$DUMP_HELPER_SCRIPT" -o "$DUMP_DIR" -u "$ZABBIX_DB_USER" -p "$ZABBIX_DB_PASSW" | tail -n1
)

if [ ! -f "$DUMP_NAME" ]; then
    this_logger cron error "The new dump is missing !"
    exit 1
fi

ROTATABLE_NAME="zabbix_cfg_db.sql.gz"

if [ -f "$ROTATABLE_NAME" ]; then
    this_logger cron notice "Found previous dump. Force-rotating..."
    $LOGROTATE_USER_WRAPPER --force $LOGROTATE_USER_CONF
fi

mv "$DUMP_NAME" "$ROTATABLE_NAME"
