---
title: "VPC/Vnet Architecture (Azure,AWS)"
date: 2023-04-04T21:54:05+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Notes]
tags: [AWS,Azure,VPC,Vnet]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Khi thiết kế kiến trúc AWS VPC và Azure Vnet nên chú ý gì?"
---

# 1. AWS VPC Architecture

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-vpc-architecture.png)  

Giải thích:  

- Vì chi phí cho traffic từ private subnet ra internet mà đi qua 1 NAT Gateway khác AZ sẽ cao hơn, nên nếu traffic nhiều thì mỗi AZ 1 NAT Gateway thì sẽ ko có traffic đi sang AZ khác.  

- Có thể chọn 1 NAT Gateway thôi cho all private subnet nếu traffic từ private subnet ra ngoài internet ít.  

- Có thể thu nhỏ phiên bản lại, chỉ dùng 1 VPC thôi, Bastion chuyển vào Public subnet của Production VPC.  

- ALB hay NLB?: 
  + ALB dùng cho HTTP/S traffic. Các app cần routing nâng cao: url-based, query string based. Microservices.  
  + NLB dùng cho TCP, UDP, TLS traffic mà cần handle hàng triệu request/s.  

- Bên cạnh Bastion có thể chứa thêm các module để monitoring như Grafana, logging EFK, Zabbix.  

- Có thể vẽ thêm S3 và VPC endpoint cho S3.  

# 2. Azure Vnet Architecture

Trong Azure cũng có khái niệm tương tự như AWS, khi chia các VNET ra làm các nhiệm vụ riêng biệt.  
Azure gọi là [Hub-Spoke topology](https://learn.microsoft.com/en-us/azure/architecture/guide/networking/private-link-hub-spoke-network#azure-hub-and-spoke-topologies).  
Được quảng cáo là giúp quản lý tập trung cho IT team. 1 số subscription có thể có limit số lượng resource nên nếu Hub và Spoke nằm ở các Subscription khác nhau và peer qua vnet Hub-Spoke thì sẽ vượt qua được cái limitation của 1 Subscription (cái này phù hợp với dự án to, workload lớn).  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-network-architecture.png)

Giải thích:  

## 2.1. Hub-Spoke topology

- Diagram này duplicate 2 Management Subnet, mình vẽ vậy cho cả 2 trường phái:
  + Muốn chia ra theo Hub - Spoke topology: khi đó Spoke Vnet không còn Management Subnet nữa.   
  + Muốn quản lý tập trung trên 1 Vnet: là phiên bản đơn giản đi, lược bỏ Hub Vnet, peering.  

- Phiên bản phức tạp hơn 1 chút thì Hub Vnet có thể nằm trong 1 Resource Group riêng biệt, Hoặc thiết kế multiple region.  

## 2.2. Application Gateway, Azure Firewall

- Application Gateway song song với Azure Firewall là [Best practice](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/gateway/firewall-application-gateway#firewall-and-application-gateway-in-parallel). 2 cái này có thể nằm trong Hub Vnet cũng được.  
  + Application Gateway có WAF bảo vệ các HTTP/S traffic inbound đi vào server của bạn. (ví dụ như User truy cập vào web app của bạn đi qua HTTP/S browser).  
  + Còn Azure Firewall thì bảo vệ các non-HTTP/S traffic outbound đi từ server của bạn đi ra internet (ví dụ như trường hợp system update, apt-get update).   
  + Xem diagram [này](https://learn.microsoft.com/en-us/azure/architecture/example-scenario/gateway/firewall-application-gateway#architectures) để hiểu hơn:  
  ![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-firewall-appgw.jpg)  

- Azure Firewall cung cấp nhiều tính năng filter hơn NSG. [So sánh Azure Firewall với NSG](https://itnext.io/choosing-between-azure-firewall-and-network-security-groups-b3ed1e6eedbd).  

- Azure Firewall khá đắt. Còn Application Gateway nếu enable tính năng WAF sẽ **rất đắt**.  

- Application Gateway có thể đặt mỗi Spoke Vnet 1 cái. Hoặc là đặt only 1 cái ở Hub Vnet thôi để save cost (nhưng có giới hạn [100 active listner](https://github.com/MicrosoftDocs/azure-docs/blob/main/includes/application-gateway-limits.md)).  

- Hiện tại thì dự án mình ko có nhiều tiền nên chỉ dùng Application Gateway + NSG thôi.  

- Application Gateway kết hợp với DNS Zone để có HTTPS giảm effort quản lý cert đi, route traffic tới các VM theo Private IP and Port, DNS của Application Gateway dạng `xxx.westeurope.cloudapp.azure.com`, config với Listener/Rule/Backend pool/Backend Setting như này:  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-appgw-dnszone.png)

■ VM1(10.0.0.1) có 1 service-1, chạy trên port 8001, VM2(10.0.0.2) có 3 service chạy trên 3 port khác nhau.  
■ Tương ứng với 2 VM sẽ có 2 Backend pool.  
■ Tương ứng với 4 service sẽ có 4 Backend setting.  
■ Chỉ có 3 Rule, bởi vì `rule-3` sẽ handle 2 cái Backend setting, rule này có type là `Path-based: /api/*`, mặc định nó sẽ route traffic tới `service-3`, nhưng nếu request nào match với `/api/*` thì sẽ gửi đến `service-4` handle.  
■ Tương ứng 3 Rule sẽ có 3 Listener.  
■ Cả 3 Listener đều được config trỏ tới 3 CNAME record của DNS Zone.  
■ Cả 3 CNAME record của DNS Zone đều được config alias là Public DNS(Public IP) của Application Gateway.  
■ User truy cập vào các `service-1,service-2,service-3` bằng 3 domain khác nhau, Nhưng truy cập vào `service-4` bằng domain của `serivce-3` cộng thêm path `/api`.  


## 2.3. DNS Zone

- DNS Zone giúp tạo custom domain của riêng công ty mà ko dùng mặc định của Azure. Để config được cần:  
  + setup DNS Zone Global, lấy đc nameserver record thì đặt vào chỗ bạn mua domain.  
  + tạo 1 CNAME record trong DNS Zone.  
  + trong Application Gateway, config Listener thì trỏ hostname vào CNAME record vừa tạo, config Backend pool thì trỏ vào Private IP của VM/Service.  

- Ngoài ra có Private DNS Zone cũng khá hay, giống như đánh alias cho các private IP trong Network của bạn, thay vì gọi đến Private IP thì gọi đến alias của Private DNS Zone 1 cách rất *meanful*. 

## 2.4. Private Endpoint, Service Endpoint, Private Link

**Private Endpoint**:  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/example-az-private-endpoint.jpg)
- Có thể sử dụng Private Endpoint giúp đưa các Azure service (như SQL Server, Storage account, Key Vault..) vào trong Vnet/Subnet của bạn. Nhờ đó VM/service của bạn có thể connect đến các Azure service đó thông qua Private IP. 
- Khi sử dụng Private Endpoint, bạn sẽ cần setup thêm DNS cho nó resolve thành cái private IP. Project của mình dùng Private DNS Zone để setup với Private Endpoint. Nhờ đó mà có thể call đến các VM service qua internal DNS thay vì gọi đến private IP rất khó nhớ.  
(Có những option khác được liệt kê ở [đây](https://jeffbrown.tech/azure-private-service-endpoint/))  
- Chú ý là từ client(VM) connect đến Private Endpoint thì ok chứ bản thân Service đằng sau Private Endpoint không thể connect ngược lại.

**Service Endpoint**:  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/example-az-svc-endpoint.jpg)
- Bạn enable Service Endpoint cho cả 1 subnet luôn. Các VM trong Subnet đó đều có khả năng connect đến Azure Service (ví dụ Azure SQL service, -> all instances trong service luôn, chứ ko phải cụ thể 1 instance/database nào).  
- Xem ảnh trên thì thấy, khi enable Service Endpoint cho subnet A, private IP của VM trong Subnet A connect đến Public IP của Azure SQL Service. Subnet B vẫn có thể connect đến Azure SQL Service thông qua Public IP.  
- Nói chung mặc dù là dùng Network backbone của Azure, nhưng vẫn có Public access vào Azure SQL Service. Khác với Private Endpoint là bạn có thể disable Public access vào Azure SQL Service.  
- Không yêu cầu thêm setup DNS custom như Private Endpoint.  

**Private Link**:  

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/az-private-link-diagram.jpg)
Private Link có use-case khá hẹp, chỉ dùng với Standard Load Balancer. Khi đó, 2 service ở các tenant khác nhau, subscription khác nhau, region khác nhau, vnet khác nhau có thể call theo 1 chiều nhất định.  

Workflow sẽ cần quá trình request-approve như này:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/az-private-link-wf.jpg)
1 - bạn có 1 Service nằm sau 1 Standard Load Balancer, muốn cho người khác gọi đến (họ là Consumer, bạn là Provider).  
2 - Provider tạo Private Link.  
3 - Provider đưa Private Link ID cho Consumer (Gửi thư, chim bồ câu cũng được 🤣)  
4 - Consumer nhận thư, tạo Private Endpoint trong Vnet của họ, trỏ đến Private Link ID nhận được, 1 request sẽ được gửi cho Provider.  
5 - Provider approve request của Consumer.  
6 - Trong lúc chờ, Consumer config DNS record để sử dụng Private Endpoint như đã đề cập trong phần Private Endpoint.  
7 - Sau bước 5, Consumer đã có thể test connection đến Service của bạn (Provider)

## 2.5. VPN Gateway

- VPN Gateway có 2 loại Point-to-Site (P2S), và Site-to-Site (S2S).  
  + P2S dùng để có 1 secure connection từ Vnet đến 1 máy tính cá nhân (work from home).  
  + S2S dùng để secure connection từ Vnet đến on-premise site (công ty).  

- VPN Gateway Site-to-Site với ExpressRoute thì chọn cái nào?: Phụ thuộc vào nếu muốn data tách biệt khỏi internet thì dùng ExpressRoute, còn muốn save cost thì dùng VPN Site-to-Site.  

## 2.6. Private Load balancer

- Nếu `VM serivce` nằm sau 1 internal Load Balancer nó sẽ bị chặn outbound traffic - nghĩa là ko thể kết nối ra internet được (ví dụ gọi google api, apt-get update). Nếu muốn có thể call ra ngoài internet thì cần: 
  + Hoặc 1 là gắn public IP vào intenal LB -> biến thành Public LB,  
  + hoặc 2 là gắn public IP vào VM đó,  
  + hoặc 3 là dùng [Azure Firewall](https://learn.microsoft.com/en-us/azure/firewall/integrate-lb#internal-load-balancer) (đắt),  
  + hoặc 4 là dùng NAT Gateway (best - NAT Gateway sẽ tạo 1 public IP và cho phép outbound traffic). [Tham khảo cách dùng NAT Gateway với internal LB](https://learn.microsoft.com/en-us/azure/virtual-network/nat-gateway/tutorial-nat-gateway-load-balancer-internal-portal).   
  + hoặc 5 là ko cho `VM service` vào trong internal LB nữa, đặt `VM service` sau 1 `VM Nginx`, còn `VM Nginx` thì đặt sau internal LB (tệ nhất vì vừa tốn thêm tiền VM Nginx, bandwith lại ko cao).  
  + Mình đã viết [1 bài](../../posts/encrypt-when-your-vm-cannot-reach-internet-and-stry-abt-load-balancer/) về cái này nhưng vẫn nên nhắc lại.  
- Tất nhiên nếu VM nằm sau 1 internal Load Balancer mà ko có xử lý logic call outboud traffic thì là tốt nhất, bao giờ cần update system thì detach nó ra khỏi LB rồi xong thì attach lại là OK. Còn nếu VM đó có xử lý logic call outbound traffic thì lúc ấy cần nghĩ đến các cách bên trên.  

## 2.7. Load Balancer trên Azure thì chọn cái nào?

Có nhiều phương án để [lựa chọn](https://learn.microsoft.com/en-us/azure/architecture/guide/technology-choices/load-balancing-overview#decision-tree-for-load-balancing-in-azure), đại khái là cần chú ý như sau:  
- Azure Frontdoor: Dùng với HTTP/S traffic, thích hợp với bài toán multiple region. Điều hướng traffic theo URL path. 
- Azure Application Gateway: Dùng với các HTTP/S traffic, khi muốn balancing traffic trong 1 Vnet, trong 1 region (ko có global như các cái khác).  
- Azure Load balancer: Dùng với TCP/UDP traffic. Nên dùng để balancing các backend services.    
- Azure Traffic Manager: Any type of traffic (HTTP/S, TCP, UDP), dùng ở level global, điều hướng traffic theo DNS, thích hợp với bài toán multiple region. Nếu muốn balancing traffic trong vnet thì cần kết hợp thêm cái khác. Tham khảo bài [này](https://blog.lionpham.com/2018/03/12/azure-traffic-manager/)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/az-afd-atm-appgw-lb.jpg)

Tất nhiên còn nhiều thứ khác để so sánh mà đã được liệt kê ở [AFD vs ATM](https://www.iamashishsharma.com/2020/04/difference-between-azure-front-door.html)
 và ở [AGW vs LB vs ATM vs AFD](https://www.c-sharpcorner.com/article/azure-application-gateway-vs-azure-load-balancer-vs-azure-traffic-manager-vs-azu/)
 
Ngoài ra còn các [câu hỏi thường gặp](https://learn.microsoft.com/en-us/azure/frontdoor/front-door-faq#when-should-we-deploy-an-application-gateway-behind-front-door)

Xem hình này thì có thể thấy, nhiệm vụ mỗi cái khác nhau:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/az-frontdoor-traffic-manager-diagram.jpg)
- Traffic Manager giúp route traffic vào các DNS khác nhau của Blob store. Nằm trên các region khác nhau.  
- Azure Front Door giúp route traffic theo path, `/store/*` thì đi vào App Service, còn lại đường màu tím thì lại đi vào 2 cái AppGW trong 2 region khác nhau.  
- AppGW xử lý các request trong 1 region, `/images/*` thì đưa vào 1 chỗ Image Server, còn lại thì đưa vào Default Server.  
- Load Balancer xử lý các request trong internal network, có thể là tầng Database tier, cũng có thể Business tier.  

# CREDIT

Phần Azure:  
https://abstraction.blog/2022/09/26/azure-hub-spoke-secure-setup  
https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/n-tier/n-tier-cassandra  
https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/hybrid-networking/hub-spoke?tabs=cli  
https://www.youtube.com/watch?v=0mgXKz-vWZU&ab_channel=CloudContext  
https://learn.microsoft.com/en-us/training/modules/hub-and-spoke-network-architecture/2-implement-hub-spoke  
**Browser Azure Architectures**: https://learn.microsoft.com/en-us/azure/architecture/browse/  
https://learn.microsoft.com/en-us/azure/architecture/reference-architectures/n-tier/n-tier-cassandra  
https://lucian.blog/azure-networking-vnet-architecture-best-practices/  
https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/migrate/azure-best-practices/  migrate-best-practices-networking#best-practice-implement-a-hub-and-spoke-network-topology  
https://purple.telstra.com.au/blog/hub-and-spoke-network-topology-in-azure  
https://learn.microsoft.com/en-us/azure/virtual-network/nat-gateway/tutorial-nat-gateway-load-balancer-internal-portal  
https://learn.microsoft.com/en-us/azure/load-balancer/outbound-rules  

Azure Private Link, Private Endpoint, Service Endpoint:  
https://jeffbrown.tech/azure-private-service-endpoint/  
https://learn.microsoft.com/en-us/azure/private-link/private-link-service-overview  
https://learn.microsoft.com/en-us/azure/private-link/private-link-faq  

Azure Load Balancer:  
https://www.c-sharpcorner.com/article/azure-application-gateway-vs-azure-load-balancer-vs-azure-traffic-manager-vs-azu/  
https://medium.com/awesome-azure/azure-difference-between-traffic-manager-and-front-door-service-in-azure-4bd112ed812f   
https://blog.lionpham.com/2018/03/12/azure-traffic-manager/   

Phần AWS:
https://taoquangne.com/post/vpc-architecture/  
https://itnext.io/high-available-vpc-architecture-in-cloudformation-2f4d8a86f4d2  
https://i.pinimg.com/originals/6e/fc/de/6efcdea5fc39be6c344d751364336234.png  
https://devopsrealtime.com/wp-content/uploads/2021/11/VPC-Architecture-1.jpeg  
https://medium.com/awesome-cloud/aws-difference-between-application-load-balancer-and-network-load-balancer-cb8b6cd296a4     
https://www.whaletech.co/2014/10/02/reference-vpc-architecture.html   
