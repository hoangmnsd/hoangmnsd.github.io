---
title: "Azure: How to change private IP of VM, Vnet, Subnet, Load balancer"
date: 2021-10-30T15:24:42+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Azure]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "You cannot move a VM from a Vnet/subnet to different Vnet/subnet without re-creating the VM. But in some specific cases, you may not have to move VM to another Vnet/subnet, it will be easier when you just change the private IP of Vnet/subnet/VM/Load balancer... "
---

You cannot move a VM from a Vnet/subnet to different Vnet/subnet without re-creating the VM. But in some specific cases, you may not have to move VM to another Vnet/subnet, it will be easier when you just change the private IP of Vnet/subnet/VM/Load balancer... 

# Background

Assume that you're having a Virtual machine with private IP is: `10.20.1.8` and you want to change it to: `10.25.2.9`.  
 See this picture:  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-vnet-subnet-ip.jpg)

Note that this article is not about moving VM to a different Vnet/Subnet. This article is about changing the private IP of Vnet, Subnet, VM, etc...

If you try to change directly in Network interface portal, you may encounter this error:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-changeip-error.jpg)

It means you have to change the Subnet IP range, Vnet IP range also.

# Steps

## 1. Create new address space for VNet

(optional) if your Vnet is peering with other Vnet, you should delete the peering first

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-changeip-vnet-add-space.jpg)

## 2. Create new subnet 

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-changeip-new-subnet.jpg)

## 3. Config on Network interface (NIC)

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-changeip-nic-click-to-static.jpg)

Change IP configuration from `Static` to `Dynamic`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-changeip-to-dynamic.jpg)

Change the subnet of NIC:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-changeip-nic-change-snet.jpg)

After above step, your VM is already placed in the new Subnet: 
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-changeip-result-nic-dynamic.jpg)

On the NIC IP configuration, change VM private IP from Dynamic → Static and set it `10.25.2.9`:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-changeip-ip-static-new.jpg)

Now your VM is already have your desired private IP:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-changeip-vm-new-ip.jpg)

## 4. Delete redundancy resources

- Delete the old Subnet  
- Delete the old address space of Vnet

Now you can re-create the Vnet Peering, then try to access the VM with new private IP to test connection.

## About Load balancer private IP

In case you want to change Load balancer private IP, try these steps:

- Create new frontend LB configuration
- Take note the LB rule, health probe config
- Delete old frontend LB configuration
- Re-create new LB rule, health probe config

