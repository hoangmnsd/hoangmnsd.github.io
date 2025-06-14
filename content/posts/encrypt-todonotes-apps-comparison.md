---
title: "Todo notes apps in comparison"
date: 2023-05-23T00:07:17+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Notes]
tags: []
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Nhu cầu take-notes càng ngày càng tăng lên..."
---


## Story 

Trước đây dùng ColorNotes thấy khá OK, nhưng lên Windows thì app đấy đúng là thảm họa. Nó cũng ko có version web. Gần đây cài lại Wins mình cũng ko thể tìm thấy ColorNotes trên Windows luôn. 

Giờ phải tìm 1 apps để take notes mới. Tìm 1 lượt mới thấy nhu cầu của mình cứ tưởng là "đơn giản, kiểu gì chả có 1 app thỏa mãn hết, chỉ cần giống ColorNotes nhưng thêm 1 vài tính năng, 1 vài support trên OS khác là OK". Mình đã lầm. Thị trường đúng là có hàng trăm hàng chục app take notes, nhưng để chọn được 1 app đúng nhu cầu của mình thì gần như là zero. 

Sau đây là bảng so sánh các app mình nghiên cứu, tương ứng trong hình thì chỉ là nhu cầu của riêng mình thôi:  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/todo-notes-app-compare.jpg)

Giải thích về 1 App take-note hoàn hảo trong tưởng tượng của mình là:

- Support nhiều OS: cả desktop, mobile.
- Có chức năng reminder, recurring reminder cho mỗi note.
- Có chức năng set password cho mỗi note quan trọng.
- Có chức năng set password cho bản backup để không phải ai cũng đọc được.
- Có khả năng export ra bản plain-text nếu muốn. 
- Không cần phải sign-up account.  
- Có thể sync/share/send notes to DropBox, Clouds.
- Free thì càng tốt, thu phí rẻ hàng tháng tầm dưới 2$ thì cũng được.  
- Nhẹ, giao diện đơn giản vì điện thoại mình cùi thôi, Android 8, LG G6.  
- Mình có thể chắc chắn data của mình sẽ ko bị Dev đọc được, được xác nhận E2EE, hoặc ít nhất là có Backup with password.  

Thế mà cuối cùng chả tìm được app nào thỏa mãn hết các yêu cầu trên.
## Solution

Cuối cùng phải kết hợp 3 app:  
- Giữ ColorNotes để reminders.  
- Obsidian để edit và quản lý hầu hết các notes, sync lên Syncthing.  
- Syncthing để sync 2 chiều đa thiết bị giữa Android và PC và Iphone.  

Lý do phải thêm Syncthing là: Dropbox ko support sync từ 1 local folder trên điện thoại lên Server. Có nghĩa là:
- Trên PC mình sửa 1 file trong folder Obsidian, thì file đó sẽ được sync lên Dropbox server ngay.
- Nhưng trên điện thoại sẽ ko thấy file đó thay đổi mà phải vào Dropbox App, export file đó ra local mới thấy. -> (việc export local sẽ làm mất khả năng sync 2 chiều)
- Rồi trên điện thoại, sửa file vừa export, muốn sync file đó lên Dropbox server lại phải vào Dropbox upload lên, hoặc share file đó lên Dropbox. -> (quá rườm rà).
- Mặc dù Dropbox bản trả phí (10$/month) có tính năng Folder Available offline, thì cũng chỉ 1 chiều từ server về Android chứ ko thể sửa file offline và sync ngay lên Dropbox server được.  

Đây là lúc mà mình cần thêm Syncthing, cho Dropbox ra chuồng gà tạm thời.  
- Sau khi setup, các folder được share từ PC sẽ được Synthing trên Android download về ngay (via wifi, local network).  
- Việc sửa file trên Android bằng Obsidian cũng sẽ được Syncthing upload và share cho PC ngay.  
- Tạm thời mình setup chỉ cần Wifi nội bộ là đủ, có thể sync qua Internet nhưng mình thấy chưa cần.   
Cụ thể cách setup như nào thì mời đọc phần [setup-syncthing-to-synchronize-between-androids-and-pc-and-ios](../../posts/encrypt-setup-home-assistant-on-raspberry-pi-and-addons/#22-setup-syncthing-to-synchronize-between-androids-and-pc-and-ios)


## Conclusion

Ngay sau khi phát hiện ra Dropbox ko thể sync 2 chiều trên Android, mình đã điều tra thêm Nextcloud thì thấy cũng bị vấn đề tương tự. Cả Onedrive nữa. Tuy không rõ nguyên nhân là gì nhưng khá chắc là sẽ còn rất lâu nữa issue này mới được các ông lớn như Dropbox, Nextcloud, Onedrive xử lý. 

Trong tương lai thì mình muốn sử dụng toàn bộ trên Obsidian hơn vì về mặt privacy thì nó làm tốt hơn, nhưng tính năng reminders quá quan trọng mình ko thể bỏ qua được, nên vẫn phải dùng song song với 1 app khác (ColorNotes) 1 thời gian nữa. 

## CREDIT

https://syncthing.net/  
https://www.youtube.com/watch?v=02XeIATCDO4&ab_channel=ApkHeaven  
https://www.dropboxforum.com/t5/View-download-and-export/Syncing-dropbox-files-on-Android-third-party-apps/td-p/532607  
https://www.reddit.com/r/dropbox/comments/oiwoqa/syncing_dropbox_files_on_android_third_party_apps/  
https://www.reddit.com/r/NextCloud/comments/mrqily/nextcloud_android_folder_sync/  
https://help.nextcloud.com/t/nextcloud-android-app-automatically-sync-files-folders/23123/31?page=2  

