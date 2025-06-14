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

### 1.9. Ethernet bị disable (ko có đèn xanh)

- Ngoài ra, nếu bạn ko muốn dùng wifi, mới đầu Ethernet bị disable (ko có đèn xanh), phải run command sau: "sudo dhclient -v". Thì sẽ thấy cổng Ethernet sáng đèn xanh. Bạn có thể add command đó vào file user-data để nó enable Ethernet ngay từ đầu

## 2. Raspian OS (no desktop environment)  

Check RPi hiện tại là bản 32bit hay 64bit:   

```
getconf LONG_BIT
# result 64
```

Chọn OS sau:

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/rpi-image-os-64bit.jpg)

### 2.1. Initial setup (connect to Wifi)

Với OS này thì đơn giản hơn vì tài liệu trên mạng rất đầy đủ

- Sau khi flash image Raspian OS without desktop vào microSD, tháo ra insert lại vào Laptop  
- Tạo 2 file sau: `SSH` và `wpa_supplicant.conf` trong root directory của microSD  
  + File `SSH` ko có content - dùng để enable SSH service.  
  + File `wpa_supplicant.conf` có content như sau:   

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

- Cắm microSD vào RPi, Cắm dây HDMI, cắm bàn phím. Rồi mới cắm dây nguồn.
- Đừng cắm dây LAN vội. Nếu cắm LAN có thể bị lỗi cả 2 eth0 và wlan0 cùng chọn 1 IP làm ko kết nối được.  
- Ngồi chờ màn hình load OS, tầm vài phút.  
- Login với user/password vào (đặt đơn giản dùng số và chữ tầm ký tự đặc bieetsk thì chọn ! thôi, vì sợ khi cắm bàn phím vào bị đổi layout UK thì các ký tự đặc biệt nó lệch đi).  
- Run `sudo raspi-config` rồi chọn Interface Options -> enable SSH lên (Bước này làm cho chắc ăn thôi, chứ chắc có file `SSH` là OK rồi).  
- `sudo reboot` để restart take effect.  
- Check `ping google.com` xem có mạng chưa.  
- Nếu chưa có mạng thì vào `sudo raspi-config` -> chọn Internet... -> chọn cái gì để điền SSID và password wifi vào nhé, rồi `sudo reboot`.  
- Check `ifconfig` xem có IP chưa, nếu có dòng này ở wlan0, nghĩa là đã connect vào wifi, IP là 192.168.X.Y:  

  ```
  wlan0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
    inet 192.168.1.5  netmask 255.255.255.0  broadcast 192.168.1.255
  ```
- Cắm dây LAN vào rồi check `ifconfig` lại xem eth0 IP đã lên chưa:  

  ```
  eth0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
    inet 192.168.1.6  netmask 255.255.255.0  broadcast 192.168.1.255
  ```

- Thử SSH vào xem. SSH bằng cả IP wlan0 lẫn IP eth0 xem, phải OK mới được.  
- Tắt RPi đi `sudo shutdown -h now`, rút nguồn. Cắm vào chỗ để lâu dài. Đừng cắm dây LAN vội. Nếu cắm LAN có thể bị lỗi cả 2 eth0 và wlan0 cùng chọn 1 IP làm ko kết nối được. Để nguyên xem nó connect Wifi OK ko.
- Nếu SSH vào OK thì có nghĩa connect Wifi ok. Lúc này mới tiếp tục cắm dây LAN test lại.  
- Nếu vẫn ko thể connect được đến IP eth0 thì có 2 khả năng:
  + là dây cable mạng LAN có vấn đề. Đổi dây khác.
  + là cổng mạng LAN có vấn đề. (Đổi dây cable mà vẫn bị). Đành phải bỏ ko dùng cổng LAN đó. Mua hub mở rộng cổng mạng LAN (?)  

Mạng nhà mình bị trường hợp là: 1 Cổng mạng LAN có vấn đề. Dù dùng dây cable nào thì PC cũng vẫn vào được mạng bình thường (vẫn xem được youtube/google, cổng mạng vẫn nháy đèn xanh), nhưng lại không thể ping/ssh từ PC khác đến được, cũng ko thể ping/ssh đến PC khác. Đến giờ vẫn chưa giải quyết được. Mình đã dán nhãn Hỏng chỗ Router chính của cổng LAN đó.  

### 2.2. Setup static IP

Bình thường mỗi khi mất mạng, stop/start RPi khả năng RPi sẽ bị thay đổi internal IP

Bạn muốn cố định IP của RPi mỗi khi như vậy cần SSH vào RPi rồi sửa ở đây `nano /etc/dhcpcd.conf`:  
```sh
...
# Example static IP configuration:
...

# Hoang: set static IP BEGIN
 # setting for ethernet (LAN)
interface eth0
static ip_address=192.168.1.128/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1 8.8.8.8
 # setting for wiredless (WIFI)
interface wlan0
static ip_address=192.168.1.200/24
static routers=192.168.1.1
static domain_name_servers=192.168.1.1 8.8.8.8
# Hoang: END

```
Chú ý có phần sửa:  
- wlan0 là config khi dùng mạng WIFI (Wireless - ko dây)  
- eth0 là config khi dùng mạng dây (Ethernet)   
- nên set các IP khác nhau thì khi vừa kết nối eth0 và wlan0 sẽ ko bị trùng nhau (dẫn đến ko kết nối được)  
- `static routers=` là config IP của Router nhà bạn (thường là `192.168.1.1`)    

Giờ reboot RPi để apply thay đổi:  
```sh
sudo reboot
```

Done, SSH vào cả 2 IP wlan0 và eth0 để check connection.  

Nếu muốn disable Wifi đi cho an toàn thì, SSH vào RPi `sudo nano /boot/config.txt`:

```
# add this line to disable wifi
dtoverlay=disable-wifi
```

Rồi `sudo reboot`. Giờ sẽ ko có Wifi, nếu muốn có Wifi thì phải sửa file trên, xóa line `dtoverlay=disable-wifi` đi.

### Nếu cần remote VNC vào RPi có desktop

Trong trường hợp bạn cần remote (dùng VNC) vào desktop của RPi chạy Raspian OS with desptop environment:  
- Nên enable SSH trước  
- Dùng Putty SSH vào rPi, run command `vncserver` để enable VNC server  
- Sẽ nhìn thấy output của command trên kiểu:  
```
New desktop is raspberrypi:1 (192.168.1.4:1)  
```
- Tải và cài đặt trên laptop phần mềm: VNC viewer  
- Dùng VNC connect vào ip: 192.168.1.4:1  

### Shutdown an toàn RPi

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


# CREDIT

https://sergejskozlovics.medium.com/how-to-set-up-a-wireless-ubuntu-server-on-raspberry-pi-89b84dca34d2  
https://forums.raspberrypi.com/viewtopic.php?t=258832  
https://raspberrypi.vn/thiet-lap-dia-chi-ip-tinh-cho-raspberry-147.pi  

Disable Wifi:
https://linuxhint.com/disable-wifi-raspberry-pi-when-ethernet-connected/#:~:text=The%20Raspberry%20Pi%20users%20can,the%20WiFi%20on%20Raspberry%20Pi.  