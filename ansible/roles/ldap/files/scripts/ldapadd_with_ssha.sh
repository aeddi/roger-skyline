#!/bin/bash

if (($# < 2)); then
  echo "Usage: $0 <ldif> <UID> [OU]" >&2
  exit 1
fi

STUB_SUFFIX='_stub'
TARGET_USER="$2"
TARGET_PASS=$(slappasswd -h '{SSHA}' -s "TARGET_USER")
LDIF_STUB="$1"
BARE_STUB="${LDIF_STUB%.*}"
LDIF="${BARE_STUB%$STUB_SUFFIX}.ldif"

EXISTS="$(shift; /tmp/ldap_exists.sh $@)"

if [ "$EXISTS" == "" ]; then
  umask 177
  cat "$LDIF_STUB" <(echo "userPassword: $TARGET_PASS") > "$LDIF"
  ldapadd -x -w "$ROOTPW" -D 'cn=admin,dc=slash16,dc=local' -f "$LDIF" >&2
else
  echo $EXISTS
fi
exit $?
