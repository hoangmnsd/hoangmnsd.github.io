---
title: "Setup Home Assistant on Raspberry Pi (Part 1) - Addons"
date: 2022-05-01T14:20:21+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [RaspberryPi,HomeAssistant,Docker-compose]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Bài này tổng hợp các step gần như từ đầu đến cuối để setup Hệ thống Home Assistant Container trên Raspberry Pi"
---

Bài này tổng hợp các step gần như từ đầu đến cuối để setup Hệ thống Home Assistant Container trên Raspberry Pi

## 1. Install Docker & Docker Compose

```sh
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install avahi-daemon
sudo apt install git -y
sudo apt update
sudo apt full-upgrade
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ${USER}
reboot to apply: sudo shutdown -r now

docker version
docker info
docker run hello-world

# install pip3
sudo apt-get install libffi-dev libssl-dev
sudo apt install python3-dev -y
sudo apt-get install -y python3 python3-pip
sudo shutdown -r now

# Cách 1 install docker-compose default
sudo shutdown -r now
sudo su
pip3 install docker-compose
docker-compose version
sudo systemctl enable docker

# Cách 2 khác để install docker-compose specific version
# Cần biết OS của bạn là gì đã:
uname -s
# giả output là linux
uname -m
# giả sử output là aarch64
# Vào trang này lấy link: https://github.com/docker/compose/releases/
# chọn cái tương ứng linux, arch64 là OK
# giả sử lấy được: https://github.com/docker/compose/releases/download/2.5.0/docker-compose-linux-aarch64
#install docker-compose như sau:
sudo curl -L https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-linux-aarch64 -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker-compose --version
sudo systemctl enable docker
```

Nếu vì 1 lý do nào đó, docker bị lỗi, bạn muốn uninstall docker khỏi máy thì:  
```sh
# uninstall docker
dpkg -l | grep -i docker

sudo apt-get purge -y docker-engine docker docker.io docker-ce docker-ce-cli
sudo apt-get autoremove -y --purge docker-engine docker docker.io docker-ce  

sudo rm -rf /var/lib/docker /etc/docker
sudo rm -rf /var/run/docker.sock

# uninstall docker-compose
pip3 uninstall docker-compose

# uninstall python
sudo apt-get remove libffi-dev libssl-dev
sudo apt remove python3-dev -Y
sudo apt-get remove -y python3 python3-pip
```

## 2. Install Portainer & HASS

create file `/opt/hass/docker-compose.yml`  
```yaml
version: '3.0'

services:
  portainer:
    container_name: portainer
    image: portainer/portainer
    restart: always
    stdin_open: true
    tty: true
    ports:
      - "9000:9000/tcp"
    environment:
      - TZ=Asia/Ho_Chi_Minh
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /opt/portainer:/data

  homeassistant:
    container_name: homeassistant
    image: "ghcr.io/home-assistant/home-assistant:2022.5.2"
    volumes:
      - /opt/hass/config:/config
      - /etc/localtime:/etc/localtime:ro
    restart: unless-stopped
    privileged: true
    network_mode: host

```

```sh
cd /opt/hass
docker-compose up -d
```

Check access HASS UI: `http://RPi_LOCAL_IP:8123/`, create account/password

Check access Portainer: `http://RPi_LOCAL_IP:9000/`, create account/password

Edit file `/opt/hass/config/configuration.yaml`  
Add this on top:
```yaml
panel_iframe:
  portainer:
    title: "Portainer"
    url: "http://RPi_LOCAL_IP:9000/#/containers"
    icon: mdi:docker
    require_admin: true
```

Go to HASS UI: Configuration -> Settings -> Restart to take effect.   
HASS UI will have new frame `Portainer` on the sidebar:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-sidebar-portainer-zigbee2mqtt.jpg)  

## 3. Install Mosquito 

edit `/opt/hass/docker-compose.yml`  
add these lines:
```yaml
....
  mosquitto:
    image: eclipse-mosquitto:2.0.14
    container_name: mosquitto
    volumes:
      - /opt/mosquitto:/mosquitto
    ports:
      - 1883:1883
      - 9001:9001
```

create file `/opt/mosquitto/config/mosquitto.conf`/:   
```sh
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log

# Authentication
#allow_anonymous false
#listener 1883
#password_file /mosquitto/config/password.txt
```

Run:  
```sh
docker-compose up -d
```

check log of mosquitto container if there is any error? You should fix it.  
this is normal: `No logs available`  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/mosquitto-log-ok.jpg)  

Từ Portainer UI -> vào `mosquitto` container via Console log, tạo user `mqttuser` và nhập password bằng command:
```sh
mosquitto_passwd -c /mosquitto/config/password.txt mqttuser
```

Sửa lại file `/opt/mosquitto/config/mosquitto.conf`, uncomment phần Authentication:
```sh
persistence true
persistence_location /mosquitto/data/
log_dest file /mosquitto/log/mosquitto.log

# Authentication
allow_anonymous false
listener 1883
password_file /mosquitto/config/password.txt
```

Vào Portainer, restart `mosquitto` container, check log no error là OK:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/mosquitto-log-ok.jpg)  

Vào HASS, Configuration -> Devices & Services -> Integrations -> Add integration -> Search MQTT
điền IP của RPi (nơi run `mosquitto` container, ex: 192.168.1.4), port: 1883, user: `mqttuser` password: ******

Mục tiêu cuối cùng là add được Integration MQTT như thế này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-mosquitto-integration.jpg)

## 4. Install Zigbee2MQTT 

Mua 1 chiếc USB 3.0 Zigbee Sonoff Dongle, cắm vào RPi:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/usb-sonof-zigbee-dongle-30-cc2652p.jpg)

Dùng command sau để xem serial id của USB vừa cắm:  
```sh
$ ls -l /dev/serial/by-id/
total 0
lrwxrwxrwx 1 root root 13 May  1 21:21 usb-ITead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_e8fc8a915ad9eb119edf148e6fe9f4d9-if00-port0 -> ../../ttyUSB0
```
-> lấy được `ttyUSB0`

edit `/opt/hass/docker-compose.yml`
add these line:
```yaml
...
  zigbee2mqtt:
    container_name: zigbee2mqtt
    image: koenkk/zigbee2mqtt:1.25.0
    restart: unless-stopped
    volumes:
      - /opt/zigbee2mqtt/data:/app/data
      - /run/udev:/run/udev:ro
    ports:
      # Frontend port
      - 8080:8080
    environment:
      - TZ=Asia/Ho_Chi_Minh
    devices:
      # Make sure this matched your adapter location
      - /dev/ttyUSB0:/dev/ttyUSB0
```
Run:  
```sh
docker-compose up -d
```

Edit file `/opt/zigbee2mqtt/data/configuration.yaml`
```yaml
# Home Assistant integration (MQTT discovery)
homeassistant: true

# allow new devices to join
permit_join: true

# MQTT settings
mqtt:
  # MQTT base topic for zigbee2mqtt MQTT messages
  base_topic: zigbee2mqtt
  # MQTT server URL
  server: 'mqtt://mosquitto:1883'
  # MQTT server authentication, uncomment if required:
  user: mqttuser
  password: PASSWORD_OF_mqttuser

# Serial settings
serial:
  # Location USB sniffer
  port: /dev/ttyUSB0

# Enable the Zigbee2MQTT frontend
frontend:
  port: 8080
experimental:
  new_api: true

```
check log container `zigbee2mqtt` ko có lỗi là OK:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/zigbee2mqtt-log-ok.jpg)  

Now you can access UI on port 8080 (ex: 192.168.1.8:8080)

Add frame `zigbee2mqtt` to HASS UI:

edit `/opt/hass/config/configuration.yaml`:  
add these line:
```yaml
panel_iframe:
...
  zigbee2mqtt:
    title: "Zigbee2MQTT"
    url: "http://RPi_LOCAL_IP:8080"
    icon: mdi:zigbee
    require_admin: true
```

Go to HASS UI: Configuration -> Settings -> Restart to take effect.  
HASS UI will have new frame on the left sidebar.  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-zigbee2mqtt-dashboard.jpg)

## 5. Connect Zigbee device to Zigbee2MQTT service

### 5.1. Setup
 
Giả sử bạn đã mua 1 sensor như thế này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/sonoff-window-door-sensor-shopee.jpg)

trên giao diện Zigbee2MQTT ấn vào nút `Permit join (All)`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-zigbee2mqtt-dashboard.jpg)

Nó sẽ hiện đếm  ngược khoảng 250s,  
Trong thời gian đó ấn lì nút này của sensor khoảng 5s, ko nên ấn lâu quá - sensor sẽ left network:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/sonoff-window-door-sensor-click.jpg)  

Cho đến khi hiện ra device như này là OK, sensor đã join network zigbee thành công:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/sonoff-window-door-sensor-joined.jpg)  

1 số tab thông tin về sensor trên Zigbee2MQTT:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/sonoff-window-door-ss-about.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/sonoff-window-door-ss-expose.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/sonoff-window-door-ss-bind.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/sonoff-window-door-ss-reporting.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/sonoff-window-door-ss-setting.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/sonoff-window-door-ss-state.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/sonoff-window-door-ss-clusters.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/sonoff-window-door-ss-devconsole.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/sonoff-window-door-ss-sence.jpg)


### 5.2. Test

Nếu bạn đặt 2 cục gần nhau, trạng thái sẽ thay đổi `closed` như này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/sonoff-window-door-ss-state-closed.jpg)   
Nếu 2 cục đặt xa nhau, trạng thái sẽ là `open`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/sonoff-window-door-ss-state-open.jpg)  

Thay đổi phản ánh rất nhanh, gần như ngay lập tức 😍 rất hữu dụng phải ko?

Giờ quay lại màn hình HASS -> Setting -> Integration, bạn sẽ thấy 1 device đã được xuất hiện dưới MQTT integration:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-integration-mqtt-1device.jpg)  

Ấn vào bạn sẽ thấy Sensor của bạn cùng với các thông số:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-device-sensor-frontdoor.jpg)  

### 5.3. Automation & Alert

Tiếp theo sẽ là 1 số script `Automation` or `Alert` để ứng dụng các sensor này nhé!  

**Automation** (`hass/config/automations.yaml`):
```yaml
# Warning when Front Door open more than 1 min => change to use Alert in configuration.json
- id: '15324556454'
  alias: Warning when Front Door open more than 1 min
  description: 'Warning when Front Door open more than 1 min'
  trigger:
  - entity_id: binary_sensor.front_door_sensor_contact
    for: 00:01:00 # wait for x min after changing state from off to on
    platform: state
    to: 'on'
  condition: []
  action:
  - data:
      message: ''
      title: '🤔 HASS: Front door left open more than a min.'
    service: telegram_bot.send_message
```
nhưng cái cách dùng Automation trên ko hay lắm, HASS cung cấp sẵn tính năng `Alert` dùng hay hơn:  

**Alert** (`hass/config/configuration.yaml`) repeat sau 3/6/10 min, về sau cứ 10min alert 1 lần:
```yaml
...
notify:
  - platform: telegram
    name: hoangmnsd
    chat_id: 816661853
...
alert:
  # Front door open
  front_door_open:
    name: Front door is open
    entity_id: binary_sensor.front_door_sensor_contact
    state: "on"   # Optional, 'on' is the default value
    repeat:
      - 3
      - 6
      - 10
    can_acknowledge: true  # Optional, default is true
    skip_first: true  # Optional, false is the default
    message: "😲 HASS: Front door left open more than a min."
    done_message: "😉 HASS: Front door closed."
    notifiers:
      - hoangmnsd # need to specify notifier
```

### 5.4. Using Blueprint to notify when Sensor battery low

**Cách 1: Dùng sbyx blueprint**

HASS Community cung cấp 1 blueprint để xử lý việc cảnh báo battery cho sensor này:
https://community.home-assistant.io/t/low-battery-level-detection-notification-for-all-battery-sensors/258664

Nếu ko ấn vào nút `Import Blueprint` mà bị lỗi, thì phải import thủ công như sau

Vào RPi server, tạo file `/opt/hass/config/blueprints/automation/sbyx/low-battery-level-detection-notification-for-all-battery-sensors.yaml`  

(content file lấy từ link này `https://gist.github.com/sbyx/1f6f434f0903b872b84c4302637d0890`)

-> restart HASS

Để sử dụng blueprint, edit file `hass/config/automations.yaml`:  

Như này là nó sẽ notify everyday at 10:00 PM, khi có 1 sensor nào battery dưới 10%, gửi message về notify `hoangmnsd`

```yaml
# Warning when Front Door sensor low battery
- id: '1653065570149'
  alias: Low battery level detection & notification for all battery sensors
  description: 'Low battery level detection & notification for all battery sensors'
  use_blueprint:
    path: sbyx/low-battery-level-detection-notification-for-all-battery-sensors.yaml
    input:
      threshold: 10
      time: '22:00:00'
      actions:
      - service: notify.hoangmnsd
        data:
          message: '☹ HASS: {{sensors}} is low battery, about 10%'
```
Các bạn có thể đọc file để hiểu `https://gist.github.com/sbyx/1f6f434f0903b872b84c4302637d0890`.  
Nó theo dõi tất cả các sensor mà có `device_class` = `battery`

**Cách 2: Clone lại hoangmsnd blueprint**

Update 2022.07.16: Sau 1 thời gian sử dụng các Sonoff Sensor, mình nhận ra rằng lúc nào chúng cũng show 100% battery.  
Mình thực sự sẽ ko thể biết thời lượng pin của chúng đang còn bao nhiêu nếu cứ chỉ nhìn vào cái số 100 ảo lòi đó.  
Thế nên mình sẽ clone lại cái blueprint trên, tạo blueprint của riêng mình.

Chúng ta sẽ dựa trên voltage để theo dõi, vì chỉ có voltage mới giảm dần theo thời gian.

Max voltage của pin là 3200 mV. Chúng ta sẽ warning khi pin giảm xuống dưới 800 mV.

Vào RPi server, tạo file `/opt/hass/config/blueprints/automation/hoangmnsd/low-battery-voltage-detection-notification-for-all-battery-sensors.yaml`  

content file:
```yml
blueprint:
  name: Low battery level detection & notification for all battery sensors
  description: Regularly test all sensors with 'battery' device-class for crossing
    a certain battery level threshold and if so execute an action.
  domain: automation
  input:
    threshold:
      name: Battery warning level threshold
      description: Battery sensors below threshold are assumed to be low-battery (as
        well as binary battery sensors with value 'on').
      default: 800
      selector:
        number:
          min: 100
          max: 3200
          unit_of_measurement: 'mV'
          mode: slider
          step: 100
    time:
      name: Time to test on
      description: Test is run at configured time
      default: '10:00:00'
      selector:
        time: {}
    day:
      name: Weekday to test on
      description: 'Test is run at configured time either everyday (0) or on a given
        weekday (1: Monday ... 7: Sunday)'
      default: 0
      selector:
        number:
          min: 0.0
          max: 7.0
          mode: slider
          step: 1.0
    exclude:
      name: Excluded Sensors
      description: Battery sensors (e.g. smartphone) to exclude from detection. Only entities are supported, devices must be expanded!
      default: {entity_id: []}
      selector:
        target:
          entity:
            device_class: battery
    actions:
      name: Actions
      description: Notifications or similar to be run. {{sensors}} is replaced with
        the names of sensors being low on battery.
      selector:
        action: {}
  source_url: https://gist.github.com/hoangmnsd
variables:
  day: !input 'day'
  threshold: !input 'threshold'
  exclude: !input 'exclude'
  sensors: >-
    {% set result = namespace(sensors=[]) %}
    {% for state in states.binary_sensor | selectattr('attributes.device_class', '==', 'battery') %}
      {% if 0 <= state.attributes.voltage | int(-1) < threshold | int and not state.entity_id in exclude.entity_id %}
        {% set result.sensors = result.sensors + [state.name] %}
      {% endif %}
    {% endfor %}
    {{result.sensors|join(', ')}}
trigger:
- platform: time
  at: !input 'time'
condition:
- '{{ sensors != '''' and (day | int == 0 or day | int == now().isoweekday()) }}'
action:
- choose: []
  default: !input 'actions'
mode: single
```

file `automations.yml` add thêm đoạn sau:  
```yml
# # Warning when sensor low battery (using hoangmnsd blueprint)
- id: '92hoangmnsd3972358762324'
  alias: Low battery voltage detection & notification for all battery sensors
  description: ''
  use_blueprint:
    path: hoangmnsd/low-battery-voltage-detection-notification-for-all-battery-sensors.yaml
    input:
      threshold: 500
      time: '22:00:00'
      actions:
      - service: notify.hoangmnsd
        data:
          message: '☹ HASS: {{sensors}}, lets take a look'
```
Thế là xong!

## 6. Install HACS (Home Assistant Comunity Store)

Go inside the container with `docker exec -it homeassistant bash`, 
Run command: 
```sh
wget -q -O - https://install.hacs.xyz | bash -
```
restart HASS

Vào Configuration -> Add Integration -> Search `HACS` -> tick chọn all -> submit

Cấp quyền cho nó access vào GitHub của bạn (sẽ có 1 key hiện ra để paste vào)

Sau đó sẽ thấy HACS hiện bên trái sidebar:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hacs-sidebar-appeared.jpg)  

Ví dụ add 1 Card từ HACS:  

Chọn `HACS` -> `Frontend` -> Ấn `Explore & dowload repositories` (nút màu xanh)

Search Air Purifier sẽ thấy `Air Purifier Card` -> Chọn cái của `@fineemb` (chú ý vì cái này dc recommended)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hacs-search-custom-card.jpg)

restart HASS

Vào Overview -> edit Dashboard -> Add Card -> Sẽ thấy `Air Purifier` xuất hiện:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-hacs-custom-card-appeared.jpg)  

## 7. Integrate Telegram Bot

Cần biết cách tạo Bot, lấy `TELEGRAM_TOKEN` và `CHAT_ID`, có thể tham khảo bài này:  
[Lambda + API Gateway, Telegram Bot and Serverless Webapp](../../posts/encrypt-lambda-apigw-telegram-bot-serverless-webapp/)  

Sau khi lấy dc `TELEGRAM_TOKEN` và `CHAT_ID` của Telegram Bot của bạn

edit `/opt/hass/config/configuration.yaml`:  
```yaml
# Example configuration.yaml entry for the Telegram Bot
telegram_bot:
  - platform: polling
    api_key: TELEGRAM_TOKEN
    allowed_chat_ids:
      - CHAT_ID # example: 123456789 for the chat_id of a user
      #- CHAT_ID_2 # example: -987654321 for the chat_id of a group
      #- CHAT_ID_3
notify:
  - platform: telegram
    name: hoangmnsd
    chat_id: CHAT_ID # example: 123456789 for the chat_id of a user
```

restart HASS

### 7.1. Cách sử dụng service Telegram Bot

Ví dụ muốn gửi message đến Telegram khi log của HASS có lỗi.   

edit file `/opt/hass/config/configuration.yaml`:
```yaml
system_log:
  fire_event: true
```

edit file `/opt/hass/config/automations.yaml`:
```yaml
# HASS Notify When Error Log Occured
- id: '15888152543'
  alias: HASS Notify When Error Log Occured
  description: HASS Notify When Error Log Occured
  trigger:
  - event_data:
      level: ERROR
    event_type: system_log_event
    platform: event
    # Ignore these errors
  condition: 
    - "{{ 'Error while getting Updates: urllib3 HTTPError' not in trigger.event.data.message[0] }}"
    - "{{ 'HacsDisabledReason.RATE_LIMIT' not in trigger.event.data.message[0] }}"
    - "{{ 'Error handling request' not in trigger.event.data.message[0] }}"
    - "{{ 'Got error when receiving: timed out' not in trigger.event.data.message[0] }}"
    - "{{ 'Error while getting Updates: Conflict: terminated by other getUpdates request' not in trigger.event.data.message[0] }}"
    - "{{ 'Update for fan.bedroom_air_purifier_3h fails' not in trigger.event.data.message[0] }}"
  action:
  # Send to Telegram or any notify platform
  - data_template:
      message: '{{trigger.event.data.name}} {{ ''\n'' -}} {{trigger.event.data.message}}'
      parse_mode: html
      title: '😱 Home Assistant: UNEXPECTED ERROR!'
    service: telegram_bot.send_message
  # - data_template:
  #     message: '{{trigger.event.data.name}} {{ ''\n'' -}} {{trigger.event.data.message}}'
  #     title: '😱 Home Assistant: ERROR!'
  #   service: notify.mobile_app_abc
```
restart HASS

Thử tạo lỗi và trải nghiệm xem có nhận được tin nhắn ko nhé?

Có 1 cách để debug trường hợp này:  

Open two browser tabs, each one connected to your Home Assistant instance.

In first tab, go to Developer Tools > Events, enter system_log_event in “Event to subscribe to” then click “Listen to events”:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-developer-listen-event.jpg)

In second tab, go to Developer Tools > Services, select “System Log: Write”, enter some text in “Message”, enable “Level”, select “error”, then click “Call Service”.  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-developer-service-call.jpg)

In first tab, you can see the structure of payload:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-developer-listen-event-fired.jpg)


## 8. Install Duplicati (for backup purpose)

edit `/opt/hass/docker-compose.yml`
add these line:
```yaml
...
  duplicati:
    image: lscr.io/linuxserver/duplicati:2.0.6
    container_name: duplicati
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=TZ=Asia/Ho_Chi_Minh
      - CLI_ARGS= #optional
    volumes:
      - /opt/duplicati/config:/config
      - /opt/duplicati/backups:/backups
      - /opt:/source
    ports:
      - 8200:8200
    restart: unless-stopped
```
Run:  
```sh
docker-compose up -d
```

Add frame `duplicati` to HASS UI:
edit `/opt/hass/config/configuration.yaml`:  
add these line:
```yaml
panel_iframe:
...
  duplicati:
    title: "Duplicati"
    url: "http://RPi_LOCAL_IP:8200"
    icon: mdi:backup-restore
    require_admin: true
```
restart HASS

Thông qua Portainer, check log của container ko có lỗi gì là OK:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-duplicati-log-ok.jpg)

Bạn có thể access vào giao diện Duplicati qua HASS UI như sau:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-sidebar-duplicati.jpg)

### 8.1. Setup Duplicati backup to AWS S3

First you should creat an user (eg: `duplicati_backup`) in IAM service, note that select `Programmatic access` type:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/duplicati-add-user-aws.jpg)

Your user should be attached this custom policy:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/duplicati-attached-policy-aws.jpg)
```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:ListBucket",
                "iam:GetUser",
                "s3:GetBucketAcl",
                "s3:GetBucketLocation",
                "s3:GetBucketPolicy"
            ],
            "Resource": [
                "arn:aws:s3:::AWS_S3_BUCKET",
                "arn:aws:iam::AWS_ACCOUNT_ID:user/duplicati_backup"
            ]
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "s3:ListAllMyBuckets",
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor2",
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObjectAcl",
                "s3:GetObject",
                "s3:DeleteObjectVersion",
                "s3:DeleteObject",
                "s3:PutObjectAcl"
            ],
            "Resource": "arn:aws:s3:::AWS_S3_BUCKET/*"
        }
    ]
}
```

Chọn Add Backup, chọn S3, nhập hết các tùy chọn như này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/duplicati-add-backup.jpg)

Chý ý khi chọn test connection hãy chọn `No` ở đây:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/duplicati-adjust-bucket-name-no.jpg)

Test connection cần works như này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/duplicati-connection-works.jpg)

Màn hình select source, ko nên chọn `containerd, duplicati, portainer` vì những cái ý ko cần backup đâu, còn cái `hass/config/.storage` thì bạn nên ssh vào RPi, dùng command `chown pi:pi hass/config/.storage/* -R` để có thể backup được:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/duplicati-add-backup-select-source.jpg)

Màn hình select schedule:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/duplicati-add-backup-select-schedule.jpg)

Màn hình select size, ko quan trọng lắm:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/duplicati-select-size.jpg)

Sau khi đã save xong bộ config, có thể ấn `Run now` để test:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/duplicati-scheduled.jpg)

Nếu bị lỗi này có nghĩa là bạn có 1 folder nào đó ko thể backup, có lẽ là `containerd, duplicati`, hoặc vì lỗi permission nên duplicati ko thể backup được chúng, nên test lại với 1 file nhỏ xem sao:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/duplicati-error-socket-shutdown.jpg)

Backup log ko có lỗi gì là ok, hoặc nếu có WARNING thì bạn xem những file đó nếu ko cần thiết thì cũng ok: 
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/duplicati-backup-log-ok.jpg)


## 9. Install DuckDNS (for expose outside access purpose)

Setup trên Router, tìm phần `NAT` -> `Port Forwarding` để tạo 1 rule forward từ port 8123 đến port 8123 của RPi IP:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/router-nat-config-port-fwarding-8123.jpg)

Đăng ký account `DuckDNS.org` và bạn sẽ nhận được token như này:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/duckdns-token-init.jpg)

Add subdomain theo ý bạn vào (giả sử là `YOUR_SUBDOMAIN.duckdns.org`), update IP là `8.8.8.8`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/duckdns-add-subdomain.jpg)

Edit file `/opt/hass/docker-compose.yaml`:  
```yaml
version: "3.0"
services:
...
  duckdns:
    image: lscr.io/linuxserver/duckdns:68a3222a-ls97
    container_name: duckdns
    environment:
      - PUID=1000 #optional
      - PGID=1000 #optional
      - TZ=Asia/Ho_Chi_Minh
      - SUBDOMAINS=YOUR_SUBDOMAIN # eg: `facebook` not `facebook.duckdns.org`
      - TOKEN=DUCKDNS_TOKEN # replace DUCKDNS_TOKEN by your token from duckdns.org
      - LOG_FILE=true #optional
    volumes:
      - /opt/duckdns/config:/config
    restart: unless-stopped
```
Run:
```sh
docker-compose up -d

# check log
docker logs duckdns
```

Nếu log như này là OK: 
```
[cont-init.d] 10-adduser: exited 0.
[cont-init.d] 40-config: executing...
Retrieving subdomain and token from the environment variables
log will be output to file
Your IP was updated at Sat May  7 22:37:48 +07 2022
[cont-init.d] 40-config: exited 0.
[cont-init.d] 90-custom-folders: executing...
[cont-init.d] 90-custom-folders: exited 0.
[cont-init.d] 99-custom-files: executing...
[custom-init] no custom files found exiting...
[cont-init.d] 99-custom-files: exited 0.
[cont-init.d] done.
[services.d] starting services
[services.d] done.
```

Quay lại `duckdns.org` sẽ thấy IP của mình đã đc cập nhật lên, ko còn là 8.8.8.8 nữa:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/duckdns-subdomain-ip-updated.jpg)

Đến lúc này vào địa chỉ subdomain mà bạn đã đăng ký là có thể truy cập được HASS từ internet rồi:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/duckdns-subdomain-accessible.jpg)

Vì 1 số hạn chế liên quan đến HASS Container, Router DASAN của VNPT mà mình ko config dc HTTPS bằng Letsencrypt. Hy vọng thời gian tới có thể làm được. Các hạn chế ví dụ như:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/router-endport-must-greater-than-startport.jpg)

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/router-cannot-set-reserved-external-port.jpg)

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/router-cannot-set-reserved-external-port-2.jpg)

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/router-endport-must-greater-than-startport-2.jpg)

và hạn chế khi HASS chạy trên Container ko có Add-on Duckdns như bản HASS OS (bản đó support Letsencrypt sẵn luôn)

## 10. Install Wireguard

### 10.1. Setup

Giả sử bạn đã đăng ký 1 subdomain trên `duckdns.org` tên là `YOUR_SUB_DOMAIN.duckdns.org`.  

Bạn cũng đã update IP của `YOUR_SUB_DOMAIN.duckdns.org` trỏ đến public IP của RPi.  

Edit file `/opt/hass/docker-compose.yaml`:  
```yaml
version: "3.0"
services:
...
  wireguard:
    image: lscr.io/linuxserver/wireguard:1.0.20210914
    container_name: wireguard
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Ho_Chi_Minh
      - SERVERURL=YOUR_SUB_DOMAIN.duckdns.org #optional
      - SERVERPORT=51820 #optional
      - PEERS=myphonelg,myphonevsm #optional
      - PEERDNS=auto #optional
      - INTERNAL_SUBNET=10.13.13.0 #optional
      - ALLOWEDIPS=0.0.0.0/0 #optional
      - LOG_CONFS=true #optional
    volumes:
      - /opt/wireguard/config:/config
      - /opt/wireguard/modules:/lib/modules
    ports:
      - 51820:51820/udp
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    restart: unless-stopped
```
Chú ý sửa `YOUR_SUB_DOMAIN`. Nếu ko có domain có thể dùng public IP.  
Phần `PEERS=`: đang đặt tên client cho dễ nhớ, bạn có thể đặt tự do ví dụ `PEERS=mylaptop`

Run:
```sh
docker-compose up -d

# check log
docker logs wireguard
```

```
[s6-init] making user provided files available at /var/run/s6/etc...exited 0.
[s6-init] ensuring user provided files have correct perms...exited 0.
[fix-attrs.d] applying ownership & permissions fixes...
[fix-attrs.d] done.
[cont-init.d] executing container initialization scripts...
[cont-init.d] 01-envfile: executing...
[cont-init.d] 01-envfile: exited 0.
[cont-init.d] 01-migrations: executing...
[migrations] started
[migrations] no migrations found
[cont-init.d] 01-migrations: exited 0.
[cont-init.d] 02-tamper-check: executing...
[cont-init.d] 02-tamper-check: exited 0.
[cont-init.d] 10-adduser: executing...

-------------------------------------
          _         ()
         | |  ___   _    __
         | | / __| | |  /  \
         | | \__ \ | | | () |
         |_| |___/ |_|  \__/


Brought to you by linuxserver.io
-------------------------------------

To support the app dev(s) visit:
WireGuard: https://www.wireguard.com/donations/

To support LSIO projects visit:
https://www.linuxserver.io/donate/
-------------------------------------
GID/UID
-------------------------------------

User uid:    1000
User gid:    1000
-------------------------------------

[cont-init.d] 10-adduser: exited 0.
[cont-init.d] 30-module: executing...
Uname info: Linux 880be7489d30 5.15.32-v8+ #1538 SMP PREEMPT Thu Mar 31 19:40:39 BST 2022 aarch64 aarch64 aarch64 GNU/Linux
**** It seems the wireguard module is already active. Skipping kernel header install and module compilation. ****
[cont-init.d] 30-module: exited 0.
[cont-init.d] 40-confs: executing...
**** Server mode is selected ****
**** External server address is set to <REDACTED-SUBDOMAIN>.duckdns.org ****
**** External server port is set to 51820. Make sure that port is properly forwarded to port 51820 inside this container ****
**** Internal subnet is set to 10.13.13.0 ****
**** AllowedIPs for peers 0.0.0.0/0 ****
**** PEERDNS var is either not set or is set to "auto", setting peer DNS to 10.13.13.1 to use wireguard docker host's DNS. ****
**** No wg0.conf found (maybe an initial install), generating 1 server and 1 peer/client confs ****
grep: /config/peer*/*.conf: No such file or directory
PEER 1 QR code:
[REDACTED]
[cont-init.d] 40-confs: exited 0.
[cont-init.d] 90-custom-folders: executing...
[cont-init.d] 90-custom-folders: exited 0.
[cont-init.d] 99-custom-scripts: executing...
[custom-init] no custom files found exiting...
[cont-init.d] 99-custom-scripts: exited 0.
[cont-init.d] done.
[services.d] starting services
[services.d] done.
[#] ip link add wg0 type wireguard
[#] wg setconf wg0 /dev/fd/63
[#] ip -4 address add 10.13.13.1 dev wg0
[#] ip link set mtu 1420 up dev wg0
.:53
CoreDNS-1.9.1
linux/arm64, go1.17.8, 4b597f8
[#] ip -4 route add 10.13.13.2/32 dev wg0
[#] iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
```

Trên Router sửa `Port Forwarding`, add thêm 1 rule `From port 51820 to port 51820` local IP là IP của RPi.  

Run câu lệnh sau để lấy QR code của `peer1`:  
```sh
docker exec -it wireguard /app/show-peer 1
hoặc 
docker exec -it wireguard /app/show-peer myphonelg
```

Trên điện thoại, tải app `Wireguard` về, scan QR code bên trên, đặt tên cho VPN đó, enable nó lên.  

Thử dùng sóng 4G và truy cập `192.168.1.x:8123` (local IP address của HASS) xem sao. Nếu truy cập được là OK.  

Vậy là chỉ cần bật VPN trên điện thoại lên, là bạn đã có thể connect đến HASS như ở nhà rồi 😁  

### 10.2. Restrict peers permission

Tuy nhiên sau khi bật VPN lên, nếu bạn có thể access tất cả các IP local kể cả: `192.168.1.1` (đây là IP của Router, rất quan trọng) thì rất nguy hiểm. Chỉ cần 1 user nào kết nội VPN của bạn, họ có thể truy cập router nhà bạn luôn. 

Việc thay đổi setting về permission trên Docker Compose file là ko thể, mà phải kết hợp các câu lệnh `iptables` của linux mới được.  

Edit file `/opt/wireguard/config/wg0.conf`:
```sh
[Interface]
Address = 10.13.13.1
ListenPort = 51820
PrivateKey = REDACTED
PostUp = /config/mnsd-scripts/postup.sh
PostDown = /config/mnsd-scripts/postdown.sh

[Peer]
# peer_myphonelg
PublicKey = REDACTED
PresharedKey = REDACTED
AllowedIPs = 10.13.13.4/32

[Peer]
# peer_myphonevsm
PublicKey = REDACTED
PresharedKey = REDACTED
AllowedIPs = 10.13.13.5/32
```
-> Như bạn thấy mình đã sửa để file `wg0.conf` call đến 2 file `postup.sh` và `postdown.sh`.

Tạo file sau `/opt/wireguard/config/mnsd-scripts/postup.sh`: 
```sh
WIREGUARD_INTERFACE=wg0
WIREGUARD_LAN=10.13.13.0/24
MASQUERADE_INTERFACE=eth0

iptables -t nat -I POSTROUTING -o $MASQUERADE_INTERFACE -j MASQUERADE -s $WIREGUARD_LAN

# Add a WIREGUARD_wg0 chain to the FORWARD chain
CHAIN_NAME="WIREGUARD_$WIREGUARD_INTERFACE"
iptables -N $CHAIN_NAME
iptables -A FORWARD -j $CHAIN_NAME

# Accept related or established traffic
iptables -A $CHAIN_NAME -o $WIREGUARD_INTERFACE -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT

# 1.Accept traffic from any peers to anywhere
#iptables -A $CHAIN_NAME -s $WIREGUARD_LAN -i $WIREGUARD_INTERFACE -j ACCEPT

# 2.Accept traffic from any peers to HAAS IP only
iptables -A $CHAIN_NAME -s $WIREGUARD_LAN -i $WIREGUARD_INTERFACE -d 192.168.1.8 -j ACCEPT

# 3.Accept traffic from myphonelg 10.13.13.4 to anywhere (both LAN and Internet)
#iptables -A $CHAIN_NAME -s 10.13.13.4 -i $WIREGUARD_INTERFACE -j ACCEPT

# 4.Accept traffic from myphonelg 10.13.13.4 to HAAS IP only
#iptables -A $CHAIN_NAME -s 10.13.13.4 -i $WIREGUARD_INTERFACE -d 192.168.1.8 -j ACCEPT

# 5.Accept traffic from myphonevsm 10.13.13.5 to LAN only
#iptables -A $CHAIN_NAME -s 10.13.13.5 -i $WIREGUARD_INTERFACE -d 192.168.1.0/24 -j ACCEPT

# 6.Accept traffic from myphonevsm 10.13.13.5 to HAAS IP only
#iptables -A $CHAIN_NAME -s 10.13.13.5 -i $WIREGUARD_INTERFACE -d 192.168.1.8 -j ACCEPT

# 7.Accept traffic from myphonevsm 10.13.13.5 to HAAS IP and port 8123 only
#iptables -A $CHAIN_NAME -s 10.13.13.5 -i $WIREGUARD_INTERFACE -d 192.168.1.8 -p tcp --dport 8123 -j ACCEPT

# 8.Limit user myphonevsm to access HTTP/S Web internet only
#iptables -A $CHAIN_NAME -s 10.13.13.5 -i $WIREGUARD_INTERFACE -d 192.168.1.1 -p udp --dport 53 -j ACCEPT
    # below drop traffic from user to any LAN
#iptables -A $CHAIN_NAME -s 10.13.13.5 -i $WIREGUARD_INTERFACE -d 10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 -j DROP
    # accept outgoing connections to HTTP(S) ports to any IP address
#iptables -A $CHAIN_NAME -s 10.13.13.5 -i $WIREGUARD_INTERFACE -d 0.0.0.0/0 -p tcp -m multiport --dports 80,443 -j ACCEPT

# Drop everything else coming through the Wireguard interface
iptables -A $CHAIN_NAME -i $WIREGUARD_INTERFACE -j DROP

# Return to FORWARD chain
iptables -A $CHAIN_NAME -j RETURN
```
-> Như bạn thấy mình tạo sẵn rất nhiều rule (từ 1->8). Bạn dùng cái nào thì uncomment cái đó (có thể kết hợp nhiều cái). Như hiện tại mình chọn cái 2, tất cả traffic của peers sẽ chỉ được accept khi connect đến IP của HASS mà thôi

Tạo file sau `/opt/wireguard/config/mnsd-scripts/postdown.sh`: 
```sh
WIREGUARD_INTERFACE=wg0
WIREGUARD_LAN=10.13.13.0/24
MASQUERADE_INTERFACE=eth0
CHAIN_NAME="WIREGUARD_$WIREGUARD_INTERFACE"

iptables -t nat -D POSTROUTING -o $MASQUERADE_INTERFACE -j MASQUERADE -s $WIREGUARD_LAN

# Remove and delete the WIREGUARD_wg0 chain
iptables -D FORWARD -j $CHAIN_NAME
iptables -F $CHAIN_NAME
iptables -X $CHAIN_NAME
```

Change quyền cho 2 file trong folder scripts (chú ý bước này quan trọng, nếu ko sẽ bị lỗi):
```sh
sudo chmod 777 /opt/wireguard/config/mnsd-scripts/*
```
-> restart `wireguard` container. Check log ko có lỗi là OK.  

Giờ hãy thử test kết nối xem sao nhé. Các peer sẽ ko thể access vào bất cứ đâu - ngoại trừ `192.168.1.8`

### 10.3. Allow traffic from client to 192.168.1.0/24 only, except internet

Nếu bạn muốn Client luôn bật VPN nhưng chỉ có kết nối đến `192.168.1.8` là đi qua VPN, còn các traffic đến `Google, myip.com` thì ko dùng VPN (dù nó đang bật). Bạn cần sửa trên Client app:  
`AllowedIPs = 192.168.1.0/24` là được.
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/wireguard_allowed_ips.jpg)   

Như vậy bạn vẫn có thể bật VPN để đó suốt ngày. Chỉ các traffic đến `192.168.1.0/24` mới qua VPN.

### 10.4. Allow traffic from client to internet only, except local intranet

Nếu bạn muốn Client luôn bật VPN nhưng chỉ các traffic ra Internet `Google, myip.com` là đi qua VPN, còn traffic đến `192.168.1.8` thì đi trong mạng nội bộ của Client. Bạn cần sửa trên Client app:  
Edit và bỏ tick ở ô `Block untunneled traffic (kill switch)`

Như vậy Client có thể bật VPN để đó suốt ngày để đọc Medium chẳng hạn. Khi họ cần truy cập vào 1 website intranet `192.168.1.8` của họ thì họ vẫn vào bình thường.  

### 10.5. Add more peer

Nếu bạn muốn có thêm 1 thiết bị nữa kết nối vào Wireguard, chỉ cần sửa lại file `/opt/hass/docker-compose.yaml`:
từ `PEERS=1` thành `PEERS=2`, hoặc thành `PEERS=myphonelg,myphonevsm`

-> restart `wireguard` container

Nếu restart xong mà ko thấy folder `peer_xxx` trong `wireguard/config/` thì cần stop container wireguard rồi run lại:  

```sh
docker-compose up -d
```

Rồi run command này để show QR code của `peer2`:   
```sh
docker exec -it wireguard /app/show-peer 2
hoặc
docker exec -it wireguard /app/show-peer myphonevsm
```

Trong trường hợp thiết bị của bạn ko thể quét QR code, ví dụ như máy tính, laptop:  
copy content trong file sau: `/opt/devops/wireguard/config/peer_mylaptop/peer_mylaptop.conf`  
```
[Interface]
Address = 10.x.x.9
PrivateKey = qxxxxxxxxxxxxxxxxxxxxxxxxxxxxQ=
ListenPort = 51821
DNS = 10.x.x.9

[Peer]
PublicKey = 7xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=
PresharedKey = yzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz=
Endpoint = x.x.x.x:51821
AllowedIPs = 0.0.0.0/0
```

Chọn WireGuard -> Add empty tunnel -> paste content trên vào màn hình, rồi Save -> OK


## 11. Install Watchman via HACS

Đây là 1 tool giúp generate ra report, giúp bạn biết được có entity nào bị missing trong automation, script hay ko?

từ report đó bạn đi tìm cách fix

vào HACS -> Explore repositories -> Search `Watchman`

vào Setting -> Integrations -> Add `Watchman`

-> restart HASS

đợi 1 lúc cho các entities start hết

vào `Developer tools` -> `Services` -> search `Watchman` -> ấn `Call service`

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-watchman.jpg)

vào `hass/config` sẽ thấy file `watchman_report.txt` xuất hiện:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-watchman-report.jpg)

đọc report rồi điều tra các entities ko cần thiết thôi 😃

## 12. Install Grafana + Prometheus

### 12.1. Install 

Mục đích là để theo dõi RAM, CPU, etc ... của RPi

Chuẩn bị persistent volume:  
```sh
sudo mkdir -p /opt/prometheus-grafana/{grafana,prometheus}

cd /opt/
wget https://raw.githubusercontent.com/grafana/grafana/main/conf/defaults.ini -O prometheus-grafana/grafana/grafana.ini

```

```sh
tee prometheus-grafana/promethueus/prometheus.yml<<EOF
global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s
alerting:
  alertmanagers:
  - static_configs:
    - targets: []
    scheme: http
    timeout: 10s
    api_version: v1
scrape_configs:
- job_name: prometheus
  honor_timestamps: true
  scrape_interval: 15s
  scrape_timeout: 10s
  metrics_path: /metrics
  scheme: http
  static_configs:
  - targets: ['localhost:9090','node-exporter:9100']
EOF
```

```sh
tee prometheus-grafana/grafana/datasource.yml<<EOF
apiVersion: 1
datasources:
- name: Prometheus
  type: prometheus
  url: http://<RPi_local_IP>:9090 
  isDefault: true
  access: proxy
  editable: true
EOF
```

File `docker-compose.yaml`:
```yaml
version: '3.0'

services:

  prometheus:
    image: prom/prometheus:v2.36.0
    container_name: prometheus
    volumes:
      # - /opt/prometheus-grafana/prometheus/prometheus_data:/prometheus
      - /opt/prometheus-grafana/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - 9090:9090
    user: "1000"

  grafana:
    image: grafana/grafana:8.5.5
    container_name: grafana
    volumes:
      - /opt/prometheus-grafana/grafana/grafana_data:/var/lib/grafana
      - /opt/prometheus-grafana/grafana/grafana.ini:/etc/grafana/grafana.ini
      - /opt/prometheus-grafana/grafana/datasource.yml:/etc/grafana/provisioning/datasources/datasource.yaml
    ports:
      - 3000:3000
    links:
      - prometheus
    user: "1000"

  node-exporter:
    image: prom/node-exporter:v1.3.1
    container_name: monitoring_node_exporter
    restart: unless-stopped
    expose:
      - 9100
```

```sh
docker-compose up -d
```
Login Grafana: http://RPi_IP:3000 (admin/admin)

Đổi password  

### 12.2. Import Dashboard

https://easycode.page/monitoring-on-raspberry-pi-with-node-exporter-prometheus-and-grafana/

Add Grafana vào làm 1 iframe cho HASS:  
File `/opt/prometheus-grafana/grafana/grafana.ini`, sửa attribute sau:  
```yaml
allow_embedding = true
```
File `/opt/hass/config/configuration.yaml`:  
```yaml
panel_iframe:
  grafana:
    title: "Grafana"
    url: "http://RPI_IP:3000"
    icon: mdi:chart-areaspline
    require_admin: true
```
-> restart Grafana, restart HASS

Tiếp theo cần làm 1 số rule để Grafana tự động gửi tin nhắn khi nhiệt độ CPU quá cao, hoặc khi full RAM, full disk...

### 12.3. Setup template message

Chủ yếu dựa trên bài này: https://grafana.com/docs/grafana/latest/alerting/unified-alerting/message-templating/  

Giả sử bạn muốn setup khi CPU lên 8% thì sẽ message vào Telegram cho bạn

Vào Dashboard `CPU Basic` chọn `Edit`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/grafana-cpu-basic.jpg)

tab `Alert`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/grafana-cpu-basic-alert-tab.jpg)

Tạo 1 rule tương tự như này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/grafana-cpu-basic-alert-rule1.jpg)
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/grafana-cpu-basic-alert-rule1-setting.jpg)

Chỗ này nghĩa là rule đấy sẽ evaluate 1 phút 1 lần trong vòng 2 phút sau khi thấy CPU > 8%

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/grafana-cpu-basic-alert-rule1-setting-alert.jpg)  
Bạn có thể truyền các label vào Alert tùy ý, ở đây mình thêm label `component=CPU_BUSY`  

-> SAVE

Vào tab Alert -> Contact point, chúng ta sẽ tạo 1 contact point `telegram_contactpoint` và 2 template `myalert` và `telegram_template`

2 message template nội dung như này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/grafana-message-template2.jpg)

myalert:  
```
{{ define "myalert" }}
  [{{.Status}}] {{ .Labels.alertname }}
  Labels:
  {{ range .Labels.SortedPairs }}
    {{ .Name }}: {{ .Value }}
  {{ end }}
{{ end }}
```

telegram_template:  
```
{{ define "telegram_template" }}
  {{ if gt (len .Alerts.Firing) 0 }}
    {{ len .Alerts.Firing }} firing:
    {{ range .Alerts.Firing }} {{ template "myalert" .}} {{ end }}
  {{ end }}
  {{ if gt (len .Alerts.Resolved) 0 }}
    {{ len .Alerts.Resolved }} resolved:
    {{ range .Alerts.Resolved }} {{ template "myalert" .}} {{ end }}
  {{ end }}
{{ end }}
```
 
Vào phần contact point tạo Telegram Contactpoint:   
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/grafana-contact-point-tele.jpg)

Chú ý field Message điền:  
```
Alert summary:
{{ template "telegram_template" . }}
```

Thử Test Contact Point với custom label mình điền là `hahaha`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/grafana-contact-point-test.jpg)

Bạn sẽ nhận được message trên Telegram như này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/grafana-message-test.jpg)

Giờ bạn có thể đã mường tượng được flow của quá trình Alert như thế nào. Hãy thử tự sửa theo ý mình nhé 😁

## 13. Setup cAdvisor

Mình muốn theo dõi chi tiết các container, xem cái nào dùng nhiều CPU nhất, cái nào ngốn nhiều traffic nhất...

Đây là lúc sử dụng cAdvisor

sửa file `docker-compose.yml`:  
```yml
  cadvisor:
    container_name: cadvisor
    # image: gcr.io/cadvisor/cadvisor:v0.47.0 # not ARM supported version
    image: gcr.io/cadvisor/cadvisor-arm64:v0.47.0 # https://github.com/google/cadvisor/issues/3190
    ports:
    - 8081:8080 # Mình expose ra 8081 để tránh duplicate
    volumes:
    - /:/rootfs:ro
    - /var/run:/var/run:ro
    - /sys:/sys:ro
    - /var/lib/docker/:/var/lib/docker:ro
    - /dev/disk/:/dev/disk:ro
    devices:
    - /dev/kmsg
```
Ở đây chú ý rằng mình đang sử dụng version `gcr.io/cadvisor/cadvisor-arm64` vì đây là image dùng cho RasberryPi (chip arm64). Nếu bạn dùng bản ko support chip arm thì khả năng sẽ bị lỗi ở đâu đó.


sửa file `/opt/prometheus-grafana/prometheus/prometheus.yml`: Add thêm `cadvisor:8080` ở dòng cuối cùng
```yml
global:
  scrape_interval: 15s
  scrape_timeout: 10s
  evaluation_interval: 15s
alerting:
  alertmanagers:
  - static_configs:
    - targets: []
    scheme: http
    timeout: 10s
    api_version: v1
scrape_configs:
- job_name: prometheus
  honor_timestamps: true
  scrape_interval: 15s
  scrape_timeout: 10s
  metrics_path: /metrics
  scheme: http
  static_configs:
  - targets: ['localhost:9090','node-exporter:9100','cadvisor:8080']
```

restart container prometheus:  
```sh
docker container restart prometheus
```

Vào đây confirm xem Prometheus đã connect được đến cAdvisor chưa:  
http://RPI_IP:9090/targets?search=  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/cadvisor-prometheus-config-1.jpg)


Mình import template này: https://grafana.com/grafana/dashboards/15120-raspberry-pi-docker-monitoring/

Có thể sẽ bị lỗi cái `Root FS Used` ko hiển thị dung lượng thẻ nhớ đang sử dụng. Lúc đó mình cần sửa lại như sau:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/cadvisor-grafana-edit-root-fs.jpg)

Sửa câu query như sau:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/cadvisor-grafana-edit-root-fs-query.jpg)

Nội dung câu query mình paste ra đây:  
```
100 - ((node_filesystem_avail_bytes{device="/dev/root", fstype="ext4", instance="node-exporter:9100", job="prometheus", mountpoint="/etc/hostname"} * 100) / node_filesystem_size_bytes{device="/dev/root", fstype="ext4", instance="node-exporter:9100", job="prometheus", mountpoint="/etc/hostname"})
```
Sau đó thì sẽ lấy được thông tin `Root FS Used` như trên hình là khoảng 75%

Kéo xuống dưới sẽ thấy được max CPU của từng container, rồi traffic của từng container, bla bla... cần theo dõi cái nào thì đặt Alert cho cái ý thôi


## 14. Setup Nmap Tracker

Để xác định 1 `person` có đang ở nhà ko thì có nhiều cách. Tuy nhiên phần này mình sẽ dùng `Nmap Tracker` để xác định.

Cơ chế hoạt động của nó là, RPi sẽ run command `nmap` để xem có bao nhiêu device đang kết nối vào wifi của nhà mình. Mỗi device sẽ là 1 entity. 

Từ đó xác định 1 person có đang ở nhà hay ko bằng cách xem device của họ có đang connect WIFI hay ko.

Tuy nhiên nên cẩn thận vì 1 số thiết bị ở chế độ idle sẽ tự ngắt kết nối WiFi. Và có 1 số thiết bị dù đang kết nối đến WiFi nhưng lại ko được nmap phát hiện ra. 

Chú ý hãy cài sẵn `nmap` command trên RPi nhé.  

Vào Setting -> Integrations -> Add Integration, search `Nmap Tracker`:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/rpi-new-integration-nmap.jpg)

điền các thông tin về subnet ip, ip của nơi sẽ run command `nmap`, thường thì cứ để default:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/rpi-nmap-tracker-config.jpg)

sau khi Submit thì restart HASS.  

Bạn sẽ thấy màn hình Integrations có Nmap Tracker xuất hiện với 1 số entities đó chính là devices đang kết nối:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/rpi-nmap-tracker-dashboard.jpg)

Tại màn hình sau, hãy sửa các entty để đổi tên cho dễ nhìn, enable chúng lên, sao cho STATUS như khung đỏ là ok:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/rpi-nmap-tracker-entities-list.jpg)

Sau đó quay lại Setting -> People, chọn Person mà bạn muốn track device, select device to track:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/rpi-nmap-tracker-peson-config.jpg)

Quay lại Setting -> Developer Tool, search `person` bạn sẽ thấy người đó đang có state=home, vì device của họ đang kết nối wifi:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/rpi-person-with-device-tracker.jpg)

Giờ bạn có thể đưa entity person đó ra ngoài dashboard để theo dõi xem họ có nhà hay ko 😋

Chú ý rằng nếu bạn có 1 chiếc Iphone đang kết nối vào mạng, để xác định đâu là địa chỉ MAC của Iphone trong list kết quả của `Nmap Tracker`, bạn cần vào Setting của Iphone phần này: 

Setting -> Wifi -> click vào biểu tượng chữ i (info) bên cạnh WiFi bạn đang kết nối.

✔ Phần địa chỉ Wifi address chính là MAC address của iphone trong mạng của bạn

❌ Nhiều người check địa chỉ MAC của Iphone mà vào `General -> About -> WiFi address` là sai nhé ❌, sẽ không khớp với kết quả trả về của `Nmap Tracker` đâu


## 15. About setting up Automations

### 15.1. Note 1

Khi setup Automations, bạn nên biết cách nhúng scripts vào Automation thì sẽ làm được nhiều thứ hơn.

Giả sử mình đang có 1 Automation như này:  
`/opt/hass/config/automations.yaml`:  
```yml
# Turn On/Off Small room Wall Light/ Bulb base on motion
- id: '9hoangmnsd7234756123978961235'
  alias: Turn On/Off Small room Wall Light/Bulb base on motion
  description: Turn On/Off Small room Wall Light/Bulb base on motion
  trigger:
  - entity_id: binary_sensor.motion_sensor_04_occupancy
    platform: state
    to: 'on'
  - entity_id: binary_sensor.motion_sensor_04_occupancy
    platform: state
    to: 'off'
    for: 00:05:00 # delay for x min after changing state
  # Only active between 9AM to 11PM
  condition:
    alias: "Time 09~23"
    condition: time
    # At least one of the following is required.
    after: "09:00:00"
    before: "23:00:00"
    weekday:
      - mon
      - tue
      - wed
      - thu
      - fri
      - sat
      - sun
  action:
  - data: {}
    entity_id: light.small_room_light_bulb
    service_template: >
      {% if is_state('binary_sensor.motion_sensor_04_occupancy', 'on') %}
      light.turn_on
      {% else %}
      light.turn_off
      {% endif %}
  - data: {}
    entity_id: switch.small_room_wall_light
    service_template: >
      {% if is_state('binary_sensor.motion_sensor_04_occupancy', 'on') %}
      switch.turn_on
      {% else %}
      switch.turn_off
      {% endif %}
```
Nó turn on 2 cái đèn khi motion detected.  
Và turn off 2 cái đèn khi motion cleared trong 5 phút.  

Nhưng giờ mình muốn: Nếu sau 5 phút motion cleared thì chỉ `turn_off` 1 đèn, rồi delay 10s, rồi mới `turn_off` đèn 2.

Nếu sửa thêm delay 10s vào giữa 2 `action` thì sẽ ảnh hưởng đến lúc `turn_on` cũng sẽ phải delay. Mà bản thân hàm delay thì ko thể có condition.

Thế nên mình cần nhúng script vào automations như sau:  
`/opt/hass/config/automations.yaml`:  
```yml
# Turn On/Off Small room Wall Light/ Bulb base on motion
- id: '9817hoangmnsd8324378098546'
  alias: Turn On/Off Small room Wall Light/Bulb base on motion
  description: Turn On/Off Small room Wall Light/Bulb base on motion
  mode: parallel
  trigger:
  - entity_id: binary_sensor.motion_sensor_04_occupancy
    platform: state
    to: 'on'
  - entity_id: binary_sensor.motion_sensor_04_occupancy
    platform: state
    to: 'off'
    for: 00:05:00 # delay for x min after changing state
  # Only active between 9AM to 11PM
  condition:
    alias: "Time 09~23"
    condition: time
    # At least one of the following is required.
    after: "09:00:00"
    before: "23:00:00"
    weekday:
      - mon
      - tue
      - wed
      - thu
      - fri
      - sat
      - sun
  action:
  - data: {}
    service_template: "script.light_bulb_{{trigger.to_state.state}}"

```
`/opt/hass/config/scripts.yaml`:  
```yml
light_bulb_on:
  sequence:
  - service: script.turn_off
    data:
      entity_id: script.light_bulb_off
  - service: light.turn_on
    entity_id: light.small_room_light_bulb
  - service: switch.turn_on
    entity_id: switch.small_room_wall_light

light_bulb_off:
  sequence:
  - service: light.turn_off
    entity_id: light.small_room_light_bulb
  - delay: '00:00:10'
  - service: switch.turn_off
    entity_id: switch.small_room_wall_light
```

Chú ý là cần để `mode: parallel` để khi trong khoảng chờ 10s sau khi motion cleared, nếu motion detected thì nó sẽ cancel cái `script.light_bulb_off` đang chạy

Đây là 1 phương pháp rất hay vì việc đưa ra script sẽ đem lại cho chúng ta nhiều đất diễn hơn.  

### 15.2. Note 2

Cách liên kết giữa input_boolean state với script: 

Phần này sẽ hướng dẫn tạo 1 button `leg_mode` trên giao diện, từ button đó call đến script để flash đèn bàn theo nhu cầu

file `/opt/hass/config/configuration.yaml`:  
```yml
input_boolean:
  leg_mode:
    name: Leg mode
    icon: mdi:shoe-print
    initial: false
```

giao diện UI:  
```yml
  - type: horizontal-stack
    cards:
    - type: 'custom:button-card'
      template: card_input_boolean
      entity: input_boolean.leg_mode
```

Automation `/opt/hass/config/automations.yaml` (có thể bạn nghĩ ko cần file này, nhưng thực chất phải có để call đến script. Nếu ko thì script sẽ ko biết được trigger khi nào):
```yml
# Turn On/Off Small room Bulb base on Leg Mode input_boolean
- id: '6hoangmnsd3052389573534892y34'
  alias: Turn On/Off Leg Mode input_boolean
  description: Turn On/Off Leg Mode input_boolean
  mode: parallel
  trigger:
  - entity_id: input_boolean.leg_mode
    platform: state
    to: 'on'
  - entity_id: input_boolean.leg_mode
    platform: state
    to: 'off'
  condition: []
  action:
  - data: {}
    service_template: "script.light_bulb_leg_mode_{{trigger.to_state.state}}"
```

file `/opt/hass/config/scripts.yaml`:  
```yml
# Smallroom Desk Lightbulb Leg mode
light_bulb_leg_mode_child:
  mode: restart
  sequence:
  - service: light.turn_on
    target:
      entity_id: light.small_room_light_bulb
  - alias: "Cycle light"
    repeat:
      while:
      - condition: state
        entity_id: input_boolean.leg_mode
        state: 'on'
      # Don't do it too many times: 3600s / 15s = 240
      - condition: template
        value_template: "{{ repeat.index <= 240 }}"
      sequence:
      - service: light.turn_on
        data:
          brightness_pct: 100
          rgb_color: [124,252,0] # lawngreen
        entity_id: light.small_room_light_bulb
      - delay: '00:00:05'
      - service: light.turn_on
        data:
          brightness_pct: 100
          rgb_color: [255,0,0] # red
        entity_id: light.small_room_light_bulb
      - delay: '00:00:10'

light_bulb_leg_mode_on:
  sequence:
  - condition: state
    entity_id: input_boolean.leg_mode
    state: 'on'
  - service: script.turn_off
    data:
      entity_id: script.light_bulb_leg_mode_off
  - alias: "Call the child script"
    service: script.light_bulb_leg_mode_child

light_bulb_leg_mode_off:
  sequence:
  - condition: state
    entity_id: input_boolean.leg_mode
    state: 'off'
  - service: script.turn_off
    data:
      entity_id: script.light_bulb_leg_mode_on
  - service: light.turn_on # revert to normal brightness
    data:
      brightness_pct: 100
      color_temp: 350
    entity_id: light.small_room_light_bulb
  - service: light.turn_off
    entity_id: light.small_room_light_bulb
```
Như vậy mỗi khi mình turn on/off button `Leg mode` trên giao diện, nó sẽ trigger Automation từ đó call đến script bên dưới.  
Việc nắm đc cách liên kết giữa các thành phần automation, UI card input_boolean, script giúp bạn hiện thực hóa được nhiều ý tưởng hơn.  

### 15.3. Note 3

Dynamic even the title text. Note này nói về cách mình làm cho title của glance card trở nên dynamic, nó sẽ thay đổi tùy theo trạng thái mà mình ấn nút:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/dynamic-title-text.jpg)  
Ví dụ khi mình ấn vào cái 29 độ C, thì đoạn text "LG Air Conditioner" sẽ chuyển thành "LG Air Conditioner(29)".  
Điều này là không thể đối với các default card. Vì thế bạn cần import 1 loại custom card mới

vào HACS -> tìm card này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hacs-config-template-card.jpg)  

download nó về:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hacs-config-template-card-dl.jpg)  

trong file `/opt/hass/config/configuration.yaml` cần thêm config sau:  
```yml
# You need to specifiy resource url if setting lovelace.mode = yaml
lovelace:
  mode: yaml
  resources:
    - url: /hacsfiles/config-template-card/config-template-card.js
      type: module
```
vẫn trong file đó, define 1 `input_select`:  
```yml
input_select:
  living_room_ac_title_base_on_temp:
    name: living_room_ac_title_base_on_temp
    options:
      - LG Air Conditioner
      - LG Air Conditioner(29)
      - LG Air Conditioner(28)
    initial: LG Air Conditioner
```

-> restart HASS

trên UI dashboard bạn cần sửa glance card, để sử dụng dc cái `config-template-card` mà mới download về:

```yml
  - type: 'custom:config-template-card'
    variables:
      AC_LIVINGROOM_TITLE: states['input_select.living_room_ac_title_base_on_temp'].state
    entities:
      - script.ac_livingroom_power
      - script.ac_livingroom_jetmode
      - script.ac_livingroom_temp29
      - script.ac_livingroom_temp28
    card:
      type: glance
      title: "${AC_LIVINGROOM_TITLE}"
      style: |
        ha-card { 
          background-color: {{ '#AAFFAA' if is_state('binary_sensor.living_room_ac_sensor_contact', 'on') else '#FFFFFF' }};
        }
      entities:
        - entity: script.ac_livingroom_power
          name: Power
          show_state: false
          show_icon: true
          icon: mdi:power
          tap_action:
            action: call-service
            service: script.ac_livingroom_power
            data:
              entity_id: script.ac_livingroom_power
        - entity: script.ac_livingroom_jetmode
          name: JetMode
          show_state: false
          show_icon: true
          icon: mdi:snowflake
          tap_action:
            action: call-service
            service: script.ac_livingroom_jetmode
            data:
              entity_id: script.ac_livingroom_jetmode
        - entity: script.ac_livingroom_temp29
          name: 29°C
          show_state: false
          show_icon: true
          icon: mdi:temperature-celsius
          tap_action:
            action: call-service
            service: script.ac_livingroom_temp29
            data:
              entity_id: script.ac_livingroom_temp29
```

trong `/opt/hass/config/scripts.yaml` bạn cần add thêm action để nó thay đổi option cho `input_select`:
```yml
ac_livingroom_temp29:
  sequence:
  - service: remote.send_command
    data:
      command: temp29
      device: ac_livingroom
    target:
      entity_id: remote.rm4_mini_livingroom_remote
  - service: input_select.select_option 
    data:
      entity_id: input_select.living_room_ac_title_base_on_temp
      option: 'LG Air Conditioner(29)'
```
-> restart HASS

Về cơ bản, bạn đã dùng `input_select` để thay đổi giá trị của title. Điều này nhờ công rất lớn của `custom:config-template-card`.  

## 16. Setup Navidrome

Đây là 1 web app để chia sẻ nhạc từ máy mình ra internet. Có thể share cho mọi người nghe cùng:  
https://github.com/navidrome/navidrome/  
https://www.navidrome.org/docs/installation/docker/  
https://www.navidrome.org/docs/usage/configuration-options/#configuration-file  


Chuẩn bị folder:  
- `/opt/navidrome/data` để chứa config  
- `/opt/navidrome/music` để chứa các file mp3

add vào `docker-compose.yml`
```yml
  navidrome:
    container_name: navidrome
    image: deluan/navidrome:0.47.5
    user: 1000:1000 # should be owner of volumes
    ports:
      - "4533:4533"
    restart: unless-stopped
    environment:
      # Optional: put your config options customization here. Examples:
      ND_SCANSCHEDULE: 1h
      ND_LOGLEVEL: info  
      ND_SESSIONTIMEOUT: 24h
      ND_BASEURL: "/"
      ND_REVERSEPROXYWHITELIST: "192.168.1.0/24,172.18.0.0/16" # mặc dù đưa vào nhưng chưa hiểu cách dùng
    volumes:
      - "/opt/navidrome/data:/data"
      - "/opt/navidrome/music:/music:ro"
```

Vậy là xong, bạn có thể access vào port 4533 để xem trang web hoạt động.

Mình đang dùng `swag` để expose trang navidrome này ra ngoài internet dưới domain `https://navidrome.MYDOMAIN.duckdns.org`. Như vậy là ở Công ty cũng có thể nghe được list nhạc ở nhà rồi 😁😁

Hiện tại có 1 vấn đề:  
- Mình vẫn chưa nhúng dc trang này vào làm 1 iframe của HASS, nó cứ báo lỗi từ chối kết nối  
-> thế nên từ mạng LAN muốn vào là phải vào theo local IP: `192.168.x.x:4533`  
vấn đề này được thảo luận trong topic này: https://github.com/navidrome/navidrome/issues/248#issuecomment-911143096

Tóm tắt để xử lý vấn đề iframe thì cần phải sử dụng nginx để ghi đè lên cái setting `X-Frame-Options: deny` của Navidrome

Để làm được thì mình đã phải setup Nginx theo bài [Setup Home Assistant on Raspberry Pi (Part 3) - Https](../../posts/encrypt-setup-home-assistant-on-raspberry-pi-p3-https)

Sau khi có nginx rồi thì:  
Trong folder `/opt/swag/config/nginx/proxy-confs/` rename file `navidrome.subdomain.conf.sample` -> `navidrome.subdomain.conf`
Trong file này sửa nội dung như sau:  
```
~~~
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

    server_name navidrome.*;

    include /config/nginx/ssl.conf;

    client_max_body_size 0;

    location / {
        include /config/nginx/proxy.conf;
        include /config/nginx/resolver.conf;
        set $upstream_app navidrome;
        set $upstream_port 4533;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;
        
        proxy_hide_header X-Frame-Options;

    }
}
```
-> như vậy mình đã set cho nginx ko redirect http sang https, và listen trên cả port 80.  
server name của Navidrome sẽ là `navidrome.MYDOMAIN.duckdns.org`.  
Mình cũng đã thêm `proxy_hide_header X-Frame-Options;` để ghi đè lên setting `X-Frame-Options` của Navidrome

Bây giờ từ Internet có thể access vào cả 2 link này đều ok:  
- https://navidrome.MYDOMAIN.duckdns.org  
- http://navidrome.MYDOMAIN.duckdns.org  

Giờ setting trong HASS file `/opt/hass/config/configuration.yaml`:  
```yml
# panel iframe
panel_iframe:
...
  navidrome:
    title: "Navidrome"
    url: "http://navidrome.MYDOMAIN.duckdns.org"
    icon: mdi:music
    require_admin: false
```

-> restart `swag` container, HASS

Test:  
- Từ Mạng 4G -> HASS http `http://MYDOMAIN.duckdns.org` -> tự redirect https, vào dc HASS -> ko mở đc iframe Navidrome.  
- Từ Mạng 4G -> HASS http `http://MYDOMAIN.duckdns.org:8123` -> vào dc HASS, mở đc iframe Navidrome.  
- Từ mạng LAN -> HASS http `http://MYDOMAIN.duckdns.org:8123`-> vào dc HASS, mở đc iframe Navidrome.  
- Từ mạng 4G -> `http://navidrome.MYDOMAIN.duckdns.org` -> vào đc Navidrome.  
- Từ mạng 4G -> `https://navidrome.MYDOMAIN.duckdns.org` -> vào đc Navidrome.  

## 17. Troubleshoot docker overlay

https://forums.docker.com/t/some-way-to-clean-up-identify-contents-of-var-lib-docker-overlay/30604/59

Nếu bạn thấy dùng lượng trong `/var/lib/docker/overlay2/` nhiều 1 cách bất thường, có 1 vài step nên kiểm tra:  
Xem tổng cộng file log có nhiều ko?
```sh
du -shc /var/lib/docker/containers/*/*.log
```
Xem số lượng file trong folder `diff`:  
```sh
du -shc /var/lib/docker/overlay2/*/diff
```
Sort các file theo thứ tự dung lượng giảm dần:  
```sh
du -s /var/lib/docker/overlay2/*/diff |sort -n -r 
```
Xem folder to nhất được dùng cho container nào:  
```sh
docker inspect $(docker container ls -q) |grep 'FOLDER_ID_HERE' -B 100 -A 100
```

Sau đó bạn có thể lựa chọn xóa container đó rồi run lại xem sao.  
Hoặc giới hạn lại dung lượng logging của container đó rồi run lại.  

1 số cách khác:  
```sh
# Xóa WARNING! This will remove:
#  - all stopped containers
#  - all networks not used by at least one container
#  - all dangling images
#  - all dangling build cache
docker system prune
```

Xác định về folder nào đang size to nhất, ví dụ sau đây folder to nhất là `/volumes` 30G:
```sh
/var/lib/docker# sudo du -h --max-depth=1
325M    ./buildkit
4.0K    ./runtimes
8.0K    ./tmp
4.0K    ./swarm
100K    ./network
92K     ./containers
4.3M    ./image
1.9G    ./overlay2
16K     ./plugins
30G     ./volumes
4.0K    ./trust
33G     .
```

Xóa các volume thừa đi:  
```sh
docker volume prune
WARNING! This will remove all local volumes not used by at least one container.
Are you sure you want to continue? [y/N] y
...
Total reclaimed space: 22.61GB
```

## 18. Setup HASS.Agent on Windows machine

Tình huống là: Mình có 1 Laptop đang sử dụng Smart Plug. Mình muốn nếu pin dc sạc đầy trên 99% sẽ tự ngắt Plug, và nếu pin dưới 10% thì tự bật plug.  

Để làm điều này thì Laptop của bạn cần gửi thông tin cho HASS.-> Bạn cần cài [HASS.Agent](https://community.home-assistant.io/t/hass-agent-windows-client-to-receive-notifications-use-commands-sensors-quick-actions-and-more/369094) trên Windows.

Sau khi download và install xong (mình cài version 2022.13.0)

Setup URL của HASS, và Long-live token:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass.agent-setup-url.jpg)

Setup connect đến MQTT server, chỗ này cần nhập user/password của MQTT server nhé:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass.agent-setup-mqtt.jpg)

Sau đó chờ HASS.Agent restart để setup, rồi vào dashboard -> chọn `Local Sensors` để add sensor vào:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass.agent-setup-local-sensor-1.jpg)

Add new:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass.agent-setup-local-sensor-2-addnew.jpg)

Chọn Battery -> ấn Store Sensor:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass.agent-setup-local-sensor-3-battery.jpg)

Ấn tiếp `Store and Active sensor`

XOng rồi, quay lại HASS -> Setting -> Devices, sẽ thấy Laptop hiện ra và các battery sensor tương ứng

Giờ bạn có thể viết Automation cho các sensor đó, hiện tại mình đang dùng cái này:  
```yml
- id: '2hoangmnsd3sadsdsdsfd4132123f'
  alias: Turn On/Off Laptop PLug base on Battery
  description: Turn On/Off Laptop PLug base on Battery
  trigger:
    # platform: time_pattern
    # minutes: '/1' # every 1 minute
  - below: '10'
    entity_id: sensor.asusk501lb_battery_charge_remaining_percentage
    platform: numeric_state
  - above: '99'
    entity_id: sensor.asusk501lb_battery_charge_remaining_percentage
    platform: numeric_state
  condition:  []
  action:
  - data: {}
    entity_id: switch.smart_plug_01
    service_template: >
      {% set p = states('sensor.asusk501lb_battery_charge_remaining_percentage') | int(0) %}
      {% if p >= 99 %}
      switch.turn_off
      {% elif p <= 10 %}
      switch.turn_on
      {% endif %}
```

## 19. Setup NFC Tag

Xem 1 số clip youtube thấy dc 1 số tình năng hữu dụng của NFC Tag trong nhà mình:  

- Đôi khi ngồi ăn cơm, mình ko muốn cứ nói "Alexa, stop", "Alexa, play news", "Alexa music" mãi. 

- Hoặc trong phòng ngủ, mình ko muốn phải gào lên "Alexa, turn off Bedroom Light" (Alexa đặt ngoài phòng khách, mình chưa có tiền mua thêm Alexa trong phòng ngủ 😆). 

Thế nên, Mình muốn có 1 NFC Tag dán trên mặt bàn/đầu giường, mình quơ điện thoại là nó sẽ tự ra lệnh luôn thay mình luôn (Androids vẫn phải unlock điện thoại trước, Iphone ko cần unlock nhưng phải sáng màn hình), ko cần gào lên, ko cần mở app trên điện thoại rồi tìm đến button ấn nút nữa.

Và bởi vì trong nhà mình có nhiều loại điện thoại nên cũng cần setup riêng cho từng loại.  

Iphone thì cần kết hợp với app `Shortcut` (chỉ hỗ trợ NFC Tag từ iphone X trở đi)

Androids thì ko phải điện thoại nào cũng có chip NFC, ví dụ Vsnart Live 4 ko có NFC thì ko scan được.

Việc setup thì chủ yếu nhờ video này là đủ:  
https://www.youtube.com/watch?v=VsjTzm2JFJ0&t=374s&ab_channel=JuanMTech

Tóm tắt nếu ko muốn xem lại Video trên:  

Đầu tiên là lên Shoppee mua 1 lố NFC tag về, giá khá rẻ thôi, loại nào cũng được vì HA App tương thích với mọi loại NFC Tag (mình cũng chưa research để biết nên dùng loại NFC tag nào)

Sau khi đã có Tag. Cài Home Assistant App trên điện thoại.

Vào phần Setting -> Tags -> Add Tag -> Đặt tên cho Tag

Quơ điện thoại trên Cái Tag mới, nó sẽ ghi đè auto-gen ID mới cho Tag

Xong phần điện thoại, giờ vào làm trên máy tính, tạo Automation cho Tag đó (Chú ý copy cái ID của Tag trước)

Ví dụ Automation cho việc scan Tag của mình:  
```yml
# Control Bedroom Light base on NFC Tag
- id: 'handle-tag-scan-bedroom-light1'
  alias: "Handle Tag Scan: Bedroom Light 1"
  mode: single
  # Hide warnings when triggered while in delay.
  max_exceeded: silent
  trigger:
  - platform: tag
    tag_id: 84df4xxxxxxxxxxxxxxxxxxxxx15f01785
  condition: []
  action:
  - service: switch.toggle
    data: {}
    target:
      entity_id: switch.bed_room_light
```

Reload lại Automation. Test bằng cách Quơ điện thoại trên Tag. Bước này Điện thoại Androids cần unlock trước.

Điện thoại Iphone sẽ cần unlock và chạm vào cái notification pop-up ra. -> hơi phiền.

Giờ fix cái **hơi phiền** của Iphone đó:

- Trên Iphone tìm app `Shortcut` chọn Automation -> NFC -> Scan -> Name the Tag -> Click Next on top right

- Add action -> search Home Assistant App -> select HA fire event -> change `shortcut_event` to anything (ko có space), ví dụ change thành `BedroomLightTag1` -> Next

- Uncheck `Ask before running` -> Uncheck `Notify when run`

- Sửa Automation trên Home Assistant, add thêm trigger `platform: event` như này, chú ý `event_type` chọn đúng cái đã đặt tên `BedroomLightTag1` trong App Shortcut:  

```yml
# Control Bedroom Light base on NFC Tag
- id: 'handle-tag-scan-bedroom-light1'
  alias: "Handle Tag Scan: Bedroom Light 1"
  mode: single
  # Hide warnings when triggered while in delay.
  max_exceeded: silent
  trigger:
  - platform: tag
    tag_id: 84xxxxxxxxxxxxxxxxxxxxx85
  - platform: event
    event_type: BedroomLightTag1
  condition: []
  action:
  - service: switch.toggle
    data: {}
    target:
      entity_id: switch.bed_room_light
```

- Reload Automation trên Home Assistant

- Test lại, ko cần unlock Iphone, nhưng cần chạm màn hình sáng, Quơ Iphone trên Tag -> Done 😘

- Điện thoại nào cũng phải làm (Tuy nhiên ko phải Iphone nào app Shortcut cũng có option NFC đâu)


**Troubeshooting**:  

Đôi khi có lỗi là scan NFC Tag xong Automation ko chạy, có thể là do mình vừa sửa Automation liên quan đến việc Scan NFC:  
https://community.home-assistant.io/t/trouble-using-nfc-tags-ha-says-never-scanned/438377  

-> Vào App xóa cache, data đi, kết nối lại với server HA và login lại là OK


## Review

Quá trình sử dụng 1,2 tuần mình gặp 1 số lỗi:  
- Cửa đóng nhưng hệ thống vẫn báo là đang mở.  
- Ko còn chuyển động nhưng sensor vẫn ở trạng thái Detected motion trong vòng 15p. 

Mình nghĩ là do qos của MQTT server đang set là qos=0. Mình đã config lại MQTT server qos=2. Chờ thêm khoảng 1.2 tuần nữa xem có ok ko…

Sau khoảng 1 tuần dùng, thì có 1 lỗi như này: 
- Motion sensor vẫn ở trạng thái Detected motion trong vòng 2 tiếng, mặc dù ko có chuyển động nào, sau 2 tiếng thì nó mới chuyển về trạng thái Cleared.

Nói chung là qos=2 thì chắc chắn là message sẽ đến dc MQTT server nhưng bao lâu mới đến thì ko biết (ở đây là 2 tiếng mới đến) 😂

- 1 lỗi nữa là Motion ko phát hiện được chuyển động. Rồi 1 lúc sau thì lại phát hiện chuyển động bình thường. Lỗi này đôi khi xảy ra. 

## CREDIT

https://www.jfrog.com/connect/post/install-docker-compose-on-raspberry-pi/  
https://www.zigbee2mqtt.io/guide/getting-started/#installation  
https://www.youtube.com/watch?v=cZV2OOXLtEI&ab_channel=HomeAutomationGuy  
https://www.home-assistant.io/installation/raspberrypi#install-home-assistant-container  
https://www.jfrog.com/connect/post/install-docker-compose-on-raspberry-pi/  
https://peyanski.com/how-to-install-home-assistant-community-store-hacs/#Initial_install_of_Home_Assistant_Community_Store_HACS_on_Home_Assistant_Container  
https://konnected.vn/home-assistant/home-assistant-thong-bao-den-dien-thoai-may-tinh-2020-05-11  
https://www.home-assistant.io/integrations/telegram/  
https://hub.docker.com/r/linuxserver/duplicati  
https://community.home-assistant.io/t/automation-based-on-log/337925/6?u=super318  
https://hub.docker.com/r/linuxserver/duckdns  
https://konnected.vn/home-assistant/home-assistant-truy-cap-bang-domain-va-cai-dat-chung-chi-https-2020-05-18  
https://www.addictedtotech.net/home-vpn-using-wireguard-docker-on-a-raspberry-pi-4/  
https://hub.docker.com/r/linuxserver/wireguard  
https://viblo.asia/p/docker-dung-vpn-server-wireguard-tren-docker-Qbq5QBOmKD8  
https://github.com/linuxserver/docker-wireguard  
https://www.youtube.com/watch?v=aGIg6N9HzSg  
https://gist.github.com/qdm12/4e0e4f9d1a34db9cf63ebb0997827d0d  
https://www.youtube.com/watch?v=XKD5vBZLKgE  
https://techviewleo.com/run-prometheus-and-grafana-using-docker-compose/  
https://easycode.page/monitoring-on-raspberry-pi-with-node-exporter-prometheus-and-grafana/  
https://grafana.com/grafana/dashboards/1860  
https://geektechstuff.com/2020/06/25/grafana-prometheus-and-node-exporter-on-raspberry-pi-via-ansible-raspberry-pi-and-linux/  
https://www.home-assistant.io/integrations/person/  
https://www.home-assistant.io/integrations/nmap_tracker/  
https://www.home-assistant.io/integrations/input_boolean/  
https://www.home-assistant.io/docs/scripts/#counted-repeat  
https://community.home-assistant.io/t/is-it-possible-to-use-dynamic-name-in-e-g-sensor-card/298677  
https://community.home-assistant.io/t/100-templatable-lovelace-configurations/105241  
https://github.com/iantrich/config-template-card  
https://www.home-assistant.io/integrations/input_select/  
https://community.home-assistant.io/t/hass-agent-windows-client-to-receive-notifications-use-commands-sensors-quick-actions-and-more/369094  
https://community.home-assistant.io/t/charge-my-android-tablet-automatically-when-battery-goes-less-than-10-stop-charging-when-100/61296/6  
https://www.youtube.com/watch?v=B4SnJPVbSXc&t=432s&ab_channel=EverythingSmartHome  
https://github.com/LAB02-Research/HASS.Agent  
https://superuser.com/a/1612473  
https://github.com/oijkn/Docker-Raspberry-PI-Monitoring  
https://thesmarthomejourney.com/2022/07/25/monitoring-smarthome-prometheus/  