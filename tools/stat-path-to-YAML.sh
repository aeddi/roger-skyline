#!/bin/bash

set -e


only=
shift_amount=0

if [ "${1:0:1}" == "-" ]; then
  for a in $@; do
    if [ "${a:0:1}" != "-" ]; then break; fi
    if [ "$a" == "--" ]; then let shift_amount+=1; break; fi
    if [ "$a" == "-d" ]; then only=d; let shift_amount+=1; fi
    if [ "$a" == "-f" ]; then only=f; let shift_amount+=1; fi
  done
fi

shift $shift_amount

if (( $# < 1 )); then
  echo "Usage: $0 [ -d | -f | -- ] [<path-to-stat>, ...]" 1>&2
  exit 1
fi


function list_type {

  local find_type=${1:0:1}
  local prefix=${2:0:1}

  shift 2

  while (( $# > 0 )); do
  
    local files=$(find $1 -type $find_type)
  
    for f in $files; do
      local fstated=$(stat -c "- { src: ${f#/}, dest: $f, owner: %U, group: %G, mode: %#a }" $f)
      echo "$prefix $fstated"
    done
    shift
  done

}


if [ -z "$only" ] || [ "$only" == f ]; then
  list_type f ' ' $@
  if [ "$only" == f ]; then exit 0; fi
fi

if [ -z "$only" ] || [ "$only" == d ]; then
  list_type d 'D' $@
  if [ "$only" == d ]; then exit 0; fi
fi

