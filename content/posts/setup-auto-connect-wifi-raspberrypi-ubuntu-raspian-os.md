---
title: "Raspberry Pi: Setup auto connect wifi at first boots for Ubuntu OS, Raspian OS"
date: 2022-03-26T23:42:35+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [RaspberryPi]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Ban đầu mình muốn connect wifi cho RPi thì phải flash OS vào thẻ microSD, cắm bàn phím, màn hình, rồi cắm dây nguồn. Sau đó vào sửa 1 số file config để connect wifi. Điều này khiến mình thấy loằng ngoằng và tốn thời gian.  "
---

Mày mò vọc vạch về Raspberry Pi 4B/8GB 1 chút. 

# Vấn đề  

Ban đầu mình muốn connect wifi cho RPi thì phải flash OS vào thẻ microSD, cắm bàn phím, màn hình, rồi cắm dây nguồn.  
Sau đó vào sửa 1 số file config để connect wifi. Điều này khiến mình thấy loằng ngoằng và tốn thời gian.  

# Mục tiêu 

Với nhu cầu bản thân chỉ cần remote từ laptop SSH vào RPi (via Putty), ko cần RPi có desktop. Thế nên mình muốn mỗi khi mình flash OS vào thẻ microSD, thẻ SD đó sẽ config hết mọi thứ sẵn. Mình chỉ cần cắm nguồn vào RPi, sau đó là mình có thể từ laptop SSH vào RPi được luôn (via Putty). 

# Cách làm

## 1. Ubuntu Server OS 20.04 LTS (no desktop environment)

Việc setup cho connect wifi trên Raspian OS thì có lẽ đã có nhiều bài viết trên mạng rồi, nhưng dành cho Ubuntu OS thì cũng có nhưng mình làm theo thì hầu như không thành công.  

Mình viết bài này để note lại các steps cần làm và chú ý trong quá trình setup.  

### 1.1. Format microSd by Raspberry Pi Imager version >= 1.7.1

link download: https://www.raspberrypi.com/software/

Chuẩn bị 1 thẻ nhớ microSD, cắm vào Laptop.  

Dùng chức năng ERASE để format thẻ nhớ sang fat32 trước:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/rpi-imager-ease.jpg)

### 1.2. Select OS

Sau khi format xong, quay lại chọn OS Ubuntu Server 20.04 LTS, 64 bit.  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/rpi-imager-os-ubuntu-server-20.04.jpg)

### 1.3. Config Advanced options 

Chọn Advanced Option, set hostname, enable SSH, set ssh public key (để cho secure thì nên disable chức năng authen via password), configure WIFI, password wifi, wifi country...  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/rpi-imager-os-ubuntu-advanced-config1.jpg)  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/rpi-imager-os-ubuntu-advanced-config2.jpg)  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/rpi-imager-os-ubuntu-advanced-config3.jpg)  

### 1.4. Process

Click button `Write` để tiến hành Flash OS vào thẻ microSD

### 1.5. Re-insert microSD to Laptop

Sau khi RP Imager done, tháo thẻ microSD ra. Cắm lại vào laptop.  

### 1.6. Edit `user-data` file

Tìm đến directory của microSD: `system-boot`.Bạn sẽ tìm 2 file sau: `user-data`, và `network-config`

2 file được generated bởi nhưng thông tin mà bạn đã input vào Raspberry Pi Imager ở step 3

Nội dung file `network-config` sẽ tương tự như này:  
```
version: 2
wifis:
  renderer: networkd
  wlan0:
    dhcp4: true
    optional: true
    access-points:
      "okThisIsMyWifi":
        password: "ced8123jka92312j332kj4b1j4b4jk14hbg3a6181234nkjn"
```
-> bạn ko cần phải sửa gì file `network-config` này. Password của bạn đã được mã hóa.

Nội dung file `user-data` sẽ tương tự như này:  
```
#cloud-config
hostname: ubuntu-rpi
manage_etc_hosts: true
packages:
- avahi-daemon
apt:
  conf: |
    Acquire {
      Check-Date "false";
    };

users:
- name: ubuntu
  groups: users,adm,dialout,audio,netdev,video,plugdev,cdrom,games,input,gpio,spi,i2c,render,sudo
  shell: /bin/bash
  lock_passwd: true
  ssh_authorized_keys:
    - ssh-rsa AAAABkjasbjkfkjdnvlvnjkdncsdn+w3Y0g24ieofnodfcndlkcfnmefjewnfd/ldmfjkwldsmvkvnwdlvn+pakovnweojfnwefojwefnjkenfdoeD9=
  sudo: ALL=(ALL) NOPASSWD:ALL


runcmd:
- sed -i 's/^s*REGDOMAIN=S*/REGDOMAIN=VN/' /etc/default/crda || true
```

-> bạn cần sửa file `user-data` này, add thêm dòng sau:  
```
....
runcmd:
- sed -i 's/^s*REGDOMAIN=S*/REGDOMAIN=VN/' /etc/default/crda || true
- netplan apply

# Reboot after cloud-init completes
power_state:
  mode: reboot

```

Như bạn thấy, mình add thêm command `netplan apply` 
và phần `reboot` để RPi của mình sẽ reboot ở step cuối cùng.  

Vậy là xong phần chuẩn bị cho thẻ microSD. Eject nó ra khỏi Laptop, giờ bạn có thể cắm nó vào RPi rồi.

### 1.7. Setup RPi

Cắm thẻ nhớ microSD vào RPi, cắm HDMI (cái này tùy bạn, nhưng cắm HDMI thì bạn sẽ theo dõi được quá trình bootstrap của OS, nếu ko theo dõi thì bạn chờ 3-4 phút rồi quay lại)

Cắm dây nguồn vào RPi.

Màn hình của RPi mà hiện như này nghĩa là đã xong:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/rpi-ubuntu-os-cloudinit-done.jpg)

### 1.8. SSH to RPi

Giờ bạn chỉ cần tìm xem ip của RPi là gì, rồi dùng Putty SSH vào thôi. Thường thì để check ip của RPi mình vào 192.168.1.1 để đăng nhập vào giao diện của modem internet.

### 1.9. Chú ý

- Ngoài ra, nếu bạn ko muốn dùng wifi, mới đầu Ethernet bị disable (ko có đèn xanh), phải run command sau: "sudo dhclient -v". Thì sẽ thấy cổng Ethernet sáng đèn xanh. Bạn có thể add command đó vào file user-data để nó enable Ethernet ngay từ đầu


## 2. Raspian OS (no desktop environment)  

### 2.1. Initial setup

Với OS này thì đơn giản hơn vì tài liệu trên mạng rất đầy đủ

- Sau khi flash image Raspian OS without desktop vào microSD, tháo ra insert lại vào Laptop  
- Tạo 2 file sau: `SSH` và `wpa_supplicant.conf` trong root directory của microSD  
- File `SSH` ko có content  
- File `wpa_supplicant.conf` có content như sau:   

```
country=vn
update_config=1
ctrl_interface=/var/run/wpa_supplicant

network={
 scan_ssid=1
 ssid="okThisIsMyWifi"
 psk="12345678"
}
```

- Cắm microSD vào RPi, tìm IP của nó, rồi SSH bằng Putty vào với user mặc định: `pi`, pass: `raspberry`. SSH dc rồi thì đổi pass đi nhé.

### 2.2. Setup static IP

Bình thường mỗi khi mất mạng, stop/start RPi khả năng RPi sẽ bị thay đổi internal IP

Bạn muốn cố định IP của RPi là `192.168.1.200` mỗi khi như vậy cần SSH vào RPi rồi sửa ở đây `/etc/dhcpcd.conf`:  
```sh
...
# Example static IP configuration:
...

# Hoang: set static IP BEGIN
 # setting for ethernet (WIFI)
interface eth0
static ip_address=192.168.1.200/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1 8.8.8.8
 # setting for wired (LAN)
interface wlan0
static ip_address=192.168.1.200/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1 8.8.8.8
# Hoang: END
...
```
chú ý có phần sửa:  
`eth0` là config khi dùng mạng WIFI (Ethernet ko dây)   
`wlan0`là config khi dùng mạng dây (Wired)  
`static routers=` là config IP của Router nhà bạn (thường là `192.168.1.1`)  

Giờ reboot RPi để apply thay đổi:  
```sh
sudo reboot
```

Done, SSH to `192.168.1.200` to check again!

### Chú ý 

Trong trường hợp bạn cần remote (dùng VNC) vào desktop của RPi chạy Raspian OS with desptop environment:  
- Nên enable SSH trước  
- Dùng Putty SSH vào rPi, run command `vncserver` để enable VNC server  
- Sẽ nhìn thấy output của command trên kiểu:  
```
New desktop is raspberrypi:1 (192.168.1.4:1)  
```
- Tải và cài đặt trên laptop phần mềm: VNC viewer  
- Dùng VNC connect vào ip: 192.168.1.4:1  

## Bonus

Không nên rút dây nguồn của RPi đột ngột, mà nên shutdown OS trước:  
Command to shutdown safely via SSH, Raspian OS:
```sh
sudo shutdown -h now
sudo shutdown -h 2

# Reboot:
sudo shutdown -r now
```

Check model of RPi on Raspian OS:  
```sh
pi@raspberrypi:~ $ cat /proc/cpuinfo | grep Model
```


# References

https://sergejskozlovics.medium.com/how-to-set-up-a-wireless-ubuntu-server-on-raspberry-pi-89b84dca34d2  
https://forums.raspberrypi.com/viewtopic.php?t=258832  
https://raspberrypi.vn/thiet-lap-dia-chi-ip-tinh-cho-raspberry-147.pi  
