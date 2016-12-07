#!/bin/bash

# Source to gain syslog logging

TEMP_ERR_FILE=$(mktemp)
exec 2> $TEMP_ERR_FILE

function cleanup {
    if [ -n "$TEMP_ERR_FILE" ] && [ -f "$TEMP_ERR_FILE" ]; then
        rm -rf "$TEMP_ERR_FILE"
    fi
}
trap cleanup EXIT INT TERM HUP

function this_logger {
    local facility="$1"
    local severity="$2"
    shift ; shift
    logger -t "$SYSLOG_TAG" -p "$facility.$severity" $@
}

function error {
    local lineno=$1  
    local msg="$2"
    local ecode="${3:-1}"

    if [ -z "$msg" ]; then
        msg=$(cat "$TEMP_ERR_FILE")
    fi
    this_logger error "Error line ${lineno} (exit ${ecode}): ${msg}"
}

trap 'error ${LINENO}' ERR
