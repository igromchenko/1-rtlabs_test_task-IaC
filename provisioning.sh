#!/bin/bash

server_ip=$1
master_ip=$2
worker_ip=$3

while : ; do
ssh -q -o "StrictHostKeyChecking=no" -o "ConnectTimeout=10" igromchenko@$server_ip exit && ssh -q -o "StrictHostKeyChecking=no" -o "ConnectTimeout=10" igromchenko@$master_ip exit && ssh -q -o "StrictHostKeyChecking=no" -o "ConnectTimeout=10" igromchenko@$worker_ip exit
[ $? -eq 0 ]&& break
echo "Waiting for nodes initialization..."
done

echo "CONNECTING TO NODES FOR PROVISIONING..."
ansible-playbook -i inventory playbook.yml
