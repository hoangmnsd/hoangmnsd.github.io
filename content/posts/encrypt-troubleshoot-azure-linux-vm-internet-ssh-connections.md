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

## 2.4. SSH được vào VM, xác định vấn đề

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

## 2.5. Tìm cách xử lý các vấn đề liên quan đến connection trước

Tìm cách xử lý các lỗi 1 và 3 trước

### 2.5.1. Fix lỗi 1: private connection đến các VM cùng mạng

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

### 2.5.2. Fix lỗi 3: public connection đến Internet
 
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

## 2.6. Xử lý các service hệ thống bị lỗi

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


# CREDIT

https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/troubleshoot-ssh-connection  
https://learn.microsoft.com/en-us/troubleshoot/azure/virtual-machines/connect-linux-vm-sshconnection  

