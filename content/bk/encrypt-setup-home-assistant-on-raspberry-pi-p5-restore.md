---
title: "Setup Home Assistant on Raspberry Pi (Part 5) - Restore"
date: 2023-07-18T23:04:36+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [HomeAssistant]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Đây là phần riêng nói về quá trình mình restore rPi sang 1 chiếc mcroSD mới (từ 16Gb lên 64Gb)"
---

Đây là phần riêng nói về quá trình mình restore rPi sang 1 chiếc microSD mới (từ 16Gb lên 64Gb)

Vì với chiếc microSD cũ mình đã setup hệ thống HASS và rất nhiều thứ linh tinh, nên giờ chuyển sang cần có plan cụ thể, cố gắng restore mọi thứ trơn tru trong thời gian ngắn nhất.

Trước đây ở [part 1](../../posts/encrypt-setup-home-assistant-on-raspberry-pi-and-addons/#81-setup-duplicati-backup-to-aws-s3) mình đã setup Duplicati để backup các file trên rPi rồi. Giờ chuyển sang SD mới thì cần chuyển data sang.  

Xác định các thay đổi:  
- Sẽ sửa `swag` để request Letsencrpyt certificate cho all subdomains `*.MAIN.duckdns.org` (not `MAIN.duckdns.org` domain).
- Kết nối rPi với Internet bằng dây LAN chứ ko dùng Wifi nữa.  

# (optional) Download backup của Duplicati hiện tại về cho chắc

Goto Duplicati -> Restore -> RPiBackupS3 -> Next, select all folders -> Pick location -> Computer -> source -> (tạo 1 location riêng cho backup: `/opt/duplicati-backup`), chọn overwrite (vì mình tạo folder mới tinh nên ko lo) -> uncheck "Restore read/write permissions" -> Restore (Chờ phải khoảng 20min cho khoảng 150Mb)

SSH vào rPi, vào `/opt/duplicati-backup`, zip lại folder vừa tạo thành file: zip: `zip -r duplicati-backup.zip /opt/duplicati-backup`

dùng SFTP download file `duplicati-backup.zip` về máy. Yên tâm ko sợ restore lỗi nữa.  

# 1. Chọn microSD nào?

Trong bài sau có người khuyên nên dùng thẻ SD card này: `SanDisk Extreme 64 GB microSDXC A2 App Performance`:   
(https://community.home-assistant.io/t/how-to-reduce-your-database-size-and-extend-the-life-of-your-sd-card/205299/66?u=super318)  
(https://cyan-automation.medium.com/best-sd-card-for-home-assistant-raspberry-pi-62df0674c405)  

Nên mình quyết định mua về dùng:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/sandisk-extreame-a2-v30-64g.jpg)

# 2. Cần tìm lại được các password backup của Duplicati file, các key đến S3

Đã backup từ trước

# 3. Setup lại các thứ ban đầu

Trước khi install:  

```
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        59G  1.7G   55G   3% /
devtmpfs        3.6G     0  3.6G   0% /dev
tmpfs           3.9G     0  3.9G   0% /dev/shm
tmpfs           1.6G  1.1M  1.6G   1% /run
tmpfs           5.0M  4.0K  5.0M   1% /run/lock
/dev/mmcblk0p1  255M   31M  225M  13% /boot
tmpfs           782M     0  782M   0% /run/user/1000
```

Sau khi install xong:

```
$ df -h
Filesystem      Size  Used Avail Use% Mounted on
/dev/root        59G  8.9G   48G  16% /
devtmpfs        3.6G     0  3.6G   0% /dev
tmpfs           3.9G     0  3.9G   0% /dev/shm
tmpfs           1.6G  1.9M  1.6G   1% /run
tmpfs           5.0M  4.0K  5.0M   1% /run/lock
/dev/mmcblk0p1  255M   31M  225M  13% /boot
tmpfs           782M     0  782M   0% /run/user/1000
```

Những setup lại ban đầu để SSH vào được rPi thì mình sẽ đọc lại bài [này](../../posts/encrypt-setup-auto-connect-wifi-raspberrypi-ubuntu-raspian-os)

Sau đó install các phần mềm cần thiết theo bài [này](../../posts/encrypt-setup-home-assistant-on-raspberry-pi-and-addons/#1-install-docker--docker-compose)

Sau đó install Portainer. Setup admin/password

Sau đó install Duplicati (comment các phần khác `trong docker-compose.yml`)

Tìm cách setup connection đến S3 bucket (nơi đang lưu các bản backup)

# 4. Restore data về từ S3 bucket bằng Duplicati 

Vào Duplicati Restore -> `Direct restore from backup files ..` -> Chọn `S3 Compatible`

Điền Bucket name, region (singapore), folder path (rpi4b), ACCESS ID/KEY

Test connection -> Nếu nó hỏi muốn prepend vào bucketname thì chọn "No" -> `Connection worked` là OK

Ấn Next

Enter backup Passphrase -> Connect, chờ 1 lúc để Duplicati fetch data (chắc phải mất 10-15 phút, và có thể phải làm lại)

Chọn tất cả source folder -> Continue

Lên RPi tạo folder `/opt/duplicati-backup`

Trên Duplicati, Chọn Pick localtion -> Chỗ folder path -> select source ->  chọn folder đã tạo bên trên `duplicati-backup`. Data restore sẽ được đưa vào folder này

Tiếp, chọn Overwrite (ko sao, vì folder đó đang empty)

Chỗ Permission, ko tick gì cả. Continue. Chờ restore xong chắc mất  15-20 phút.

Rồi dùng terminal `cp -rp` copy lần lượt các folder mong muốn từ `/opt/duplicati-backup` sang `/opt` để sử dụng

# 5. Bắt đầu setup HASS 

Giờ sửa file `docker-compose.yml` để đưa các component khác vào

Đưa duckdns vào trước. Check trên duckdns.org xem IP của mình đã cập nhật chưa.

Cắm cái USB Dongle Sonoff vào trước. Lấy được đúng `ttyUSB0`

```
 $ ls -l /dev/serial/by-id/
total 0
lrwxrwxrwx 1 root root 13 Aug  6 13:22 usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_e8fc8a915ad9eb119edf148e6fe9f4d9-if00-port0 -> ../../ttyUSB0
```

Đưa `homeassistant,mosquitto,zigbee2mqtt` vào. Run `docker-compose up -d`

Check giao diện HASS có HACS, điều khiển được các đèn là OK.

Check connection RM4 mini xem có gửi tín hiệu đến Điều hòa, quạt được ko, có trả về độ ẩm nhiệt độ ko?

# 6. Setup các iptable rules để chặn connect nếu rPi đang trong DMZ

Xem các port đang open:

```sh
# UDP
$ sudo nmap -sU -p- 192.168.1.128
Starting Nmap 7.80 ( https://nmap.org ) at 2023-08-06 20:58 +07
Nmap scan report for 192.168.1.128
Host is up (0.000040s latency).
Not shown: 65529 closed ports
PORT      STATE         SERVICE
68/udp    open|filtered dhcpc
546/udp   open|filtered dhcpv6-client
5353/udp  open          zeroconf
51820/udp open|filtered unknown
56002/udp open|filtered unknown
57929/udp open|filtered unknown

# TCP
$ sudo nmap -sT -p- 192.168.1.128
Starting Nmap 7.80 ( https://nmap.org ) at 2023-08-06 21:00 +07
Nmap scan report for 192.168.1.128
Host is up (0.00056s latency).
Not shown: 65526 closed ports
PORT     STATE SERVICE
22/tcp   open  ssh
443/tcp  open  https
1883/tcp open  mqtt
3000/tcp open  ppp
8080/tcp open  http-proxy
8123/tcp open  polipo
8200/tcp open  trivnet1
9000/tcp open  cslistener
9090/tcp open  zeus-admin
```

Vào portal của Router, enable DMZ cho ip của RPi 192.168.1.128

Nếu lần này chuyển sang dùng mạng LAN (eth0) ko dùng mạng Wifi nữa thì cũng cần chú ý các rule nên sửa kiểu khác.

Đọc lại bài [này](../../posts/encrypt-setup-home-assistant-on-raspberry-pi-p2-dmz)

Check các rule đã tồn tại:

```
$ sudo iptables -L -v -n | more
Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain FORWARD (policy DROP 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination
 393K  919M DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
 393K  919M DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
 349K  903M ACCEPT     all  --  *      br-7593419e3462  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
  107  9369 DOCKER     all  --  *      br-7593419e3462  0.0.0.0/0            0.0.0.0/0
43902   15M ACCEPT     all  --  br-7593419e3462 !br-7593419e3462  0.0.0.0/0            0.0.0.0/0
   15  4652 ACCEPT     all  --  br-7593419e3462 br-7593419e3462  0.0.0.0/0            0.0.0.0/0
    0     0 ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
    0     0 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
    0     0 ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
    0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain DOCKER (2 references)
 pkts bytes target     prot opt in     out     source               destination
    6   312 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.2           tcp dpt:9000
    8   416 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.3           tcp dpt:8200
    0     0 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.6           tcp dpt:9001
    0     0 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.6           tcp dpt:1883
    7   364 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.7           tcp dpt:8080

Chain DOCKER-ISOLATION-STAGE-1 (1 references)
 pkts bytes target     prot opt in     out     source               destination
43902   15M DOCKER-ISOLATION-STAGE-2  all  --  br-7593419e3462 !br-7593419e3462  0.0.0.0/0            0.0.0.0/0
    0     0 DOCKER-ISOLATION-STAGE-2  all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
 393K  919M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0

Chain DOCKER-ISOLATION-STAGE-2 (2 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 DROP       all  --  *      br-7593419e3462  0.0.0.0/0            0.0.0.0/0
    0     0 DROP       all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
43902   15M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0

Chain DOCKER-USER (1 references)
 pkts bytes target     prot opt in     out     source               destination
 393K  919M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
```

Tóm tắt các command cần làm, bởi vì chuyển từ `wlan0 sang eth0` nên các command sẽ như này:

```sh
# Chain DOCKER-USER
# drop any traffic TCP incoming interface eth0 on Docker from anywhere, except LAN
iptables -I DOCKER-USER -p tcp -i eth0 ! -s 192.168.1.0/24 -j DROP
# drop any traffic UDP incoming interface eth0 on Docker from anywhere, except LAN
iptables -I DOCKER-USER -p udp -i eth0 ! -s 192.168.1.0/24 -j DROP

# This open makes connection from Duplciati to S3 works
# accept traffic TCP incoming interface eth0 on Docker port XXX from anywhere
iptables -I DOCKER-USER -p tcp -i eth0 --match multiport --dport 33000:65535 -j ACCEPT

# This open makes these app works: Efootball24, PokemonGo, Duplicati
# accept traffic UDP incoming interface eth0 on Docker port XXX from anywhere
iptables -I DOCKER-USER -p udp -i eth0 --match multiport --dport 33000:65535 -j ACCEPT

iptables -I DOCKER-USER -p tcp -i eth0 --dport 80 -j ACCEPT
iptables -I DOCKER-USER -p tcp -i eth0 --dport 443 -j ACCEPT

# This open makes these app works: Wireguard
# accept traffic UDP incoming interface eth0 on Docker port 51820 from anywhere
iptables -I DOCKER-USER -p udp -i eth0 --dport 51820 -j ACCEPT


# Chain INPUT
# drop all traffic TCP incoming interface eth0 Chain INPUT from anywhere, except LAN
iptables -I INPUT -p tcp -i eth0 ! -s 192.168.1.0/24 -j DROP
# drop all traffic UDP incoming interface eth0 Chain INPUT from anywhere, except LAN
iptables -I INPUT -p udp -i eth0 ! -s 192.168.1.0/24 -j DROP

# This open makes HASS working normal
# accept traffic TCP incoming interface eth0 on Chain INPUT port XXX from anywhere
iptables -I INPUT -p tcp -i eth0 --match multiport --dport 22000:65535 -j ACCEPT

# This open HASS so you can access from Outside Internet
# accept traffic TCP incoming interface eth0 on Chain INPUT port XXX from anywhere
iptables -I INPUT -p tcp -i eth0 --dport 8123 -j ACCEPT
```

Confirm:

```
# sudo iptables -L -v -n | more

Chain INPUT (policy ACCEPT 4817 packets, 5058K bytes)
pkts bytes target     prot opt in     out     source               destination
  570 68108 ACCEPT     tcp  --  eth0   *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8123
  341  187K ACCEPT     tcp  --  eth0   *       0.0.0.0/0            0.0.0.0/0            multiport dports 22000:65535
  102 20012 DROP       udp  --  eth0   *      !192.168.1.0/24       0.0.0.0/0
  254 10256 DROP       tcp  --  eth0   *      !192.168.1.0/24       0.0.0.0/0

Chain DOCKER-USER (1 references)
pkts bytes target     prot opt in     out     source               destination
    0     0 ACCEPT     udp  --  eth0   *       0.0.0.0/0            0.0.0.0/0            udp dpt:51820
  20  1757 ACCEPT     tcp  --  eth0   *       0.0.0.0/0            0.0.0.0/0            tcp dpt:443
1227  162K ACCEPT     tcp  --  eth0   *       0.0.0.0/0            0.0.0.0/0            tcp dpt:80
  193 29556 ACCEPT     udp  --  eth0   *       0.0.0.0/0            0.0.0.0/0            multiport dports 33000:65535
  733 1729K ACCEPT     tcp  --  eth0   *       0.0.0.0/0            0.0.0.0/0            multiport dports 33000:65535
  40  4119 DROP       udp  --  eth0   *      !192.168.1.0/24       0.0.0.0/0
    0     0 DROP       tcp  --  eth0   *      !192.168.1.0/24       0.0.0.0/0
3632 5966K RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
```

Test lại bằng cách vào `https://canyouseeme.org/` rồi thử hết các port đang open xem nếu chỉ có port 8123 `Success` thì OK.

Sau khi reboot RPi sẽ thấy iptable lại bị reset, mất hết các rules vừa set, Nên cần save rule bằng command sau:  

```sh
sudo apt-get install iptables-persistent
sudo netfilter-persistent save
sudo netfilter-persistent reload
```

Thử reboot rồi vào check xem các iptables rule có bị mất ko? ko thì OK

# 7. Expose HASS to Internet

Sau khi tạo các rule trên iptables xong thì áp dụng bài [này](../../posts/encrypt-setup-home-assistant-on-raspberry-pi-p3-https) để expose HASS bằng swag

Đưa swag vào `docker-compose.yml`:

```sh
swag:
    image: lscr.io/linuxserver/swag:1.30.0
    container_name: swag
    cap_add:
      - NET_ADMIN
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Ho_Chi_Minh
      - URL=<MY_DOMAIN>.duckdns.org
      - VALIDATION=duckdns
      - SUBDOMAINS=wildcard #optional
      - CERTPROVIDER= #optional
      - DNSPLUGIN=duckdns #optional
      - PROPAGATION= #optional
      - DUCKDNSTOKEN=<DUCKDNS_TOKENNN> #optional
      - EMAIL=<MY_EMAIL@gmail.com> #optional
      - ONLY_SUBDOMAINS=true #optional
      - EXTRA_DOMAINS= #optional
      - STAGING=true #optional
    volumes:
      - /opt/swag/config:/config
    ports:
      - 443:443
    #   - 80:80 #optional
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "10"
```

- Lần này mình muốn tạo certificate cho all sub domains (wildcard luôn). Còn cái `XXX.duckdns.org` thì sẽ ko cần https valid. Nên chú ý chỗ `ONLY_SUBDOMAINS`

- `STAGING=true` để test trước.  

Sửa `/opt/swag/config/nginx/proxy-confs/homeassistant.subdomain.conf`:  

```
~~~
server_name hass.XXX.duckdns.org;
~~~
```

`docker-compose up -d` rồi Check log swag

Log phải như này, ko có ERROR mới OK:  

```
Variables set:
PUID=1000
PGID=1000
TZ=Asia/Ho_Chi_Minh
URL=<MY_DOMAIN>.duckdns.org
SUBDOMAINS=wildcard
EXTRA_DOMAINS=
ONLY_SUBDOMAINS=true
VALIDATION=duckdns
CERTPROVIDER=
DNSPLUGIN=duckdns
EMAIL=<MY_EMAIL>@gmail.com
STAGING=true

NOTICE: Staging is active
Using Let's Encrypt as the cert provider
SUBDOMAINS entered, processing
Wildcard cert for only the subdomains of <MY_DOMAIN>.duckdns.org will be requested
E-mail address entered: <MY_EMAIL>@gmail.com
duckdns validation is selected
the resulting certificate will only cover the subdomains due to a limitation of duckdns, so it is advised to set the root location to use www.subdomain.duckdns.org
Certificate exists; parameters unchanged; starting nginx
cont-init: info: /etc/cont-init.d/50-certbot exited 0
cont-init: info: running /etc/cont-init.d/55-permissions
cont-init: info: /etc/cont-init.d/55-permissions exited 0
cont-init: info: running /etc/cont-init.d/60-renew
The cert does not expire within the next day. Letting the cron script handle the renewal attempts overnight (2:08am).
cont-init: info: /etc/cont-init.d/60-renew exited 0
cont-init: info: running /etc/cont-init.d/70-outdated
/config/nginx/ldap.conf exists.
        Please apply any customizations to /config/nginx/ldap-server.conf
        Ensure your configs are updated and remove /config/nginx/ldap.conf
        If you do not use this config, simply remove it.
cont-init: info: /etc/cont-init.d/70-outdated exited 0
cont-init: info: running /etc/cont-init.d/85-version-checks
**** The following active confs have different version dates than the samples that are shipped. ****
**** This may be due to user customization or an update to the samples. ****
**** You should compare the following files to the samples in the same folder and update them. ****
**** Use the link at the top of the file to view the changelog. ****
/config/nginx/authelia-location.conf
/config/nginx/site-confs/default.conf
/config/nginx/proxy-confs/homeassistant.subdomain.conf
/config/nginx/proxy-confs/navidrome.subdomain.conf
/config/nginx/ssl.conf
/config/nginx/nginx.conf
/config/nginx/ldap-server.conf
/config/nginx/authelia-server.conf
/config/nginx/proxy.conf

cont-init: info: /etc/cont-init.d/85-version-checks exited 0
cont-init: info: running /etc/cont-init.d/99-custom-files
[custom-init] No custom files found, skipping...
cont-init: info: /etc/cont-init.d/99-custom-files exited 0
s6-rc: info: service legacy-cont-init successfully started
s6-rc: info: service init-mods: starting
s6-rc: info: service init-mods successfully started
s6-rc: info: service init-mods-package-install: starting
s6-rc: info: service init-mods-package-install successfully started
s6-rc: info: service init-mods-end: starting
s6-rc: info: service init-mods-end successfully started
s6-rc: info: service init-services: starting
s6-rc: info: service init-services successfully started
s6-rc: info: service legacy-services: starting
services-up: info: copying legacy longrun cron (no readiness notification)
services-up: info: copying legacy longrun fail2ban (no readiness notification)
services-up: info: copying legacy longrun nginx (no readiness notification)
services-up: info: copying legacy longrun php-fpm (no readiness notification)
s6-rc: info: service legacy-services successfully started
s6-rc: info: service 99-ci-service-check: starting
[ls.io-init] done.
s6-rc: info: service 99-ci-service-check successfully started
Server ready
```

Test thử trên điện thoại dùng 4G, vào endpoint: `https://hass.<MY_DOMAIN>.duckdns.org`, nếu vào đc màn hình login là OK (tất nhiên đang HTTPS not valid vì STAGING=true)

Sửa `docker-compose.yml`, `STAGING=false`, rồi `docker-compose up -d` rồi Check log swag như này là ok:

```
Variables set:
PUID=1000
PGID=1000
TZ=Asia/Ho_Chi_Minh
URL=<MY_DOMAIN>.duckdns.org
SUBDOMAINS=wildcard
EXTRA_DOMAINS=
ONLY_SUBDOMAINS=true
VALIDATION=duckdns
CERTPROVIDER=
DNSPLUGIN=duckdns
EMAIL=<MY_EMAIL>@gmail.com
STAGING=false

Using Let's Encrypt as the cert provider
SUBDOMAINS entered, processing
Wildcard cert for only the subdomains of <MY_DOMAIN>.duckdns.org will be requested
E-mail address entered: <MY_EMAIL>@gmail.com
duckdns validation is selected
the resulting certificate will only cover the subdomains due to a limitation of duckdns, so it is advised to set the root location to use www.subdomain.duckdns.org
Different validation parameters entered than what was used before. Revoking and deleting existing certificate, and an updated one will be created
Saving debug log to /var/log/letsencrypt/letsencrypt.log
No match found for cert-path /config/etc/letsencrypt/live/<MY_DOMAIN>.duckdns.org/fullchain.pem!
Ask for help or search for solutions at https://community.letsencrypt.org. See the logfile /var/log/letsencrypt/letsencrypt.log or re-run Certbot with -v for more details.
Generating new certificate
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Account registered.
Requesting a certificate for *.<MY_DOMAIN>.duckdns.org
Hook '--manual-auth-hook' for <MY_DOMAIN>.duckdns.org ran with output:
 OKsleeping 60
Hook '--manual-auth-hook' for <MY_DOMAIN>.duckdns.org ran with error output:
 % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                  Dload  Upload   Total   Spent    Left  Speed

   0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
   0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
   0     0    0     0    0     0      0      0 --:--:--  0:00:01 --:--:--     0
   0     0    0     0    0     0      0      0 --:--:--  0:00:02 --:--:--     0
   0     0    0     0    0     0      0      0 --:--:--  0:00:03 --:--:--     0
   0     0    0     0    0     0      0      0 --:--:--  0:00:04 --:--:--     0
   0     0    0     0    0     0      0      0 --:--:--  0:00:05 --:--:--     0
 100     2    0     2    0     0      0      0 --:--:--  0:00:05 --:--:--     0

Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/<MY_DOMAIN>.duckdns.org/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/<MY_DOMAIN>.duckdns.org/privkey.pem
This certificate expires on 2023-11-04.
These files will be updated when the certificate renews.
NEXT STEPS:
- The certificate will need to be renewed before it expires. Certbot can automatically renew the certificate in the background, but you may need to take steps to enable that functionality. See https://certbot.org/renewal-setup for instructions.

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
If you like Certbot, please consider supporting our work by:
 * Donating to ISRG / Let's Encrypt:   https://letsencrypt.org/donate
 * Donating to EFF:                    https://eff.org/donate-le
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
New certificate generated; starting nginx
cont-init: info: /etc/cont-init.d/50-certbot exited 0
cont-init: info: running /etc/cont-init.d/55-permissions
cont-init: info: /etc/cont-init.d/55-permissions exited 0
cont-init: info: running /etc/cont-init.d/60-renew
The cert does not expire within the next day. Letting the cron script handle the renewal attempts overnight (2:08am).
cont-init: info: /etc/cont-init.d/60-renew exited 0
cont-init: info: running /etc/cont-init.d/70-outdated
/config/nginx/ldap.conf exists.
        Please apply any customizations to /config/nginx/ldap-server.conf
        Ensure your configs are updated and remove /config/nginx/ldap.conf
        If you do not use this config, simply remove it.
cont-init: info: /etc/cont-init.d/70-outdated exited 0
cont-init: info: running /etc/cont-init.d/85-version-checks
**** The following active confs have different version dates than the samples that are shipped. ****
**** This may be due to user customization or an update to the samples. ****
**** You should compare the following files to the samples in the same folder and update them. ****
**** Use the link at the top of the file to view the changelog. ****
/config/nginx/authelia-location.conf
/config/nginx/site-confs/default.conf
/config/nginx/proxy-confs/homeassistant.subdomain.conf
/config/nginx/proxy-confs/navidrome.subdomain.conf
/config/nginx/ssl.conf
/config/nginx/nginx.conf
/config/nginx/ldap-server.conf
/config/nginx/authelia-server.conf
/config/nginx/proxy.conf

cont-init: info: /etc/cont-init.d/85-version-checks exited 0
cont-init: info: running /etc/cont-init.d/99-custom-files
[custom-init] No custom files found, skipping...
cont-init: info: /etc/cont-init.d/99-custom-files exited 0
s6-rc: info: service legacy-cont-init successfully started
s6-rc: info: service init-mods: starting
s6-rc: info: service init-mods successfully started
s6-rc: info: service init-mods-package-install: starting
s6-rc: info: service init-mods-package-install successfully started
s6-rc: info: service init-mods-end: starting
s6-rc: info: service init-mods-end successfully started
s6-rc: info: service init-services: starting
s6-rc: info: service init-services successfully started
s6-rc: info: service legacy-services: starting
services-up: info: copying legacy longrun cron (no readiness notification)
services-up: info: copying legacy longrun fail2ban (no readiness notification)
services-up: info: copying legacy longrun nginx (no readiness notification)
services-up: info: copying legacy longrun php-fpm (no readiness notification)
s6-rc: info: service legacy-services successfully started
s6-rc: info: service 99-ci-service-check: starting
[ls.io-init] done.
s6-rc: info: service 99-ci-service-check successfully started
Server ready
```

Test thử trên điện thoại dùng 4G, vào endpoint: `https://hass.<MY_DOMAIN>.duckdns.org`, nếu vào đc màn hình login là OK. Thấy HTTPS VALID là được. (Cái này dùng cho Alexa)

Test thử trên điện thoại dùng 4G, vào endpoint: `http://hass.<MY_DOMAIN>.duckdns.org:8123`, nếu vào đc màn hình login là OK. (Cái này dùng cho Alexa - AWS Lambda function `homeassistant-alexa`)

Test thử trong mạng LAN ở nhà, vào endpoint: `http://hass.<MY_DOMAIN>.duckdns.org:8123`, nếu vào đc màn hình login là OK. (Cái này dùng cho app trên điện thoại, để cả Wifi ở nhà và 4G đều vào được)

# 8. Setup lại Amazon Alexa endpoint nếu đang expose lại swag certificate for all subdomains

Đọc lại bài [này](../encrypt-connect-home-assistant-to-alexa-echo-dot4) về Alexa và các skil để check lại chỗ nào cần reconfigure

Vào AWS Lambda, function `homeassistant-alexa`, sửa environment variable `BASE_URL` vì giờ url đã là `http://hass.<MY_DOMAIN>.duckdns.org:8123`

Tạo LongLiveToken để test, config Lamda event test, thay thế LongLiveToken vào, test thấy trả về 1 đống data là OK. Delete đi LongLiveToken đi được rồi.

Vào page `https://developer.amazon.com/alexa`, chọn skill HASS của mình, -> `Account Linking`, sửa đường dẫn mới đến HASS của mình. Save.

Trên điện thoại bật 4G, vào `Your Skills` -> Skill HASS của mình, disable rồi enable lại -> Login vào HASS của mình với account chính chủ.

Test thử các skill xem nếu hoạt động tốt như bình thường, tắt/bật đèn, Youtube, NCT, Lunar Calendar... là OK.

# 9. Setup lại các crontab

```
0 10,16,22 * * * python -W ignore::DeprecationWarning /opt/devops/ethanglong-lab/schedule-scrape-ethanglong-selenium.py >> /opt/devops/logs/schedule-scrape-ethanglong.log 2>&1
*/3 * * * * bash /opt/devops/oracle-rm-lab/create-vm-oracle-sg.sh
*/5 * * * * bash /opt/devops/oracle-rm-lab/start-vm-oracle-london.sh
```

Sẽ cần đọc lại bài này để chạy được script selenium: [Play around selenium](../encrypt-play-around-w-selenium/#2-workspace-2-raspberry-pi-4b-8g-raspion-os-lite-without-desktop)

Riêng các script oracle cần cài thêm oci-cli:

```sh
python3 -m pip install oci-cli
```

Sẽ cần đọc lại bài này để chạy được các scripts liên quan Oracle: [Oracle scripts](../encrypt-oracle-oci-cli-script/)

# 10. Install htpdate

Có khả năng sau khi chặn các port bằng iptable, sau này sẽ bị lỗi này (ko sync datetime được):  
https://hoangmnsd.github.io/bk/encrypt-setup-home-assistant-on-raspberry-pi-and-addons/#126-troubeshoot-data-display-thi%E1%BA%BFu

Thế nên cần install:

```sh
sudo apt-get install htpdate

sudo htpdate -a google.com

service htpdate status
```