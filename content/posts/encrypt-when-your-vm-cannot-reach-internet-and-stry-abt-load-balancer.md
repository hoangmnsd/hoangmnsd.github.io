---
title: "When your VM failed to reach Internet and story about Azure Load Balancer"
date: 2022-09-07T15:17:42+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Notes]
tags: [Azure,Notes]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Đây là note để xử lý khi bạn thấy Server của bạn có vẻ như ko thể kết nối internet được"
---

# 1. Story

Đây là note để xử lý khi bạn thấy Server của bạn có vẻ như ko thể kết nối internet được

Có thể bạn sẽ nhìn thấy thông báo này ngay khi ssh vào server:  
```
Failed to connect to https://changelogs.ubuntu.com/meta-release-lts. Check you Internet connection or proxy setting
```
Hoặc khi bạn run 1 vài command đơn giản như `sudo apt update`, màn hình sẽ dừng lại ở 0% và cuối cùng báo lỗi:
```
Connection timeout. Could not connect to nginx.org:443 (xxx)
```

Vậy thì cần test mấy comment sau:
Try `sudo ping 8.8.8.8` inside your distro (Ubuntu).

=> Nếu ko thấy kết quả gì, chứng tỏ máy bạn ko thể kết nối internet dc, liên quan đến network rồi.

=> Nếu có kết quả bình thường, chứng tỏ máy bạn vẫn có kết nối internet và do Ubuntu bị lỗi nên bạn cần test tiếp các domain khác:
To check dns try `sudo ping archive.ubuntu.com`

Nếu chỉ `archive.ubuntu.com` là ko ping được, try changing your apt sources to some other mirror. There is plenty of info on how to do this in the web.

Trong trường hợp của mình, nguyên nhân là do VM đó đang là backend của 1 Azure Private Loadbalancer. Ko có public IP.
Dẫn đến VM đó ko thể access internet được.  

Việc này dẫn đến 1 số service trong VM đó mà cần connect đến Internet sẽ bị lỗi timeout. 

Để xử lý, 1 số nơi có kiến trúc kiểu này:  
`VM service` nằm sau 1 `VM Nginx` -> `VM Nginx` sẽ là backend của Azure private Loadbalancer.  
Đi qua 2 lớp như vậy thì `VM service` sẽ có thể reach Internet bình thường. 

Tuy nhiên đây lại là cách tệ nhất trong số các cách thiết kế mà Microsoft recommend:  
https://docs.microsoft.com/en-gb/azure/load-balancer/load-balancer-outbound-connections

# 2. Recommended

Trong tài liệu trên mô tả 4 cách:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-outbound-medthod.jpg)

- Cách 1 là với điều kiện LoadBalancer bạn đang dùng có public IP gắn vào (public LoadBalacner). Khi đó ở phần setting bạn sẽ nhìn thấy tab `Outbound rules` ở bên trái. Nếu ko có public IP gắn vào LB bạn sẽ ko thấy đâu.
Cách này được đánh giá là OK nhưng ko scale được. Và thực tế thì với 1 số LB bạn sẽ ko muốn nó bị được public ra, như vậy ko đảm bảo security lắm.

- Cách 2 là Best recommend: sử dụng NAT Gateway, Azure NAT Gateway cũng khá rẻ, không như AWS NAT Gateway:
https://azure.microsoft.com/en-us/pricing/details/virtual-network/#pricing 
($0.045 per hour, $0.045 per GB) 1 tháng 730 hours liên tục nếu outbound traffic là 1TB thì tốn khoảng 80 $. 
Cách này khá OK vì nó giải quyết được vấn đề của cách 1, LB của bạn vẫn là private LB ko expose ra ngoài. 

- Cách 3 là Gắn 1 public IP vào VM luôn. Cách này nghe đã thấy nghiệp dư rồi.

- Cách 4 chính là cách mà mình mô tả ở phần 1

1 kiểu thiết kế mà MS recommend:  
https://docs.microsoft.com/en-us/azure/architecture/networking/guide/well-architected-network-address-translation-gateway
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/auzre-natgw.jpg)
- Có 2 Loadbalancer, 1 là external/public LB, 2 là internal/private LB.  
- Internal LB để các service gọi nhau nội bộ qua IP của internal LB.  
- External LB để serve các inbound traffic (trường hợp mà bạn muốn expose service của bạn ra ngoài).  
- Còn NAT Gateway là để serve các outbound traffic muốn từ VM đi ra internet (Ví dụ như 1 VM trong LB muốn call đến google api chẳng hạn).


1 vài comment chú ý:  
> The answer is contained in this LB outbound connection MS doc page. Outbound connectivity, for vnets with a standard* SKU load balancer does not exist automatically: the VMs requiring outbound access must either be given an external facing IP address, or be put into a backend pool of the load balancer AND the load balancer must have an outbound rule defined for the required outbound traffic on that backend pool (even if the rule merely accepts the default options). For a basic SKU load balancer this isn't necessary.  
https://serverfault.com/a/1017065/589181


# CREDIT

https://github.com/MicrosoftDocs/WSL/issues/937  
https://docs.microsoft.com/en-gb/azure/load-balancer/load-balancer-outbound-connections  
