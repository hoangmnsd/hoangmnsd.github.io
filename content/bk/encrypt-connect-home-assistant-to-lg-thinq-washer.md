---
title: "Connect Home Assistant to LG thinQ Washer"
date: 2022-05-07T10:24:37+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [HomeAssistant]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Bài này hướng dẫn các integrate `Máy giặt LG ThinQ FV1409S4W` đến Home Assistant Container"
---

Bài này hướng dẫn các integrate `Máy giặt LG ThinQ FV1409S4W` đến Home Assistant Container

# Các bước setup

Tải app `LG ThinQ` về, đăng ký account độc lập LG ThinQ, chú ý là ko đăng ký bằng Social Network account như (Google, Facebook or Amazon).

Sau đó làm theo các hướng dẫn trên `LG ThinQ` App để add/kết nối với máy giặt.  
Chú ý sau khi bật nút Power trên máy giặt.  
Bạn cần connect App với máy giặt bằng cách ấn giữ nút này chứ ko phải biểu tượng wifi nhé:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-lg-washer-button-wifi.jpg)

Chờ add xong thiết bị là OK:   
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-lg-washer-button-wifi-add-device.jpg)

Clone this repo to local:  
`https://github.com/ollo69/ha-smartthinq-sensors`

Copy folder `https://github.com/ollo69/ha-smartthinq-sensors/custom_components/smartthinq_sensors` cho vào 
`/opt/hass/config/custom_components/`

-> restart HASS

Vào HASS -> Setting -> Devices&Services -> Add Integration, search `SmartThinQ LGE Sensors` xuất hiện:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-integration-search-lg-thinq.jpg)

Login account mà bạn vừa mới tạo trên App mobile:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-integration-submit-lg-thinq.jpg)

Add được như màn hình này là ok:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-integration-lg-thinq.jpg)

Vào HASS -> Setting -> Devices&Services -> Entities, thấy được list các entity như này là ok:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-entities-lg-washer.jpg)

Nếu bị lỗi như này chứng tỏ bạn nên update HASS lên version `2022.5.0`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-lg-thinq-integration-require-2022.5.0.jpg)

Create `opt/hass/config/packages/lg_logia_washer.yaml`:  
```yaml
sensor:
- platform: template
  sensors:
     washer_door_lock:
       friendly_name: "Washer Door Lock"
       value_template: "{{ state_attr('sensor.lg_washer','door_lock') }}"

     washer_time_display:
       friendly_name: "Washer Time Display"
       value_template: >
         {% if is_state('sensor.lg_washer_run_state', '-') %}
         {% elif is_state('sensor.lg_washer_run_state', 'Standby') %}
           -:--
         {% else %}
           {{ state_attr('sensor.lg_washer', 'remain_time') }}
         {% endif %}

     blank:
       friendly_name: "Blank Sensor"
       value_template: ""
```

Edit file `opt/hass/config/configuration.yaml`:  
```yaml
...
homeassistant:
  packages: !include_dir_named packages
```

Copy all files trong `https://github.com/phrz/lg-washer-dryer-card/tree/main/config/www` vào `/opt/hass/config/www`

--> restart HASS  

Lên giao diện HASS, edit Dashboard -> add Card manual, paste đoạn code sau:  
```yaml
type: vertical-stack
cards:
  - type: picture-elements
    elements:
      - type: image
        entity: sensor.lg_washer_run_state
        image: /local/lg-icons/sensing.png
        state_image:
          Cảm biến tải trọng: /local/lg-icons/sensing-on.png
        style:
          top: 33%
          left: 33%
          width: 20%
          image-rendering: crisp
      - type: image
        entity: sensor.lg_washer_run_state
        image: /local/lg-icons/wash.png
        state_image:
          Giặt: /local/lg-icons/wash-on.png
        style:
          top: 33%
          left: 51%
          width: 20%
          image-rendering: crisp
      - type: image
        entity: sensor.lg_washer_run_state
        image: /local/lg-icons/rinse.png
        state_image:
          Giũ: /local/lg-icons/rinse-on.png
        style:
          top: 33%
          left: 69%
          width: 20%
          image-rendering: crisp
      - type: image
        entity: sensor.lg_washer_run_state
        image: /local/lg-icons/spin.png
        state_image:
          Vắt: /local/lg-icons/spin-on.png
        style:
          top: 33%
          left: 87%
          width: 20%
          image-rendering: crisp
      - type: image
        entity: sensor.lg_washer
        image: /local/lg-icons/wifi.png
        state_image:
          'on': /local/lg-icons/wifi-on.png
        style:
          top: 73%
          left: 32%
          width: 10%
          image-rendering: crisp
      - type: image
        entity: sensor.washer_door_lock
        image: /local/lg-icons/lock.png
        state_image:
          'on': /local/lg-icons/lock-on.png
        style:
          top: 73%
          left: 45%
          width: 10%
          image-rendering: crisp
      - type: state-label
        entity: sensor.washer_time_display
        style:
          color: '#8df427'
          font-family: segment7
          font-size: 50px
          left: 95%
          top: 74%
          transform: translate(-100%,-50%)
    image: /local/hass-washer-card-bg.png
  - type: conditional
    conditions:
      - entity: sensor.lg_washer_run_state
        state_not: '-'
    card:
      type: entities
      entities:
        - entity: sensor.lg_washer
          type: attribute
          attribute: current_course
          name: Current Course
          icon: mdi:tune-vertical-variant
        - entity: sensor.lg_washer
          type: attribute
          attribute: water_temp
          name: Water Temperature
          icon: mdi:coolant-temperature
      state_color: false
  - type: entities
    entities:
      - entity: sensor.lg_washer_tub_clean_counter
        name: Tub clean counter
        icon: mdi:washing-machine
      - entity: binary_sensor.lg_washer_error_state
        name: Error state
      - entity: sensor.lg_washer_error_message
        name: Error message

```
Thấy được card hiển thị như này là OK:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-custom-card-lg-washer.jpg)

# Set Automations

Edit file `opt/hass/config/automations.yaml`: 
```yaml
# Notify when Washing completed
- id: '15911453452345'
  alias: LG Washer Completed Notify
  description: Notify to Telegram when LG Washer Completed
  trigger:
  - platform: template
    value_template: '{{ state_attr(''sensor.lg_washer'',''run_completed'') == ''on'' }}'
  condition: []
  action:
  - data_template:
      message: ''
      title: '🥳 Home Assistant: Washing completed.'
    service: telegram_bot.send_message

# Warning when Washer error
- id: '165745563453345'
  alias: LG Washer Reported Error Warning
  description: Notify to Telegram when LG Washer Reported Error
  trigger:
  - platform: template
    value_template: '{{ state_attr(''sensor.lg_washer'',''error_state'') == ''on'' }}'
  condition: []
  action:
  - data_template:
      message: 'Error message: {{ state_attr(''sensor.lg_washer'',''error_message'') }}'
      title: '🤨 HASS: Your LG Washer reported error.'
    service: telegram_bot.send_message
```


# CREDIT

https://github.com/ollo69/ha-smartthinq-sensors  
https://github.com/phrz/lg-washer-dryer-card  
https://community.home-assistant.io/t/in-development-lg-smartthinq-component/40157/481  