#!/bin/sh

STATE_DIR=/home/git/.local/var/lib/logrotate

if [ ! -d "$STATE_DIR" ]; then
  mkdir -p "$STATE_DIR"
fi

logrotate --state $STATE_DIR/status $@
