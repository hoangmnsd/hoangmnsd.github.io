---
title: "Setup SSO (Single Sign On) with Keycloak + VouchProxy/Oauth2Proxy + Nginx"
date: 2023-08-20T23:09:57+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Keycloak,SSO,VouchProxy,Oauth2Proxy,Swag,Docker,Nginx,Postgresql]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Khi bạn cần phải tích hợp nhiều application mà không muốn mỗi app dùng 1 account riêng..."
---
# 1. Story

Giả sử bạn cần tích hợp nhiều application khác nhau. Có app thì có chức năng login, có app thì không. Nếu mỗi app dùng 1 ngôn ngữ riêng (python, react, java...) thì việc xây dựng chức năng login riêng sẽ tốn effort, nếu app đó là của người khác maintain và họ nghỉ việc rồi thì còn tốn effort tìm hiểu bussiness của app đó. 

Đó là từ góc nhìn của dev. Còn từ phía user, nếu mỗi app lại phải nhớ 1 account riêng thì sẽ rất khó, có thể ban đầu bạn set chung 1 account, nhưng sau 1 thời gian user sử dụng sẽ đổi password, và họ sẽ phải nhớ hết.  

Thế nên việc có 1 hệ thống Authen chung cho các app là rất cần thiết. 

Mình đang từng nói vấn đề này trong bài [Notes About Docker OpenLDAP](../../posts/encrypt-notes-about-docker-openldap).  
Tuy nhiên việc setup OpenLDAP không chỉ setup hệ thống Authen xong là xong, mà bản thân Application còn phải được develop theo hướng có support tích hợp LDAP nữa. 

Vì thế mà bài này mình giới thiệu 1 giải pháp khác, là dùng Keycloak + Vouch Proxy + Nginx.  

Giải pháp này giúp bạn chỉ cần setup chủ yếu ở Nginx. Các app khác thì ko cần phải code thêm gì cả. Single Sign On (SSO) là bạn chỉ cần sign-on 1 lần, và sẽ truy cập được tất cả các App đằng sau hệ sinh thái đó.    

Về cơ bản bạn có thể xem hình vẽ này của Vouch Proxy để hiểu cơ chế: https://github.com/vouch/vouch-proxy#what-vouch-proxy-does

Hình này mình vẽ riêng bao gồm các thành phần mình dùng trong bài viết này:  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-vouch-swagnginx-overview.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-oauth2-swagnginx-overview.jpg)

Về giải thích Flow, vì flow trên đơn giản nên mình ko giải thích gì thêm, nhưng Vouch Proxy có giải thích ở đây. Cũng tương tự với suy nghĩ của mình: https://github.com/vouch/vouch-proxy#the-flow-of-login-and-authentication-using-google-oauth

Giới thiệu qua về các thành phần:  

- Swag (Nginx): chính là https://github.com/linuxserver/docker-swag, support Nginx và Letsencrypt rất tiện dụng. Mình đã viết về cách config nó trong bài [Expose HASS to internet](../../posts/encrypt-setup-home-assistant-on-raspberry-pi-p5-restore/#7-expose-hass-to-internet). Nên bài này ko làm chi tiết nữa mà sẽ đi nhanh.  

- KeyCloak: https://github.com/keycloak/keycloak. Là 1 open source Identity Provider - IdP, giống như Okta, Github, AzureAD, OAuth... Nơi lưu trữ các user account của bạn. 

- Vouch Proxy: https://github.com/vouch/vouch-proxy. Là 1 Open SSO solution cho Nginx support việc tích hợp các app của bạn với IdP.  

- Oauth2 Proxy: https://github.com/oauth2-proxy/oauth2-proxy. Tương tự như VouchProxy nhưng được nhiều star hơn, hỗ trợ nhiều tính năng hơn. 

- App1, App2: Ở đây mình sẽ dùng 1 Hello World docker image (viết = Python FastAPI) very simple. Clone thành 2 App để test. 

# 2. Setup Keycloak + Nginx + VouchProxy

Sau khi setup xong thì bạn sẽ có 1 cấu trúc folder như này:  

```sh
├── helloworld-python/
│   └── app/
├── vouch-proxy/
│   └── config/
└── keycloak-lab/
│   ├── config/
│   ├── postgres_data/
└── swag/
│   └── config/
└── docker-compose.yml # All configurations list here
```

## 2.1. Setup App1, App2 

Clone source ở đây về, sau đó ta sẽ build 2 image để run 2 App độc lập. Chúng ta sẽ run từ Docker Compose.  

```sh
git clone https://github.com/hoangmnsd/helloworld-python.git
```

### 2.1.1. Build image cho App1

Chú ý - Nội dung file `helloworld-python/app/main.py`:  

```py
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def get():
    return "Hello World!"
```

```
$ cd helloworld-python/
$ docker build -t helloworld-python:0.0.1 .

$ docker images | grep helloworld
helloworld-python                         0.0.1                   43f37ef499c0   13 hours ago    1.02GB
```

Tạo file `docker-compose.yml` cho App1:  

```yml
version: '3.0'

services:
  helloworld-python:
    container_name: helloworld-python
    image: helloworld-python:0.0.1
    ports:
      - 8081:4040
```

Run bằng docker-compose: `docker-compose up -d` 

Test thử được như dưới là OK: 

```
$ docker ps | grep helloworld
5230e6229c86   helloworld-python:0.0.1                      "uvicorn app.main:ap…"   13 hours ago   Up 13 hours             0.0.0.0:8081->4040/tcp, :::8081->4040/tcp             helloworld-python

$ curl localhost:8081
"Hello World!"
```

### 2.1.2. Build image cho App2

Sửa nội dung file `helloworld-python/app/main.py`:  

```py
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def get():
    return "こんにちは～!"
```

```
$ cd helloworld-python/
$ docker build -t helloworld-python:0.0.2 .

$ docker images | grep helloworld
helloworld-python                         0.0.2                   664f425c925f   13 hours ago    1.02GB
```

Sửa file `docker-compose.yml` cho App2:  

```yml
version: '3.0'

services:
  helloworld-python:
    container_name: helloworld-python
    image: helloworld-python:0.0.1
    ports:
      - 8081:4040

  konnichiwa-python:
    container_name: konnichiwa-python
    image: helloworld-python:0.0.2
    ports:
      - 8082:4040
```

Run bằng docker-compose: `docker-compose up -d` 

Test thử được như dưới là OK: 

```
$ docker ps | grep helloworld
99a839d479c8   helloworld-python:0.0.2                      "uvicorn app.main:ap…"   13 hours ago   Up 13 hours             0.0.0.0:8082->4040/tcp, :::8082->4040/tcp             konnichiwa-python

$ curl localhost:8082
"こんにちは～!"

$ curl localhost:8081
"Hello World!"
```

Như vậy cả App1 `helloworld-python` và App2 `konnichiwa-python` đều đã run local OK.

## 2.2. Expose App1, App2 to internet by Swag

Phần này để sử dụng Swag cần có domain trước. Mình dùng DuckDns vì nó free. (Tất nhiên bạn có thể ko sử dụng DuckDns, mà dùng 1 service khác.)

Trước khi làm phần này cần hoàn thành 1 số step:  
- Đăng ký domain trên duckdns.org. (Giả sử `YOUR_DOMAIN.duckdns.org`)
- Cập nhật public IP của server trên duckdns.org.  
- Có TOKEN mà duckdns.org cung cấp.  

Sửa file `docker-compose.yml`, add thêm phần swag vào như này: 

(chú ý sửa `YOUR_DOMAIN` = domain của bạn, `YOUR_DUCKDNS_TOKENNNnn` bằng token của bạn, `YOUR_EMAL@gmail.com` bằng email của bạn )
```yml
version: '3.0'

services:
  helloworld-python:
    container_name: helloworld-python
    image: helloworld-python:0.0.1
    ports:
      - 8081:4040

  konnichiwa-python:
    container_name: konnichiwa-python
    image: helloworld-python:0.0.2
    ports:
      - 8082:4040

  swag:
    image: lscr.io/linuxserver/swag:1.30.0
    container_name: swag
    cap_add:
      - NET_ADMIN
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Ho_Chi_Minh
      - URL=YOUR_DOMAIN.duckdns.org # SỬA THEO DOMAIN CỦA BẠN
      - VALIDATION=duckdns
      - SUBDOMAINS=wildcard # CHỈ CÁC SUB DOMAIN XXX.YOUR_DOMAIN.duckdns.org LÀ có CERT HTTPS VALID
      - CERTPROVIDER= #optional
      - DNSPLUGIN=duckdns #optional
      - PROPAGATION= #optional
      - DUCKDNSTOKEN=YOUR_DUCKDNS_TOKENNNnn # SỬA THEO DUCKDNS TOKEN BẠN LẤY ĐƯỢC TRÊN DUCKDNS
      - EMAIL=YOUR_EMAL@gmail.com # SỬA THÀNH MAIL CỦA BẠN
      - ONLY_SUBDOMAINS=true # CHỈ CÁC SUB DOMAIN XXX.YOUR_DOMAIN.duckdns.org LÀ có CERT HTTPS VALID
      - EXTRA_DOMAINS= #optional
      - STAGING=true # TEST TRÊN STAGING OK THÌ CHUYỂN QUA false ĐỂ LẤY CERT VALID
    volumes:
      - ./swag/config:/config # MOUNT FOLDER /swag/config vào 
    ports:
      - 443:443
      # - 80:80 #optional
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "10"
```

Run `docker-compose up -d`, check log của swag ko có lỗi gì là OK. Sửa `STAGING=false` rồi run lại `docker-compose up -d`.

Vào folder này: `swag/config/nginx/proxy-confs`, tạo file `hello.subdomain.conf`:  

(chú ý sửa `YOUR_DOMAIN` = domain của bạn)

```sh

server {

    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name hello.YOUR_DOMAIN.duckdns.org;
    
    include /config/nginx/ssl.conf;

    location / {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app helloworld-python;
	      set $upstream_port 4040;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }
}

```

Restart swag: `docker restart swag`

Giờ từ browser của bạn, ví dụ Chrome, vào link: `https://hello.YOUR_DOMAIN.duckdns.org`, thấy như sau là OK xong App1:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hello-python-fastapi-with-swag.jpg)

Tiếp sẽ expose App2, tạo file `swag/config/nginx/proxy-confs/konnichiwa.subdomain.conf`: 

(chú ý sửa `YOUR_DOMAIN` = domain của bạn)

```sh

server {

    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name konnichiwa.YOUR_DOMAIN.duckdns.org;
    
    include /config/nginx/ssl.conf;

    location / {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app konnichiwa-python;
	      set $upstream_port 4040;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
        proxy_set_header X-Vouch-User $auth_resp_x_vouch_user;
    }
}

```

Restart swag: `docker restart swag`

Giờ từ browser của bạn, ví dụ Chrome, vào link: `https://konnichiwa.YOUR_DOMAIN.duckdns.org`, thấy như sau là OK xong App2:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hello2-python-fastapi-with-swag.jpg)

Vậy là xong phần này chúng ta đã có 2 App1,App2 tr.ần tru.ồng ra Internet và rất cần 1 trang login cho cả 2.

## 2.3. Setup Keycloak with Posgresql DB, behind Nginx Swag

Mình khuyến khích đọc bài này để hiểu cơ bản về cách vận hành Keycloak: https://www.keycloak.org/getting-started/getting-started-docker

Vào phần chính của mình: 

Sửa file `docker-compose.yml`, add thêm:  

```yml
...
  keycloak-pgdb:
    container_name: keycloak-pgdb
    image: postgres
    volumes:
      - ./keycloak-lab/postgres_data:/var/lib/postgresql/data # THIS IS FOLDER STORE YOUR KEYCLOAK DATABASE
    ports:
      - 5432:5432
    environment:
      POSTGRES_DB: keycloak
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD: password # KEYCLOAK POSTGRESQL DB PASSWORD

  keycloak:
    container_name: keycloak
    image: quay.io/keycloak/keycloak:22.0.1
    hostname: keycloak
    volumes:
      - ./keycloak-lab/config/realm.json:/opt/keycloak/data/import/realm.json  # THIS IS FOLDER STORE YOUR KEYCLOAK CONFIG
    ports:
      - 8080:8080
    environment:
      KC_DB: postgres
      KC_DB_URL_HOST: keycloak-pgdb
      KC_DB_URL_PORT: 5432
      KC_DB_URL_DATABASE: keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: password # KEYCLOAK POSTGRESQL DB PASSWORD

      KEYCLOAK_ADMIN: admin
      KEYCLOAK_ADMIN_PASSWORD: yoursupersecurepassword # YOUR PASSWORD LOGIN TO KEYCLOAK ADMIN CONSOLE
      KC_HTTP_ENABLED: true
      KC_PROXY: edge
      KC_HOSTNAME_STRICT: false
    command:
      - start
    depends_on:
      - keycloak-pgdb
```

Run `docker-compose up -d`, check log của keycloak ko có lỗi gì là OK. 

```
$ docker logs keycloak
Changes detected in configuration. Updating the server image.
Updating the configuration and installing your custom providers, if any. Please wait.
2023-08-21 08:27:33,017 INFO  [io.quarkus.deployment.QuarkusAugmentor] (main) Quarkus augmentation completed in 6710ms
Server configuration updated and persisted. Run the following command to review the configuration:

        kc.sh show-config

Next time you run the server, just run:

        kc.sh start --optimized

2023-08-21 08:27:34,727 INFO  [org.keycloak.quarkus.runtime.hostname.DefaultHostnameProvider] (main) Hostname settings: Base URL: <unset>, Hostname: <request>, Strict HTTPS: false, Path: <request>, Strict BackChannel: false, Admin URL: <unset>, Admin: <request>, Port: -1, Proxied: true
```

Giờ sẽ expose Keycloak ra internet bằng swag. Tạo file `swag/config/nginx/proxy-confs/keycloak.subdomain.conf`: 

(chú ý sửa `YOUR_DOMAIN` = domain của bạn)

```sh
server {

    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name keycloak.YOUR_DOMAIN.duckdns.org;
    
    include /config/nginx/ssl.conf;

    location / {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app keycloak;
	      set $upstream_port 8080;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
    }
}

```

Restart swag: `docker restart swag`

Giờ từ browser của bạn, ví dụ Chrome, vào link: `https://keycloak.YOUR_DOMAIN.duckdns.org`. Đây gọi là Keycloak Administration UI. Thấy như sau là OK:  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-admin-ui1.jpg)

Login với account admin/(password lấy từ file `docker-compose.yml`)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-admin-ui-logged-in.jpg)

Tạo mới 1 realms, giả sử tên là `messi`. Realm là 1 khái niệm về tổ chức trong Keycloak, giống như org vậy   

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-admin-ui-logged-in-create-realms.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-admin-ui-logged-in-create-realms-messi.jpg)

Tạo mới 1 user (giả sử `user2`) trong realm `messi`- user này sau sẽ dùng để login vào các App của bạn  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-admin-ui-logged-in-create-user.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-admin-ui-logged-in-create-user-screen.jpg)

Set password cho user trên. Set Temporary -> Off.  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-admin-ui-logged-in-create-user-pwd.jpg)  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-admin-ui-logged-in-pwd-off.jpg)  

Giờ vào trang này: `https://keycloak.YOUR_DOMAIN.duckdns.org/realms/messi/account`. Đây gọi là KeyCloak Account Console. Login bằng acount `user2`. login thành công là OK.   
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-account-ui.jpg)
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-account-ui-login.jpg)  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-account-ui-login-ok.jpg)  

Logout ra, Quay lại trang Keycloak Administration UI `https://keycloak.YOUR_DOMAIN.duckdns.org`, login bằng admin account.

Chọn realm ở góc trên cùng bên trái, chọn tab Clients -> Create Client.  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-admin-create-client.jpg)

Mình sẽ tạo 1 client mới id là `allinone`.  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-admin-create-client-allinone.jpg)

Ở phần Capability config, chú ý enable `Client authentication`.  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-admin-create-client-allinone-enable-client-authen.jpg)

Ở phần Access settings:   
- Set `Valid redirect URIs` to `https://vouch.YOUR_DOMAIN.duckdns.org/*`
- Set `Web origins` to `https://vouch.YOUR_DOMAIN.duckdns.org`

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-admin-create-client-allinone-add-url.jpg)

Giải thích: phần này chúng ta set trước Keycloak sẽ chỉ valid các request đến từ Vouch Proxy của chúng ta. Lát nữa sẽ tạo Vouch Proxy các bạn sẽ thấy link này.

Next -> Next, bỏ trống các chỗ khác -> Save để tạo client

Nhìn thấy client `allinone` đã tạo ra, select nó, chọn tab `Credential`.  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-admin-create-client-get-secret.jpg)

Copy value của Client Secret để sau này dùng. Còn Client ID thì chính là `allinone`

Vào phần Realm settings -> ấn vào link `OpenID Endpoint Configuration`.  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-admin-get-oidc-endpoint.jpg)
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-admin-get-oidc-endpoint-2.jpg)

chúng ta sẽ được 1 chuỗi JSON như trên ảnh, bạn cần lấy ra 3 thông tin, tương tự như này:  

- `"authorization_endpoint":"https://keycloak.YOUR_DOMAIN.duckdns.org/realms/messi/protocol/openid-connect/auth",`  
- `"token_endpoint":"https://keycloak.YOUR_DOMAIN.duckdns.org/realms/messi/protocol/openid-connect/token",`  
- `"userinfo_endpoint":"https://keycloak.YOUR_DOMAIN.duckdns.org/realms/messi/protocol/openid-connect/userinfo"`  

Vậy là xong kết thúc phần này ta đã có được các thông tin của Keycloak: 

`Client ID, Client secret, authorization_endpoint, token_endpoint, userinfo_endpoint`

## 2.4. Setup Vouch Proxy, behind Nginx Swag

Sửa file `docker-compose.yml` để add thêm Vouch Proxy:

```yml
...
  vouch-proxy:
    container_name: vouch-proxy
    image: voucher/vouch-proxy:latest-arm # THIS IMAGE TAG `latest-arm` IS FOR ARM OS ARCHITECT
    ports:
      - 9090:9090
    volumes:
      - ./vouch-proxy/config:/config # THIS FOLDER STORE VOUCH PROXY CONFIG FILE
    restart: unless-stopped
```

Trong folder `./vouch-proxy/config` tạo file `config.yml`, sửa các chỗ:  

- `vouch.cookie.domain` => `YOUR_DOMAIN.duckdns.org`  
- `oauth.client_id`     => `Client ID` đã có từ step config Keycloak  
- `oauth.client_secret` => `Client Secret` có từ step config Keycloak  
- `oauth.auth_url`      => `authorization_endpoint` đã có từ step config Keycloak  
- `oauth.user_info_url` => `userinfo_endpoint` đã có từ step config Keycloak  
- `oauth.token_url`     => `token_endpoint` đã có từ step config Keycloak  
- `oauth.callback_url`  => `https://vouch.YOUR_DOMAIN.duckdns.org/auth`  

(chú ý sửa `YOUR_DOMAIN` = domain của bạn)

```yml
# Vouch Proxy configuration
# bare minimum to get Vouch Proxy running with OpenID Connect (such as okta)

vouch:
  # testing: true
  # logLevel: debug
  # domains:
  # valid domains that the jwt cookies can be set into
  # the callback_urls will be to these domains
  domains:
  # - yourotherdomain.com

  # - OR 
  # instead of setting specific domains you may prefer to allow all users...
  # set allowAllUsers: true to use Vouch Proxy to just accept anyone who can authenticate at the configured provider
  # and set vouch.cookie.domain to the domain you wish to protect
  allowAllUsers: true

  cookie:
    # allow the jwt/cookie to be set into http://yourdomain.com (defaults to true, requiring https://yourdomain.com) 
    secure: false
    # vouch.cookie.domain must be set when enabling allowAllUsers
    domain: YOUR_DOMAIN.duckdns.org

oauth:
  # Generic OpenID Connect
  # including okta
  provider: oidc
  client_id: allinone
  client_secret: 4V4xxxxxxxxxxxxxxxxxx3fa
  auth_url: https://keycloak.YOUR_DOMAIN.duckdns.org/realms/messi/protocol/openid-connect/auth
  user_info_url: https://keycloak.YOUR_DOMAIN.duckdns.org/realms/messi/protocol/openid-connect/userinfo
  token_url: https://keycloak.YOUR_DOMAIN.duckdns.org/realms/messi/protocol/openid-connect/token
  scopes:
    - openid
    - email
    - profile
  callback_url: https://vouch.YOUR_DOMAIN.duckdns.org/auth

```

Có thể các bạn muốn biết đầy đủ all config available của VouchProxy thì có thể xem ở đây https://github.com/vouch/vouch-proxy/blob/master/config/config.yml_example

Run `docker-compose up -d`, check log của vouch-proxy ko có lỗi gì là OK. 

```
$ docker logs vouch-proxy

{"level":"info","ts":1692778767.8115623,"msg":"Copyright 2020-2022 the Vouch Proxy Authors"}
{"level":"warn","ts":1692778767.8115938,"msg":"Vouch Proxy is free software with ABSOLUTELY NO WARRANTY."}
{"level":"info","ts":1692778767.8127365,"msg":"jwt.secret read from /config/secret"}
{"level":"warn","ts":1692778767.8127532,"msg":"generating random session.key"}
{"level":"info","ts":1692778767.8127794,"msg":"setting LogLevel to info"}
{"level":"info","ts":1692778767.8129365,"msg":"configuring oidc OAuth with Endpoint https://keycloak.YOUR_DOMAIN.duckdns.org/realms/messi/protocol/openid-connect/auth"}
{"level":"info","ts":1692778767.812991,"msg":"jwtcache: the returned headers for a valid jwt will be cached for 20 minutes"}
{"level":"info","ts":1692778767.813395,"msg":"starting Vouch Proxy","version":"a676feb","buildtime":"2023-01-21T21:47:45Z","uname":"Linux","buildhost":"buildkitsandbox","branch":"master","semver":"","listen":"http://0.0.0.0:9090","tls":false,"document_root":"","oauth.provider":"oidc"}

$ curl localhost:9090/healthcheck
{ "ok": true }

```

Tiếp theo sẽ expose Vouch Proxy ra internet bằng Nginx Swag

Tạo file `swag/config/nginx/proxy-confs/vouch.subdomain.conf`:  

(chú ý sửa `YOUR_DOMAIN` = domain của bạn)
```sh

server {

    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name vouch.YOUR_DOMAIN.duckdns.org;
    
    include /config/nginx/ssl.conf;

    location / {
        # include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app vouch-proxy;
	      set $upstream_port 9090;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
        # be sure to pass the original host header
        proxy_set_header Host $http_host;
    }
}

```

Restart swag: `docker restart swag`

Giờ từ browser của bạn, ví dụ Chrome, vào link: `https://vouch.YOUR_DOMAIN.duckdns.org/healthcheck` thấy trả về `{ "ok": true }` là OK.

## 2.5. Config on Nginx App1, App2 to use Vouch Proxy

Giờ cần sửa file `swag/config/nginx/proxy-confs/hello.subdomain.conf` để sử dùng được Vouch Proxy:  

(chú ý sửa `YOUR_DOMAIN` = domain của bạn)
```sh

server {

    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name hello.YOUR_DOMAIN.duckdns.org;
    
    include /config/nginx/ssl.conf;

    # send all requests to the `/validate` endpoint for authorization
    auth_request /validate;

    location = /validate {
      # forward the /validate request to Vouch Proxy
      proxy_pass http://vouch-proxy:9090/validate;
      # be sure to pass the original host header
      proxy_set_header Host $http_host;

      # Vouch Proxy only acts on the request headers
      proxy_pass_request_body off;
      proxy_set_header Content-Length "";

      # optionally add X-Vouch-User as returned by Vouch Proxy along with the request
      auth_request_set $auth_resp_x_vouch_user $upstream_http_x_vouch_user;

      # optionally add X-Vouch-IdP-Claims-* custom claims you are tracking
      #    auth_request_set $auth_resp_x_vouch_idp_claims_groups $upstream_http_x_vouch_idp_claims_groups;
      #    auth_request_set $auth_resp_x_vouch_idp_claims_given_name $upstream_http_x_vouch_idp_claims_given_name;
      # optinally add X-Vouch-IdP-AccessToken or X-Vouch-IdP-IdToken
      #    auth_request_set $auth_resp_x_vouch_idp_accesstoken $upstream_http_x_vouch_idp_accesstoken;
      #    auth_request_set $auth_resp_x_vouch_idp_idtoken $upstream_http_x_vouch_idp_idtoken;

      # these return values are used by the @error401 call
      auth_request_set $auth_resp_jwt $upstream_http_x_vouch_jwt;
      auth_request_set $auth_resp_err $upstream_http_x_vouch_err;
      auth_request_set $auth_resp_failcount $upstream_http_x_vouch_failcount;

      # Vouch Proxy can run behind the same Nginx reverse proxy
      # may need to comply to "upstream" server naming
      # proxy_pass http://vouch.yourdomain.com/validate;
      # proxy_set_header Host $http_host;
    }

    error_page 401 = @error401;

    location @error401 {
        # redirect to Vouch Proxy for login
        return 302 https://vouch.YOUR_DOMAIN.duckdns.org/login?url=$scheme://$http_host$request_uri&vouch-failcount=$auth_resp_failcount&X-Vouch-Token=$auth_resp_jwt&error=$auth_resp_err;
        # you usually *want* to redirect to Vouch running behind the same Nginx config proteced by https
        # but to get started you can just forward the end user to the port that vouch is running on
        # return 302 http://vouch.yourdomain.com:9090/login?url=$scheme://$http_host$request_uri&vouch-failcount=$auth_resp_failcount&X-Vouch-Token=$auth_resp_jwt&error=$auth_resp_err;
    }

    location / {
        # include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app helloworld-python;
	      set $upstream_port 4040;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
        proxy_set_header X-Vouch-User $auth_resp_x_vouch_user;
    }
}

```

Restart swag: `docker restart swag`

Giờ từ browser của bạn, ví dụ Chrome, vào link: `https://hello.YOUR_DOMAIN.duckdns.org` nó redirect sang login vào KeyCloak là OK. Nhập account `user2` vào, login thành công sẽ redirect bạn về nội dung `Hello World`.  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-account-ui-login.jpg)  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hello-python-fastapi-with-swag.jpg)  

Tương tự với App1, chúng ta sẽ sửa App2 để nó cũng dùng được Vouch Proxy.

Sửa file `swag/config/nginx/proxy-confs/konnichiwa.subdomain.conf`:   

(chú ý sửa `YOUR_DOMAIN` = domain của bạn)

```sh

server {

    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name konnichiwa.YOUR_DOMAIN.duckdns.org;
    
    include /config/nginx/ssl.conf;

    # send all requests to the `/validate` endpoint for authorization
    auth_request /validate;

    location = /validate {
      # forward the /validate request to Vouch Proxy
      proxy_pass http://vouch-proxy:9090/validate;
      # be sure to pass the original host header
      proxy_set_header Host $http_host;

      # Vouch Proxy only acts on the request headers
      proxy_pass_request_body off;
      proxy_set_header Content-Length "";

      # optionally add X-Vouch-User as returned by Vouch Proxy along with the request
      auth_request_set $auth_resp_x_vouch_user $upstream_http_x_vouch_user;

      # optionally add X-Vouch-IdP-Claims-* custom claims you are tracking
      #    auth_request_set $auth_resp_x_vouch_idp_claims_groups $upstream_http_x_vouch_idp_claims_groups;
      #    auth_request_set $auth_resp_x_vouch_idp_claims_given_name $upstream_http_x_vouch_idp_claims_given_name;
      # optinally add X-Vouch-IdP-AccessToken or X-Vouch-IdP-IdToken
      #    auth_request_set $auth_resp_x_vouch_idp_accesstoken $upstream_http_x_vouch_idp_accesstoken;
      #    auth_request_set $auth_resp_x_vouch_idp_idtoken $upstream_http_x_vouch_idp_idtoken;

      # these return values are used by the @error401 call
      auth_request_set $auth_resp_jwt $upstream_http_x_vouch_jwt;
      auth_request_set $auth_resp_err $upstream_http_x_vouch_err;
      auth_request_set $auth_resp_failcount $upstream_http_x_vouch_failcount;

      # Vouch Proxy can run behind the same Nginx reverse proxy
      # may need to comply to "upstream" server naming
      # proxy_pass http://vouch.yourdomain.com/validate;
      # proxy_set_header Host $http_host;
    }

    error_page 401 = @error401;

    location @error401 {
        # redirect to Vouch Proxy for login
        return 302 https://vouch.YOUR_DOMAIN.duckdns.org/login?url=$scheme://$http_host$request_uri&vouch-failcount=$auth_resp_failcount&X-Vouch-Token=$auth_resp_jwt&error=$auth_resp_err;
        # you usually *want* to redirect to Vouch running behind the same Nginx config proteced by https
        # but to get started you can just forward the end user to the port that vouch is running on
        # return 302 http://vouch.yourdomain.com:9090/login?url=$scheme://$http_host$request_uri&vouch-failcount=$auth_resp_failcount&X-Vouch-Token=$auth_resp_jwt&error=$auth_resp_err;
    }

    location / {
        # include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app konnichiwa-python;
	    set $upstream_port 4040;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
        proxy_set_header X-Vouch-User $auth_resp_x_vouch_user;
    }
}

```

Restart swag: `docker restart swag`

Giờ từ browser của bạn, ví dụ Chrome, vào link: `https://konnichiwa.YOUR_DOMAIN.duckdns.org` nó redirect sang login vào KeyCloak. Nhập account `user2` vào, login thành công sẽ redirect bạn về nội dung `こんにちは～!` là OK. 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hello2-python-fastapi-with-swag.jpg)


## 2.6. Troubleshoot

Nếu khi login bằng `user1` mà bị lỗi 400 Bad request. Thử lại + Check F12 thì thấy các request loop lại liên tục.
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/400badgateway-vouchproxy.jpg)

Check log vouch-proxy có lỗi:

```
$ docker logs vouch-proxy
{"level":"info","ts":1692786021.9747577,"msg":"|302| 17.609691ms /auth/9Ep3OPCxXjfb9rvvv0jO1TltPVUa1Kwf/","statusCode":302,"request":98,"latency":0.017609691,"avgLatency":0.00977582,"ipPort":"172.18.0.3:52858","method":"GET","host":"vouch.YOUR_DOMAIN.duckdns.org","path":"/auth/9Ep3OPCxXjfb9rvvv0jO1TltPVUa1Kwf/","referer":""}
{"level":"warn","ts":1692786022.2136517,"msg":"no User found in jwt"}
{"level":"info","ts":1692786024.4422774,"msg":"OpenID userinfo body: {\"sub\":\"115c5245-92a7-4a76-a74b-41abf66e926b\",\"email_verified\":true,\"name\":\"user1 user1\",\"preferred_username\":\"user1\",\"given_name\":\"user1\",\"family_name\":\"user1\"}"}
{"level":"info","ts":1692786024.4425893,"msg":"|302| 17.330291ms /auth/TFnsn7z9NTydBm9dDhRDYarck6CHEO8/","statusCode":302,"request":106,"latency":0.017330291,"avgLatency":0.009378383,"ipPort":"172.18.0.3:52940","method":"GET","host":"vouch.YOUR_DOMAIN.duckdns.org","path":"/auth/TFnsn7z9NTydBm9dDhRDYarck6CHEO8/","referer":""}
{"level":"warn","ts":1692786054.719587,"msg":"/auth Error while retrieving user info after successful login at the OAuth provider: oauth2: cannot fetch token: 400 Bad Request\nResponse: {\"error\":\"invalid_grant\",\"error_description\":\"Code not valid\"}"}
```

Solution: Thì hãy thử tạo 1 user khác `user2` chẳng hạn. Rồi login lại bằng `user2` -> ko còn lỗi nữa. Vậy có nghĩa là lỗi chỉ xảy ra với 1 `user1`. Xóa user đó đi và tạo lại thử xem (Chú ý tạo lại thì điền đầy đủ các trường như email, first name, lastname). Nếu xóa đi tạo lại mà vẫn ko login được với `user1` thì mình vẫn chưa biết còn cách nào nữa.  

# 3. Problem của VouchProxy, thay thế bằng Oauth2Proxy

1 usecase nữa là nếu bạn expose App của bạn ko có giao diện mà chỉ là API service thôi, khi đó mà bạn vẫn muốn bảo vệ API của mình khỏi người khác "dùng chùa" thì sao? Cũng có thể dùng KeyCloak cho trường hợp này, mặc dù ko chắc là có phổ biến hay ko...

Keycloak cung cấp API để bạn có thể lấy được `access_token`:

```sh
KEYCLOAK_TOKEN_URL=https://keycloak.YOUR_DOMAIN.duckdns.org/realms/messi/protocol/openid-connect/token
KEYCLOAK_CLIENT_ID=allinone
KEYCLOAK_CLIENT_SECRET="4V4xxxx3fa"
KEYCLOAK_USERNAME=user1
KEYCLOAK_PWD=SuPErSecuRePaSsWoRd

TOKEN=$(curl -L -X POST -s "$KEYCLOAK_TOKEN_URL" \
-H 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode "client_id=$KEYCLOAK_CLIENT_ID" \
--data-urlencode 'grant_type=password' \
--data-urlencode "client_secret=$KEYCLOAK_CLIENT_SECRET" \
--data-urlencode 'scope=openid' \
--data-urlencode "username=$KEYCLOAK_USERNAME" \
--data-urlencode "password=$KEYCLOAK_PWD")

ACCESS_TOKEN=$(echo $TOKEN | jq -r .access_token)
```

Hiện nếu dùng `ACCESS_TOKEN` vẫn chưa load được content của App1, nó trả về code 302 (Code này thường thấy khi redirect sang login page): 

```
$ curl https://hello.YOUR_DOMAIN.duckdns.org \
>      -H "Authorization: Bearer $ACCESS_TOKEN"
<html>
<head><title>302 Found</title></head>
<body>
<center><h1>302 Found</h1></center>
<hr><center>nginx</center>
</body>
</html>
```

Nếu dùng "VouchProxy" thì không thể lấy được cookie bằng câu lệnh. Mình đã thử F12 nhưng ko rõ user/password gửi đường nào mà đến được Keycloak thông qua Vouch Proxy

Thực tế là VouchProxy issue token riêng của nó đối với Keycloak, thế nên mình ko thể làm thay nó bằng command line được.  

Nếu run script từ bên ngoài đến App service thì hiện tại ko thể, Vouch chưa support. Phải chờ #362 và #422 được implement:
https://github.com/vouch/vouch-proxy/issues/446#issuecomment-966550433

Không thể dùng `access_token` từ ngoài và authenticate App bằng script:  
https://github.com/vouch/vouch-proxy/issues/432 (Google App Script)

#362 có 1 diagram về feature mà Vouch muốn làm từ 2021, nhưng hiện tại vẫn chưa làm: https://github.com/vouch/vouch-proxy/issues/362#issuecomment-788344936

Họ nói rõ VouchProxy đang tập trung vào việc handle human interaction with browser mà thôi:  
https://github.com/vouch/vouch-proxy/issues/362#issuecomment-779392480  
https://github.com/vouch/vouch-proxy/issues/94#issuecomment-534353665  
https://github.com/vouch/vouch-proxy/issues/484#issuecomment-1179280657  

Issue trên dẫn đến 1 Giải pháp khác: "Keycloak + VouchProxy" có thể thay bằng "Keycloak + Oauth2Proxy".  
Oauth2Proxy có vẻ được nhiều ⭐ hơn VouchProxy trên Github: https://github.com/oauth2-proxy/oauth2-proxy

## 3.1. Config trên Keycloak

Tạo mới 1 client riêng tên là `oauth2-proxy`

Enable `Client authentication`

Note lại Client ID và Client Secret

Set `Valid redirect URIs` = `https://oauth2.YOUR_DOMAIN.duckdns.org/oauth2/callback`

Vào tab `Client Scopes` (cạnh tab Credential, Roles) -> select scope `oauth2-proxy-dedicated` -> tạo các mapper mới sau:  

> Create a mapper with Mapper Type 'Group Membership' and Token Claim Name 'groups'.  
> Create a mapper with Mapper Type 'Audience' and Included Client Audience and Included Custom Audience set to your client name.  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-oauth2-proxy-mapper.jpg)

## 3.2. Install oauth2-proxy

Sửa `docker-compose.yml`, thêm đoạn sau:

```yml
version: '3.0'

services:
...

  oauth2-proxy:
    image: quay.io/oauth2-proxy/oauth2-proxy:v7.4.0
    container_name: oauth2-proxy
    command: --config /oauth2-proxy.cfg
    hostname: oauth2-proxy
    volumes:
      - "./oauth2-proxy/oauth2-proxy-keycloak.cfg:/oauth2-proxy.cfg"
    restart: unless-stopped
    ports:
      - 4180:4180/tcp
```

tạo file `./oauth2-proxy/oauth2-proxy-keycloak.cfg`. Chú ý sửa `client_secret`, `client_id`, `YOUR_DOMAIN`. `messi` là REALM mà mình tạo ra từ đầu:

```conf
http_address="0.0.0.0:4180"
cookie_secret="OQINaROshtE9TcZkNAm-5Zs2Pv3xaWytBmc5W7sPX7w="
email_domains=["*"]
cookie_secure="false"
cookie_domains=[".YOUR_DOMAIN.duckdns.org"] # Required so cookie can be read on all subdomains.
whitelist_domains=[".YOUR_DOMAIN.duckdns.org"] # Required to allow redirection back to original requested target.

# keycloak provider
client_secret="szR5YsgtJaDtrZkhmKKfKbqIUF3iSfyr"
client_id="oauth2-proxy"
redirect_url="https://oauth2.YOUR_DOMAIN.duckdns.org/oauth2/callback"

# in this case oauth2-proxy is going to visit
# http://keycloak.localtest.me:9080/auth/realms/master/.well-known/openid-configuration for configuration
oidc_issuer_url="https://keycloak.YOUR_DOMAIN.duckdns.org/realms/messi"
provider="keycloak-oidc"
provider_display_name="Keycloak"
```

chú ý `cookie_secret` chỉ là 1 chuỗi secret random thôi, generate bằng shell:  

```sh
# Create Cookie Secret

# using python
python -c 'import os,base64; print(base64.urlsafe_b64encode(os.urandom(32)).decode())'
fLIblJsthbMhgELnmpqrCbWQD9P1vyDfI5SAs8BUG6c=

# using bash
dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64 | tr -d -- '\n' | tr -- '+/' '-_'; echo
```

Run `docker-compose up -d`. Check log của oauth2-proxy ko có lỗi là ok

```
$ docker logs oauth2-proxy

[2023/08/30 09:05:15] [provider.go:55] Performing OIDC Discovery...
[2023/08/30 09:05:16] [providers.go:145] Warning: Your provider supports PKCE methods ["plain" "S256"], but you have not enabled one with --code-challenge-method
[2023/08/30 09:05:16] [oauthproxy.go:162] OAuthProxy configured for Keycloak OIDC Client ID: oauth2-proxy
[2023/08/30 09:05:16] [oauthproxy.go:168] Cookie settings: name:_oauth2_proxy secure(https):false httponly:true expiry:168h0m0s domains:.YOUR_DOMAIN.duckdns.org path:/ samesite: refresh:disabled
```

## 3.3. Config Nginx cho oauth2-proxy

tạo file `swag/config/nginx/proxy-confs/oauth2.subdomain.conf`:  

```conf

server {

    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name oauth2.YOUR_DOMAIN.duckdns.org;
    
    include /config/nginx/ssl.conf;

    location /oauth2/ {
        proxy_pass http://oauth2-proxy:4180;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Scheme $scheme;
        proxy_set_header X-Auth-Request-Redirect $scheme://$host$request_uri;
        proxy_buffer_size 8k;
    }

    location /oauth2/auth {
        proxy_pass http://oauth2-proxy:4180;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Scheme $scheme;
        proxy_set_header Content-Length   "";
        proxy_pass_request_body off;
    }

    location / {
        try_files $uri $uri/ =404;
        auth_request /oauth2/auth;
        error_page 401 = /oauth2/sign_in?rd=https://$host$request_uri;
        auth_request_set $user   $upstream_http_x_auth_request_user;
        auth_request_set $email  $upstream_http_x_auth_request_email;
        proxy_set_header X-User  $user;
        proxy_set_header X-Email $email;
        auth_request_set $auth_cookie $upstream_http_set_cookie;
        add_header Set-Cookie $auth_cookie;
    }
}
```

Restart `swag` check log ko có lỗi là ok

Giờ vào browser truy cập: `https://oauth2.YOUR_DOMAIN.duckdns.org` sẽ thấy giao diện này là OK: 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-oauth2-proxy-login-screen.jpg)

Login vào bằng user1 account, thành công sẽ redirect bạn về site `Welcome to nginx!` là OK 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-oauth2-proxy-login-screen-ok.jpg)

## 3.4. Config Nginx cho App1

Giờ ta sẽ sửa file `swag/config/nginx/proxy-confs/hello.subdomain.conf` để sử dụng oauth2-proxy: 

```conf

server {

    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name hello.YOUR_DOMAIN.duckdns.org;
    
    include /config/nginx/ssl.conf;

    location / {
      proxy_pass http://helloworld-python:4040;
      proxy_set_header Host $host;
      #proxy_redirect off;
      #proxy_http_version 1.1;
      
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header X-Auth-Request-Redirect $request_uri;
      
      auth_request /oauth2/auth;
      error_page 401 = /oauth2/sign_in?rd=https://$host$request_uri;
      auth_request_set $user   $upstream_http_x_auth_request_user;
      auth_request_set $email  $upstream_http_x_auth_request_email;
      proxy_set_header X-User  $user;
      proxy_set_header X-Email $email;
      auth_request_set $token  $upstream_http_x_auth_request_access_token;
      proxy_set_header X-Access-Token $token;
    }
  
    location /oauth2/ {
      proxy_pass http://oauth2-proxy:4180;
      proxy_set_header Host $host;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Scheme $scheme;
      proxy_set_header X-Auth-Request-Redirect $request_uri;
  }
}

server {
    listen 80;
    server_name hello.YOUR_DOMAIN.duckdns.org;
    return 301 https://$host$request_uri;
}
```

Restart `swag` check log ko có lỗi là ok

Giờ vào browser truy cập: `https://hello.YOUR_DOMAIN.duckdns.org` sẽ thấy giao diện này là OK:  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/keycloak-oauth2-proxy-login-screen.jpg)

Login vào bằng user1 account, thành công sẽ redirect bạn về site `Hello World!` là OK

## 3.5. Config để call API cho App1

Hiện tại ko thể call App1 qua command như này được: 

```sh
curl https://hello.YOUR_DOMAIN.duckdns.org
```

Nó sẽ ko trả về `Hell World!` mà sẽ trả về html của giao diện login.

Cần sửa file `/oauth2-proxy/oauth2-proxy-keycloak.cfg`, add thêm vào cuối như sau:

```conf
...
skip_jwt_bearer_tokens="true"
oidc_email_claim="sub"
set_xauthrequest="true"
```

Restart `oauth2-proxy`, check log ko có lỗi là oK.

Lấy `access_token` từ keycloak có 2 cách.

### 3.5.1. Cách 1 là dùng cả client info và user/password

```sh
CLIENT_ID=oauth2-proxy
CLIENT_SECRET=szRXXXXXXXXXXXXXXfyr
USERNAME=user1
PASSWD=paSSSWord

ACCESS_TOKEN=$(curl -L -X POST -s 'https://keycloak.YOUR_DOMAIN.duckdns.org/realms/messi/protocol/openid-connect/token' \
-H 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode "client_id=$CLIENT_ID" \
--data-urlencode 'grant_type=password' \
--data-urlencode "client_secret=$CLIENT_SECRET" \
--data-urlencode 'scope=openid' \
--data-urlencode "username=$USERNAME" \
--data-urlencode "password=$PASSWD" | jq --raw-output '.access_token')

curl https://hello.YOUR_DOMAIN.duckdns.org \
    -H "Authorization: Bearer $ACCESS_TOKEN"
```

Bạn sẽ thấy kết quả trả về là `Hello World!` , Như vậy là chúng ta đã có thể call APi thông qua `access_token`.

Token này chỉ valid trong vòng 5p mà thôi. 

Vậy là nếu bạn cần `access_token` bạn sẽ cần `client_id, client_secret, username, password` để tạo access token - điều này vẫn hơi khó khăn 1 chút

### 3.5.2. Cách 2 là dùng chỉ client info

vào Keycloak enable `Service account roles` của Client `oauth2-proxy` (ảnh). Như vậy chỉ cần dùng `client_id` và `client_secret`:

```sh
ACCESS_TOKEN=$(curl -L -X POST -s 'https://keycloak.YOUR_DOMAIN.duckdns.org/realms/messi/protocol/openid-connect/token' \
-H 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode "client_id=$CLIENT_ID" \
--data-urlencode 'grant_type=client_credentials' \
--data-urlencode "client_secret=$CLIENT_SECRET" | jq --raw-output '.access_token')

curl https://hello.YOUR_DOMAIN.duckdns.org -H "Authorization: Bearer $ACCESS_TOKEN"
```

Hiện mình vẫn chưa biết cách nào lấy access token bằng user/password

## 3.6. Import/Export data in Keycloak

Sửa `docker-compose.yml` file: 

```
keycloak:
...
    volumes:
      - /home/deploy/devops/keycloak/config/import/realm.json:/opt/keycloak/data/import/realm.json
      - /home/deploy/devops/keycloak/config/export/realm.json:/opt/keycloak/data/export/realm.json:rw
...
```

Export command, specify `--realm`, specify `--dir`, specify `--users realm_file` will create one file with all Users information:  

```sh
docker exec -it keycloak /opt/keycloak/bin/kc.sh export --help
docker exec -it keycloak /opt/keycloak/bin/kc.sh export --realm messi --dir /opt/keycloak/data/export/realm.json --users realm_file
```

1 json file will be created in folder `export`, copy that to `import` folder.

Import command:

```sh
docker exec -it keycloak /opt/keycloak/bin/kc.sh import --help
docker exec -it keycloak /opt/keycloak/bin/kc.sh import --file /opt/keycloak/data/import/realm.json/messi-realm.json
```

If no ERROR happen, you all ready to set. All users and realm config is imported. 

## 3.7. Troubleshoot oauth2-proxy

- Lỗi 500 Internal Server error:

```
$ docker logs oauth2-proxy
[2023/08/31 03:29:38] [oauthproxy.go:830] Error creating session during OAuth2 callback: audience from claim aud with value [account] does not match with any of allowed audiences map[oauth2-proxy:{}]
172.18.0.3:40120 - 566c794c-d15b-47d4-992a-5d2b0db22dc5 - - [2023/08/31 03:29:38] oauth2.YOUR_DOMAIN.duckdns.org GET - "/oauth2/callback?state=LTZNRXh2jXkQFbAa1EQPHWQ7kA0HyhIQzuM0u1msRc4%3Ahttps%3A%2F%2Fhello.YOUR_DOMAIN.duckdns.org%2F&session_state=7f570cc3-03c4-4c40-a025-6f5e52ed787c&code=1e25c65b-3495-4cea-9d74-bfcfca02d53f.7f570cc3-03c4-4c40-a025-6f5e52ed787c.a7a91ac8-c1ca-4cc2-b4ca-93796f1bcb0b" HTTP/1.0 "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36 Edg/116.0.1938.62" 500 3507 0.021
172.18.0.3:40132 - 797fbc45-8241-4e45-a054-a5beb0244ce6 - - [2023/08/31 03:29:39] oauth2.YOUR_DOMAIN.duckdns.org GET - "/oauth2/auth" HTTP/1.0 "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36 Edg/116.0.1938.62" 401 13 0.000
172.18.0.3:40138 - db1ce558-bc50-4719-97c7-9987b39488e2 - - [2023/08/31 03:29:39] oauth2.YOUR_DOMAIN.duckdns.org GET - "/oauth2/sign_in?rd=https://oauth2.YOUR_DOMAIN.duckdns.org/favicon.ico" HTTP/1.0 "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36 Edg/116.0.1938.62" 200 8544 0.001
```

Solution: Cần làm đủ các step 3+4 trong doc này: https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/oauth_provider/#keycloak-oidc-auth-provider

Chọn Client `oauth2-proxy` -> Client scope -> `oauth2-proxy-dedicated` -> Configure new mapper:

```
Create a mapper with Mapper Type 'Group Membership' and Token Claim Name 'groups'.
Create a mapper with Mapper Type 'Audience' and Included Client Audience and Included Custom Audience set to your client name.
```

- Lỗi 502 Bad Gateway sau khi login thành công, lỗi này làm mình mày mò 2 ngày vì nghĩ là đã setting sai ở đâu đó:  

```
$ docker logs oauth2-proxy

172.18.0.3:34748 - 8d203ec4-bdc4-4bd0-b7f6-c3b149acb4d7 - - [2023/08/30 09:19:38] hello.YOUR_DOMAIN.duckdns.org GET - "/oauth2/start?rd=https%3A%2F%2Fhello.YOUR_DOMAIN.duckdns.org%2F" HTTP/1.0 "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36 Edg/116.0.1938.62" 302 456 0.000
172.18.0.3:34754 - 4b9048d0-779b-43fd-8f62-5f567f44f325 - user1@gmail.com [2023/08/30 09:19:46] [AuthSuccess] Authenticated via OAuth2: Session{email:user1@gmail.com user: PreferredUsername:user1 token:true id_token:true created:2023-08-30 09:19:46.717410685 +0000 UTC m=+871.010355512 expires:2023-08-30 09:24:46.716940725 +0000 UTC m=+1171.009885552 refresh_token:true groups:[role:offline_access role:default-roles-messi role:uma_authorization role:account:manage-account role:account:manage-account-links role:account:view-profile]}
[2023/08/30 09:19:46] [session_store.go:163] WARNING: Multiple cookies are required for this session as it exceeds the 4kb cookie limit. Please use server side session storage (eg. Redis) instead.
172.18.0.3:34754 - 4b9048d0-779b-43fd-8f62-5f567f44f325 - - [2023/08/30 09:19:46] oauth2.YOUR_DOMAIN.duckdns.org GET - "/oauth2/callback?state=34cFe_7SR8bI8JtwAhuX2rQrEHk3EkvuhYcmDJ48pVM%3Ahttps%3A%2F%2Fhello.YOUR_DOMAIN.duckdns.org%2F&session_state=29a4527d-e067-446b-81fc-b0326ccb2872&code=1217f09e-6ebe-4831-b313-3dd2ac600439.29a4527d-e067-446b-81fc-b0326ccb2872.a7a91ac8-c1ca-4cc2-b4ca-93796f1bcb0b" HTTP/1.0 "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36 Edg/116.0.1938.62" 302 64 0.303
172.18.0.3:34756 - 16d4aae3-4695-4b16-9504-42163e1c6c63 - - [2023/08/30 09:19:47] oauth2.YOUR_DOMAIN.duckdns.org GET - "/oauth2/auth" HTTP/1.0 "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/116.0.0.0 Safari/537.36 Edg/116.0.1938.62" 401 13 0.000
```

Solution: Cuối cùng thì tìm được người cũng bị lỗi này, là do nginx setting `proxy_buffer_size` mặc định là 4k, cần phải tăng lên 8k mới ok.
https://github.com/oauth2-proxy/oauth2-proxy/issues/646#issuecomment-654773777

Mình set trong file `oauth2.subdomain.conf`:  

```conf
~~~
    server_name oauth2.*;
    
    include /config/nginx/ssl.conf;

    location /oauth2/ {
        proxy_pass http://oauth2-proxy:4180;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Scheme $scheme;
        proxy_set_header X-Auth-Request-Redirect $scheme://$host$request_uri;
        proxy_buffer_size 8k; # <-------------------ADD HERE
    }
~~~
```

# 4. Thay Keycloak bằng Auth0 (Okta), Github

Use case này có vẻ khá phổ biến. Okta là 1 IdP nổi tiếng, có bản free và trả phí

## 4.1. Config on Auth0 (Okta)

Đăng ký account Auth0 (Okta), dùng version for DEVELOPMENT là đủ để test (bản Free của họ cho active 7000 users)

Tạo Application mới.  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/auth0-okta-app-list.jpg)

Vào tab Settings:
- Note lại Client ID, Client Secret.  
- Application Login URI: `https://vouch.YOUR_DOMAIN.duckdns.org/auth`
- Allow Callback URLs: `https://vouch.YOUR_DOMAIN.duckdns.org/auth`  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/auth0-okta-app-list-setting-1.jpg)  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/auth0-okta-app-list-setting-2.jpg)  

Kéo xuống dưới -> Save Changes.

Quay lại tab Settings, Kéo xuống Advanced Settings, Tab Endpoints chứa các endpoint cần note lại:  
- OAuth Authorization URL: `https://dev-XXX.auth0.com/authorize`  
- OAuth Token URL: `https://dev-XXX.auth0.com/oauth/token`  
- OAuth User info URL: `https://dev-XXX.auth0.com/userinfo`  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/auth0-okta-app-list-setting-3.jpg)  

Vào tab User, tạo 1 user để lát test. 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/auth0-okta-user-list.jpg)  

## 4.2. Config on Vouch Proxy

Sửa file `vouch-proxy/config/config.yml`, phần oauth:  

```yml
...
oauth:
  provider: oidc
  client_id: sczXXXXXXXXXXXXXXXXXX3FX
  client_secret: 8I7a-xxx-1xdA
  auth_url: https://dev-XXX.auth0.com/authorize
  user_info_url: https://dev-XXX.auth0.com/userinfo
  token_url: https://dev-XXX.auth0.com/oauth/token
  scopes:
    - openid
    - email
    - profile
  callback_url: https://vouch.YOUR_DOMAIN.duckdns.org/auth
```

Restart vouch-proxy `docker restart vouch-proxy`, check log ko có lỗi gì là OK.  

Test trên Browser, vào trang `https://hello.YOUR_DOMAIN.duckdns.org` sẽ redirect bạn đến trang login của Okta (ảnh)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/auth0-okta-login-screen.jpg)

Login thành công sẽ trở về `Hello World!` là OK.  

# 5. Không cần Internet, Bỏ Swag dùng Nginx thuần

Mình nghĩ về ý tưởng các app hoàn toàn run trong mạng nội bộ, ko expose ra Internet thì cần setup như nào?. Tất nhiên về lý thuyết là vẫn OK nhưng nhiều chỗ config sẽ khác biệt. Swag ko cần thiết mà chỉ cần Nginx thôi. 

[PENDING]

# 6. Interact with Keycloak API by Shell script

Sẽ có lúc bạn cần thực hiện 1 số thao tác tự động (không được dùng giao diện). Thì Keycloak cũng expose ra REST API để chúng ta call đến.  
Nguồn check rest API, vào đây: https://www.keycloak.org/documentation -> Tìm "Administration REST API"

## 6.1. Muốn change master admin password

Password trong biến môi trường `KEYCLOAK_ADMIN_PASSWORD` của docker-compose file chỉ là initial password cho lần đầu tạo, sau đó tạo lại thì nó sẽ ko được sử dụng nữa vì user admin đã tồn tại rồi. (credit: https://stackoverflow.com/a/71298007)

Thế nên các cách sau sẽ vô ích:  
- stop container keycloak rồi `docker-compose up -d` -> vẫn ăn pwd cũ
- `docker container rm keycloak` rồi `docker-compose up -d` -> vẫn ăn pwd cũ
- `docker-compose down` rồi `docker-compose up -d` -> vẫn ăn pwd cũ
- sửa trực tiếp file `docker-compose.yml` rồi `docker-compose down`, rồi `docker-compose up -d` -> vẫn ăn pwd cũ
- xóa `rm -rf /datadrive/docker-resources/postgres_data/*` rồi rồi `docker-compose down` rồi `docker-compose up -d` -> OK, nhưng mất hết data đã import.

Solution 1:  

Cách 1 là phải login vào psql server, xóa user admin đó đi nhưng trong link trên. Rồi `docker-compose up -d` lại:
```sh
docker exec -it keycloak-pgdb /bin/bash
# docker exec -it keycloak-pgdb /bin/bash
root@f5f8f303da54:/# psql -U keycloak
psql (13.11 (Debian 13.11-1.pgdg120+1))
Type "help" for help.

keycloak=# select * from user_entity;
-> Lấy được USER ID của admin. Giả sử là 'a23396aa-29da-4ed7-82a0-320d22847d0f'

keycloak=# delete from credential where user_id = 'a23396aa-29da-4ed7-82a0-320d22847d0f';
keycloak=# delete from user_role_mapping where user_id = 'a23396aa-29da-4ed7-82a0-320d22847d0f';
keycloak=# delete from user_entity where id = 'a23396aa-29da-4ed7-82a0-320d22847d0f';

```
Rồi `docker stop keycloak` và `docker-compose up -d` lại để tạo lại keycloak container.

Cách 1 này cần connect đến psql server cũng cần password. Mình nghĩ thà làm cách 2 bên dưới còn hơn.

Solution 2:

Cách 2 mình sẽ dùng pw cũ (đang ở /etc/environment) để lấy TOKEN, rồi change password bằng call REST API, như vậy ko bị mất data đã import:

```sh
KEYCLOAK_HOST=http://localhost:8080
ADMIN_MASTER_PASSWORD=$KEYCLOAK_ADMIN_PASSWORD
REALM_TO_UPDATE=master
USER1_NAME=admin
USER1_PASSWORD=Hehehehe1234  

# Get token from Master Realm admin
TOKEN=$(curl -s -X POST -H 'Content-Type: application/x-www-form-urlencoded' -d "username=admin&password=$ADMIN_MASTER_PASSWORD&client_id=admin-cli&grant_type=password" "$KEYCLOAK_HOST/realms/master/protocol/openid-connect/token" | jq -r ".access_token" ;)

# Get ID of User who you want to update
USER_ID=$(curl -s -X GET -H "Authorization: Bearer $TOKEN" -H "Content-type: application/json;charset=UTF-8" -H 'Accept: application/json' "$KEYCLOAK_HOST/admin/realms/$REALM_TO_UPDATE/users" | jq -r --arg USER1_NAME_ARG "$USER1_NAME" '.[] | select(.username==$USER1_NAME_ARG) | .id' )

# Update User password
curl -s -X PUT -H "Authorization: Bearer $TOKEN" -H "Content-type: application/json;charset=UTF-8" -H 'Accept: application/json' "$KEYCLOAK_HOST/admin/realms/$REALM_TO_UPDATE/users/$USER_ID/reset-password" -d "{\"type\":\"password\",\"value\":\"$USER1_PASSWORD\",\"temporary\":false}"

```

## 6.2. Get Keycloak client secret, regenerate secret, update user password

```sh
KEYCLOAK_HOST=http://YOUR-KEYCLOAK.com:8080
ADMIN_MASTER_PASSWORD=AAAAAXXXXXYYYYY
REALM_TO_UPDATE=messi
USER1_NAME=admin # is user you created in realm Loamics
USER1_PASSWORD=Hehehehe # is password of user you created in realm Loamics

# Get token from Master Realm admin
TOKEN=$(curl -s -X POST -H 'Content-Type: application/x-www-form-urlencoded' -d "username=admin&password=$ADMIN_MASTER_PASSWORD&client_id=admin-cli&grant_type=password" "$KEYCLOAK_HOST/realms/master/protocol/openid-connect/token" | jq -r ".access_token" ;)

# Get ID of User who you want to update
USER_ID=$(curl -s -X GET -H "Authorization: Bearer $TOKEN" -H "Content-type: application/json;charset=UTF-8" -H 'Accept: application/json' "$KEYCLOAK_HOST/admin/realms/$REALM_TO_UPDATE/users" | jq -r --arg USER1_NAME_ARG "$USER1_NAME" '.[] | select(.username==$USER1_NAME_ARG) | .id' )

# Update User password
curl -s -X PUT -H "Authorization: Bearer $TOKEN" -H "Content-type: application/json;charset=UTF-8" -H 'Accept: application/json' "$KEYCLOAK_HOST/admin/realms/$REALM_TO_UPDATE/users/$USER_ID/reset-password" -d "{\"type\":\"password\",\"value\":\"$USER1_PASSWORD\",\"temporary\":false}"


REALM_TO_GET_INFO=messi
CLIENT_ID=test-hoang

# Get client UID
CLIENT_UID=$(curl -s -X GET -H "Authorization: Bearer $TOKEN" -H "Content-type: application/json;charset=UTF-8" -H 'Accept: application/json' "$KEYCLOAK_HOST/admin/realms/$REALM_TO_GET_INFO/clients" | jq -r --arg CLIENT_ID_ARG "$CLIENT_ID" '.[] | select(.clientId==$CLIENT_ID_ARG) | .id' )

# Regenerate client secret
CLIENT_SECRET=$(curl -s -X POST -H "Authorization: Bearer $TOKEN" -H "Content-type: application/json;charset=UTF-8" -H 'Accept: application/json' "$KEYCLOAK_HOST/admin/realms/$REALM_TO_GET_INFO/clients/$CLIENT_UID/client-secret" | jq -r ".value" ;)

# Get current client secret
CLIENT_SECRET=$(curl -s -X GET -H "Authorization: Bearer $TOKEN" -H "Content-type: application/json;charset=UTF-8" -H 'Accept: application/json' "$KEYCLOAK_HOST/admin/realms/$REALM_TO_GET_INFO/clients/$CLIENT_UID/client-secret" | jq -r ".value" ;)
```


## 6.3. Config Keycloak to allow HTTP traffic (Not HTTPS by default)

(credit: https://stackoverflow.com/questions/70577004/keycloak-could-not-find-resource-for-full-path)

Nếu cần sửa keycloak để vào qua HTTP thường. Public internet cho test/dev thì:  
Sau khi deploy bằng docker-compose xong, phải login bằng account admin của master realm, rồi mới làm j thì làm:  

```sh
docker exec -it keycloak /bin/bash

bash-5.1$ cd /opt/keycloak/bin/
bash-5.1$ /opt/keycloak/bin/kcadm.sh config credentials --server http://localhost:8080 --realm master --user admin --password ThXtraDLaoBFSxctaqdpq79
Logging into http://localhost:8080 as user admin of realm master
bash-5.1$
bash-5.1$
bash-5.1$
bash-5.1$ /opt/keycloak/bin/kcadm.sh update realms/master -s sslRequired=NONE
bash-5.1$
```

Như vậy là bạn có thể access Keycloak mà không gặp lỗi yêu cầu HTTPS nữa.

# 7. Change/Forgot password of Docker Postgresql 

**Vấn đề**:  
Trường hợp nếu bạn Setup Keycloak với Postgresql bằng Docker Compose file.   
Bạn đặt biến env trong `docker-compose.yml` file `POSTGRES_USER=keycloak, POSTGRES_PASSWORD=XXX`.  
Rồi bạn quên password `POSTGRES_PASSWORD`,  
hoặc bạn muốn đổi password `POSTGRES_PASSWORD` từ XXX thành YYY. 
hoặc bạn đã đổi password 1 lần rồi, giờ password trong file `docker-compose.yml` không còn đúng nữa. Và bạn quên password mới đổi luôn rồi.  


**Giải pháp**:
Việc sửa file `docker-compose.yml` rồi `docker-compose up` sẽ ko có tác dụng gì. 
Cần SSH vào container của postgresql container, sửa trực tiếp trên database. Rồi run command: (Nó sẽ ko đòi hỏi password cũ vì đang trên localhost)

```sh
docker exec -it keycloak-pgdb /bin/bash
root@b4e1caa77cc1:/# psql -U keycloak
psql (13.11 (Debian 13.11-1.pgdg120+1))
Type "help" for help.

keycloak=# ALTER USER keycloak with password 'YYY';
ALTER ROLE
keycloak=#
```

Như vậy là `POSTGRES_PASSWORD` đã được đổi thành YYY.


# CREDIT

Docker compose Keycloak + Postgresql: https://www.mastertheboss.com/keycloak/keycloak-with-docker/

Docker Keycloak + Keycloak proxy: https://medium.com/docker-hacks/how-to-apply-authentication-to-any-web-service-in-15-minutes-using-keycloak-and-keycloak-proxy-e4dd88bc1cd5

Setup reverproxy for Keycloak: https://www.keycloak.org/server/reverseproxy  

Keycloak run on Docker Get Start Guilde: https://www.keycloak.org/getting-started/getting-started-docker  

Docker Keycloak + Traefik: https://github.com/ibuetler/docker-keycloak-traefik-workshop 

VouchProxy config file example:  
https://github.com/vouch/vouch-proxy/blob/master/examples/nginx/single-file/nginx_with_vouch_ssl.conf   
https://github.com/vouch/vouch-proxy/blob/master/config/config.yml_example   

VouchProxy + CILOGON: https://github.com/RENCI-NRIG/cilogon-vouch-proxy-example  

https://www.keycloak.org/docs/latest/authorization_services/index.html  

https://developers.redhat.com/blog/2020/01/29/api-login-and-jwt-token-generation-using-keycloak  

1 số bài tutorial về Oauth2Proxy:  
https://developer.okta.com/blog/2022/07/14/add-auth-to-any-app-with-oauth2-proxy  
https://medium.com/devops-dudes/using-oauth2-proxy-with-nginx-subdomains-e453617713a  
https://piotrkrzyzek.com/setup-keycloak-oauth2-proxy-via-docker-compose-npm-nginx-proxy-manager/  

Setting trong trang chủ của Oauth2-Proxy để connect đến Keycloak:  
https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/oauth_provider/#keycloak-oidc-auth-provider

Tổng hợp các config cho oauth2-proxy, với mỗi config ví dụ như `--api-route` nếu muốn đưa vào config file thì sửa thành `api_route` là được:  
https://oauth2-proxy.github.io/oauth2-proxy/docs/configuration/overview/#config-file  
