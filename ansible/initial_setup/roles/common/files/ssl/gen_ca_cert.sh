certtool -p --outfile ca_cert.key
certtool -s \
    --load-privkey ca_cert.key \
    --template ca_cert.conf \
    --outfile ca_cert.pem 

