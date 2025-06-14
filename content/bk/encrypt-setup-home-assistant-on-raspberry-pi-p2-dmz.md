---
title: "Setup Home Assistant on Raspberry Pi (Part 2) - iptables rule and DMZ"
date: 2022-05-15T18:34:01+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [RaspberryPi,HomeAssistant,Iptables]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Bài thứ 2 trong series về Setup HASS trên RPi"
---

Đây là phần cố gắng giải quyết vấn đề khi mình làm cái này:
[9. Install DuckDNS (for expose outside access purpose)](../../posts/encrypt-setup-home-assistant-on-raspberry-pi-and-addons/#9-install-duckdns-for-expose-outside-access-purpose)

Tóm tắt tình huống của mình: Có 1 RPi, chạy HASS trên docker. DÙng mạng VNPT, ko thể `Port Forwarding` được port 443 (do router đã reserve port 443, 80).  
-> Phải dùng chức năng `DMZ` - cho RPi vào DMZ, nhưng chức năng này lại mở all port (bao gồm cả 443) trên con RPi (risk về security)  
-> Phải tìm cách để hạn chế traffic từ Internet vào DMZ (chỉ cho traffic đi vào port 80,443 và 1 số port cần thiết thôi)

-> Mình tìm được cách: Dùng `iptables` command, tạo các rule trên chính con RPi (ko cho nó nhận traffic từ bên ngoài Internet vào 1 số port)

# 1. Check xem RPi đang nói chuyện với Internet bằng interface nào
```sh
root@raspian-rpi:/opt/hass# ifconfig
br-564d64d5a58a: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.18.0.1  netmask 255.255.0.0  broadcast 172.18.255.255
        inet6 fexxxxxxxxxxxx8b  prefixlen 64  scopeid 0x20<link>
        ether 0xxxxxxxxxxxx:8b  txqueuelen 0  (Ethernet)
        RX packets 9724621  bytes 14542091134 (13.5 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 9678446  bytes 14944508794 (13.9 GiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

docker0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 172.17.0.1  netmask 255.255.0.0  broadcast 172.17.255.255
        inet6 fxxxxxxxxxxxxxbb  prefixlen 64  scopeid 0x20<link>
        ether 0xxxxxxxxxxxxbb  txqueuelen 0  (Ethernet)
        RX packets 187  bytes 24270 (23.7 KiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 207  bytes 27492 (26.8 KiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

eth0: flags=4099<UP,BROADCAST,MULTICAST>  mtu 1500
        ether exxxxxxxxxxx6  txqueuelen 1000  (Ethernet)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 1801769  bytes 441955165 (421.4 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 1801769  bytes 441955165 (421.4 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

wlan0: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.1.128  netmask 255.255.255.0  broadcast 192.168.1.255
        inet6 fxxxxxxxxxxxxxxx36  prefixlen 64  scopeid 0x20<link>
        ether exxxxxxxxxxxxx97  txqueuelen 1000  (Ethernet)
        RX packets 5982425  bytes 2708750541 (2.5 GiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 7859191  bytes 1834756180 (1.7 GiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```
Trong nhiều trường hợp, nếu server của bạn cắm dây LAN đến Router để vào mạng thì có nghĩa là nó dùng `eth0`.

Nhưng vì RPi của mình dùng Wifi để vào mạng -> nên cái nó đang dùng phải là `wlan0` -> Để confirm thì Bạn sẽ thấy lượng package/traffic đi ra vào `wlan0` khá nhiều (`RX packets 5982425  bytes 2708750541 (2.5 GiB)`)

Vậy là xác định được interface là `wlan0`

# 2. Check các rule đã tồn tại trong `iptables`

```sh
sudo iptables -L -v -n | more
Chain INPUT (policy ACCEPT 635K packets, 705M bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain FORWARD (policy ACCEPT 4921 packets, 2451K bytes)
 pkts bytes target     prot opt in     out     source               destination
 279K  149M DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
 279K  149M DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    0     0 ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
    0     0 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
    0     0 ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
    0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
 152K   85M ACCEPT     all  --  *      br-564d64d5a58a  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
  634  122K DOCKER     all  --  *      br-564d64d5a58a  0.0.0.0/0            0.0.0.0/0
 126K   64M ACCEPT     all  --  br-564d64d5a58a !br-564d64d5a58a  0.0.0.0/0            0.0.0.0/0
  489  114K ACCEPT     all  --  br-564d64d5a58a br-564d64d5a58a  0.0.0.0/0            0.0.0.0/0

Chain OUTPUT (policy ACCEPT 673K packets, 687M bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain DOCKER (2 references)
 pkts bytes target     prot opt in     out     source               destination
   20  1128 ACCEPT     tcp  --  !br-564d64d5a58a br-564d64d5a58a  0.0.0.0/0            172.18.0.2           tcp dpt:9000
    6   312 ACCEPT     tcp  --  !br-564d64d5a58a br-564d64d5a58a  0.0.0.0/0            172.18.0.4           tcp dpt:8200
    1    40 ACCEPT     tcp  --  !br-564d64d5a58a br-564d64d5a58a  0.0.0.0/0            172.18.0.5           tcp dpt:9001
    0     0 ACCEPT     tcp  --  !br-564d64d5a58a br-564d64d5a58a  0.0.0.0/0            172.18.0.5           tcp dpt:1883
    0     0 ACCEPT     tcp  --  !br-564d64d5a58a br-564d64d5a58a  0.0.0.0/0            172.18.0.6           tcp dpt:9090
   11   564 ACCEPT     tcp  --  !br-564d64d5a58a br-564d64d5a58a  0.0.0.0/0            172.18.0.9           tcp dpt:8080
    0     0 ACCEPT     udp  --  !br-564d64d5a58a br-564d64d5a58a  0.0.0.0/0            172.18.0.10          udp dpt:51820
    0     0 ACCEPT     tcp  --  !docker0 docker0  0.0.0.0/0            172.17.0.2           tcp dpt:4444
   39  2180 ACCEPT     tcp  --  !br-564d64d5a58a br-564d64d5a58a  0.0.0.0/0            172.18.0.7           tcp dpt:3000

Chain DOCKER-ISOLATION-STAGE-1 (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 DOCKER-ISOLATION-STAGE-2  all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
 126K   64M DOCKER-ISOLATION-STAGE-2  all  --  br-564d64d5a58a !br-564d64d5a58a  0.0.0.0/0            0.0.0.0/0
 279K  149M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0

Chain DOCKER-ISOLATION-STAGE-2 (2 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 DROP       all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
    0     0 DROP       all  --  *      br-564d64d5a58a  0.0.0.0/0            0.0.0.0/0
 126K   64M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0

Chain DOCKER-USER (1 references)
 pkts bytes target     prot opt in     out     source               destination
 279K  149M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
```
Chú ý vào `Chain DOCKER`, cho thấy hiện đang mở khá nhiều port:
```
tcp dpt:9000
tcp dpt:8200
tcp dpt:9001
tcp dpt:1883
tcp dpt:9090
tcp dpt:8080
udp dpt:51820
tcp dpt:3000
```
nhưng ko có port 8123 trong list này (Chỗ này bởi vì HASS ko expose port 8123 từ Docker ra ngoài nên bạn sẽ ko thấy nó trong `Chain DOCKER`)
```
docker ps
CONTAINER ID   IMAGE                                            COMMAND                  CREATED        STATUS        PORTS                                                                                  NAMES
228ccfed3015   grafana/grafana:8.5.5                            "/run.sh"                6 hours ago    Up 6 hours    0.0.0.0:3000->3000/tcp, :::3000->3000/tcp                                              grafana
105c497b8114   ghcr.io/home-assistant/home-assistant:2022.8.2   "/init"                  24 hours ago   Up 24 hours                                                                                          homeassistant
45f43bcdae93   prom/prometheus:v2.36.0                          "/bin/prometheus --c…"   6 weeks ago    Up 24 hours   0.0.0.0:9090->9090/tcp, :::9090->9090/tcp                                              prometheus
324fd3e2ce26   portainer/portainer-ce:2.13.1                    "/portainer"             2 months ago   Up 24 hours   8000/tcp, 9443/tcp, 0.0.0.0:9000->9000/tcp, :::9000->9000/tcp                          portainer
2d80eee17aaf   prom/node-exporter:v1.3.1                        "/bin/node_exporter"     3 months ago   Up 24 hours   9100/tcp                                                                               monitoring_node_exporter
7c56755c52fe   koenkk/zigbee2mqtt:1.25.0                        "docker-entrypoint.s…"   3 months ago   Up 24 hours   0.0.0.0:8080->8080/tcp, :::8080->8080/tcp                                              zigbee2mqtt
b00bc6092048   lscr.io/linuxserver/wireguard:1.0.20210914       "/init"                  3 months ago   Up 24 hours   0.0.0.0:51820->51820/udp, :::51820->51820/udp                                          wireguard
ebfecd7ed0b4   lscr.io/linuxserver/duckdns:68a3222a-ls97        "/init"                  3 months ago   Up 24 hours                                                                                          duckdns
ae09a218d43f   eclipse-mosquitto:2.0.14                         "/docker-entrypoint.…"   3 months ago   Up 24 hours   0.0.0.0:1883->1883/tcp, :::1883->1883/tcp, 0.0.0.0:9001->9001/tcp, :::9001->9001/tcp   mosquitto
413fcaac7b9a   lscr.io/linuxserver/duplicati:2.0.6              "/init"                  3 months ago   Up 24 hours   0.0.0.0:8200->8200/tcp, :::8200->8200/tcp                                              duplicati
```

Giờ cần chú ý vào `Chain DOCKER-USER`, hiện đang chỉ có 1 rule RETURN, ko cần quan tâm, như vậy coi như ko có rule nào.
Đây chính là nơi mà các bạn sẽ add rule vào, để hạn chế traffic đi vào các port trong Docker của bạn.

# 3. Dùng iptables để filter các traffic

## 3.1. Drop all traffic đi vào Chain DOCKER-USER trước, rồi allow từng port một sau

Đầu tiên hãy test để chắc chắn đang làm đúng:  
Từ mạng 4G -> port 3000, 9000, 8123 -> access được hết.  
Tất nhiên rồi, bởi vì chúng ta chưa add rule nào mà.

Giờ add 1 rule để DROP tất cả traffic đến Docker ngoại trừ mạng LAN `192.168.1.0/24`:  
**Chú ý thứ tự rất quan trọng, câu lệnh này phải run trước khi chạy các câu lệnh add rule khác**
```sh
# drop any traffic TCP incoming interface wlan0 from anywhere, except LAN
iptables -I DOCKER-USER -p tcp -i wlan0 ! -s 192.168.1.0/24 -j DROP
```
Test:  
Từ mạng local -> port 8123, 3000, 9000, 8200 -> access được.
Từ mạng 4G -> port 8123 -> access được.  
Từ mạng 4G -> port 3000, 9000, 8200, 8080 -> ko access được.  
Port 3000,9000,8200,8080 ở trong `Chain DOCKER` nên nó chịu ảnh hưởng bởi rule trên. Còn port 8123 thì ko, nên bạn vẫn access được.
HASS các hoạt động: ko có lỗi đặc biệt.   
Test Duplicati connection to S3: Lỗi luôn ❌  

Có lẽ là Duplicati khi test connection to S3 nó cần TCP incoming traffic 😁  
Ko hiểu vì sao? 

Tìm thấy 1 post ko ai trả lời:  
https://stackoverflow.com/questions/71763830/what-ports-are-required-to-open-for-aws-s3-to-work
Thử accept port 443:
```sh
# accept traffic TCP incoming interface wlan0 on Docker port 443 from anywhere
iptables -I DOCKER-USER -p tcp -i wlan0 --dport 443 -j ACCEPT
```
Test lại Duplicati connection to S3: Vẫn lỗi❌

Thử accept port 80:
```sh
# accept traffic TCP incoming interface wlan0 on Docker port 80 from anywhere
iptables -I DOCKER-USER -p tcp -i wlan0 --dport 80 -j ACCEPT
```
Test lại Duplicati connection to S3: Vẫn lỗi❌

Thử accept port 55000-and 65535: 
```sh
# accept traffic TCP incoming interface wlan0 on Docker port XXX from anywhere
iptables -I DOCKER-USER -p tcp -i wlan0 --match multiport --dport 55000:65535 -j ACCEPT
```
Test lại Duplicati connection to S3: Vẫn lỗi❌- nhưng log lỗi có vẻ ngắn hơn: `A WebException with status Timeout was thrown`  
```
[services.d] done.
Amazon.Runtime.AmazonServiceException: A WebException with status Timeout was thrown. ---> System.Net.WebException: The operation has timed out.
  at System.Net.HttpWebRequest.GetRequestStream () [0x00016] in <9c6e2cb7ddd8473fa420642ddcf7ce48>:0 
  at Amazon.Runtime.Internal.HttpRequest.GetRequestContent () [0x00000] in <e28e89f25c1649a69062a2c53f89d718>:0 
  at Amazon.Runtime.Internal.HttpHandler`1[TRequestContent].InvokeSync (Amazon.Runtime.IExecutionContext executionContext) [0x0006b] in <e28e89f25c1649a69062a2c53f89d718>:0 
  at Amazon.Runtime.Internal.PipelineHandler.InvokeSync (Amazon.Runtime.IExecutionContext executionContext) [0x0000e] in <e28e89f25c1649a69062a2c53f89d718>:0 
  at Amazon.Runtime.Internal.Unmarshaller.InvokeSync (Amazon.Runtime.IExecutionContext executionContext) [0x00000] in <e28e89f25c1649a69062a2c53f89d718>:0 
  at Amazon.Runtime.Internal.PipelineHandler.InvokeSync (Amazon.Runtime.IExecutionContext executionContext) [0x0000e] in <e28e89f25c1649a69062a2c53f89d718>:0 
  at Amazon.Runtime.Internal.ErrorHandler.InvokeSync (Amazon.Runtime.IExecutionContext executionContext) [0x00000] in <e28e89f25c1649a69062a2c53f89d718>:0 
   --- End of inner exception stack trace ---
```

```sh
sudo iptables -L -v -n | more
Chain DOCKER-USER (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 ACCEPT     tcp  --  wlan0  *       0.0.0.0/0            0.0.0.0/0            tcp dpt:443
    0     0 ACCEPT     tcp  --  wlan0  *       0.0.0.0/0            0.0.0.0/0            tcp dpt:80
  113  110K ACCEPT  tcp  --  wlan0  *       0.0.0.0/0            0.0.0.0/0            multiport dports 55000:65535
   81  4596 DROP    tcp  --  wlan0  *      !192.168.1.0/24       0.0.0.0/0
1006K  976M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
```

Nhìn thấy 2 rule `tcp dpt:443` và `tcp dpt:80` ko thấy có traffic gì (cột `pkts, bytes`) chứng tỏ vô nghĩa khi thêm vào. Chủ yếu là rule `multiport dports 55000:65535` cần thiết thôi.


Quyết định debug đến cùng để ra vấn đề:  
https://stackoverflow.com/questions/21771684/iptables-log-and-drop-in-one-rule

Let's create a chain to log and accept:
```sh
iptables -N LOG_ACCEPT
```
And let's populate its rules:
```sh
iptables -A LOG_ACCEPT -j LOG --log-prefix "INPUT:ACCEPT:" --log-level 6
iptables -A LOG_ACCEPT -j ACCEPT
```
Now let's create a chain to log and drop:
```sh
iptables -N LOG_DROP
```
And let's populate its rules:
```sh
iptables -A LOG_DROP -j LOG --log-prefix "INPUT:DROP: " --log-level 6
iptables -A LOG_DROP -j DROP
```

Now you can do all actions in one go by jumping (-j) to you custom chains instead of the default LOG / ACCEPT / REJECT / DROP:

```sh
# drop any traffic TCP incoming interface wlan0 from anywhere, except LAN, log result to LOG_DROP
iptables -I DOCKER-USER -p tcp -i wlan0 ! -s 192.168.1.0/24 -j LOG_DROP

# accept traffic TCP incoming interface wlan0 on Docker port XXX from anywhere, log result to LOG_ACCEPT
iptables -I DOCKER-USER -p tcp -i wlan0 --match multiport --dport 55000:65535 -j LOG_ACCEPT
```

Sẽ được cái output như này, chú ý đúng thứ tự là ok:
```
sudo iptables -L -v -n | more
Chain DOCKER-USER (1 references)
 pkts bytes target     prot opt in     out     source               destination
  113  110K LOG_ACCEPT  tcp  --  wlan0  *       0.0.0.0/0            0.0.0.0/0            multiport dports 55000:65535
   81  4596 LOG_DROP   tcp  --  wlan0  *      !192.168.1.0/24       0.0.0.0/0
1006K  976M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0

Chain LOG_ACCEPT (1 references)
 pkts bytes target     prot opt in     out     source               destination
  113  110K LOG        all  --  *      *       0.0.0.0/0            0.0.0.0/0            LOG flags 0 level 6 prefix "INPUT:ACCEPT:"
  113  110K ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0

Chain LOG_DROP (1 references)
 pkts bytes target     prot opt in     out     source               destination
   81  4596 LOG        all  --  *      *       0.0.0.0/0            0.0.0.0/0            LOG flags 0 level 6 prefix "INPUT:DROP: "
   81  4596 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0
```
Test: 
Duplicati - Test connection to AWS S3.   
Cùng lúc đó, vào log check: `tail -200f /var/log/messages | grep "DST=172.18.0.4"`, (172.18.0.4 là IP của container duplicati) bạn sẽ thấy có rất nhiều package ACCEPT/DROP đã được log lại:  

Được Accept:

```
Sep 16 23:43:48 raspian-rpi kernel: [1598976.871464] INPUT:ACCEPT:IN=wlan0 OUT=br-564d64d5a58a MAC=e4:5f:01:3d:a3:97:d0:96:fb:99:7f:2f:08:00 SRC=139.59.135.67 DST=172.18.0.4 LEN=60 TOS=0x00 PREC=0x20 TTL=51 ID=0 DF PROTO=TCP SPT=443 DPT=58882 WINDOW=65160 RES=0x00 ACK SYN URGP=0
Sep 16 23:43:48 raspian-rpi kernel: [1598977.137601] INPUT:ACCEPT:IN=wlan0 OUT=br-564d64d5a58a MAC=e4:5f:01:3d:a3:97:d0:96:fb:99:7f:2f:08:00 SRC=139.59.135.67 DST=172.18.0.4 LEN=52 TOS=0x00 PREC=0x20 TTL=51 ID=12226 DF PROTO=TCP SPT=443 DPT=58882 WINDOW=508 RES=0x00 ACK URGP=0
Sep 16 23:43:48 raspian-rpi kernel: [1598977.141156] INPUT:ACCEPT:IN=wlan0 OUT=br-564d64d5a58a MAC=e4:5f:01:3d:a3:97:d0:96:fb:99:7f:2f:08:00 SRC=139.59.135.67 DST=172.18.0.4 LEN=1492 TOS=0x00 PREC=0x20 TTL=51 ID=12227 DF PROTO=TCP SPT=443 DPT=58882 WINDOW=508 RES=0x00 ACK URGP=0
Sep 16 23:43:48 raspian-rpi kernel: [1598977.141322] INPUT:ACCEPT:IN=wlan0 OUT=br-564d64d5a58a MAC=e4:5f:01:3d:a3:97:d0:96:fb:99:7f:2f:08:00 SRC=139.59.135.67 DST=172.18.0.4 LEN=1492 TOS=0x00 PREC=0x20 TTL=51 ID=12228 DF PROTO=TCP SPT=443 DPT=58882 WINDOW=508 RES=0x00 ACK PSH URGP=0
```

Bị drop:  

```
Sep 16 23:48:06 raspian-rpi kernel: [1599234.486899] INPUT:DROP: IN=wlan0 OUT=br-564d64d5a58a MAC=e4:5f:01:3d:a3:97:d0:96:fb:99:7f:2f:08:00 SRC=52.119.198.223 DST=172.18.0.4 LEN=52 TOS=0x00 PREC=0x20 TTL=238 ID=51533 DF PROTO=TCP SPT=443 DPT=53954 WINDOW=8190 RES=0x00 ACK SYN URGP=0
Sep 16 23:48:20 raspian-rpi kernel: [1599248.485699] INPUT:DROP: IN=wlan0 OUT=br-564d64d5a58a MAC=e4:5f:01:3d:a3:97:d0:96:fb:99:7f:2f:08:00 SRC=52.219.36.104 DST=172.18.0.4 LEN=52 TOS=0x00 PREC=0x20 TTL=239 ID=27892 PROTO=TCP SPT=80 DPT=51988 WINDOW=64240 RES=0x00 ACK SYN URGP=0
```

Đến đây thì có vẻ dần hiểu ra vấn đề, open port `55000:65535` là chưa đủ cho Duplicati call api của AWS S3 SDK.  
Lần theo LOG thì mình thấy `DPT=33234` có vẻ là số nhỏ nhất trong số các port bị DROP.  
Thế nên mình sẽ allow port từ `33000:65535` để test lại connection.  

```sh
# drop any traffic TCP incoming interface wlan0 from anywhere, except LAN
iptables -I DOCKER-USER -p tcp -i wlan0 ! -s 192.168.1.0/24 -j DROP

# accept traffic TCP incoming interface wlan0 on Docker port XXX from anywhere
iptables -I DOCKER-USER -p tcp -i wlan0 --match multiport --dport 33000:65535 -j ACCEPT
```

như này là ok:  

```
sudo iptables -L -v -n | more
Chain DOCKER-USER (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 ACCEPT     tcp  --  wlan0  *       0.0.0.0/0            0.0.0.0/0            multiport dports 33000:65535
    0     0 DROP       tcp  --  wlan0  *      !192.168.1.0/24       0.0.0.0/0
1202K 1060M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
```
Test lại Duplicati connection to S3: worked 👌 -> vậy là ngon rồi

Check lại có bao nhiêu `pkts/bytes` bị DROP trong khi test, thì mình thấy 0 `pkts,bytes` -> rất tốt 😁
```
sudo iptables -L -v -n | more
Chain DOCKER-USER (1 references)
 pkts bytes target     prot opt in     out     source               destination
   93 74599 ACCEPT     tcp  --  wlan0  *       0.0.0.0/0            0.0.0.0/0            multiport dports 33000:65535
    0     0 DROP       tcp  --  wlan0  *      !192.168.1.0/24       0.0.0.0/0
1203K 1060M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
```

Check hoạt động của HASS: Log ko có lỗi đặc biệt.

Restart HASS, check lại có 1 package 40 bytes bị drop:
```
Chain DOCKER-USER (1 references)
 pkts bytes target     prot opt in     out     source               destination
  339  172K ACCEPT     tcp  --  wlan0  *       0.0.0.0/0            0.0.0.0/0            multiport dports 33000:65535
    1    40 DROP       tcp  --  wlan0  *      !192.168.1.0/24       0.0.0.0/0
1211K 1064M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
```

Sau khi theo dõi 1 thời gian thì mình đã bắt dc package bị DROP trong `/var/log/messages` đó:  

```
tail -100f /var/log/messages

Sep 17 16:27:56 raspian-rpi kernel: [1659225.415084] INPUT:DROP: IN=wlan0 OUT=br-564d64d5a58a MAC=e4:5f:01:3d:a3:97:d0:96:fb:99:7f:2f:08:00 SRC=80.94.92.239 DST=172.18.0.9 LEN=40 TOS=0x00 PREC=0x20 TTL=239 ID=54321 PROTO=TCP SPT=37396 DPT=8080 WINDOW=65535 RES=0x00 SYN URGP=0
Sep 17 16:58:12 raspian-rpi kernel: [1661041.646975] INPUT:DROP: IN=wlan0 OUT=br-564d64d5a58a MAC=e4:5f:01:3d:a3:97:d0:96:fb:99:7f:2f:08:00 SRC=59.153.245.143 DST=172.18.0.4 LEN=60 TOS=0x00 PREC=0x00 TTL=47 ID=3383 DF PROTO=TCP SPT=13887 DPT=8200 WINDOW=65535 RES=0x00 SYN URGP=0
Sep 17 17:13:35 raspian-rpi kernel: [1661964.791511] INPUT:DROP: IN=wlan0 OUT=br-564d64d5a58a MAC=e4:5f:01:3d:a3:97:d0:96:fb:99:7f:2f:08:00 SRC=89.248.165.199 DST=172.18.0.5 LEN=40 TOS=0x00 PREC=0x20 TTL=245 ID=48797 PROTO=TCP SPT=47266 DPT=9001 WINDOW=1024 RES=0x00 SYN URGP=0
```
Nó đi đến port 8080 của `zigbee2mqtt` container, 9001 của `mosquitto` và 8200 của `duplicati`. Ngoài ra ko thấy lỗi gì trên HASS khi hoạt động -> cho qua và theo dõi tiếp..

---

Tiếp theo thử add 1 rule để ACCEPT traffic từ anywhere đến port 3000,  
(Trong trường hợp bạn có thêm 1 app nào đó muốn expose ra Internet, giả sử port 3000):  

```sh
# accept traffic TCP incoming interface wlan0 on Docker port 3000 from anywhere
iptables -I DOCKER-USER -p tcp -i wlan0 --dport 3000 -j ACCEPT
```

Test:  
Từ mạng 4G -> port 3000, 8123 -> access được. (port 3000 bị ảnh hưởng bởi rule vừa xong, port 8123 thì ko bị ảnh hưởng do nó ko dc expose bởi DOCKER).   
Từ mạng 4G -> port 9000,8200,8080 -> ko access được.  
Vậy là đúng ý rồi.  

Chú ý thứ tự rất quan trọng (bảng dưới đây chỉ ra rule DROP all traffic đang nằm áp chót mới được nhé):  

```
sudo iptables -L -v -n | more
....
Chain DOCKER-USER (1 references)
 pkts bytes target     prot opt in     out     source               destination
 6472  356K ACCEPT     tcp  --  wlan0  *       0.0.0.0/0            0.0.0.0/0            tcp dpt:3000
 93 74599   ACCEPT     tcp  --  wlan0  *       0.0.0.0/0            0.0.0.0/0            multiport dports 33000:65535
 2022  494K DROP       tcp  --  wlan0  *      !192.168.1.0/24       0.0.0.0/0
 358K  192M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
```

Nếu muốn remove 1 rule nào đó - chỉ cần thay chữ `-I` bằng chữ `-D` là OK, rule đó sẽ bị xóa, ví dụ:

```sh
# add rule
iptables -I DOCKER-USER -p tcp -i wlan0 --dport 3000 -j ACCEPT
# remove rule
iptables -D DOCKER-USER -p tcp -i wlan0 --dport 3000 -j ACCEPT
```

Tổng kết các rule mình sử dụng trong phần này:  

```sh
# drop any traffic TCP incoming interface wlan0 from anywhere, except LAN
iptables -I DOCKER-USER -p tcp -i wlan0 ! -s 192.168.1.0/24 -j DROP

# accept traffic TCP incoming interface wlan0 on Docker port XXX from anywhere
iptables -I DOCKER-USER -p tcp -i wlan0 --match multiport --dport 33000:65535 -j ACCEPT
```

Giờ sẽ tiếp tục xử lý đến port 8123 và `Chain INPUT`  

## 3.2. Drop all traffic đi vào Chain INPUT, rồi allow từng port một sau

trước tiên để tránh làm HASS bị crash, thì nên stop HASS container trước. (hoặc stop cái Automation send error to Telegram).

Sau đó:

```sh
# drop all traffic TCP incoming interface wlan0 Chain INPUT, except LAN, log to LOG_DROP
iptables -I INPUT -p tcp -i wlan0 ! -s 192.168.1.0/24 -j LOG_DROP

sudo iptables -L -v -n | more
Chain INPUT (policy ACCEPT 2663K packets, 2572M bytes)
 pkts bytes target     prot opt in     out     source               destination
    2    88 LOG_DROP       tcp  --  wlan0  *      !192.168.1.0/24       0.0.0.0/0
```

Trong LOG_DROP sẽ thấy rất nhiều port bị DROP từ khoảng 22000-65535

Trong HASS sẽ thấy 1 số lỗi:

```
telegram.error.NetworkError: urllib3 HTTPError HTTPSConnectionPool(host='api.telegram.org', port=443): Max retries exceeded with url: /bot/getMe (Caused by NewConnectionError('<telegram.vendor.ptb_urllib3.urllib3.connection.VerifiedHTTPSConnection object at 0x7f8f6c9f90>: Failed to establish a new connection: [Errno 101] Network unreachable'))

requests.exceptions.ConnectTimeout: HTTPSConnectionPool(host='route.lgthinq.com', port=46030): Max retries exceeded with url: /v1/service/application/gateway-uri (Caused by ConnectTimeoutError(<urllib3.connection.HTTPSConnection object at 0x7f9a880310>, 'Connection to route.lgthinq.com timed out. (connect timeout=10)'))
2022-09-17 18:07:42.403 ERROR (MainThread) [homeassistant] Error doing job: Future exception was never retrieved

requests.exceptions.ConnectionError: HTTPSConnectionPool(host='route.lgthinq.com', port=46030): Max retries exceeded with url: /v1/service/application/gateway-uri (Caused by NewConnectionError('<urllib3.connection.HTTPSConnection object at 0x7f88286320>: Failed to establish a new connection: [Errno -3] Try again'))
2022-09-17 18:02:30.066 ERROR (MainThread) [metno] Access to https://aa015h6buqvih86i1.api.met.no/weatherapi/locationforecast/2.0/complete returned error 'ClientConnectorError'
2022-09-17 18:02:30.553 ERROR (MainThread) [custom_components.hacs] Request exception for 'https://api.github.com/rate_limit' with - Cannot connect to host api.github.com:443 ssl:default [Try again]
Traceback (most recent call last):
  File "/config/custom_components/hacs/base.py", line 451, in async_can_update
    response = await self.async_github_api_method(self.githubapi.rate_limit)
  File "/config/custom_components/hacs/base.py", line 505, in async_github_api_method
    raise HacsException(_exception)
    
custom_components.hacs.exceptions.HacsException: Request exception for 'https://api.github.com/rate_limit' with - Cannot connect to host api.github.com:443 ssl:default [Try again]
2022-09-17 18:02:55.077 WARNING (MainThread) [custom_components.smartthinq_sensors] Connection not available. ThinQ platform not ready

2022-09-17 18:02:30.066 ERROR (MainThread) [metno] Access to https://aa015h6buqvih86i1.api.met.no/weatherapi/locationforecast/2.0/complete returned error 'ClientConnectorError'
2022-09-17 18:02:30.553 ERROR (MainThread) [custom_components.hacs] Request exception for 'https://api.github.com/rate_limit' with - Cannot connect to host api.github.com:443 ssl:default [Try again]
Traceback (most recent call last):
  File "/config/custom_components/hacs/base.py", line 451, in async_can_update
    response = await self.async_github_api_method(self.githubapi.rate_limit)
  File "/config/custom_components/hacs/base.py", line 505, in async_github_api_method
    raise HacsException(_exception)
```

Quá trình bị lỗi này tạo ra nhiều file rác trong `/var/log/journal/*` nên xóa đi bớt, hoặc setting cho nó chỉ chứa tối đa 200M trong đó thôi (Làm theo bài này: https://unix.stackexchange.com/questions/130786/can-i-remove-files-in-var-log-journal-and-var-cache-abrt-di-usr)
test app Duplicati, chưa kịp test thì bị server bị treo/đơ luôn,    
HASS lại bị restart, full CPU, ko check dc nữa.  
Log của HASS có lỗi liên quan đến call api weather ra ngoài ko nổi.  
Cuối cùng phải đợi vào đc Portainer UI, stop `homeassistant` container.  

thế nên phải add thêm:

```sh
# accept traffic TCP incoming interface wlan0 on Chain INPUT port XXX from anywhere
iptables -I INPUT -p tcp -i wlan0 --match multiport --dport 22000:65535 -j ACCEPT

sudo iptables -L -v -n | more
Chain INPUT (policy ACCEPT 2687K packets, 2589M bytes)
 pkts bytes target     prot opt in     out     source               destination
   12  9365 ACCEPT     tcp  --  wlan0  *       0.0.0.0/0            0.0.0.0/0            multiport dports 22000:65535
  344 19784 LOG_DROP   tcp  --  wlan0  *      !192.168.1.0/24       0.0.0.0/0
```

restart HASS -> thì ko còn log lỗi nữa

Trong LOG_DROP thì mình phát hiện nhiều traffic đến các port nhỏ hơn như DPT=5007,4100,81,20000,4228,18617,2525...etc. Nói chung rất nhiều port nhỏ hơn 22000 bị DROP. Nhưng HASS vẫn hoạt động ổn nên cho qua.. 

Giờ accept traffic on port 8123 để từ mạng 4G có thể connect đến được:  

```sh
# accept traffic TCP incoming interface wlan0 on Chain INPUT port XXX from anywhere
iptables -I INPUT -p tcp -i wlan0 --dport 8123 -j ACCEPT

sudo iptables -L -v -n | more
Chain INPUT (policy ACCEPT 2699K packets, 2600M bytes)
 pkts bytes target     prot opt in     out     source               destination
    0     0 ACCEPT     tcp  --  wlan0  *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8123
 2203 1380K ACCEPT     tcp  --  wlan0  *       0.0.0.0/0            0.0.0.0/0            multiport dports 22000:65535
  442 25513 LOG_DROP   tcp  --  wlan0  *      !192.168.1.0/24       0.0.0.0/0
```

Đến đây về cơ bản mọi thứ đã OK. Add thêm accept các port 80,443 là được, để sau này làm https. 

Tổng kết các rule mình sử dụng trong phần này: 

```sh
# drop all traffic TCP incoming interface wlan0 Chain INPUT, except LAN
iptables -I INPUT -p tcp -i wlan0 ! -s 192.168.1.0/24 -j DROP

# accept traffic TCP incoming interface wlan0 on Chain INPUT port XXX from anywhere
iptables -I INPUT -p tcp -i wlan0 --match multiport --dport 22000:65535 -j ACCEPT

# accept traffic TCP incoming interface wlan0 on Chain INPUT port XXX from anywhere
iptables -I INPUT -p tcp -i wlan0 --dport 8123 -j ACCEPT
```

Còn Bên dưới là các hướng mình đã làm nhưng ko recommend lắm.  

# 4. Một số chú ý

## 4.1. Nếu bạn chỉ add rule iptables vào Chain INPUT thì sao

Add rule này vào chain INPUT:  

```sh
# drop all traffic incoming interface wlan0 Chain INPUT, except LAN
iptables -I INPUT -p tcp -i wlan0 ! -s 192.168.1.0/24 -j DROP
```
Test:  
Từ mạng 4G -> port 8123 -> ko access được.  
Từ mạng 4G -> port Docker (3000, 9000, 8200, ...) -> access được hết.  
Tổng kết: Như vậy việc add rule drop traffic ở `Chain INPUT` ko ảnh hưởng gì đến `Chain DOCKER-USER` cả. ☹ 


## 4.2. Nếu bạn chỉ drop traffic ở từng port cụ thể thôi

```sh
# drop traffic incoming interface wlan0 Chain DOCKER-USER port XXX from anywhere, except LAN
iptables -I DOCKER-USER -p tcp -i wlan0 ! -s 192.168.1.0/24 --dport 3000 -j DROP
iptables -I DOCKER-USER -p tcp -i wlan0 ! -s 192.168.1.0/24 --dport 9000 -j DROP
iptables -I DOCKER-USER -p tcp -i wlan0 ! -s 192.168.1.0/24 --dport 9001 -j DROP
iptables -I DOCKER-USER -p tcp -i wlan0 ! -s 192.168.1.0/24 --dport 1883 -j DROP
iptables -I DOCKER-USER -p tcp -i wlan0 ! -s 192.168.1.0/24 --dport 9090 -j DROP
iptables -I DOCKER-USER -p udp -i wlan0 ! -s 192.168.1.0/24 --dport 51820 -j DROP
iptables -I DOCKER-USER -p tcp -i wlan0 ! -s 192.168.1.0/24 --dport 4444 -j DROP
iptables -I DOCKER-USER -p tcp -i wlan0 ! -s 192.168.1.0/24 --dport 8200 -j DROP
iptables -I DOCKER-USER -p tcp -i wlan0 ! -s 192.168.1.0/24 --dport 8080 -j DROP
# drop traffic incoming interface wlan0 Chain INPUT port 22 từ anywhere, except LAN
iptables -I INPUT -p tcp -i wlan0 ! -s 192.168.1.0/24 --dport 22 -j DROP
```

nó sẽ được như này ( toàn các rule được add vào `Chain DOCKER-USER`, 1 rule được add vào `Chain INPUT` để chặn port 22 ):  

```
sudo iptables -L -v -n | more
Chain INPUT (policy ACCEPT 1492K packets, 1581M bytes)
 pkts bytes target     prot opt in     out     source               destination
    0     0 DROP       tcp  --  wlan0  *      !192.168.1.0/24       0.0.0.0/0            tcp dpt:22

Chain FORWARD (policy ACCEPT 4921 packets, 2451K bytes)
 pkts bytes target     prot opt in     out     source               destination
 838K  745M DOCKER-USER  all  --  *      *       0.0.0.0/0            0.0.0.0/0
 794K  736M DOCKER-ISOLATION-STAGE-1  all  --  *      *       0.0.0.0/0            0.0.0.0/0
    0     0 ACCEPT     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
    0     0 DOCKER     all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
    0     0 ACCEPT     all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
    0     0 ACCEPT     all  --  docker0 docker0  0.0.0.0/0            0.0.0.0/0
 422K  168M ACCEPT     all  --  *      br-564d64d5a58a  0.0.0.0/0            0.0.0.0/0            ctstate RELATED,ESTABLISHED
 1653  224K DOCKER     all  --  *      br-564d64d5a58a  0.0.0.0/0            0.0.0.0/0
 371K  568M ACCEPT     all  --  br-564d64d5a58a !br-564d64d5a58a  0.0.0.0/0            0.0.0.0/0
  756  176K ACCEPT     all  --  br-564d64d5a58a br-564d64d5a58a  0.0.0.0/0            0.0.0.0/0

Chain OUTPUT (policy ACCEPT 1559K packets, 1541M bytes)
 pkts bytes target     prot opt in     out     source               destination

Chain DOCKER (2 references)
 pkts bytes target     prot opt in     out     source               destination
  207 11020 ACCEPT     tcp  --  !br-564d64d5a58a br-564d64d5a58a  0.0.0.0/0            172.18.0.2           tcp dpt:9000
   34  1720 ACCEPT     tcp  --  !br-564d64d5a58a br-564d64d5a58a  0.0.0.0/0            172.18.0.5           tcp dpt:9001
    4   208 ACCEPT     tcp  --  !br-564d64d5a58a br-564d64d5a58a  0.0.0.0/0            172.18.0.5           tcp dpt:1883
    5   240 ACCEPT     tcp  --  !br-564d64d5a58a br-564d64d5a58a  0.0.0.0/0            172.18.0.6           tcp dpt:9090
    0     0 ACCEPT     udp  --  !br-564d64d5a58a br-564d64d5a58a  0.0.0.0/0            172.18.0.10          udp dpt:51820
  125  6832 ACCEPT     tcp  --  !br-564d64d5a58a br-564d64d5a58a  0.0.0.0/0            172.18.0.7           tcp dpt:3000
   86  4704 ACCEPT     tcp  --  !br-564d64d5a58a br-564d64d5a58a  0.0.0.0/0            172.18.0.4           tcp dpt:8200
   60  3176 ACCEPT     tcp  --  !br-564d64d5a58a br-564d64d5a58a  0.0.0.0/0            172.18.0.9           tcp dpt:8080

Chain DOCKER-ISOLATION-STAGE-1 (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 DOCKER-ISOLATION-STAGE-2  all  --  docker0 !docker0  0.0.0.0/0            0.0.0.0/0
 371K  568M DOCKER-ISOLATION-STAGE-2  all  --  br-564d64d5a58a !br-564d64d5a58a  0.0.0.0/0            0.0.0.0/0
 794K  736M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0

Chain DOCKER-ISOLATION-STAGE-2 (2 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 DROP       all  --  *      docker0  0.0.0.0/0            0.0.0.0/0
    0     0 DROP       all  --  *      br-564d64d5a58a  0.0.0.0/0            0.0.0.0/0
 371K  568M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0

Chain DOCKER-USER (1 references)
 pkts bytes target     prot opt in     out     source               destination
   45  2600 DROP       tcp  --  wlan0  *      !192.168.1.0/24       0.0.0.0/0            tcp dpt:8080
   17   908 DROP       tcp  --  wlan0  *      !192.168.1.0/24       0.0.0.0/0            tcp dpt:8200
    0     0 DROP       tcp  --  wlan0  *      !192.168.1.0/24       0.0.0.0/0            tcp dpt:4444
    0     0 DROP       udp  --  wlan0  *      !192.168.1.0/24       0.0.0.0/0            udp dpt:51820
    0     0 DROP       tcp  --  wlan0  *      !192.168.1.0/24       0.0.0.0/0            tcp dpt:9090
    0     0 DROP       tcp  --  wlan0  *      !192.168.1.0/24       0.0.0.0/0            tcp dpt:1883
    0     0 DROP       tcp  --  wlan0  *      !192.168.1.0/24       0.0.0.0/0            tcp dpt:9001
   31  1804 DROP       tcp  --  wlan0  *      !192.168.1.0/24       0.0.0.0/0            tcp dpt:9000
   52  3120 DROP       tcp  --  wlan0  *      !192.168.1.0/24       0.0.0.0/0            tcp dpt:3000
 794K  736M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0

```
Test:  
Từ mạng 4G -> port 8123 -> access được. (dễ hiểu thôi vì nó ko phải port trong Docker chain).  
Từ mạng 4G -> port  Docker -> ko access được.    
Từ local -> access được hết.  
Test connection đến AWS S3 từ Duplicati: worked.  
Log của HASS: ko có lỗi gì.  
Lên `canyouseeme.org`, check hết các port xem ở ngoài có thấy service nào chạy ko?   
Có vẻ tạm chấp nhận thôi.  

check lại các port đang open bằng nmap:  

```sh
# UDP scan
sudo nmap -sU -p- 192.168.1.128
Starting Nmap 7.80 ( https://nmap.org ) at 2022-09-16 17:01 +07
Nmap scan report for 192.168.1.128
Host is up (0.000041s latency).
Not shown: 65529 closed ports
PORT      STATE         SERVICE
68/udp    open|filtered dhcpc
546/udp   open|filtered dhcpv6-client
5353/udp  open          zeroconf
34484/udp open|filtered unknown
46861/udp open|filtered unknown
51820/udp open|filtered unknown

# TCP scan
sudo nmap -sT -p- 192.168.1.128
Starting Nmap 7.80 ( https://nmap.org ) at 2022-09-16 17:05 +07
Nmap scan report for 192.168.1.128
Host is up (0.00072s latency).
Not shown: 65527 closed ports
PORT     STATE SERVICE
22/tcp   open  ssh
1883/tcp open  mqtt
3000/tcp open  ppp
8080/tcp open  http-proxy
8123/tcp open  polipo
8200/tcp open  trivnet1
9000/tcp open  cslistener
9090/tcp open  zeus-admin
```

Như vậy là bạn thấy hầu hết các port TCP đang open kia mình đã close lại bằng `iptables` rồi (trừ 8123 để sử dụng). Các port TCP thì có vài port hơi lạ ko biết để làm gì: `34484, 46861`

Thử DROP 2 port lạ hoắc trên xem có vấn đề gì xảy ra, đầu tiên là port `34484`:  

```sh
iptables -I INPUT -p udp -i wlan0 ! -s 192.168.1.0/24 --dport 34484 -j DROP
```
Test: ko thấy có lỗi nào xảy ra.     
HASS vẫn hoạt động bình thường. Ko có log lỗi. 
Duplicati test connection to S3: worked.  

tiếp port `46861`:

```sh
iptables -I INPUT -p udp -i wlan0 ! -s 192.168.1.0/24 --dport 46861 -j DROP
```
Test: ko thấy lỗi gì xảy ra.  

Tổng kết: Cách này về cơ bản cũng có thể chấp nhận được. Nhưng mình thích `3.1,3.2` hơn.  

## 4.3. Save iptable rule to reload on boots

Sau khi reboot RPi sẽ thấy iptable lại bị reset, mất hết các rules vừa set, Nên cần save rule bằng command sau:  

```sh
sudo apt-get install iptables-persistent
sudo netfilter-persistent save
sudo netfilter-persistent reload
```

Thử reboot rồi vào check xem các iptables rule có bị mất ko? ko thì OK

# 5. Tóm tắt

Các command cần làm:

```sh
# Chain DOCKER-USER
# drop any traffic TCP incoming interface wlan0 on Docker from anywhere, except LAN
iptables -I DOCKER-USER -p tcp -i wlan0 ! -s 192.168.1.0/24 -j DROP

# This open makes connection from Duplciati to S3 works
# accept traffic TCP incoming interface wlan0 on Docker port XXX from anywhere
iptables -I DOCKER-USER -p tcp -i wlan0 --match multiport --dport 33000:65535 -j ACCEPT
iptables -I DOCKER-USER -p tcp -i wlan0 --dport 80 -j ACCEPT
iptables -I DOCKER-USER -p tcp -i wlan0 --dport 443 -j ACCEPT

# Chain INPUT
# drop all traffic TCP incoming interface wlan0 Chain INPUT from anywhere, except LAN
iptables -I INPUT -p tcp -i wlan0 ! -s 192.168.1.0/24 -j DROP

# This open makes HASS working normal
# accept traffic TCP incoming interface wlan0 on Chain INPUT port XXX from anywhere
iptables -I INPUT -p tcp -i wlan0 --match multiport --dport 22000:65535 -j ACCEPT

# This open HASS so you can access from Outside Internet
# accept traffic TCP incoming interface wlan0 on Chain INPUT port XXX from anywhere
iptables -I INPUT -p tcp -i wlan0 --dport 8123 -j ACCEPT
```

Confirm:

```output
Chain INPUT (policy ACCEPT 2756K packets, 2653M bytes)
 pkts bytes target     prot opt in     out     source               destination
   19   778 ACCEPT     tcp  --  wlan0  *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8123
   76 44116 ACCEPT     tcp  --  wlan0  *       0.0.0.0/0            0.0.0.0/0            multiport dports 22000:65535
    5   208 DROP       tcp  --  wlan0  *      !192.168.1.0/24       0.0.0.0/0

Chain DOCKER-USER (1 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 ACCEPT     tcp  --  wlan0  *       0.0.0.0/0            0.0.0.0/0            multiport dports 33000:65535
    0     0 DROP       tcp  --  wlan0  *      !192.168.1.0/24       0.0.0.0/0
1298K 1123M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
```

Khi muốn Debug:
https://stackoverflow.com/a/29544353/9922066

Let's create a chain to log and accept:

```sh
iptables -N LOG_ACCEPT
```
And let's populate its rules:
```sh
iptables -A LOG_ACCEPT -j LOG --log-prefix "INPUT:ACCEPT:" --log-level 6
iptables -A LOG_ACCEPT -j ACCEPT
```
Now let's create a chain to log and drop:
```sh
iptables -N LOG_DROP
```
And let's populate its rules:
```sh
iptables -A LOG_DROP -j LOG --log-prefix "INPUT:DROP: " --log-level 6
iptables -A LOG_DROP -j DROP
```

Confirm:

```output
Chain LOG_ACCEPT (0 references)
 pkts bytes target     prot opt in     out     source               destination
  154  129K LOG        all  --  *      *       0.0.0.0/0            0.0.0.0/0            LOG flags 0 level 6 prefix "INPUT:ACCEPT:"
  154  129K ACCEPT     all  --  *      *       0.0.0.0/0            0.0.0.0/0

Chain LOG_DROP (0 references)
 pkts bytes target     prot opt in     out     source               destination
 1088 58637 LOG        all  --  *      *       0.0.0.0/0            0.0.0.0/0            LOG flags 0 level 6 prefix "INPUT:DROP: "
 1088 58637 DROP       all  --  *      *       0.0.0.0/0            0.0.0.0/0
```

Now you can do all actions in one go by jumping (-j) to you custom chains instead of the default LOG / ACCEPT / REJECT / DROP:

```sh
iptables -A <your_chain_here> <your_conditions_here> -j LOG_ACCEPT
iptables -A <your_chain_here> <your_conditions_here> -j LOG_DROP
```

# CREDIT

https://stackoverflow.com/a/56038551/9922066   
https://docs.docker.com/network/iptables/   
https://stackoverflow.com/a/29544353/9922066