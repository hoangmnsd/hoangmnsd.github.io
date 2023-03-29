---
title: "Connect Home Assistant to Amazon Alexa Echo Dot4"
date: 2022-11-25T23:09:57+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [HomeAssistant]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Bài này tổng hợp các tut khi sử dụng Alexa Echo Dot4 của mình"
---


# 1. Setup Alexa connect to Home Assistant

Làm theo hướng dẫn ở đây:  
https://www.home-assistant.io/integrations/alexa.smart_home/ 

## 1.1. Setup

Trên AWS Console create Role for Lambda:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-lambda-create-role1.jpg)  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-lambda-create-permision.jpg)  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-lambda-create-role2.jpg)  

Trên Alexa developer page, create skill:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-lambda-create-skill-dashboard.jpg)  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-lambda-create-skill-smt-home.jpg)  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-lambda-create-skill-smt-home-2.jpg)  

Trên AWS Console Lambda, tạo function, nên chọn us-east-1 vì các region khác dễ bị lỗi lắm:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-lambda-create-function-1.jpg)  

Set trigger to Alexa:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-lambda-add-trigger1.jpg)  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-lambda-add-trigger2.jpg)  

Upload code from Github:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-lambda-add-code-from-github.jpg)  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-lambda-add-code-from-github2.jpg)  

Setup Environment variables:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-lambda-add-env-var-baseurl.jpg)  

Update home assistant file `configuration.yml`:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-update-hass-config-file.jpg)  

Create long live token để test tý nữa:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-create-long-live-token-for-test-lambda.jpg)   

Test Lambda:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-test-lambda.jpg)  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-test-lambda-result-ok.jpg)  

Copy Lambda ARN:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-copy-function-arn.jpg)  

Trên Alexa Developer Page, paste function ARN:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-config-smart-home-tab-function-arn.jpg)  

Trên Alexa Developer Page, setup Link account:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-setup-account-linking.jpg)  

Chỗ `Your Client ID`, nên chọn https://pintagui.amazon.com/:    
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-setup-account-link2.jpg)

Giờ login vào app Alexa trên điện thoại (Nếu bạn dung Iphone, có thể bạn sẽ phải chuyển vùng US để tải app, dùng Android sẽ cần down file APK):  
Vào tab `Skill & Game`, Your Skill sẽ thấy Skill của bạn vừa tạo:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-config-on-alexa-mobile-app1.jpg)  

Login để link account thành công nhé, nếu dùng wifi ko login dc thì hãy dùng 4G

Sau khi login thì App sẽ tự động discovery devices


## 1.2. Troubeshooting

Bạn có thể dùng web sau để thay cho app trên điện thoại:  
https://alexa.amazon.com

- Lỗi vì chọn Singapore, 1 region không được chấp nhận:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-error-with-singapore-region.jpg)  

- Lỗi vì chọn Trigger nhầm skill set mà ko chọn `Smart Home`:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-error-with-setup-trigger-for-lambda.jpg)  

- Lỗi vì mình chọn `Your Client ID` là cái link `...jp/` phải dùng `https://pintagui.amazon.com/`:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-error-with-clientid-jp.jpg)

- Nếu bị lỗi ko discovery được device sau khi linked account, solution: Đổi hết stack sang English (US), lambda sang N.Verginia region:    
https://community.home-assistant.io/t/alexa-integration-does-not-find-devices/193732/5


# 2. Setup Youtube Skill for Alexa

Làm theo hướng dẫn ở đây:  
https://github.com/hoangmnsd/YouTubeForAlexa

## 2.1. Setup trên GCP 

vào đây tạo project:  
https://console.developers.google.com/project  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-gcp-create-project-gcp.jpg)  

vào đây:  
https://console.developers.google.com/apis/library?project=tester-api-key  

search youtube data API v3. Enable it:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-gcp-search-yt-api-v3.jpg)  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-gcp-enable-yt-api-v3.jpg)  

Click on "Create Credentials"

Set like this:  
- “Which API are you using?”: YouTube Data API v3
- “From where you call the API?”: Server web (ex. node.js, Tomcat)
- “Which data you use?”: Public Data
- Click on “Which credentials i need?”

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-gcp-yt-api-v3-create-creds.jpg)  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-gcp-yt-api-v3-create-creds-next.jpg)  

After some seconds you will see under “Get your credentials” the key that wee need.

COPY and SAVE the key in the notepad.

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-gcp-yt-api-v3-create-creds-done.jpg)  



## 2.2. Setup trên AWS

Create lambda function on `us-east-1`:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-aws-create-lambda.jpg)

Add trigger for Lambda, note that Skill ID verification:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-aws-create-lambda-select-trigger.jpg)

Upload zip file from https://github.com/wes1993/YouTubeForAlexa/blob/master/YouTubeForAlexaLambda.zip  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-aws-create-lambda-upload-zip-code.jpg)

Set Environment variable for Lambda, mình chọn `pytube` để test thôi, người ta khuyên dùng `youtube_dl` vì nó ổn định hơn tuy hơi chậm:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-aws-create-lambda-add-env-var.jpg)

Setup timeout to 30s, Memory to 512 Mb:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-aws-create-lambda-edit-basic-setting.jpg)

## 2.3. Setup trên Alexa Developer Page

Go to the Alexa Console (https://developer.amazon.com/alexa/console/ask):  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-skill-create-custom-skill.jpg)  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-skill-choose-template.jpg)  

Invocation name chọn `my youtube`, ko nên chọn `you tube` vì dễ phát âm sai:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-skill-update-invocation-name.jpg)  

Update JSON Editor:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-skill-update-json-editor.jpg)  

Update Interface:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-skill-update-interfaces.jpg)  

Update Endpoints:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-skill-update-endpoint.jpg)  

Update permission tab:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-skill-update-permission-tab.jpg)

click Build Model and wait for success

Enable Test development:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-skill-enable-test-development.jpg)  

## 2.4. Test Youtube skill

`Alexa launch youtube`: sau command này sẽ thấy trong list của Alexa app có list Youtube Favorite, Youtube:  
https://alexa.amazon.com/

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-app-lists.jpg)

Update Youtube Alexa list, Mình sửa lại các playlist public Youtube: 
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-app-lists-fav.jpg)

Giải thích:  
`My News playlist`: tin mới của VTC NOW  
`My Vietnam TV playlist`: chuyển động 24h VTV   

`My Black playlist`: Đen vâu official  
`That song I like`: Show của Đen  
`My Dragon playlist`: Imagine Dragon   
`My Taylor playlist`: Taylor Swift  
`My Super awsome playlist`: Phan Mạnh Quỳnh   

`My Social playlist`: Kiến thức thú vị playlist  
`My Billionaire playlist`: tổ buôn 247 tuấn tiền tỉ  

Command to use:  
`Alexa launch youtube`: command này sẽ khởi tạo bạn đầu các Favorite Youtube list cho bạn  
`Alexa stop / next / previous / shuffle`: phải stop trước.  
`Alexa ask my youtube to play [My Dragon playlist]`:  chú ý phát âm `my youtube`


## 2.5. Optional steps

Có 3 lỗi mà mình gặp phải trong quá trình dùng skill này:  
- 1. Lỗi `Playback failed, "Device playback error", MEDIA ERROR`  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-lambda-red-playlist-error-media.jpg)  
Có những playlist lỗi ngay cả khi dùng hoặc ko dùng proxy như 2 playlist này:  
Taylor playlist | https://www.youtube.com/playlist?list=PLMEZyDHJojxNYSVgRCPt589DI5H7WT1ZK  
Red playlist | https://www.youtube.com/playlist?list=PLvaeEf26a-mB6RsQ1UjLfAhGypELXulZE  
**Solution: chưa tìm ra..**

- 2. Lỗi `Nếu trong playlist có các video vi phạm chính sách Youtube bị ẩn đi thì Alexa sẽ stop luôn playlist`:  
mình đã log issue: https://github.com/wes1993/YouTubeForAlexa/issues/23  
**Solution: chưa tìm ra..**

- 3. Lỗi `Vì Lambda call đến Youtube từ IP của Lambda region (US) nên sẽ có 1 số video chỉ khả dụng ở Vietnam sẽ ko thể play được`.   
**Solution: Dùng forward proxy `tiny proxy`** (https://github.com/hoangmnsd/YouTubeForAlexa#extra-step-optional)

Dưới đây mình viết về việc mình làm để chạy tinyproxy:  

---
Cài tinyproxy để làm forward proxy. (Để hiểu forward proxy và reserve proxy khác như nào thì xem bài này nhé: 
[Reverse proxy and Forward proxy](../../posts/reverse-proxy-forward-proxy/))

theo hướng dẫn này: https://github.com/hoangmnsd/YouTubeForAlexa#extra-step-optional

Nói nôm na thì ta sẽ setup để Lambda ko call trực tiếp đến Youtube mà đi qua tinyproxy rồi mới đến Youtube, như vậy Youtube sẽ hiểu các request là đến từ 1 IP cố định của nhà mình, chứ ko phải đến từ Lambda

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/yt-alexa-aws-create-lambda-add-env-var-proxy.jpg)

Mình đã thử run docker trên RPi nhưng bị lỗi (có lẽ do Rpi là arm64 nên ko dùng dc image của vimagick trên Docker Hub). Nên phải build lại image trên RPi để chạy theo Dockerfile ở đây: https://github.com/vimagick/dockerfiles/tree/master/tinyproxy

Test trong local thì ok nhưng khi test Lambda ko connect dc đến tinyproxy trong mạng nhà mình. Có thể vì mình ko thể expose port 8888 ra được, mà mình cũng ko muốn expose nhiều port ra.  

-> Mình chuyển qua cài tinyproxy trên VM Oracle Cloud của mình. Sẽ cần mở all port 8888.  

Do VM Oracle của mình là ip UK nên sẽ có 1 số playlist ko thể play được, ví dụ như các playlist của VTC, VTV24 (Chắc VTV24 chỉ publish video cho khu vực Vietnam xem)

Mình đang tính thuê VPS của Vietnam như hostingviet.vn 130k/tháng, để cài tinyproxy

nhưng kể cả cài proxy thì chỉ có thể fix được lỗi số 3 thôi, ko fix được lỗi 1 & 2 😪😪

**Update 2023/Jan/07**:  

Sau khi mình thuê 1 VPS của hostingviet.vn với giá 135k/tháng thì vẫn ko play được video latest trong 1 channel

Nếu dùng proxy của Hostingviet, mình set 1 HA script TTS cho Alexa rằng "ask My Youtube to play channel VTV1 VTV Go" thì:   
- lỗi 1 là nó ko play clip latest của Channel đó,  
- lỗi 2 là được 1 lúc thì thường xuyên trả về lỗi `"The channel XXX hasn't worked, shall I try the next one?"`  

Đã thử chuyển biến môi trường của AWS Lambda qua lại `pytube`, `youtube-dl` nhưng vẫn ko fix được lỗi 1, lỗi 2.

Nhưng nếu chuyển proxy sang dùng VM của Oracle thì ko bị lỗi số 2, tuy nhiên vẫn ko fix được lỗi 1 (mà play 1 clip từ 14/06/2022.)

Còn nếu set cứng Youtube playlist URL trên Alexa app thì gặp phải lỗi: Do Admin kênh VTV1 VTV Go đang sắp xếp thứ tự từ oldest đến latest, nên khi play thì luôn bắt đầu từ clip cũ nhất, phải "next" mãi mới đến clip latest. Hoặc là cứ ra lệnh "shuffle" rồi next mãi để may mắn đến clip latest.😃🤣


## 2.6. Update 2023.02 using Youtube Stream Repeater

Tháng 2.2023, [wes1993](https://github.com/wes1993/YouTubeForAlexa) đã release 1 bản update mới với cập nhật là sử dụng [YouTube-Stream-Repeater](https://github.com/DavidBerdik/YouTube-Stream-Repeater) để stream Youtube video/audio, có thể coi là ổn định hơn `pytube và youtube-dl`. Thực sự là version cũ nhiều lỗi quá, cứ 1 tháng dùng khoảng 10 15 ngày là lại lỗi. Mà lỗi rất khó debug luôn, chả hiểu nguyên nhân gì mà tự nhiên bị lỗi, thường Alexa sẽ ko phát Youtube video và nói "Video hasn't work". Hy vọng là lần update này sẽ khá hơn.  

Tuy nhiên thì Stephano (aka wes1993) đã tạo ra 1 Home Assistant Addon để integrate.  

Với mình cách này ko dùng được, vì mình đang sử dụng Home Assistant Container, ko có chức năng Addon.

Và, mình cũng ko thích dùng Addon vì nó đặc thù cho HomeAssistant quá. 

Lần mò khi đọc comment [này](https://github.com/DavidBerdik/YouTube-Stream-Repeater/issues/1#issuecomment-1407498032) thì mình thấy cách của DavidBerdik phù hợp với mình hơn.

Mình muốn làm thử kiểu này: (diagram)  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-yt-stream-repeater.jpg)

Vì mình có 1 Oracle VM (4CPU/24GB RAM) đang chưa tận dụng hết, sẽ run `YouTube-Stream-Repeater` container, expose ra HTTPS url.

AWS Lambda sẽ request đến `YouTube-Stream-Repeater`, và Alexa sẽ serve audio từ đó.

Mình ko run `YouTube-Stream-Repeater` trên RPi ở trong mạng local cùng với HA vì:  
- Con RPi đang dùng Wifi 2.4Ghz, kết nối internet của nó khá chậm,  
- RPi cũng gần full bộ nhớ rồi (80%).   
- Việc expose mạng gia đình thêm 1 app trên port 4000 nữa làm mình thấy lo lắng. Mình muốn expose càng ít càng tốt (Hiện tại đang expose HomeAssistant rồi)  

Dưới đây là các step khi mình đã làm:  

### 2.6.1. Expose VM Oracle to HTTPs with swag

Tạo 1 subdomain `<REDACTED>.duckdns.org` trên https://duckdns.org (có thể phải dùng VPN để vào được)

Trên vm Oracle cloud, sửa Security Group: expose port 80,443

Cài swag theo bài [này](../../posts/encrypt-setup-home-assistant-on-raspberry-pi-p3-https):  

File `/opt/devops/docker-compose.yml`:  

```
version: '3.0'

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
      - DNSPLUGIN=cloudflare #optional
      - PROPAGATION= #optional
      - DUCKDNSTOKEN= #optional
      - EMAIL= #optional
      - ONLY_SUBDOMAINS=false #optional
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

Chú ý mình đang chỉ định STAGING=true để test việc request staging trước

Tạo sẵn folder `/opt/devops/swag/config`

Run:  

```sh
cd /opt/devops/
docker-compose up -d
```

Check log như này là ok:  

```
$ docker logs swag
...
Successfully received certificate.
Certificate is saved at: /etc/letsencrypt/live/<REDACTED>.duckdns.org/fullchain.pem
Key is saved at:         /etc/letsencrypt/live/<REDACTED>.duckdns.org/privkey.pem
This certificate expires on 2023-06-18.
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
cont-init: info: /etc/cont-init.d/70-outdated exited 0
cont-init: info: running /etc/cont-init.d/85-version-checks
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

Trên browser access vào `<REDACTED>.duckdns.org`, Nếu browser báo unsecure, phải ấn vào "wish to continue" thì là bình thường vì mình đang dùng `STAGING=true` mà, thấy giao diện "Welcome to your SWAG instance" là OK.

Sửa lại file: `docker-compose.yml`:  

```
STAGING=false
```

Xong chạy lại:  

```sh
cd /opt/devops/
docker-compose up -d
```

Check `docker logs swag` ko có lỗi gì và Nếu hiện `Server ready` là OK.  

Vào 1 Browser ẩn danh khác check: `<REDACTED>.duckdns.org`, ko thấy trình duyệt báo unsecure, ko cần phải ấn vào "wish to continue", thấy giao diện "Welcome to your SWAG instance" là OK

### 2.6.2. Setup backend là YouTube-Stream-Repeater container

Giờ run YouTube-Stream-Repeater:  

```sh
cd /opt/devops/
git clone https://github.com/DavidBerdik/YouTube-Stream-Repeater
cd YouTube-Stream-Repeater
docker-compose up -d
```

Sẽ thấy 1 container run trên port 4000

Test bằng cách: `curl http://localhost:4000/meta/FBjVss96C0E`

Nếu trả về 1 chuỗi json là OK

Giờ stop nó đi:  

```
cd YouTube-Stream-Repeater
docker-compose stop
```

Check `docker images` sẽ thấy đã có images:  

```
$ docker images
REPOSITORY                                TAG            IMAGE ID       CREATED         SIZE
youtube-stream-repeater_server            latest         f18dd1edca15   8 hours ago     575MB
```

Sửa `/opt/devops/docker-compose.yml` ban đầu, thêm `youtubestreamrepeater` vào:  

```
version: '3.0'

services:
...
  youtubestreamrepeater:
    image: youtube-stream-repeater_server:latest
    container_name: youtubestreamrepeater
    restart: unless-stopped
    ports:
      - "4000:4000"
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "10"
```

### 2.6.3. Setup Nginx để point vào backend YouTube-Stream-Repeater container

Vào folder `/opt/devops/swag/config/nginx/proxy-confs` đã được mount:

Sửa file `youtube-dl-server.subdomain.conf.sample`, rename thành `youtube-dl-server.subdomain.conf`:  

```
# chỗ 1.
server_name <REDACTED>.duckdns.org;
# chỗ 2.
set $upstream_app youtubestreamrepeater; # <======== container name
set $upstream_port 4000;
```

Run 1 thể:  

```sh
cd /opt/devops/
docker-compose up -d
```

Vào Browser check lại `<REDACTED>.duckdns.org` nếu trả về `{"detail":"Not Found"}` là OK.  

Nếu trả về lỗi `502 Bad gateway` là lỗi nha, cần làm đúng step, trong file `/opt/devops/docker-compose.yml` cần có cả `swag` và `youtubestreamrepeater`.

Thử link này: `https://<REDACTED>.duckdns.org/meta/FBjVss96C0E`, Nếu trả về 1 chuỗi JSON nghĩa là OK

### 2.6.4. Setup Nginx Basic Authentication

Hiện tại thì đang expose `<REDACTED>.duckdns.org` ra public, ai cũng dùng được.  
Giờ muốn setup Authentication cho nó để hạn chế người lạ vào dùng *chùa* 😁 

Ta tạo password cho user name `ytalexa`:  

```sh
sudo apt install apache2-utils
cd /opt/devops/swag/config/nginx
htpasswd -c /opt/devops/swag/config/nginx/.htpasswd ytalexa

# Nhập password vào, ko nên có mấy ký tự đặc biệt, chỉ nên dùng chữ/số/in hoa
```

Command trên lưu user name và password vào 1 file `/opt/devops/swag/config/nginx/.htpasswd`

Sửa file: `/opt/devops/swag/config/nginx/proxy-confs/youtube-dl-server.subdomain.conf`, uncomment mấy dòng này:  

```
...
location / {
  # enable the next two lines for http auth
  auth_basic "Restricted";
  auth_basic_user_file /config/nginx/.htpasswd;
...
```

restart `swag` container

Test lại từ ngoài vào nếu ko có user/password thì sẽ như này:  

```
$ curl https://<REDACTED>.duckdns.org/meta/FBjVss96C0E
<html>
<head><title>401 Authorization Required</title></head>
<body>
<center><h1>401 Authorization Required</h1></center>
<hr><center>nginx</center>
</body>
</html>
```

Nếu có user/password đúng format này sẽ trả về chuỗi JSON kết quả:  

```sh
curl -u <YOUR USER NAME>:<YOUR PASSWORD> https://<REDACTED>.duckdns.org/meta/FBjVss96C0E

hoặc:  

curl https://<YOUR USER NAME>:<YOUR PASSWORD>@<REDACTED>.duckdns.org/meta/FBjVss96C0E
```

### 2.6.5. Update AWS Lambda function

Update Lambda function bằng file zip ở đây: 
https://github.com/wes1993/YouTubeForAlexa/releases/download/09.02.2023/YouTubeForAlexaLambda.zip

Vào Lambda -> Configuration -> Environment variables, sửa:  

```
Key: get_url_service
Value: youtubestream
```

```
Key: ytstreamurl
Value: <username>:<password>@<REDACTED>.duckdns.org
```

Do chúng ta đang sử dụng [YouTube-Stream-Repeater](https://github.com/DavidBerdik/YouTube-Stream-Repeater) của DavidBerdik chứ ko phải Home Assistant Addon của Stephano (wes1993) nên Có 1 chút cần sửa nữa để mọi thứ chạy được, là `lambda_function.py`:  

```
Line 1074: url = "https://" + environ['ytstreamurl'] + "/api/meta/" + id
sửa thành: url = "https://" + environ['ytstreamurl'] + "/meta/" + id

Line 1083: stream_ext = "https://" + environ['ytstreamurl'] + "/api/dl/" + id + "?f=bestvideo"
sửa thành: stream_ext = "https://" + environ['ytstreamurl'] + "/dl/" + id + "?f=bestvideo"

Line 1085: stream_ext = "https://" + environ['ytstreamurl'] + "/api/dl/" + id + "?f=bestaudio"
sửa thành: stream_ext = "https://" + environ['ytstreamurl'] + "/dl/" + id + "?f=bestaudio"
```

Save function Lambda lại.  

Giờ test mọi thứ sẽ OK, thử `Alexa, ask My Youtube to play a video by Taylor Swift`

Log Cloudwatch:  

```
INIT_START Runtime Version: python:3.7.v23 Runtime Version ARN: arn:aws:lambda:us-east-1::runtime:4xxxxxxxxxxxxxxxxxc
START RequestId: 2bxxxxxxxxxxxxxxxbd Version: $LATEST
[INFO] 2023-03-21T07:22:39.754Z 2b5xxxabbd 400
[INFO] 2023-03-21T07:22:39.754Z 2b5xxxabbd {'message': 'List name already exists', 'type': 'NameConflict'}
[INFO] 2023-03-21T07:22:39.972Z 2b5xxxabbd 400
[INFO] 2023-03-21T07:22:39.972Z 2b5xxxabbd {'message': 'List name already exists', 'type': 'NameConflict'}
END RequestId: 2b5xxxabbd
REPORT RequestId: 2b5xxxabbd Duration: 326.93 ms Billed Duration: 327 ms Memory Size: 512 MB Max Memory Used: 51 MB Init Duration: 550.63 ms
START RequestId: 0yyyyyyyyyyyyye Version: $LATEST
[INFO] 2023-03-21T07:23:06.701Z 0yyyyyyyyyyyyye {'version': '1.0', 'session': {'new': False, 'sessionId': 'amzn1.echo-api.session.b5xxxxxxxxxxxxxxbc4a8', '
[INFO] 2023-03-21T07:23:06.701Z 0yyyyyyyyyyyyye Looking for: video by Taylor swift
[INFO] 2023-03-21T07:23:06.701Z 0yyyyyyyyyyyyye checking for faves
[INFO] 2023-03-21T07:23:06.867Z 0yyyyyyyyyyyyye checking Add shortcuts to your favorite videos or playlists like this:
[INFO] 2023-03-21T07:23:07.370Z 0yyyyyyyyyyyyye Getting YouTubeStream url for https://www.youtube.com/watch?v=h8DLofLM7No
[INFO] 2023-03-21T07:23:07.370Z 0yyyyyyyyyyyyye Appending ?f=bestaudio
[INFO] 2023-03-21T07:23:08.866Z 0yyyyyyyyyyyyye Sending song: Taylor Swift - Lavender Haze (Official Music Video) to Alexa
END RequestId: 0yyyyyyyyyyyyye
REPORT RequestId: 0yyyyyyyyyyyyye Duration: 2167.59 ms Billed Duration: 2168 ms Memory Size: 512 MB Max Memory Used: 51 MB
```

Check log của YouTube-Stream-Repeater như này là ok, ko có lỗi gì:  

```
$ docker logs youtubestreamrepeater
INFO:     Uvicorn running on http://0.0.0.0:4000 (Press CTRL+C to quit)
INFO:     Started parent process [1]
INFO:     Started server process [9]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Started server process [11]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Started server process [14]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Started server process [7]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Started server process [13]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Started server process [8]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Started server process [12]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Started server process [10]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
[QV3jQQ9_TUw]: requested with format bestaudio and subs None, configuring...
[QV3jQQ9_TUw]: sending stream
[QV3jQQ9_TUw]: stream will be sent as is (bestaudio)
[QV3jQQ9_TUw]: download type: video/webm (.webm)
INFO:     172.18.0.3:39584 - "GET /dl/QV3jQQ9_TUw?f=bestaudio HTTP/1.1" 200 OK
INFO:     172.18.0.3:39156 - "GET /meta/XcQWfs90lFU HTTP/1.1" 200 OK
[XcQWfs90lFU]: requested with format bestaudio and subs None, configuring...
[XcQWfs90lFU]: sending stream
[XcQWfs90lFU]: stream will be sent as is (bestaudio)
[XcQWfs90lFU]: download type: video/webm (.webm)
INFO:     172.18.0.3:55760 - "GET /dl/XcQWfs90lFU?f=bestaudio HTTP/1.1" 200 OK
[QV3jQQ9_TUw]: end of data (no error reported)
cleanup[QV3jQQ9_TUw]: killing downloader process (PID: 499)
INFO:     172.18.0.3:35288 - "GET /meta/wyqwYhDXkNQ HTTP/1.1" 200 OK
[wyqwYhDXkNQ]: requested with format bestaudio and subs None, configuring...
[wyqwYhDXkNQ]: sending stream
[wyqwYhDXkNQ]: stream will be sent as is (bestaudio)
[wyqwYhDXkNQ]: download type: video/webm (.webm)
INFO:     172.18.0.3:35290 - "GET /dl/wyqwYhDXkNQ?f=bestaudio HTTP/1.1" 200 OK
```

Done! Dùng cách này mình thấy ngon lành hơn hẳn. Special thanks to Stephano (wes1993) and DavidBerdik 🥰

# 3. Setup other skills

Search 2 skill sau: VOV, NhacCuaTui

## 3.1. VOV

VOV Command to use:  
`Alexa open VOV`: open VOV.   
`Alexa stop`: stop, muốn chuyển channel khác thì phải stop trước.  
`Alexa next`: để chuyển channel 1, 2, 3, vov giao thông.    

## 3.2. NhacCuaTui

Trước tiên cần đăng ký account NCT, free cũng dc ko cần VIP

Skill này nó ko hiểu tên của Playlist, mà muốn playlist thì cần biết playlist đó có số thứ tự là số mấy.

Ví dụ trong account NCT mình có khoảng 9,10 playlist:  
playlist 2: Vietnamese 2  
playlist 3: My Music  
playlist 4: Foreign 2  
playlist 5: Vietnamese 1  
playlist 6: Foreign 1  
playlist 7: 2NE1 Parkbom  
playlist 8: Bức tường  
playlist 9: So deep  
playlist 10: billboard 100 (1958-2015)  

Command to use:  
`Alexa, play playlist [3] from NCT`: Muốn play playlist `My Music` tương ứng với số thứ tự là 3.  
`Alexa, stop / next`: muốn next bài tiếp theo cần stop trước.  
`Alexa play Vpop from NCT`: Play nhạc Việt trên NCT.    
`Alexa what's hot today from NCT`: play lần lượt các bài đang TOP BXH nhạc Việt.  

# 4. Troubleshooting

1. Nếu bạn muốn Xem lại các command mà Alexa đã record lại thì vào đây:  
https://www.amazon.com/alexa-privacy/apd/rvh  
Nhờ cái trang trên mà mình biết mình phát âm lúc thì `youtube` lúc thì `you tube`. Lúc thì có `my news playlist`, lúc thì `news playlist`.  
Thế nên mình tóm lại nên để invocation name là `my youtube` chứ ko nên để `you tube`. 
Các playlist thì cũng đồng bộ 1 chút, đều có chữ `my` ở đầu. Đọc sai 1 chữ là nó ko hiểu ngay, do con Youtube skill này nó lởm.  

2. Nếu bị lỗi ko discovery được device sau khi linked account, solution: Đổi hết stack sang English (US), lambda sang N.Verginia region:  
https://community.home-assistant.io/t/alexa-integration-does-not-find-devices/193732/5

3. Bạn có thể dùng web sau để thay cho app trên điện thoại:  
https://alexa.amazon.com


# 5. Integrate Alexa Media Player on HACS

cái này là để có thể control Alexa qua giao diện Home Assistant hoặc qua programming

## 5.1. Setup 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-media-player-hacs-add.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-media-player-hacs-download-repo.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-media-player-hacs-download-repo-2.jpg)

restart HASS

Setting -> Integration -> Add integration:  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-media-player-add-int.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-media-player-setup-new-int.jpg)

màn hình Alexa Integration Configuration:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-media-player-config.jpg)

Đừng vội điền Built-in 2FA App Key vì chúng ta sẽ lấy nó bằng các step sau:  

Login vào https://amazon.com rồi vào `Your Account`:  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-media-player-your-account.jpg)

Vào phần 2 step verfication:  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-media-player-login-secu.jpg)

Ấn vào `Add new app`:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-media-player-2step-verify-setting1.jpg)

Đừng scan QR code, hãy ấn vào `Cant scan barcode` để COPY lấy code:  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-media-player-get-bar-code-digit.jpg)

Paste code vừa lấy được vào màn hình Alexa Integration Configuration: 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-media-player-paste-barcode-here.jpg)

Sẽ xuất hiện OTP Code 6 ký tự ở đây, Copy tiếp:   

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-media-player-copy-opt-code.jpg)

Paste OTP 6 ký tự vào đây rồi ấn verify:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-media-player-paste-otp-verify.jpg)

Quay lại màn hình HASS, click check box và Submit:  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-media-player-confirm-opt-code-ok.jpg)

Nó sẽ hiện 1 web để login bằng account Amazon:  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-media-player-sigin-again.jpg)

màn hình Loading:  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-media-player-wait-screen.jpg)

Màn hình tìm đc device echo trên HASS:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-media-player-success-found-echo.jpg)

Tab Setting - Integration sẽ xuất hiện Echo device:  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-media-player-integration-displayed.jpg)

Đến đây bạn có thể Dùng HASS điều khiển các entity của Alexa:  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-media-player-entities.jpg)

## 5.2. Use case

### 5.2.1. Text to speech

Giả sử mình muốn add 1 card vào lovelace:  

```yml
title: "Alexa Notes"
path: "alexa"
cards:
  - type: 'custom:mini-media-player'
    entity: media_player.hoang_s_echo_dot
    icon: 'mdi:amazon'
    tts:
      platform: alexa
      entity_id: media_player.hoang_s_echo_dot
```

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-hass-config-on-lovelace.jpg)

Bạn có thể đánh text vào text box, sau đó Alexa sẽ đọc những gì bạn viết (Alexa chỉ hiểu English)

Đến đây mình nghĩ đến 1 use case:   

- Mình ở cty gõ text vào text to speech: How are you?. Alexa ở nhà sẽ phát ra tiếng "How are you" đến vợ mình.  
- Vợ mình ở nhà nghe thấy, ra lệnh cho Alexa: "Alexa, ask Reply Now say I am fine". ALexa sẽ gửi message vào group chat gia đình "I am fine".   
- Mình nhận dc tin nhắn qua Telegram.  

Để làm được điều đó thì cần viết 1 skill để ra lệnh cho Alexa send message đến Telegram group chat. Khá thú vị đấy chứ. Sẽ làm ngay ở phần 6.

### 5.2.2. Command to Alexa by text

Trước giờ là chúng ta ra lệnh cho Alexa qua giọng nói thực sự. Giờ nếu bạn ko muốn nói vì lười, bạn muốn call 1 HA script, script đó sẽ gửi text đến Alexa, Alexa nhận đoạn text đó, hiểu và thực hiện thì làm thế nào? Nếu làm được điều này sẽ rất tiện lợi cho các automation của chúng ta với Alexa.  

Use case dễ nhất với mình là, Để ra lệnh Alexa mở `My Youtube` skill và bật playlist `My Vietnam TV playlist`, mình sẽ phải nói:  
> Alexa ask My Youtube to play My Vietnam TV playlist

Nhưng lần nào cũng phải nói thế thì hơi dài 🙄. Hoặc là với những channel tiếng Việt thì bạn nói chắc chắn Alexa sẽ ko hiểu. Mình muốn 1 trong 3 cách sau:  
- Ấn 1 button trên giao diện Home Assistant, nó sẽ trigger 1 HA script, Alexa nghe lệnh làm theo.  
- Dùng điện thoại quơ nhẹ vào cái NFC tag gắn trên bàn ăn, nó sẽ trigger 1 HA script, Alexa nghe lệnh làm theo.  
- Dùng tính năng Routine của Alexa app, chỉ cần nói "Alexa, TV", nó sẽ trigger 1 HA script, Alexa nghe lệnh làm theo.  

Cả 3 cách trên đều khả thi 1 khi bạn đã integrate được [Alexa Media player](https://github.com/custom-components/alexa_media_player/wiki#run-custom-command). 

Về cơ bản thì script trong file `scripts.yaml`:  
```yml
# command to alexa ask My Youtube to play my Vietnam TV playlist
alexa_youtube_cd24:
  sequence:
  - service: media_player.play_media
    target:
      entity_id: media_player.hoang_s_echo_dot
    data:
      media_content_type: custom
      media_content_id: 'ask My Youtube to play my Vietnam TV playlist'
```
Còn ở dashboard thì call script qua button như này:  
```yml
...
  - type: glance
    title: Alexa command
    entities:
      - entity: script.alexa_youtube_cd24
        icon: 'mdi:youtube-tv'
        name: CĐ24h
        show_state: false
        tap_action:
          # confirmation:
          #   text: Are you sure to change state of this device?
          action: call-service
          service: script.alexa_youtube_cd24
          service_data:
            entity_id: script.alexa_youtube_cd24
```

Vậy là bạn chỉ cần ấn button CĐ24h là xong, magic?🤣

1 khi đã tạo được script rồi thì việc còn lại chỉ là setting NFC tag hoặc Routine trên Alexa app nữa thôi, cái ấy tùy bạn chọn.

### 5.2.3. Dùng service TTS trong automaion

Đây là 1 ví dụ về việc sử dụng `service: notify.YOUR_ECHO` và tts để trigger Alexa nói 1 random phrase nào đó:  
```yml
- id: 'welcome-home-dvfhsfef'
  alias: "Welcome home"
  description: Alexa say welcome home
  mode: restart
  trigger:
  - entity_id: binary_sensor.front_door_sensor_contact
    platform: state
    to: 'on'
  condition: "{{ is_state('input_boolean.nobodyhome_mode', 'on') }}"
  action:
  - delay: 00:00:03
  - data: {}
    service_template: "script.striplight_power"
  - service: notify.alexa_media_hoang_s_echo_dot
    data:
      data:
        type: tts
      message: '{{
        [
          "Welcome home! ",
          "Wow! You are home. ",
          "Finally! You are home. ",
          "Home sweet home! ",
        ]| random + [

          "I am really very happy you here. ",
          "You belong here. ",
          "Hope you have enjoyed your day. ",
          "I have been waiting for you all day long. ",
          "Hope you had a busy day. ",
          "Its great to have you back. ",
          "Would you like some music? say, Alexa, make some noise. ",
        ]| random }}'
```

# 6. Create My Alexa skill that send Telegram message

Nhắc lại use case:   

- Mình ở cty gõ text vào text to speech: How are you?. Alexa ở nhà sẽ phát ra tiếng "How are you" đến vợ mình.  
- Vợ mình ở nhà nghe thấy, ra lệnh cho Alexa: "Alexa, ask Reply Now say I am fine". ALexa sẽ gửi message vào group chat gia đình "I am fine".   
- Mình nhận dc tin nhắn qua Telegram.  

Để làm được điều đó thì cần viết 1 skill để ra lệnh cho Alexa send message đến Telegram group chat. Khá thú vị đấy chứ. Sẽ làm ngay sau đây...

## 6.1. Setup Telegram bot

... mình ko viết lại phần này vì có thể sử dụng lại bài trước: [Lambda + API Gateway, Telegram Bot and Serverless Webapp](../../posts/encrypt-lambda-apigw-telegram-bot-serverless-webapp/) 

Lấy được TELEGRAM_TOKEN để sử dụng.  

Ngoài ra cần lấy dc CHAT_ID của group chat mà con bot đã được add vào.  

## 6.2. Setup trên Alexa Developer console

Vào đây: https://developer.amazon.com/alexa/console/ask

Tạo Skill `Reply Now`:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-skill-reply-now-create-1.jpg)

Chú ý, chọn Model -> Custom, Hosting services -> Provision your own:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-skill-reply-now-create-2.jpg)

Chọn template -> Start from Scratch:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-skill-reply-now-create-3.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-skill-reply-now-invoke-name.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-skill-reply-now-josn-editor.jpg)

Json content:  
```json
{
    "interactionModel": {
        "languageModel": {
            "invocationName": "reply now",
            "intents": [
                {
                    "name": "AMAZON.CancelIntent",
                    "samples": []
                },
                {
                    "name": "AMAZON.HelpIntent",
                    "samples": []
                },
                {
                    "name": "AMAZON.StopIntent",
                    "samples": []
                },
                {
                    "name": "HelloWorldIntent",
                    "slots": [],
                    "samples": []
                },
                {
                    "name": "SendMessageIntent",
                    "slots": [
                        {
                            "name": "query",
                            "type": "AMAZON.SearchQuery"
                        }
                    ],
                    "samples": [
                        "send {query}",
                        "say {query}"
                    ]
                },
                {
                    "name": "AMAZON.NavigateHomeIntent",
                    "samples": []
                },
                {
                    "name": "AMAZON.FallbackIntent",
                    "samples": []
                },
                {
                    "name": "AMAZON.PauseIntent",
                    "samples": []
                },
                {
                    "name": "AMAZON.ResumeIntent",
                    "samples": []
                }
            ],
            "types": []
        }
    }
}
```
Save Model, Build Model

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-skill-reply-now-interface.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-skill-reply-now-endpoint.jpg)

Save Endpoint, Save Model, Build Model

Chờ Build Model success

## 6.3. Setup trên AWS

Tạo function `telegram-alexa`, dùng runtime python 3.9

Tạo và add các layer vào (có thể bạn sẽ cần tìm lại bài `discord` để biết cách tạo layer):  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-skill-reply-now-lambda-layer.jpg)

Lấy code ở đây paste vào: https://github.com/alexa-samples/skill-sample-python-helloworld-classes/tree/master/lambda/py

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-skill-reply-now-lambda-func.jpg)

Chú ý dòng cuối cùng phải sửa thành `lambda_handler = sb.lambda_handler()` thì mới chạy dc

Chú ý set các environment variable: `CHAT_ID, TELEGRAM_TOKEN`

Code Lambda cần sửa lại như sau, về cơ bản mình chỉ thêm class `SendMessageIntentHandler`, function `send_telegram_msg(msg, chat_id)`:  
```python
# -*- coding: utf-8 -*-

# This sample demonstrates handling intents from an Alexa skill using the Alexa Skills Kit SDK for Python.
# Please visit https://alexa.design/cookbook for additional examples on implementing slots, dialog management,
# session persistence, api calls, and more.
# This sample is built using the handler classes approach in skill builder.
import logging, os
import gettext
import requests
import json
from botocore.exceptions import ClientError

from ask_sdk_core.skill_builder import SkillBuilder
from ask_sdk_core.dispatch_components import (
    AbstractRequestHandler, AbstractRequestInterceptor, AbstractExceptionHandler)
import ask_sdk_core.utils as ask_utils
from ask_sdk_core.handler_input import HandlerInput

from ask_sdk_model import Response
from alexa import data

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

# Get Lambda environment variables
TOKEN = os.environ.get('TELEGRAM_TOKEN')
chat_id = os.environ.get('CHAT_ID')

...

def send_telegram_msg(msg, chat_id):
        """
        Tries to Send Telegram message. If a ThrottlingException is encountered
        recursively calls itself until success.
        """
        try:
            BASE_URL = "https://api.telegram.org/bot{}".format(TOKEN)
            url = BASE_URL + "/sendMessage"
            data = {"text": msg.encode("utf8"), "chat_id": chat_id}
            requests.post(url, data)
        except ClientError as err:
            if 'ThrottlingException' in str(err):
                logger.info(
                    "Send message to Telegram command throttled, automatically retrying...")
                send_telegram_msg(msg, chat_id)
            else:
                logger.error(
                    "Send message to Telegram command Failed!\n%s", str(err))
                return False
        except:
            raise

class SendMessageIntentHandler(AbstractRequestHandler):
    """Handler for SendMessage Intent."""

    def can_handle(self, handler_input):
        # type: (HandlerInput) -> bool
        return ask_utils.is_intent_name("SendMessageIntent")(handler_input)

    def handle(self, handler_input):
        # envelope = handler_input.request_envelope # DEBUG
        # logger.info("Envelope Attr: {}".format(envelope)) # DEBUG
        slots = handler_input.request_envelope.request.intent.slots
        query = slots["query"].value
        msg = "\"" + query + "\"" + " - someone said."
        # send telegram message
        logger.info("Your messsage: " + query)
        send_telegram_msg(msg, chat_id)
        logger.info("Your messsage to Telegram was sent")
        speak_output = "Sent it"
        return (
            handler_input.response_builder
            .speak(speak_output)
            # .ask("add a reprompt if you want to keep the session open for the user to respond")
            .response
        )

...

sb = SkillBuilder()

sb.add_request_handler(LaunchRequestHandler())
sb.add_request_handler(HelloWorldIntentHandler())
sb.add_request_handler(SendMessageIntentHandler())
sb.add_request_handler(HelpIntentHandler())
sb.add_request_handler(CancelOrStopIntentHandler())
sb.add_request_handler(FallbackIntentHandler())
sb.add_request_handler(SessionEndedRequestHandler())
# make sure IntentReflectorHandler is last so it doesn't override your custom intent handlers
sb.add_request_handler(IntentReflectorHandler())

sb.add_global_request_interceptor(LocalizationInterceptor())

sb.add_exception_handler(CatchAllExceptionHandler())

lambda_handler = sb.lambda_handler()
```
Add trigger cho Lambda function, chú ý chọn Enable skill verification:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-skill-reply-now-add-trigger.jpg)


## 6.4. Test Alexa skill

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-skill-reply-now-test-1.jpg)

Gõ vào hoặc nói vào mic, nếu trả về kết quả `sent it` là OK:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-skill-reply-now-test-2.jpg)

Check kết quả trên telegram chat sẽ có tin nhắn con bot gửi đến

Bằng cách này bạn có thể vào Cloudwatch để xem log:   
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/alexa-skill-reply-now-test-3-log.jpg)

# 7. Create My Alexa skill that return Lunar Calendar

Mình sẽ hỏi Alexa kiểu như:   
- Me: "Alexa lunar calendar?"  
- Alexa: "today? yesterday? tomorrow?"   
- Me: "today"  
- Alexa: "In Vietnam Lunar calendar, today is day: 3, month: 12" -> nghĩa là mùng 3 tháng chạp.  

Để làm skill này về cơ bản là dễ, quan trọng là google đc cách tính Lunar calendar mà thôi

Các bước tạo skill giống như đã làm với Reply Now

Chuỗi JSON trong phần model sẽ kiểu như này:  
```json
{
    "interactionModel": {
        "languageModel": {
            "invocationName": "lunar calendar",
            "intents": [
                {
                    "name": "AMAZON.CancelIntent",
                    "samples": []
                },
                {
                    "name": "AMAZON.HelpIntent",
                    "samples": []
                },
                {
                    "name": "AMAZON.StopIntent",
                    "samples": []
                },
                {
                    "name": "HelloWorldIntent",
                    "slots": [],
                    "samples": []
                },
                {
                    "name": "LunarCalendarTodayIntent",
                    "slots": [],
                    "samples": [
                        "tell me lunar calendar",
                        "today",
                        "lunar calendar today",
                        "lunar calendar date",
                        "lunar date today",
                        "tell me lunar date",
                        "lunar calendar today",
                        "today in lunar calendar",
                        "what is today in lunar calendar",
                        "what is today in lunar date"
                    ]
                },
                {
                    "name": "LunarCalendarYesterdayIntent",
                    "slots": [],
                    "samples": [
                        "yesterday",
                        "lunar calendar yesterday",
                        "the day before"
                    ]
                },
                {
                    "name": "LunarCalendarTomorrowIntent",
                    "slots": [],
                    "samples": [
                        "tomorrow",
                        "lunar calendar tomorrow",
                        "the day after"
                    ]
                },
                {
                    "name": "AMAZON.NavigateHomeIntent",
                    "samples": []
                },
                {
                    "name": "AMAZON.FallbackIntent",
                    "samples": []
                },
                {
                    "name": "AMAZON.PauseIntent",
                    "samples": []
                },
                {
                    "name": "AMAZON.ResumeIntent",
                    "samples": []
                }
            ],
            "types": []
        }
    }
}
```

Step tạo Lambda cũng tương tự, nhưng trong folder `/data` tạo file `AL.py` content lấy từ link [này](https://www.informatik.uni-leipzig.de/~duc/amlich/AL.py)

Code Lambda sẽ có những phần này:  
```python
# -*- coding: utf-8 -*-

# This sample demonstrates handling intents from an Alexa skill using the Alexa Skills Kit SDK for Python.
# Please visit https://alexa.design/cookbook for additional examples on implementing slots, dialog management,
# session persistence, api calls, and more.
# This sample is built using the handler classes approach in skill builder.
import logging, os
import gettext
import requests
import json
from botocore.exceptions import ClientError

from ask_sdk_core.skill_builder import SkillBuilder
from ask_sdk_core.dispatch_components import (
    AbstractRequestHandler, AbstractRequestInterceptor, AbstractExceptionHandler)
import ask_sdk_core.utils as ask_utils
from ask_sdk_core.handler_input import HandlerInput

from ask_sdk_model import Response
from alexa import data
from alexa import AL
from datetime import datetime
from dateutil.relativedelta import relativedelta

currentDT = datetime.now()
print('------------------')
print("Run at: %s" % currentDT)

# Get current datetime
this_year = datetime.today().strftime('%Y')
this_month = datetime.today().strftime('%m')
current_day = currentDT.strftime('%d')
print("This year: %s. This month: %s. Current day: %s" % (this_year, this_month, current_day))

# Get yesterday datetime
yesterday_date = relativedelta(days=-1) + currentDT
yesterday_day = yesterday_date.strftime('%d')
yesterday_month = yesterday_date.strftime('%m')
yesterday_year = yesterday_date.strftime('%Y')
print("Yesterday year: %s. Yesterday month: %s. Yesterday day: %s" % (yesterday_year, yesterday_month, yesterday_day))

# Get tomorrow datetime
tomorrow_date = relativedelta(days=1) + currentDT
tomorrow_day = tomorrow_date.strftime('%d')
tomorrow_month = tomorrow_date.strftime('%m')
tomorrow_year = tomorrow_date.strftime('%Y')
print("Tomorrow year: %s. Tomorrow month: %s. Tomorrow day: %s" % (tomorrow_year, tomorrow_month, tomorrow_day))

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)

....

class LunarCalendarTodayIntentHandler(AbstractRequestHandler):
    """Handler for LunarCalendarTodayIntent Intent."""

    def can_handle(self, handler_input):
        # type: (HandlerInput) -> bool
        return ask_utils.is_intent_name("LunarCalendarTodayIntent")(handler_input)

    def handle(self, handler_input):
        # envelope = handler_input.request_envelope # DEBUG
        # logger.info("Envelope Attr: {}".format(envelope)) # DEBUG
        lunar_date = AL.S2L(int(current_day), int(this_month), int(this_year), timeZone = 7)
        print(lunar_date) # DEBUG
        lunar_day = lunar_date[0]
        lunar_month = lunar_date[1]
        speak_output = "In Vietnam Lunar calendar, today is... Day: %d. Month: %d." % (lunar_day, lunar_month)
        return (
            handler_input.response_builder
            .speak(speak_output)
            # .ask("add a reprompt if you want to keep the session open for the user to respond")
            .response
        )
        

class LunarCalendarYesterdayIntentHandler(AbstractRequestHandler):
    """Handler for LunarCalendarYesterdayIntent Intent."""

    def can_handle(self, handler_input):
        # type: (HandlerInput) -> bool
        return ask_utils.is_intent_name("LunarCalendarYesterdayIntent")(handler_input)

    def handle(self, handler_input):
        # envelope = handler_input.request_envelope # DEBUG
        # logger.info("Envelope Attr: {}".format(envelope)) # DEBUG
        lunar_date = AL.S2L(int(yesterday_day), int(yesterday_month), int(yesterday_year), timeZone = 7)
        print(lunar_date) # DEBUG
        lunar_day = lunar_date[0]
        lunar_month = lunar_date[1]
        speak_output = "In Vietnam Lunar calendar, yesterday is... Day: %d. Month: %d." % (lunar_day, lunar_month)
        return (
            handler_input.response_builder
            .speak(speak_output)
            # .ask("add a reprompt if you want to keep the session open for the user to respond")
            .response
        )


class LunarCalendarTomorrowIntentHandler(AbstractRequestHandler):
    """Handler for LunarCalendarTomorrowIntent Intent."""

    def can_handle(self, handler_input):
        # type: (HandlerInput) -> bool
        return ask_utils.is_intent_name("LunarCalendarTomorrowIntent")(handler_input)

    def handle(self, handler_input):
        # envelope = handler_input.request_envelope # DEBUG
        # logger.info("Envelope Attr: {}".format(envelope)) # DEBUG
        lunar_date = AL.S2L(int(tomorrow_day), int(tomorrow_month), int(tomorrow_year), timeZone = 7)
        print(lunar_date) # DEBUG
        lunar_day = lunar_date[0]
        lunar_month = lunar_date[1]
        speak_output = "In Vietnam Lunar calendar, tomorrow is... Day: %d. Month: %d." % (lunar_day, lunar_month)
        return (
            handler_input.response_builder
            .speak(speak_output)
            # .ask("add a reprompt if you want to keep the session open for the user to respond")
            .response
        )
        
...

sb = SkillBuilder()

sb.add_request_handler(LaunchRequestHandler())
sb.add_request_handler(HelloWorldIntentHandler())
sb.add_request_handler(LunarCalendarTodayIntentHandler())
sb.add_request_handler(LunarCalendarYesterdayIntentHandler())
sb.add_request_handler(LunarCalendarTomorrowIntentHandler())
sb.add_request_handler(HelpIntentHandler())
sb.add_request_handler(CancelOrStopIntentHandler())
sb.add_request_handler(FallbackIntentHandler())
sb.add_request_handler(SessionEndedRequestHandler())
# make sure IntentReflectorHandler is last so it doesn't override your custom intent handlers
sb.add_request_handler(IntentReflectorHandler())

sb.add_global_request_interceptor(LocalizationInterceptor())

sb.add_exception_handler(CatchAllExceptionHandler())

lambda_handler = sb.lambda_handler()
```

Test lại Alexa skill giống như phần 6.4

# 8. CREDIT

Document Official:
https://www.home-assistant.io/integrations/alexa.smart_home/#test-the-lambda-function  

EverythingSmartHome:  
Alexa with Home Assistant Local for FREE Without Subscription:  
https://www.youtube.com/watch?v=Ww2LI59IQ0A&ab_channel=EverythingSmartHome  


Sauber-LabUK:  
Let's install Amazon Alexa in our Home Assistant – Local Setup:  
https://www.youtube.com/watch?v=5G733Lv-PhY&ab_channel=Sauber-LabUK


Kênh Táy Máy - Alexa setup:
https://www.youtube.com/watch?v=sBaeXxKnSMg&ab_channel=K%C3%AAnhT%C3%A1yM%C3%A1y  
Alexa call script:  
https://youtu.be/0ElXDPw5c1Q?t=1136
Alexa include exclude entity:  
https://youtu.be/PhWpnc-Pvko?t=223


Mark Watt Tech:  
Install Alexa Media player qua HACS để control Echo thông qua HASS:  
https://www.youtube.com/watch?v=UsnhL2z_UUY&ab_channel=MarkWattTech  
Scripts + Automations, Idea về setup cho Alexa run script của HASS:    
https://www.youtube.com/watch?v=0ElXDPw5c1Q&ab_channel=MarkWattTech  
ALEXA ACTIONABLE NOTIFICATIONS (Home Assistant + Alexa Skill):   
https://www.youtube.com/watch?v=uoifhNyEErE&ab_channel=MarkWattTech  


PaulHibbert - Alexa play Youtube music, Setup alexa skill riêng của mình và AWS lambda riêng: post từ 2019 2020, có thể đã outdated:  
https://www.youtube.com/watch?v=mluD8kQ06NM&ab_channel=PaulHibbert  
https://www.youtube.com/watch?v=5k9OGbeek28&ab_channel=PaulHibbert  


Github alexa-youtube mà tác giả ndg63276 sẽ cung cấp Lambda ARN url cho mỗi người giá 3$/month:
https://github.com/ndg63276/alexa-youtube  
các forks trước khi ndg63276 make private: 
https://github.com/cipi1965/alexa-youtube-it update từ 2018
https://github.com/FedericoHeichou/alexa-youtube : NÊN FORK VỀ


Github alexa-youtube-skill, tác giả đã archive:
https://github.com/dmhacker/alexa-youtube-skill
https://imgur.com/a/H5R7L

https://github.com/mbpictures/alexa-youtube-skill -> update từ 2019
https://github.com/waiwong614/alexa-tube -> update từ 2019

Github alexa-youtube well-maintained:
https://github.com/wes1993/YouTubeForAlexa: NÊN FORK VỀ
file zip được extract ra repo này để xem:  
https://github.com/DavidBerdik/YouTubeForAlexa-Lambda 


Các cách nghe Youtube audio trên Alexa Echo dot:  
https://diysmarthomeplanet.com/echo-dot-youtube/  
- Unofficial YouTube Skill on Github  
- Workaround via Fire TV  
- Pairing with the smartphone  


AndrewTech kênh làm các demo liên quan đến Youtube với Alexa:  
https://www.youtube.com/@Andrewstech/videos  
Github của Kênh AndrewTech làm Youtube for Alexa:   
https://github.com/Imihaljko/youtube-for-alexa


well-maintained, web base run trên Docker để download Youtube tự host: NÊN FORK VỀ
https://github.com/xxcodianxx/youtube-dl-web

well-maintained, CLI, 1 library python có 2.9k forks, 36k stars: NÊN FORK VỀ
https://github.com/yt-dlp/yt-dlp

well-maintained, stream bằng tự dựng server Youtube audio server:  
https://github.com/codealchemist/youtube-audio-server

1 số tip khi sử dụng Alexa:
https://www.youtube.com/watch?v=Zey1P1ZEyn4&ab_channel=Pocket-lint

LunarCalendar:  
https://github.com/quangvinh86/SolarLunarCalendar/blob/master/LunarSolar.py  
https://www.informatik.uni-leipzig.de/~duc/amlich/AL.py  

Random phrase with Alexa:  
https://youtu.be/3MdnRfCQcVE?t=154  
https://community.home-assistant.io/t/how-to-create-multiple-phrases-to-send-at-random-to-tts/19807/43  
