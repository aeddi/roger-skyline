#!/bin/bash

# Source to gain syslog logging

TEMP_ERR_FILE=$(mktemp)
EXIT_TRAP=this_atexit
if readlink /proc/$$/fd/2 | grep -q pts; then
    exec 2> >(tee $TEMP_ERR_FILE >&2)
else
    exec 2> $TEMP_ERR_FILE
fi

function this_atexit {
    if [ -n "$TEMP_ERR_FILE" ] && [ -f "$TEMP_ERR_FILE" ]; then
        rm -rf "$TEMP_ERR_FILE"
    fi
}
# EXIT manages any blockable sig and ERR.
EXIT_CONDITIONS=(EXIT)
trap "${EXIT_TRAP}" ${EXIT_CONDITIONS[@]}

function this_logger {
    local facility="$1"
    local severity="$2"
    shift ; shift
    logger -t "$SYSLOG_TAG" -p "$facility.$severity" $@
}

function this_onerror {
    local lineno=$1  
    local msg="$2"
    local ecode="${3:-1}"

    if [ -z "$msg" ]; then
        msg=$(cat "$TEMP_ERR_FILE")
    fi
    if readlink /proc/$$/fd/1 | grep -q pts; then
      echo "Error line ${lineno} (exit ${ecode}): ${msg}"
    fi
    save_IFS="${IFS}"
    this_logger cron error "Error line ${lineno} (exit ${ecode}):"
    IFS=$'\n'
    for l in "$msg"; do
        this_logger cron error "${l}"
    done
    IFS="${save_IFS}"
}

trap 'this_onerror ${LINENO}' ERR
