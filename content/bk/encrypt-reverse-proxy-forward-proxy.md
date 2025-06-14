---
title: "Reverse proxy and Forward proxy"
date: 2022-12-06T23:09:57+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Notes]
#tags: [Proxy]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Đây chỉ là note lại để nhớ về sau, khác nhau giữa Reverse Proxy và Forward Proxy."
---

# 1. Story

Trên thực tế có 2 loại proxy là Reverse Proxy (ex: Nginx) và Forward proxy (ex: Tinyproxy)

Reverse Proxy được config ở phía Server để route các traffic từ Client đến backend phù hợp. Client sẽ ko biết về sự tồn tại của reverse proxy (Nginx).

Forward Proxy được config ở phía Client để control traffic đến và đi ra khỏi network của Client. Server sẽ ko biết về sự tồn tại của forward proxy.   

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/reverse-proxy-forward-proxy.jpg)

**Use cases của Forward Proxy**: 

- Forward proxy sẽ monitor các traffic incoming và outgoing khỏi network của Client (hoạt động như firewall), trong 1 số công ty họ sẽ chặn Internet và chỉ cho nhân viên lướt web khi đã setup proxy, proxy này sẽ chặn 1 số website như facebook.com chẳng hạn.

- Nếu bạn gửi request liên tục đến 1 server, khả năng cao IP của bạn sẽ bị block vì phía Server phát hiện bạn đang crawl data của họ. Khi đó nếu bạn setup nhiều proxy server ở phía trước IP của bạn, thì cái mà Server phát hiện và block sẽ là các IP của Proxy server chứ ko phải IP thật sự của bạn.  

- 1 số trang web sẽ chặn các IP nước ngoài request đến. Ví dụ 1 web của VN chặn các IP từ nước ngoài. Vậy thì các AWS Lambda của bạn call từ US, Singapore, ... sẽ bị chặn hết. Khi đó bạn cần setup 1 proxy server có IP ở VN, rồi cho Lambda call qua các proxy server đó. Như vậy website sẽ coi các request từ Lambda dc gửi tới từ VN.  

**Use cases của Reverse Proxy**: 

- Để làm cache content qua đó sẽ reduce load traffic on Server qua đó tăng trải nghiệm người dùng vì request nhanh hơn.

- Ngăn chặn data breach, bằng cách encrypt transmitted data in network traffic, reverse proxy sẽ giúp web server bảo vệ dữ liệu ng dùng.  

- Load balancing, reverse proxy giúp cân bằng tải cho các server  


> Reverse proxy is for server end and something client doesn't really see or think about. It's to retrieve content from the backend servers and hand to the client. 

> Forward proxy is something the client sets up in order to connect to rest of the internet. In turn, the server may potentially know nothing about your forward proxy.

> Nginx is originally designed to be a reverse proxy, and not a forward proxy. But it can still be used as a forward one. That's why you probably couldn't find much configuration for it.

> This is more a theory answer as I've never done this myself, but a configuration like following should work.

```
server {
    listen       8888;

    location / {
        resolver 8.8.8.8; # may or may not be necessary.
        proxy_pass http://$http_host$uri$is_args$args;
    }
}
```

> This is just the important bits, you'll need to configure the rest.

> The idea is that the proxy_pass will pass to a variable host rather than a predefined one. So if you request http://example.com/foo?bar, your http header will include host of example.com. This will make your proxy_pass retrieve data from http://example.com/foo?bar.

> The document that you linked is using it as a reverse proxy. It would be equivalent to

```
proxy_pass http://localhost:80;
```

# 2. Practice with Forward Proxy

Đầu tiên là setup 1 Forward proxy server (mình chọn tinyproxy):  
```sh
mkdir tinyproxy & mkdir tinyproxy/data
```

tạo file `tinyproxy/Dockerfile`:  
```yml
#
# Dockerfile for tinyproxy
#

FROM alpine:3
MAINTAINER EasyPi Software Foundation

RUN set -xe \
    && apk add --no-cache tinyproxy \
    && sed -i -e '/^Allow /s/^/#/' \
              -e '/^ConnectPort /s/^/#/' \
              -e '/^#DisableViaHeader /s/^#//' \
              /etc/tinyproxy/tinyproxy.conf

VOLUME /etc/tinyproxy
EXPOSE 8888

CMD ["tinyproxy", "-d"]

```
build image `tinyproxy`:  
```sh
docker build -t tinyproxy .
```

Tạo file `tinyproxy/data/tinyproxy.conf`:  
Copy từ đây: https://github.com/vimagick/dockerfiles/blob/master/tinyproxy/data/tinyproxy.conf   

Uncomment dòng `#BasicAuth user password`, sửa thành user/pass mà bạn mong muốn,  
**chú ý** chỉ dùng các ký tự sau cho password `-a-z0-9._`:  
```
BasicAuth youruser1 yourpassword123
```

Tạo file `tinyproxy/docker-compose.yml`:  
```yml
version: "3.8"
services:
  tinyproxy:
    container_name: tinyproxy
    image: tinyproxy
    ports:
      - "8888:8888"
    volumes:
      - ./data:/etc/tinyproxy
    restart: unless-stopped
```

Run:  
```sh
cd tinyproxy/
docker-compose up -d
```

Test:  
```sh
curl -x youruser:yourpassword@127.0.0.1:8888 https://ifconfig.co
```

Giờ *Bằng 1 cách nào đó*, hãy open port 8888 để các request từ internet có thể đến đc con server đang cài tinyproxy của bạn.🤣

Đoạn code sau trên AWS Lambda sẽ giúp bạn send request thông qua Proxy trên:  
(Chú ý Python của mình 3.9, `requests` layer dùng lại từ 3.6)  
(Mình đã set biến môi trường proxy = `http://youruser1:yourpassword123@133.215.12.13:8888`)  
```sh
import os, requests
from requests.auth import HTTPProxyAuth

def lambda_handler(event, context):
    # Get Lambda environment variables
    proxy_string = os.environ.get('proxy')

    s = requests.Session()
    url = 'https://ifconfig.co/json'
    response = s.get(url, proxies={"http": proxy_string, "https": proxy_string}) 
    ip = response.json()['ip']
    print('Your IP is {}'.format(ip))
    print(response.status_code)
```
Log:  
```
START RequestId: d344caxxxxxxxxxxxxxxxxx814ea Version: $LATEST
Your IP is 133.215.12.13
200
END RequestId: d344caxxxxxxxxxxxxxxxxx814ea
REPORT RequestId: d344caxxxxxxxxxxxxxxxxx814ea	Duration: 679.03 ms	Billed Duration: 680 ms	Memory Size: 128 MB	Max Memory Used: 51 MB	Init Duration: 412.09 ms
```

Như vậy các request từ Lambda đến 1 endpoint nào đó, sẽ đi qua tinyproxy của mình. Điều này sẽ có ích nếu bạn muốn crawl data từ dâu đó.  

Trên mạng có 1 số chỗ free proxy IP nhưng ko chắc có nên dùng ko:  
https://pastebin.com/raw/VJwVkqRT  
https://proxyscrape.com/free-proxy-list  
https://www.freeproxylists.net/  


# 3. CREDIT

giải thích forward proxy and reverse proxy:  
https://stackoverflow.com/a/46083709/9922066  
https://research.aimultiple.com/forward-vs-reverse-proxy/  

so sánh tinyproxy với nginx về việc forward proxy:  
https://serverfault.com/questions/168151/multi-threaded-alternative-to-tinyproxy

nginx proxy with Basic Auth:  
https://serverfault.com/a/230754/589181

Nginx đc design cho reverse proxy, ko officially support forward proxy:  
https://superuser.com/a/604353

1 cách để dùng nginx để làm forward proxy là dùng: `ngx_http_proxy_connect_module`, nhưng cần build lại, ko chắc dùng dc với swag:  
https://superuser.com/a/1270790,  
https://github.com/reiz/nginx_proxy

https://stackoverflow.com/questions/34025964/python-requests-api-using-proxy-for-https-request-get-407-proxy-authentication-r

https://github.com/vimagick/dockerfiles/blob/master/tinyproxy