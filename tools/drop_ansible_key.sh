#!/bin/bash

# Connect with password (provided separetely in ./pass.ish)
# And drop the Ansible servers's public RSA keys on hosts' root.

function purge_sshpass {
  trap '' SIGINT SIGTERM SIGHUP SIGUSR1 SIGUSR2 QUIT ERR
  term=$(tty)
  if [ "$term" == "not a tty" ]; then term=/dev/null; fi
  ( nohup sudo apt-get autoremove --purge -y sshpass > $term )
  exit 0
}

# Pull password list.
source ./pass.ish

key_path=/home/ansible/.ssh/id_rsa.pub

trap purge_sshpass SIGINT SIGTERM SIGHUP SIGUSR1 SIGUSR2 QUIT ERR
sudo apt-get install -y sshpass || exit 1

for i in $(seq 1 10); do
  s=S$i
  echo \* Copying on s${i}... >&2
  SSHPASS=${!s} sshpass -e \
    ssh \
      '-oStrictHostKeyChecking=no' \
      root@192.168.54.$i \
      'mkdir -p /root/.ssh && cat - >> /root/.ssh/authorized_keys' \
      < $key_path
  echo Result: $? >&2
done

purge_sshpass
