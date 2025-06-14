---
title: "Setup Home Assistant on Raspberry Pi (Part 6) - Camera"
date: 2024-03-06T20:48:00+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [HomeAssistant]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Việc integrate các camera của nhiều hãng khác nhau là 1 thứ rất phổ biến khi xây dựng hệ thống Smart Home"
---


# 1. Story

Nay mua được chiếc camera EZVIZ C6N 500k đã có thẻ nhớ 64GB. Về config xem thế nào..

# 2. Setup Camera EZVIZ

Cắm thẻ nhớ vào, cắm nguồn, cài app trên điện thoại, đăng ký tài khoản = email, add device, quét mã, đăng nhập wifi 2.4G của nhà, định dạng lại thẻ nhớ, 1 lúc là xong. 

Setup luồng RTSP stream:

Vào APP trên điện thoại (Chú ý cùng wifi với thiết bị) - Cài đặt - LAN LIVE VIEW - tìm thấy camera của mình - nhập password (là VERIFICATION CODE dưới đáy thiết bị) - Login

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/camera-lan-live-view.jpg)
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/camera-lan-live-view-login.jpg)

Sau đó thì enable RTSP như này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/camera-lan-live-view-setting.jpg)
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/camera-lan-live-view-setting-local.jpg)
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/camera-lan-live-view-setting-local-rtsp.jpg)

Note lại IP và port của thiết bị.

Vào máy tính, mở app VLC - Media - Open Network Stream - nhập url: 

```sh
rtsp://admin:<VERIFICATION CODE DƯỚI ĐÁY THIẾT BỊ>@<địa chỉ IP CỦA THIẾT BỊ>:554/H.264
```

ví dụ:

```
rtsp://admin:PASSWORD@192.168.1.8:554/H.264
```

ra được màn hình VLC như này có nghĩa là đã setup luông RTSP thành công:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/camera-lan-live-view-vlc.jpg)

# 3. Install Frigate

File `docker-compose.yml`:

```yml
version: '3.0'

services:
    frigate:
        container_name: frigate
        privileged: true # this may not be necessary for all setups
        restart: on-failure:15
        image: ghcr.io/blakeblackshear/frigate:0.13.2
        shm_size: "64mb" # update for your cameras based on calculation above
        devices:
        # - /dev/bus/usb:/dev/bus/usb  # Passes the USB Coral, needs to be modified for other versions
        # - /dev/apex_0:/dev/apex_0    # Passes a PCIe Coral, follow driver instructions here https://coral.ai/docs/m2/get-started/#2a-on-linux
        - /dev/video11:/dev/video11  # For Raspberry Pi 4B
        # - /dev/dri/renderD128:/dev/dri/renderD128 # For intel hwaccel, needs to be updated for your hardware
        volumes:
        - /etc/localtime:/etc/localtime:ro
        - /opt/frigate/config:/config
        - /opt/frigate/storage:/media/frigate
        - type: tmpfs # Optional: 1GB of memory, reduces SSD/SD Card wear
            target: /tmp/cache
            tmpfs:
            size: 1000000000
        ports:
        - "5000:5000"
        - "8554:8554" # RTSP feeds
        - "8555:8555/tcp" # WebRTC over tcp
        - "8555:8555/udp" # WebRTC over udp
        environment:
        FRIGATE_RTSP_PASSWORD: "password"
```

file `/opt/frigate/config/config.yml`:

```yml
mqtt:
  enabled: True
  host: 192.168.X.Y
  port: 1883
  user: YOUR_MQTT_USER
  password: YOUR_MQTT_PASSWORD
  topic_prefix: frigate

cameras:
  CameraEZVIZC6N:
    ffmpeg:
      inputs:
        - path: rtsp://admin:PASSWORD@192.168.1.8:554/H.264
          roles:
            - detect
            - record
    detect:
      width: 1280
      height: 720
      fps: 5
    record:
      enabled: True
```

Run `docker-compose up -d`

log như này là có vẻ OK:

```
2024-03-09 13:30:32.873130188  [INFO] Preparing Frigate...
2024-03-09 13:30:32.877242299  [INFO] Starting NGINX...
s6-rc: info: service legacy-services successfully started
2024-03-09 13:30:33.161840169  [INFO] Preparing new go2rtc config...
2024-03-09 13:30:33.181247632  [INFO] Starting Frigate...
2024-03-09 13:30:34.026388613  [INFO] Starting go2rtc...
2024-03-09 13:30:34.254075817  13:30:34.253 INF go2rtc version 1.8.4 linux/arm64
2024-03-09 13:30:34.258035650  13:30:34.255 INF [api] listen addr=:1984
2024-03-09 13:30:34.258047613  13:30:34.255 INF [rtsp] listen addr=:8554
2024-03-09 13:30:34.258059965  13:30:34.256 INF [webrtc] listen addr=:8555
2024-03-09 13:30:37.225932537  [2024-03-09 13:30:37] frigate.app                    INFO    : Starting Frigate (0.13.2-6476f8a)
2024-03-09 13:30:37.304514426  [2024-03-09 13:30:37] peewee_migrate.logs            INFO    : Starting migrations
2024-03-09 13:30:37.320249778  [2024-03-09 13:30:37] peewee_migrate.logs            INFO    : There is nothing to migrate
2024-03-09 13:30:37.334546759  [2024-03-09 13:30:37] frigate.app                    INFO    : Recording process started: 298
2024-03-09 13:30:37.343170519  [2024-03-09 13:30:37] frigate.app                    INFO    : go2rtc process pid: 89
2024-03-09 13:30:37.415446037  [2024-03-09 13:30:37] detector.cpu                   INFO    : Starting detection process: 308
2024-03-09 13:30:37.423413574  [2024-03-09 13:30:37] frigate.app                    INFO    : Output process started: 310
2024-03-09 13:30:37.423967259  [2024-03-09 13:30:37] frigate.detectors              WARNING : CPU detectors are not recommended and should only be used for testing or for trial purposes.
2024-03-09 13:30:37.460010204  [2024-03-09 13:30:37] frigate.app                    INFO    : Camera processor started for CameraEZVIZC6N: 315
2024-03-09 13:30:37.478031296  [2024-03-09 13:30:37] frigate.app                    INFO    : Capture process started for CameraEZVIZC6N: 316
2024-03-09 13:30:42.872070738  [INFO] Starting go2rtc healthcheck service...

```

# 4. Integrate with HASS

Search qua HACS rồi donwload về:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-hacs-frigate-search.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-hacs-frigate-search-download.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-hacs-frigate-search-download-2.jpg)

Vào HASS - Settings - Integration - Select Frigate vừa download về:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-integration-select-frigate.jpg)

Nhập địa chỉ Ip của frigate rồi submit:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-integration-select-frigate-submit.jpg)

Như này là OK:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-integration-select-frigate-submit-ok.jpg)

Reload lại HASS vào Integrations - tìm thấy Frigate:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-integration-reload-select-frigate.jpg)

Như này là OK:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-integration-reload-select-frigate-ok.jpg)

Vào Browser truy cập IP của frigate port 5000, thấy như này là OK:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/frigate-web-port-5000-cameras.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/frigate-web-port-5000-cameras-birdeye.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/frigate-web-port-5000-cameras-event.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/frigate-web-port-5000-cameras-exports.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/frigate-web-port-5000-cameras-storage.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/frigate-web-port-5000-cameras-system.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/frigate-web-port-5000-cameras-config.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/frigate-web-port-5000-cameras-logs.jpg)

Sửa file `configuration.yml` của HASS add panel Frigate:

```yml
# panel iframe
panel_iframe:
  frigate:
    title: "Frigate"
    url: "http://YOUR_FRIGATE_IP:5000"
    icon: mdi:camera
    require_admin: true
```

Như vậy có thể vào HASS rồi vào panel bên trái để xem Frigate:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-frigate-panel-iframe.jpg)

# 5. Add live view to HASS dashboard (frigate-card)

Install frigate-card:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-hacs-frigate-lovelace-card-select.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-hacs-frigate-lovelace-card-download.jpg)

Thêm như này vào dashboard:

```yml
title: "Camera"
path: "camera"
cards:
  - type: custom:frigate-card
    cameras:
      - camera_entity: camera.cameraezvizc6n
```

Sẽ được thành quả như này: 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-hacs-frigate-lovelace-card-show.jpg)

# 6. Tweak Frigate

Đọc hết file này để biết các option có thể điều chỉnh: https://docs.frigate.video/configuration/reference

## 6.1. Openvino

> If you do not have GPU or Edge TPU hardware, using the OpenVINO Detector is often more efficient than using the CPU detector.

Frigate nói nếu không có GPU hoặc Edge TPU hardware (Google Coral) thì nên dùng OpenVINO làm detector hơn là dùng CPU.  
Nhưng mình chưa có thời gian thử chạy openvino trên RPi của mình.  
Đây là 1 trang tham khảo: https://www.intel.com/content/www/us/en/support/articles/000055220/boards-and-kits.html

## 6.2. Increase GPU memory and use hardware acceleration

Theo doc này: https://docs.frigate.video/configuration/hardware_acceleration

Họ khuyên nên allocate RAM cho GPU của RPi lên ít nhất 128 bằng cách:  
- `sudo raspi-config` > Performance Options > GPU Memory > chọn 256 > OK > restart
- cách khác: `sudo nano /boot/config.txt` -> add thêm: `gpu_mem=256`

Rồi add thêm dòng này vào frigate `config.yml`:  

```yml
# if you want to decode a h264 stream
ffmpeg:
  hwaccel_args: preset-rpi-64-h264
```

## 6.3. Object filter

Set các object sẽ được track, có nhiều loại có sẵn ở đây: https://docs.frigate.video/configuration/objects

frigate `config.yml`:  

```yml
objects:
  track:
    - person
  filters:
    person:
      min_score: 0.5
      threshold: 0.7
```

## 6.4. Two-way audio (Two-way talk) - Pending chưa thành công

Nghĩa là đưa khả năng trò chuyện 2 chiều vào HASS.

Sau khi đọc bài này:

https://community.home-assistant.io/t/two-way-audio-e-g-for-doorbell-intercom-camera-systems-baby-monitors-sip/444063/19

https://github.com/AlexxIT/go2rtc

Yêu cầu là: https://github.com/dermotduffy/frigate-hass-card?tab=readme-ov-file#using-2-way-audio

Cần sử dụng go2rtc đã được bundle sẵn trong frigate

Hướng dẫn upgrade version go2rtc lên version latest trong frigate: https://docs.frigate.video/configuration/advanced#custom-go2rtc-version

Đọc bài này để sửa config frigate:

https://docs.frigate.video/configuration/live/#live-view-options

https://docs.frigate.video/guides/configuring_go2rtc/

File frigate `config.yml` cần sửa lại:

```yml
go2rtc:
  streams:
    CameraEZVIZC6N:
      - rtsp://admin:PASSWORD@192.168.1.8:554/live0
      - "ffmpeg:CameraEZVIZC6N#audio=opus"
  webrtc:
    candidates:
      - 192.168.1.128:8555
      - stun:8555
  log:
    level: debug
    api: debug
    rtsp: debug
    streams: debug
    webrtc: debug
    mse: debug
    hass: debug
    homekit: debug

# https://docs.frigate.video/configuration/cameras
cameras:
  CameraEZVIZC6N:
    ffmpeg:
      inputs:
        - path: rtsp://127.0.0.1:8554/CameraEZVIZC6N
          input_args: preset-rtsp-restream
          roles:
            - detect
            - record
    live:
      stream_name: CameraEZVIZC6N
```

file `docker-compose.yml` nên sửa như này để expose port 1984 ra cho UI của Go2rtc:

```yml
version: '3.0'

services:
    frigate:
        container_name: frigate
...
        ports:
        - "5000:5000"
        - "1984:1984" # Hoàng add: Go2rtc to expose Go2rtc Web UI
        - "8554:8554" # RTSP feeds
        - "8555:8555/tcp" # WebRTC over tcp
        - "8555:8555/udp" # WebRTC over udp
...
```

Sau restart sẽ có thể truy cập vào Go2rtc UI:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-frigate-go2rtc1984.jpg)

Test trên UI của Frigate:

Thử nói chuyện xem ok ko?

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/frigate-ui-camera-in-webrtc.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/frigate-ui-camera-in-mse.jpg)

Cả 2 mode MSE và Webrtc đều nghe được 1 chiều từ Camera đến HASS. 

Nhưng chiều từ HASS / App điện thoại đến Camera thì chịu.

UI của dashboard HASS cần sửa:

```yml
title: "Camera"
path: "camera"
cards:

  - type: custom:frigate-card
    cameras:
      - camera_entity: camera.cameraezvizc6n
        live_provider: go2rtc
        go2rtc:
          modes:
            - webrtc
    menu:
      buttons:
        microphone:
          enabled: true
        timeline:
          enabled: false
    live:
      microphone:
        always_connected: true
        disconnect_seconds: 0
```

Khi đó sẽ thấy biểu tượng microphone hiện lên ở đây:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-frigate-go2rtc-display-microphone.jpg)

Nhưng hiện tại ko thể dùng được. Có lẽ vì camera EZVIZ C6N ko có đúng codec support chăng:
https://github.com/AlexxIT/go2rtc?tab=readme-ov-file#two-way-audio

Ở link trên chỉ thấy 1 số camera support:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/go2rtc-support-2ways-audio.jpg)

Điều này làm mình muốn bán con camera này đi để mua Tapo TP Link C200 quá 😪

Đang tiếp tục debug...

Thử vào router mở port 8555 TCP/UDP (vào portal của Router DASAN làm):

- Thêm các rule vào iptables của RPi: 

  ```sh
  # This open makes these app works: Go2rtc
  # accept traffic TCP/UDP incoming interface eth0 on Docker port 8555 from anywhere
  iptables -I DOCKER-USER -p tcp -i eth0 --dport 8555 -j ACCEPT
  iptables -I DOCKER-USER -p udp -i eth0 --dport 8555 -j ACCEPT
  ```

- Confirm:

  ```
  $ sudo iptables -L -v -n | more

  Chain DOCKER-USER (1 references)
  pkts bytes target     prot opt in     out     source               destination
      0     0 ACCEPT     udp  --  eth0   *       0.0.0.0/0            0.0.0.0/0            udp dpt:8555
      0     0 ACCEPT     tcp  --  eth0   *       0.0.0.0/0            0.0.0.0/0            tcp dpt:8555
  22773 3043K ACCEPT     udp  --  eth0   *       0.0.0.0/0            0.0.0.0/0            udp dpt:51820
  54193 3422K ACCEPT     tcp  --  eth0   *       0.0.0.0/0            0.0.0.0/0            tcp dpt:443
  57266 2570K ACCEPT     tcp  --  eth0   *       0.0.0.0/0            0.0.0.0/0            tcp dpt:80
  230K   37M ACCEPT     udp  --  eth0   *       0.0.0.0/0            0.0.0.0/0            multiport dports 33000:65535
    12M 4352M ACCEPT     tcp  --  eth0   *       0.0.0.0/0            0.0.0.0/0            multiport dports 33000:65535
  18292 2888K DROP       udp  --  eth0   *      !192.168.1.0/24       0.0.0.0/0
  4528  277K DROP       tcp  --  eth0   *      !192.168.1.0/24       0.0.0.0/0
    13M 2365M RETURN     all  --  *      *       0.0.0.0/0            0.0.0.0/0

  $ sudo netfilter-persistent save
  $ sudo netfilter-persistent reload

  ```

- Sau khi làm bước trên thì mình vào HASS qua https url, trên điện thoại dùng 4G, đã thấy cái microphone đỏ hiện ra như này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/frigate-ui-camera-have-mic-icon-active.jpg)

- Tuy nhiên khi nói thì vẫn ko truyền âm thanh đến Camera được. Khó hiểu thực sự ...

Họ nói ở đây:

> There are many requirements for 2-way audio to work. See Using 2-way audio for more information about these. If your microphone still does not work and you believe you meet all the requirements try eliminating the card from the picture by going directly to the go2rtc UI, navigating to links for your given stream, then to webrtc.html with a microphone. If this does not work correctly with 2-way audio then your issue is with go2rtc not with the card. In this case, you could file an issue in that repo with debugging information as appropriate.

Thử sửa config go2rtc:

```yml
go2rtc:
  streams:
    CameraEZVIZC6N:
      - rtsp://admin:PASSWORD@192.168.1.8:554/live0
      - "ffmpeg:CameraEZVIZC6N#audio=pcm"
      - "ffmpeg:CameraEZVIZC6N#audio=opus"
      - "ffmpeg:CameraEZVIZC6N#audio=pcmu"
      - "ffmpeg:CameraEZVIZC6N#audio=pcma"
      - "ffmpeg:CameraEZVIZC6N#audio=aac"
  webrtc:
    candidates:
      - 192.168.1.128:8555
      - stun:8555
  log:
    level: debug
    api: debug
    rtsp: debug
    streams: debug
    webrtc: debug
    mse: debug
    hass: debug
    homekit: debug
```

- Nhưng mình vào go2rtc UI vẫn chưa test được cái microphone.

- Thử send post request thì bị lỗi `can't find consumer`:

```sh
$ curl --location --request POST 'http://192.168.1.128:1984/api/streams?dst=CameraEZVIZC6N&src=ffmpeg:https://download.samplelib.com/mp3/sample-6s.mp3#audio=pcma#input=file'
can't find consumer

# đã thử thay pcma bằng pcmu, aac, opus đều bị lỗi trên

# thử bằng 1 file sample lấy từ website Opus:
$ curl --location --request POST 'http://192.168.1.128:1984/api/streams?dst=CameraEZVIZC6N&src=ffmpeg:https://opus-codec.org/static/examples/samples/speech_orig.wav#audio=opus#input=file'
can't find consumer

$ curl --location --request POST 'http://192.168.1.128:1984/api/streams?dst=CameraEZVIZC6N&src=ffmpeg:https://opus-codec.org/static/examples/samples/speech_orig.wav#audio=pcma#input=file'
can't find consumer
```

- Khi vào page này để xem: http://192.168.1.128:1984/api/streams?src=CameraEZVIZC6N, Mình thấy có vẻ như EZVIZ C6N của mình có audio dùng codec là:

```
"medias": [
  "video, recvonly, H264",
  "audio, recvonly, MPEG4-GENERIC/16000"
],
```

- Mà cái codec `MPEG4-GENERIC/16000` thì lại ko được go2rtc/webrtc support: https://community.home-assistant.io/t/realtime-camera-streaming-without-any-delay-webrtc/258216/454

Chả lẽ phải mua camera khác sao?

Có 1 cái link khá hay ví dụ về cách chọn codec cho stream: https://github.com/AlexxIT/go2rtc?tab=readme-ov-file#codecs-negotiation

đang tìm hiểu tiếp link: https://community.home-assistant.io/t/tapo-cameras-frigate-go2rtc-i-cannot-figure-out-how-to-pass-audio/586077

dùng VLC app để check codec information:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/vlc-debug-camera-restream.jpg)

ko hiểu sao đã lấy link được frigate restream lại rồi, mà vẫn codec = AAC MPEG4:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/vlc-debug-camera-restream1.jpg)

thử thay đổi output arg preset như doc này ko ăn thua: https://docs.frigate.video/configuration/ffmpeg_presets/#output-args-presets

Làm thử theo clip này ko ăn thua, mặc dù clip làm khá rõ ràng HASS + frigate card + microphone: https://www.youtube.com/watch?v=upXyBVMR4RM&ab_channel=HassAssistant

Mình thử expose port 1984 go2rtc qua swag để có 1 link có https:

- tạo file `/opt/swag/config/nginx/proxy-confs/ezvizc6n-camera-go2rtc.subdomain.conf`:

```yml
## Version 2021/05/18
# make sure that your dns has a cname set for navidrome and that your navidrome container is not using a base url

# redirect all traffic to https
# server {
#     listen 80;
#     listen [::]:80;
#     server_name navidrome.*;
#     return 301 https://$host$request_uri;
# }

server {
    listen 80;
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name ezvizc6n-camera-go2rtc.MY_DOMAIN.duckdns.org;

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
        set $upstream_app frigate;
        set $upstream_port 1984;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
        
        proxy_hide_header X-Frame-Options;

    }
}
```

- Rồi restart swag, trên điện thoại 4G, vào link https://ezvizc6n-camera-go2rtc.MY_DOMAIN.duckdns.org để vào giao diện go2rtc. (Nếu hiện box đòi quyền microphone thì allow)

- Chọn links => kéo xuống WebRTC Magic => select `video+audio+microphone = two way audio from camera` => click link `webrtc.html`
Nhìn thấy được camera, nghe được audio, nhưng vẫn ko truyền được âm thanh từ mic trên điện thoại đến camera. 

Tiếp theo mình thử làm theo cái card này: https://github.com/AlexxIT/WebRTC?tab=readme-ov-file#two-way-audio

- install WebRTC camera integration trên HACS
- trên dashboard của HASS: 
  ```yml
  title: "Camera"
  path: "camera"
  cards:
    - type: 'custom:webrtc-camera'
      streams:
        - url: rtsp://127.0.0.1:8554/CameraEZVIZC6N
          mode: webrtc
          media: video,audio,microphone
          ui: true
  ```

- Tuy nhiên thì cũng ko dùng được chức năng 2ways audio.

Giờ mình làm theo cái này: https://community.home-assistant.io/t/go2rtc-send-audio-to-cam/587937/19:

- sửa file hass `configuration.yaml`:

  ```yml
  media_player:
    - platform: webrtc
      name: EZVIZ C6N Camera A
      stream: CameraEZVIZC6N
      audio: '-af "volume=10dB,adelay=2s,apad=pad_dur=6" -c:a pcm_alaw -ar:a 8000 -ac:a 1'
  ```

- Vào HASS -> Deleveloper tools => select `Services` => Go to YAML mode:

  ```yml
  service: media_player.play_media
  data:
    media_content_type: music
    media_content_id: https://download.samplelib.com/mp3/sample-6s.mp3
  target:
    entity_id: media_player.ezviz_c6n_camera_2
  ```

- Kết quả là vẫn bị lỗi Timeout ko thể send được media.
- Nếu dùng service TTS: Speak thì lại bị lỗi require Targets.
- Nói chung vẫn bị lỗi ko dùng được.

# 7. Setup Deepstack and Double Take

## 7.1. Install 

`docker-compose.yml` file:

```yml
...
  deepstack:
    container_name: deepstack
    restart: on-failure:15
    image: deepquestai/deepstack:arm64-2022.01.1
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /opt/deepstack:/datastore
    ports:
      - "5080:5000"
    environment:
      - VISION-FACE=True

  double-take:
    container_name: double-take
    restart: on-failure:15
    image: jakowenko/double-take:1.13.1
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /opt/double-take:/.storage
    ports:
      - 3080:3000
```

Run `docker-compose up -d`

Check log DeepStack:

```
 $ docker logs deepstack -f
DeepStack: Version 2022.01.01
/v1/vision/face
---------------------------------------
/v1/vision/face/recognize
---------------------------------------
/v1/vision/face/register
---------------------------------------
/v1/vision/face/match
---------------------------------------
/v1/vision/face/list
---------------------------------------
/v1/vision/face/delete
---------------------------------------
---------------------------------------
v1/backup
---------------------------------------
v1/restore

```

Giờ test giao diện Deepstack ở port 5080:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-deepstack-ui-first.jpg)

Giờ test giao diện Double Take ở port 3080:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-doubletake-ui-first.jpg)

File configuration của Double Take ở: `/opt/double-take/config/config.yml`

Check trên giao diện DoubleTake thấy xanh hết như này là đã connect được:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-doubletake-ui-config-ok.jpg)

Giờ test thử ra trước camera cho nó detect, sẽ thấy giao diện của Double Take nhận được ảnh như này, tuy nhiên ảnh bị trùng lặp 3 lần (1 ảnh của camera snapshot, 1 ảnh của mqtt, 1 ảnh latest):

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-doubletake-ui-match.jpg)

để giảm sự trùng lặp này thì cần sửa config đoạn này: (https://github.com/jakowenko/double-take/issues/102)

```yml
frigate:
  url: http://192.168.1.128:5000
  attempts:
    # number of times double take will request a frigate latest.jpg for facial recognition
    latest: 0
    # number of times double take will request a frigate snapshot.jpg for facial recognition
    snapshot: 10
    # process frigate images from frigate/+/person/snapshot topics
    mqtt: false
```

## 7.2. Train cho Deepstack biết người trong ảnh là ai

Tạo folder cho người sắp train:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-doubletake-ui-train-from-match.jpg)

Chọn các ảnh trên giao diện DoubleTake rồi ấn nút Train:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-doubletake-ui-train-from-match-start.jpg)

Rồi ấn nút này để Deepstack process lại image:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-doubletake-ui-train-from-match-reprocess.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-doubletake-ui-train-from-match-reprocessed.jpg)

Nếu bạn vào HASS thấy sensor double check của person thì có nghĩa là bạn đang setup sai sai:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-doubletake-ha-sensor-not-ok.jpg)

Như này: Mặc dù confidence 100% nhưng deepstack ko hiện xanh, màu đỏ nghĩa là `not matched`

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-doubletake-ha-sensor-not-ok-deepstack.jpg)

Cần sửa file config của double-take, `min_area: 500` hoặc bao nhiêu tùy bạn:

```yml
detect:
  match:
    # save match images
    save: true
    # include base64 encoded string in api results and mqtt messages
    # options: true, false, box
    base64: false
    # minimum confidence needed to consider a result a match
    confidence: 60
    # hours to keep match images until they are deleted
    purge: 168
    # minimum area in pixels to consider a result a match
    min_area: 500

  unknown:
    # save unknown images
    save: true
    # include base64 encoded string in api results and mqtt messages
    # options: true, false, box
    base64: false
    # minimum confidence needed before classifying a name as unknown
    confidence: 40
    # hours to keep unknown images until they are deleted
    purge: 8
    # minimum area in pixels to keep an unknown result
    min_area: 0
```

Làm sao hiện như này mới OK:  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-doubletake-ha-sensor-ok-deepstack.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-doubletake-ha-sensor-person-ok.jpg)

## 7.3. Setup để Double Take gửi message và hình ảnh qua Telegram Notify service

Hiện tại thì phải dựa vào state của `sensor.double_take_cameraezvizc6n` để phát hiện có chuyển động, sau khoảng 20s để DeepStack phân tích, nó sẽ trả về matches 

Khi ko có người chuyển dộng, state của nó sẽ như này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-doubletake-sensor-when-0.jpg)

Khi có phát hiện chuyển động và có matched, state sẽ chuyển sang dạng này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-doubletake-sensor-when-1-matched.jpg)

Sửa file `hass/config/configuration.yaml` để add notify Telegram platform vào:

```yml
telegram_bot:
  - platform: polling
    api_key: <API_KEY>
    allowed_chat_ids:
      - 888888888
      - -5555555555
      #- CHAT_ID # example: -987654321 for the chat_id of a group
notify:
  - platform: telegram
    name: hoangmnsd
    chat_id: 888888888
  - platform: telegram
    name: Family_Group
    chat_id: -5555555555
```

Tạo 1 Automation như sau:

```yml
- id: '458xxxxxxxxxxx7385hoangmnsd47286'
  alias: DoubleTake Actions
  trigger:
  - platform: state
    entity_id: sensor.double_take_cameraezvizc6n
    to: '1'
  action:
  - delay: 00:00:20
  - service: notify.hoangmnsd
    data:
      message: |-
        DoubleTake message
      data:
        photo:
          url: |-
            {% if trigger.to_state.attributes.matches[0] is defined %}
              http://192.168.1.128:3080/api/storage/matches/{{ trigger.to_state.attributes.matches[0].filename }}?box=true
            {% endif %}
          caption: |-
            {% if trigger.to_state.attributes.matches[0] is defined %}
              {{ trigger.to_state.attributes.matches[0].name }} is detected at home
            {% endif %}
```

Khi Telegram gửi message thành công:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-doubletake-send-telegram-photo.jpg)


# CREDIT

Doubletake + Deepstack + HASS for facial recognize:

https://www.youtube.com/watch?v=_61-hIL1AjQ&ab_channel=EverythingSmartHome

Deepstack:

https://www.youtube.com/watch?v=XPs0J1EQhK0&ab_channel=EverythingSmartHome

https://www.youtube.com/watch?v=vMdpLiAB9dI

Connect camera ezviz qua local network, not via internet or wifi:

https://www.youtube.com/watch?v=Mjo35rP1quI&ab_channel=ITKOUSTAV

https://www.youtube.com/watch?v=fNruvDy9tgc&ab_channel=ArhostNaMEDIA

Install frigate: https://www.youtube.com/watch?v=3pWQg4-VQ8o&ab_channel=HomeAutomationGuy

Full configuration của Frigate: https://docs.frigate.video/configuration/reference/

Kênh review về các loại security camera: https://www.youtube.com/playlist?list=PL-51DG-VULPom8Ud6vdf56Oeq51yA2xlp

2-ways voice HA:

https://community.home-assistant.io/t/two-way-audio-e-g-for-doorbell-intercom-camera-systems-baby-monitors-sip/444063/19

https://github.com/AlexxIT/go2rtc

Clip hướng dẫn sử dụng go2rtc:

https://www.youtube.com/watch?v=xx9DyCIHK-8&ab_channel=HassAssistant

https://www.youtube.com/watch?v=WnRJxneCUYE&ab_channel=HassAssistant

Cách để downgrade firmware của camera TP Link C200: https://github.com/nervous-inhuman/tplink-tapo-c200-re/issues/4#issuecomment-1030056785

Có người fix được lỗi two-way audio:

https://github.com/dermotduffy/frigate-hass-card/issues/1230#issuecomment-1645015445

FAQ về two-way audio not work:

https://github.com/dermotduffy/frigate-hass-card?tab=readme-ov-file#microphone--2-way-audio-doesnt-work


https://github.com/blakeblackshear/frigate/discussions/6190

debug test audio:
https://community.home-assistant.io/t/realtime-camera-streaming-without-any-delay-webrtc/258216/470


tạo go2rtc html page để allow microphone 2ways audio:  
https://community.home-assistant.io/t/go2rtc-project-help-thread/454451/107

config nginx để đến go2rtc 1984:  
https://community.home-assistant.io/t/go2rtc-project-help-thread/454451/101

thử dùng vlc app để check codec:  
https://github.com/blakeblackshear/frigate/discussions/2572

thử sửa camera section, thêm input_args và output_args:  
https://docs.frigate.video/configuration/live/#setting-stream-for-live-ui

post lại comment vào thread này cho đúng frigate+go2rtc:  
https://community.home-assistant.io/t/frigate-got2rtc-webrtc-camera-and-the-combination-of-things-not-getting-what-i-want/561667/14

hoặc thread này: 
https://community.home-assistant.io/t/go2rtc-project-help-thread/454451/443

thử dùng webrtc này xem có works ko, đây là webrtc riêng, ko phải bundle trong frigate: 
https://github.com/AlexxIT/WebRTC?tab=readme-ov-file#two-way-audio

thử add media_player to configuration file:  
https://github.com/AlexxIT/WebRTC?tab=readme-ov-file#stream-to-camera  
hoặc: 
https://community.home-assistant.io/t/go2rtc-send-audio-to-cam/587937/19

có người share config cho TPLink TAPO C200 camera:
https://github.com/blakeblackshear/frigate/issues/9849

thử dùng cái port 8000 giống như app EZVIZ provide => ko ăn thua

đọc tiếp: https://www.reddit.com/r/homeassistant/comments/11ezkns/cameras_and_audio_help/
 