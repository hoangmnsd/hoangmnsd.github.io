---
title: "Import new dashboard to Home Assistant: Minimalist"
date: 2022-05-22T21:13:54+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Notes]
#tags: [HomeAssistant,Notes]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description:  "Tóm tắt các step để import 1 dashboard rất đẹp cho HASS của bạn"
---

Đây là bài tóm tắt các step của clip này: https://www.youtube.com/watch?v=A0fMt8IRKoI

Trang chủ để theo dõi các custom card: https://ui-lovelace-minimalist.github.io/UI/usage/custom_cards/custom_card_homeassistant_updates/ 

Mục đích cuối cùng là import được dashboard Minimalist theme vào HASS

# Steps

Add repository: 
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-minimalist-add-repo.jpg)

Add some required repos - browser-mod:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-minimalist-add-repo-broser-mod.jpg)

Add some required repos - auto-entities:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-minimalist-add-repo-auto-entities.jpg)

Add some required repos - button-cards:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-minimalist-add-repo-button-cards.jpg)

Add some required repos - card-mod:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-minimalist-add-repo-card-mod.jpg)

Add some required repos - mini-graph:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-minimalist-add-repo-mini-graph.jpg)

Add some required repos - mini-media:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-minimalist-add-repo-mini-media.jpg)

Add some required repos - light-entities:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-minimalist-add-repo-light-entities.jpg)

Add some required repos - simple-weather:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-minimalist-add-repo-simple-weather.jpg)

Add some required repos - my-cards:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-minimalist-add-custom-repo-my-cards.jpg)

-> restart HASS

Add new integration Minimalist:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-minimalist-add-new-integration.jpg)

Setting integration Minimalist:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-minimalist-add-repo-setting-integration.jpg)

Integration hiện như này là OK: 
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-minimalist-integration-displayed.jpg)

Setting Profile để chọn theme default:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-minimalist-profile-theme-default.jpg)

-> restart HASS

Lúc đầu Dashboard default sẽ như thế này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-minimalist-default-dashboard.jpg)

Edit file `/opt/hass/config/configuration.yaml`:  
```yaml
frontend:
  themes: !include_dir_merge_named themes
```

-> restart HASS

Go to HASS Profile, change Theme default to `minimalist-desktop`

# Troubleshoot

Nếu bạn gặp lỗi này trên mobile phone, mình đã comment solution bên dưới thread đó luôn: 
https://github.com/UI-Lovelace-Minimalist/UI/issues/693

Phần còn lại thì các bạn xem clip để chỉnh sửa dashboard sao cho phù hợp với nhu cầu của mình.  

Nếu có 1 ngày các bạn bị lỗi này trên cái bóng đèn ko thể kéo tăng giảm độ sáng được như này:
```
Custom Element doesn't exist:my-slider
```

Thì nên làm các bước sau

Delete `/opt/hass/config/custom_components/ui_lovelace_minimalist/cards/my-cards`

Delete `/opt/hass/config/www/community/my-cards` 

Lên HACS, redownload lại Frontend integration này `My bundle cards`:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hass-minimalist-my-cards.jpg)

Vào file `/opt/hass/config/configuration.yaml`, sửa như sau:  
```yml
# lovelace:
#   mode: storage

# You need to specifiy resource url if setting lovelace.mode = yaml
lovelace:
  mode: yaml
  resources:
    - url: /hacsfiles/button-card/button-card.js
      type: module
    - url: /hacsfiles/light-entity-card/light-entity-card.js
      type: module
    - url: /hacsfiles/lovelace-auto-entities/auto-entities.js
      type: module
    - url: /hacsfiles/lovelace-card-mod/card-mod.js
      type: module
    - url: /hacsfiles/mini-graph-card/mini-graph-card-bundle.js
      type: module
    - url: /hacsfiles/mini-media-player/mini-media-player-bundle.js
      type: module
    - url: /hacsfiles/my-cards/my-cards.js
      type: module
    - url: /hacsfiles/my-cards/null
      type: module
    - url: /hacsfiles/simple-weather-card/simple-weather-card-bundle.js
      type: module
```
Chú ý mình đã add thêm:  
```
    - url: /hacsfiles/my-cards/my-cards.js
      type: module
    - url: /hacsfiles/my-cards/null
      type: module
```
-> restart HASS, sẽ fix được lỗi

# CREDIT

https://www.youtube.com/watch?v=A0fMt8IRKoI  
https://ui-lovelace-minimalist.github.io/UI/usage/custom_cards/custom_card_homeassistant_updates/  



