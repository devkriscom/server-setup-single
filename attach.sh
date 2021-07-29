#!/bin/bash

echo "
auto eth0:1
iface eth0:1 inet static
address 95.111.194.12
netmask 255.255.255.255
" >> /etc/network/interfaces
sudo systemctl restart networking