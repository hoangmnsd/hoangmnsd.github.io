---
title: "Azure: Publish Solution to Azure Marketplace (Part1)"
date: 2021-04-10T22:17:59+07:00
draft: true
authors: ["hoangmnsd"]
#categories: [Tech-Notes]
#tags: [Azure]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Bài này nói về làm thế nào để mang 1 solutiton lên Azure Marketplace."
---

# 1. About this document
Khi vào Azure Portal -> tìm Marketplace, bạn có thể nhìn thấy nhiều sản phẩm ở đây,
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-marketplace-home.jpg)

Ấn vào nút Create, bạn sẽ đem deploy các sản phẩm (solution) đó về Subscription của bản thân (Tất nhiên sẽ có charge tiền hoặc không)

Bài này nói về làm thế nào để mang 1 solutiton lên Azure Marketplace.  
Thông qua Marketplace, solution của bạn sẽ tiếp cận đến nhiều khách hàng hơn, và bán được thì sẽ mang tiền về cho bạn (hoặc tổ chức của bạn)

# 2. Offer types and how to choose
Azure cung cấp 1 số loại offer mà chúng ta có thể publish lên Azure Marketplace:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-marketplace-list-offer-type.jpg)

Cung cấp nhiều offer như vậy thì làm sao để chúng ta xác định là nên chọn loại Offer nào để publish đây?

Thì ở đây có 1 cách để xác định:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-marketplace-select-offer-type.jpg)

Để xác định bạn sẽ cần phải trả lời 1 vài câu hỏi:   
**Solution của bạn có phải là SaaS hay ko?**   
■ nếu có -> chọn "SaaS Offer", điều đó dẫn đến Offer của bạn sẽ:  
  _ Được deploy trong Subscription của Publisher (là bạn)  
  _ Publisher hoặc MS sẽ quản lý tính tiền   
  _ Yêu cầu integrate với Azure AD  
■ nếu không -> thì có phức tạp ko? - nếu có -> chọn VM Offer, nếu không -> chọn Azure App...  

Cứ thế để cuối cùng lựa ra best option cho solution của mình.

Ở trong bài này mình hướng đến việc chọn "Managed Application Offer":   
_ Giống như "Solution template Offer" (có thể deploy nhiều VM, kết hợp với các Azure service khác, kết hợp với VM Offer...)  
_ Được deploy trong Subscription của Customer và được quản lý bởi Publisher hoặc bên thứ 3    

# 3. Process of publishing Managed App Offer in basic
Quá trình publish 1 Managed App Offer về cơ bản sẽ có những giai đoạn sau:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-marketplace-managed-app-stages.jpg)

Nếu có thêm VM Offer thì sẽ như sau:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-marketplace-managed-app-vm-offer-stages.jpg)

**Giai đoạn 1**:   
- Publisher cần chuẩn bị ARM template (đã zip lại, chứa mô tả về Infrastructure của Solution).  
- Publisher publish Managed App Offer trên Partner Center.  
- Ở Partner Center bạn sẽ phải trải qua 3 state: `Publish -> Preview -> Live`  
- Ở mỗi state bạn phải chắc chắn code ARM của mình đã thỏa mãn các tiêu chuẩn mà Microsoft đề ra.  
- Nếu không thỏa mãn ví dụ bị lỗi khi Publish, bạn sẽ phải sửa lại Offer, sửa lại Code ARM, và publish lại đến khi nào Microsoft thỏa mãn  

**Giai đoạn 2**:  
- Đây là quá trình tự động mà Partner Center sẽ hiển thị Offer của bạn lên Marketplace.  
- Khi offer của bạn ở state `Preview` hoặc `Live` trên Partner Center, offer cũng sẽ xuất hiện trên Marketplace cho 1 số người có thể deploy sử dụng.  

**Giai đoạn 3**:  
- Customer/End-user sẽ vào Marketplace, nhìn thấy sản phẩm của bạn, bị thu hút bởi sự marketing của bạn, họ quyết định mua sản phẩm.  
- Họ ấn vào nút `Create` để đồng ý với việc sẽ thanh toán các chi phí theo như mô tả, ở đây sẽ sang gian đoạn 4.   

**Giai đoạn 4**:  
- Solution của bạn sẽ được tự động deploy lên subscription của Customer.  
- Nó sẽ tự tạo ra 1 resource group riêng chứa solution của bạn.  

**Giai đoạn 5**:  
- Vì offer của bạn là Managed App Offer, nên việc quản lý vận hành/operate sẽ ko phải nhiệm vụ của Customer, mà là của Publisher (là bạn)  
- Bạn sẽ có toàn bộ quyền trên resource group đã được tạo ra, và sẽ vào đó fix bug, update, hotfix, etc... tùy theo nhu cầu của Customer

[TO BE CONTINUE]