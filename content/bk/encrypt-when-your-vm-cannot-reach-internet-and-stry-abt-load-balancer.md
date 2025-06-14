---
title: "When your VM failed to reach Internet and story about Azure Load Balancer"
date: 2022-09-07T15:17:42+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Notes]
#tags: [Azure]
comments: false
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

Vậy thì cần test mấy comment sau: `sudo ping 8.8.8.8` inside your distro (Ubuntu).

- Nếu có kết quả bình thường, chứng tỏ máy bạn vẫn có kết nối internet và do Ubuntu bị lỗi nên bạn cần test tiếp các domain khác: `sudo ping archive.ubuntu.com`. Nếu chỉ `archive.ubuntu.com` là lỗi, còn `google.com` thì bình thường, bạn có thể tìm cách thay `archive.ubuntu.com` bằng 1 link khác để update hệ thống. (Tìm trên mạng là đc)  

- Nếu ko thấy kết quả gì, chứng tỏ máy bạn ko thể kết nối internet dc, liên quan đến network rồi. Trong trường hợp của mình, nguyên nhân là do VM đó đang là backend của 1 Azure Private Loadbalancer. Ko có public IP.
Dẫn đến VM đó ko thể access internet được. Hay còn gọi là bị chặn outbound traffic ra Internet (đây là 1 behavior của Azure Loadbalancer: "It's not a bug, it's a feature" - Azure said 🤣)  

Việc này dẫn đến các service trong VM đó mà cần outbound traffic ra Internet sẽ bị lỗi timeout. (ví dụ như có service nào đó call google api, youtube api, third-party api, hoặc VM đó cần system update..)  

Để xử lý, 1 số project có kiến trúc kiểu này:  
- Đặt `VM service` nằm sau 1 `VM Nginx` -> `VM Nginx` sẽ là backend của Azure private Loadbalancer (internal Loadbalancer).  
- Đi qua 2 lớp như vậy thì `VM service` sẽ có thể reach Internet bình thường.  
- VM Nginx sẽ trở thành **vật tế thần**, nó sẽ bị chặn outbound traffic ra internet.  

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

- Cách 4 chính là cách mà mình mô tả ở phần 1: bỏ cái VM đó ra khỏi Backend pool của internal LB, đặt nó sau 1 VM Nginx, VM Nginx sẽ thế chỗ đặt sau cái internal LB kia. Và như vậy Nginx sẽ ko có out bound traffic ra internet, còn VM cần connect ra internet thì ok. Cách này là tệ nhất vì vừa tốn tiền cho VM Nginx mà bandwitch lại ko cao.  

- Cách 5 là dùng [Azure Firewall](https://learn.microsoft.com/en-us/azure/firewall/integrate-lb#internal-load-balancer), nó sẽ tạo 1 public IP và outbound traffic sẽ đi qua đó ra ngoài. (khá đắt)  

1 kiểu thiết kế mà MS recommend nhưng mình ko thấy cần dùng lắm:  
https://docs.microsoft.com/en-us/azure/architecture/networking/guide/well-architected-network-address-translation-gateway
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/auzre-natgw.jpg)

1 vài comment chú ý:  
> The answer is contained in this LB outbound connection MS doc page. Outbound connectivity, for vnets with a standard* SKU load balancer does not exist automatically: the VMs requiring outbound access must either be given an external facing IP address, or be put into a backend pool of the load balancer AND the load balancer must have an outbound rule defined for the required outbound traffic on that backend pool (even if the rule merely accepts the default options). For a basic SKU load balancer this isn't necessary.  
https://serverfault.com/a/1017065/589181


# CREDIT

https://github.com/MicrosoftDocs/WSL/issues/937  
https://docs.microsoft.com/en-gb/azure/load-balancer/load-balancer-outbound-connections  
https://serverfault.com/a/1017065/589181  
https://learn.microsoft.com/en-us/azure/firewall/integrate-lb#internal-load-balancer  