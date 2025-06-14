---
title: "Troubleshoot Azure Linux VM: Internet & SSH Connections"
date: 2023-03-14T22:58:56+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [Azure]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "1 số cách fix lỗi không thể SSH vào Azure VM và mất kết nối internet"
---

# 1. Story

Mới đây mình gặp 1 tình huống là tạo 1 VM (Ubuntu18.04-LTS) trên Azure cho Dev sử dụng, có toàn quyền sudo luôn.  
Dev setup nhiều phần mềm, và sau 1 thời gian thì VM bị lỗi ko thể SSH vào được nữa. 

```
ssh: port 22: Connection timed out
```

Nói chung là sử dụng hàng Cloud thì xử lý những case kiểu này có tài liệu khá đầy đủ, vì Azure là 1 đơn vị cung cấp Cloud lớn.  
https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/troubleshoot-ssh-connection  
https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/connect-linux-vm-sshconnection  

# 2. Connection troubleshooting

## 2.1. Một số bước nên check trước

Check xem CPU và Disk đang như nào, có thể full disk và full CPU dẫn đến SSH đến VM bị timeout?

Thử ping đến VM đang lỗi từ 1 VM khác cùng subnet xem?

Check xem NSG có đang open port 22 ko?

Check xem VM có đang ở sau 1 Internal Load Balancer ko? Điều này ko ngăn cản việc SSH vào VM nhưng có thể nó đã chặn kết nối ra ngoài internet của VM

Check NIC xem có đang gắn vào NSG ko? 

## 2.2. Các cách đã đọc nhưng chưa thử

- Delete VM nhưng giữ lại OS disk, deploy lại VM với OS disk cũ được attach vào

- Run command trong VM bằng AZ cli:   

```sh
vmname=yourvm;rg=yourrg;timestamp=`date +%d%Y%H%M%S`;az vm extension set –resource-group $rg –vm-name $vmname –name customScript –publisher Microsoft.Azure.Extensions –settings "{'commandToExecute': 'bash -c \'chmod 755 /var/empty/sshd;chown root:root /var/empty/sshd;systemctl start sshd;ps -eaf | grep sshd\",'timestamp': "$((timestamp))"}"
```

## 2.3. Các cách đã thử và bị lỗi

- Reset ssh bằng az cli như này, hiện vẫn bị lỗi:   

```
$ az vm user reset-ssh --resource-group rg-20230222124816 --name vm-123

(VMAgentStatusCommunicationError) VM 'vm-123' has not reported status for VM agent or extensions. Verify that the OS is up and healthy, the VM has a running VM agent, and that it can establish outbound connections to Azure storage. Please refer to https://aka.ms/vmextensionlinuxtroubleshoot for additional VM agent troubleshooting information.
Code: VMAgentStatusCommunicationError
Message: VM 'vm-123' has not reported status for VM agent or extensions. Verify that the OS is up and healthy, the VM has a running VM agent, and that it can establish outbound connections to Azure storage. Please refer to https://aka.ms/vmextensionlinuxtroubleshoot for additional VM agent troubleshooting information.
```

- Dùng Serial Console trên Azure Portal: (https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/connect-linux-vm-sshconnection#serial-console)
Có thể sẽ bị lỗi:  

```
For more information on the Azure Serial Console, see <https://aka.ms/serialconsolelinux>.
Preparing console connection to vm-123   ■ □ □
 The serial console connection to the VM encountered an error: 'DenyAssignmentAuthorizationFailed'
 
 (403) - The client '' with object id '' has permission to perform action 'Microsoft.SerialConsole/serialPorts/connect/action' on scope '/subscriptions/subscriptionID/resourcegroups/rg/providers/Microsoft.Compute/virtualMachines/vm-123/providers/Microsoft.SerialConsole/serialPorts/0'; however, the access is denied because of the deny assignment with name 'System deny assignment created by managed application /subscriptions/subscriptionID/resourceGroups/rg/providers/Microsoft.Solutions/applications/AppsName' and Id '' at scope '/subscriptions/subscriptionID/resourceGroups/rg'.
```

-> Cách này thì cần dùng account có quyền cao hơn là OK.

## 2.4. Dùng Serial Console để SSH được vào VM (2023-03-14)

Dùng Serial Console trên Azure Portal

Sau khi dùng thì sẽ có giao diện để SSH vào VM ngay trên Browser

Mình đã check connection thì thấy Vm này gặp 3 lỗi:  

- 1 là ko ping đến các VM private cùng mạng được  
- 2 là các version python và python3 default của hệ thống bị sai, dẫn đến các service của hệ thống cũng bị die như:  
`cloud-config, cloud-init, cloud-final, cloud-init-local, networkd-dispatcher, walinuxagent, unattended-upgrades`
- 3 là ko ping ra ngoài internet được:   

```
# curl google.com
curl: (6) Could not resolve host: google.com
```

### 2.4.1 Tìm cách xử lý các vấn đề liên quan đến connection trước

Tìm cách xử lý các lỗi 1 và 3 trước

### 2.4.2. Fix lỗi 1: private connection đến các VM cùng mạng

Thử cách này: Reset NIC bằng giao diện portal, đổi qua lại private IP: (nguồn https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/reset-network-interface-azure-linux-vm)  
-> Vẫn lỗi ko ping đến các VM cùng mạng

Check nic status bằng ifconfig thì như này:  

```
$ ifconfig
lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 14646  bytes 1143824 (1.1 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 14646  bytes 1143824 (1.1 MB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

-> Hiện chỉ có interface `lo` là đang `UP`.  
Trong check `ifconfig -a` lại ra 3 cái `eth0, enP39453s1, lo`, nhưng ko có cái nào `UP`.  

Ở 1 VM bình thường sẽ phải như này:  

```
$ ifconfig
enP10290s1: flags=6211<UP,BROADCAST,RUNNING,SLAVE,MULTICAST>  mtu 1500
        ether 00:0d:3a:29:26:cf  txqueuelen 1000  (Ethernet)
        RX packets 1081434  bytes 324837416 (324.8 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 1450041  bytes 554743361 (554.7 MB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.10.16.10  netmask 255.255.255.0  broadcast 10.10.16.255
        inet6 fe80::20d:3aff:fe29:26cf  prefixlen 64  scopeid 0x20<link>
        ether 00:0d:3a:29:26:cf  txqueuelen 1000  (Ethernet)
        RX packets 981774  bytes 306181728 (306.1 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 1286521  bytes 543930689 (543.9 MB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 952  bytes 128818 (128.8 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 952  bytes 128818 (128.8 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

-> Vậy cần enable interface `eth0` và `enP39453s1`, Dùng command sau:  

```sh
ifconfig eth0 up
```

Check lại thì đã thấy cả 3 interface đã UP. Nhưng UP rồi tuy nhiên ko có private IP trong `eth0` như bình thường:  

```
enP39453s1: flags=6211<UP,BROADCAST,RUNNING,SLAVE,MULTICAST>  mtu 1500
        ether 60:45:bd:91:b0:e2  txqueuelen 1000  (Ethernet)
        RX packets 1  bytes 86 (86.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 11  bytes 866 (866.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet6 fe80::6245:bdff:fe91:b0e2  prefixlen 64  scopeid 0x20<link>
        ether 60:45:bd:91:b0:e2  txqueuelen 1000  (Ethernet)
        RX packets 1  bytes 72 (72.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 11  bytes 866 (866.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 480  bytes 35664 (35.6 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 480  bytes 35664 (35.6 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

-> Cần phải add Private IP vào interface lại: (nguồn: https://www.computerhope.com/unix/uifconfi.htm) 

```sh
ifconfig eth0 10.10.10.6 netmask 255.255.255.0 broadcast 10.10.48.255

# Nếu muốn xóa đi:
# ip address del 10.10.10.6 dev eth0
```

Sau khi add private IP vào nó sẽ như này:  

```
$ ifconfig
enP39453s1: flags=6211<UP,BROADCAST,RUNNING,SLAVE,MULTICAST>  mtu 1500
        ether 60:45:bd:91:b0:e2  txqueuelen 1000  (Ethernet)
        RX packets 2061  bytes 125890 (125.8 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 2027  bytes 123142 (123.1 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.10.10.6  netmask 255.255.255.0  broadcast 10.10.48.255
        inet6 fe80::6245:bdff:fe91:b0e2  prefixlen 64  scopeid 0x20<link>
        ether 60:45:bd:91:b0:e2  txqueuelen 1000  (Ethernet)
        RX packets 2217  bytes 108256 (108.2 KB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 19  bytes 2054 (2.0 KB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 14646  bytes 1143824 (1.1 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 14646  bytes 1143824 (1.1 MB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

Giờ bạn sẽ ping được đến private ip khác. 

```
$ ping 10.10.10.5
PING 10.10.10.5 56(84) bytes of data.
64 bytes from 10.10.10.5: icmp_seq=1 ttl=64 time=0.029 ms
64 bytes from 10.10.10.5: icmp_seq=2 ttl=64 time=0.067 ms
64 bytes from 10.10.10.5: icmp_seq=3 ttl=64 time=0.066 ms
```

-> OK! Fix được lỗi 1 🤗

### 2.4.3. Fix lỗi 3: public connection đến Internet
 
Tiếp tục fix lỗi 3. Hiện vẫn ko có internet (từ VM ko connect đến google.com được). 

```
# curl google.com
curl: (6) Could not resolve host: google.com
```

Run vài câu lệnh linh tinh:
```sh
service hostname restart
sudo dhclient enP1219s1
sudo dhclient eth0
```

sau đó tự nhiên 1 lúc sau vào được internet:  
check file: `/etc/resolv.conf` thấy tự sửa thành như này:  

```
domain xsdfsdgfegbtergfvwefweee.ax.internal.cloudapp.net
search xsdfsdgfegbtergfvwefweee.ax.internal.cloudapp.net
nameserver 168.63.129.16
```

vào ifconfig thấy như sau, ko có gì đặc biệt lắm, dù IP được add thêm vào `enP62109s1`, nhưng trước đó mình cũng add rồi, ko có mạng:  

```
$ ifconfig
enP62109s1: flags=6211<UP,BROADCAST,RUNNING,SLAVE,MULTICAST>  mtu 1500
        inet 10.10.10.6  netmask 255.255.255.0  broadcast 10.10.48.255
        ether 60:45:bd:87:c4:a6  txqueuelen 1000  (Ethernet)
        RX packets 1350521  bytes 1871982693 (1.8 GB)
        RX errors 0  dropped 1010  overruns 0  frame 0
        TX packets 66743  bytes 26351775 (26.3 MB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

eth0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 10.10.10.6  netmask 255.255.255.0  broadcast 10.10.48.255
        inet6 fe80::6245:bdff:fe87:c4a6  prefixlen 64  scopeid 0x20<link>
        ether 60:45:bd:87:c4:a6  txqueuelen 1000  (Ethernet)
        RX packets 98512  bytes 1851838727 (1.8 GB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 56806  bytes 25686229 (25.6 MB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 14992  bytes 1216028 (1.2 MB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 14992  bytes 1216028 (1.2 MB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

Restart lại VM thì vẫn bị lỗi khi curl connect ra internet, nhưng sau khi run mấy câu lệnh này thì restart lại ko thấy lỗi nữa: (nguồn: http://www.freekb.net/Article?id=1196#:~:text=The%20dhclient%20command%20is%20used,will%20use%20the%20service%20command)  

```
$ curl google.com
curl: (6) Could not resolve host: google.com

$ sudo dhclient enP1219s1
sudo: unable to resolve host vm-123
RTNETLINK answers: File exists

$ sudo dhclient eth0
sudo: unable to resolve host vm-123: Resource temporarily unavailable
RTNETLINK answers: File exists

$ service hostname restart
Failed to restart hostname.service: Unit hostname.service is masked.

$ curl google.com
<HTML><HEAD><meta http-equiv="content-type" content="text/html;charset=utf-8">
<TITLE>301 Moved</TITLE></HEAD><BODY>
<H1>301 Moved</H1>
The document has moved
<A HREF="http://www.google.com/">here</A>.
</BODY></HTML>
```

OK! Đã fix được lỗi 3. 🥰

-> Như vậy có vẻ như các command này dù bị lỗi nhưng vẫn có tác dụng:  

```sh
sudo dhclient eth0
service hostname restart
```

### 2.4.4. Xử lý các service hệ thống bị lỗi

Tìm cách fix lỗi 2. 

Sau khi sửa python version mặc định, các service sau cần check lại status:  

```sh
service walinuxagent status
service unattended-upgrades status
service networkd-dispatcher status
service cloud-init-local status
service cloud-final status
service cloud-init status
service cloud-config status
service sshd status
```

Nếu sửa file .servie thì phải reload bằng command này:  

```sh
systemctl daemon-reload
```

Debug:  

```sh
tail -n 200 /var/log/waagent.log
```

Nếu service walinuxagent bị lỗi ko biết vì sao như này (check log lỗi ko có log):  

```
# service walinuxagent status
● walinuxagent.service - Azure Linux Agent
   Loaded: loaded (/lib/systemd/system/walinuxagent.service; enabled; vendor preset: enabled)
  Drop-In: /lib/systemd/system/walinuxagent.service.d
           └─10-Slice.conf, 11-CPUAccounting.conf, 12-CPUQuota.conf, 13-MemoryAccounting.conf
   Active: failed (Result: exit-code) since Tue 2023-03-14 02:29:09 UTC; 805ms ago
  Process: 9679 ExecStart=/usr/bin/python3 -u /usr/sbin/waagent -daemon (code=exited, status=1/FAILURE)
 Main PID: 9679 (code=exited, status=1/FAILURE)
      CPU: 26ms

Mar 14 02:29:09 vm-123 systemd[1]: walinuxagent.service: Consumed 26ms CPU time
Mar 14 02:29:09 vm-123 systemd[1]: walinuxagent.service: Service hold-off time
Mar 14 02:29:09 vm-123 systemd[1]: walinuxagent.service: Scheduled restart job,
Mar 14 02:29:09 vm-123 systemd[1]: Stopped Azure Linux Agent.
Mar 14 02:29:09 vm-123 systemd[1]: walinuxagent.service: Consumed 26ms CPU time
Mar 14 02:29:09 vm-123 systemd[1]: walinuxagent.service: Start request repeated
Mar 14 02:29:09 vm-123 systemd[1]: walinuxagent.service: Failed with result 'ex
Mar 14 02:29:09 vm-123 systemd[1]: Failed to start Azure Linux Agent.
```

Có vẻ service đã bị broken, fix bằng command sau:  

```sh
sudo apt-get --fix-broken install walinuxagent --fix-missing
```

Nếu các service hệ thống bị lỗi `masked` như này:

```
$ service unattended-upgrades status
● unattended-upgrades.service
   Loaded: masked (/dev/null; bad)
   Active: inactive (dead)

$ service unattended-upgrades restart
Failed to restart unattended-upgrades.service: Unit unattended-upgrades.service is masked.

$ systemctl enable networkd-dispatcher
Failed to enable unit: Unit file networkd-dispatcher.service does not exist.

$ service networkd-dispatcher start
Failed to start networkd-dispatcher.service: Unit networkd-dispatcher.service not found.
```

Fix = command sau:  

```
$ systemctl unmask unattended-upgrades
Removed /etc/systemd/system/unattended-upgrades.service.

$ systemctl enable unattended-upgrades
unattended-upgrades.service is not a native service, redirecting to systemd-sysv-install.
Executing: /lib/systemd/systemd-sysv-install enable unattended-upgrades

$ systemctl start unattended-upgrades

$ sudo apt-get --fix-broken install networkd-dispatcher --fix-missing
```

Vậy là xong, đã fix được tất cả các lỗi, restart lại VM cũng ko có lỗi nữa, SSH được bình thường, connect Internet bình thường.

Cần chú ý Azure Ubuntu 18.04 vẫn dùng Python3.6 là default cho python3. Python2.7 là default cho python. Đừng cố gắng chuyển default Python vì có rất nhiều service hệ thống phụ thuộc vào các python default. Việc thay đổi default sẽ gây lỗi ko đáng có.


## 2.5. Update 2024-07-03, Nếu không thể SSH được vào VM bằng Serial Console

Hôm nay gặp lỗi "Agent status not ready. Agent Status and version is unknown". Minh đã thử các cách như sau:

 - telnet, ping, curl từ mạng public, mạng internal subnet ko phản hồi.  
 - đã thử restart/stop/start nhiều lần ko ăn thua, ko thể SSH vào.  
 - đã thử Serial Console + reset password nhưng ko login vào được.  
 - đã thử `az vm user reset-ssh --resource-group rg-name-123 --name vm-name-123` ko ăn thua.  
 - Check NSG, NIC, public IP, các VM khác hoạt động bình thường, chỉ có vm VM bị lỗi.  
 - Azure portal -> Troubleshoot -> `Reapply, Redeploy` đều ko thành công, ko SSH vào được.  
 - check Monitoring -> CPU ko thấy quá.  
 - update disk size từ 32GB -> 64GB rồi reset -> ko thành công.  
 - update VM size từ 2CPU/8G lên 8 CPU/32G RAM rồi reset -> ko thành công.  
 - Đã thử snapshot disk, tạo managed disk (https://docs.microsoft.com/en-us/azure/virtual-machines/scripts/virtual-machines-linux-cli-sample-create-vm-from-managed-os-disks?toc=/azure/virtual-machines/linux/toc.json), attach Disk đó vào làm OS disk của 1 VM khác -> vẫn ko connect SSH vào được.
 - Chịu hết cách🥵, giờ chỉ mong lấy dc data để move sang 1 VM hoàn toàn mới. Cuối cùng mình phải dùng Azure Cloudshell, run command `az vm repair` để attach Disk vào làm DataDisk của 1 VM mới.

```
hoang [ ~ ]$ az vm repair create --verbose -g rg-name-123 -n vm-name-123 --repair-username rescue --repair-password 'pAssWord!' --copy-disk-name vmrepair-prefix-osdisk

Does repair vm requires public ip? (y/n): y
Fetching architecture type of the source VM...
Checking if source VM is gen2
Generation 2 VM detected
No specific distro was provided , using the default Ubuntu distro
No specific distro was provided , using the default Ubuntu distro
Checking if source VM size is available...
Source VM size 'Standard_D8_v4' is available. Using it to create repair VM.

Checking for existing resource groups with identical name within subscription...
Pre-existing repair resource group with the same name is 'False'
Creating resource group for repair VM and its resources...
Source VM uses managed disks. Creating repair VM with managed disks.

Copying OS disk of source VM...
Creating repair VM with command: az vm create -g repair-vm-name-123-20240703025247 -n repair-vm-mi_ --tag repair_source=rg-name-123/vm-name-123 --image Ubuntu2204 --admin-username rescue --admin-password pAssWord! --public-ip-address repair-vm-mi_PublicIP --custom-data /home/hoang/.azure/cliextensions/vm-repair/azext_vm_repair/scripts/linux-build_setup-cloud-init.txt --size Standard_D8_v4
copy_disk_id: /subscriptions/SUBSCRIPTION_ID/resourceGroups/rg-name-123/providers/Microsoft.Compute/disks/vmrepair-prefix-osdisk
repair_password: pAssWord!
repair_username: rescue
fix_uuid: True
Validating VM template before continuing...
Creating repair VM...
Attaching copied disk to repair VM as data disk...

Your repair VM 'repair-vm-mi_' has been created in the resource group 'repair-vm-name-123-20240703025247' with disk 'vmrepair-prefix-osdisk' attached as data disk. Please use this VM to troubleshoot and repair. Once the repairs are complete use the command 'az vm repair restore -n vm-name-123 -g rg-name-123 --verbose' to restore disk to the source VM. Note that the copied disk is created within the original resource group 'rg-name-123'.

{
  "copied_disk_name": "vmrepair-prefix-osdisk",
  "copied_disk_uri": "/subscriptions/SUBSCRIPTION_ID/resourceGroups/rg-name-123/providers/Microsoft.Compute/disks/vmrepair-prefix-osdisk",
  "created_resources": [
    "/subscriptions/SUBSCRIPTION_ID/resourceGroups/repair-vm-name-123-20240703025247/providers/Microsoft.Network/virtualNetworks/repair-vm-mi_VNET",
    "/subscriptions/SUBSCRIPTION_ID/resourceGroups/repair-vm-name-123-20240703025247/providers/Microsoft.Network/networkSecurityGroups/repair-vm-mi_NSG",
    "/subscriptions/SUBSCRIPTION_ID/resourceGroups/repair-vm-name-123-20240703025247/providers/Microsoft.Network/publicIPAddresses/repair-vm-mi_PublicIP",
    "/subscriptions/SUBSCRIPTION_ID/resourceGroups/repair-vm-name-123-20240703025247/providers/Microsoft.Network/networkInterfaces/repair-vm-mi_VMNic",
    "/subscriptions/SUBSCRIPTION_ID/resourceGroups/repair-vm-name-123-20240703025247/providers/Microsoft.Compute/virtualMachines/repair-vm-mi_",
    "/subscriptions/SUBSCRIPTION_ID/resourceGroups/REPAIR-vm-name-123-20240703025247/providers/Microsoft.Compute/disks/repair-vm-mi__OsDisk_1_da78ab30231b4a6b99939a6be032f91f",
    "/subscriptions/SUBSCRIPTION_ID/resourceGroups/rg-name-123/providers/Microsoft.Compute/disks/vmrepair-prefix-osdisk"
  ],
  "message": "Your repair VM 'repair-vm-mi_' has been created in the resource group 'repair-vm-name-123-20240703025247' with disk 'vmrepair-prefix-osdisk' attached as data disk. Please use this VM to troubleshoot and repair. Once the repairs are complete use the command 'az vm repair restore -n vm-name-123 -g rg-name-123 --verbose' to restore disk to the source VM. Note that the copied disk is created within the original resource group 'rg-name-123'.",
  "repair_resource_group": "repair-vm-name-123-20240703025247",
  "repair_vm_name": "repair-vm-mi_",
  "resource_tag": "repair_source=rg-name-123/vm-name-123",
  "status": "SUCCESS"
}
Command ran in 205.133 seconds (init: 0.108, invoke: 205.026)
```

Giải thích:  
command trên tạo ra 1 RG mới, trong RG đó nó tạo 1 VM "repair-vm-mi_", VM đó có 1 OS disk và 1 DataDisk "vmrepair-prefix-osdisk". Cái Data Disk chính là bản 1 bản copy của cái disk mà mình muốn access.

Giờ mình định mount DataDisk để troubleshoot nhưng gặp lỗi khi mount:

```s
root@repair-algo-mi:~# lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
loop0     7:0    0 63.9M  1 loop /snap/core20/2318
loop1     7:1    0   87M  1 loop /snap/lxd/28373
loop2     7:2    0 38.8M  1 loop /snap/snapd/21759
sda       8:0    0   30G  0 disk
├─sda1    8:1    0 29.9G  0 part /
├─sda14   8:14   0    4M  0 part
└─sda15   8:15   0  106M  0 part /boot/efi
sdb       8:16   0   64G  0 disk
├─sdb1    8:17   0 31.9G  0 part
├─sdb14   8:30   0    4M  0 part
└─sdb15   8:31   0  106M  0 part
sr0      11:0    1  634K  0 rom

root@repair-algo-mi:/# sudo mkdir /datadrive2
root@repair-algo-mi:/# sudo mount /dev/sdb /datadrive2
mount: /datadrive2: wrong fs type, bad option, bad superblock on /dev/sdb, missing codepage or helper program, or other error.
```
        
Troubleshoot lỗi mount:  
```s
root@repair-algo-mi:/# fdisk -l
Disk /dev/loop0: 63.95 MiB, 67051520 bytes, 130960 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/loop1: 87.03 MiB, 91258880 bytes, 178240 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/loop2: 38.83 MiB, 40714240 bytes, 79520 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/sda: 30 GiB, 32213303296 bytes, 62916608 sectors
Disk model: Virtual Disk
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: 2ECEF1EE-95DE-4B9F-891E-4388EC10E0FB

Device      Start      End  Sectors  Size Type
/dev/sda1  227328 62916574 62689247 29.9G Linux filesystem
/dev/sda14   2048    10239     8192    4M BIOS boot
/dev/sda15  10240   227327   217088  106M EFI System

Partition table entries are not in disk order.
GPT PMBR size mismatch (67108863 != 134217727) will be corrected by write.
The backup GPT table is not on the end of the device.


Disk /dev/sdb: 64 GiB, 68719476736 bytes, 134217728 sectors
Disk model: Virtual Disk
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: 3E4FB487-3A45-4912-B6A0-DBE5F0E83A52

Device      Start      End  Sectors  Size Type
/dev/sdb1  227328 67108830 66881503 31.9G Linux filesystem
/dev/sdb14   2048    10239     8192    4M BIOS boot
/dev/sdb15  10240   227327   217088  106M EFI System

Partition table entries are not in disk order.
```

Sau đó run "parted -l" ko thấy lỗi "GPT PMBR size mismatch" nữa:

```s
root@repair-algo-mi:~# parted -l

Model: Msft Virtual Disk (scsi)
Disk /dev/sda: 32.2GB
Sector size (logical/physical): 512B/4096B
Partition Table: gpt
Disk Flags:

Number  Start   End     Size    File system  Name  Flags
14      1049kB  5243kB  4194kB                     bios_grub
15      5243kB  116MB   111MB   fat32              boot, esp
        1      116MB   32.2GB  32.1GB  ext4


Warning: Not all of the space available to /dev/sdb appears to be used, you can
fix the GPT to use all of the space (an extra 67108864 blocks) or continue with
the current setting?
Fix/Ignore? Fix
Model: Msft Virtual Disk (scsi)
Disk /dev/sdb: 68.7GB
Sector size (logical/physical): 512B/4096B
Partition Table: gpt
Disk Flags:

Number  Start   End     Size    File system  Name  Flags
14      1049kB  5243kB  4194kB                     bios_grub
15      5243kB  116MB   111MB   fat32              boot, esp
        1      116MB   34.4GB  34.2GB  ext4
        
root@repair-algo-mi:~# fdisk -l

Disk /dev/loop0: 63.95 MiB, 67051520 bytes, 130960 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/loop1: 87.03 MiB, 91258880 bytes, 178240 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/loop2: 38.83 MiB, 40714240 bytes, 79520 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes


Disk /dev/sda: 30 GiB, 32213303296 bytes, 62916608 sectors
Disk model: Virtual Disk
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: 2ECEF1EE-95DE-4B9F-891E-4388EC10E0FB

Device      Start      End  Sectors  Size Type
/dev/sda1  227328 62916574 62689247 29.9G Linux filesystem
/dev/sda14   2048    10239     8192    4M BIOS boot
/dev/sda15  10240   227327   217088  106M EFI System

Partition table entries are not in disk order.


Disk /dev/sdb: 64 GiB, 68719476736 bytes, 134217728 sectors
Disk model: Virtual Disk
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 4096 bytes
I/O size (minimum/optimal): 4096 bytes / 4096 bytes
Disklabel type: gpt
Disk identifier: 3E4FB487-3A45-4912-B6A0-DBE5F0E83A52

Device      Start      End  Sectors  Size Type
/dev/sdb1  227328 67108830 66881503 31.9G Linux filesystem
/dev/sdb14   2048    10239     8192    4M BIOS boot
/dev/sdb15  10240   227327   217088  106M EFI System

Partition table entries are not in disk order.
```
        
Nhưng khi mount vẫn bị lỗi:

```s
root@repair-algo-mi:~# sudo mount /dev/sdb /datadrive2
mount: /datadrive2: wrong fs type, bad option, bad superblock on /dev/sdb, missing codepage or helper program, or other error.
        
root@repair-algo-mi:/# fsck /dev/sdb
fsck from util-linux 2.37.2
e2fsck 1.46.5 (30-Dec-2021)
ext2fs_open2: Bad magic number in super-block
fsck.ext2: Superblock invalid, trying backup blocks...
fsck.ext2: Bad magic number in super-block while trying to open /dev/sdb

The superblock could not be read or does not describe a valid ext2/ext3/ext4
filesystem.  If the device is valid and it really contains an ext2/ext3/ext4
filesystem (and not swap or ufs or something else), then the superblock
is corrupt, and you might try running e2fsck with an alternate superblock:
        e2fsck -b 8193 <device>
        or
        e2fsck -b 32768 <device>

Found a gpt partition table in /dev/sdb
        
root@repair-algo-mi:/# e2fsck -b 8193 /dev/sdb
e2fsck 1.46.5 (30-Dec-2021)
e2fsck: Bad magic number in super-block while trying to open /dev/sdb

The superblock could not be read or does not describe a valid ext2/ext3/ext4
filesystem.  If the device is valid and it really contains an ext2/ext3/ext4
filesystem (and not swap or ufs or something else), then the superblock
is corrupt, and you might try running e2fsck with an alternate superblock:
        e2fsck -b 8193 <device>
        or
        e2fsck -b 32768 <device>

Found a gpt partition table in /dev/sdb
```
        
Nguyên nhân lỗi mount:

Cần phải mount /dev/sdb1 chứ ko phải /dev/sdb 😖😖

```sh
root@repair-algo-mi:~# mount /dev/sdb1 /datadrive2
```

Tada~✨ Access vào được data trên disk để backup data rồi 🤣. Tuy nhiên chưa thể làm con VM đã hỏng hoạt động trở lại...

Review data trong folder /datadrive2 Thấy Dev họ cài Python2.7, có thể do cài python2.7 làm mặc định nên Azure Agent bị lỗi.

1 bước quan trọng mà mình quên là cần check `syslog` để xem vì sao Azure Agent lại ko hoạt động. 

Các bước tiếp theo mình nghĩ có thể sẽ là: 
- copy data cần thiết sang OS Disk của VM repair. 
- Rồi snapshot OS Disk thành Managed Disk.
- Rồi Create VM mới từ Managed Disk đó.
- Xóa con VM bị lỗi ko thể SSH vào đi.  

# CREDIT

https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/troubleshoot-ssh-connection  
https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/connect-linux-vm-sshconnection  

