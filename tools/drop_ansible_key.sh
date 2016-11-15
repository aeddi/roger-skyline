#!/bin/bash

function purge_sshpass {
  trap 'true' SIGINT SIGTERM SIGHUP SIGUSR1 SIGUSR2 ERR
  sudo apt-get autoremove --purge -y sshpass || true
  exit 0
}

# Pull password list where it resides.
source=./pass.ish

key_path=/home/ansible/.ssh/id_rsa.pub

trap purge_sshpass SIGINT SIGTERM SIGHUP SIGUSR1 SIGUSR2 ERR
sudo apt-get install -y sshpass || exit 1

for i in $(seq 1 10); do
  s=S$i
  echo \* Copying on s${i}... >&2
  SSHPASS=${!s} sshpass -e \
    ssh \
      '-oStrictHostKeyChecking=no' \
      root@192.168.54.$i \
      'mkdir -p /root/.ssh && cat - > /root/.ssh/authorized_keys' \
      < $key_path
  echo Result: $? >&2
done

purge_sshpass
