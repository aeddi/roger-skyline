#!/bin/bash

set -e

olcAccess_ref_ldif='dn: olcDatabase={-1}frontend,cn=config
olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external
 ,cn=auth manage by * break
olcAccess: {1}to dn.exact="" by * read
olcAccess: {2}to dn.base="cn=Subschema" by * read

dn: olcDatabase={0}config,cn=config
olcAccess: {0}to * by dn.exact=gidNumber=0+uidNumber=0,cn=peercred,cn=external
 ,cn=auth manage by * break

dn: olcDatabase={1}mdb,cn=config
olcAccess: {0}to attrs=userPassword,shadowLastChange by self write by anonymou
 s auth by dn.children="ou=services,dc=slash16,dc=local" compare by * none
olcAccess: {1}to dn.base="" by * read
olcAccess: {2}to * by * read

'

SEARCH_CMD="ldapsearch -LLL -Y EXTERN -H ldapi:/// -b 'cn=config' 'olcDatabase=*'  olcAccess 2>/dev/null"

diff <(echo -n "$olcAccess_ref_ldif") <(eval $SEARCH_CMD) || true
