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
description: "Các step khi cài lại Win10, các link cần nhớ, các phần mềm cài cài..."
---

# 1. Create USB Boots Win10

## 1.1. Download windows 10

từ https://www.microsoft.com/software-download/windows10.  

Bật F12 vì MS chỉ cho phép tải từ trình duyệt mobile.

## 1.2. Download Rufus từ https://rufus.ie/

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/usb-boot-rufus-config.jpg)

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/usb-boot-rufus-config-start.jpg)

Xong thì có thể eject USB và rút ra

# 2. Install Win10 from USB Boots

## 2.1. Cắm USB đã cài Win10 vào

## 2.2. Start/restart máy

ấn liên tục F10 để vào Boots Menu screen

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/boot-win10-menu1.jpg)

## 2.3. Chọn cái USB bên trên

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

## 2.4. Sau khi vào thì update Windows drivers 

Bằng cách vào Settings -> Update & Security -> Windows Update -> Check for Updates -> install

## 2.5. Udate Intel drivers

Mở Edge browser, search intel driver -> Get Start -> Download - Install - Accept, vào lại browser sẽ thấy nhiều update availables -> Download all

Chờ tất cả các Drivers download hết rồi thì restart 1 thể.  

Có thể sẽ phải restart vài lần.  

# 3. Cài các phần mềm cần thiết cho công việc

## 3.1. Disable Bitlocker Encryption

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

## 3.2. Install MS Office

Tạo account MS Developer E5 link với github theo guideline trên mạng

Login vào portal.office.com

Download and Install Office application

Sau đó vào Excel, Signin vào Excel bằng account bên trên

## 3.3. Copy bộ cài đã download 

...từ trong ổ cứng di dộng ra, cần phần mềm nào thì cài.

Riêng IDM thì cứ cài latest, xong rồi dùng script này để activate:  
https://github.com/lstprjct/IDM-Activation-Script

Run on Powershell:  

```sh
iwr -useb https://raw.githubusercontent.com/lstprjct/IDM-Activation-Script/main/IAS.ps1 | iex
```

Riêng Your Uninstaller Pro 7.5(2014), cài xong thì điền key sau:  

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
Utorrent
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
The Great suspender
```

## 3.4. Activate Kaspersky Total Security

Lên topic này xin key: https://vn-z.vn/threads/kaspersky-total-security-500-days.15942/page-380

Có thể sẽ phải dùng OpenVPN sang Đức hoặc Brazil Italia Egypt để active key, trung binh key khoảng vài tháng 1 năm

ví dụ mình xin đc key này: A989W-BBYCM-B1NH5-82T2T - Đức (hạn March 5, 2024)

## 3.5. Troubeshooting

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


# 4. Backup 

## 4.1. Backup bằng chức năng của Win10 trên chính ổ SSD đó (phân vùng khác) bị failed

Vào Setting -> Update & security -> Backup

Go to Backup and restore (Windows 7)

Setup a backup

Chọn ổ sẽ lưu file backup

Quá trình run backup bị failed, thôi bỏ ko dùng cách này nữa

## 4.2. Ghost Win10 with Acronis True Image

Sau khi cài tất cả các phần mềm cần thiết, sử dụng OK 1 thời gian thì nên Ghost lại 1 image để backup.  

Sau này nếu dính virus, máy chậm quá, thì "bung" ra, ko cần phải cài phần mềm nọ kia gì nữa. Cứ thế dùng luôn.  

## 4.2.1. Tạo usb boot anhdv

https://anh-dv.com/usb-boot/tao-usb-boot-uefi-legacy-cuu-ho-may-tinh-chuyen

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/anhdvboot-one-click-1.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/anhdvboot-one-click-2.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/anhdvboot-one-click-3.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/anhdvboot-one-click-4.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/anhdvboot-one-click-5.jpg)  
chờ vài phút...
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/anhdvboot-one-click-6.jpg)  
 
## 4.2.2. Tạo file ghost .tib bằng Acronis True Image có trong usb trên

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


## 4.2.3. Restore từ file ghost .tib bằng usb trên

https://anh-dv.com/ghost/ghost-windows-10-uefi-voi-acronis-true-image/comment-page-1#comments


# 5. Install Python3.9 for Ubuntu

install python3.9:  

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

# CREDIT

https://quantrimang.com/cong-nghe/cach-tao-usb-boot-usb-cai-windows-bang-rufus-118460  
https://www.youtube.com/watch?v=I4_50zV63pA&ab_channel=TechwithStefan  
https://blogchiasekienthuc.com/thu-thuat-may-tinh/sao-luu-va-phuc-hoi-windows-tib.html  
https://anh-dv.com/usb-boot/tao-usb-boot-uefi-legacy-cuu-ho-may-tinh-chuyen  
https://anh-dv.com/ghost/ghost-windows-10-uefi-voi-acronis-true-image/comment-page-1#comments  