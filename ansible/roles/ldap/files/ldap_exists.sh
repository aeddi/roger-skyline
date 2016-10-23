#!/bin/bash

if (($# < 1)); then
  echo "Usage: $0 <UID> [OU]" >&2
  exit 1
fi

FILTER="(uid=$1)"

if [[ ! -z "$2" ]]; then
    BASE=$(echo "-b ou=${2},dc=slash16,dc=local")
fi

EXISTS=$(ldapsearch -x -LLL $BASE "$FILTER" dn | grep '^dn:')

if [[ ! -z "$EXISTS" ]]; then
  echo exists
fi
