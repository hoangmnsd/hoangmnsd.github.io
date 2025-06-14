---
title: "Setup NextCloud with Swag (nginx) on a VM"
date: 2023-07-15T14:20:21+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [NextCloud,Docker-compose]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Mày mò chút về NextCloud..."
---

## 1. Story

Câu chuyện là mình đang cần tìm 1 app Notes (Todo Notes) mới thay thế cho ColorNote.

Tìm hiểu nhiều thì thấy có người ta giới thiệu NextCloud Notes App. Muốn dùng cái này thì cần phải cài đặt NextCloud server của riêng mình. Khá hay nên vọc vạch xem sao.

Nhưng ko ngờ con đường setup Nextcloud gian nan ko tưởng.

Bắt đầu: (Mình viết theo trình tự thời gian, giống như 1 bài nhật ký quá trình debug của mình)

---

## 2. Setup Nextcloud AIO với Docker Swag

Mình muốn cài NextCloud trên 1 remote VM.  

Mình hiện đang có 1 Cloud VM (Oracle Cloud arm64). Trước đây mình đã dùng config này setup swag như này để generate certificate valid cho toàn bộ subdomain (main domain thì ko được do limitation của duckdns):  

```yml
services:
  swag:
    image: lscr.io/linuxserver/swag:1.30.0
    container_name: swag
    cap_add:
      - NET_ADMIN
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Ho_Chi_Minh
      - URL=<REDACTED>.duckdns.org
      - VALIDATION=duckdns
      - SUBDOMAINS=wildcard, #optional
      - CERTPROVIDER= #optional
      - DNSPLUGIN=duckdns #optional
      - PROPAGATION= #optional
      - DUCKDNSTOKEN= #optional
      - EMAIL= #optional
      - ONLY_SUBDOMAINS=true #optional
      - EXTRA_DOMAINS= #optional
      - STAGING=true #optional
    volumes:
      - /opt/devops/swag/config:/config
    ports:
      - 443:443
      - 80:80 #optional
    restart: unless-stopped
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "10"
```

Nên giờ bất cứ subdomain nào dưới dạng `xyz.<REDACTED>.duckdns.org` cũng sẽ có valid HTTPS. (Cái này đã test ko cần show evident)

Sửa file compose, để add Nextcloud: 

```sh
version: '3.0'

services:
  # https://github.com/nextcloud/all-in-one/blob/main/compose.yaml
  nextcloud:
    image: nextcloud/all-in-one:latest
    container_name: nextcloud-aio-mastercontainer # This line is not allowed to be changed as otherwise AIO will not work correctly
    restart: always
    ports:
      - "8080:8080"
    volumes:
      - nextcloud_aio_mastercontainer:/mnt/docker-aio-config # This line is not allowed to be changed as otherwise the built-in backup solution will not work
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - NEXTCLOUD_DATADIR=/opt/devops/nextcloud_data
      - APACHE_PORT=11000 # Is needed when running behind a web server or reverse proxy (like Apache, Nginx, Cloudflare Tunnel and else). See https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md
      - APACHE_IP_BINDING=127.0.0.1 # Should be set when running behind a web server or reverse proxy (like Apache, Nginx, Cloudflare Tunnel and else) that is running on the same host. See https://github.com/nextcloud/all-in-one/blob/main/reverse-proxy.md
      - SKIP_DOMAIN_VALIDATION=true
  swag:
  ...
```

Rồi trong swag config folder, sửa file `swag/config/nginx/proxy-confs/nextcloud.subdomain.conf.sample` thành `swag/config/nginx/proxy-confs/nextcloud.subdomain.conf`. Rồi edit như sau:

```
server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name nextcloud.*;

    include /config/nginx/ssl.conf;

    client_max_body_size 0;

    location / {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app nextcloud-aio-apache;
        set $upstream_port 11000;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;

        proxy_max_temp_file_size 2048m;
    }
}
```

Rồi bình thường thì bạn có thể truy cập vào https://swag-domain:8080 để vào NextCloud AIO Interface để tiến hành setup. Từ màn hình đó dùng để cài đặt/install các containers.

Cài xong hết là được.

## 3. Debug

👀Nếu bị lỗi này: 

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/nextcloud-error-500.jpg)

Có thể do bạn đã ko set biến `APACHE_PORT=11000` trong file `docker-compose.yml`. Mình thiếu file này nên chạy mãi ko được.  

👀Nếu nhập domain vào báo lỗi như này:

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/nextcloud-error-validate-dns.jpg)

Dù đã generate certificate cho wildcard rồi, nghĩa là tất cả các subdomain đều có https, nhưng nhập vào đây thế nào cũng vẫn lỗi:  
```
Domain does not point to this server or the reverse proxy is not configured correctly. See the mastercontainer logs for more details. ('sudo docker logs -f nextcloud-aio-mastercontainer')
```

Check log thì:

```
Initial startup of Nextcloud All-in-One complete!
You should be able to open the Nextcloud AIO Interface now on port 8080 of this server!
E.g. https://internal.ip.of.this.server:8080

If your server has port 80 and 8443 open and you point a domain to your server, you can get a valid certificate automatically by opening the Nextcloud AIO Interface via:
https://your-domain-that-points-to-this-server.tld:8443
[Mon Jul 17 14:48:30.747248 2023] [mpm_event:notice] [pid 117:tid 280692189831264] AH00489: Apache/2.4.57 (Unix) OpenSSL/3.1.1 configured -- resuming normal operations
[Mon Jul 17 14:48:30.747713 2023] [core:notice] [pid 117:tid 280692189831264] AH00094: Command line: 'httpd -D FOREGROUND'
[17-Jul-2023 14:48:30] NOTICE: fpm is running, pid 122
[17-Jul-2023 14:48:30] NOTICE: ready to handle connections
{"level":"info","ts":1689605310.7652102,"msg":"using provided configuration","config_file":"/Caddyfile","config_adapter":""}
{"level":"info","ts":1689605310.768098,"msg":"failed to sufficiently increase receive buffer size (was: 208 kiB, wanted: 2048 kiB, got: 416 kiB). See https://github.com/quic-go/quic-go/wiki/UDP-Receive-Buffer-Size for details."}
</html>nter>nginx</center>y</h1></center>d>nnection attempt to "https://nextcloud.<REDACTED>.duckdns.org:443" was: <html>
NOTICE: PHP message: Expected was: 663ac3xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd02b
NOTICE: PHP message: The error message was:
</html>nter>nginx</center>y</h1></center>d>nnection attempt to "https://nextcloud.<REDACTED>.duckdns.org:443" was: <html>
NOTICE: PHP message: Expected was: 663ac3xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd02b
NOTICE: PHP message: The error message was:
</html>nter>nginx</center>y</h1></center>d>nnection attempt to "https://nextcloud.<REDACTED>.duckdns.org:443" was: <html>
NOTICE: PHP message: Expected was: 663ac3xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxd02b
NOTICE: PHP message: The error message was:
```

Có vẻ nó ko thể lấy được cái Expected string kia. Mà mình cũng ko biết làm sao để lấy được.  
Thế là phải skip bằng cách: `SKIP_DOMAIN_VALIDATION=true`. Mặc dù ko muốn skip đoạn này. Chưa tìm ra nguyên nhân.

Màn hình tiếp theo là ấn nút `Download and start containers`:  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/nextcloud-start-container-screen.jpg)

Rồi bạn có thể chờ nó load hết các container lên. 

👀Nếu chờ mãi ko thấy lên mà xem log thấy lỗi này:  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/nextcloud-error-on-1-containers.jpg)

```
$ docker logs nextcloud-aio-notify-push
Waiting for Nextcloud to start...
Waiting for Nextcloud to start...
Waiting for Nextcloud to start...
Waiting for Nextcloud to start...
nc: getaddrinfo for host "nextcloud-aio-nextcloud" port 9000: Try again
Waiting for Nextcloud to start...
Waiting for Nextcloud to start...


$ docker logs nextcloud-aio-nextcloud
              now
-------------------------------
 2023-07-16 07:28:48.017824+00
(1 row)

+ '[' -f /dev-dri-group-was-added ']'
++ find /dev -maxdepth 1 -mindepth 1 -name dri
+ '[' -n '' ']'
+ set +x
Installing imagemagick via apk...
Enabling Imagick...
Configuring Redis as session handler...
Setting php max children...
The initial Nextcloud installation failed.
Please reset AIO properly and try again. For further clues what went wrong, check the logs above.
See https://github.com/nextcloud/all-in-one#how-to-properly-reset-the-instance
              now
-------------------------------
 2023-07-16 07:28:55.400801+00
(1 row)

+ '[' -f /dev-dri-group-was-added ']'
++ find /dev -maxdepth 1 -mindepth 1 -name dri
+ '[' -n '' ']'
+ set +x
Configuring Redis as session handler...
Setting php max children...
The initial Nextcloud installation failed.
Please reset AIO properly and try again. For further clues what went wrong, check the logs above.
See https://github.com/nextcloud/all-in-one#how-to-properly-reset-the-instance
```

Lý do có thể do bạn chưa reset đúng cách, hãy làm theo cách step này: https://github.com/nextcloud/all-in-one#how-to-properly-reset-the-instance

👀Nếu chờ mãi thấy lỗi `nextcloud-aio-talk` vẫn bị unhealthy:

```
$ docker ps
CONTAINER ID   IMAGE                                        COMMAND                  CREATED          STATUS                      PORTS                                                                                                      NAMES
3dbef5644fb3   nextcloud/aio-talk:latest                    "/start.sh superviso…"   12 minutes ago   Up 12 minutes (unhealthy)   0.0.0.0:3478->3478/tcp, 0.0.0.0:3478->3478/udp, :::3478->3478/tcp, :::3478->3478/udp, 5349/tcp, 5349/udp   nextcloud-aio-talk
```

-> Nghĩa là bạn đang mở thiếu port 3478/UDP and 3478/TCP ra Internet cho cái service Talk đó chạy.

Ok hết là như này:  

```
$ docker ps
CONTAINER ID   IMAGE                                        COMMAND                  CREATED          STATUS                      PORTS                                                                                                      NAMES
1228ffe63f00   nextcloud/aio-apache:latest                  "/start.sh /usr/bin/…"   12 minutes ago   Up 12 minutes (healthy)     80/tcp, 127.0.0.1:11000->11000/tcp                                                                         nextcloud-aio-apache
e6a21f88095f   nextcloud/aio-notify-push:latest             "/start.sh"              12 minutes ago   Up 12 minutes (healthy)                                                                                                                nextcloud-aio-notify-push
c6d575ec05b6   nextcloud/aio-nextcloud:latest               "/start.sh /usr/bin/…"   12 minutes ago   Up 12 minutes (healthy)     9000/tcp                                                                                                   nextcloud-aio-nextcloud
391edb8e48d9   nextcloud/aio-imaginary:latest               "imaginary -return-s…"   12 minutes ago   Up 12 minutes (healthy)                                                                                                                nextcloud-aio-imaginary
9e08145fadbe   nextcloud/aio-redis:latest                   "/start.sh"              12 minutes ago   Up 12 minutes (healthy)     6379/tcp                                                                                                   nextcloud-aio-redis
ee10a24a0438   nextcloud/aio-postgresql:latest              "/start.sh"              12 minutes ago   Up 12 minutes (healthy)     5432/tcp                                                                                                   nextcloud-aio-database
3dbef5644fb3   nextcloud/aio-talk:latest                    "/start.sh superviso…"   12 minutes ago   Up 12 minutes (healthy)   0.0.0.0:3478->3478/tcp, 0.0.0.0:3478->3478/udp, :::3478->3478/tcp, :::3478->3478/udp, 5349/tcp, 5349/udp   nextcloud-aio-talk
7a84b580cc86   nextcloud/aio-collabora:latest               "/start-collabora-on…"   12 minutes ago   Up 12 minutes (healthy)     9980/tcp                                                                                                   nextcloud-aio-collabora
709af6c76f2c   nextcloud/all-in-one:latest                  "/start.sh /usr/bin/…"   14 minutes ago   Up 14 minutes (healthy)     80/tcp, 8443/tcp, 9000/tcp, 0.0.0.0:8080->8080/tcp, :::8080->8080/tcp                                      nextcloud-aio-mastercontainer

```


👀Tuy nhiên lỗi mới là lỗi 502 Bad Gateway:  

Khi ra màn hình này là khá OK:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/nextcloud-up-to-date.jpg)

Xong bạn ấn nút `Open your Nextcloud`, nó sẽ ra màn hình lỗi `502 Bad Gateway`.  

Check log:

```
$ docker logs nextcloud-aio-nextcloud

             now
------------------------------
 2023-07-17 10:49:23.21065+00
(1 row)

+ '[' -f /dev-dri-group-was-added ']'
++ find /dev -maxdepth 1 -mindepth 1 -name dri
+ '[' -n '' ']'
+ set +x
Configuring Redis as session handler...
Setting php max children...
System config value tempdirectory set to string /mnt/ncdata/tmp/
Applying one-click-instance settings...
System config value one-click-instance set to boolean true
System config value one-click-instance.user-limit set to integer 100
System config value one-click-instance.link set to string https://nextcloud.com/all-in-one/
support already enabled
Adjusting log files...
System config value upgrade.cli-upgrade-link set to string https://github.com/nextcloud/all-in-one/discussions/2726
System config value logfile set to string /var/www/html/data/nextcloud.log
Config value logfile for app admin_audit set to /var/www/html/data/audit.log
System config value updatedirectory set to string /nc-updater
Applying network settings...
System config value trusted_domains => 1 set to string nextcloud.<REDACTED>.duckdns.org
System config value overwrite.cli.url set to string https://nextcloud.<REDACTED>.duckdns.org/
System config value htaccess.RewriteBase set to string /
.htaccess has been updated
System config value files_external_allow_create_new_local set to boolean false
System config value trusted_proxies => 0 set to string 127.0.0.1
System config value trusted_proxies => 1 set to string ::1
Config value base_endpoint for app notify_push set to https://nextcloud.<REDACTED>.duckdns.org/push
Config value wopi_url for app richdocuments set to https://nextcloud.<REDACTED>.duckdns.org/
System config value allow_local_remote_servers set to boolean true
No ipv6-address found for nextcloud.<REDACTED>.duckdns.org.
Config value wopi_allowlist for app richdocuments set to 132.145.71.114,127.0.0.1/8,192.168.0.0/16,172.16.0.0/12,10.0.0.0/8,fd00::/8,::1
Config value recording_servers of app spreed deleted
System config value enabledPreviewProviders => 0 set to string OC\Preview\Imaginary
System config value preview_imaginary_url set to string http://nextcloud-aio-imaginary:9000
[17-Jul-2023 10:49:40] NOTICE: fpm is running, pid 336
[17-Jul-2023 10:49:40] NOTICE: ready to handle connections
Activating collabora config...
Failed to activate any config changes
Server error: `GET https://nextcloud.<REDACTED>.duckdns.org/hosting/discovery` resulted in a `502 Bad Gateway` response:
<html>
<head><title>502 Bad Gateway</title></head>
<body>
<center><h1>502 Bad Gateway</h1></center>
<hr><center>ngin (truncated...)

#0 /var/www/html/3rdparty/guzzlehttp/guzzle/src/Middleware.php(69): GuzzleHttp\Exception\RequestException::create(Object(GuzzleHttp\Psr7\Request), Object(GuzzleHttp\Psr7\Response), NULL, Array, NULL)
#1 /var/www/html/3rdparty/guzzlehttp/promises/src/Promise.php(204): GuzzleHttp\Middleware::GuzzleHttp\{closure}(Object(GuzzleHttp\Psr7\Response))
#2 /var/www/html/3rdparty/guzzlehttp/promises/src/Promise.php(153): GuzzleHttp\Promise\Promise::callHandler(1, Object(GuzzleHttp\Psr7\Response), NULL)
#3 /var/www/html/3rdparty/guzzlehttp/promises/src/TaskQueue.php(48): GuzzleHttp\Promise\Promise::GuzzleHttp\Promise\{closure}()
#4 /var/www/html/3rdparty/guzzlehttp/promises/src/Promise.php(248): GuzzleHttp\Promise\TaskQueue->run(true)
#5 /var/www/html/3rdparty/guzzlehttp/promises/src/Promise.php(224): GuzzleHttp\Promise\Promise->invokeWaitFn()
#6 /var/www/html/3rdparty/guzzlehttp/promises/src/Promise.php(269): GuzzleHttp\Promise\Promise->waitIfPending()
#7 /var/www/html/3rdparty/guzzlehttp/promises/src/Promise.php(226): GuzzleHttp\Promise\Promise->invokeWaitList()
#8 /var/www/html/3rdparty/guzzlehttp/promises/src/Promise.php(62): GuzzleHttp\Promise\Promise->waitIfPending()
#9 /var/www/html/3rdparty/guzzlehttp/guzzle/src/Client.php(187): GuzzleHttp\Promise\Promise->wait()
#10 /var/www/html/lib/private/Http/Client/Client.php(226): GuzzleHttp\Client->request('get', 'https://nextclo...', Array)
#11 /var/www/html/custom_apps/richdocuments/lib/WOPI/DiscoveryManager.php(89): OC\Http\Client\Client->get('https://nextclo...', Array)
#12 /var/www/html/custom_apps/richdocuments/lib/WOPI/DiscoveryManager.php(61): OCA\Richdocuments\WOPI\DiscoveryManager->fetchFromRemote()
#13 /var/www/html/custom_apps/richdocuments/lib/WOPI/Parser.php(41): OCA\Richdocuments\WOPI\DiscoveryManager->get()
#14 /var/www/html/custom_apps/richdocuments/lib/Command/ActivateConfig.php(67): OCA\Richdocuments\WOPI\Parser->getUrlSrc('Capabilities')
#15 /var/www/html/3rdparty/symfony/console/Command/Command.php(255): OCA\Richdocuments\Command\ActivateConfig->execute(Object(Symfony\Component\Console\Input\ArgvInput), Object(Symfony\Component\Console\Output\ConsoleOutput))
#16 /var/www/html/3rdparty/symfony/console/Application.php(1009): Symfony\Component\Console\Command\Command->run(Object(Symfony\Component\Console\Input\ArgvInput), Object(Symfony\Component\Console\Output\ConsoleOutput))
#17 /var/www/html/3rdparty/symfony/console/Application.php(273): Symfony\Component\Console\Application->doRunCommand(Object(OCA\Richdocuments\Command\ActivateConfig), Object(Symfony\Component\Console\Input\ArgvInput), Object(Symfony\Component\Console\Output\ConsoleOutput))
#18 /var/www/html/3rdparty/symfony/console/Application.php(149): Symfony\Component\Console\Application->doRun(Object(Symfony\Component\Console\Input\ArgvInput), Object(Symfony\Component\Console\Output\ConsoleOutput))
#19 /var/www/html/lib/private/Console/Application.php(211): Symfony\Component\Console\Application->run(Object(Symfony\Component\Console\Input\ArgvInput), Object(Symfony\Component\Console\Output\ConsoleOutput))
#20 /var/www/html/console.php(100): OC\Console\Application->run()
#21 /var/www/html/occ(11): require_once('/var/www/html/c...')
#22 {main}
```


```
$ docker logs nextcloud-aio-apache

Waiting for Nextcloud to start...
Waiting for Nextcloud to start...
Waiting for Nextcloud to start...
Waiting for Nextcloud to start...
Waiting for Nextcloud to start...
Waiting for Nextcloud to start...
Waiting for Nextcloud to start...
Waiting for Nextcloud to start...
Waiting for Nextcloud to start...
Waiting for Nextcloud to start...
Waiting for Nextcloud to start...
Waiting for Nextcloud to start...
Waiting for Nextcloud to start...
Waiting for Nextcloud to start...
Waiting for Nextcloud to start...
Waiting for Nextcloud to start...
[Mon Jul 17 07:23:41.435697 2023] [mpm_event:notice] [pid 71:tid 280592317489248] AH00489: Apache/2.4.57 (Unix) configured -- resuming normal operations
[Mon Jul 17 07:23:41.435738 2023] [core:notice] [pid 71:tid 280592317489248] AH00094: Command line: '/usr/local/apache2/bin/httpd -D FOREGROUND'
{"level":"info","ts":1689578621.448192,"msg":"using provided configuration","config_file":"/Caddyfile","config_adapter":""}
[Mon Jul 17 07:31:42.303030 2023] [mpm_event:notice] [pid 24:tid 281430654910560] AH00489: Apache/2.4.57 (Unix) configured -- resuming normal operations
[Mon Jul 17 07:31:42.304834 2023] [core:notice] [pid 24:tid 281430654910560] AH00094: Command line: '/usr/local/apache2/bin/httpd -D FOREGROUND'
{"level":"info","ts":1689579102.3194304,"msg":"using provided configuration","config_file":"/Caddyfile","config_adapter":""}
```

Có vẻ apache ko chạy được, ko hiểu vì sao nó cứ load config từ /Caddyfile mà mình chưa dùng

Dù ko muốn nhưng cuối cùng phải thử run cùng với caddy theo cách này: https://github.com/nextcloud/all-in-one/discussions/575#discussion-4055615

Nhưng vẫn bị lỗi. Do mình đang chạy `swag` để expose 1 service khác ra HTTPS (ytalexa), nên ko thể run thêm `caddy` nữa vì sẽ bị trùng port 443. Nếu stop Swag để run Caddy thì cũng sẽ ko issue được certificate (khả năng là vi mình đã xin wildcard domain cho cái domain đó bằng Swag rồi):  

```
$ docker logs caddy

{"level":"error","ts":1689609231.1199305,"logger":"http.acme_client","msg":"validating authorization","identifier":"nc.<REDACTED>.duckdns.org","problem":{"type":"urn:ietf:params:acme:error:connection","title":"","detail":"132.145.71.114: Error getting validation data","instance":"","subproblems":[]},"order":"https://acme-staging-v02.api.letsencrypt.org/acme/order/111277074/9804874094","attempt":2,"max_attempts":3}
{"level":"error","ts":1689609231.1199572,"logger":"tls.obtain","msg":"could not get certificate from issuer","identifier":"nc.<REDACTED>.duckdns.org","issuer":"acme-v02.api.letsencrypt.org-directory","error":"HTTP 400 urn:ietf:params:acme:error:connection - 132.145.71.114: Error getting validation data"}
{"level":"info","ts":1689609231.3198948,"logger":"http.acme_client","msg":"trying to solve challenge","identifier":"nc.<REDACTED>.duckdns.org","challenge_type":"http-01","ca":"https://acme.zerossl.com/v2/DV90"}
{"level":"error","ts":1689609232.0329041,"logger":"http.acme_client","msg":"challenge failed","identifier":"nc.<REDACTED>.duckdns.org","challenge_type":"http-01","problem":{"type":"","title":"","detail":"","instance":"","subproblems":[]}}
{"level":"error","ts":1689609232.032963,"logger":"http.acme_client","msg":"validating authorization","identifier":"nc.<REDACTED>.duckdns.org","problem":{"type":"","title":"","detail":"","instance":"","subproblems":[]},"order":"https://acme.zerossl.com/v2/DV90/order/1Ez2PNwRKuD_4Pbu8lIBpQ","attempt":1,"max_attempts":3}
{"level":"error","ts":1689609232.033002,"logger":"tls.obtain","msg":"could not get certificate from issuer","identifier":"nc.<REDACTED>.duckdns.org","issuer":"acme.zerossl.com-v2-DV90","error":"HTTP 0  - "}
{"level":"error","ts":1689609232.033033,"logger":"tls.obtain","msg":"will retry","error":"[nc.<REDACTED>.duckdns.org] Obtain: [nc.<REDACTED>.duckdns.org] solving challenge: nc.<REDACTED>.duckdns.org: [nc.<REDACTED>.duckdns.org] authorization failed: HTTP 0  -  (ca=https://acme.zerossl.com/v2/DV90)","attempt":2,"retrying_in":120,"elapsed":74.134302897,"max_duration":2592000}
```

Nếu mình sửa `Caddyfile` thành:  

```
http://nc.<REDACTED>.duckdns.org:80 {
    header Strict-Transport-Security max-age=31536000;
    reverse_proxy localhost:11000
}
```

```
$ docker logs caddy

{"level":"info","ts":1689609293.1893675,"logger":"admin","msg":"stopped previous server","address":"localhost:2019"}
{"level":"info","ts":1689609293.189381,"msg":"shutdown complete","signal":"SIGTERM","exit_code":0}
{"level":"info","ts":1689609661.052052,"msg":"using provided configuration","config_file":"/etc/caddy/Caddyfile","config_adapter":"caddyfile"}
{"level":"warn","ts":1689609661.0536613,"msg":"Caddyfile input is not formatted; run the 'caddy fmt' command to fix inconsistencies","adapter":"caddyfile","file":"/etc/caddy/Caddyfile","line":2}
{"level":"info","ts":1689609661.0558805,"logger":"admin","msg":"admin endpoint started","address":"localhost:2019","enforce_origin":false,"origins":["//localhost:2019","//[::1]:2019","//127.0.0.1:2019"]}
{"level":"warn","ts":1689609661.0567436,"logger":"http","msg":"server is listening only on the HTTP port, so no automatic HTTPS will be applied to this server","server_name":"srv0","http_port":80}
{"level":"info","ts":1689609661.0567982,"logger":"tls.cache.maintenance","msg":"started background certificate maintenance","cache":"0x40004b2b60"}
{"level":"info","ts":1689609661.0569763,"logger":"tls","msg":"cleaning storage unit","description":"FileStorage:/data/caddy"}
{"level":"info","ts":1689609661.0570025,"logger":"tls","msg":"finished cleaning storage units"}
{"level":"info","ts":1689609661.0571907,"logger":"http.log","msg":"server running","name":"srv0","protocols":["h1","h2","h3"]}
{"level":"info","ts":1689609661.057759,"msg":"autosaved config (load with --resume flag)","file":"/config/caddy/autosave.json"}
{"level":"info","ts":1689609661.0577765,"msg":"serving initial configuration"}
```

Nhưng khi validate domain bằng AIO interface sẽ bị lỗi: (Vì nó cứ trỏ đến :443 để check)  

```
$ docker logs nextcloud-aio-mastercontainer

NOTICE: PHP message: The response of the connection attempt to "https://nc.<REDACTED>.duckdns.org:443" was: <html>    <head>        <title>Welcome to your SWAG instance</title>        <style>        body{            font-family: Helvetica, Arial, sans-serif;        }        .message{            width:440px;            padding:20px 40px;            margin:0 auto;            background-color:#f9f9f9;            border:1px solid #ddd;            color: #1e3d62;        }        center{            margin:40px 0;        }        h1{            font-size: 18px;            line-height: 26px;        }        p{            font-size: 12px;        }        a{            color: rgb(207, 48, 139);        }        </style>    </head>    <body>        <div class="message">            <h1>Welcome to your <a target="_blank" href="https://github.com/linuxserver/docker-swag">SWAG</a> instance</h1>            <p>A webserver and reverse proxy solution brought to you by <a target="_blank" href="https://www.linuxserver.io/">linuxserver.io</a> with php support and a built-in Certbot client.</p>            <p>We have an article on how to use swag here: <a target="_blank" href="https://docs.linuxserver.io/general/swag">docs.linuxserver.io</a></p>            <p>For help and support, please visit: <a target="_blank" href="https://www.linuxserver.io/support">linuxserver.io/support</a></p>        </div>    </body></html>
NOTICE: PHP message: Expected was: e6140d2b93d90816fa34d54a7840d8c152346d363414f81d
NOTICE: PHP message: The error message was:

```

Đến đây mình nghĩ vấn đề 99% là năm ở cái apache `nextcloud-aio-apache`. Phải làm sao để nó chạy được thì sẽ qua được lỗi 502 Bad Gateway.

Sau 1 thời gian tìm hiểu ko thấy cách nào debug được. 

Thử cài ko ở mode reverse proxy, rồi dùng Putty tunnel xem vào được ko? -> Mặc dù vào được AIO interface như login xong là bị lỗi 500 tùm lum.  
```
GuzzleHttp\Exception\ServerException
Code: 500
Message: Server error: `POST http://localhost/v1.41/containers/nextcloud-aio-domaincheck/start` resulted in a `500 Internal Server Error` response: {"message":"driver failed programming external connectivity on endpoint nextcloud-aio-domaincheck (a83747a3704fd3a423e34 (truncated...)
```

Phát hiện ra 1 điều kỳ lạ: trong VM, nếu curl đến server `next-aio-apache` bằng cách: 

`curl http://localhost:11000` -> sẽ ko trả ra kết quả gì.  

`curl http://localhost:11000/login` -> sẽ trả về data của page NextCloud Login!!!! Ảo vãi!

Tiếp tục thử lại bằng Tunnel, trên PC của mình sau khi đã tunnel theo bài viết [này](../../posts/encrypt-expose-localhost-webapp-by-ssh-tunnel/). Thì có thể bật giao diện web Firefox, Chrome (not incognito mode), `http://localhost:11000/login` vào được NextCloud Login!!!

Tiếp tục login thì nó lại redirect về cái page `https://nextcloud.<REDACTED>.duckdns.org`. Chỉ cần sửa lại url thay domain bằng: `http://localhost:11000` là vào được giao diện Nextcloud. Ảo ma!

Đến đây mình quay xe, dường như `nextcloud-aio-apache` ko có lỗi. Lỗi ở Nginx của Swag...  

Giờ mình test bằng cách `docker exec -it swag sh` vào swag, thử curl:  
- `curl youtubestreamrepeater:4000` -> OK
- `curl nextcloud-aio-apache:11000` -> NG
- `curl nextcloud-aio-apache:11000/login` -> NG
- `curl http://localhost:11000/login` -> NG

Như vậy là mình hiểu ra vấn đề: Do `swag` và `nextcloud-aio-apache` đang nằm trong 2 network khác nhau, chúng ko thể nói chuyện với nhau được.  

```
$ docker network ls
NETWORK ID     NAME                DRIVER    SCOPE
234447d5b5cd   bridge              bridge    local
a94c129234a4   devops_default      bridge    local
ac19cf8ae7cd   host                host      local
3e5d3413a98e   nextcloud-aio       bridge    local
b920d04f1d19   none                null      local
```

Dùng `docker inspect` sẽ biết được các container đang nằm trong network nào:  
`swag` nằm trong `devops_default` network, còn 
`nextcloud-aio-apache` nằm trong `nextcloud-aio` network.

Bây giờ cần làm sao để `swag` có thể call được đến container `nextcloud-aio-apache`, mình sẽ dùng `docker network connect` để connect:

```sh
docker network connect nextcloud-aio swag
```

Sau command trên, swag đã nằm trong 2 network luôn, nhờ thế mà nó sẽ gọi được container apache test:

```
~$ docker exec -it swag sh
root@074c9822ed36:/#
root@074c9822ed36:/# curl youtubestreamrepeater:4000
{"detail":"Not Found"}
root@074c9822ed36:/# curl nextcloud-aio-apache:11000
root@074c9822ed36:/# curl nextcloud-aio-apache:11000/login
<!DOCTYPE html>
<html class="ng-csp" data-placeholder-focus="false" lang="en" data-locale="en" translate="no" >
        <head

```

## 4. Túm lại

Vẫn làm mọi thứ như đã đề cập Phần #2

Sau đó cần check lại xem từ trong swag có thể call đến `nextcloud-aio-apache` ko? Nếu ko thì cần connect swag đến network `nextcloud-aio` như bên trên.
Thế là xong. 

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/nextcloud-welcome-page.jpg)

## 5. Cách khác

Nếu tuyệt vọng quá, mình sẽ phải từ bỏ Nextcloud AIO, và chuyển sang dùng 1 số guide khác:  
- Setup NextCloud Manual: https://github.com/nextcloud/all-in-one/tree/main/manual-install    
- Dùng image của linuxserver: https://docs.linuxserver.io/general/swag#nextcloud-subdomain-reverse-proxy-example

Chúc các bạn thành công 🤞

## CREDIT

https://docs.linuxserver.io/general/swag#nextcloud-subdomain-reverse-proxy-example  
https://github.com/nextcloud/all-in-one/tree/main/manual-install  
https://github.com/nextcloud/all-in-one/discussions/575#discussion-4055615  
https://github.com/nextcloud/all-in-one#how-to-properly-reset-the-instance  
  