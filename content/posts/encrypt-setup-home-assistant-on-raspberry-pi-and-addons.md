---
title: "Setup Home Assistant on Raspberry Pi (Part 1) - Addons"
date: 2022-05-01T14:20:21+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [RaspberryPi,HomeAssistant,Docker-compose,DDOS,Iptables]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Bài này tổng hợp các step gần như từ đầu đến cuối để setup Hệ thống Home Assistant Container trên Raspberry Pi"
---

Bài này tổng hợp các step gần như từ đầu đến cuối để setup Hệ thống Home Assistant Container trên Raspberry Pi

trước khi install:  

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
wget -O - https://install.hacs.xyz | bash -
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

### Troubleshoot 2024.01.12

Muốn upgrade các integration trong HACS nhưng khi ấn thì nó cứ xoay không có thay đổi gì.

đọc log thì thấy lỗi: 

```
2024-01-12 22:33:57.256 ERROR (MainThread) [custom_components.hacs] No RepositoryFile.MAINIFEST_JSON file found 'custom_components/ui_lovelace_minimalist/RepositoryFile.MAINIFEST_JSON'
```

=> Cần reinstall lại HACS:

```
# vào container:
docker exec -it homeassistant bash
# run shell
wget -O - https://install.hacs.xyz | bash -
```

Nếu ko thấy command trên nhanh xong bị lỗi timeout thì download shell script từ https://install.hacs.xyz về

rồi vào container run shell đó.

Restart HASS.

Sau đó sẽ update được các integration.

Nếu check lỗi thấy lỗi này khi update các HACS integration:

```
Cannot connect to host api.github.com:443 ssl:None [Try again]
```

thì check xem homeassistant có connect được ra internet ko? 

Nếu ko thì RPi có connect được ra internet ko?

Trường hợp của mình: RPi connect được ra internet nhưng container `homeassistant` thì ko. Nên cần sửa dns của container `homeassistant`

bên trong container `cat /etc/resolv.conf` ra. Sẽ thấy sự khác biệt giữa RPi host và container. Sửa docker-compose.yml lại:

```yml
  homeassistant:
    container_name: homeassistant
    dns:
      - 8.8.8.8
      - 192.168.1.128
```

rồi `docker-compose up -d` là ok.

### Troubleshoot 2025.01.13

Sau 1 hôm mất điện, Hass bật lên thấy lỗi UI trên điện thoại `Custom element doesn’t exist: button-card`

Điều tra thì các chức năng của Hass như tự động bật tắt vẫn works chỉ có trên điện thoại Dashboard Minimalist là bị lỗi (trên PC vẫn OK)

Check log thì ra lỗi của HACS:

```s
2025-01-13 20:51:55.330 CRITICAL (MainThread) [custom_components.hacs] <HacsData restore> [The repo id for music-assistant/hass-music-assistant is already set to 476357279] Restore Failed!
Traceback (most recent call last):
  File "/config/custom_components/hacs/utils/data.py", line 241, in restore
    self.async_restore_repository(entry, repo_data)
  File "/config/custom_components/hacs/utils/data.py", line 282, in async_restore_repository
    self.hacs.repositories.set_repository_id(repository, entry)
  File "/config/custom_components/hacs/base.py", line 283, in set_repository_id
    raise ValueError(
ValueError: The repo id for music-assistant/hass-music-assistant is already set to 476357279
2025-01-13 20:51:55.335 ERROR (MainThread) [custom_components.hacs] HACS is disabled - restore
```

Dù đã thử vài cách ở [đây](https://github.com/hacs/integration/issues/4314#issuecomment-2571551650) ko ăn thua phải reinstall HACS lại:

```s
$ docker exec -it homeassistant /bin/bash
raspberrypi:/config# wget -O - https://install.hacs.xyz | bash -
Connecting to install.hacs.xyz (172.67.68.101:443)
Connecting to raw.githubusercontent.com (185.199.109.133:443)
writing to stdout
-                    100% |***********************************************************************************************|  4990  0:00:00 ETA
written to stdout
INFO: Trying to find the correct directory...
INFO: Found Home Assistant configuration directory at '/config'
INFO: Changing to the custom_components directory...
INFO: Downloading HACS
Connecting to github.com (20.205.243.166:443)
Connecting to github.com (20.205.243.166:443)
Connecting to objects.githubusercontent.com (185.199.108.133:443)
saving to 'hacs.zip'
hacs.zip             100% |***********************************************************************************************| 16.0M  0:00:00 ETA
'hacs.zip' saved
WARN: HACS directory already exist, cleaning up...
INFO: Creating HACS directory...
INFO: Unpacking HACS...

INFO: Verifying versions
INFO: Current version is 2024.1.2, minimum version is 2024.4.1
ERROR: Version 2024.1.2 is not new enough, needs at least 2024.4.1
```

Báo lỗi, cần phải upgrade cả HASS lên 2024.4.1:

```s
raspberrypi:/config# wget -O - https://install.hacs.xyz | bash -
Connecting to install.hacs.xyz (172.67.68.101:443)
Connecting to raw.githubusercontent.com (185.199.110.133:443)
writing to stdout
-                    100% |***********************************************************************************************|  4990  0:00:00 ETA
written to stdout
INFO: Trying to find the correct directory...
INFO: Found Home Assistant configuration directory at '/config'
INFO: Changing to the custom_components directory...
INFO: Downloading HACS
Connecting to github.com (20.205.243.166:443)
Connecting to github.com (20.205.243.166:443)
Connecting to objects.githubusercontent.com (185.199.111.133:443)
saving to 'hacs.zip'
hacs.zip             100% |***********************************************************************************************| 16.0M  0:00:00 ETA
'hacs.zip' saved
INFO: Creating HACS directory...
INFO: Unpacking HACS...

INFO: Verifying versions
INFO: Current version is 2024.4.1, minimum version is 2024.4.1

INFO: Removing HACS zip file...
INFO: Installation complete.

INFO: Remember to restart Home Assistant before you configure it
```

Upgrade HASS và install lại HACS xong. Lỗi vẫn thế.

Cần phải vào HACS, upgrade version của `button-card` lên 4.1.2

Rồi vào file `/opt/hass/config/configuration.yaml`, sửa đoạn này để nó dùng version latest của `button-card`:
```yaml
lovelace:
  mode: yaml
  resources:
    - url: /hacsfiles/button-card/button-card.js # /hacsfiles/button-card/button-card.js?v=4.1.1
      type: module
```

Restart HASS là OK. Quay lại điện thoại ko bị lỗi nữa.

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

### 10.6. Troubleshoot

Nếu 1 ngày tự nhiên ko active được Wireguard, nguyên nhân:  
- Trường hợp 1: Hãy kiểm tra có phải bạn đang connect vào 1 wifi có setup proxy (trường hợp của mình là Wifi có setup Pihole làm DNS) (Hãy kéo xuống đọc phần Pihole để hiểu).  
- Trường hợp 2: Hãy thử dùng 1 thiết bị khác, vẫn connect cùng 1 wifi. (Nếu vẫn connect thành công có nghĩa là ko phải lỗi ở Server Wireguard, mà là do thiết bị của bạn -> Hãy thử restart). Tình huống của mình là Wireguard PC bị lỗi `Access is denied`, nhưng điện thoại vẫn kết nối OK. Check log PC thấy:  

```
2023-10-12 21:08:19.792: [TUN] [londontest] Could not bind socket to 0.0.0.0:51820 (0xc0000022)
2023-10-12 21:08:19.792: [TUN] [londontest] Unable to bring up adapter: Access is denied.
2023-10-12 21:08:19.837: [TUN] [londontest] Shutting down
```
-> restart PC là được.  

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

### 12.4. Setup collector: directory size

Mặc định thì node-exporter ko có chỗ config để lấy disk size mình muốn. Nên cần phải tạo 1 collector đúng format cho Prometheus đọc được.

Trước tiên trong RPi host tạo dir: `/var/lib/node_exporter/textfile_collector`

Sửa file `docker-compose.yml`, phần node-exporter, thêm đoạn `volumes và command` như dưới:  

```yml
  node-exporter:
    image: prom/node-exporter:v1.3.1
    container_name: monitoring_node_exporter
    restart: unless-stopped
    expose:
      - 9100
    volumes:
      - /var/lib/node_exporter/textfile_collector:/var/lib/node_exporter/textfile_collector:ro
    command:
      - '--collector.textfile.directory=/var/lib/node_exporter/textfile_collector'
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "10"
```

Sau đó tạo crontab job bằng lệnh `crontab -e`, add line sau vào cuối:  

```
*/5 * * * * sudo du -sb /opt/hass /opt/hass-influxdb /opt/hass-pgdb /opt/syncthing /opt/prometheus-grafana /opt/devops /opt/swag | sed -ne 's/^\([0-9]\+\)\t\(.*\)$/node_directory_size_bytes{directory="\2"} \1/p' > /var/lib/node_exporter/textfile_collector/directory_size.prom.$$ && mv /var/lib/node_exporter/textfile_collector/directory_size.prom.$$ /var/lib/node_exporter/textfile_collector/directory_size.prom
```

Giải thích: Cứ 5 phút 1 lần, chạy với quyền `sudo`, run command `du -sb` đối với các folder bạn muốn (ở đây mình chọn `/opt/hass /opt/hass-influxdb /opt/hass-pgdb /opt/syncthing /opt/prometheus-grafana /opt/devops /opt/swag`). Ghi kết quả vào file `/var/lib/node_exporter/textfile_collector/directory_size.prom`

- Chờ 5 phút sau vào check data có trong file `/var/lib/node_exporter/textfile_collector/directory_size.prom` hay ko?  
- Check trên Prometheus có query được data ko? - gõ như này `node_directory_size_bytes` mà ra được đủ các dir là ok.  
- Check xem có lấy đúng size ko: `du -sb -h /opt/devops`

Lên Prometheus check data sẽ thấy bạn có thể lấy đc data thông qua metric `node_directory_size_bytes`

Trên Grafana tạo riêng panel và query như này, để hiển thị data dưới dạng MB phải chia cho 1048576:  

```
node_directory_size_bytes{directory="/opt/devops", instance="node-exporter:9100", job="prometheus"} / 1048576
```

### 12.5. Setup collector: troubeshoot

Khi mình monitor các sub dir của /opt (như trên /opt/hass, /opt/swag, etc...) thì mình nảy sinh ý muốn monitor cả size total của /opt luôn.

Cứ nghĩ đơn giản là add thêm vào crontab như này `*/5 * * * * sudo du -sb /opt /opt/hass /opt/hass-influxdb /opt/hass-pgdb /opt/syncthing /opt/prometheus-grafana /opt/devops /opt/swag....` là đủ nhưng hóa ra ko phải. Làm thế bạn sẽ ko thể output ra được size của các sub dir. Vì dường như command bị overlab giữa parent dir /opt và các sub dir /opt/hass... ở trong cùng 1 command.

Solution: Tạo thêm 1 crontab riêng cho parent dir:

```
*/5 * * * * sudo du -sb /opt | sed -ne 's/^\([0-9]\+\)\t\(.*\)$/node_directory_size_opt_bytes{directory="\2"} \1/p' > /var/lib/node_exporter/textfile_collector/directory_size_opt.prom.$$ && mv /var/lib/node_exporter/textfile_collector/directory_size_opt.prom.$$ /var/lib/node_exporter/textfile_collector/directory_size_opt.prom
```

Giải thích: Cứ 5 phút 1 lần, chạy với quyền `sudo`, run command `du -sb` đối với các folder bạn muốn (ở đây mình chọn `/opt`). Ghi kết quả vào file `/var/lib/node_exporter/textfile_collector/directory_size_opt.prom`

Lên Prometheus check data sẽ thấy bạn có thể lấy đc data thông qua metric `node_directory_size_opt_bytes`

Như vậy về cơ bản bạn đã biết cách tạo 1 custom metric bằng crontab và hiển thị data đó trên Prometheus & Grafana

### 12.6. Troubeshoot data display thiếu

1 ngày nọ nhận ra Dashboard của Grafana bị dừng lại như này:

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/grafana-dashboard-date-late.jpg)

Tại thời điểm chụp là 22:30, nhưng Dashboard chỉ show đến 21:40 mà thôi. 

Ngay lập tức điều tra, test lại publish/receive message: vẫn nhận ngay lập tức, check lại các logs docker containers: ko có gì đặc biệt. 

Thử grep `grep CRON /var/log/syslog` : cứ đến mốc thời gian 21:40 là stop các CRON job.

Check lại `tail -20f /var/log/syslog`, log vẫn sinh ra đều đều nhưng mốc thời gian khác với thực tế.

Check `date` của hệ thống thì thấy thời gian của RPi là 21:45, nhưng hiện tại là 22:30 mà ??? =>  Tìm ra nguyên nhân là đây

```
$ tail -20f /var/log/syslog

Oct 27 21:48:01 raspberrypi CRON[124506]: (admin) CMD (python3 ..../rpi-cpu2mqtt.py)
Oct 27 21:48:01 raspberrypi CRON[124507]: (admin) CMD (bash ..../create-vm-oracle-sg.sh)
Oct 27 21:48:02 raspberrypi dockerd[741]: time="2023-10-27T21:48:02.896730544+07:00" level=error msg="[resolver] failed to query DNS server: 192.168.1.1:53, query: ;.\tIN\t NS" error="read udp 172.18.0.6:52830->192.168.1.1:53: i/o timeout"
Oct 27 21:48:04 raspberrypi dockerd[741]: time="2023-10-27T21:48:04.399010062+07:00" level=error msg="[resolver] failed to query DNS server: 192.168.1.1:53, query: ;.\tIN\t NS" error="read udp 172.18.0.6:34092->192.168.1.1:53: i/o timeout"
Oct 27 21:48:05 raspberrypi dockerd[741]: time="2023-10-27T21:48:05.899927783+07:00" level=error msg="[resolver] failed to query DNS server: 192.168.1.1:53, query: ;.\tIN\t NS" error="read udp 172.18.0.6:38289->192.168.1.1:53: i/o timeout"
Oct 27 21:48:07 raspberrypi dockerd[741]: time="2023-10-27T21:48:07.400986412+07:00" level=error msg="[resolver] failed to query DNS server: 192.168.1.1:53, query: ;.\tIN\t NS" error="read udp 172.18.0.6:43641->192.168.1.1:53: i/o timeout"
Oct 27 21:48:08 raspberrypi dockerd[741]: time="2023-10-27T21:48:08.903172059+07:00" level=error msg="[resolver] failed to query DNS server: 192.168.1.1:53, query: ;.\tIN\t NS" error="read udp 172.18.0.6:42449->192.168.1.1:53: i/o timeout"
Oct 27 21:48:10 raspberrypi dockerd[741]: time="2023-10-27T21:48:10.405057669+07:00" level=error msg="[resolver] failed to query DNS server: 192.168.1.1:53, query: ;.\tIN\t NS" error="read udp 172.18.0.6:33171->192.168.1.1:53: i/o timeout"
Oct 27 21:48:11 raspberrypi dockerd[741]: time="2023-10-27T21:48:11.905704168+07:00" level=error msg="[resolver] failed to query DNS server: 192.168.1.1:53, query: ;.\tIN\t NS" error="read udp 172.18.0.6:48174->192.168.1.1:53: i/o timeout"
```

Thấy các query vẫn liên tục trỏ đến IP `192.168.1.1` và bị timeout. Source là từ IP `172.18.0.6` -> check bằng iptables thì biết được đây là Ip của wireguard

Cần sửa lại file `/opt/hass/docker-compose.yml`:

```yml
wireguard:
    image: lscr.io/linuxserver/wireguard:1.0.20210914
    container_name: wireguard
    dns:
      - 8.8.8.8
....
```

Check lại `tail -20f /var/log/syslog` ko còn log lỗi timeout nữa. Nhưng thời gian vẫn chưa được sync.

Check service ntp thấy lỗi `kernel reports TIME_ERROR: 0x41: Clock Unsynchronized`:  

```
$ sudo service ntp stop
$ sudo service ntp start
$ sudo service ntp status
● ntp.service - Network Time Service
     Loaded: loaded (/lib/systemd/system/ntp.service; enabled; vendor preset: enabled)
     Active: active (running) since Fri 2023-10-27 22:20:51 +07; 4s ago
       Docs: man:ntpd(8)
    Process: 128633 ExecStart=/usr/lib/ntp/ntp-systemd-wrapper (code=exited, status=0/SUCCESS)
   Main PID: 128639 (ntpd)
      Tasks: 2 (limit: 8755)
        CPU: 50ms
     CGroup: /system.slice/ntp.service
             └─128639 /usr/sbin/ntpd -p /var/run/ntpd.pid -g -u 110:114

Oct 27 22:20:51 raspberrypi ntpd[128639]: Listen normally on 31  []:123
Oct 27 22:20:51 raspberrypi systemd[1]: Started Network Time Service.
Oct 27 22:20:51 raspberrypi ntpd[128639]: Listen normally on 32  []:123
Oct 27 22:20:51 raspberrypi ntpd[128639]: Listen normally on 33  []:123
Oct 27 22:20:51 raspberrypi ntpd[128639]: Listening on routing socket on fd #50 for interface updates
Oct 27 22:20:51 raspberrypi ntpd[128639]: kernel reports TIME_ERROR: 0x41: Clock Unsynchronized
Oct 27 22:20:51 raspberrypi ntpd[128639]: kernel reports TIME_ERROR: 0x41: Clock Unsynchronized
Oct 27 22:20:52 raspberrypi ntpd[128639]: Soliciting pool server 203.113.174.44
Oct 27 22:20:53 raspberrypi ntpd[128639]: Soliciting pool server 203.113.174.44
Oct 27 22:20:55 raspberrypi ntpd[128639]: Soliciting pool server 203.113.174.44
```

```
$ ntptime
ntp_gettime() returns code 5 (ERROR)
  time e8e654e5.265d9000  Fri, Oct 27 2023 22:25:25.149, (.149865),
  maximum error 16000000 us, estimated error 16000000 us, TAI offset 0
ntp_adjtime() returns code 5 (ERROR)
  modes 0x0 (),
  offset 0.000 us, frequency 0.000 ppm, interval 1 s,
  maximum error 16000000 us, estimated error 16000000 us,
  status 0x41 (PLL,UNSYNC),
  time constant 7, precision 1.000 us, tolerance 500 ppm,
```

Đã thử dùng `chrony` như 1 số recommend trên mạng đều ko sync thời gian được. 

```sh
sudo apt install chrony
```

Đã thử restart RPi vẫn ko giải quyết được vấn đề.

#### 2023/October/27. Tạm thời set datetime bằng tay

Đành phải set cứng thời gian bằng tay:

```sh
sudo timedatectl set-ntp false
sudo timedatectl set-time '23:49:48'
```

Sau vài ngày tự nhiên chạy mấy command này thấy ko bị lỗi nữa:

```
$ sudo systemctl status ntp
● ntp.service
     Loaded: masked (Reason: Unit ntp.service is masked.)
     Active: inactive (dead)


$ sudo timedatectl set-ntp true


$ timedatectl
               Local time: Tue 2023-10-31 21:05:26 +07
           Universal time: Tue 2023-10-31 14:05:26 UTC
                 RTC time: n/a
                Time zone: Asia/Bangkok (+07, +0700)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: no


$ chronyc activity
200 OK
4 sources online
0 sources offline
0 sources doing burst (return to online)
0 sources doing burst (return to offline)
0 sources with unknown address


$ chronyc sources
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^* t2.time.sg3.yahoo.com         2   6   377    17   -187us[ -395us] +/-   33ms
^+ 2400:2410:b520:5400::f:1>     2   6   377    16  +1600us[+1600us] +/-   45ms
^- 2603:c024:8002:70ff:b932>     5   6   377    15    +78ms[  +78ms] +/-  151ms
^- y.ns.gin.ntt.net              2   6   377    16  +7071us[+7071us] +/-  115ms


$ service chrony status
● chrony.service - chrony, an NTP client/server
     Loaded: loaded (/lib/systemd/system/chrony.service; enabled; vendor preset: enabled)
     Active: active (running) since Tue 2023-10-31 21:04:07 +07; 23s ago
       Docs: man:chronyd(8)
             man:chronyc(1)
             man:chrony.conf(5)
    Process: 132474 ExecStart=/usr/sbin/chronyd $DAEMON_OPTS (code=exited, status=0/SUCCESS)
   Main PID: 132476 (chronyd)
      Tasks: 2 (limit: 8755)
        CPU: 164ms
     CGroup: /system.slice/chrony.service
             ├─132476 /usr/sbin/chronyd -F 1
             └─132477 /usr/sbin/chronyd -F 1

Oct 31 21:04:07 raspberrypi systemd[1]: Starting chrony, an NTP client/server...
Oct 31 21:04:07 raspberrypi chronyd[132476]: chronyd version 4.0 starting (+CMDMON +NTP +REFCLOCK +RTC +PRIVDROP +SCFILTER +SIGND +ASYNCDNS +NTS +SECHASH +IPV6 -DEBUG)
Oct 31 21:04:07 raspberrypi chronyd[132476]: Frequency 0.000 +/- 1000000.000 ppm read from /var/lib/chrony/chrony.drift
Oct 31 21:04:07 raspberrypi chronyd[132476]: Using right/UTC timezone to obtain leap second data
Oct 31 21:04:07 raspberrypi chronyd[132476]: Loaded seccomp filter
Oct 31 21:04:07 raspberrypi systemd[1]: Started chrony, an NTP client/server.
Oct 31 21:04:13 raspberrypi chronyd[132476]: Selected source 2406:2000:e4:a1f::1001 (2.debian.pool.ntp.org)
Oct 31 21:04:13 raspberrypi chronyd[132476]: System clock TAI offset set to 37 seconds


$ chronyc tracking
Reference ID    : 570A772A (t2.time.sg3.yahoo.com)
Stratum         : 3
Ref time (UTC)  : Tue Oct 31 14:11:46 2023
System time     : 0.000404081 seconds fast of NTP time
Last offset     : -0.000208332 seconds
RMS offset      : 0.005089778 seconds
Frequency       : 16.710 ppm fast
Residual freq   : -0.270 ppm
Skew            : 17.042 ppm
Root delay      : 0.049899403 seconds
Root dispersion : 0.006518754 seconds
Update interval : 64.6 seconds
Leap status     : Normal


$ sudo chronyc makestep
200 OK


$ chronyc tracking
Reference ID    : 570A772A (t2.time.sg3.yahoo.com)
Stratum         : 3
Ref time (UTC)  : Tue Oct 31 14:13:56 2023
System time     : 0.000000000 seconds slow of NTP time
Last offset     : -0.001906959 seconds
RMS offset      : 0.004620512 seconds
Frequency       : 13.762 ppm fast
Residual freq   : -0.305 ppm
Skew            : 10.823 ppm
Root delay      : 0.051409919 seconds
Root dispersion : 0.002382592 seconds
Update interval : 64.9 seconds
Leap status     : Normal


$ sudo chronyc serverstats
NTP packets received       : 0
NTP packets dropped        : 0
Command packets received   : 11
Command packets dropped    : 0
Client log records dropped : 0
NTS-KE connections accepted: 0
NTS-KE connections dropped : 0
Authenticated NTP packets  : 0
```

CREDIT: https://www.golinuxcloud.com/configure-chrony-ntp-server-client-force-sync/

#### 2024/April/20. Solution: install htpdate

Lỗi này vẫn thường xuất hiện mỗi lần Router restart. Nhưng mình đã tìm ra được cách để sync date tự động

```
$ sudo apt-get install htpdate
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following packages were automatically installed and are no longer required:
  libevent-core-2.1-7 libevent-pthreads-2.1-7 libopts25 sntp
Use 'sudo apt autoremove' to remove them.
The following NEW packages will be installed:
  htpdate
0 upgraded, 1 newly installed, 0 to remove and 8 not upgraded.
Need to get 19.0 kB of archives.
After this operation, 60.4 kB of additional disk space will be used.
Get:1 http://deb.debian.org/debian bullseye/main arm64 htpdate arm64 1.2.2-4 [19.0 kB]
Fetched 19.0 kB in 0s (43.6 kB/s)
Selecting previously unselected package htpdate.
(Reading database ... 51908 files and directories currently installed.)
Preparing to unpack .../htpdate_1.2.2-4_arm64.deb ...
Unpacking htpdate (1.2.2-4) ...
Setting up htpdate (1.2.2-4) ...
Created symlink /etc/systemd/system/multi-user.target.wants/htpdate.service → /lib/systemd/system/htpdate.service.
Processing triggers for man-db (2.9.4-2) ...

$ sudo htpdate -a google.com
Adjusting 1.000 seconds

$ service htpdate status
● htpdate.service - HTTP based time synchronization tool
     Loaded: loaded (/lib/systemd/system/htpdate.service; enabled; vendor preset: enabled)
     Active: active (running) since Sat 2024-04-20 09:30:52 +07; 37min ago
       Docs: man:htpdate
    Process: 7788 ExecStart=/usr/sbin/htpdate $HTP_OPTIONS $HTP_PROXY -i /run/htpdate.pid $HTP_SERVERS (code=exite>
   Main PID: 7790 (htpdate)
      Tasks: 1 (limit: 8544)
        CPU: 122ms
     CGroup: /system.slice/htpdate.service
             └─7790 /usr/sbin/htpdate -D -s -i /run/htpdate.pid www.pool.ntp.org www.ntp.br www.wikipedia.org

Apr 20 09:30:52 raspberrypi systemd[1]: Starting HTTP based time synchronization tool...
Apr 20 09:30:52 raspberrypi systemd[1]: htpdate.service: Supervising process 7790 which is not our child. We'll mo>
Apr 20 09:30:52 raspberrypi systemd[1]: Started HTTP based time synchronization tool.
Apr 20 09:30:59 raspberrypi htpdate[7790]: www.wikipedia.org no timestamp
Apr 20 09:31:00 raspberrypi htpdate[7790]: www.wikipedia.org no timestamp
Apr 20 09:31:00 raspberrypi htpdate[7790]: Setting 2192.500 seconds
Apr 20 09:31:00 raspberrypi htpdate[7790]: Set: Sat Apr 20 10:07:33 2024

$ date
Sat 20 Apr 10:08:05 +07 2024

```

CREDIT: https://askubuntu.com/a/948282

**Chú ý**:

Việc sai giờ hệ thống cũng dẫn đến nhiều vấn đề, không chỉ Grafana show data thiếu/chậm, mà còn:  
- Logbook của HASS show thiếu/chậm.  
- Reconnect đến LG ThinQ service integration bị lỗi liên tục: authen bằng account đúng user/password nhưng vẫn báo lỗi invalid.  


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

Tuy Dashboard rất đẹp nhưng sau 1 thời gian sử dụng mình thấy nó làm tăng disk size lên 1 cách từ từ (điều mà mình ko muốn chút nào, lúc đó đang có 14.8Gb và tăng dần), tuy nhiên dùng node-exporter cũ thì lại ko thấy disk size tăng lên như vậy.

Thế là mình quyết định bỏ cái cadvisor đi

Dù bỏ cadvisor nhưng vẫn cần 1 cái chart để monitoring các directory size của mình. Thế nên mình đã tìm được cách để node-exporter có thể collect được directory size: https://www.robustperception.io/monitoring-directory-sizes-with-the-textfile-collector/. Cụ thể thì mình update mô tả trong phần Setup Prmoetheous + Grafana bên trên. 

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
      card_mod: # add từ 2024/06/16 
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

### 18.1. Send laptop battery to HASS as sensor

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

### 18.2. Send NUC Temperature to HASS as sensor

Tình huống là: Mình có 1 máy Mini PC (NUC11i5) cần theo dõi nhiệt độ. Mình đang để nó trên nóc cái Mi AirPurifier luôn =)) Coi như làm tản nhiệt cao cấp 🤣

Mình muốn khi nào Mini PC có nhiệt độ CPU trên 70 độ thì sẽ tự động bật cái Mi AirPurifier lên 😁

Muốn làm vậy thì mình cần export được CPU temp vào Hass. Thì cần cài HASS.Agent. Tuy nhiên mặc định không có thông số CPU Temperature nên cần custom.

Vào HASS.Agent -> Local sensor -> Add thêm sensor như này:  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass.agent-powershell-cpu-temp.jpg)

Content trong cái Powershell script như sau - chú ý dấu ngoặc kép, hãy copy y nguyên:

```
Get-WMIObject -Query “SELECT * FROM Win32_PerfFormattedData_Counters_ThermalZoneInformation” -Namespace “root/CIMV2” | Select-object -ExpandProperty Temperature -First 1
```

Test thử thấy như này là OK: ![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass.agent-powershell-cpu-temp-test.jpg)

324 nghĩa là = 273+51 -> 51 độ C (273 độ K = 0 độ C)

Vào HASS -> Developer Tools -> States -> Search `nuc11i5_cputemperature` sẽ thấy sensor đó hiện ra là OK.

Tiếp theo có 1 vấn đề là trên HASS (HASS -> Developer Tools -> States -> Search `nuc11i5_cputemperature`), Cột Attribute ko hiển thị `device_class và unit_of_measurement` của sensor. Điều này làm cho nó ko show đồ thị dạng chart khi ấn vào Office Room -> chạm vào cái box `NUC Temperature`.

Nguyên nhân là do cái HASS.Agent PowerShell Command nó chỉ truyền giá trị thôi. Mình cần phải sửa trong HASS để nó rewrite lại sensor custom đó, thêm `device_class và unit_of_measurement` vào: 

Sửa file `hass/config/configuration.yaml`:

```yml
homeassistant:
  ....
  customize:
    sensor.nuc11i5_cputemperature:
      device_class: temperature
      unit_of_measurement: °K
```

Rồi vào HASS -> Developer Tools -> YAML -> YAML configuration reloading -> tick `LOCATION & CUSTOMIZATIONS` chờ 1 lúc sẽ thấy nó reload lại.

Confirm lại: HASS -> Developer Tools -> States -> Search `nuc11i5_cputemperature`, Cột Attribute SẼ hiển thị `device_class và unit_of_measurement` của sensor.

Giờ tạo automation tương ứng là xong thôi.

File `automations.yml`: 

```yml
# Turn On/off Air Purifier base on NUC temperature
- id: '12486934745678032456823hoangmnsd'
  alias: Turn On/off Air Purifier base on NUCi5 temperature
  description: Turn On/off Air Purifier base on NUCi5 temperature
  trigger:
  - below: '323' # <= 50 *C
    entity_id: sensor.nuc11i5_cputemperature
    platform: numeric_state
  - above: '343' # >= 70 *C
    entity_id: sensor.nuc11i5_cputemperature
    platform: numeric_state
  condition: []
  action:
  - data: {}
    entity_id: fan.mi_air_purifier_33h
    service_template: >
      {% set p = states('sensor.nuc11i5_cputemperature') | int(0) %}
      {% if p >= 343 %}
      fan.turn_on
      {% elif p <= 323 %}
      fan.turn_off
      {% endif %}
```

**Troubeshoot**:  

- Đôi khi có thể gặp vấn đề là: NUC chạy trên 70 độ nhưng automation ko chạy.   
  Nguyên nhân: HASS.Agent bị lỗi ko gửi nhiệt độ lên HASS Server.   
  Solution: Restart HASS.Agent là OK ngay.


**Credit**:  
https://www.techepages.com/get-cpu-temperature-using-powershell/   
https://hassagent.readthedocs.io/en/latest/wmi-examples/  
https://hassagent.readthedocs.io/en/latest/examples/#command-grab-screenshot-using-powershell  
https://www.home-assistant.io/docs/configuration/customizing-devices/#manual-customization  

### 18.3. Setup custom sensor on HASS, send RPi CPU temperature to MQTT server 

Tình huống là con RPi của mình có nhiệt độ hiện tại chỉ được đó bằng Exporter+Prometheus+Grafana mà thôi. Điều này giúp mình check và set alert thông qua Grafana.

Nhưng mình muốn set action tương ứng trên HASS nữa: Nếu nhiệt độ của RPi trên 50 độ C thì sẽ tự động turn-on cái Mi AirPurifier 🤣

Thế nên: Cần expose RPi Temperature vào MQTT server (mosquitto), từ đó HASS sẽ đọc thông tin sensor.  

Làm theo hướng dẫn manual trong repo này: https://github.com/hjelev/rpi-mqtt-monitor/tree/master

Sửa file `rpi-mqtt-monitor/src/config.py.example` thành `rpi-mqtt-monitor/src/config.py`:  

```
mqtt_host = "localhost"
mqtt_user = "<INPUT MQTT USER HERE>"
mqtt_password = "<INPUT MQTT PASSWORD HERE>"
mqtt_port = "1883"
mqtt_topic_prefix = "rpi-MQTT-monitor"
group_messages = False
discovery_messages = False

sleep_time = 0.5
cpu_load = False
cpu_temp = True
used_space = False
used_space_path = '/'
voltage = False
sys_clock_speed = False
swap = False
memory = False
uptime = False
wifi_signal = False
wifi_signal_dbm = False
```

Vì mình chỉ cần Temperature nên mình chỉ set `cpu_temp = True` thôi.

check hostname của RPi: 

```sh
$ hostname
raspberrypi
```

Như vậy tool này sẽ expose thông tin temperature lên MQTT Topic `rpi-MQTT-monitor/raspberrypi/cputemp`

Giờ Test: 

Bật 1 terminal RPi #1 lên, gõ command sau để subscribe topic trên:  

```sh
docker exec -it mosquitto /bin/sh
mosquitto_sub -t 'rpi-MQTT-monitor/raspberrypi/cputemp' -u mqttuser -P AAAAAAAXXX

```

Bật 1 terminal RPi #2 lên, run script để publish thông tin sensor lên:

```sh
python3 ./rpi-mqtt-monitor/src/rpi-cpu2mqtt.py
```

Gần như cùng lúc, terminal #1 sẽ nhìn thấy giá trị nhiệt độ được gửi vào topic. -> Thế là ngon.

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/sensor-rpi-cpu-tem-mqtt-server.jpg)

Giờ tạo crontab để script để send message lên MQTT Topic thường xuyên 2 phút 1 lần:  

```
*/2 * * * * python3 /opt/devops/rpi-mqtt-monitor/src/rpi-cpu2mqtt.py
```

Giờ setup trên HASS, sửa file `configuration.yml`, add thêm entry sau:  

```yml
sensor:
...

  - platform: mqtt
    state_topic: "rpi-MQTT-monitor/raspberrypi/cputemp"
    name: Rpi4 Cpu Temp
    unit_of_measurement: "°C"
```

Restart HASS. ko có lỗi gì là OK, vào Developer tools -> state, search cpu sẽ thấy sensor này hiện ra `sensor.rpi4_cpu_temp`

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/sensor-rpi-cpu-temp.jpg)

Giờ có thể làm Automation để tự động hóa dựa trên temperature rồi. 😀

Chú ý từ phiên bản HASS 2022.09 đã có thay đổi format define sensor như này: https://www.home-assistant.io/integrations/sensor.mqtt/#new_format

#### UPDATE 2024.01.13

Từ version mới của HASS 2024.1.2 thì đã ko thể dùng `- platform: mqtt` như trên để define sensor.

Sửa file `rpi-mqtt-monitor/src/config.py`: 

```yml
# If this is set, then the script will send MQTT discovery messages meaning a config less setup in HA.  Only works
# when group_messages is not used

discovery_messages = True
```

Trong file `configuration.yml`, bỏ đoạn này đi:  

```yml
sensor:
...

  - platform: mqtt
    state_topic: "rpi-MQTT-monitor/raspberrypi/cputemp"
    name: Rpi4 Cpu Temp
    unit_of_measurement: "°C"
```

Restart HASS. Vào Developer tools -> state, search cpu sẽ thấy sensor này hiện ra `sensor.raspberrypi_cpu_temperature`


CREDIT:  
https://github.com/hjelev/rpi-mqtt-monitor/tree/master


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

## 20. Setup a not supported device (zigbee2mqtt not supported)

### 20.1. Công tắc TS011F

Lên Shopee mua được 2 cái ổ cắm này: [link shopee](https://shopee.vn/%E1%BB%94-c%E1%BA%AFm-%C4%91i%E1%BB%87n-SMATRUL-wifi-h%E1%BA%B9n-gi%E1%BB%9D-th%C3%B4ng-minh-Zigbee-ph%C3%ADch-c%E1%BA%AFm-US-16-20A-cho-Google-Amazon-Alexa-i.293326414.15562217358)

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/zigbee2mqtt-device-bsd04.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/zigbee2mqtt-device-bsd04-b.jpg)  

Về nhà tá hỏa ra là zigbee2mqtt của mình ko support loại này, khi vào pairing mode sẽ thấy lỗi sau:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/zigbee2mqtt-unsupported-device-error.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/zigbee2mqtt-unsupported-device-error2.jpg)

Mặc vẫn join được vào Zigbee network nhưng sẽ bị lỗi là nó ko expose ra state, vào HomeAssistant Device sẽ ko nhìn thấy nó để mà tương tác, bật tắt.
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/zigbee2mqtt-unsupported-device-error3.jpg)

**Solution**: Cần đọc page này để làm bằng tay: https://www.zigbee2mqtt.io/advanced/support-new-devices/01_support_new_devices.html#_2-adding-your-device

Step 1: Tạo file `TS011F.js` trong cùng folder với `configuration.yaml` của `zigbee2mqtt` 
Nội dung file thì như này, link trên có sample của sensor - ko dùng được cho switch. Đoạn code dưới được lấy từ link này:  
https://github.com/Koenkk/zigbee2mqtt.io/blob/master/docs/externalConvertersExample/switch.js
  

```sh
const fz = require('zigbee-herdsman-converters/converters/fromZigbee');
const tz = require('zigbee-herdsman-converters/converters/toZigbee');
const exposes = require('zigbee-herdsman-converters/lib/exposes');
const reporting = require('zigbee-herdsman-converters/lib/reporting');
const extend = require('zigbee-herdsman-converters/lib/extend');
const e = exposes.presets;
const ea = exposes.access;

const definition = {
    zigbeeModel: ['TS011F'],
    model: 'BSD04',
    vendor: 'Unknown',
    description: 'Smart Plug',
    fromZigbee: [fz.on_off],
    toZigbee: [tz.on_off],
    exposes: [e.switch()],
    // The configure method below is needed to make the device reports on/off state changes
    // when the device is controlled manually through the button on it.
    configure: async (device, coordinatorEndpoint, logger) => {
        const endpoint = device.getEndpoint(1);
        await reporting.bind(endpoint, coordinatorEndpoint, ['genOnOff']);
        await reporting.onOff(endpoint);
    },
};

module.exports = definition;

```

Step 2: Sửa file `configuration.yaml` của `zigbee2mqtt` 

```sh
...
advanced:
  log_level: debug
external_converters:
  - TS011F.js
```

restart lại zigbee2mqtt, đọc log xem có gì lạ ko...

Vào lại Zigbee2mqtt sẽ thấy device đã expose ra state để sử dụng:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/zigbee2mqtt-unsupported-device-fixed.jpg)

Chỗ này cũng được update thành `Supported`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/zigbee2mqtt-unsupported-device-supported.jpg)

😎

### 20.2. Motion sensor _TZE204_qasjif9e

Lên Shopee mua được cái này: [link shopee](https://shopee.vn/C%E1%BA%A3m-bi%E1%BA%BFn-hi%E1%BB%87n-di%E1%BB%87n-Tuya-ZigBee-ZY-M100-C%E1%BA%A3m-Bi%E1%BA%BFn-Chuy%E1%BB%83n-%C4%90%E1%BB%99ng-Con-Ng%C6%B0%E1%BB%9Di-K%E1%BA%BFt-N%E1%BB%91i-Wifi-mmWave-i.32325402.18882227491)

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/zigbee2mqtt-ts0601-shopee1.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/zigbee2mqtt-ts0601-shopee2.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/zigbee2mqtt-ts0601-shopee3.jpg)  

Khi add vào Zigbee2mqtt thì sẽ bị lỗi như này:  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/zigbee2mqtt-ts0601-error-not-supported.jpg)

cần update `koenkk/zigbee2mqtt:1.25.0` lên `koenkk/zigbee2mqtt:1.35.3` thì sẽ ko cần làm gì cả. Sẽ từ chuyển thành `Supported`

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/zigbee2mqtt-ts0601-supported.jpg)

tuy nhiên vào tab Expose vẫn thấy `Presence = Null`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/zigbee2mqtt-ts0601-expose.jpg)

sau 1 hồi restart thì nó chuyển thành như này:

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/zigbee2mqtt-ts0601-expose-ok.jpg)

## 21. Setup cooler dual fan

Gần đây chuyển RPi từ trên trần nhà xuống bàn làm việc, phải bỏ quạt ra vì quá ồn. Điều này làm nhiệt độ của Pi vọt lên 60 độ (điều kiện thường) và có khi lên 65 70 độ khi chạy các tác vụ nặng (trước đây có quạt 5v thì khoảng 50-55 độ). Dẫn đến mình phải mua 1 cái tản nhiệt mới. 
Quyết định mua cái này, [giá 160k](https://shopee.vn/V%E1%BB%8F-nh%C3%B4m-t%E1%BA%A3n-nhi%E1%BB%87t-Raspberry-pi-4-model-B-(k%C3%A8m-qu%E1%BA%A1t-t%E1%BA%A3n-nhi%E1%BB%87t)-ch%E1%BA%A5t-li%E1%BB%87u-h%E1%BB%A3p-kim-nh%C3%B4m-m%E1%BB%8Bn-%C4%91%E1%BB%99-c%E1%BB%A9ng-cao-ch%E1%BB%8Bu-%C3%A1p-l%E1%BB%B1c-t%E1%BB%91t-i.891300093.19571256924)


Thành quả sau khi lắp, nhiệt độ giảm đột ngột từ 60 độ về 40 độ kinh khủng thật 🤣 Biết thế lắp sớm hơn. Quạt chạy rất êm, hầu như ko có tiếng ồn.

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/rpi-dual-fan.jpg)

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/rpi-temp-40.jpg)

## 22. Setup Syncthing (to synchronize between Androids and PC and IOS)

Mình có 3 thiết bị: Android, iPhone, PC Window cần sync 1 folder với nhau. Và Trên các thiết bị sẽ mở folder đó bằng Obsidian Notes App.

Ban đầu mình nghĩ đến dùng 1 Cloud storage để share folder chung đó, nhưng ko khả thi vì Dropbox/Ondrive ko làm được cái mình muốn.

Để đạt được việc này thì mình sẽ chọn Syncthing. Dùng RPi làm 1 cái như Hub (Syncthing gọi là Introducer) chứa folder chung. 

Các device khác như Android, iPhone, PC sẽ kết nối đến Hub RPi (Introducer) để sync file 2 chiều.

Trước tiên là cài Syncthing trên RPi:  

`docker-compose.yml`:  

```yml
syncthing:
    image: lscr.io/linuxserver/syncthing:1.23.7
    container_name: syncthing
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Ho_Chi_Minh
    volumes:
      - /opt/syncthing/config:/config
    ports:
      - 8384:8384
      - 22000:22000/tcp
      - 22000:22000/udp
      - 21027:21027/udp
    restart: unless-stopped
  # after setup syncthing, goto port 8384, create admin user/password, disable Anonymous Usage Reporting, enable NAT traversal, disable Global Discovery
```

After setup syncthing, goto port 8384, create admin user/password, disable Anonymous Usage Reporting, enable NAT traversal, disable Global Discovery 

### 22.1. Setup Sync giữa Điện thoại Android với RPi Syncthing

Login vào giao diện Syncthing RPi, show QR code

Dùng điện thoại Android, -> Add Device -> Quét QR code -> Add (Chỗ biểu tượng link `dynamic` hãy sửa lại thành `tcp://192.x.x.x:22000`). Làm sao để status là `Đã đồng bộ` là OK (Như vậy nghĩa là Androids app đã connect được đến Hub RPi)

Quay lại Syncthing RPi -> Add remote device -> Check xem suggest Device ID hiện ra có trùng với cái trên điện thoại ko? có thì OK, Add. Hiện Connected là OK

Lên điện thoại Add Folder muốn share, vào folder đó enable cho thiết bị RPi

Quay lại Syncthing RPi, sẽ thấy dialog kiểu `LG wants to share folder "ObsidianNotes" (obsidiannotes). Add new folder?` -> OK, Add

Chọn folder path: Nên chọn:  `/config/data/ObsidianNotes` thì tức là trên RPi sẽ tạo folder `/opt/syncthing/config/data/ObsidianNotes` để sync data.

Chờ 1 lúc để data Sync rồi check.

### 22.2. Setup Sync giữa PC với RPi Syncthing

Trên PC, Download và cài đặt Syncthing (Cùng version với Syncthing RPi), vào Setting lấy Device ID của Syncthing PC. 

Trên Syncthing RPi, Add remote device -> Điền Device ID của Syncthing PC vào, đặt tên cho device.

Quay lại Syncthing PC, Add remote device -> Điền Device ID của Syncthing RPi vào:  
- Tab Sharing, tick vào Introducer. Để biết Introducer là gì thì vào trang chủ đọc ở [đây](https://docs.syncthing.net/users/introducer.html?highlight=introducer).  
- Tab Advanced, điền IP của RPi vào: `tcp://192.168.y.x:22000` (port 22000 là port Syncthing dùng để lắng nghe nhau, cái này define trong file `docker-compose.yml`).  

- Add folder, làm sao để các device `connected, up to date` là ok

Giờ test thử sửa file trên điện thoại -> sync lên PC. Và sửa file trên PC, sync lên điện thoại. Là OK.

### 22.3. Setup Sync giữa iPhone với RPi Syncthing (mất phí 129k)

Trên iphone cài Obsidian, create 1 new vault. (Obsidian ko cho create 1 new Vault ở bên ngoài folder của Obsidian nên mình sẽ ko chọn chỗ được. Nếu muốn nhìn vault bạn có thể vào `Files -> On My Iphone -> Obsidian`)

Sẽ cần cài 1 app tên là `Mobius Sync` trên App Store.

Trên RPi Syncthing, Add Remote Device -> add iphone device vào.  

Trên app `Mobius Sync` -> Add Remote Device, quét QR code của RPi. Tab Advanced -> điền `tcp://192.168.x.y:22000` (ip của RPi)

Thấy Connected là OK. 

Add folder trên Mobius, chú ý chỗ chọn `Folder Path` phải chọn `pick external folder` (**ĐỂ SỬ DỤNG CHỨC NĂNG NÀY PHẢI TRẢ PHÍ 129.000 VNĐ NHA**) . 

Vậy là xong, giờ cả 4 thiết bị đã có thể dùng Obsidian Notes cùng nhau.  

Tuy nhiên trên Iphone có limitation là IOS ko cho ứng dụng chạy ngầm, nên chỉ khi nào bật app Mobius lên thì mới sync data được nha.

### 22.4. Chú ý

- Đọc ở đâu đó thì `Folder ID` là cái unique của folder, nên nếu sync giữa các máy với nhau thì nên chọn cùng 1 `Folder ID` để Synthing nó hiểu và ko bị lỗi.

- Nếu bị lỗi này:  

```
2023-08-12 14:50:05: Failed to create folder root directory mkdir /opt/syncthing: permission denied

2023-08-12 14:50:05: Error on folder "ObsidianNotes" (obsidiannotes): folder path missing
```

-> Nên chọn folder `config` của syncthing RPi, chứ chọn đường dẫn ngoài nó ko hiểu

### 22.5. Setup Syncthing run on background Windows

Mỗi lần bật máy thì lại phải bật app Syncthing lên. Nên mình tìm cách để Syncthing sẽ luôn run on background mỗi khi mở máy.

Làm theo cách này: https://docs.syncthing.net/users/autostart.html

Vào đường dẫn này: `%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup`

tạo 1 shortcut với command: `D:\downloads\syncthing-windows-amd64-v1.23.6\syncthing-windows-amd64-v1.23.6\syncthing.exe --no-console --no-browser`

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/syncthing-run-on-background-windows-shortcut.jpg)

### 22.6. Troubleshoot

```
2024/04/22 20:47:19 INFO: Overall send rate is unlimited, receive rate is unlimited
[QUBJS] 2024/04/22 20:47:19 INFO: Relay listener (dynamic+https://relays.syncthing.net/endpoint) starting
[QUBJS] 2024/04/22 20:47:19 INFO: Using discovery mechanism: IPv4 local broadcast discovery on port 21027
[QUBJS] 2024/04/22 20:47:19 INFO: Using discovery mechanism: IPv6 local multicast discovery on address [ff12::8384]:21027
[QUBJS] 2024/04/22 20:47:19 INFO: Ready to synchronize "ObsidianNotes" (obsidiannotes) (sendreceive)
[QUBJS] 2024/04/22 20:47:19 WARNING: Starting API/GUI: listen tcp 127.0.0.1:8384: bind: An attempt was made to access a socket in a way forbidden by its access permissions.
[QUBJS] 2024/04/22 20:47:19 WARNING: Starting API/GUI: listen tcp 127.0.0.1:8384: bind: An attempt was made to access a socket in a way forbidden by its access permissions.
[QUBJS] 2024/04/22 20:47:19 WARNING: Starting API/GUI: listen tcp 127.0.0.1:8384: bind: An attempt was made to access a socket in a way forbidden by its access permissions.
[QUBJS] 2024/04/22 20:47:19 WARNING: Starting API/GUI: listen tcp 127.0.0.1:8384: bind: An attempt was made to access a socket in a way forbidden by its access permissions.
[QUBJS] 2024/04/22 20:47:19 WARNING: Starting API/GUI: listen tcp 127.0.0.1:8384: bind: An attempt was made to access a socket in a way forbidden by its access permissions.
[QUBJS] 2024/04/22 20:47:19 WARNING: Failed starting API: listen tcp 127.0.0.1:8384: bind: An attempt was made to access a socket in a way forbidden by its access permissions.
[QUBJS] 2024/04/22 20:47:19 INFO: Relay listener (dynamic+https://relays.syncthing.net/endpoint) shutting down
[QUBJS] 2024/04/22 20:47:19 INFO: Failed initial scan of sendreceive folder "ObsidianNotes" (obsidiannotes)
[QUBJS] 2024/04/22 20:47:19 INFO: TCP listener ([::]:22000) starting
[QUBJS] 2024/04/22 20:47:19 INFO: QUIC listener ([::]:22000) starting
[QUBJS] 2024/04/22 20:47:19 INFO: QUIC listener ([::]:22000) shutting down
[QUBJS] 2024/04/22 20:47:20 INFO: TCP listener ([::]:22000) shutting down
[QUBJS] 2024/04/22 20:47:20 INFO: Exiting
[monitor] 2024/04/22 20:47:20 INFO: Syncthing exited: exit status 1
```

Solution: https://stackoverflow.com/a/68959633/9922066

```sh
# Open PowerShell Admin
net stop winnat
net start winnat
```

## 23. Setup Pihole

Dùng pihole để quản lý các request in-out trong mạng gia đình thì Pihole là đủ rồi.  
Tuy nhiên đừng mong chờ dùng pihole để chặn quảng cáo vì sẽ rất khó để nó đạt được những kỳ vọng bạn mong muốn.   
Nó hữu ích khi bạn muốn biết mạng nhà mình truy cập trang web nào nhiều nhất, block các web phim đen để quản lý trẻ em.  
Hoặc khi bạn thấy các thiết bị trong nhà gửi quá nhiều request đến baidu, taobao, tiktok của Trung quốc, muốn chặn thì giao diện Pihole cũng rất dễ dùng.  

Sửa `docker-compose.yml`:  

```yml
version: '3.0'

services:
~~~
  pihole:
    container_name: pihole
    image: pihole/pihole:2023.05.2
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "67:67/udp"
      - "8027:80/tcp"
    environment:
      TZ: 'Asia/Ho_Chi_Minh'
      WEBPASSWORD: XXXXXSUPER_SECUREXXXXX
      FTLCONF_LOCAL_IPV4: 192.168.X.X # local IP of RPi which Pihole running in
    volumes:
      - /opt/pihole/etc-pihole:/etc/pihole
      - /opt/pihole/etc-dnsmasq.d:/etc/dnsmasq.d
    cap_add:
      - NET_ADMIN
    restart: unless-stopped
```

Truy cập vào Pihole Admin: `http://192.168.X.X:8027/admin` đăng nhập với password: XXXXXSUPER_SECUREXXXXX

- Tiếp theo, Nếu muốn chỉ máy của bạn sử dụng Pihole:  
  Hãy Window+R, nhập ncpa.cpl và chuột phải vào Network Connection mà bạn đang sử dụng.  
  Nếu bạn dùng wifi, hãy chuột phải vào Wifi -> Properties -> double click vào TCP/IP v4.   
  Nếu bạn dùng mạng dây, hãy chuột phải vào Ethernet -> Properties -> double click vào TCP/IP v4.  
  Sửa DNS thành 192.168.X.X (trường hợp này: 192.168.1.5) vào đây:  

  ![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/dns-custom-tcp-ip.jpg)

- Nếu muốn cả mạng của ngôi nhà sử dụng Pihole:  
  Hãy truy cập vào Giao diện quản lý router, tìm đến phần Configure DNS, thay bằng IP của Pihole server 192.168.X.X là OK.

Có thể tham khảo thêm bài này: https://tinhte.vn/thread/cach-dung-raspberry-pi-pi-hole-de-chan-quang-cao-cho-tat-ca-thiet-bi-trong-nha.3000792/

Sau khi setup, trên giao diện Pihole UI, cần block 1 số domain mà cái Router XiaoMi của mình hay call đến như: 
miwifi.com, taobao.com, baidu.com...

### 23.1. Có 2 cách setup Pihole

1- là Config Router enable DHCP và trỏ DNS đến IP của Pihole (làm trên Giao diện của Router wifi): https://discourse.pi-hole.net/t/how-do-i-configure-my-devices-to-use-pi-hole-as-their-dns-server/245#1-define-pi-holes-ip-address-as-the-_only_-dns-entry-in-the-router-2
Cách 1 này có nhược điểm là vì tất cả device connect đến Wifi của Router. Trên giao diện Pihole sẽ chỉ thấy các request từ IP/client của Router mà thôi. (caveat 1)

2- là Config Router disable DHCP. Rồi Setup Pihole running được enable DHCP. Chỉ thế là xong. Họ bảo có 1 cái service pihole-FTL run làm DHCP server. Nếu trong mạng chỉ có 1 cái DHCP server (ở đây là Pihole) thì OK, nhưng nếu có 2 cái (1 là Router chưa bị disable DHCP, 2 là Pihole vừa đc enable DHCP) thì sẽ lỗi. (credit: https://discourse.pi-hole.net/t/how-do-i-use-pi-holes-built-in-dhcp-server-and-why-would-i-want-to/3026/33)
Cách này giải quyết được cái nhược điểm của cách 1.
Nhưng người ta không recommend dùng khi Pihole đang run trên 1 cái máy đc expose ra internet. ( Mà cái Pihole của mình đang run trên RPi đặt trong DMZ - nên chắc là thôi 😐 credit: https://discourse.pi-hole.net/t/how-do-i-use-pi-holes-built-in-dhcp-server-and-why-would-i-want-to/3026/29 )
Cần chú ý có người report rằng nếu họ disable DHCP trên Router thì họ bị mất internet: https://discourse.pi-hole.net/t/disabling-dhcp-on-my-router-causes-no-internet-connection/25013/3. Có cách work-around trong post đó luôn.
Cũng có người disable DHCP trên Router thì mất kết nối đến mạng LAN luôn: https://discourse.pi-hole.net/t/at-t-dhcp-times-out-every-2-5-minutes/65636/4


### 23.2. Vấn đề port

Tuy nhiên có 1 vấn đề là mình thấy khi mở port 8027 để vào UI của Pihole, vì server Pihole lại đang để trong DMZ, nên check `canyouseeme.org` sẽ thấy port 8027 đang mở. Không biết làm cách nào để port đó đóng lại như các port khác (3000, 8034, 9090...).  

- Cách 1: đành dùng cách này, sửa `docker-compose.yml`:  

  ```yml
      ports:
        - "53:53/tcp"
        - "53:53/udp"
        - "67:67/udp"
        - "80/tcp"
  ```

  Bao giờ ở nhà cần vào giao diện Pihole thì lại sửa lại file `docker-compose.yml`, restart pihole container để vào được UI. Cách này hơi bất tiện nhưng secure và dễ hiểu.

- Cách 2: Sửa Router, vào NAT, Port forwarding -> add thêm rule để forward traffic vào port 8027 sẽ sang port 8999. Hoặc sang 1 cái IP khác hẳn luôn. Như vậy check lại từ `canyouseeme.org` sẽ ko thấy port 8027,8999 mở ra nữa... haha 🤣 Còn trong mạng local/LAN thì vẫn vào được port 8027. Cách này tuy có hơi **ma giáo** nhưng nó hiệu quả. 

### 23.3. Vấn đề VPN

Do đang redirect các traffic qua DNS của Pihole, nên bạn sẽ ko dùng được Wireguard VPN (OpenVPN thì vẫn OK). Do nhà mình có 2 Wifi Router, mình đang config Pihole DNS trên Router #2 nên nếu muốn dùng Wireguard VPN sẽ phải connect vào Wifi của Router #1. 

### 23.4. Lỗi DNS resolution is currently unavailable

Lỗi `DNS resolution is currently unavailable` xảy ra sau 1 thời gian dài không bị sao:

```
$ docker logs pihole -f
s6-rc: info: service s6rc-oneshot-runner: starting
s6-rc: info: service s6rc-oneshot-runner successfully started
s6-rc: info: service fix-attrs: starting
s6-rc: info: service fix-attrs successfully started
s6-rc: info: service legacy-cont-init: starting
s6-rc: info: service legacy-cont-init successfully started
s6-rc: info: service cron: starting
s6-rc: info: service cron successfully started
s6-rc: info: service _uid-gid-changer: starting
s6-rc: info: service _uid-gid-changer successfully started
s6-rc: info: service _startup: starting
  [i] Starting docker specific checks & setup for docker pihole/pihole
  [i] Setting capabilities on pihole-FTL where possible
  [i] Applying the following caps to pihole-FTL:
        * CAP_CHOWN
        * CAP_NET_BIND_SERVICE
        * CAP_NET_RAW
        * CAP_NET_ADMIN
  [i] Ensuring basic configuration by re-running select functions from basic-install.sh

  [i] Installing configs from /etc/.pihole...
  [i] Existing dnsmasq.conf found... it is not a Pi-hole file, leaving alone!
  [✓] Installed /etc/dnsmasq.d/01-pihole.conf
  [✓] Installed /etc/dnsmasq.d/06-rfc6761.conf

  [i] Installing latest logrotate script...
        [i] Existing logrotate file found. No changes made.
  [i] Assigning password defined by Environment Variable
  [✓] New password set
  [i] Added ENV to php:
                    "TZ" => "Asia/Ho_Chi_Minh",
                    "PIHOLE_DOCKER_TAG" => "",
                    "PHP_ERROR_LOG" => "/var/log/lighttpd/error-pihole.log",
                    "CORS_HOSTS" => "",
                    "VIRTUAL_HOST" => "eaf4efa7580d",
  [i] Using IPv4 and IPv6

  [✓] Installing latest Cron script
  [i] Preexisting ad list /etc/pihole/adlists.list detected (exiting setup_blocklists early)
  [i] Existing DNS servers detected in setupVars.conf. Leaving them alone
  [i] Applying pihole-FTL.conf setting LOCAL_IPV4=192.168.1.128
  [i] FTL binding to default interface: eth0
  [i] Enabling Query Logging
  [i] Testing lighttpd config: Syntax OK
  [i] All config checks passed, cleared for startup ...
  [i] Docker start setup complete

  [i] pihole-FTL (no-daemon) will be started as pihole

s6-rc: info: service _startup successfully started
s6-rc: info: service pihole-FTL: starting
s6-rc: info: service pihole-FTL successfully started
s6-rc: info: service lighttpd: starting
s6-rc: info: service lighttpd successfully started
s6-rc: info: service _postFTL: starting
s6-rc: info: service _postFTL successfully started
s6-rc: info: service legacy-services: starting
  Checking if custom gravity.db is set in /etc/pihole/pihole-FTL.conf
s6-rc: info: service legacy-services successfully started
  [✗] DNS resolution is currently unavailable
```

Solution: https://github.com/pi-hole/docker-pi-hole/issues/342#issuecomment-723449768

### 23.5. Lỗi FTL is not running

Khi truy cập giao diện Pihole thấy quay mãi. Chọn "Query Log" thì thấy lỗi `FTL is not running`.

![](https://b2discourse.pi-hole.net/original/2X/4/4d6d6dd50a10a19157e1210c7658e67f490442bd.png)

Check log thấy:

```
  [i] List stayed unchanged

  [✓] Building tree
  [✓] Swapping databases
  [✓] The old database remains available
  [i] Number of gravity domains: 143280 (143280 unique domains)
  [i] Number of exact blacklisted domains: 0
  [i] Number of regex blacklist filters: 0
  [i] Number of exact whitelisted domains: 0
  [i] Number of regex whitelist filters: 0
/bin/bash: line 1:   237 Hangup                  /usr/bin/pihole-FTL no-daemon > /dev/null 2>&1
  [i] Cleaning up stray matter...Stopping pihole-FTL
  [✓] Cleaning up stray matter
pihole-FTL: no process found
Stopping pihole-FTL
Terminated

  [✓] FTL is listening on port
     [✓] UDP (IPv4)
     [✓] TCP (IPv4)
     [✗] UDP (IPv6)
     [✓] TCP (IPv6)

  [✓] Pi-hole blocking is enabled

  Pi-hole version is v5.17.1 (Latest: v5.17.2)
  AdminLTE version is v5.20.1 (Latest: null)
  FTL version is v5.23 (Latest: v5.23)
  Container tag is: 2023.05.2
```

Solution: Xóa hết folder `/opt/pihole` đi, tạo lại từ đầu.

Log như này là ok:  

```
 [✓] FTL is listening on port 53
     [✓] UDP (IPv4)
     [✓] TCP (IPv4)
     [✓] UDP (IPv6)
     [✓] TCP (IPv6)

  [i] Pi-hole blocking will be enabled
  [i] Enabling blocking
  [✓] Pi-hole Enabled

  Pi-hole version is v5.17.1 (Latest: v5.17.2)
  AdminLTE version is v5.20.1 (Latest: null)
  FTL version is v5.23 (Latest: v5.23)
  Container tag is: 2023.05.2
```

### 23.6. Botnet or DDOS issue: Millions of TXT request from unknown public IP address

Bỗng 1 ngày phát hiện sự lạ, Pihole có rất nhiều query (hàng chục nghìn mỗi phút, hàng triệu chỉ trong vài tiếng)

Vì Pihole quá lag nên phải vào 1 số link trực tiếp:  
http://192.168.1.128:8027/admin/db_lists.php -> Top Lists

http://192.168.1.128:8027/admin/groups-domains.php -> Domains

http://192.168.1.128:8027/admin/groups-adlists.php -> Ad lists

http://192.168.1.128:8027/admin/queries.php -> Query logs

Check logs trên Pihole UI thấy như này: (ảnh)
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/pihole-recent-query-txt-screen.jpg)
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/pihole-network-overview-screen.jpg)
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/pihole-log-live.jpg)
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/pihole-network-screen.jpg)

Trước khi install pihole các port sau đc open qua protocol UDP:

```
$ sudo nmap -sU -p- 192.168.1.128
Starting Nmap 7.80 ( https://nmap.org ) at 2023-10-18 21:42 +07
Nmap scan report for 192.168.1.128
Host is up (0.000041s latency).
Not shown: 65527 closed ports
PORT      STATE         SERVICE
68/udp    open|filtered dhcpc
546/udp   open|filtered dhcpv6-client
5353/udp  open          zeroconf
21027/udp open|filtered unknown
22000/udp open|filtered snapenetio
33714/udp open|filtered unknown
33908/udp open|filtered unknown
51820/udp open|filtered unknown

$ sudo iptables -L -v -n | more
Chain DOCKER (2 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.13          tcp dpt:443
    6  1056 ACCEPT     udp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.2           udp dpt:51820
    0     0 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.3           tcp dpt:8080
    0     0 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.4           tcp dpt:9001
    9   468 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.4           tcp dpt:1883
    0     0 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.5           tcp dpt:8086
    0     0 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.6           tcp dpt:5432
    2   104 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.8           tcp dpt:22000
   97  9312 ACCEPT     udp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.8           udp dpt:22000
    0     0 ACCEPT     udp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.8           udp dpt:21027
    0     0 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.8           tcp dpt:8384
    0     0 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.10          tcp dpt:9090
   40  2120 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.11          tcp dpt:3000
```

Sau khi install pihole các port sau đc open qua protocol UDP:

```
$ sudo nmap -sU -p- 192.168.1.128
Starting Nmap 7.80 ( https://nmap.org ) at 2023-10-18 21:48 +07
Nmap scan report for 192.168.1.128
Host is up (0.000042s latency).
Not shown: 65526 closed ports
PORT      STATE         SERVICE
53/udp    open|filtered domain
68/udp    open|filtered dhcpc
546/udp   open|filtered dhcpv6-client
5353/udp  open          zeroconf
21027/udp open|filtered unknown
22000/udp open|filtered snapenetio
33714/udp open|filtered unknown
33908/udp open|filtered unknown
51820/udp open|filtered unknown

Nmap done: 1 IP address (1 host up) scanned in 17.90 seconds

$ sudo iptables -L -v -n | more
Chain DOCKER (2 references)
 pkts bytes target     prot opt in     out     source               destination
    0     0 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.13          tcp dpt:443
    6  1056 ACCEPT     udp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.2           udp dpt:51820
    0     0 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.3           tcp dpt:8080
    0     0 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.4           tcp dpt:9001
    9   468 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.4           tcp dpt:1883
    0     0 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.5           tcp dpt:8086
    0     0 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.6           tcp dpt:5432
    2   104 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.8           tcp dpt:22000
   97  9312 ACCEPT     udp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.8           udp dpt:22000
    0     0 ACCEPT     udp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.8           udp dpt:21027
    0     0 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.8           tcp dpt:8384
    0     0 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.10          tcp dpt:9090
   40  2120 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.11          tcp dpt:3000
    0     0 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.12          tcp dpt:80
    0     0 ACCEPT     tcp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.12          tcp dpt:53
   34  2054 ACCEPT     udp  --  !br-7593419e3462 br-7593419e3462  0.0.0.0/0            172.18.0.12          udp dpt:53

```

=> pihole đã mở thêm port 53. Mặc dù check trên `https://canyouseeme.org/` hoặc `https://www.yougetsignal.com/` đều thấy port 53 đang closed.

Thậm chí mình phải lập 1 thread trên form pihole để hỏi: https://discourse.pi-hole.net/t/pihole-handle-too-many-txt-query-from-dynamic-public-ip-address/65653

Khá chắc là con Pihole hoặc con XiaoMi Router của mình đã bị sử dụng để làm botnet: https://www.cloudflare.com/learning/ddos/dns-amplification-ddos-attack/

Sau khi mình đăng bài thì đến hôm sau các query đến TXT và các client IP lạ hoắc kia tự nhiên biến mất. Có thể chúng đã phát hiện ra và tắt botnet đi chăng?.

Nhưng mình vẫn băn khoăn ko hiểu vì sao chúng lại khai thác được. Có 2 khả năng, 1 là do Pihole 2 là do Router Xiaomi.

Note lại các cách debug nếu gặp lại chuyện này:  

- Tái hiện lỗi -> Nếu vẫn bị thì làm tiếp các step sau.  

- Trên Giao diện Pihole -> Settings -> DNS -> Check "Allow only local requests" -> Save. (Chú ý ấn nút Save). Check xem Pihole có còn sinh ra các query TXT liên tục nữa ko? (credit: 
https://github.com/pi-hole/pi-hole/issues/3426).  
Có lẽ do mình chưa ấn nút Save nên Kết quả sau 1 đêm có vẻ ko đúng lắm: là qua 1 đêm vẫn có các active client lạ hoắc call đến: 
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/pihole-network-strange2-screen.jpg).  
Nhưng nếu mình có ấn nút Save thì sau đó sẽ bị 1 lỗi là: Từ các device (laptop, phones) khi connect vào wifi sẽ bị mất Internet. Có lẽ là do cơ chế chỉ "allow only local requests" sẽ chỉ cho phép các request từ bản thân pihole mà thôi, hoặc request từ Router call đến mà thôi. Chứ các request từ các thiết bị connect đến wifi của Router thì Pihole ko coi là local devices, nên nó block luôn => Túm lại cách này ko ổn trong setup nhà mình. 

- Tìm cách dùng iptables của RPi, block các traffic inbound đi qua port 53 vào local, mình đã phải đọc bài này để làm [này](../../posts/encrypt-setup-home-assistant-on-raspberry-pi-p5-restore/#6-setup-c%C3%A1c-iptable-rules-%C4%91%E1%BB%83-ch%E1%BA%B7n-connect-n%E1%BA%BFu-rpi-%C4%91ang-trong-dmz): 

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

  Đề phòng sau khi reboot RPi sẽ thấy iptable lại bị reset, mất hết các rules vừa set, Nên cần save rule bằng command sau:  

  ```sh
  sudo apt-get install iptables-persistent
  sudo netfilter-persistent save
  sudo netfilter-persistent reload
  ```

  **Cần confirm hết các app sau đều hoạt động bình thường: Duplicati (test connection S3 works), HASS, Alexa ra lệnh qua giọng nói control smart devices, Pokemon Go, Efootball24 on Steam, Syncthing (sync 2 chiều giữa nhiều devices: IOS, Android, PC), Wireguard, `/var/log/syslog` không có nhiều lỗi liên quan DNS.**

- Trong lúc confirm thì có 1 số lỗi là điện thoại Android LG G6 của mình thông qua Wifi_5G (đã setup Pihole), thì ko connect được đến syncthing để sync data. Dù open port 22000/tcp/udp, 21027/udp các kiểu cũng ko ăn thua. Re-add các rule debug `LOG_ACCEPT` và `LOG_DROP`, Check log `tail -200f /var/log/messages | grep "DST=172.18.0.8"` (172.18.0.8 là port trong Docker của Syncthing) thì thấy không có DROP packages nào. Check log syncthing thì thấy timeout:

  ```
  [VICCQ] 2023/10/19 21:52:46 INFO: Connection to QPNP76O-OQ3LAOB-P7ANZII-S7VCTAP-3KHS37K-7VCKLSX-XL2FTG2-SQ2SGQ6 at 172.18.0.8:22000-192.168.1.5:22000/tcp-client/TLS1.3-TLS_CHACHA20_POLY1305_SHA256/WAN-P30 closed: read timeout
  ``` 

  => Solution: mình cần phải vào setting của Syncthing trên Android, edit cái Remote Devices (RPi Hub mà mình đang sync data lên): Edit -> Advanced -> Addresses: điền `tcp://192.168.X.Y:22000` (ip của RPi) -> Save. Thế là tự nhiên sẽ sync được data như bình thường.
  
- Khi bạn setup DNS server là RPi thì, trên RPi nên trỏ DNS về localhost: Bạn nên sửa file này: `/etc/resolv.conf`, bỏ cái `192.168.1.1` đi: 

  ```sh
  # Generated by resolvconf
  nameserver localhost
  nameserver 192.168.1.128
  nameserver 8.8.8.8
  ```

  Hoặc sửa file: `/etc/resolvconf.conf`:  
  
  ```
  # Configuration for resolvconf(8)
  # See resolvconf.conf(5) for details

  resolv_conf=/etc/resolv.conf
  # If you run a local name server, you should uncomment the below line and
  # configure your subscribers configuration files below.
  name_servers="192.168.1.128 8.8.8.8"

  # Mirror the Debian package defaults for the below resolvers
  # so that resolvconf integrates seemlessly.
  dnsmasq_resolv=/var/run/dnsmasq/resolv.conf
  pdnsd_conf=/etc/pdnsd.conf
  unbound_conf=/etc/unbound/unbound.conf.d/resolvconf_resolvers.conf
  ```

  rồi run command: `sudo resolvconf -u`. Check lại file `/etc/resolv.conf` xem đã được update chưa.

- Trong lúc test `tail -n 20 /var/log/syslog` thấy có 1 lỗi timeout ở đây:

  ```
  # tail -n 20 /var/log/syslog
  Oct 21 12:42:06 raspberrypi dockerd[617]: time="2023-10-21T12:42:06.655775908+07:00" level=error msg="[resolver] failed to query DNS server: 192.168.1.1:53, query: ;www.duckdns.org.\tIN\t AAAA" error="read udp 172.18.0.9:38058->192.168.1.1:53: i/o timeout"
  Oct 21 12:42:06 raspberrypi dockerd[617]: time="2023-10-21T12:42:06.655800649+07:00" level=error msg="[resolver] failed to query DNS server: 192.168.1.1:53, query: ;www.duckdns.org.\tIN\t A" error="read udp 172.18.0.9:60765->192.168.1.1:53: i/o timeout"
  ```

  Nguyên nhân có lẽ là do DuckDNS container đang trỏ đến IP của Router 192.168.1.1 để làm DNS server. 
  Check log lỗi của duckdns:  

  ```
  # docker logs duckdns
  [cont-init.d] 10-adduser: exited 0.
  [cont-init.d] 40-config: executing...
  Retrieving subdomain and token from the environment variables
  log will be output to file
  Your IP was updated at Wed Oct 18 15:47:41 +07 2023
  [cont-init.d] 40-config: exited 0.
  [cont-init.d] 90-custom-folders: executing...
  [cont-init.d] 90-custom-folders: exited 0.
  [cont-init.d] 99-custom-files: executing...
  [custom-init] no custom files found exiting...
  [cont-init.d] 99-custom-files: exited 0.
  [cont-init.d] done.
  [services.d] starting services
  [services.d] done.
  curl: (6) Could not resolve host: www.duckdns.org
  curl: (6) Could not resolve host: www.duckdns.org
  curl: (6) Could not resolve host: www.duckdns.org
  curl: (6) Could not resolve host: www.duckdns.org
  curl: (6) Could not resolve host: www.duckdns.org
  curl: (6) Could not resolve host: www.duckdns.org
  curl: (6) Could not resolve host: www.duckdns.org
  curl: (6) Could not resolve host: www.duckdns.org
  curl: (6) Could not resolve host: www.duckdns.org
  ```
  => Solution: Bạn cần set DNS server của DuckDNS container lại là `8.8.8.8` để nó có thể chạy được. sửa file `docker-compose.yml`:  
  
  ```yml
  duckdns:
    image: lscr.io/linuxserver/duckdns:68a3222a-ls97
    container_name: duckdns
    dns:
      - 8.8.8.8
    ....
  ```

- Check RPi `tail -n 20 /var/log/syslog`, nếu còn có mấy lỗi kiểu này: 

  ```
  Oct 19 22:55:31 raspberrypi dockerd[617]: time="2023-10-19T22:55:31.578450441+07:00" level=error msg="[resolver] failed to query DNS server: 192.168.1.1:53, query: ;cadvisor.\tIN\t A" error="read udp 172.18.0.10:56690->192.168.1.1:53: i/o timeout"
  Oct 19 22:55:31 raspberrypi dockerd[617]: time="2023-10-19T22:55:31.578954696+07:00" level=error msg="[resolver] failed to query DNS server: 192.168.1.1:53, query: ;cadvisor.\tIN\t AAAA" error="read udp 172.18.0.10:47255->192.168.1.1:53: i/o timeout"
  ```

  Đây là do DNS server của container `172.18.0.10 (Prometheus)` đang trỏ về 192.168.1.1, nếu bạn vẫn dùng cadvisor thì nên set lại dns cho container prometheus (giống như vừa làm bên trên với duckdns). Vì mình ko dùng cdavisor nữa nên chỉ cần bỏ setting gửi data từ prometheus về cdavisor là đủ (sửa file `prometheus.yml` đoạn `targets`)

...DONE, đã fix được lỗi về port 53. 😁

Bên dưới là các Debug mà không có nhiều tác dụng fix Issue chính, nên mình chỉ note lại:  


- (Chưa hiểu) Tìm hiểu về cái này để test xem Wireguard có đang bị DNS leak hay ko: https://docs.pi-hole.net/guides/vpn/wireguard/client/#test-for-dns-leaks

- (Chưa thử) Trên Giao diện con Router Xiaomi bỏ setting DNS đang đến Pihole (RPi). Check xem Pihole có còn sinh ra các query TXT liên tục nữa ko?  

- (Chưa thử) Trên Giao diện Router chính, thử lần lượt close các port như 80, 8123, 8027, 8099 xem sao. Có còn các request TXT liên tục ko? (vì đây là các port mình đang mở, port 443 thì thôi ko cần)  

- (Chưa thử) Trong `docker-compose.yml` file, thử map port `5312:53` xem, đại khái là ko sử dụng port 53 đến map ra ngoài nữa mà map 1 port random như 5312.

- (Chưa thử) Trong `docker-compose.yml` file, chỗ `ports` của pihole, ko open port `8027:80` nữa:
  ```
    pihole:
    ....
      ports:
        - "53:53/tcp"
        - "53:53/udp"
        # - "67:67/udp"
        # - "8027:80/tcp"
    ....
  ```
  Như này sẽ ko có cách nào xem được giao diện Pihole nên đành chờ 1 lúc rồi revert lại check xem trong thời gian đó có các query TXT liên tục nữa ko? 

- (Chưa thử) Trong `docker-compose.yml` file, chỗ `ports` của pihole, ko open port `8027` nữa:
  ```
    pihole:
    ....
      ports:
        - "53:53/tcp"
        - "53:53/udp"
        # - "67:67/udp"
        - "80/tcp"
    ....
  ```
  Như này thì Pihole sẽ tự map 1 port random ví dụ:
  ```
  CONTAINER ID   IMAGE                                            COMMAND                  CREATED         STATUS                           PORTS                                                                                                                                                                                    NAMES
  8bb26095f77f   pihole/pihole:2023.05.2                          "/s6-init"               3 seconds ago   Up 1 second (health: starting)   0.0.0.0:53->53/tcp, 0.0.0.0:53->53/udp, :::53->53/tcp, :::53->53/udp, 67/udp, 0.0.0.0:32768->80/tcp, :::32768->80/tcp
  ```
  Thử vào Pihole UI ở port 32768 để xem có còn các request TXT liên tục ko?

CREDIT của riêng phần Pihole này:

Đọc comment này, nói về việc cần block traffic UDP: https://www.reddit.com/r/OPNsenseFirewall/comments/hm5g0k/comment/fx5hmp9/?utm_source=share&utm_medium=web2x&context=3

1 comment nói về việc public pihole port 53 sẽ làm Router cũng expose port 53 và ng khác sẽ dùng Pihole của bạn làm DNS server: https://www.reddit.com/r/pihole/comments/5g249i/comment/jojgnge/?utm_source=share&utm_medium=web2x&context=3

## 24. Setup Smart switch Aqara D1

### 24.1. Công tắc cũ 2 nút -> Aqara D1 2 nút

khá dễ...

### 24.2. Công tắc cũ 3 nút (nhưng chỉ dùng 2) -> Aqara D1 2 nút

Công tắc khu Phòng khách cũ của mình như này, 3 nút nhưng thực tế chỉ dùng 2 nút

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/swtich-old-style-3gang.jpg)

Thế nên mình mua Aqara D1 switch 2 gang về lắp sang

Sơ đồ như này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/setup-old-3gang-to-new-aqara-d1-2gang.jpg)

Công tắc mình dùng loại này, mua ở Smarthomekit.vn:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aqara-d1-2gang-no-neutral.jpg)

### 24.3. How to pair with Zigbee2mqtt

Vào UI của Zigbee2mqtt -> Permit join All

Ấn lì 5s 1 nút bất kỳ trên công tắc

Trên UI sẽ thấy device connect đến và xoay...chờ xoay xong

Đổi tên, vào HomeAssistant -> Device -> Check điều khiển được là OK

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
Syncthing: https://www.youtube.com/watch?v=02XeIATCDO4&ab_channel=ApkHeaven  
Node-exporter directory size: https://www.robustperception.io/monitoring-directory-sizes-with-the-textfile-collector/  
https://github.com/prometheus-community/node-exporter-textfile-collector-scripts/blob/master/directory-size.sh  
Check open port: https://www.yougetsignal.com/tools/open-ports/   
Hướng dẫn deny all traffic incoming (inbound), và allow traffic outgoing (outbound): https://superuser.com/questions/427458/deny-all-incoming-connections-with-iptables  
