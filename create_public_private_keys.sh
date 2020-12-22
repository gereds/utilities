#!/bin/sh
#
# Author: Sandor Gered sandor.gered at gmail.com
# Brief:  Creates public/private keys to avoid using password when ssh into another machine
# Date:   2020-05-26

# If you want to ssh from A to B with no password, copy this script to A and run it
# For Windows users, start git bash, cd to home, copy this script there and start it

if [ "$#" -ne 3 ]; then
        execname=`basename $0`
        echo "Usage:  $execname server_ip server_name remote_user_name"
        echo "Example:"
        echo "        $execname 192.168.0.200 myraspi pi"
        echo "Creates and install private/public key pairs"
        echo "Then type \"myraspi\" to login to your server"
        exit 1
fi

cfg_file=~/.ssh/config
server_ip=$1
server_name=$2
remote_user_name=$3

key_file=~/.ssh/id_rsa_${server_name}
private_key=${key_file}
public_key=${key_file}.pub

echo "creating private/public keys pair for ${server_name}..."
ssh-keygen -t rsa -b 4096 -f ${private_key} -N ""

echo "adding ${server_ip} and ${server_name} to ssh..."
echo "Host ${server_ip} ${server_name}" >> ${cfg_file}
echo "        IdentityFile ${private_key}" >> ${cfg_file}

echo "Trying to copy public key on ${server_ip} with user ${remote_user_name}..."
echo
ssh-copy-id -i ${public_key} -f ${remote_user_name}@${server_ip}

echo "creating an alias for your server..."
echo "alias ${server_name}=\"ssh ${remote_user_name}@${server_ip}\"" >> ~/.bashrc
echo "echo \"type: ${server_name} to login to ${server_name}\"" >> ~/.bashrc
echo "" >> ~/.bashrc

echo
source ~/.bashrc
