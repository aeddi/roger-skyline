certtool -p --sec-param high --outfile cert.key
certtool -c --load-privkey cert.key --load-ca-certificate ca_cert.pem --load-ca-privkey ca_cert.key --template cert.conf --outfile cert.pem
