---
title: "Connect Home Assistant Container to Xiaomi Air Purifier3H"
date: 2022-05-01T22:52:01+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [HomeAssistant]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Bài này mình hướng dẫn cả 2 cách: 1 là dùng custom component, 2 là dùng Miio Integration"
---

Làm theo 1 số hướng dẫn trên mạng để Connect Mi Air Purifier 3H đến HASS thường bị lỗi:  
`platform: xiaomi_miio` ko còn được HASS support, timeout khi connect. Cuối cùng mình đã tìm được cách để làm được.
Đó là dùng custom component của Github này: https://github.com/syssi/xiaomi_airpurifier/custom_components/

Tuy nhiên sau khoảng 3 tháng sử dụng, mình thấy trình độ tăng lên,  
mình phát hiện ra có 1 lỗi là ko thể setup được LED Brightness.

Và mình tìm được 1 cách nữa là dùng Miio Integration còn OK hơn. Và ưu điểm hơn là ko cần nhập token vào file `configuration.yml`

Bài này mình hướng dẫn cả 2 cách: 1 là dùng custom component, 2 là dùng Miio Integration

# 1. Cách 1: Dùng custom component

## 1.1. Setup

Cài đặt app `MiHome` latest trên Androids, đăng ký, pair nó với `Air Purifier 3H` của bạn (ấn đồng thời nút bấm sau máy với nút cảm ứng, chờ đến khi 3 tiếng bíp liên tiếp). Trên App `MiHome` login vào wifi 2.4Ghz. Add thiết bị vào, đổi tên thiết bị thành `Mi Air Purifier 33H`. Hãy đảm bảo pair thành công nhé!

Note: *1 số bài viết bảo bạn lấy token bằng cách cài đặt apk version cũ (5.4.49) của Mi Home thì mình thử đều ko được, có lẽ cách đấy ko còn phù hợp nữa rồi, hãy cài version latest luôn*

Trên máy Windows, download exe sau về: `https://github.com/PiotrMachowski/Xiaomi-cloud-tokens-extractor/releases/latest/download/token_extractor.exe`

Run file exe trên, nhập user/pass của MiHome app, bạn sẽ thấy token của thiết bị Air Purifier trong mạng của bạn, note lại `token` và `model`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/token_extractor_exe.jpg)  

Copy folder `https://github.com/syssi/xiaomi_airpurifier/custom_components/xiaomi_miio_airpurifier` vào `/opt/hass/config/custom_components`  

-> restart HASS

edit file `/opt/hass/config/configuration.yaml`:   
```yaml
...
fan:
  - platform: xiaomi_miio_airpurifier
    name: Bedroom Air Purifier 3H
    host: 192.168.1.9
    token: d5xxxxxxxxxxxxxxxxxxxa
    model: zhimi.airpurifier.mb3
```
-> restart HASS

Vào HASS -> Configuration -> Devices&Services -> Entities:   
Sẽ thấy entity của `Mi Air Purifier` xuất hiện.  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-entity-mi-air-purifier-3h.jpg)  

Check log của HASS ko có lỗi gì là OK (Có thể có warning thì ko sao)

Create `opt/hass/config/packages/xiaomi_bedroom_airpurifier.yaml`
```yaml
###FIND & REPLACE ALL bedroom_air_purifier_3h with your entity NAME###
sensor:
  - platform: template
    sensors:
      bedroom_air_purifier_3h_temp:
        friendly_name: "Temperature"
        value_template: "{{ state_attr('fan.bedroom_air_purifier_3h', 'temperature') }}"
        unit_of_measurement: "°C"
        device_class: "temperature"
      bedroom_air_purifier_3h_humidity:
        friendly_name: "Humidity"
        value_template: "{{ state_attr('fan.bedroom_air_purifier_3h', 'humidity') }}"
        unit_of_measurement: "%"
        device_class: "humidity"
      bedroom_air_purifier_3h_air_quality_pm25:
        friendly_name: "Air quality"
        value_template: "{{ state_attr('fan.bedroom_air_purifier_3h', 'aqi') }}"
        unit_of_measurement: "μg/m³"
        icon_template: "mdi:weather-fog"
      bedroom_air_purifier_3h_speed:
        friendly_name: "Fan speed"
        value_template: "{{ state_attr('fan.bedroom_air_purifier_3h', 'motor_speed') }}"
        unit_of_measurement: "rpm"
        icon_template: "mdi:speedometer"
      bedroom_air_purifier_3h_filter_remaining:
        friendly_name: "Filter remaining"
        value_template: "{{ state_attr('fan.bedroom_air_purifier_3h', 'filter_life_remaining') }}"
        unit_of_measurement: "%"
        icon_template: "mdi:heart-outline"

switch:
  - platform: template
    switches:
      bedroom_air_purifier_3h_led:
        friendly_name: "LED"
        value_template: "{{ is_state_attr('fan.bedroom_air_purifier_3h', 'led', true) }}"
        turn_on:
          service: xiaomi_miio_airpurifier.fan_set_led_on
          data:
            entity_id: fan.bedroom_air_purifier_3h
        turn_off:
          service: xiaomi_miio_airpurifier.fan_set_led_off
          data:
            entity_id: fan.bedroom_air_purifier_3h
        icon_template: "mdi:lightbulb-outline"

      bedroom_air_purifier_3h_child_lock:
        friendly_name: "Children lock"
        value_template: "{{ is_state_attr('fan.bedroom_air_purifier_3h', 'child_lock', true) }}"
        turn_on:
          service: xiaomi_miio_airpurifier.fan_set_child_lock_on
          data:
            entity_id: fan.bedroom_air_purifier_3h
        turn_off:
          service: xiaomi_miio_airpurifier.fan_set_child_lock_off
          data:
            entity_id: fan.bedroom_air_purifier_3h
        icon_template: "mdi:lock-outline"

      bedroom_air_purifier_3h_buzzer:
        friendly_name: "Buzzer"
        value_template: "{{ is_state_attr('fan.bedroom_air_purifier_3h', 'buzzer', true) }}"
        turn_on:
          service: xiaomi_miio_airpurifier.fan_set_buzzer_on
          data:
            entity_id: fan.bedroom_air_purifier_3h
        turn_off:
          service: xiaomi_miio_airpurifier.fan_set_buzzer_off
          data:
            entity_id: fan.bedroom_air_purifier_3h
        icon_template: "mdi:volume-high"
  
input_select:
  bedroom_air_purifier_3h_mode:
    name: Mode
    initial: Fan
    options:
      - Auto
      - Silent
      - Favorite
      - Fan
    icon: "mdi:animation-outline"

input_number:
  bedroom_air_purifier_3h_fan_level:
    name: "Fan level"
    initial: 1
    min: 1
    max: 3
    step: 1
    icon: "mdi:weather-windy"

automation:
    - id: '9231979hoangmnsd231298'
      alias: Bedroom Air Purifier mode change
      trigger:
        entity_id: input_select.bedroom_air_purifier_3h_mode
        platform: state
      action:
        service: fan.set_preset_mode
        data_template:
          entity_id: fan.bedroom_air_purifier_3h
          preset_mode: '{{ states.input_select.bedroom_air_purifier_3h_mode.state }}'

    - id: '3467979hoangmnsd2365698'
      alias: Bedroom Air Purifier fan level change
      trigger:
        entity_id: input_number.bedroom_air_purifier_3h_fan_level
        platform: state
      action:
        service: xiaomi_miio_airpurifier.fan_set_fan_level
        data_template:
          entity_id: fan.bedroom_air_purifier_3h
          level: '{{ states.input_number.bedroom_air_purifier_3h_fan_level.state | int }}'

```

edit file `opt/hass/config/configuration.yaml`:  
```yaml
...
homeassistant:
  packages: !include_dir_named packages
```

-> restart HASS

Lên giao diện HASS, edit Dashboard -> add Card manual, paste đoạn code sau:  
```yaml
type: horizontal-stack
cards:
  - type: entities
    title: Bedroom Air Purifier 3H
    show_header_toggle: false
    entities:
      - entity: fan.bedroom_air_purifier_3h
        name: Power
      # Only display Mode when Power is not on state
      - type: conditional
        conditions:
          - entity: fan.bedroom_air_purifier_3h
            state: "on"
        row: 
          entity: input_select.bedroom_air_purifier_3h_mode
      - entity: switch.bedroom_air_purifier_3h_child_lock
      - entity: switch.bedroom_air_purifier_3h_led
      - entity: switch.bedroom_air_purifier_3h_buzzer
      # Only display Fan level when Power is ON state
      - type: conditional
        conditions:
          - entity: fan.bedroom_air_purifier_3h
            state: "on"
        row: 
          entity: input_number.bedroom_air_purifier_3h_fan_level
      - entity: sensor.bedroom_air_purifier_3h_speed
      - entity: sensor.bedroom_air_purifier_3h_filter_remaining
  - type: vertical-stack
    cards:
      - entities:
          - entity: sensor.bedroom_air_purifier_3h_air_quality_pm25
          - entity: sensor.bedroom_air_purifier_3h_temp
          - entity: sensor.bedroom_air_purifier_3h_humidity
        show_header_toggle: false
        theme: default
        title: Bedroom Env
        type: entities
      - entities:
          - sensor.bedroom_air_purifier_3h_air_quality_pm25
        hours_to_show: 24
        refresh_interval: 60
        title: Bedroom Air quality
        type: history-graph

```
Save và quay lại thử điều khiển xem sao. Check log ko có lỗi ERROR là OK:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-dashboard-mi-air.jpg)  

# 1.2. Set các Automations

## 1.2.1. Bật tắt theo giờ

Edit file `opt/hass/config/automations.yaml`:  
```yaml
# Bedroom Air Purifier On Off on Time
- id: '15914324182184740'
  alias: Bedroom Air Purifier On Off on Time
  description: Turn on/off Bedroom Air Purifier on schedule
  trigger:
  - at: '01:00:00'
    platform: time
  - at: '07:00:00'
    platform: time
  condition: []
  action:
  - data: {}
    entity_id: fan.bedroom_air_purifier_3h
    service_template: >
      {% if trigger.now.hour == 1 %}
      fan.turn_on
      {% elif trigger.now.hour == 7 %}
      fan.turn_off
      {% else %}
      fan.turn_off
      {% endif %}
```
Automation tự động trigger vào 2 thời điểm là 1h sáng và 6h sáng. Tự động bật nếu là 1h sáng. Tự động tắt nếu là 6h sáng.

## 1.2.2. Gửi thông báo khi AQI quá cao

Edit file `opt/hass/config/automations.yaml`: 
```yaml
# Bedroom Air Purifier AQI over 80 Warning
- id: '1591183075585'
  alias: Bedroom Air Purifier AQI over 80 Warning
  description: Notify to Telegram when Bedroom Air Purifier AQI over 80
  trigger:
  - platform: template
    value_template: '{{ state_attr(''fan.bedroom_air_purifier_3h'',''aqi'')| int(0) > 80 }}'
  condition: []
  action:
  - data_template:
      message: 'Becareful, right now AQI = {{state_attr(''fan.bedroom_air_purifier_3h'',''aqi'')}}'
      title: '♨️ Home Assistant: Bedroom AQI is too high!'
    service: telegram_bot.send_message

```
Có thể bạn sẽ tự hỏi khi nào Automation trên được trigger lần thứ 2. Câu trả lời là:
> The Template Trigger’s template will be evaluated every time the sensor’s value changes

Nghĩa là khi nào AQI thay đổi từ 80 sang số khác thì Automation trên mới được trigger lần thứ 2

source: https://community.home-assistant.io/t/trigger-template-will-it-keep-firing/325009/7


## 1.2.3. Gửi thông báo khi lõi lọc hết thời gian sử dụng

Edit file `opt/hass/config/automations.yaml`: 
```yaml
# Bedroom Air Purifier Filter lifetime Warning
- id: '1591183684060'
  alias: Bedroom Air Purifier Filter lifetime Warning
  description: Bedroom Air Purifier Low Filter Life Notify 5%
  trigger:
  - platform: template
    value_template: '{{ state_attr(''fan.bedroom_air_purifier_3h'',''filter_life_remaining'')| int(30) < 6 and state_attr(''fan.bedroom_air_purifier_3h'',''filter_life_remaining'')| int(30) > 0 }}'
  condition: []
  action:
  - data_template:
      message: >-
        Your filter remaining is {{state_attr(trigger.entity_id,'filter_life_remaining')}}% 
      title: '😓 Home Assistant: Air Purifier 3H filter remain warning'
    service: telegram_bot.send_message
```

Có thể bạn sẽ tự hỏi khi nào Automation trên được trigger lần thứ 2. Câu trả lời là:
> The Template Trigger’s template will be evaluated every time the sensor’s value changes

Nghĩa là khi nào Filter remaning thay đổi từ 5 sang số khác thì Automation trên mới được trigger lần thứ 2

source: https://community.home-assistant.io/t/trigger-template-will-it-keep-firing/325009/7


# 2. Cách 2: Dùng Xiaomi Miio Integration (Recommended)

## 2.1. Setup 

Cài đặt app `MiHome` latest trên Androids, đăng ký, pair nó với `Air Purifier 3H` của bạn (ấn đồng thời nút bấm sau máy với nút cảm ứng, chờ đến khi 3 tiếng bíp liên tiếp). Trên App `MiHome` login vào wifi 2.4Ghz. Add thiết bị vào, đổi tên thiết bị thành `Mi Air Purifier 33H`. Hãy đảm bảo pair thành công nhé!

Vào Setting -> Devices,Intergration -> Add Integration -> Search Miio:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/air-purifier-miio-integration.jpg)

Nhập User/password mà các bạn đã đăng ký tài khoản bên trên

Nó sẽ tự động tìm các devices có trong account của bạn

Hiện như này là OK:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/air-purifier-miio-integration-devices.jpg)

Vẫn cần tạo file này để tạo entity:  
`/opt/hass/config/packages/xiaomi_bedroom_airpurifier.yaml`
```yml
input_select:
  bedroom_air_purifier_3h_mode:
    name: Mode
    initial: Fan
    options:
      - Auto
      - Silent
      - Favorite
      - Fan
    icon: "mdi:animation-outline"
```

`configurations.yml`:  
```yml
homeassistant:
  packages: !include_dir_named packages
```

Dashboard của bạn sẽ có code như này:
```yml
# using Miio Integration
  - type: entities
    title: Air Purifier 33H
    show_header_toggle: false
    entities:
      - entity: fan.mi_air_purifier_33h
        name: Power
      - type: conditional
        conditions:
          - entity: fan.mi_air_purifier_33h
            state: 'on'
        row:
          entity: input_select.bedroom_air_purifier_3h_mode
          name: Mode
      - entity: switch.mi_air_purifier_33h_child_lock
        name: Child lock
      - entity: select.mi_air_purifier_33h_led_brightness
        name: Led
      - entity: switch.mi_air_purifier_33h_buzzer
        name: Buzzer
      - type: conditional
        conditions:
          - entity: fan.mi_air_purifier_33h
            state: 'on'
        row:
          entity: number.mi_air_purifier_33h_fan_level
          name: Fan level
      - entity: sensor.mi_air_purifier_33h_motor_speed
        name: Motor speed
      - entity: sensor.mi_air_purifier_33h_filter_life_remaining
        name: Filter Life remaining
```

file `automations.yml` cần add thêm cái này:  
```yml
# Bedroom Air Purifier change mode 
# (Because Miio Integration doesn't provide set_mode entity, so...
# this automation help to set mode when `input_select.bedroom_air_purifier_3h_mode` is updated )
- id: '9hoangmnsd231979231298'
  alias: Bedroom Air Purifier mode change
  trigger:
    entity_id: input_select.bedroom_air_purifier_3h_mode
    platform: state
  action:
    service: fan.set_preset_mode
    data_template:
      entity_id: fan.mi_air_purifier_33h
      preset_mode: '{{ states.input_select.bedroom_air_purifier_3h_mode.state }}'
```

Các Automations khác thì cũng cần sửa vì cách lấy attributes khác nhau:  
`automations.yml`  
```yml
# Bedroom Air Purifier On Off on Time
- id: '1hoangmnsd5914324182184740'
  alias: Bedroom Air Purifier On Off on Time
  description: Turn on/off Bedroom Air Purifier on schedule
  trigger:
  - at: '23:30:00'
    platform: time
  - at: '07:00:00'
    platform: time
  condition: []
  action:
  - data: {}
    entity_id: fan.mi_air_purifier_33h
    service_template: >
      {% if trigger.now.hour == 23 %}
      fan.turn_on
      {% elif trigger.now.hour == 7 %}
      fan.turn_off
      {% else %}
      fan.turn_off
      {% endif %}


# Bedroom Air Purifier AQI over 80 Warning
- id: '1hoangmnsd591183075585'
  alias: Bedroom Air Purifier AQI over 80 Warning
  description: Notify to Telegram when Bedroom Air Purifier AQI over 80
  trigger:
  - platform: template
    value_template: '{{ states(''sensor.mi_air_purifier_33h_pm2_5'')| int(0) > 80 }}'
  condition: []
  action:
  - data_template:
      target: 
      - 1xxxxxxx3
      message: 'Becareful, right now AQI = {{states(''sensor.mi_air_purifier_33h_pm2_5'')}}'
      title: '♨️ HASS: Bedroom AQI is too high!'
    service: telegram_bot.send_message


# Bedroom Air Purifier Filter lifetime Warning
- id: '1591183684060'
  alias: Bedroom Air Purifier Filter lifetime Warning
  description: Bedroom Air Purifier Low Filter Life Notify 5%
  trigger:
  - platform: template
    value_template: '{{ states(''sensor.mi_air_purifier_33h_filter_life_remaining'')| int(30) < 6 and states(''sensor.mi_air_purifier_33h_filter_life_remaining'')| int(30) > 0 }}'
  condition: []
  action:
  - data_template:
      target: 
      - 1xxxxxxx3
      message: >-
        Your filter remaining is {{states('sensor.mi_air_purifier_33h_filter_life_remaining')}}%
      title: '😓 HASS: Air Purifier 3H filter remain warning'
    service: telegram_bot.send_message
```

Xong rồi, Cách này sẽ nhẹ nhàng hơn, mình thấy dễ hơn nhiều


# 3. Trouble shooting

## 3.1. Lỗi timeout

Quá trình theo dõi có thể xuất hiện 1 số log WARNING như này:

```
2022-05-02 18:45:21 WARNING (MainThread) [homeassistant.components.input_select] Invalid option: None (possible options: Auto, Silent, Favorite, Fan)

2022-05-03 04:19:35 WARNING (MainThread) [homeassistant.helpers.template] Template warning: 'int' got invalid input 'None' when rendering template '{{ state_attr('fan.bedroom_air_purifier_3h','filter_life_remaining')|int < 6 and state_attr('fan.bedroom_air_purifier_3h','filter_life_remaining')|int > 0 }}' but no default was specified. Currently 'int' will return '0', however this template will fail to render in Home Assistant core 2022.1

2022-05-03 11:47:20 WARNING (MainThread) [homeassistant.helpers.entity] Update of fan.bedroom_air_purifier_3h is taking over 10 seconds

2022-05-03 16:15:41 ERROR (SyncWorker_5) [miio.miioprotocol] Got error when receiving: timed out
...
```
- Thì mình đã thử fix trong các đoạn code bên trên, Chỉ display Mode select khi mà Power đang ở state `on`  
- Thêm các giá trị default khi so sánh giá trị `int`, bằng syntax `int(30) < 6`: có thể hiểu nếu ko có giá trị thì code sẽ lấy default là `30` để so sánh với `6`  
- Đang chờ xem các log lỗi/warning trên có xuất hiện nữa hay ko....

## 3.2. Lỗi user ack timeout

```
2024-01-26 21:27:19.078 ERROR (SyncWorker_4) [miio.miioprotocol] Got error when receiving: {'code': -9999, 'message': 'user ack timeout'}
```

Đôi khi bị lỗi này, dù có delete integration đi và add lại thì cũng vẫn bị lỗi. 

Solution: 
- Reset lại device, ấn cùng lúc nút cảm ứng + nút vật lý đằng sau.  
- Vào app Mi Home delete device và add lại. Vào device accept các điều kiện, etc...  

# 4. Tham khảo

1 bài viết cho rằng không nên sử dụng chế độ `Auto` của Air Purifier:  
https://smartairfilters.com/en/blog/data-explains-never-use-purifiers-auto-mode/

# CREDIT 

https://konnected.vn/home-assistant/home-assistant-tich-hop-may-loc-khong-khi-xiaomi-2020-06-03  
https://thesmarthomejourney.com/2021/06/28/smart-fan-with-home-assistant/  
https://github.com/syssi/xiaomi_airpurifier  
https://mic22.medium.com/how-to-get-token-of-xiaomi-air-purifier-h3-oct-2020-47d0f02451c3  
https://github.com/PiotrMachowski/Xiaomi-cloud-tokens-extractor/releases/latest/download/token_extractor.exe  
https://community.home-assistant.io/t/trigger-template-will-it-keep-firing/325009/7  
https://community.home-assistant.io/t/conditional-inside-entities-card/208819/2  
https://community.home-assistant.io/t/issue-with-template-no-default-was-specified-currently-int-will-return-0/387966  
https://smartairfilters.com/en/blog/data-explains-never-use-purifiers-auto-mode/  
https://community.home-assistant.io/t/lovelace-xiaomi-mi-air-purifier-3h-card/192100/12  