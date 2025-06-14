---
title: "Setting up my environments Windows, Ubuntu"
date: 2023-03-03T21:56:40+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Windows,Ubuntu,Python]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Các step khi cài lại Win10, các link cần nhớ, các phần mềm cần cài..."
---

# Windows

## 1. Create USB Boots Win10

### 1.1. Download windows 10

từ https://www.microsoft.com/software-download/windows10.  

Bật F12 vì MS chỉ cho phép tải từ trình duyệt mobile.

### 1.2. Download Rufus từ https://rufus.ie/

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/usb-boot-rufus-config.jpg)

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/usb-boot-rufus-config-start.jpg)

Xong thì có thể eject USB và rút ra

## 2. Install Win10 from USB Boots

### 2.1. Cắm USB đã cài Win10 vào

### 2.2. Start/restart máy

ấn liên tục F10 để vào Boots Menu screen của NUC11i5, ấn liên tục vào F12 nếu là máy Lenovo Thinkbook 14p, ấn ESC nếu là Asus K501LB.

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/boot-win10-menu1.jpg)

### 2.3. Chọn cái USB bên trên

Vào màn hình cài Win, chọn Win 10 Pro - Accept terms.   

Có thể chọn Format Partition, Delete Partition, Extend để gộp các phân vùng lại thành 1 ổ.  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/boot-win10-setup-drive1.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/boot-win10-setup-drive2.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/boot-win10-setup-drive3.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/boot-win10-setup-drive4.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/boot-win10-setup-drive5.jpg)  

Chờ cài xong

Chú ý: nên chọn layout US Keyboard (ko nên chọn layout UK vì 1 số phím sẽ khác).  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/boot-win10-setup-6.jpg)

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/boot-win10-limit-setup.jpg)

### 2.4. Sau khi vào thì update Windows drivers 

Bằng cách vào Settings -> Update & Security -> Windows Update -> Check for Updates -> install

### 2.5. Update Intel drivers

Mở Edge browser, search intel driver -> Get Start -> Download - Install - Accept, vào lại browser sẽ thấy nhiều update availables -> Download all

Chờ tất cả các Drivers download hết rồi thì restart 1 thể.  

Có thể sẽ phải restart vài lần.  

### 2.6. Activate Win 10 Pro

Mua 1 key riêng của Thơ nụ Voz (250k) là key bản quyển digital

Activate key thôi.

Nhưng có thể sẽ gặp lỗi này: (ảnh)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/win10activate-trouble.jpg)

Nguyên nhân là do mình đã nhờ cửa hàng activate win 10 Home bản quyền digital trước.

Giờ cài lại win 10 Pro thì máy ko nhận key mới nữa, vì nó đã ăn cái key của cửa hàng rồi.

Không làm sao tháo key ra được thì tìm được cách này: https://github.com/massgravel/Microsoft-Activation-Scripts/releases  
Chi tiết có thể vào đây xem: https://massgrave.dev.  
Có vẻ uy tín vì trên voz recommend: https://voz.vn/t/active-windows-ban-quyen-so-bang-cach-nay-co-an-toan-va-hieu-qua-khong-cac-cau.406785/post-13096345

Trên PowerShell as Admin, run command: `irm https://massgrave.dev/get | iex`.  
Chọn [1] để activate win 10 Pro.

Activate thành công thì out ra, nhập lại key đã mua của Thơ nụ vào. Done.  

## 3. Cài các phần mềm cần thiết cho công việc

### 3.1. Disable Bitlocker Encryption

Check trong Disk Management, thấy ổ C bị Bitlocker Encrpyted, muốn xóa disable Bitlocker đi

https://vn-z.vn/threads/o-cung-bi-khoa-bitlocker-xin-cac-cao-nhan-chi-giup.45182/page-4

bật CMD as Administrator, run command:  

```sh
reg add "HKLM\SYSTEM\CurrentControlSet\Control\BitLocker" /v PreventDeviceEncryption /t REG_DWORD /d 1 /f
```

https://www.manageengine.com/products/os-deployer/help/how-to-disable-bitlocker-encryption.html

Open Windows Powershell in Administrator mode:  

```sh
Disable-BitLocker -MountPoint "C:"
```

Vào check lại trong Disk Management là thấy cái dòng chữ "Bitlocker Encrypted" bên cạnh ổ C đã bị xóa 

### 3.2. Install MS Office

Tạo account MS Developer E5 link với github theo guideline trên mạng

Login vào portal.office.com

Download and Install Office application

Sau đó vào Excel, Signin vào Excel bằng account bên trên

### 3.3. Copy bộ cài đã download 

...từ trong ổ cứng di dộng ra, cần phần mềm nào thì cài.

Riêng IDM thì cứ cài latest, xong rồi dùng script này để activate:  
https://github.com/lstprjct/IDM-Activation-Script

Run on Powershell:  

```sh
iwr -useb https://raw.githubusercontent.com/lstprjct/IDM-Activation-Script/main/IAS.ps1 | iex
```

Riêng Your Uninstaller Pro 7.5(2014), lên đây download về: https://ursoftware.com/download, cài xong thì điền key sau:  

```
Name: sharyn kolibob
Registration code: 000016-9P0U6X-N5BBFB-EH9ZTE-DEZ8P0-9U4R72-RGZ6PF-EMYUAZ-9J6XQQ-89BV1Z
```

List các phần mềm đã cài:  

```
Firefox
Chrome
PotPLayer
OpenVPN
Wireguard
Putty
Ubuntu1804LTS
TeamViewer
Notepad++
Discord
PowerBIDesktop
GitBash
TorBrowser
Utorrent => Không nên cài vì có virus
FileZilla
Zoom
PasswordSafe
Slack
Telegram
VLC
WinSCP
DockerDesktop
Skype
Postman
Drawio
Dropbox
sakura
SublimeText
ACEStream
Anki
VSCode
DaemonToolLite (Có file)
IDM (Có script activate reset trial)
YourUninstaller7.5-2014 (trên mạng có account key)
AdobeIllustrator2020 (có file iso và hướng dẫn)
AdobePhotoshop2021 (Có file)
BeyonCompare (Có key)
FastonCapture (Có account trên mạng share)
KasperskyTotalSecurity (trên vn-z có share key)
Tableau (cho Linh)
SQLServer2022 Developer (cho Linh)
Azure Data Studio (cho Linh)
MS SQL Server Tools 19 (cho Linh)
```

Cài extension cho Chrome:  

```
Adblock
I still dont care about cookie
The Great suspender -> ko nên cài vì có nhiều review ko tốt (nên thay bằng The Marvellous Suspender)
```

### 3.4. Activate Kaspersky Total Security

Lên topic này xin key: https://vn-z.vn/threads/kaspersky-total-security-500-days.15942/page-380

Có thể sẽ phải dùng OpenVPN sang Đức hoặc Brazil Italia Egypt để active key, trung binh key khoảng vài tháng 1 năm

ví dụ máy NUC11 mình xin đc key KTS này: A989W-BBYCM-B1NH5-82T2T - Đức (hạn March 5, 2024)

Máy Lenovo của Linh thì mình xin được key KTS này: 6ZKWR-59UQD-7PSG9-1E8UQ - Ấn Độ (hạn đến September 27, 2025) [linh](https://vn-z.vn/threads/kaspersky-total-security-500-days.15942/post-977707)


### 3.5. Cài PowerToy để split windows screen

https://github.com/microsoft/PowerToys/releases/

### 3.6. Troubeshooting

Khi cài MS SQL Server:  
- test connection từ MS SQL Server Studio 2019 xem có tạo được Database ko (`CREATE DATABASE test` -> Execute).
- test connection từ Azure Data Studio đến SQL Server 2022 xem được ko.

Có thể bị lỗi như này:  

```
Azure data studio cannot connect to the database due to invalid owneruri (parameter 'owneruri')

hoặc: 

A connection was successfully established with the server, but then an error occurred during the pre-login handshake. (provider: Shared Memory Provider, error: 0 - No process is on the other end of the pipe.)
```

SQL Server Network Configuration -> Protocol for XXX -> Disable cái Shared Memory như này:  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/sqlserver-configuration.jpg)

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/services.msc-sqlserver-browser.jpg)

restart


## 4. Backup 

### 4.1. Backup bằng chức năng của Win10 trên chính ổ SSD đó (phân vùng khác)

Vào Setting -> Update & security -> Backup

Go to Backup and restore (Windows 7)

Setup a backup

Chọn ổ sẽ lưu file backup

Quá trình run backup bị failed, thôi bỏ ko dùng cách này nữa

### 4.2. Ghost Win10 with Acronis True Image

Sau khi cài tất cả các phần mềm cần thiết, sử dụng OK 1 thời gian thì nên Ghost lại 1 image để backup.  

Sau này nếu dính virus, máy chậm quá, thì "bung" ra, ko cần phải cài phần mềm nọ kia gì nữa. Cứ thế dùng luôn.  

#### 4.2.1. Tạo usb boot anhdv

https://anh-dv.com/usb-boot/tao-usb-boot-uefi-legacy-cuu-ho-may-tinh-chuyen

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/anhdvboot-one-click-1.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/anhdvboot-one-click-2.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/anhdvboot-one-click-3.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/anhdvboot-one-click-4.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/anhdvboot-one-click-5.jpg)  
chờ vài phút...
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/anhdvboot-one-click-6.jpg)  
 
#### 4.2.2. Tạo file ghost .tib bằng Acronis True Image có trong usb trên

https://anh-dv.com/windows/tao-ghost-windows-10-uefi-voi-acronis-true-image/comment-page-2#comments

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/backup-ati2014-anhdvboot2023-select.jpg)
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/anhdvboot-screen2023.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/anhdv-ati2014-backup.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/anhdv-ati2014-backup-select-c.jpg)
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/anhdv-ati2014-backup-select-location.jpg)
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/anhdv-ati2014-backup-compress-opt.jpg)
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/anhdv-ati2014-backup-almost.jpg)
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/anhdv-ati2014-backup-wait.jpg)
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/anhdv-ati2014-backup-success.jpg)


#### 4.2.3. Restore từ file ghost .tib bằng usb trên

https://anh-dv.com/ghost/ghost-windows-10-uefi-voi-acronis-true-image/comment-page-1#comments

### 4.3. Create restore point bằng Windows 10

https://www.windowscentral.com/how-use-system-restore-windows-10

## 5. Disable Windows Update hoặc tweak 1 vài thứ để nhẹ máy hơn

1. Disable Windows Update (source: https://vt.tiktok.com/ZSNEQ8Aoy/)

```sh
irm christitus.com/win  | iex
```

=> chọn tab Update => Security recommended setting 

Muốn khôi phục lại thì chọn Default setting

2. Tweak 1 số settings để nhẹ máy (source: https://vt.tiktok.com/ZSNE9tyct/)

```sh
irm christitus.com/win  | iex
```

=> Tweak => Laptop/Destop => Tweak

```
=================================
--     Tweaks are Finished    ---
=================================
Bye bye!
Transcript stopped, output file is C:\Users\Admin\AppData\Local\Temp\Winutil.log
```

Muốn khôi phục lại thì chọn Default setting

## 6. Install Proxmox

Download file iso Proxmox ve về máy.

Cắm 1 USB 16GB vào máy.

Bật Rufus, select file ISO vừa download về. Ấn Start.  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/proxmox-setup-1-rufus.jpg)

Vì cái USB này trước đó được dùng để cài win10 boots nên nó hiện thông báo này, ko sao, ấn OK để destroy hết data trên cái USB đó và cài Proxmox lên.
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/proxmox-setup-rufus-2.jpg)

chờ đến hình này là OK, rút USB ra.  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/proxmox-setup-rufus-3.jpg)

Cắm USB vừa xong vào lại máy tính, restart máy, ấn liên tục F10 để vào Boots Menu screen của NUC11i5, ấn liên tục vào F12 nếu là máy Lenovo Thinkbook 14p, ấn ESC nếu là Asus K501LB.

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/proxmox-setup-3.jpg)

Proxmox cung cấp 2 tùy chọn install bản graphic UI hoặc terminal UI khá hay, mình thực sự muốn thử bản terminal vì chắc chăn sẽ nhẹ hơn. Nhưng chọn thử bản Graphic trước:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/proxmox-setup-3-graphic-or-terminal.jpg)

Chỗ này **RẤT QUAN TRỌNG**, chọn hard disk nào thì cái đó sẽ bị delete TOÀN BỘ data:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/proxmox-setup-hard-disk-select.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/proxmox-setup-hard-disk-select-carefully.jpg)

Vì lý do này nên mình tạm dừng việc cài Proxmox ở đây. Quá rủi ro.

Có thể trong tương lai mình sẽ tạo 1 Virtual Hard disk để cài Proxmox lên. Hướng dẫn tạo virtual hard disk ở đây mình chưa thử: https://www.youtube.com/watch?v=kSDHgv_ScLI&ab_channel=Tricknology

Nhưng tạm thời thì cứ dùng Oracle VirtualBox thay cho Proxmox xem thế nào đã.

## 7. Setup Oracle VirtualBox

Download và cài Oracle VirtualBox khá đơn giản ko phức tạp như Proxmox. Nên mình ko nói.

Giờ nói việc tạo 1 VM ubuntu trên VirtualBox

Download file iso của ubuntu 20 ở đây:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-iso-download.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-iso-download-file-server.jpg)

CPU RAM DISK trước khi tạo Virtual Box ubuntu server:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-before-cpu.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-before-ram.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-before-disk.jpg)

Tạo VM trên VirtualBox:

Oracle Virtual Box -> chọn New:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-create-1.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-create-2-ram-cpu.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-create-2-disk.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-create-overview.jpg)

vào đây để select file iso Ubuntu đã download về:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-select-iso-file-1.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-selected-iso.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-start.jpg)

Ấn Show để vào terminal:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-show.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-setup-1.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-setup-2.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-setup-3.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-setup-4.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-setup-5.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-setup-6.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-setup-7.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-setup-8.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-setup-9.jpg)

ghi là Install complelte! Nhưng bên dưới lại có Option `Cancel update and reboot`??

Mình chọn và nó stuck ở màn hình này rất lâu:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-setup-11.jpg)

Chọn View Full Log để xem mọi thứ gặp lỗi gì, thì thấy lỗi kiểu:

```
E: Can not write log (Is /dev/pts mounted?) - posix_openpt (19: No such device)
```

Rồi cứ thể chờ đến khi được màn hình này là OK:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-setup-12.jpg)

Sau khi Running VM, thông số CPU/RAM của host cũng ko thay đổi nhiều:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-after-cpu-ram.jpg)

Disk Free thay đổi từ 521 xuống 515 GB, Nghĩa là VM chiếm dụng khoảng 6GB, thực chất mình đã allocate cho nó 10 GB, nó mới dùng hết 6GB:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-after-disk.jpg)


Thử ping google.com nếu OK nghĩa là có Internet.

Check `df -h`:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-check-df-h.jpg)

Check `htop` xem có đúng 1cpu 1G ram ko:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-check-htop.jpg)

check private IP bằng `ifconfig`:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-ifconfig.jpg)

Nhưng hiện tại, từ máy windows WSL ubuntu ko ping đến được ip `10.0.2.15` kia:

```s
hoanglh@DESKTOP-GKJJ17P:~$ ping 10.0.2.15
PING 10.0.2.15 (10.0.2.15) 56(84) bytes of data.
^C
--- 10.0.2.15 ping statistics ---
2 packets transmitted, 0 received, 100% packet loss, time 1020ms
```

Để giải quyết, Vào Oracle VirtualBox setting của VM đó, chọn như này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-network-adapter.jpg)

Nếu muốn tìm hiểu Các loại config network adapter khác nhau trong VirtualBox: https://www.golinuxhub.com/2017/08/how-to-configure-different-types-of/

Check lại `ifconfig`, sẽ thấy IP private đã thay đổi:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/oracle-virtualbox-ubuntu-ifconfig-changed.jpg)

Từ WSL đã có thể ping đến được Virtualbox VM, nghĩa là nếu có 1 app nào cài trong VM, thì ngoài host có thể access qua web browser được:

```s
hoanglh@DESKTOP-GKJJ17P:~$ ping 192.168.31.216
PING 192.168.31.216 (192.168.31.216) 56(84) bytes of data.
64 bytes from 192.168.31.216: icmp_seq=1 ttl=63 time=1.10 ms
64 bytes from 192.168.31.216: icmp_seq=2 ttl=63 time=1.47 ms
^C
--- 192.168.31.216 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 1.098/1.282/1.467/0.184 ms
```

Từ WSL có thể ping đến VirtualBox VM nhưng ko ssh đến được thì rất có khả năng VM chưa được cài openSSH server. Hãy cài:

```sh
sudo apt install openssh-server
```

Đã có thể ping/ssh đến VM được rồi:

```s
hoanglh@DESKTOP-GKJJ17P:~$ ping 192.168.31.216
PING 192.168.31.216 (192.168.31.216) 56(84) bytes of data.
64 bytes from 192.168.31.216: icmp_seq=1 ttl=63 time=1.10 ms
64 bytes from 192.168.31.216: icmp_seq=2 ttl=63 time=1.47 ms
^C
--- 192.168.31.216 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1002ms
rtt min/avg/max/mdev = 1.098/1.282/1.467/0.184 ms


hoanglh@DESKTOP-GKJJ17P:~$ ssh hoangmnsd@192.168.31.216
The authenticity of host '192.168.31.216 (192.168.31.216)' can't be established.

Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Please type 'yes', 'no' or the fingerprint: yes
Warning: Permanently added '192.168.31.216' (ECDSA) to the list of known hosts.
hoangmnsd@192.168.31.216's password:
Welcome to Ubuntu 20.04.6 LTS (GNU/Linux 5.4.0-189-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Sat 20 Jul 2024 08:53:11 AM UTC

  System load:             0.09
  Usage of /:              49.4% of 8.02GB
  Memory usage:            23%
  Swap usage:              0%
  Processes:               109
  Users logged in:         1
  IPv4 address for enp0s3: 192.168.31.216
  IPv6 address for enp0s3: fd00:6868:6868::ce6
  IPv6 address for enp0s3: fd00:6868:6868:0:a00:27ff:fe06:130d


 * Introducing Expanded Security Maintenance for Applications.
   Receive updates to over 25,000 software packages with your
   Ubuntu Pro subscription. Free for personal use.

     https://ubuntu.com/pro

Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


The list of available updates is more than a week old.
To check for new updates run: sudo apt update
New release '22.04.3 LTS' available.
Run 'do-release-upgrade' to upgrade to it.


Last login: Sat Jul 20 08:42:52 2024
hoangmnsd@oraclevmbox01-ubuntu20:~$
```

Việc SSH từ ngoài Host như WSL/Putty đến được VM rất quan trọng, vì như thế chứng minh Network traffic thông suốt, và có thể dùng chuột để copy/trỏ/paste các command nhanh hơn dùng cái Terminal của VirtualBox. Hiện mình thấy VirtualBox chưa hỗ trợ con trỏ chuột nên mỗi command đều phải gõ từ đầu rất mất time.


# Ubuntu

## 1. Install Python3.9 for Ubuntu

### 1.1. install python3.9 (from apt)  

```sh
# install python3.9
sudo apt-get update
sudo apt-get upgrade -y

sudo apt install software-properties-common
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt install python3.9
sudo apt install python3-pip
```

But when I check version of pip3:  

```sh
# check pip3 version
$ pip3 --version
pip 9.0.1 from /usr/lib/python3/dist-packages (python 3.6)
# => means you are using pip3 from python3.6, i want to install pip3 for python3.9
```

install pip3 for python3.9: 

```sh
# install pip3 for python3.9
# https://stackoverflow.com/questions/65644782/how-to-install-pip-for-python-3-9-on-ubuntu-20-04
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
sudo apt install python3.9-distutils
python3.9 get-pip.py

# check default python3 version
$ python3 --version
Python 3.6.9

# change default python3 to python3.9
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.6 1
sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.9 2

update-alternatives --config python3
# => select number of python3.9

# check default python3 version
$ python3 --version
Python 3.9.16
# => ok, default python3 is now python3.9

$ pip3 --version
pip 9.0.1 from /usr/lib/python3/dist-packages (python 3.9)
# => OK
```

Troubleshooting khi dùng pip3 install 1 package nào đó:  

```sh
# Fix trước 1 lỗi https://bobbyhadz.com/blog/python-attributeerror-htmlparser-object-has-no-attribute-unescape
pip install --upgrade setuptools
pip3 install --upgrade setuptools

pip install --upgrade distlib
pip3 install --upgrade distlib

pip3 install --upgrade pip
```

Giờ bạn đã có pip3 tương ứng với từng version Python3.6 / Python3.9.  
Điều quan trọng mà bạn cần nhớ là đôi khi có những package cần phải install bằng python3.6 thì mới work, nên phải dùng pip3 tương ứng của Python3.6 để install.  

Tất nhiên hầu hết trường hợp là cứ dùng version cao hơn thì tốt hơn.  


### 1.2. install python3.9 (from source)  

Có thể có TH OS của bạn ko thể install python3.9 bằng apt được vì lỗi:

```
Reading package lists... Done
Building dependency tree
Reading state information... Done
E: Unable to locate package python3.9
E: Couldn't find any package by glob 'python3.9'
E: Couldn't find any package by regex 'python3.9'
```

Solution:

```sh
sudo apt install build-essential zlib1g-dev \
libncurses5-dev libgdbm-dev libnss3-dev \
libssl-dev libreadline-dev libffi-dev curl software-properties-common
```

```sh
wget https://www.python.org/ftp/python/3.9.0/Python-3.9.0.tar.xz
tar -xf Python-3.9.0.tar.xz
```

```sh
cd Python-3.9.0

./configure

sudo make altinstall

python3.9 --version
```

## 2. Install Python3.10 for Ubuntu (from source)

1 số Ubuntu như 18.04 ko thể install python3.10/python3.9 được vì lỗi này:

```
Reading package lists... Done
Building dependency tree
Reading state information... Done
Note, selecting 'postgresql-plpython3-10' for regex 'python3.10'
postgresql-plpython3-10 is already the newest version (10.19-0ubuntu0.18.04.1)
```

Nguyên nhân do https://github.com/deadsnakes/issues/issues/269

`deadsnakes` đã xóa hết các package dành cho Ubuntu 18.04 nên mọi người ko dùng được nữa.

Bắt buộc phải install from source python3.10:

```sh
sudo apt update && sudo apt upgrade

sudo apt install wget build-essential libreadline-gplv2-dev libncursesw5-dev \
     libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev

wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tgz

tar xzf Python-3.10.0.tgz

cd Python-3.10.0

./configure --enable-optimizations

sudo make altinstall # câu lệnh này phải dùng altinstall nhé, nếu là install sẽ bị ghi đè python của hệ thống, gây lỗi OS

python3.10 -V

python3.10 --version
```

## 3. Install Docker, Docker Compose in Ubuntu 20.04/18.04 (Oracle cloud VM ARM based CPU)

```sh
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo apt update
sudo apt upgrade -y
sudo apt install docker.io -y
sudo systemctl enable docker
sudo curl -L "https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-linux-aarch64" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
```

## 4. Install Docker, Docker Compose in Ubuntu 20.04 (AMD based CPU)

```sh
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
sudo apt update
apt-cache policy docker-ce
sudo apt install docker-ce -y
sudo systemctl status docker
sudo usermod -aG docker ${USER}
exit
login again

sudo curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
sudo systemctl enable docker

wget https://bootstrap.pypa.io/get-pip.py
sudo python3 get-pip.py
pip install requests==2.31 docker==6.1.3 docker-compose==1.29.2
pip show docker-compose docker
```

## 5. Activate python3.10 venv

Nếu bị lỗi này:

```
$ python3.10 -m venv .venv
Error: Command '['XXX/.venv/bin/python3.10', '-m', 'ensurepip', '--upgrade', '--default-pip']' returned non-zero exit status 1.
```

Thì bạn cần cài như sau: https://askubuntu.com/a/1379765

```sh
sudo apt-get install python3.10-dev
sudo apt-get install python3.10-venv

$ python3.10 -m venv .venv
$ source .venv/bin/activate
(.venv) ...
```

# WSL

## 1. Lỗi mất internet connection khi ping google từ WSL terminal

Story: 

Thi thoảng Syncthing trên PC ko bật tự động, dẫn đến mình phải bật nó lên thủ công, nhưng bật lên thủ công cứ bật là nó lại tự động tắt ngay sau đó, do có 1 port nào đó đã bị sử dụng.

Giải pháp để có thể bật Syncthing mà ko cần restart PC là, bật Powershell as Administrator:

```s
PS C:\Windows\system32> net stop winnat
The Windows NAT Driver service was stopped successfully.

PS C:\Windows\system32> net start winnat
The Windows NAT Driver service was started successfully.
```

Sau đó có thể bật Syncthing mà nó ko tự động tắt nữa..

Tuy nhiên lại xuất hiện 1 lỗi khác là: Mất internet connection của WSL.

Giải pháp là switch WSL version to 1 or 2: https://stackoverflow.com/a/66005586/9922066

```s
PS C:\Windows\system32> wsl --list --verbose
  NAME                   STATE           VERSION
* Ubuntu-20.04           Running         2
  docker-desktop         Stopped         2
  Ubuntu-18.04           Stopped         1
  docker-desktop-data    Stopped         2

PS C:\Windows\system32> wsl --shutdown

PS C:\Windows\system32> wsl -t Ubuntu-20.04

PS C:\Windows\system32> wsl --list --verbose
  NAME                   STATE           VERSION
* Ubuntu-20.04           Stopped         2
  docker-desktop         Stopped         2
  Ubuntu-18.04           Stopped         1
  docker-desktop-data    Stopped         2

PS C:\Windows\system32> wsl --set-version Ubuntu-20.04 1
Conversion in progress, this may take a few minutes...
Conversion complete

PS C:\Windows\system32> wsl --list --verbose
  NAME                   STATE           VERSION
* Ubuntu-20.04           Stopped         1
  docker-desktop         Stopped         2
  Ubuntu-18.04           Stopped         1
  docker-desktop-data    Stopped         2
PS C:\Windows\system32>
```

Giờ thử lại sẽ ko bị mất internet nữa:  
```
$ ping google.com
PING google.com (142.250.66.142) 56(84) bytes of data.
64 bytes from hkg12s29-in-f14.1e100.net (142.250.66.142): icmp_seq=1 ttl=115 time=40.7 ms
64 bytes from hkg12s29-in-f14.1e100.net (142.250.66.142): icmp_seq=2 ttl=115 time=43.7 ms
^C
--- google.com ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1001ms
```

# CREDIT

https://quantrimang.com/cong-nghe/cach-tao-usb-boot-usb-cai-windows-bang-rufus-118460  
https://www.youtube.com/watch?v=I4_50zV63pA&ab_channel=TechwithStefan  
https://blogchiasekienthuc.com/thu-thuat-may-tinh/sao-luu-va-phuc-hoi-windows-tib.html  
https://anh-dv.com/usb-boot/tao-usb-boot-uefi-legacy-cuu-ho-may-tinh-chuyen  
https://anh-dv.com/ghost/ghost-windows-10-uefi-voi-acronis-true-image/comment-page-1#comments  
https://stackoverflow.com/questions/60824700/how-can-i-install-python-3-9-on-a-linux-ubuntu-terminal  

Các loại config network adapter khác nhau trong VirtualBox:  
https://www.golinuxhub.com/2017/08/how-to-configure-different-types-of/