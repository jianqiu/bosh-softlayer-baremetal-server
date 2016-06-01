#!/bin/bash

#Setup the network
cp 70-persistent-net.rules /mnt/etc/udev/rules.d/
eth0_mac=`ip link show eth0 | grep ether | sed "s/.*ether *//g" | sed "s/ brd .*//g"`
eth1_mac=`ip link show eth1 | grep ether | sed "s/.*ether *//g" | sed "s/ brd .*//g"`
eth2_mac=`ip link show eth2 | grep ether | sed "s/.*ether *//g" | sed "s/ brd .*//g"`
eth3_mac=`ip link show eth3 | grep ether | sed "s/.*ether *//g" | sed "s/ brd .*//g"`
eth4_mac=`ip link show eth4 | grep ether | sed "s/.*ether *//g" | sed "s/ brd .*//g"`
eth5_mac=`ip link show eth5 | grep ether | sed "s/.*ether *//g" | sed "s/ brd .*//g"`
sed -i "s/ETH0_MAC/$eth0_mac/" /mnt/etc/udev/rules.d/70-persistent-net.rules
sed -i "s/ETH1_MAC/$eth1_mac/" /mnt/etc/udev/rules.d/70-persistent-net.rules
sed -i "s/ETH2_MAC/$eth2_mac/" /mnt/etc/udev/rules.d/70-persistent-net.rules
sed -i "s/ETH3_MAC/$eth3_mac/" /mnt/etc/udev/rules.d/70-persistent-net.rules
sed -i "s/ETH4_MAC/$eth4_mac/" /mnt/etc/udev/rules.d/70-persistent-net.rules
sed -i "s/ETH5_MAC/$eth5_mac/" /mnt/etc/udev/rules.d/70-persistent-net.rules
cp interfaces /mnt/etc/network/
sed -i "s/PRIVATE_IP/$PRIVATE_IP/" /mnt/etc/network/interfaces
sed -i "s/PRIVATE_NETMASK/$PRIVATE_NETMASK/" /mnt/etc/network/interfaces
sed -i "s/PRIVATE_GATEWAY/$PRIVATE_GATEWAY/" /mnt/etc/network/interfaces
sed -i "s/PUBLIC_IP/$PUBLIC_IP/" /mnt/etc/network/interfaces
sed -i "s/PUBLIC_NETMASK/$PUBLIC_NETMASK/" /mnt/etc/network/interfaces
sed -i "s/PUBLIC_GATEWAY/$PUBLIC_GATEWAY/" /mnt/etc/network/interfaces

