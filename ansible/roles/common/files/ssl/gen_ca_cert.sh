certtool -p --outfile ca_certs.key
certtool -s --load-privkey ca_certs.key --template ca_certs.conf --outfile ca_server.pem
