---
title: "Connect Home Assistant to LG thinQ Washer"
date: 2022-05-07T10:24:37+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [HomeAssistant]
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

# Troubeshooting

Lâu lâu sẽ thấy vào giao diện thấy máy giặt LG báo Unavailable. Vào màn hình `Integrations` thì thấy mất kết nối.

Check log homeassistant container:

## Log lỗi kiểu 1

```
2024-06-30 14:39:03.306 ERROR (MainThread) [custom_components.smartthinq_sensors] Error retrieving OAuth info from ThinQ
Traceback (most recent call last):
  File "/config/custom_components/smartthinq_sensors/wideq/core_async.py", line 916, in oauth_info_from_user_login
    token_info = await gateway.core.auth_user_login(
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/config/custom_components/smartthinq_sensors/wideq/core_async.py", line 606, in auth_user_login
    raise exc.TokenError()
custom_components.smartthinq_sensors.wideq.core_exceptions.TokenError: Token Error

The above exception was the direct cause of the following exception:

Traceback (most recent call last):
  File "/config/custom_components/smartthinq_sensors/__init__.py", line 137, in get_oauth_info_from_login
    return await ClientAsync.oauth_info_from_user_login(
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/config/custom_components/smartthinq_sensors/wideq/core_async.py", line 1658, in oauth_info_from_user_login
    result = await Auth.oauth_info_from_user_login(username, password, gateway)
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/config/custom_components/smartthinq_sensors/wideq/core_async.py", line 925, in oauth_info_from_user_login
    raise exc.AuthenticationError("User login failed") from ex
custom_components.smartthinq_sensors.wideq.core_exceptions.AuthenticationError: User login failed


2024-06-30 14:49:54.445 ERROR (MainThread) [custom_components.smartthinq_sensors] Error retrieving OAuth info from ThinQ
Traceback (most recent call last):
  File "/config/custom_components/smartthinq_sensors/wideq/core_async.py", line 916, in oauth_info_from_user_login
    token_info = await gateway.core.auth_user_login(
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/config/custom_components/smartthinq_sensors/wideq/core_async.py", line 504, in auth_user_login
    pre_login = await resp.json()
                ^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.12/site-packages/aiohttp/client_reqrep.py", line 1166, in json
    raise ContentTypeError(
aiohttp.client_exceptions.ContentTypeError: 0, message='Attempt to decode JSON with unexpected mimetype: text/html', url=URL('https://vn.m.lgaccount.com/spx/preLogin')

The above exception was the direct cause of the following exception:

Traceback (most recent call last):
  File "/config/custom_components/smartthinq_sensors/__init__.py", line 137, in get_oauth_info_from_login
    return await ClientAsync.oauth_info_from_user_login(
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/config/custom_components/smartthinq_sensors/wideq/core_async.py", line 1658, in oauth_info_from_user_login
    result = await Auth.oauth_info_from_user_login(username, password, gateway)
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/config/custom_components/smartthinq_sensors/wideq/core_async.py", line 925, in oauth_info_from_user_login
    raise exc.AuthenticationError("User login failed") from ex
custom_components.smartthinq_sensors.wideq.core_exceptions.AuthenticationError: User login failed


The above exception was the direct cause of the following exception:

Traceback (most recent call last):
  File "/config/custom_components/smartthinq_sensors/__init__.py", line 137, in get_oauth_info_from_login
    return await ClientAsync.oauth_info_from_user_login(
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/config/custom_components/smartthinq_sensors/wideq/core_async.py", line 1657, in oauth_info_from_user_login
    gateway = await Gateway.discover(core)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/config/custom_components/smartthinq_sensors/wideq/core_async.py", line 750, in discover
    gw_info = await core.gateway_info()
              ^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/config/custom_components/smartthinq_sensors/wideq/core_async.py", line 456, in gateway_info
    result = await self.thinq2_get(V2_GATEWAY_URL)
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/config/custom_components/smartthinq_sensors/wideq/core_async.py", line 338, in thinq2_get
    async with self._get_session().get(
  File "/usr/local/lib/python3.12/site-packages/aiohttp/client.py", line 1194, in __aenter__
    self._resp = await self._coro
                 ^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.12/site-packages/aiohttp/client.py", line 578, in _request
    conn = await self._connector.connect(
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.12/site-packages/aiohttp/connector.py", line 544, in connect
    proto = await self._create_connection(req, traces, timeout)
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.12/site-packages/aiohttp/connector.py", line 911, in _create_connection
    _, proto = await self._create_direct_connection(req, traces, timeout)
               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/local/lib/python3.12/site-packages/aiohttp/connector.py", line 1187, in _create_direct_connection
    raise ClientConnectorError(req.connection_key, exc) from exc
aiohttp.client_exceptions.ClientConnectorError: Cannot connect to host route.lgthinq.com:46030 ssl:default [Try again]

```

## Log lỗi kiểu 2

```
2024-07-20 13:19:55.359 ERROR (MainThread) [custom_components.smartthinq_sensors.config_flow] Invalid ThinQ credential error. Please use the LG App on your mobile device to verify if there are Term of Service to accept. Account based on social network are not supported and in most case do not work with this integration.
Traceback (most recent call last):
  File "/config/custom_components/smartthinq_sensors/config_flow.py", line 222, in _check_connection
    client = await lge_auth.create_client_from_token(
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/config/custom_components/smartthinq_sensors/__init__.py", line 151, in create_client_from_token
    return await ClientAsync.from_token(
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/config/custom_components/smartthinq_sensors/wideq/core_async.py", line 1568, in from_token
    await client.refresh()
  File "/config/custom_components/smartthinq_sensors/wideq/core_async.py", line 1488, in refresh
    await self._load_devices()
  File "/config/custom_components/smartthinq_sensors/wideq/core_async.py", line 1403, in _load_devices
    if (new_devices := await self._session.get_devices()) is None:
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/config/custom_components/smartthinq_sensors/wideq/core_async.py", line 1187, in get_devices
    return await self.get_devices_dashboard()
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/config/custom_components/smartthinq_sensors/wideq/core_async.py", line 1168, in get_devices_dashboard
    dashboard = await self.get2("service/application/dashboard")
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/config/custom_components/smartthinq_sensors/wideq/core_async.py", line 1093, in get2
    return await self._auth.gateway.core.thinq2_get(
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/config/custom_components/smartthinq_sensors/wideq/core_async.py", line 350, in thinq2_get
    return self._manage_lge_result(out, True)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/config/custom_components/smartthinq_sensors/wideq/core_async.py", line 397, in _manage_lge_result
    raise API2_ERRORS[code](message)
custom_components.smartthinq_sensors.wideq.core_exceptions.InvalidCredentialError: ThinQ APIv2 error

```

## Nguyên nhân 1

LG App cập nhật Term of Service và bạn cần phải accept ToS thì mới login được.

Vào App LG ThinQ trên điện thoại, sẽ thấy màn hình này: Accept chúng. Rồi vào HomeAssistant login lại Integration

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/hass-lg-washer-accept-tos.jpg)

## Nguyên nhân 2

Giờ hệ thống RPi bị sai. Lệch giờ so với thực tế.

Dẫn đến việc connect đến LG ThinQ service integration bị lỗi liên tục: authen bằng account đúng user/password nhưng vẫn báo lỗi invalid.

Giải pháp: Làm sao để sync datetime lại là OK.

## Nguyên nhân 3

Đó là do, Cứ 3 tháng LG lại bắt đổi password account 1 lần. Password hiện tại expired nên ko dùng được nữa.  

Cần phải:  
- Vào app LG ThinQ, đổi password mới.  
- Trên HASS, delete Integration đi rồi Connect lại bằng password mới.  
- Để tránh lặp lại thì nên cài 1 cái Alert trên HASS, theo dõi state của `sensor.lg_washer`.  
- Vì xóa đi add lại integration, nên có 1 số sensor bị disable by default cần được enable lên: Cần vào Settings -> Devices -> Select LG Washer, click on `+6 entities not shown` then click on `Advanced Settings` -> check box `Entity status: Enabled`.  

## Nguyên nhân 4

Integration của HASS đã update và nó cần được clone lại theo step:

Clone this repo to local:  
`https://github.com/ollo69/ha-smartthinq-sensors`

Copy folder `https://github.com/ollo69/ha-smartthinq-sensors/custom_components/smartthinq_sensors` cho vào 
`/opt/hass/config/custom_components/`

-> restart HASS

Sau đó add Integration lại khả năng bạn sẽ bị lỗi: 

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-lg-thinq-integration-require-2022.5.0.jpg)

Cần phải update HASS lên version mới để chạy được cái intergration này (tệ thật, mình ko muốn cứ phải upgrade version theo nó mãi như vậy)


# CREDIT

https://github.com/ollo69/ha-smartthinq-sensors  
https://github.com/phrz/lg-washer-dryer-card  
https://community.home-assistant.io/t/in-development-lg-smartthinq-component/40157/481  