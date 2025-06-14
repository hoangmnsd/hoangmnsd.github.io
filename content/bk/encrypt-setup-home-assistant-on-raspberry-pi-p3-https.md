---
title: "Setup Home Assistant on Raspberry Pi (Part 3) - Https"
date: 2022-05-18T23:04:36+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Nginx,HomeAssistant,Letsencrypt,Fail2ban]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Bài thứ 3 trong series về Setup HASS trên RPi"
---

Đây là phần tiếp theo bài này: 
[Setup Home Assistant on Raspberry Pi (Part 2) - DMZ and iptables rule)](../../posts/encrypt-setup-home-assistant-on-raspberry-pi-p2-dmz)

# 1. Access from external network

Đọc kỹ bài sau để biết về các parameter có thể sử dụng:
https://github.com/linuxserver/docker-swag

Trước đó hãy chắc chắn mình đã mở port 80,443 trên iptables DOCKER-USER Chain nhé
```
sudo iptables -L -v -n | more
Chain DOCKER-USER (1 references)
 pkts bytes target     prot opt in     out     source               destination
67922 4074K ACCEPT     tcp  --  wlan0  *       0.0.0.0/0            0.0.0.0/0            tcp dpt:443
  456 40283 ACCEPT     tcp  --  wlan0  *       0.0.0.0/0            0.0.0.0/0            tcp dpt:80
28386   20M ACCEPT     tcp  --  wlan0  *       0.0.0.0/0            0.0.0.0/0            multiport dports 33000:65535
  223 11872 DROP       tcp  --  wlan0  *      !192.168.1.0/24       0.0.0.0/0
 572K  404M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0
```

Sửa file `docker-compose.yml`:  
```yml
...
    swag:
        image: lscr.io/linuxserver/swag:1.30.0
        container_name: swag
        cap_add:
        - NET_ADMIN
        environment:
        - PUID=1000
        - PGID=1000
        - TZ=Asia/Ho_Chi_Minh
        - URL=MYDOMAIN.duckdns.org
        - VALIDATION=duckdns
        - SUBDOMAINS=wildcard, #optional
        - CERTPROVIDER= #optional
        - DNSPLUGIN=cloudflare #optional
        - PROPAGATION= #optional
        - DUCKDNSTOKEN=MY-DUCKDNS-TOKENnn #optional
        - EMAIL=MY_EMAIL@gmail.com #optional
        - ONLY_SUBDOMAINS=false #optional
        - EXTRA_DOMAINS= #optional
        - STAGING=true #optional
        volumes:
        - /opt/swag/config:/config
        ports:
        - 443:443
        - 80:80 #optional
        restart: unless-stopped
```
Chú ý:  
- Chỗ `STAGING=true`, mình sẽ test với staging certificate trước, OK rồi thì mới chuyển sang `STAGING=false` (production certificate)  
- `/opt/swag/config` đã được mình tạo từ trước trên Server RPi.  
- `MY_EMAIL@gmail.com` hãy dùng email chuẩn để sau này nhận thông báo.  
- Khi làm thế này chỉ domain `MYDOMAIN.duckdns.org` là có https secure (https và có valid certificate) thôi, các subdomain tạo như `test.MYDOMAIN.duckdns.org` sẽ ko có https secure (https nhưng ko có valid certificate)  

Sửa file HASS configuration `/opt/hass/config/configuration.yaml` (bước này thực ra mình ko biết nó ảnh hưởng như nào):  
```yml
http:
  use_x_forwarded_for: true
  trusted_proxies:
    - 192.168.1.0/24  # Local Lan
    - 172.18.0.0/24  # Docker network
```

Run `docker-compose up -d`

Check log của swag container ko có lỗi là ok:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/swag-log-container.jpg)

Khi bạn truy cập HTTP `http://MYDOMAIN.duckdns.org/` nó sẽ tự động redirect đến HTTPS `https://MYDOMAIN.duckdns.org/`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/swag-web-default.jpg)

Giờ tìm đến file `/opt/swag/config/nginx/proxy-confs/homeassistant.subdomain.conf.sample`. Đây là 1 file sample được cộng đồng đóng góp và Swag đã include nó vào sẵn trong image.  

Rename file này thành:`/opt/swag/config/nginx/proxy-confs/homeassistant.subdomain.conf`

Sửa nội dung file 1 chút:  
1. `set $upstream_app homeassistant;` -> sửa thành: `set $upstream_app 192.168.X.XXX;` (`192.168.X.XXX` là local IP của HASS)  
2. Chỗ `server_name` thì tùy ý mà thay đổi:  
```
server_name MYDOMAIN.duckdns.org; # when you want to access your HASS as `https://MYDOMAIN.duckdns.org`
# server_name hass.*; # when you want to access your HASS as `https://hass.MYDOMAIN.duckdns.org`
```

File của mình:  
```
## Version 2021/10/11
# make sure that your dns has a cname set for homeassistant and that your homeassistant container is not using a base url

# As of homeassistant 2021.7.0, it is now required to define the network range your proxy resides in, this is done in Homeassitants configuration.yaml
# https://www.home-assistant.io/integrations/http/#trusted_proxies
# Example below uses the default dockernetwork ranges, you may need to update this if you dont use defaults.
#
# http:
#   use_x_forwarded_for: true
#   trusted_proxies:
#     - 172.16.0.0/12

server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name hehe.duckdns.org; # when you want to access your HA as `https://hehe.duckdns.org`
    # server_name hass.*; # when you want to access your HA as `https://hass.hehe.duckdns.org`

    include /config/nginx/ssl.conf;

    client_max_body_size 0;

    # enable for ldap auth, fill in ldap details in ldap.conf
    #include /config/nginx/ldap.conf;

    # enable for Authelia
    #include /config/nginx/authelia-server.conf;

    location / {
        # enable the next two lines for http auth
        #auth_basic "Restricted";
        #auth_basic_user_file /config/nginx/.htpasswd;

        # enable the next two lines for ldap auth
        #auth_request /auth;
        #error_page 401 =200 /ldaplogin;

        # enable for Authelia
        #include /config/nginx/authelia-location.conf;

        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app 192.168.1.128;
        set $upstream_port 8123;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;

    }

    location ~ ^/(api|local|media)/ {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app 192.168.1.128;
        set $upstream_port 8123;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }
}
```

Sau đó restart container `swag`, check log ko có lỗi gì là OK (Mỗi lần thay đổi config trong folder `swag` đều nên restart container để apply)

Giờ test:  
Từ mạng 4G -> `http://MYDOMAIN.duckdns.org` -> tự redirect sang `https://MYDOMAIN.duckdns.org` và access được HASS

Giờ sửa file `docker-compose.yml`: chuyển sang `STAGING=false` để sử dụng production certificate.  

Run `docker-compose up -d`

Check log `swag` như này là OK, đã request certificate thành công:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/swag-cert-success.jpg)

Test truy cập từ mạng 4G -> `http://MYDOMAIN.duckdns.org` -> tự redirect sang `https://MYDOMAIN.duckdns.org` và access được HASS mà khi bạn ấn vào cái ổ khóa trên Browser sẽ thấy màu xanh HTTPS

Vậy là thành công rồi. 

## 1.1. Nếu muốn disalbe tính năng redirect http->https

Giờ ví dụ mình ko muốn nó từ redirect http sang https thì cần sửa file:  
`/opt/swag/config/nginx/site-confs/default`, comment phần này lại:  
```
# redirect all traffic to https
#server {
#    listen 80 default_server;
#    listen [::]:80 default_server;
#    server_name _;
#    return 301 https://$host$request_uri;
#}
```
restart `swag` container, check lại bằng cách từ mạng local cũng dc:  

trước khi sửa nếu bạn run `wget http://MYDOMAIN.duckdns.org`    
sẽ nhận được thông báo kiểu `301 Moved Permanently`...  
Rồi lỗi kiểu port 443 bị refused.  
```
wget http://MYDOMAIN.duckdns.org
Will not apply HSTS. The HSTS database must be a regular and non-world-writable file.
ERROR: could not open HSTS store at '/home/xxx/.wget-hsts'. HSTS will be disabled.
--2022-09-21 20:18:09--  http://MYDOMAIN.duckdns.org/
Resolving MYDOMAIN.duckdns.org (MYDOMAIN.duckdns.org)... 15.xx.xx.32
Connecting to MYDOMAIN.duckdns.org (MYDOMAIN.duckdns.org)|15.xx.xx.32|:80... connected.
HTTP request sent, awaiting response... 301 Moved Permanently
Location: https://MYDOMAIN.duckdns.org/ [following]
--2022-09-21 20:18:09--  https://MYDOMAIN.duckdns.org/
Connecting to MYDOMAIN.duckdns.org (MYDOMAIN.duckdns.org)|15.xx.xx.32|:443... failed: Connection refused.
Resolving MYDOMAIN.duckdns.org (MYDOMAIN.duckdns.org)... 15.xx.xx.32
Connecting to MYDOMAIN.duckdns.org (MYDOMAIN.duckdns.org)|15.xx.xx.32|:443... failed: Connection refused
```
Chú ý chỗ `:80... connected.` chứng tỏ traffic đến port 80 của proxy `swag` rồi xong nó được redirect sang https luôn (Chú ý chỗ này `swag` container của mình đang run trên cả 2 port 80 và 443 nhé)

Sau khi sửa:  
```
$ wget http://MYDOMAIN.duckdns.org 
Will not apply HSTS. The HSTS database must be a regular and non-world-writable file.
ERROR: could not open HSTS store at '/home/xxx/.wget-hsts'. HSTS will be disabled.
--2022-09-21 14:26:50--  http://MYDOMAIN.duckdns.org/
Resolving MYDOMAIN.duckdns.org (MYDOMAIN.duckdns.org)... 15.xx.xx.3x
Connecting to MYDOMAIN.duckdns.org (MYDOMAIN.duckdns.org)|15.xx.xx.3x|:80... failed: Connection refused.
```
vẫn lỗi là do port 80 đang bị refused, có thể do ko có service nào chạy trên port đó.

Tuy nhiên mình khuyên bạn ko nên sửa, việc redirect http->https là tốt cho người dùng. 

# 2. Access from LAN network

Giờ Có 1 vấn đề nhỏ là từ mạng LAN -> `http://MYDOMAIN.duckdns.org` -> thì sẽ ko vào dc HASS 😫 (nó ra cái Router dashboard nhà mạng)

Cứ tưởng do trong ROuter dashboard đang dùng port 80 nên nó tự redirect về, nhưng sau khi đổi port 80 của Router Dashboard thành 8080. Thì giờ từ mạng LAN -> `http://MYDOMAIN.duckdns.org` vẫn ko vào được HASS

Trên Router add 1 rule vào Port Forwarding port 80 của host -> port 80 của RPi Server.  

Mặc dù từ mạng LAN -> `http://MYDOMAIN.duckdns.org:8123` thì OK. -> chứng tỏ Router có activate NAT Loopback trên port 8123

Tiếp thử expose grafana ra port `80:3000` thì cũng OK. Từ mạng LAN -> `http://MYDOMAIN.duckdns.org` (đã disabled redirect https) -> sẽ vào Grafana

Chứng tỏ NAT Loopback có active với port 80. Chỉ ko làm dc với port 443. 

Nhờ có lỗi `301 Moved Permanently` bên trên mà mình hiểu rằng muốn từ mạng local kết nối đến HASS đang ở port 8123 thì cần port forwarding

## 2.1. Dùng Nginx

Sửa file `/opt/swag/config/nginx/site-confs/default`, comment hết phần redirect lại (thực ra đã làm ở phần `1.1`): 
```
# redirect all traffic to https
#server {
#    listen 80 default_server;
#    listen [::]:80 default_server;
#    server_name _;
#    return 301 https://$host$request_uri;
#}
```
Sửa đoạn đầu file `/opt/swag/config/nginx/proxy-confs/homeassistant.subdomain.conf`, add `listen 80;` vào:  
```
~~~
server {
    listen 80;
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name MYDOMAIN.duckdns.org;
~~~
```
Như vậy mình ra lệnh cho Nginx rằng nó phải listen cả port 80 nữa.  
Khi có request đến port 80 nó sẽ ko redirect sang https nữa mà forward đến HASS (port 8123) luôn.  

-> restart `swag` container.  

Test:  
Từ mạng LAN -> `http://MYDOMAIN.duckdns.org` (tab ẩn danh của Chrome) -> access được HASS, chứng tỏ traffic đến port 80 từ trong LAN đã dc forward đến port 8123

Việc này phải chạy trên tab ẩn danh, chứ nếu chạy tab thông thường thì http sẽ bị redirect về https và ko access được.  

Test bằng cách call từ LAN run command:  
```
wget http://MYDOMAIN.duckdns.org
Will not apply HSTS. The HSTS database must be a regular and non-world-writable file.
ERROR: could not open HSTS store at '/home/xxxx/.wget-hsts'. HSTS will be disabled.
--2022-09-21 16:31:59--  http://MYDOMAIN.duckdns.org/
Resolving MYDOMAIN.duckdns.org (MYDOMAIN.duckdns.org)... 1x.x.x.xx3
Connecting to MYDOMAIN.duckdns.org (MYDOMAIN.duckdns.org)|1x.x.x.xx3|:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 9331 (9.1K) [text/html]
Saving to: ‘index.html.4’

index.html.4                  100%[=================================================>]   9.11K  --.-KB/s    in 0.007s

2022-09-21 16:31:59 (1.27 MB/s) - ‘index.html.4’ saved [9331/9331]
```
Tạm chấp nhận. Tuy nhiên cách này có vấn đề:  
- Từ mạng LAN vào `http://MYDOMAIN.duckdns.org` sẽ phải dùng tab ẩn danh, vì nếu ko trình duyệt sẽ tự động redirect sang https và ko vào dc
- Từ mạng external vào cả 2 link đều được `http://MYDOMAIN.duckdns.org` và `https://MYDOMAIN.duckdns.org`, điều này ko tốt về security


## 2.2. Dùng iptables

Cách này được mình thử đầu tiên, nhưng xếp mục 2.2 vì mình ko ưu tiên lắm.  

Do ban đầu tưởng Nginx ko làm được việc port forwarding HASS nên mình đã thử cách 2 này, cố gắng port forward bằng iptables:

https://serverfault.com/questions/140622/how-can-i-port-forward-with-iptables

Nhằm forward traffic từ port 80 của host về port 8123 của HASS:  

```sh
# forward traffic từ LAN (192.168.1.0/24) port 80 sẽ đến ip 192.168.1.128:8123
iptables -t nat -A PREROUTING -p tcp -i wlan0 -s 192.168.1.0/24 --dport 80 -j DNAT --to-destination 192.168.1.128:8123
```

```
# show 
iptables -L -n -t nat
Chain PREROUTING (policy ACCEPT)
target     prot opt source               destination
DOCKER     all  --  0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL
DNAT       tcp  --  192.168.1.0/24       0.0.0.0/0            tcp dpt:80 to:192.168.1.128:8123

Chain INPUT (policy ACCEPT)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination
DOCKER     all  --  0.0.0.0/0           !127.0.0.0/8          ADDRTYPE match dst-type LOCAL

Chain POSTROUTING (policy ACCEPT)
target     prot opt source               destination
MASQUERADE  all  --  172.17.0.0/16        0.0.0.0/0
MASQUERADE  all  --  172.18.0.0/16        0.0.0.0/0
MASQUERADE  tcp  --  172.18.0.2           172.18.0.2           tcp dpt:9000
MASQUERADE  tcp  --  172.18.0.4           172.18.0.4           tcp dpt:8080
MASQUERADE  udp  --  172.18.0.5           172.18.0.5           udp dpt:51820
MASQUERADE  tcp  --  172.18.0.6           172.18.0.6           tcp dpt:9001
MASQUERADE  tcp  --  172.18.0.6           172.18.0.6           tcp dpt:1883
MASQUERADE  tcp  --  172.18.0.7           172.18.0.7           tcp dpt:8200
MASQUERADE  tcp  --  172.18.0.9           172.18.0.9           tcp dpt:9090
MASQUERADE  tcp  --  172.18.0.10          172.18.0.10          tcp dpt:3000
MASQUERADE  tcp  --  172.18.0.8           172.18.0.8           tcp dpt:443

Chain DOCKER (2 references)
target     prot opt source               destination
RETURN     all  --  0.0.0.0/0            0.0.0.0/0
RETURN     all  --  0.0.0.0/0            0.0.0.0/0
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:9000 to:172.18.0.2:9000
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:8080 to:172.18.0.4:8080
DNAT       udp  --  0.0.0.0/0            0.0.0.0/0            udp dpt:51820 to:172.18.0.5:51820
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:9001 to:172.18.0.6:9001
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:1883 to:172.18.0.6:1883
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:8200 to:172.18.0.7:8200
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:9090 to:172.18.0.9:9090
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:3000 to:172.18.0.10:3000
DNAT       tcp  --  0.0.0.0/0            0.0.0.0/0            tcp dpt:443 to:172.18.0.8:443
```

Từ mạng LAN -> `http://MYDOMAIN.duckdns.org` (tab ẩn danh của Chrome) -> access được HASS, chứng tỏ traffic đến port 80 từ trong LAN đã dc forward đến port 8123

Việc này phải chạy trên tab ẩn danh, chứ nếu chạy tab thông thường thì http sẽ bị redirect về https và ko access được.  

test bằng cách call từ LAN run command:  

```
wget http://MYDOMAIN.duckdns.org
Will not apply HSTS. The HSTS database must be a regular and non-world-writable file.
ERROR: could not open HSTS store at '/home/xxxx/.wget-hsts'. HSTS will be disabled.
--2022-09-21 16:31:59--  http://MYDOMAIN.duckdns.org/
Resolving MYDOMAIN.duckdns.org (MYDOMAIN.duckdns.org)... 1x.x.x.xx3
Connecting to MYDOMAIN.duckdns.org (MYDOMAIN.duckdns.org)|1x.x.x.xx3|:80... connected.
HTTP request sent, awaiting response... 200 OK
Length: 9331 (9.1K) [text/html]
Saving to: ‘index.html.4’

index.html.4                  100%[=================================================>]   9.11K  --.-KB/s    in 0.007s

2022-09-21 16:31:59 (1.27 MB/s) - ‘index.html.4’ saved [9331/9331]

```

Command tiếp theo mình thấy ko cần lắm, vì ngay sau khi tạo DNAT rule bên trên, mọi thứ có vẻ đã OK. (nhưng trên Stackoverflow họ vẫn có):  

```sh
iptables -A FORWARD -p tcp -d 192.168.1.128 --dport 8123 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
```
mà mình xóa rule này đi thì cũng ko sao.

Như vậy Cách này (dùng Iptables) là "phần nào" chấp nhận được, nó giải quyết được vấn đề của Cách Nginx là: iptable rule chặn external network connect đến port 80 (link `http://MYDOMAIN.duckdns.org`) hoặc nó sẽ redirect sang https luôn.  
Nhưng cách này vẫn còn vấn đề:  
- Từ mạng LAN vào `http://MYDOMAIN.duckdns.org` sẽ phải dùng tab ẩn danh, vì nếu ko trình duyệt sẽ tự động redirect sang https và ko vào dc.  

Mình nghĩ, nếu có cách nào đó để setup trên Nginx để ko redirect http->https khi dùng mạng LAN thì tốt. Cái này mình đang tìm hiểu..

## 2.3. Kết luận

Tóm lại dù cách 2 (dùng Iptables) giải quyết dc 1 vấn đề của cách 1 (dùng Nginx), mình vẫn ko recommend việc sửa iptables để forward traffic lắm. Bởi vì đã từng có lần mình reset lại server RPi, hầu như tất cả các rule trên iptables đều bị xóa hết. Mà RPi của mình lại đang ở trong DMZ, gây risk về security.

Tìm được bài này về việc save và reload iptables rule on reboots: https://askubuntu.com/questions/119393/how-to-save-rules-of-the-iptables

```sh
sudo netfilter-persistent save
sudo netfilter-persistent reload
```
Tuy nhiên chưa thử restart xem có mất rule ko, hoặc có cần run command để reload rule hay ko?

Vậy nên mình vẫn dùng cách 1 (Nginx), giữ 2 link để dùng:  

1: `http://MYDOMAIN.duckdns.org` redirect `https://MYDOMAIN.duckdns.org` -> để integrate với Alexa

2: `http://MYDOMAIN.duckdns.org:8123` để gia đình sử dụng (link này thì do có NAT loopback trên port 8123 nên từ mạng 4G hay LAN đều access được hết)

Ngoài ra: Mình tự hỏi là nếu không thể Nat Loopback được port 443 được thì việc mình đưa RPi ra DMZ có ý nghĩa gì? Có lẽ thử disable DMZ đi xem sao?  

-> Thì ngay sau khi disable DMZ, từ External network sẽ không thể connect đến `https://MYDOMAIN.duckdns.org` và `http://MYDOMAIN.duckdns.org`. Còn connect đến `http://MYDOMAIN.duckdns.org:8123` vẫn ok.  
Như vậy là vừa phải đưa ra DMZ, vừa phải kết hợp Port Forwarding trên Router.  
Mà đã đưa ra DMZ là phải kết hợp thêm các rule trên iptables để filter traffic đi vào nhé (đã làm ở bài trước [Part2](../../posts/encrypt-setup-home-assistant-on-raspberry-pi-p2-dmz/)  ). 


# 3. Nếu muốn expose thêm 1 service nào đó để test

Giả dụ muốn expose thêm 1 web Grafana ra ngoài, kiểu `https://grafana.MYDOMAIN.duckdns.org` (tuy nhiên sẽ ko có Browser secured vì cert chỉ valid với domain `https://MYDOMAIN.duckdns.org` thôi )

Giả sử grafana đang run trong Docker container port 3000, container name là `grafana`

Trong `swag` config folder sửa file `/opt/swag/config/nginx/proxy-confs/grafana.subdomain.conf.sample`, rename thành `/opt/swag/config/nginx/proxy-confs/grafana.subdomain.conf` và sửa nội dung file đó:  
```
thực ra hầu như ko cần sửa, chỉ cần check lại xem đúng với case của mình chưa thôi
```
-> restart `swag` container.  

Giờ sẽ access từ mạng 4G vào `https://grafana.MYDOMAIN.duckdns.org` là sẽ được. Tất nhiên access từ mạng LAN sẽ ko đc đâu nhé.
Mạng LAN thì vẫn dùng IP thôi 😫

Đây là sự tiện lợi của NGINX, bạn chỉ cần sửa trong nginx mà ko cần sửa gì bên ngoài Router, iptables cả

# 4. Fail2ban

## 4.1. Overview về fail2ban

Trong `swag` container đã tích hợp sẵn tính năng `fai2ban`:  
https://www.fail2ban.org/wiki/index.php/Commands

This container includes fail2ban set up with 5 jails by default:   
- nginx-http-auth  
- nginx-badbots  
- nginx-botsearch  
- nginx-deny   
- nginx-unauthorized  

To enable or disable other jails, modify the file `/config/fail2ban/jail.local`

To modify filters and actions, instead of editing the `.conf` files, create `.local` files with the same name and edit those because .conf files get overwritten when the actions and filters are updated. .local files will append whatever's in the `.conf` files (ie. `nginx-http-auth.conf` --> `nginx-http-auth.local`)

You can check which jails are active via:  
```sh
docker exec -it swag fail2ban-client status
```
You can check the status of a specific jail via:  
```sh
docker exec -it swag fail2ban-client status <jail name>
```  
You can unban an IP via:  
```sh
docker exec -it swag fail2ban-client set <jail name> unbanip <IP>
```
A list of commands can be found here: https://www.fail2ban.org/wiki/index.php/Commands

## 4.2. Troubleshoot 2025/Jan/08

Gần đây phát hiện bị scan nginx, xem trong log `error.log` sẽ thấy các request này:

```s
$ tail -n 200f error.log

2025/01/07 04:56:07 [crit] 4805#4805: *27040 SSL_do_handshake() failed (SSL: error:141CF06C:SSL routines:tls_parse_ctos_key_share:bad key share) while SSL handshaking, client: 104.152.52.180, server: 0.0.0.0:443
2025/01/07 06:23:13 [crit] 4805#4805: *27069 SSL_do_handshake() failed (SSL: error:141CF06C:SSL routines:tls_parse_ctos_key_share:bad key share) while SSL handshaking, client: 209.126.83.235, server: 0.0.0.0:443
2025/01/07 06:34:25 [crit] 4805#4805: *27085 SSL_do_handshake() failed (SSL: error:141CF06C:SSL routines:tls_parse_ctos_key_share:bad key share) while SSL handshaking, client: 57.129.64.10, server: 0.0.0.0:443
2025/01/07 06:55:12 [crit] 4805#4805: *27101 SSL_do_handshake() failed (SSL: error:141CF06C:SSL routines:tls_parse_ctos_key_share:bad key share) while SSL handshaking, client: 206.81.24.227, server: 0.0.0.0:443
2025/01/07 06:55:15 [error] 4805#4805: *27119 FastCGI sent in stderr: "Primary script unknown" while reading response header from upstream, client: 206.81.24.227, server: _, request: "GET /info.php HTTP/1.1", upstream: "fastcgi://127.0.0.1:9000", host: "MY_SERVER_IP"

2025/01/08 09:39:30 [crit] 277#277: *843 SSL_do_handshake() failed (SSL: error:141CF06C:SSL routines:tls_parse_ctos_key_share:bad key share) while SSL handshaking, client: 157.230.226.170, server: 0.0.0.0:443
2025/01/08 11:02:58 [crit] 277#277: *966 SSL_do_handshake() failed (SSL: error:141CF06C:SSL routines:tls_parse_ctos_key_share:bad key share) while SSL handshaking, client: 44.220.188.189, server: 0.0.0.0:443
2025/01/08 12:19:58 [error] 277#277: *1607 FastCGI sent in stderr: "Primary script unknown" while reading response header from upstream, client: 47.236.54.136, server: _, request: "GET /vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1", upstream: "fastcgi://127.0.0.1:9000", host: "MY_SERVER_IP:443"
2025/01/08 12:19:59 [error] 277#277: *1607 FastCGI sent in stderr: "Primary script unknown" while reading response header from upstream, client: 47.236.54.136, server: _, request: "GET /vendor/phpunit/phpunit/Util/PHP/eval-stdin.php HTTP/1.1", upstream: "fastcgi://127.0.0.1:9000", host: "MY_SERVER_IP:443"
2025/01/08 12:20:00 [error] 277#277: *1607 FastCGI sent in stderr: "Primary script unknown" while reading response header from upstream, client: 47.236.54.136, server: _, request: "GET /vendor/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1", upstream: "fastcgi://127.0.0.1:9000", host: "MY_SERVER_IP:443"
2025/01/08 12:20:02 [error] 277#277: *1607 FastCGI sent in stderr: "Primary script unknown" while reading response header from upstream, client: 47.236.54.136, server: _, request: "GET /vendor/phpunit/Util/PHP/eval-stdin.php HTTP/1.1", upstream: "fastcgi://127.0.0.1:9000", host: "MY_SERVER_IP:443"
2025/01/08 12:20:04 [error] 277#277: *1607 FastCGI sent in stderr: "Primary script unknown" while reading response header from upstream, client: 47.236.54.136, server: _, request: "GET /vendor/phpunit/phpunit/LICENSE/eval-stdin.php HTTP/1.1", upstream: "fastcgi://127.0.0.1:9000", host: "MY_SERVER_IP:443"
2025/01/08 12:20:05 [error] 277#277: *1607 FastCGI sent in stderr: "Primary script unknown" while reading response header from upstream, client: 47.236.54.136, server: _, request: "GET /vendor/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1", upstream: "fastcgi://127.0.0.1:9000", host: "MY_SERVER_IP:443"
2025/01/08 12:20:07 [error] 277#277: *1607 FastCGI sent in stderr: "Primary script unknown" while reading response header from upstream, client: 47.236.54.136, server: _, request: "GET /phpunit/phpunit/src/Util/PHP/eval-stdin.php HTTP/1.1", upstream: "fastcgi://127.0.0.1:9000", host: "MY_SERVER_IP:443"
```

```s
$ tail -n 200f access.log

44.220.188.189 - - [08/Jan/2025:11:02:55 +0700] "GET / HTTP/1.1" 200 1345 "-" "Mozilla/5.0 (Windows NT 6.2;en-US) AppleWebKit/537.32.36 (KHTML, live Gecko) Chrome/54.0.3048.71 Safari/537.32"
44.220.188.189 - - [08/Jan/2025:11:03:15 +0700] "\x15\x03\x01\x00\x02\x02P" 400 150 "-" "-"
44.220.188.189 - - [08/Jan/2025:11:03:17 +0700] "\x15\x03\x01\x00\x02\x02P" 400 150 "-" "-"
103.161.18.132 - - [09/Jan/2025:08:51:20 +0700] "GET /Media/.env HTTP/2.0" 200 1345 "-" "curl/7.81.0"
101.96.50.45 - - [09/Jan/2025:08:52:17 +0700] "GET /robots.txt HTTP/2.0" 200 1345 "-" "curl/7.81.0"
64.62.156.59 - - [09/Jan/2025:08:54:02 +0700] "GET /favicon.ico HTTP/1.1" 200 1345 "-" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15"
64.62.156.56 - - [09/Jan/2025:08:55:43 +0700] "GET / HTTP/1.1" 200 1345 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36 Edg/125.0.0.0"
185.142.236.43 - - [09/Jan/2025:08:58:27 +0700] "GET / HTTP/1.1" 200 1345 "-" "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36"
64.62.156.52 - - [09/Jan/2025:09:00:50 +0700] "GET /geoserver/web/ HTTP/1.1" 200 1345 "-" "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:124.0) Gecko/20100101 Firefox/124.0"
64.62.156.55 - - [09/Jan/2025:09:03:21 +0700] "GET /.git/config HTTP/1.1" 200 1345 "-" "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/109.0"
```

Hầu hết là từ các IP lạ, chứng tỏ có người/bot đang cố scan website của mình. 1 số link nhưng ko thấy cách giải quyết:  
https://serverfault.com/questions/1098753/ssl-do-handshake-failed-ssl-error141cf06cssl-routinestls-parse-ctos-key-s  
https://stackoverflow.com/questions/71895320/ssl-do-handshake-failed-ssl-error141cf06cssl-routinestls-parse-ctos-key-s  
https://stackoverflow.com/questions/65854933/nginx-ssl-error141cf06cssl-routinestls-parse-ctos-key-sharebad-key-share/67424645#67424645  
https://serverfault.com/questions/905011/nginx-ssl-do-handshake-failed-ssl-error1417d18cssl/905019  

**Step 1: Tái hiện lỗi xuất hiện trong `error.log`**

```sh
$ curl https://1.ubuntuoc.duckdns.org/phpinfo.php
File not found.
```

command trên sẽ trả ra log lỗi trong `nginx/log/error.log`:

```s
2025/01/09 09:10:18 [error] 279#279: *8 FastCGI sent in stderr: "Primary script unknown" while reading response header from upstream, client: 101.96.50.45, server: _, request: "GET /phpinfo.php HTTP/2.0", upstream: "fastcgi://127.0.0.1:9000", host: "1.ubuntuoc.duckdns.org"
```

Nguyên nhân là do trong `config/nginx/site-confs/default.conf` đang setting:

```s
    location ~ ^(.+\.php)(.*)$ {
        fastcgi_split_path_info ^(.+\.php)(.*)$;
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
    }
```

Solution: dùng fail2ban để block các Ip trên. Cụ thể tạo thêm file `fail2ban/filter.d/nginx-custom01-hoang.conf`:

```s
# fail2ban filter configuration for nginx
[Definition]
failregex = .*SSL_do_handshake\(\) failed.*client: <HOST>,.*
            .*FastCGI sent in stderr: "Primary script unknown".*client: <HOST>
ignoreregex =
datepattern = {^LN-BEG}
```

Sửa file `fail2ban/jail.local`, add thêm:

```s
[nginx-custom01-hoang]
enabled  = true
port     = http,https
filter   = nginx-custom01-hoang
logpath  = /config/log/nginx/error.log
maxretry = 1 # Lỗi 1 lần thôi là cũng bị ban
bantime = 30d # Ban hẳn 30 ngày cho chắc cú
```

Bên cạnh đó, trong `config/nginx/site-confs/default.conf` mình sửa thành port 9111:

```s
    location ~ ^(.+\.php)(.*)$ {
        fastcgi_split_path_info ^(.+\.php)(.*)$;
        fastcgi_pass 127.0.0.1:9111;
        fastcgi_index index.php;
        include /etc/nginx/fastcgi_params;
    }
```

Sau này nếu có tạo app nào đó thì ko nên dùng port 9111 để đề phòng nguy cơ có người scan lấy được index.php của app đang chạy trên port 9111.

**Step 2: Tái hiện các request xuất hiện trong access.log**, 

nó sẽ hiển thị ra Page `Welcome to your SWAG instance`:

```sh

$ curl https://ubuntuoc.duckdns.org
<html>
    <head>
        <title>Welcome to your SWAG instance</title>
        <style>
...

$ curl https://1.ubuntuoc.duckdns.org/robots.txt
<html>
    <head>
        <title>Welcome to your SWAG instance</title>
        <style>
...
```

Solution: https://forum.openmediavault.org/index.php?thread/46242-secure-your-swag-nginx-server-docker-get-rid-of-the-default-page/

Sửa file `nginx/site-confs/default.conf`:
```s
server {
    # Hoang edit
    add_header X-Robots-Tag "noindex, nofollow, nosnippet, noarchive";
.........

    location / {
        return 444;
    }
.........
```

Giờ nếu có request đến page `Welcome to your SWAG instance` thì sẽ bị trả về lỗi 444:

```sh
config/log/nginx$ tail -n 100 access.log

103.161.18.132 - - [09/Jan/2025:09:05:52 +0700] "GET /robots.txt HTTP/2.0" 444 0 "-" "curl/7.81.0"
101.96.50.45 - - [09/Jan/2025:09:06:23 +0700] "GET /Media/.env HTTP/2.0" 444 0 "-" "curl/7.81.0"
101.96.50.45 - - [09/Jan/2025:09:07:57 +0700] "GET /.git/config HTTP/2.0" 444 0 "-" "curl/7.81.0"
101.96.50.45 - - [09/Jan/2025:09:10:18 +0700] "GET /phpinfo.php HTTP/2.0" 404 16 "-" "curl/7.81.0"
103.161.18.132 - - [09/Jan/2025:09:10:35 +0700] "GET /phpinfo.php HTTP/2.0" 404 16 "-" "curl/7.81.0"
```

Nếu họ curl đến thì cũng sẽ trả về lỗi như này:

```sh
# REQUEST đến root dùng HTTP
$ curl http://ubuntuoc.duckdns.org/
curl: (7) Failed to connect to ubuntuoc.duckdns.org port 80 after 204 ms: No route to host

# REQUEST đến root dùng HTTPS
$ curl https://ubuntuoc.duckdns.org/
curl: (60) SSL: no alternative certificate subject name matches target host name 'ubuntuoc.duckdns.org'
More details here: https://curl.se/docs/sslcerts.html
curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.

# REQUEST đến sub domain (ko tồn tại) dùng HTTP
$ curl http://1.ubuntuoc.duckdns.org/
curl: (7) Failed to connect to 1.ubuntuoc.duckdns.org port 80 after 705 ms: No route to host

# REQUEST đến sub domain (ko tồn tại) dùng HTTPS
$ curl https://1.ubuntuoc.duckdns.org/
curl: (92) HTTP/2 stream 0 was not closed cleanly: PROTOCOL_ERROR (err 1)
```


# CREDIT

1 ví dụ về việc dùng Nginx làm reverse proxy cho 2 app trong Docker:  
https://www.bogotobogo.com/DevOps/Docker/Docker-Compose-Nginx-Reverse-Proxy-Multiple-Containers.php  

1 bài viết về dùng Swag với Hass để tạo https auto-renewal cert. Swag có sẵn Nginx:  
https://community.home-assistant.io/t/nginx-reverse-proxy-set-up-guide-docker/54802  
https://github.com/linuxserver/docker-swag  
https://pentacent.medium.com/nginx-and-lets-encrypt-with-docker-in-less-than-5-minutes-b4b8a60d3a71
https://hub.docker.com/r/linuxserver/swag  

1 bài về sử dụng Traefik làm reverse proxy thay cho Nginx:  
https://community.home-assistant.io/t/help-multiple-containers-nextcloud-ha-letsencrypt/46725/5  
https://thesmarthomejourney.com/2021/11/08/traefik-1-reverse-proxy-setup/  
https://thesmarthomejourney.com/2022/01/26/traefik-force-cert-renewal/#Traefik_and_lets_encrypt  
https://community.home-assistant.io/t/help-with-ha-in-a-docker-container-and-lets-encrypt/51595  

1 chú ý khi setting hass with certificate: 
https://community.home-assistant.io/t/help-with-ha-in-a-docker-container-and-lets-encrypt/51595/8  
https://community.home-assistant.io/t/configure-ssl-with-docker/196878  

2 bài về dùng nginx và lesencript docker mà ko phải là swag:  
https://pentacent.medium.com/nginx-and-lets-encrypt-with-docker-in-less-than-5-minutes-b4b8a60d3a71  
Github: https://github.com/wmnnd/nginx-certbot  
tuy nhiên có vẻ đã lâu ko update gì (từ 2020)

bài này thấy viết dễ hiểu và khá clear:  
https://evgeniy-khyst.com/letsencrypt-docker-compose/  
https://github.com/evgeniy-khist/letsencrypt-docker-compose  

https://community.home-assistant.io/t/remote-access-with-docker/314345  

https://serverfault.com/questions/140622/how-can-i-port-forward-with-iptables

https://askubuntu.com/questions/119393/how-to-save-rules-of-the-iptables