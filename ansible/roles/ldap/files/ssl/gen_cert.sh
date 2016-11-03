certtool -p --sec-param high --outfile ldap.key
certtool -c \
    --load-privkey ldap.key \
    --load-ca-certificate ca_cert.pem \
    --load-ca-privkey ca_cert.key \
    --template ldap_cert.conf \
    --outfile ldap.pem

