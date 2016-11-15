#!/bin/bash

# Untested -- roughly the routine to make the host ansible-ready
# As root

useradd -m ansible
chpasswd <<< ansible:ansible
apt-get update
apt-get install -y ansible vim git
mkdir -p /root/.ssh
su ansible -c 'mkdir /home/ansible/.ssh'
su ansible -c 'cd /home/ansible/.ssh && /bin/echo -e "\n\n\n\n\n" | ssh-keygen'
cat /home/ansible/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
