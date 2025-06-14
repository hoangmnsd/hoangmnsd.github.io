---
title: "Setup Home Assistant on Raspberry Pi (Part 7) - Tunnel"
date: 2024-12-28T18:34:01+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [RaspberryPi,HomeAssistant,Tunnel,Cloudflare,Alexa,Nginx,Docker]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Bài thứ 7 trong series về Setup HASS trên RPi"
---

# 1. Story

Mình đang có 1 app HomeAssistant (HASS) chạy trên RPi ở nhà.

Mình có nhiều device (bóng đèn) đã connect với HASS rồi.

Mình có 1 Alexa speaker để trong nhà.

Mình cần ra lệnh cho Alexa tắt/bật đèn trong nhà. 

Khi config Alexa nó sẽ cần integrate với HASS để điều khiển device trong nhà.

Alexa connect với HASS qua internet (ko phải local). Phải là https HASS.

Nên mình cần expose HASS ra internet (HTTPS) để integrate được với Alexa. 

Để expose HASS ra internet https, mình đã làm:

- cài nginx(swag) để có Let'sencrypt certifcate cho HTTPS.
- swag cần expose port 443,80 ra ngoài internet.

port 80 và 443 bị ISP (VNPT) reserved nên ko expose bằng `Port Forwarding` được.

Thế nên mình đã đặt RPi vào `DMZ` (trên Router VNPT) để swag có thể expose 443,80. 

Nhược điểm là server trong DMZ thì expose tất cả các port kể cả 443.

Để hạn chế phần nào nhược điểm trên thì mình đã đặt iptable rule để chỉ cho phép expose 1 số port cụ thể như 443.

Như vậy mình đã expose internet HASS ra https, và cả http:8123.

Và Alexa đã dùng được tất cả tính năng cần.

Cho đến 2024-12-26:

1 ngày Alexa ko thực hiện các yêu cầu (như tắt/bật đèn) nữa. 

Check lại thì từ bên ngoài internet ko connect được đến HASS https nữa. Nhưng bên ngoài vẫn connect được đến HASS http 8123.

Đã check thử grafana port 3000 expose qua swag https, thì từ 4G cũng ko connect được.

Khả năng là port 443 trong DMZ cũng ko được expose nữa rồi. (Có thể do ISP VNPT thay đổi)

# 2. Hướng đi mới

Mình sẽ thay đổi ko dùng cách đặt RPi vào DMZ rồi expose trực tiếp ra Internet nữa. 

Có 2 cách thay thế:

- Dùng Cloudflare tunnel https://www.youtube.com/watch?v=ey4u7OUAF3c.

  Ưu điểm:
    + bảo mật, nếu Router bị restart -> public IP của nhà mình thay đổi thì cũng ko sao.
    + có thêm nhiều chức năng bảo vệ, ví dụ như hạn chế access theo location, OPT send qua email khi webapp bạn chưa có trang login. (https://youtu.be/ZvIdFs3M5ic?t=1723)
    + IP expose ra là IP của Cloudflare chứ ko phải của mình.
    + ko cần Letsencrypt certificate nữa. (vì dùng https của Cloudflare rồi).  

  Nhược điểm:
    + Sẽ cần mua 1 Domain để register vào Cloudflare (ko dùng được cái Duckdns sub domain có sẵn, mất tiền duy trì domain hàng năm).
    + phụ thuộc vào Cloudflare Tunnel ZeroTrust, họ có thể tăng giá, hoặc thay đổi chính sách trong tương lai.  

- Dùng VPS tunnel (mình đã có sẵn 1 oracle cloud VM).

  Ưu điểm:
    + bảo mật, có thể tiếp tục sử dụng Duckdns sub domain, let'sencrypt certificate, nginx(swag) có sẵn.  

  Nhược điểm:
    + Nếu Router bị restart -> public IP mới sẽ cần sửa NSG oracle cloud -> để có thể SSH tunnel lại.
    + phụ thuộc vào VPS, Oracle có thể terminate, stop VPS, hoặc tăng giá.
    + Cần bảo mật tốt cho swag (nginx) vì bạn expose IP ra nên có thể sẽ thường xuyên bị scan port (hãy check log `error.log`). 
    + IP expose ra internet sẽ là IP của VPS (có thể ko sao nếu bạn ko có gì đặc biệt cần che giấu IP của VPS).  

# 3. Thử cách 1, Tạo tunnel từ local đến VPS

tạo Tunnel từ local RPi sang VPS instance:

```sh
ssh -i /path/to/your/private_key.pem -N -R 8123:localhost:8123 user@VPS_PUBLIC_IP
```

xong trên VPS terminal: 
```s
$ curl localhost:8123
# Thấy trả về kết quả là ok

$ curl 127.0.0.1:8123
# Thấy trả về kết quả là ok
```

Có thể dùng `autossh` hoặc run command `ssh -fnNT -R 8123:localhost:8123 user@VPS_PUBLIC_IP` để run tunnel dưới background

Sửa docker compose file trên VPS:

```yml
version: '3.9'

services:

  proxy-relay:
    image: alpine/socat:latest
    container_name: proxysocat
    network_mode: host
    command: TCP-LISTEN:8123,fork,bind=host.docker.internal TCP-CONNECT:127.0.0.1:8123
    extra_hosts:
      - host.docker.internal:host-gateway

  swag:
    image: lscr.io/linuxserver/swag:1.30.0
    container_name: swag
    cap_add:
      - NET_ADMIN
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Ho_Chi_Minh
      - URL=YOUR_DOMAIN.duckdns.org
      - VALIDATION=duckdns
      - SUBDOMAINS=wildcard #optional
      - CERTPROVIDER= #optional
      - DNSPLUGIN=duckdns #optional
      - PROPAGATION= #optional
      - DUCKDNSTOKEN=YOUR_DUCKDNS_TOKEN #optional
      - EMAIL=YOUR_EMAIL@gmail.com #optional
      - ONLY_SUBDOMAINS=true #optional
      - EXTRA_DOMAINS= #optional
      - STAGING=false #optional
    volumes:
      - /opt/devops/swag/config:/config
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "10"
    ports:
      - 443:443
      # - 80:80 #optional
    extra_hosts:
      - "host.docker.internal:host-gateway"
    network_mode: "bridge"
```

Bắt buộc phải dùng docker `socat` vì:
- dùng docker network mode `host` thì swag ko hoạt động
- dùng nginx install trực tiếp trên VPS Host thay vì docker thì mình ko muốn.
- dùng docker network mode `bridge` thì swag hoạt động nhưng:
  + từ container swag ko curl đến được VPS Host port 8123. 
  (
    đã thử nhiều cách:
    + Tunnel đến Docker gateway (172.17.0.1) interface.
    + Tunnel đến 0.0.0.0 interface.
    + sửa iptable rule.
  ) 

docker inspect để xem gateway đang dùng ip nào, mặc định là `172.17.0.1`:
```sh
docker inspect swag
# kết quả là 172.17.0.1
...
            "Networks": {
                "bridge": {
                    "IPAMConfig": null,
                    "Links": null,
                    "Aliases": null,
                    "NetworkID": "7b978d34e660e86a6dc996a54e4bd53bfc1e9c563c2eaf2c134685ab9d69251a",
                    "EndpointID": "39d188e65610fc91e87cde025d61f8dd4bd8f15dcb614e1b7dd4868150167f16",
                    "Gateway": "172.17.0.1",
                    "IPAddress": "172.17.0.2",
                    "IPPrefixLen": 16,
                    "IPv6Gateway": "",
                    "GlobalIPv6Address": "",
                    "GlobalIPv6PrefixLen": 0,
                    "MacAddress": "02:42:ac:11:00:02",
                    "DriverOpts": null
                }
            }

```

Sửa iptable rule (quan trọng):

```sh
sudo iptables -I INPUT -i docker0 -d 172.17.0.1 -p tcp --dport 8123 -j ACCEPT

# Check lại 
sudo iptables -L -v -n | more

# Nếu muốn xóa rule trên thì dùng: sudo iptables -D INPUT -i docker0 -d 172.17.0.1 -p tcp --dport 8123 -j ACCEPT
```

Vào container check curl xem:

```s
$ docker exec -it swag /bin/bash
root@b319708116ac:/# curl 172.17.0.1:8123
# trả về kết quả là OK
```

Sửa nginx (swag) config:

```s
server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name hass.*;
    
    add_header X-Robots-Tag "noindex, nofollow, nosnippet, noarchive"; # Hoang: This will ask Google et al not to index and list your site. 
    include /config/nginx/ssl.conf;

    client_max_body_size 0;

    location / {

        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app 172.17.0.1;
        set $upstream_port 8123;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;

    }

    location ~ ^/(api|local|media)/ {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app 172.17.0.1;
        set $upstream_port 8123;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }
}
```

docker restart swag

Từ Browser vào lại domain đã chọn cho hass đã vào được. TADA~~~~ 😍😎😎😋

```s
$ wget https://hass.DOMAIN.duckdns.org/
--2024-12-27 22:53:14--  https://hass.DOMAIN.duckdns.org/
Resolving hass.DOMAIN.duckdns.org (hass.DOMAIN.duckdns.org)... PUBLIC_IP
Connecting to hass.DOMAIN.duckdns.org (hass.DOMAIN.duckdns.org)|PUBLIC_IP|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 4192 (4.1K) [text/html]
Saving to: ‘index.html.1’

index.html.1                  100%[=================================================>]   4.09K  --.-KB/s    in 0s

2024-12-27 22:53:16 (816 MB/s) - ‘index.html.1’ saved [4192/4192]
```

## Re-enable Alexa Skill and Re-link account

Giờ sẽ Cần link lại Alexa app với cái domain mới của mình.

vào Alexa Developer page để sửa lại URL mới của HASS (ảnh)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-ssh-tunnel-new-domain.jpg)

Vào lambda function sửa env: (ảnh)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-ssh-tunnel-new-domain-lamdbda.jpg)

sau đó vào app Alexa trên điện thoại để disable skill và re-enable lại, link account.

Nó sẽ redirect bạn đến page URL mới của HASS, Bạn sẽ cần login lại vào nó (dùng account riêng càng tốt Alexa chẳng hạn)

Login và Link account thành công, discovery devices thành công là OK.

Nếu bị lỗi dừng lại mãi ở màn hình Link Account:  

- Trường hợp của mình là do dùng Android. Đã thử VPN sang US, 4G, Wifi đều ko ăn thua.
- Phải Chuyển sang dùng Iphone để link account thì thành công.
- Có thể app trên Android cần phải update file apk latest.

Test thử nếu Dùng voice để điều khiển device (on/off) thành công! Tuyệt vời 😎

## Troubleshoot

Trước khi đi vào các step debug:

> SPECIAL THANKS TO henk: https://superuser.com/a/1839649,
  
  AND Mohammad Javad Naderi: https://dev.to/mjnaderi/accessing-host-services-from-docker-containers-1a97.
  
  Họ giúp mình save cả tuần debug với docker network.

---

Khi đã tạo SSH tunnel từ RPi đến VPS:

```sh
$ ssh -i /path/to/key -N -R 8123:localhost:8123 ubuntu@VPS_PUBLIC_IP

```
Test từ `VPS` host, curl đến 127.0.0.1:8123 OK

Sửa swag proxy đến `proxy_pass http://127.0.0.1:8123;`

Test từ inside `swag` container, curl đến 127.0.0.1:8123 ko được:

```s
root@1b468089edf7:/# curl 127.0.0.1:8123
curl: (7) Failed to connect to 127.0.0.1 port 8123 after 0 ms: Connection refused
```
Từ Browser thử test đến https://hass.DOMAIN.duckdns.org, sẽ bị Lỗi `502 Bad gateway`.
```s
$ wget https://hass.DOMAIN.duckdns.org
--2024-12-27 10:22:51--  https://hass.DOMAIN.duckdns.org/
Resolving hass.DOMAIN.duckdns.org (hass.DOMAIN.duckdns.org)... PUBLIC_IP
Connecting to hass.DOMAIN.duckdns.org (hass.DOMAIN.duckdns.org)|PUBLIC_IP|:443... connected.
HTTP request sent, awaiting response... 502 Bad Gateway
2024-12-27 10:22:52 ERROR 502: Bad Gateway.
```

Nghĩa là swag container đang trong 1 network riêng ko connect được đến port 8123 của host VPS. 

Sửa docker-compose file sang network mode `bridge` driver:
```yml
    ports:
      - 443:443
    #   - 80:80 #optional
    network_mode: bridge
```

Vẫn lỗi như trên.

Còn nếu sửa thêm binding port 8123:
```yml
    ports:
      - 443:443
      - 8123:8123
    #   - 80:80 #optional
    network_mode: bridge
```
ko docker-compose up được vì port 8123 đã in use bởi tunnel:
```s
$ docker-compose up -d
Creating swag ...
Creating swag ... error

ERROR: for swag  Cannot start service swag: driver failed programming external connectivity on endpoint swag (df17648e0c6b8cde0f3f78db94f7dfdb7942da9b2451aca615f559d3931441a8): Error starting userland proxy: listen tcp4 0.0.0.0:8123: bind: address already in use

ERROR: for swag  Cannot start service swag: driver failed programming external connectivity on endpoint swag (df17648e0c6b8cde0f3f78db94f7dfdb7942da9b2451aca615f559d3931441a8): Error starting userland proxy: listen tcp4 0.0.0.0:8123: bind: address already in use
ERROR: Encountered errors while bringing up the project.
```

Sửa tắt Tunnel đi, bind được port 8123 vào container trước, rồi sau đó mới tạo Tunnel.
```s
$ docker ps
CONTAINER ID   IMAGE                             COMMAND   CREATED         STATUS         PORTS                                                                     NAMES
5f88393098b8   lscr.io/linuxserver/swag:1.30.0   "/init"   6 seconds ago   Up 4 seconds   80/tcp, 0.0.0.0:443->443/tcp, :::443->443/tcp, 127.0.0.1:8123->8123/tcp   swag
```

Thì lại bị lỗi từ `VPS` host, curl đến 127.0.0.1:8123 Lỗi:
```s
$ curl 127.0.0.1:8123
curl: (56) Recv failure: Connection reset by peer

$ curl localhost:8123
curl: (56) Recv failure: Connection reset by peer
```
Từ inside container swag, curl đến 127.0.0.1:8123 Lỗi:
```s
$ docker exec -it swag /bin/bash
root@5f88393098b8:/# curl 127.0.0.1:8123
curl: (7) Failed to connect to 127.0.0.1 port 8123 after 0 ms: Connection refused
root@5f88393098b8:/# curl localhost:8123
curl: (7) Failed to connect to localhost port 8123 after 0 ms: Connection refused
root@5f88393098b8:/# curl http://localhost:8123
curl: (7) Failed to connect to localhost port 8123 after 0 ms: Connection refused
```

Sửa docker-compose file sang network mode `host` driver, thì phải bỏ port binding để ko bị incompartible:
```yml
    # ports:
    #   - 443:443
    #   - 80:80 #optional
    network_mode: host
```

Test từ inside `swag` container, curl đến 127.0.0.1:8123 OK:
```s
root@VPS:/# curl 127.0.0.1:8123
# OK
```
Test từ `VPS` host, curl đến 127.0.0.1:8123 vẫn OK như cũ.

Nhưng Test từ Browser sẽ bị lỗi `Resource temporarily unavailable`:
```s
$ wget https://hass.DOMAIN.duckdns.org
--2024-12-27 10:39:46--  https://hass.DOMAIN.duckdns.org/
Resolving hass.DOMAIN.duckdns.org (hass.DOMAIN.duckdns.org)... PUBLIC_IP
Connecting to hass.DOMAIN.duckdns.org (hass.DOMAIN.duckdns.org)|PUBLIC_IP|:443... failed: Resource temporarily unavailable.
Retrying.

--2024-12-27 10:40:09--  (try: 2)  https://hass.DOMAIN.duckdns.org/
Connecting to hass.DOMAIN.duckdns.org (hass.DOMAIN.duckdns.org)|PUBLIC_IP|:443... failed: Resource temporarily unavailable.
Retrying.
```
Có nghĩa là docker `swag` mà không có port binding thì nó ko works

Cuối cùng tìm được post: https://superuser.com/questions/1837964/access-remote-ssh-tunnel-from-inside-docker-container

Nói đúng trường hợp mình đang gặp phải.

Tuy nhiên mình đã đi qua hầu hết các solution của anh ta. Nhưng không thể giải quyết được cho đến khi làm thử theo hướng dùng socat (https://dev.to/mjnaderi/accessing-host-services-from-docker-containers-1a97) 😘😘😍


# 4. Thử cách 2, Tạo tunnel bằng Cloudflare

Tạo acc Cloudflare 

Mua 1 domain (trên Namecheap chẳng hạn)

Vào Cloudflare, `Add Site` (or `Add Domain`)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/cloudflare-add-site-add-domain.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/cloudflare-add-site-add-domain-exist.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/cloudflare-add-site-add-domain-select-plan.jpg)

Đây là các records đc auto tạo ra do Cloudflare:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/cloudflare-add-site-add-domain-records-auto.jpg)

Copy Cloudflare DNS servername, add vào DNS Registrars (trên Namecheap)

Trên Cloudflare có 2 ns records ở đây:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/cloudflare-add-site-add-domain-records-ns.jpg)

Edit trên Namecheap:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/cloudflare-add-site-add-domain-records-ns-on-namecheap.jpg)

Quay lại Cloudflare delete các records ko cần thiết:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/cloudflare-add-site-add-domain-records-delete.jpg)

Cloudflare đã show các steps cần làm ở đây, vì chúng ta đã làm xong nên sẽ ấn vào button `Check nameservers now`:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/cloudflare-add-site-add-domain-last-steps.jpg)

Rồi chờ:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/cloudflare-add-site-add-domain-last-steps-wait.jpg)

Chờ đến khi site `Active`

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/cloudflare-add-site-add-domain-activate.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/cloudflare-domain-active.jpg)

Vào Cloudflare => Access => Launch Zero Trust 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/cloudflare-domain-zero-trust.jpg)

Có thể phải tạo Team name domains, ko sao họ bảo có thể sửa sau này: `xxx.cloudflareareas.com`

Chọn plan Free:  
  - 50 seat limit
  - Zero Trust controls
  - Up to 3 network locations (for office-based DNS filtering)
  - Layer 7 (HTTP) filtering rules
  - Roaming user support via WARP
  - Up to 24 hours of log retention

(có thể phải add Credit Card làm payment method)

Vào Network => Tunnels => Add Tunnel => Select Cloudflared

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/cloudflare-domain-tunnel-create.jpg)

Trên VPS, run docker command để tạo connector từ VPS đến Cloudflare

```sh
sudo sysctl -w net.core.rmem_max=7500000
sudo sysctl -w net.core.wmem_max=7500000
docker run -d cloudflare/cloudflared:latest tunnel --no-autoupdate run --token ...
```
check log của container vừa tạo, và trên dashboard của Cloudflare phải có tunnel ở trạng thái Healthy mới OK

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/cloudflare-tunnel-rpi-healthy.jpg)

Trên Cloudflare, edit public hostname, point đến IP của RPi và port 8123 chẳng hạn.

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/cloudflare-public-hostname-tunnel-rpi.jpg)

Test vào thử domain mới, OK.

Giờ làm lại các step config Alexa trong phần `## Re-enable Alexa Skill and Re-link account` ở bên trên.

## Troubleshoot

### 2025.03.18

2,3 Hôm nay bị lỗi Alexa ko play music được.
Vào check Labmda log ko có gì (hoàn toàn ko có log). Nghĩa là từ Alexa ko connect được đến Hass public endpoint.
Vào check log clouflare thấy cái này:
```s
2025-03-13T19:35:21Z WRN Failed to serve tunnel connection error="Application error 0x0 (remote)" connIndex=1 event=0 ip=X.XX.XX.77
2025-03-13T19:35:21Z WRN Serve tunnel error error="Application error 0x0 (remote)" connIndex=1 event=0 ip=X.XX.XX.77
2025-03-13T19:35:21Z INF Retrying connection in up to 1s connIndex=1 event=0 ip=X.XX.XX.77
2025-03-13T19:35:22Z WRN Connection terminated error="Application error 0x0 (remote)" connIndex=1
2025-03-13T19:35:27Z INF Registered tunnel connection connIndex=1 connection=ed7810a6-17ed-4416-a194-4565f8627004 event=0 ip=X.XX.XX.77 location=hkg01 protocol=quic
2025-03-14T06:30:57Z WRN Your version 2024.12.2 is outdated. We recommend upgrading it to 2025.2.1
2025-03-15T06:30:57Z WRN Your version 2024.12.2 is outdated. We recommend upgrading it to 2025.2.1
2025-03-16T06:30:57Z WRN Your version 2024.12.2 is outdated. We recommend upgrading it to 2025.2.1
2025-03-17T06:30:57Z WRN Your version 2024.12.2 is outdated. We recommend upgrading it to 2025.2.1
2025-03-17T12:23:53Z WRN Failed to serve tunnel connection error="failed to accept QUIC stream: timeout: no recent network activity" connIndex=0 event=0 ip=X.XX.XX.33
2025-03-17T12:23:53Z WRN Serve tunnel error error="failed to accept QUIC stream: timeout: no recent network activity" connIndex=0 event=0 ip=X.XX.XX.33
2025-03-17T12:23:53Z INF Retrying connection in up to 1s connIndex=0 event=0 ip=X.XX.XX.33
2025-03-17T12:23:53Z WRN Connection terminated error="failed to accept QUIC stream: timeout: no recent network activity" connIndex=0
2025-03-17T12:24:06Z INF Registered tunnel connection connIndex=0 connection=37c468b5-7975-45f0-908f-40cbd2c9b067 event=0 ip=X.XX.XX.33 location=hkg11 protocol=quic
2025-03-17T18:14:34Z WRN Failed to serve tunnel connection error="timeout: no recent network activity" connIndex=0 event=0 ip=X.XX.XX.33
2025-03-17T18:14:34Z WRN Serve tunnel error error="timeout: no recent network activity" connIndex=0 event=0 ip=X.XX.XX.33
2025-03-17T18:14:34Z INF Retrying connection in up to 1s connIndex=0 event=0 ip=X.XX.XX.33
2025-03-17T18:14:34Z WRN Connection terminated error="timeout: no recent network activity" connIndex=0
2025-03-17T18:14:46Z INF Registered tunnel connection connIndex=0 connection=b90a9a6a1a03 event=0 ip=198.41.200.233 location=hkg10 protocol=quic
2025-03-18T06:30:57Z WRN Your version 2024.12.2 is outdated. We recommend upgrading it to 2025.2.1
```

Run lại `docker-compose up -d` để lấy latest image `cloudflared` là OK


# CREDIT

SPECIAL THANKS TO henk: https://superuser.com/a/1839649

AND Mohammad Javad Naderi: https://dev.to/mjnaderi/accessing-host-services-from-docker-containers-1a97

Họ giúp mình save có khi cả tuần debug với docker network.

---

Về Cloudflare Tunnel: https://www.youtube.com/watch?v=ey4u7OUAF3c

https://transang.me/ssh-tunnel-in-ubuntu/

https://www.reddit.com/r/selfhosted/comments/sv0n0e/my_isp_doesnt_allow_me_to_open_port_443_and_80/

1 repo cập nhật các giải pháp Tunnel: https://github.com/anderspitman/awesome-tunneling

https://tecadmin.net/keep-the-ssh-tunnels-alive-with-autossh/
