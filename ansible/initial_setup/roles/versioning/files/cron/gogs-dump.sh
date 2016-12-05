#!/bin/bash

set -e

# Should be run as ``git'' user.
# May 'su git' if run as root.
#
# syslog: ``cron'' facility
#       with tag: [CRON: GoGS-Dump PID]
#
# Action:
# 1. Discovers last dump
# 2. Performs a new dump
# 3. Compares both crc32 with cksum
# 4. If equal, forcefully hard links the previous as new

THIS_SCRIPT="$(realpath $0)"

function this_logger {
  local severity="$1"
  shift
  logger -t "$SYSLOG_TAG" -p "cron.$severity" $@
}

function hard_link_dupes {
  local last_dump_crc32="$1"
  local new_dump_crc32="$2"

  if [ "$last_dump_crc32" == "$new_dump_crc32" ]; then
    ln -f "$LAST_DUMP" "$NEW_DUMP"
    this_logger info "New dump digest is the same as the previous ones'. Hard-linking..."
  fi
}

if [ "$(id -un)" != "git" ]; then
  if [ "$(id -u)" != "0" ]; then
    this_logger error "Not \`\`git'' user, neither root; exiting."
    exit 1
  else
    this_logger notice "Run as root; becoming \`\`git'' user. Please run this job as user \`\`git'' instead."
    exec su git -c "$THIS_SCRIPT"
  fi
fi

SYSLOG_TAG="[CRON: GoGS-Dump $$]"

GITUSER_HOME=/home/git
DUMP_DIR=$GITUSER_HOME/gogs-dumps

if [ ! -d "$DUMP_DIR" ]; then
  mkdir -p "$DUMP_DIR"
fi

cd "$DUMP_DIR"

LAST_DUMP=$( ls -1t | head -n1 )/

"$GITUSER_HOME/link-gogs/gogs" dump

NEW_DUMP=$( ls -1t | head -n1 )

if [ -z "$NEW_DUMP" ] || [ "$NEW_DUMP" == "$LAST_DUMP" ]; then
    this_logger error "The new dump is missing !"
    exit 1
fi

if [ ! -z "$LAST_DUMP" ] && [ -f "$LAST_DUMP" ]; then
  hard_link_dupes $( cksum "$LAST_DUMP" "$NEW_DUMP" | awk '{ print $1}' )
fi
