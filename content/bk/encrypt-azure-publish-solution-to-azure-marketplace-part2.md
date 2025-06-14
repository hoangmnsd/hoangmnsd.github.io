---
title: "Azure: Publish Solution to Azure Marketplace (Part2)"
date: 2021-05-10T22:17:59+07:00
draft: true
authors: ["hoangmnsd"]
#categories: [Tech-Notes]
#tags: [Azure]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Phần 2 của bài về cách publish solution lên Azure Marketplace"
---

...

# 4. How to create an Azure Managed Application Offer

Trước tiên, bạn cần login vào Partner Center Portal, để login bạn cần có account, hãy đăng ký với MS nhé

## Tab Overview  
Đây là màn hình tab Overview của Partner Center sau khi bạn đã Login:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-partnercenter-overview.jpg)

### Create New offer
Click vào New Offer -> chọn Azure Application: 
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-partnercenter-create.jpg)

Điền `Offer ID`, cái này sẽ ko thể thay đổi về sau, nên hãy cân nhắc khi lựa chọn.   
`Offer alias` thì có thể sửa về sau nên ko vấn đề gì:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-partnercenter-create-offer-id.jpg)

Sau khi ấn Create thì đây là màn hình Offer overview, chưa cần quan tâm lắm:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-partnercenter-offer-overview.jpg)

## Tab Offer setup
Chuyển sang tab `Offer setup` (Chúng ta sẽ đi dần dần từng tab một), Alias là tên mà Offer sẽ hiển thị:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-partnercenter-offer-setup.jpg)

## Tab Properties
Chuyển sang tab `Properties`, chú ý tick chọn vào `Use the Standard Contract for Microsoft’s commercial marketplace?`  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-partnercenter-offer-properties.jpg)

## Tab Offer listing
Sang tab `Offer listing`, điền hết các thông tin cần thiết, chú ý sử dụng tiếng Anh, nếu có 1 chỗ nào đó sử dụng tiếng non-English thì cần thêm dòng này vào:  
`This application is available only in [non-English language]`  
Bởi vì sau này sẽ có 1 team của MS đi validate description này, họ validate bằng cơm nên có khả năng họ sẽ phát hiện ra hoặc không 🤣, cứ làm cho cẩn thận.  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-partnercenter-offer-listing.jpg)

## Tab Preview Audience
Chuyển sang tab `Preview Audience`:  
Đây là nơi add các subscription ID mà sẽ có thể deploy Application khi App mới chỉ ở trang thái Preview, tất nhiên Preview Audience vẫn bị charge tiền như thường nhé.  
Nên chọn 1 subscription nằm hẳn ngoài tenant id để test cho hoàn toàn trung lập.  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-partnercenter-preview-audience.jpg)

## Tab Techinal configuration
Chuyển tab `Techinal configuration`, ko cần làm gì:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-partnercenter-offer-technical-config.jpg)

## Tab Co-sell with MS
Chuyển tab `Co-sell with MS`, chọn những gì phù hợp với App của bạn:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-partnercenter-co-sell-ms.jpg)

## Tab Resell through CSPs
Chuyển tab `Resell through CSPs`, Chọn "No partners in CSP program":  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-partnercenter-re-sell-throughcsp.jpg)

## Tab Plan overview
Quay lại tab `Plan overview`:
Create new plan, 1 Offer có thể có tối đa khoảng 100 Plan nhé.  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-partnercenter-plan-overview.jpg)

## Tab Plan listing
Chuyển tab `Plan listing`, Điền các description, Bạn có thể điền dạng HTML, table, nhưng số lượng ký tự chỉ được giới hạn khoảng 2000 ký tự:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-partnercenter-plan-listing.jpg)

## Tab Pricing and availability
Chuyển tab `Pricing and availability`:  
Nên chọn all market, set price cẩn thận vì bạn sẽ ko thể thay đổi giá sau này  
về Plan visibility:  
◼ Nếu chọn Public, tất cả đều có thể nhìn thấy, chú ý là 1 khi đã public thì bạn sẽ ko thể thay đổi từ public sang private nữa!
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-partnercenter-plan-pricing-avai.jpg)

◼ Nếu chọn Private, bạn sẽ cần add Subscription của các customer vào đây. 1 khi app Live, chỉ những subscription đó là thấy được App của bạn từ Marketplace của Azure Portal:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-partnercenter-plan-pricing-avai2.jpg)

## Tab Techical Configuration
Sang tab `Techical Configuration`:    
◼ `Version` thì tùy bạn chọn, bắt buộc phải dạng `{integer}.{integer}.{integer}`.  
Upload file zip của code ARM lên (file zip phải tuân thủ quy tắc tên các file template theo chuẩn của MS).  

◼ `Customize allowed customer actions`, nếu tick vào đây, hãy consider xem App của bạn sẽ cho User những quyền gì:  
Ví dụ như ở dưới, bạn cho customer - người deploy sản phẩm của bạn sẽ có toàn quyền đối với Azure Network Security group (họ có thể thêm bớt sửa xóa).  
Còn mặc định là customer sẽ chỉ có quyền đọc/read và ko có quyền chỉnh sửa nào cả.

◼ Phần `Public Azure*`: ở đây, khi App của bạn được deploy, bạn cần chỉ định ai sẽ có quyền Owner, có thể manage (quản lý) App đó cho customer, thì bạn đưa `tenant ID` và `principal id` vào đây.  
Thường thì người ta sẽ tạo 1 group các user trên Azure AD, rồi lấy principal ID cho vào đây.  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-partnercenter-plan-technical-config.jpg)  

Sau đó chọn `Review and Publish`.  
Chú ý cột Status cần Complete hết mới được:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-partnercenter-offer-review-publish.jpg)

## Publish
Sau đó sẽ ấn vào `Publish`.   
◼ App sẽ chạy đến trạng thái `Preview` như hình này là OK 1 phần.  
Bây giờ bạn có thể deploy app từ các link Preview bên dưới, Chỉ những subscription được list trong Preview Audience mới có thể deploy được.  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-partnercenter-offer-overview-progress.jpg)

◼ Khi bạn đã test OK hết thì có thể ấn vào `Go live` để cho nó publish hoàn toàn:  
Đây là màn hình khi Offer đã Go Live thành công. Để đến được màn hình này, nhiều khả năng các bạn sẽ phải chờ đến 7 ngày làm việc để chờ MS team validate đầy đủ Offer của bạn.  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-partnercenter-offer-overview-progress-golive.jpg)

[TO BE CONTINUE]