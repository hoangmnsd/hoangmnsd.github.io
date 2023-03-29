---
title: "Connect Home Assistant to Broadlink Rm4 Mini"
date: 2022-08-14T18:19:25+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [HomeAssistant]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Chắc hẳn sau khi setup HASS bạn sẽ muốn mình có thể điều khiển tất cả những cái remote trên giao diện HASS."
---

# 1. Story

Nếu như nhà bạn có 1 chiếc điều hòa bình thường (ko phải loại smart), bạn sẽ phải điều khiển nó thông qua 1 cái điều khiển (remote) riêng.  
Rồi có TV bạn lại có 1 remote cho nó. Nếu có thêm 1 chiếc quạt cây, chắc bạn cũng sẽ có remote dành riêng cho nó. Rồi nếu có thêm cái quạt trần, bạn lại có thêm 1 cái remote cho nó. Vậy là bạn phải quản lý 4 cái remote cho 4 món đồ đó.  

Chắc hẳn sau khi setup HASS bạn sẽ muốn mình có thể điều khiển tất cả những cái remote trên giao diện HASS.  

Bản thân hệ thống HASS không thể hoạt động thay cho chiếc remote của bạn, vì thế bạn cần sự hỗ trợ của một cái hub -> đây chính là lúc Broadlink RM4 mini xuất hiện.  

**Chú ý**: RM4 mini chỉ có thể hoạt động trong 1 phạm vi nhất định, giống như chiếc remote của bạn vậy. Nếu nhà bạn có 3 phòng mỗi phòng có 1 cái Tivi, điều hòa, quạt, v..v thì bạn sẽ cần mua 3 cái RM4 mini này 😂 thì mới điều khiển hết được.  

Cơ chế rất đơn giản: RM4 mini sẽ kết nối wifi, nó nhận lệnh từ HASS rồi chuyển các lệnh đó thành sóng hồng ngoại, truyền sóng đó tới thiết bị.

Đây là RM4 mini nhà mình:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/rm4-mini.jpg)

Các bước để kết nối RM4 mini tới Wifi thường sẽ được hướng dẫn ngay bới shop bán sản phẩm:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/rm4mini-connect-apps.jpg)

Cắm nguồn usb RM4 mini -> Tải app Broadlink trên điện thoại -> bật bluetooth -> tìm RM4 mini -> pair RM4 mini với điện thoại -> kết nối wifi -> xong

Giờ là lúc setup trên HASS

# 2. Setup integration on HASS

Vào Setting -> Add Integration -> search Broadlink:  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/broadlink-new-integration.jpg)

Nhập host Ip của RM4 mini vào (trong trường hợp của mình là `192.168.1.8`):  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/broadlink-new-integration-add-host.jpg)

Hãy chú ý rằng phiên bản HASS core `2022.5.2` ko hỗ trợ RM4 mini, bạn cần upgrade lên phiên bản mới như mình là `2022.8.2`

sau khi nhập tên cho RM4 mini thì bạn sẽ thấy các entity mới xuất hiện:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/broadlink-new-integration-entity.jpg)

# 3. Learn commands on HASS

Tiếp theo bạn cần dạy command cho HASS. Bản thân HASS và RM4 mini hiện chưa hiểu nhau. 

Ảnh dưới là chế độ Learn Command của HASS, mình đang muốn dạy cho RM4 mini biết nút `power` sẽ gửi đoạn code gì:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/broadlink-learn-command.jpg)

Sau khi ấn `CALL SERVICE`, bạn sẽ thấy RM4 mini đèn sáng, đây là lúc bạn ấn nút POWER trên điều khiển, chĩa vào chiếc RM4 mini mà ấn (ko phải ấn giữ nha, mà là ấn 1 cái rồi thả tay), ấn 2 lần là xong.

Giờ bạn vào folder này `/opt/hass/config/.storage/broadlink_remote_xxxxx_codes ` bạn sẽ thấy list code tương ứng với nút Power đã được HASS ghi nhớ lại: 
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/broadlink-learn-command-storage.jpg)

Lặp lại quá trình trên cho các nút còn lại: speed, tempup, tempdown, ... Quá trình này có thể hơi lâu nhưng bạn chỉ cần làm 1 lần

Bạn có thể test lại bằng cách chọn chế độ `Remote: Send Command` trên HASS: 
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/broadlink-send-command.jpg)  
Sau khi ấn nút `CALL SERVICE`, đèn trên RM4 mini sẽ nháy 1 cái để gửi sóng hồng ngoại đi. Hãy check xem điều hòa/quạt/tv của bạn có bật lên đúng như ý bạn ko?   
Hãy chắc chắn rằng cái RM4 mini đang ở gần thiết bị của bạn. Kiểu như RM4 mini giờ đã thành 1 chiếc remote điều khiển từ xa qua HASS

# 4. Setup dashboard on HASS

Giờ là lúc bạn đưa các command đã học được lên giao diện của HASS thôi.  

Đầu tiên là bạn sẽ tạo file sau, tương ứng với từng nút, sẽ có đoạn code như này:  

`/opt/hass/config/scripts.yaml`:  
```yml
# Fan Living Room
fan_livingroom_power:
  sequence:
  - service: remote.send_command
    data:
      command: power
      device: fan_livingroom
    target:
      entity_id: remote.rm4_mini_livingroom_remote

fan_livingroom_speed:
  sequence:
  - service: remote.send_command
    data:
      command: speed
      device: fan_livingroom
    target:
      entity_id: remote.rm4_mini_livingroom_remote
```

Rồi giao diện của HASS sẽ call đến các `script` mà bạn vừa tạo:  

```yml
title: "Living Room"
path: "livingroom"
cards:
  - type: entities
    title: Panasonic Fan
    show_header_toggle: false
    entities:
      - type: button
        name: Power
        show_state: false
        show_icon: true
        icon: mdi:power
        tap_action:
          action: call-service
          service: script.fan_livingroom_power
          data:
            entity_id: script.fan_livingroom_power
      - type: button
        name: Speed
        show_state: false
        show_icon: true
        icon: mdi:fan
        tap_action:
          action: call-service
          service: script.fan_livingroom_speed
          data:
            entity_id: script.fan_livingroom_speed
```
đoạn code bên trên tạo ra 1 cái card to với title là `Panasonic Fan`, bên trong card đó gồm 2 button Power và Speed.  
Mỗi khi có người ấn button đó, nó sẽ call service `script.fan_livingroom_power` hoặc `script.fan_livingroom_speed` tương ứng.  

giao diện của đoạn code trên như này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/fan-livingroom-test-old.jpg)

Nhưng mình ko muốn phải ấn nút `Run` thì mới bất được quạt, thế nên bạn nên sửa đoạn code, ko sử dụng `type: entities` nữa, mà dùng `type: glance`:   
```yml
title: "Living Room"
path: "livingroom"
cards:
- type: glance
    title: Panasonic Fan
    entities:
      - entity: script.fan_livingroom_power
        icon: 'mdi:power'
        name: Power
        show_state: false
        tap_action:
          action: call-service
          service: script.fan_livingroom_power
          service_data:
            entity_id: script.fan_livingroom_power
      - entity: script.fan_livingroom_speed
        icon: 'mdi:fan'
        name: Speed
        show_state: false
        tap_action:
          action: call-service
          service: script.fan_livingroom_speed
          service_data:
            entity_id: script.fan_livingroom_speed
```
giao diện sẽ dễ nhìn hơn, kiểu như này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/fan-livingroom-test-new.jpg)

# 5. Lưu ý

Có 1 vài lưu ý sau khi mình sử dụng vài ngày

1. Quay đúng chiều của RM4 mini:  
Bạn có thể sẽ thấy rằng tại sao RM4 mini nhiều khi ko điều khiển được cái quạt cây của mình, kiểu như ... sóng hồng ngoại phát ra từ RM4 mini ko đến được thiết bị ấy. Chả lẽ nó bị hỏng? 

Sau 1 hồi tìm hiểu thì mình mới biết rằng, chỗ phát ra sóng hồng ngoại:  
ko phải là cái đèn led nhỏ nhỏ xinh xinh ở mặt bên❌,  
mà là cả phần bề mặt bên trên (bôi vàng)✅:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/broadlink-where-ir-start.jpg)

Thế nên để RM4 mini hoạt động tốt, thì bạn nên hướng cái mặt kính/nhựa bóng ấy về phía thiết bị nhé. 

2. Tăng giảm nhiệt độ của điều hòa:  
Điều khiển điều hòa LG của mình cần set mỗi mốc nhiệt độ 1 nút ấn.  
Bạn sẽ ko thể "ấn nút tăng/giảm để thay đổi nhiệt độ".  
Mà bạn nếu bạn muốn set nhiệt độ 26 độ thì cần dạy cho `RM4 mini` biết 26 độ là như nào.  
Khi đó trên giao diện bạn ấn nút 26 độ để set nhiệt độ cho điều hòa.

Mình đã dạy RM4 mini các mốc nhiệt độ như này:  
Chuẩn bị trước: Bật cái remote điều hòa lên, chỉnh sẵn về mức 20 độ.
Setting trên HASS như này để dạy nó biết 19 độ là như nào:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/broadlink-learn-command-temp19.jpg)

Chú ý mình ko chọn tick vào chỗ `Alternative`. Sau khi ấn `CALL SERVICE`, bạn sẽ trỏ remote vào RM4 mini rồi ấn 1 phát nút giảm nhiệt độ từ 20 xuống 19.
Như vậy là xong, RM4 mini sẽ hiểu thế nào là 19 độ.

Làm tương tự với các mốc nhiệt độ khác bạn sẽ có 1 list code như này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/broadlink-learn-command-storage-temp-all.jpg)  

Việc đưa các script ra dashboard thì tương tự như làm với Fan ở bên trên mình đã hướng dẫn

# 6. Troubleshoot

Trong quá trình sử dụng có thể sẽ có lúc bạn thấy tự nhiên RM4 mini ko hoạt động nữa, khi vào HASS UI check thì phát hiện lỗi sau:   
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/rm4mini-err.jpg)

Nhiều khả năng lý do là Broadlink đã bị thay đổi IP khi reconnect vào wifi nhà bạn. 

(Hãy check lại xem IP của Broadlink mới là gì trước)

-> Hãy Delete integration đi và add lại nhé.  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/rm4mini-delete.jpg)  

Nhớ note lại cái tên bôi vàng này để lát nữa add lại cho trùng tên:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/rm4mini-delete-confirm.jpg)  

Đây là màn hình add lại:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/rm4mini-add-name.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/rm4mini-add-ok.jpg)  

Xong rồi, khá dễ thôi, chúc các bạn thành công! 😁

# CREDIT 

https://www.youtube.com/watch?v=jEOyTGaKwaQ&t=634s&ab_channel=EverythingSmartHome  
https://www.home-assistant.io/dashboards/glance/  