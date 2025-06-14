---
title: "Aws Certified Sysops Administrator Associate Note (SOA)"
date: 2019-09-07T23:01:48+09:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Notes]
#tags: [AWS]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Những notes của bản thân trong quá trình ôn thi chứng chỉ AWS SOA"
---

# Các câu hỏi và câu trả lời được note lại trong quá trình học

## **---P1---**

> Q. Cty của bạn có 1 VPC với vài ec2. App trên ec2 làm việc với IPv6. Cần ensure là ec2 này có thể init traffic ra Internet, nhưng ko cho connect từ internet vào instance. Làm nào?

Dùng egress-only Internet gateway. 

ko dùng NAT GW hay NAT instance vì cái đó dùng cho IP v4, IGW thì hiển nhiên ko dùng rồi.

egress-only IGW là stateful, nó forward traffic từ instance ra Internet, và gửi respone lại cho instance

> Q. Cty bạn có VPC với vài Ec2. 1 instance mới launch sẽ host app làm việc với IPv6. VPC của bạn cần cái gì để ensure các Ec2 mới launch sẽ có thể communicate qua IPv6?

Cần ensure là VPC được enable Dual Stack mode.

việc attach 1 egress-only IGW cũng đúng nhưng là chưa đủ.

Các step để enable VPC sử dụng dc IPv6:

1-VPC và subnet cần dc associate IPv6 CIDR block  

2-Update route table:  

_Public subnet thì cần tạo route để route traffic IPv6 từ subnet đến IGW  

_Private subnet thì cần tạo route để route traffic Ipv6 từ subnet đến egress-only IGW  

3-Update SG (và ACL nếu có), để include IPv6 address vào SG  

4-Xác định xem instance type có support IPv6 ko, nếu ko thì phải đổi  (m3.large ko support phải tăng lên `m4.large`)

5-Assign Ipv6 cho instance  

6-Nếu instance chưa dc configure DHCPv6 thì cũng phải configure.  

> Q. Cty bạn cần setup 1 hybric connection giữa on-premise và aws vpc. Họ sẽ transfer lượng lớn data từ on premise lên aws. Cần dùng gì? VPN hay Direct Connect?

AWS Direct Connect.

Vì VPN ko thể đảm bảo high banwidth connection cho lượng lớn data dc.

> Q. Bạn setup VPC và 1 subnet. Tạo 1 IGW attach vào VPC. Vpc dã cho phép DNS resolution và hostname. Bạn launch 1 ec2 có public ip và đã setting SG và NACL rồi, nhưng vẫn ko access dc EC2 vì sao?
Có phải vì chưa attach IGW vào public subnet? hay vì chưa setup Route table?

Vì chưa setup Route table

IGW chỉ cần attach vào VPC là đủ rồi, ko cần subnet

> Q. Bạn muốn cho phép 1 admin vào setup EC2, EC2 đó cần quyền access vào DynamoDB. Những policy permission gì cần để đảm bảo security?

Cần trust policy cho phép EC2 instance assume role  
Cần permission policy cho phép User Pass role to EC2

Theo AWS Documents cần 3 yếu tố:  
First, **IAM permission policy attach vào role**, define những action và resource mà role có thể làm.  
ví dụ define action read-only DynamoDB table.

Second, 1 **trust policy cho role**, cho phép service assume role.  
ví dụ sau là trust policy cho phép EC2 service sử dụng role và các permission dc attach vào role.
```
{
    "Version": "2012-10-17",
    "Statement": {
        "Sid": "TrustPolicyStatementThatAllowsEC2ServiceToAssumeTheAttachedRole",
        "Effect": "Allow",
        "Principal": { "Service": "ec2.amazonaws.com" },
       "Action": "sts:AssumeRole"
    }
}
``` 
Third, 1 **IAM permission policy attach vào IAM User**, cho phép user pass những role đã dc aproved.  
ví dụ sau là User chỉ được pass cái role tên là `EC2-role-for-XYZ-*`
```
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Action": [
            "iam:GetRole",
            "iam:PassRole"
        ],
        "Resource": "arn:aws:iam::<account-id>:role/EC2-roles-for-XYZ-*"
    }]
}
```
Giờ, User có thể start EC2, app run trên EC2 có thể access temporary credential thông qua instance profile meta data. Instance có thể làm những action đã dc determine trong permission policies.

1 Ví dụ khác dễ hiểu hơn:

**IAM permission policy attach vào IAM User A** như sau:
```
{
   "Version": "2012-10-17",
   "Statement": [{
      "Effect":"Allow",
      "Action":["ec2:*"],
      "Resource":"*"
    },
    {
      "Effect":"Allow",
      "Action":"iam:PassRole",
      "Resource":"arn:aws:iam::123456789012:role/S3Access"
    }]
}
```
User A sẽ có full quyền về EC2, và khi User A launch 1 EC2, Anh ta chỉ có quyền Pass (associate/gán) cái role tên là `S3Access` vào Instance thôi.

Tất nhiên trước đó, Bạn cũng cần tạo cái role tên là `S3Access` với **trust policy attach vào role** là:
```
{
    "Version": "2012-10-17",
    "Statement": {
        "Sid": "TrustPolicyStatementThatAllowsEC2ServiceToAssumeTheAttachedRole",
        "Effect": "Allow",
        "Principal": { "Service": "ec2.amazonaws.com" },
       "Action": "sts:AssumeRole"
    }
}
``` 
Và Role `S3Access` cũng cần có **permission policy attach vào role** tương tự như sau:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:ListAllMyBuckets",
                "s3:ListBucket"
            ],
            "Resource": "*"
        }
    ]
}
```

> Q. Những service sau cái nào by default ko cung cấp khả năng HA? EC2-RDS-DynamoDB-ELB?

EC2 ko HA by default, muốn HA thì phải tự làm bằng scripts.

RDS có feature Multi-AZ, DynamoDB thì full mamanged by AWS, ELB thì vốn đã HA

> Q. Bạn muốn có 1 list các user trong AWS account của bạn, check xem các user đó có dùng MFA ko? làm nào?

Vào IAM, download credential report, những thông tin rất nhiều liên quan đến ví dụ như password, access key, MFA

> Q. 1 bucket có thể set policy để deny hoặc allow 1 IP range nào đó bằng cách:

```
{
  "Version": "2012-10-17",
  "Id": "S3PolicyId1",
  "Statement": [
    {
      "Sid": "IPAllow",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": "arn:aws:s3:::examplebucket/*",
      "Condition": {
         "IpAddress": {"aws:SourceIp": "54.240.143.0/24"},
         "NotIpAddress": {"aws:SourceIp": "54.240.143.188/32"} 
      } 
    } 
  ]
}
```

> Q. Bạn là sysops admin của 1 cty IT. Sau khi đã setup SSM trên EC2 ở các region, bạn cần setup SSM cho 50 db server ở data centre của công ty bạn. Những action gì là bắt buộc?

Tạo 1 IAM role để communicate SSM service.

Install TLS certificate trên server của Data centre.

**Tạo 1 managed-instance activation cho môi trường Hybrid. Cái này để tạo ra 1 cặp Code-ID dùng cho việc install SSM agent sau này.**

Download và Install SSM agent trên các server của Data centre.

> Q. Tuần trước có 1 vài sự cố cho môi trường Production khi 1 số phần mềm unauthorised của third-party dc install trên servers. Giờ bạn cần duy trì 1 trạng thái đã dc defined trước (predefined state) cho all Ec2 thì cần làm gì trên SSM?

Dùng State manager với Command Document hay Policy Document, hay Automation Document, hay Package Document, hay Session Document?

**Command Document**: `Runcommand` dùng loại này để run command. Còn `State Manager` dùng loại này để apply configuration. `Maintenance Windows` thì dùng loại này để apply configuraition theo schedule.

**Policy Document**: `State Manager` dùng loại này để apply policy trên EC2

**Automation Document**: Dùng để thực hiện những task automation

**Package Document**: Dùng để tạo zip folder để install trên target instance

**Session Document**: `Session Manager` dùng loại này để start 1 session kiểu như SSH tunnel hay port forwarding

> Q. 1 cty muốn transfer 1 lượng lớn data lên s3. Số lượng data ban đầu khoảng **100TB**. Dùng service gì? Direct Connect hay Snowball?

Snowball.

ko thấy đề cập về việc transfer data on-going, thế nên setup Direct connect chỉ để cho 1 lần transfer như này thì ko hợp lý.

> Q. Bạn đang dùng CodeDeploy để update app với 1 password mới cho production. Ngta lo ngại rằng việc store new password trong khi update app trên 1 lượng lớn instance sẽ làm service bị outage. Làm nào? 

Dùng System manager Parameter Store để store pw. Nó store và save config data theo encrypted format. `Parameter Store` tăng cường secure vì nó store password tách riêng khỏi configuration file

> Q. VPC của bạn có cả Public subnet và private subnet. Application dc deploy trong 1 Ec2 ở Private subnet. EC2 đó cần tương tác với S3. Nhưng lại ko tương tác S3 đc, mặc dù IAM role đã đúng rồi, Làm nào?

VPC của bạn cần dc attach 1 VPC gateway enpoint.

Hoặc bạn cần đặt Ec2 đó ở Public subnet thay vì private subnet như hiện tại.

Túm lại, nếu EC2 để trong private subnet muốn connect S3 thì cần có VPC gateway enpoint

> Q. Bạn là IT admin, Công ty có 1 set EC2 trên AWS, và 1 set server onpremise. Họ muốn monitor system level log của both side server theo metric thì làm nào?

Install cloudwatch agent trên both set of servers

setup metrics dashboard trên Cloudwatch

> Q. Công ty muốn dùng aws và sử dụng gói support plan của aws. Nhu cầu là: Có operational reviews và có respone time < 30 minutes
 cho những critical issues. Nên chọn cái nào? Developer, Basic, Business, Enterprise?

Dùng Enterprise

 ![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/aws-support-plan-1.jpg)
 ![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/aws-support-plan-2.jpg)

**ko có Basic plan**

`giống nhau` giữa Business và Enterprise:  
system hư hỏng (support < 12h)  
system Production bị hư hỏng (support < 4h)  
system Production bị down (support < 1h)  

`khác nhau` giữa Business và Enterprise:  
system critical-quan trọng bị down (Business ko support, Enterprise support < 15 phút)

Enterprise có review operation, review well architect, coordinate với expert của AWS, có thể access self-paced lab, có team đến tận nơi support, giá > 15000 USD/tháng

Trong khi Bussiness chỉ khoảng > 100 USD/tháng

> Q. Cty bạn có khoảng 500 instances, cần ensure là SSH luôn dc disable. Làm nào?

Dùng AWS Config Rules để check Security Groups

Thực chất AWS Config rule là những hàm lambda check liên tục những điều kiện như: EC2 luôn dc associate với ít nhất 1 SG, port 22 ko đc mở trong production SG, các resource cần có required tags, EIP cần dc attach vào instances, các volume đang dc encrypt

> Q. 1 Dev muốn dc notify bất cứ khi nào có API activity dc call trên S3 bucket của anh ta. Làm nào?

Config a cloud trail và SNS

> Q. Bạn start các EC2 instance, nhưng chúng chuyển sang bị terminate ngay sau trạng thái pending, vì sao?

đây là lỗi `Instance Terminates Immediately`, lý do:  

_EBS volume bị limit

_EBS snapshot bị hỏng (corrupt)

_EBS root volume bị encrypt và bạn ko có quyền access vào KMS để decrypt key

_AMI mà bạn dùng để launch instance bị thiếu file nào đó.

-> Túm lại chủ yếu là lỗi về EBS và AMI, ko thể là lỗi về limit instances được

> Q. Team bạn dùng EC2 để setup database, sẽ rất nặng về workload, nên dùng loại EBS nào? 

Provisioned IOPS

ko dùng General purpose SSD vì AWS Document ghi rõ io1 dùng để host DB workload lớn

 ![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/ec2-ebs-volume-type.jpg)

> Q. 1 cty đang dùng EC2 để host Memcached dùng là Cache cho các app. Thì nên chọn loại instance nào?
Memory Optimized? hay Compute Optimized? hay Storage Optimized? hay General Purpose?

Dùng Memory Optimized Instances

Trong AWS Documents có viết:

**Compute Optimized Instances**: (c4, c5)  
Batch processing  
Media transcoding  
High-performance web servers  
Scientific modeling  
Dedicated gaming servers and ad serving engines  
Machine learning  

**General Purpose Instances**: (a1, m5, t2, t3)  
Web/Game servers  
microservices  
Caching fleets  
Small and medium databases  
Code repositories  
Development, build, test, and staging environments  

**Memory Optimized Instances**: (r4, r5)  
High-performance Database Relational/NoSQL  
In-memory caching (Memcached and Redis).  
In-memory databases and analytics (for example, SAP HANA).  
Real-time processing (Hadoop/Spark clusters).

**Storage Optimized Instances**: (d2, h1, i3)  
data warehouse  
MapReduce and Hadoop distributed computing  
Log or data processing applications  
High frequency online transaction processing (OLTP) systems

> Q. Cty bạn có 1 set EC2, các EC2 này run 24/7 trong suốt cả năm. Và bạn cần upgrade instance type để đáp ứng đc workload trong 1 năm đó thì nên chọn loại nào?
Convertible Reserved hay Standard Reserved Instance?

Convertible Reserved Instances

2 loại Convertible và Standard khác nhau ở chỗ loại Standard ko thể change dc instance type during the term.  
Loại Standard thì có thể change **instance size**, tuy nhiên ko thể exchange  
Loại Convertible thì có thể change dc **instance family, type, size, platform, scope, tenacy.**

> Q. Bạn có 3 VPC A, B, C, cần phải communicate với nhau, làm sao để ensure là all instance sẽ communicate dc với nhau?

A peer với B, B peer C, A peer C  
Mỗi Route table trong 1 vpc cần phải add CIDR block của 2 cái còn lại vào Destination

 ![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/3-vpc-peering-route-table.jpg)

> Q. Bạn có 1 VPC, và 1 custom domain, bạn muốn ensure là custom domain chỉ dc access bởi các instance trong VPC thôi, ko phải public internet, làm nào?

Dùng private hosted zone ở Route53

> Q. NAT Gateway setup ở trong public subnet hay private subnet?
bandwidth restrictions là gì?

Trong public subnet  
`bandwidth restrictions` là hạn chế về băng thông

> Q. Bạn đang cần connect on-premise lên AWS vpc. Bạn nhận nhiệm vụ setup vpn connection để setup hybrid architecture thì cần làm những step gì?

Tạo customer gateway

Tạo virtual private gateway attach vào vpc

Update route table, sửa cái route propagation: add cái virtual private gateway vừa tạo vào

Update SG: phần inbound cần enable SSH, RDP, ICMP access

Tạo VPN connection

> Q. Bạn đang tạo 1 Organization cho công ty bạn, những gì là đúng với Master account của Organization?

tạo Organization và OU,  
invite external account để join vào org,  
thanh toán tất cả charge của all account trong org (ko chỉ OU),  
master account ko bị ảnh hưởng bởi service control policies

> Q. 1 App đc deploy trên ec2, có dùng ELB. Bạn cần list các Ip address truy cập vào ELB, làm nào?

enable access logging cho ELB,  

cấp quyền để access logging truy cập dc vào s3 bucket

AWS Document giải thích: ELB access logging lưu trữ client ip, timestamp, latencies, request path, server respone. Tuy nhiên default nó disable, Nếu muốn thì phải enable lên. Sau khi enable thì ELB sẽ capture log và lưu vào S3 bucket mà bạn chỉ định

Cần phải sửa Bucket policy để ELB có quyền ghi log vào bucket đó

> Q. Web app server đc deploy trên ec2, Cần 1 phương pháp phòng chống security, bạn cần tạo 1 process để đánh giá security sau khi deploy. Cách hiệu quả để mỗi khi có thay đổi về Security Group dẫn đến sự tiếp xúc với Internet (assess network exposure) bạn sẽ dc biết là gì?

Sử dụng Amazon Inspector, nó sẽ có cái `Network Reachability package` để evaluate Network config có đang risk ko. Cái package này ko yêu cầu install agent Inspector trên ec2. 

Bạn có thể tạo 1 Cloudwatch event để monitor sự thay đổi của SG or VPC config, khi đó nó sẽ trigger cái Network Assessment

`Network Reachability package` sẽ tự động monitor AWS network của bạn, xem có cái nào misconfig ko. Nó ko yêu cầu install agent Inspector, tuy nhiên nếu install sẽ dc cung cấp chính xác các process đang listen on ports.

package này ko support Clasic EC2

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/inspector-network-assess-cloudwatch-event.jpg)

> Q. 1 cty setup 1 website host trên s3, muốn user có seamless user experience (trải nghiệm liền mạch) thì cần gì?

Dùng cloudfront

> Q. Phân biệt 3 cách Server side encrpytion s3: (SSE-S3, SSE-KMS, SSE-C)

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/server-side-encryption-3-ways.jpg)

> Q. 1 Cty cần store historical data. Có thể sẽ dùng Business Intelligence solution để query đống data đó. Thì nên dùng loại DB nào? EMR, DynamoDB, Redshift?

Dùng Redshift.

DynamoDB thì ko thể lưu trữ historical data

EMR dùng để làm data transformation, và load data đã processed đến Redshift thôi

Còn Redshift thì full managed, petabyte scale data warehouse service, là giải pháp về historical data storage, có thể query như SQL

> Q. Bạn đang có AWS RDS MySQL database, đang gặp vấn đề về performance, vì là sysadmin bạn cần xem có cách nào cải thiện performance ko. Dùng cái gì?
(AWS Trust Advisor, AWS Inspector, AWS Performance Insights, AWS Config?)

Dùng AWS Performance Insights

Nó là 1 chức năng có trong RDS/Aurora, support cho các loại DB nhất định, giúp monitor, phân tích issue, trouble shooting performance problem và visualize data load.

Inspector dùng để phân tích EC2 vulnerability

AWS Config để manage configuration

Trust Advisor chỉ đưa ra các best practice chứ ko phân tích sâu các issue trong DB của bạn

> Q. Bạn có 1 set các EC2, cần 1 dashboard metric của CPU utilization trong interval 1 phút. Cần làm nào?

Enable detailed monitoring for EC2 (Console->Action->Cloudwatch monitoring->Enable `Detailed monitoring`)

Tạo 1 dashboard trong Cloudwatch

Bởi vì nếu để chế độ `Basic monitoring` của EC2 thì interval send metric to Cloudwatch là 5 phút

> Q. Công ty bạn đang setup database trên EC2, Cần phải config fault tolenrance vì đây sẽ host những data quan trọng. Dự định implement RAID configuration. Thì nên chọn loại nào? RAID 0, RAID 1, RAID 5, RAID 6?

Dùng RAID 1

RAID 0 dùng chủ yếu cho mục đích `I/O performance`. Bạn add thêm volume thì bạn sẽ có thêm throughput. Nó kết hợp các volume lại thành 1 stripe. Tuy nhiên performance của stripe bị giới hạn ở cái performance của cái volume kém nhất. Và nếu mất 1 volume cũng sẽ mất toàn bộ data

RAID 1 dùng chủ yếu cho mục đích `fault tolerance` (các ứng dụng critical). Data sẽ ổn định hơn. Nhưng vì data dc ghi vào nhiều volume cùng 1 lúc, nên cần băng thông lớn. Và nó ko cải thiện performance WRITE dc.

RAID 5,6 ko dc recommend cho Amazon EBS, vì nó làm giảm IOPS của EBS xuống 20-30% so với RAID 0, trong khi giá tăng gấp 2. Ví dụ: 1 array gồm 2 volume RAID 0 sẽ performance tốt hơn 1 array 4 volume RAID 6 mà có giá gấp đôi.

Nói chung cứ nhớ, **RAID 0 stripe**, vì nó stripe nhiều volume lại để tăng performance. Từ đó suy ra RAID 1 sẽ fault tolerance.

> Q. Bạn cần sử dụng AWS QuickSight và có gì cần chú ý giữa 2 phiên bản Enterpise và Standard?

Enterprise hơn Standard ở chỗ cho phép encrpyt data rest và tương thích với Microsoft Active Directory (AD)

Bản Standard thì bạn có thể invite IAM user vào hoặc tạo cho họ 1 user QuickSight only

Bản Enterprise thì dùng MS AD để user access QuickSight

> Q. 1 Cty muốn các EC2 được patch với latest security patches?

AWS System Management

> Q. Bạn có 1 VPC và các subnets. Sau khi launch EC2 thì nó ko có public DNS name, cần làm gì?

Check 2 attribute của VPC: `enableDnsHostnames, enableDnsSupport`

Nếu cả 2 đang dc set = true thì EC2 mới có public DNS hostname

> Q. Bạn đang setup AWS Direct Connect giữa AWS VPC và on-premise data center. Thì Network cần phải như nào?

Network của bạn phải đang đặt cùng chỗ với AWS Direct Connect location (Cần tìm hiểu về location hiện có của Direct Connect)

Network của bạn phải làm việc với AWS Direct Connect Partner-đối tác sẽ hỗ trợ khách hàng (là bạn) connect vào Direct Connect

Về kỹ thuật:  
Network của bạn phải dùng single-mode fiber  
Auto negotiation for port phải disabled  
802.1Q VLAN phải dc support  
Device phải support BGP (Border Gateway Protocol) và BGP MD5  

> Q. Bạn đang quản lý việc migrate 1 app on-premise lên AWS. Dev đang launch EC2 để test app. Bạn concern về số lượng ec2, service nào dùng để xác định số lượng ec2 có đang trong limit hay ko?
AWS Config, AWS Trust Advisor, SSM, Cloudwatch?

AWS Trust Advisor

AWS Trust Advisor dashboard có 1 feature tên là `Service limit`, dùng để liên tục monitor usaged resource để bạn có thể request tăng limit hoặc shut down bớt resource trước khi limit bị reached

> Q. Bạn tạo EC2 nhưng nó ko auto có public Ip address, làm nào?

Sửa Subnet, modify auto-asign public IP = true

Nhớ là Sửa subnet chứ ko phải VPC

> Q. Bạn đang setup Test env. Bạn bật VPC flow log để capture IP traffic cho sau này còn audit. VPC flow log publish nhiều log file vào 1 single s3 bucket. Vài flow log đầu thì dc publish vào encrypted bucket thành công, nhưng sau đó thì bị lỗi `LogDestinationPermissionIssueException`. Vì sao?

Vì S3 bucket policy giới hạn 20KB thôi, Mỗi lần tạo 1 flow log mới, aws sẽ add thêm ARN của folder mới vào `Resource` element của bucket policy. Càng nhiều thì sẽ càng có nguy cơ vượt quá limit 20KB

Giải pháp: xóa hết các entries cũ ko dùng trong policy. Hoặc phân quyền cho toàn bộ bucket policy là `arn:aws:s3:::bucket_name/*`

Còn nếu gặp lỗi `LogDestinationNotFoundException`: thì có thể ARN của s3 bucket đang chỉ định sai, hoặc bucket đó ko còn tồn tại

CÒn nếu gặp lỗi tạo Flow log rồi nhưng ko nhìn thấy log ở trong s3 bucket hay Cloudwatch, thì là do chưa có traffic sinh ra, hoặc phải chờ 10 phút 

## **---P2---**

> Q. Bạn có 1 VPC, đã setup SG, network ACL, nhưng traffic ko reach đến instance, làm sao để diagnose issue? dùng Cloudtrail hay VPC Flow logs ?

Dùng VPC Flow logs, nó giúp monitor traffic reach instances

chứ Cloudtrail để monitoring API thôi

> Q. 2 VPC A(10.0.0.0/16) và VPC B(20.0.0.0/16), đã tạo 1 VPC peering có id là: pcx-1a2b1a2b. Thì route table của 2 VPC cần config Destination và Target là gì?

Destination là CIDR block của VPC kia, còn Target là id của VPC peering

> Q. Bạn đã tạo 1 RDS Instance. Công ty muốn ko có downtime khi 1 snapshot dc tạo ra. Làm nào?

enable multi-AZ

vì single-AZ gây downtime, nên nếu multi-AZ thì việc tạo snapshot sẽ chỉ diễn ra trên con RDS standby

> Q. 1 Consultant muốn view contents của 1 S3 bucket trong AWS Account. Content đó sẽ available trong 1 khoảng time. Thì nên dùng cách gì?

Tạo 1 IAM Role với session duration parameter

Ko thể specify time limit trong bucket ACL được

Cũng ko thể tạo IAM User với session duration parameter được

bắt buộc dùng ROLE

> Q. Cty bạn host web trên S3. User sẽ truy cập vào web bằng uRL: `http://companya.com`, vậy khi đặt tên cho s3 bucket cần đặt tên gì?

companya.com

kết hợp với Route53 để setting cái domain của riêng công ty bạn

> Q. 1 flow log record có format như sau:  
`10 123456789010 eni-abc123de 172.31.41.189 172.8.51.117 39751 3389 6 20 3279 1218430010 1218430070 REJECT OK`  
nghĩa là gì?

ip `172.31.41.189` từ port 39751 đang cố connect đến ip `172.8.51.117` ở port RDP 3389, giao thức TCP, và bị REJECT, đã lưu vào log

số packages gửi đến là 20, nặng 3279 byte, timestamp lúc start là 1218430010 và end là 1218430070

`<version 10> <account-id> <interface-id> <source address> <dest address> <srcport> <dstport> <protocol> <packets> <bytes> <start> <end> <action> <log-status>`

> Q. 1 Cty host 1 web app và có DynamoDB làm backend. Vấn đề là khi peak loads có thể các request đến DB sẽ bị throttle. Làm nào để đáp ứng dc lượng lớn các request đó?

Enable auto scaling cho DynamoDB, nó sẽ tăng read/write capacity để DB ko bị throttle

Các DB như RDS, Aurora, DynamoDB đều có thể enable auto scaling

Trước đây SAA Notes có 1 câu: DB bị tăng số lượng write, ko thể handle đc load. Làm nào để write ko bị mất cái nào? - Dùng SQS FIFO để lưu các write request pending 

-> thì đó là do câu hỏi chỉ muốn để write request ko bị mất cái nào thôi, chứ SQS ko đáp ứng dc việc high throughput của DynamoDB

> Q. Bạn restore 1 volume từ 1 snapshot để attach vào EC2. Bạn nhận ra có độ trễ về I/O trên cái New volume đó khi app đc launch lần đầu. Làm sao để các volume sau này dc restore từ snapshot ko bị issue đó nữa?

Ensure là all block trên cái volume mới đó phải dc access ít nhất 1 lần

1 New EBS volume thì sẽ luôn maximum performance ngay từ đầu mà ko cần initialization (hay còn gọi là pre-warming)

Nhưng các storage blocks của volume dc restore từ snapshot thì phải dc initialization, nếu ko sẽ có issue về performance trong lần đầu access

> Q. 1 Cty có set các EC2 trong VPC. Cần scan xem có risk về security ko, check cần phải làm với “Center for Internet Security (CIS) Benchmarks”. Nên dùng service nào?
Trusted Advisor, Inspector, Config, GuardDuty?

Inspector

Hiện giờ Inspector đang support những rule sau:  
· Common Vulnerabilities and Exposures  
· Center for Internet Security (CIS) Benchmarks  
· Security Best Practices  
· Runtime Behavior Analysis  

Trusted Advisor để đưa ra recommendations,   
Config để config,  
GuardDuty để quản lý threat detections  

> Q. Bạn có 1 set các EC2, để giảm cost, thì muốn shutdown các EC2 ko đc sử dụng, làm nào?

tạo Cloudwatch alarm, base on các metric cụ thể để shutdown instance

> Q. Cty bạn tạo AWS Organization để quản lý nhiều account. Với những service mà liên quan đến critical về security thì họ muốn chúng dc nottify cho Security Team từ những account trong org đó. Làm nào?

Dùng AWS Personal Health Dashboard và 
trong mỗi account sẽ tạo 1 CF template để run Cloudwatch rule của Org, Rule đó sẽ notify Security Team mỗi khi có critical alarm được generate ra.

> Q. Bạn có 1 set các app trên EC2 trong private subnet. Các app này cần dùng Kinesis stream. Làm nào để ensure là các app có thể sử dụng Kinesis stream?

Dùng 1 VPC Endpoint interface

VPC Endpoint interface dc cung cấp bởi Private link, đảm bảo các traffic ko đi ra khỏi Amazon network

> Q. Công ty bạn đang chọn gói support của AWS, cần:  
■ 24x7 access vào customer service   
■ trong giờ hành chính access vào Cloud Support Associate  

Chọn Developer là đủ
 ![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/aws-support-plan-1.jpg)

> Q. Bạn dùng public key hay private key để access vào EC2? key để trong EC2 là public hay private?

Dùng private key để access vào EC2,  
Key trong EC2 là public key

> Q. Bạn đang dùng Storage Gateway để extend data storage của bạn, yêu cầu là all data cần encrypt at rest thì dùng gì?

KMS, hoặc S3 SSE

> Q. Bạn đang dùng Redshift để manage data warehouse. Yêu cầu là all data cần transfer đến Redshift qua 1 VPC. Làm nào?

Enable Amazon Redshift Enhanced VPC Routing

khi làm vậy, Redshift sẽ force all COPY và UNLOAD traffic thông qua VPC.

> Q. Cty bạn muốn dùng S3 dể lưu file, và làm chúng available như NFS file share đến On-premise server. Làm nào?

Dùng File gateway

AWS Storage Gateway cung cấp, File-based, Volume-based, Tape-based, thì cái File Gateway chính là File-based.

Nó cung cấp access vào s3 object như là files/share mount point
Bạn có thể lưu và retrieve S3 object sử dụng NFS hoặc SMB (server message block)

> Q. Cty bạn dùng ElastiCache, bạn đã setup Memcahed cho họ, Sau khi dùng thì họ alert rằng sẽ có thể bị high CPU utilization cho cluster. Làm sao để resolve issue đó?

scale up cluster bằng cách dùng 1 larger node type, 

hoặc scale out cluster bằng cách add thêm nodes  

AWS Document viết:  

Có nhiều loại Cloudwatch metric monitor performance của ElastiCache: CPUUtilization, SwapUsage, Evictions, CurrConnections.

■ CPUUtilization > 90% thì nên làm như trên  

■ SwapUsage > 50MB thì nên tăng value của parameter `ConnectionOverhead`

■ Evictions là loại engine metric. Nếu gặp thì nên scale up cluster bằng cách dùng 1 larger node type, hoặc scale out cluster bằng cách add thêm nodes

■ CurrConnections, nếu gặp thì nên xem lại app của bạn

> Q. Công ty bạn có 1 set các EC2 và cả các server trên on-premise env. Bạn cần collect thông tin rằng các server này đã install software gì? thì làm nào?
Dùng System Manager để get software inventory, hay dùng AWS Config?

Bạn có thể dùng SSM để query metadata để biết những software nào đã dc install, cái server nào cần update, ..

Dùng AWS Config chỉ có thể check sự thay đổi về configuration của server, chứ ko thể biết server đã install gì.

> Q. 1 Cty muốn dùng Active Directory có sẵn để grant quyền cho user access vào AWS Console thì chuỗi action sẽ là gì? (nghĩa là dùng IAM Federated sign-in using AD)

1- User access vào portal sign-in page được cung cấp bởi AD FS (Active Directory Federation Service), rồi login

2- AD FS sẽ authenticate user đối với AD

3- AD trả về User info, trong đó bao gồm AD group membership

4- AD FS dùng group membership info để create SAML redirect link đến AWS STS

5- AWS STS dùng AssumeRoleWithSAML để grant temporary credential cho user (session từ 15m đến max 12h, default 1h) và trả về

6- User được authenticated và access vào AWS console

Không dùng `AssumeRoleWithWebIdentity` vì mình dùng AD nên phải đi với SAML

 ![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/adfs-authentication-flow.jpg)

> Q. 1 Cty có DynamoDB. Họ muốn ensure là có thể recover dc trong TH accidental write or delete operation. Làm nào?
có dùng Multi-AZ ko?

Dùng Point-in-time recovery feature, bạn có thể recover về any point trong khoảng 35 ngày (backup retention period (thời gian lưu backup) max 35 days)

Multi-AZ là feature của RDS thôi, ko phải của DynamoDB, DynamoDB có cái gọi là global table

> Q. So sánh giữa Multi-AZ và Read Replicas của RDS:  

 ![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/compare-multi-az-and-read-replica.jpg)

Multi-AZ là Synchronous (ReadRep là async)  

Multi-AZ chỉ primary instance là active (ReadRep thì mấy cái replica có thể read)    

Multi-AZ thì auto backup trên con standby (ReadRep thì default ko config)  

Multi-AZ thì luôn span 2 AZ trong region (ReadRep thì có thể 1 AZ, hoặc Cross-AZ, Cross-Region)  

Multi-AZ thì DB engine upgrade trên con primary (ReadRep thì ko phụ thuộc)  

Multi-AZ thì auto failover khi có vấn đề (ReadRep thì manual promote từ replica thành 1 con db instance standalone)

> Q. Bạn có 1 set các DynamoDB table. Cần phải monitoring report về Read/Write Capacity của DynamoDB để utilized. Làm nào?

Dùng Cloudwatch metrics để xem Read/Write capacity dc utilized

Cloudwatch cung cấp các metric để monitor DynamoDB:

Nếu muốn monitor rate of TTL deletion on table? - monitor cái `TimeToLiveDeletedItemCount` 

Nếu muốn xem dynamo table của mình đang có provisioned throughput là bao nhiêu? - monitor cái `ConsumedReadCapacityUnits` hoặc `ConsumedWriteCapacityUnits`

Nếu muốn xác định request nào vượt quá limit của throughput? - monitor cái `ThrottledRequest, ReadThrottleEvents, WriteThrottleEvents`

Nếu muốn xác định có lỗi system err ko? - monitor cái `SystemErrors` xem có lỗi HTTP 500 (Server error) hay ko

> Q. Cty bạn có 1 S3 bucket trên EU region. Giờ có yêu cầu replicate các object sang 1 region khác, cần ensurre điều gì?

Cả source và destination bucket đều phải enable versioning

và tất nhiên là chúng phải khác AWS region

> Q. Cty bạn có 2 account AWS, 1 cái cho Dev, 1 cái cho Prod, giờ Dev cần access vào Prod account để update application thì làm nào cho secure?

Tạo 1 cross account role, rồi share ARN cho Role

Trong AWS Document có ghi:

1- Trong Prod account, admin tạo 1 role `UpdateApp`, trong trust policy của role sẽ chỉ định AWS account id của Dev Account. Trong permission của role thì define những cái quyền cụ thể như write s3 bucket...

2- Trong Dev account, admin sẽ grant quyền cho group developer có quyền AssumeRole, để từ đó nhưng IAM trong group developer sẽ có thể switch role sang.

3- User sẽ switch Role trên console, hoặc CLI

4- STS sẽ verify và return credential tạm thời, 

5- Từ đó User sẽ tự động dc redirect sang console của account Prod

> Q. Cty có 1 on-premise web, muốn healthcheck liên tục, nếu health bị degrade thì sẽ switch sang 1 static website trên aws, làm nào?

Dùng Route53, health check to failover

> Q. Bạn có set các EC2 trong private subnet (10.0.1.0/24), những EC2 này cần download update từ internet HTTPS. Bạn đã setup NAT instance trong public subnet. Giờ cần setup SG cho NAT instance như nào?

Inbound rule: cho phép traffic từ private subnet IP qua port 443

Theo AWS Document:  
SG của NAT instance nên setting là:  

■ Inbound cho phép traffic từ private subnet IP qua port 443/80  

■ Outbound cho phép traffic từ port 80/443 ra 0.0.0.0/0 (để cho NAT access internet)

Giải thích thêm: Bản thân con NAT đã nằm ở `public` subnet rồi, nó đã nhận dc traffic từ World rồi, chỉ cần config thêm cho nó dc nhận traffic từ `private` subnet nữa thôi

 ![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/config-route-table-vpc.jpg)

> Q. Bạn có 1 app host trên aws. Bạn muốn setup instance type hiệu quả, sẽ flexible khi spikes usage. Nên chọn cái gì?

T2.micro, Config T2 unlimited option

Ví dụ: bạn có 1 ec2 t3.large, baseline CPU của nó là 30%, nếu nó chạy trung bình ở 30% hoặc ít hơn trong khoảng 24h, thì sẽ ko phát sinh thêm chi phí. Nhưng nếu run trung bình ở mức 40% trong khoảng 24h đó thì sẽ mất thêm tiền 10% đó.

> Q. Bạn plan host 1 batch process app trên ec2. Nên Instances loại nào? General Purpose, Memory Optimized, Storage Optimized, Compute Optimized

Compute Optimized

> Q. VPC có 2 subnet là public và private. Public subnet cần 1 NAT gateway. Thì config trên main route table và custom route table cần như nào? các route table ở trong private hay public subnet?

**main** route table phải ở trong **private** subnet, target đến NAT:  
0.0.0.0/0 target đến NAT gateway  

custom route table phải ở trong public subnet, target đến IGW:  
0.0.0.0/0 target đến IGW

 ![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/config-route-table-vpc.jpg)

> Q. 1 Cty lưu document trên s3. Họ bị audit raise vấn đề về non-maintaining access logs. Bạn dự định enable s3 server access log cho all buckets. Cần chú ý gì?

Source và target bucket phải là 2 bucket riêng và cùng trong 1 region

AWS Document viết:  
Server access logging để track request vào bucket. Bạn ko tốn tiền cho việc dùng feature này. Tất nhiên vẫn trả phí lưu trữ, phí access vào xem log như các request thông thường.

`source bucket` là bucket bạn muốn config để track access log của nó, (sẽ config phần logging)

`target bucket` là bucket lưu access log của source

default encrpytion trên target bucket là AES256 (S3-SSE), và ko thể thay đổi sang cái khác như SSE-KMS dc.

> Q. Cty bạn có 1 Redshift cluster trên EU region. Họ cần phải ensure là cluster sẽ available trên other region đề phòng TH primary cluster bị isue do region. Làm nào? Có thể Multi-AZ, Cross Region Read Replica, Global table hay ko?

Readshift ko có mấy tính năng trên đâu mà chỉ có thể Config Redshift automatic/manual copy snapshot to secondary region.

ko thể Multi-AZ hay Read replica như RDS dc

cũng ko thể global table như DynamoDB dc

> Q. Bạn muốn block public access vào all s3 buckets. Làm nào?
apply trên bucket level hay object level?  
apply theo region hay toàn bộ region?
apply cho current bucket hay future bucket?

block public access sẽ apply trên bucket level or account level, trên toàn bộ region (globally), cho cả current và future bucket

> Q. Bạn đang deploy 1 vài Cloudformation templates. Khi deploy gặp lỗi sau:  
Sender  
Throttling  
Rate exceeded  
Làm nào?

add 1 exponential backoff giữa các lần call API createStack

Lỗi xảy ra do createStack API tạo quá nhiều resource cùng 1 thời điểm. Cần phải có delay giữa các request đó

(Bạn ko thể add pause trong CF template mà chỉ có thể dùng wait hoặc depend on condition thôi)

> Q. 1 công ty Audit đang audit your infra. Họ muốn biết loại security nào đang dc implement ở data centre mà host các AWS resource của bạn? làm nào?

Dùng document cung cấp ở AWS Artifact service

AWS Artifact service là service cung cấp các security & compliance 
documents giống như ISO cert, PCI, SOC reports

> Q. App của bạn dùng RDS host database. Sau khoảng vài ngày, 1 table bị drop accidently và cần phải retrieve ngay lập tức trong vòng 5 phút sau khi bị drop. Dùng tính năng nào của RDS?
Multi-AZ hay Read replica hay Automated backup?

RDS Automated backup

RDS tự động backup DB instance theo period mà bạn chỉ định, và bạn có thể recover db về bất kỳ thời điểm nào trong backup retention period đó

AWS Document viết:  
Khi bạn delete DB instance, nếu ko chọn giữ lại backup thì mặc định sẽ xóa hết các bản backup luôn

Backup retention period, nếu bạn ko setup thì mặc định là 1 ngày nếu bạn tạo DB instance qua CLI, API. Là 7 ngày nếu tạo DB instance qua Console.

Automated backup chỉ diễn ra với DB trong trạng thái `Avalable`.

Automated backup diễn ra hàng ngày. Nếu ko chỉ định thì default là 30 phút backup windows, chọn ngẫu nhiên trong block 8h tùy theo region (ví dụ: virginia: 3-11h, tokyo: 13-21h)

> Q. Bạn muốn setup EC2 trong VPC. Yêu cầu là support higher bandwidth và higher packet per second (PPS) performance. Làm nào?
Có dùng EBS Optimized Instance type dc ko?

Dùng Instance type loại mà support Enhanced Networking

ko dùng EBS Optimized Instance type vì nó chỉ dùng để tăng performance cho EBS volumes

AWS Document viết:  
ENA (Elastic Network Adapter) support tăng tốc network **100 Gbps**: a1, c5, m5, t3, r5, p2, p3

VF (Intel Virtual function) support tăng tốc network **10 Gbps**: c3, c4, d2, i2, m4, r3

> Q. Bạn có 1 ASG trong đó có 1 số ec2, giờ app đang có issue và cần debug thì làm nào?
có thể dùng AWS Config để lấy config snapshot của ec2 để điều tra ko?

Cần suspend 1 hoặc nhiều scaling process để điều tra ec2

ko thể dùng AWS config vì điều đó là ko thể

AWS Document viết:  
Có 1 số scaling process trong ASG có thể suspend như:  
`Launch`: add ec2 vào ASG,   
`Terminate`: remove ec2 khỏi ASG,  
`AddToLoadBalancer`: add ec2 vào LB or target group,  
`AlarmNotification`: chấp nhận thông báo của Cloudwatch,  
`AZRebalance`: cân bằng số lượng ec2 giữa các AZ,  
`HealthCheck`: check health of ec2,  
`ReplaceUnhealthy`: terminate ec2 và create cái mới,  
`ScheduledActions`: thực hiện scheduled scaling action  

 > Q. 1 công ty có các file mà nếu đã dc verify thì sẽ ko cần trong tương lai trừ TH có issue. Nên lưu ở đâu cho tiết kiệm? Glacier hay S3 RRS hay S3 IA

Glacier vì nó rẻ hơn hẳn

■ Dùng S3-RRS (Reduced Redundancy Storage) nếu bạn muốn lưu những data ko quan trọng và nếu mất thì cũng dễ tái tạo lại     
■ Dùng IA nếu bạn muốn 1 chỗ lưu long-term nhưng có thể retrieve ngay lập tức  
■ Dùng Glacier nếu bạn muốn 1 chỗ lưu long-term nhưng có thể retrieve trong vòng 3-5 giờ  

> Q. Bạn cần capture all traffic flowing giữa client và server, bạn plan to enable Access log trên Application Load Balancer. Có loại traffic nào mà Access log ALB ko capture lại?

health check request từ ALB đến target group sẽ **ko** dc ALB access log capture lại

> Q. 1 Cty muốn implement quá trình deployment automatically tạo LAMP stack, download latest PHP từ s3, setup ELB. Nên dùng service nào để tạo 1 orderly deployment of software?  
Beanstalk hay Opswork?

AWS Elastic Beanstalk

> Q. Cty bạn plan setup 1 performance-sensitive workload trên aws. Bạn cần setup ec2 cho hosting this workload. Cần chú ý gì về config?

Chọn EBS Optimized Instance

Hoặc Chọn Instance type with 10 Gigabit network connectivity

khi bạn plan config EBS volume cho app, 2 cái trên rất quan trọng khi bạn muốn stripe nhiều volume lại trong RAID configuration

Có 1 list các loại instance type dc support EBS Optimized, đa số dc enable by default, 1 số cần phải enable bằng tay.

Có 1 list các instance type dc support Enhanced Networking lên đến 10 Gbps bandwidth

## **---P3---**

> Q. Bạn đang setup DynamoDB, có 40 device ghi data mỗi 10s, mỗi data 1KB. Vậy Write throughput set cho table là bao nhiêu?

4WCU

> Q. Cty của bạn có VPN connection giữa AWS VPC và on-premise data centre. Họ cần các ec2 sử dụng DNS server của On-premise cho việc resolve DNS, làm nào?

Tạo 1 DHCP Option set rồi asign nó vào VPC

Chú ý sau khi tạo DHCP Option set rồi thì bạn ko thể modify nó. Muốn thì phải tạo cái mới. 

> Q. Cty đang quản lý MySQL DB trên on-premise. Họ muốn migrate lên AWS, họ ko muốn mất công managed hay scaling DB thì nên dùng RDS hay Aurora?

Aurora, vì RDS vẫn cần 1 phần quản lý manage và scale  
Còn Aurora là full-managed by AWS

> Q. Công ty bạn muốn cắt giảm cost thì có nên consider việc ko sử dụng Autoscaling group vì nó gây cost ko?

ko, vì ASG ko phát sinh cost

> Q. Bạn cần phải tạo các metric cloudwatch, cái nào sau đây là cái bạn cần phải tạo **custom** metric?

CPU Utilization.  

Network Throughput.  

Số bytes read/writte vào volume.  

Dung lượng Disk storage còn lại trong volume.  
????

cái cần tạo custom metric là `Dung lượng Disk storage còn lại trong volume`,  
những cái kia đều là default metric, ko cần custom, ngay cả số lượng byte read/write vào volume cũng default

> Q. Limit về ELB và DynamoDB table?

ELB limit 20 LB mỗi region, có thể request để tăng  
DynamoDB limit 256 tables per account, có thể request để tăng  

> Q. Công ty bạn đang audit cả những AWS resource, họ yêu cầu compliance của aws resources thì lấy đâu?

Vào compliance portion của AWS website để lấy all:  
`https://aws.amazon.com/compliance/resources/`

> Q. Bạn access dc vào web server qua bastion nhưng ko thể access vào qua ELB, cần ensure gì?

ensure là ELB có attach vào public subnet    
ensure SG hoặc ACL của ELB có allow inbound traffic  

> Q. Công ty bạn muốn keep control cost, và muốn nhận alert cho billing thì cần enable gì trước khi tạo alarm for estimated metric? Còn nếu muốn tạo billng alarm thì tạo ở đâu?

Enable billing alert ở mục Account Preferences  

Nếu muốn tạo billing alarm thì tạo ở Cloudwatch

> Q. Bạn có 1 web app static content có nhiều truy cập gây bị chậm, nên làm nào? host trên s3 hay dùng read replica hay elastiCache?

host trên s3

app bị chậm vì bị truy cập nhiều, app respone ko phải vì dynamic content dc fetch từ DB nên dùng elastiCache ko hợp lý.

read replica cũng chỉ dùng để giảm độ trễ của dynamic data thôi.

1 static website gồm các static content, có thể chứa client-side script.

1 dynamic website thì dựa vào server-side process, script như PHP, JSP, .NET. S3 ko hỗ trợ server-side scripting.

> Q. Team member của bạn launch 1 ec2 thuộc loại EBS-backed instance, xong vài tuần sau thì mất private key, ko thể login vào dc nữa. Giờ làm nào?

chú ý các step sau chỉ dành cho EBS-backed instance, ko dành cho instance store-backed instance:  

0- đầu tiên, tạo 1 keypair mới,  
1- launch 1 `temp instance` cũng từ ami đó,  
2- stop `origin instance`,  
3- detach root volume của `origin` ra, attach vào `temp instance` dưới dạng data volume,  
4- connect vào temp insntace,  
5- mount volume mới vào 1 folder tạm để modify file system của volume đó,  
5- modify authorized_keys: copy authorized_keys từ `temp instance` sang origin volume vừa mount,  
6- move cái volume đó trở lại `origin instance`,  
7- restart instance.  

> Q. Bạn lưu billing report trên 1 s3 bucket theo dạng csv. Giờ cần dùng Athena để query những report đó. Thì trong Athena chỉ specify s3 bucket theo path nào?

s3://bucketname/prefix/  
hay  
s3://bucketname/prefix/*  

Phải dùng: `s3://bucketname/prefix/`

> Q. Team bạn có 1 ASG và 1 ELB, trong đó có 1 set ec2. Sau khi cho ng dùng thử thì thấy là traffic ko distribute đều qua các ec2. Lý do gì?

sticky session đã dc enable cho LB

all subnets có ec2 ko dc register với LB

AWS Document viết:
sticky session sẽ ensure là all request của user trong suốt session sẽ gửi dến cùng 1 ec2

> Q. Khác nhau giữa Dedicated Host và Dedicated Instance?

EC2 - Dedicated Host:  
AWS cho bạn toàn quyền trên 1 con server vật lý luôn, ko chia sẻ với ai, cho bạn toàn quyền control số lượng core, socket…, cho bạn quyền sử dụng licence có sẵn của bạn (BYOL-bring your own licene), ko mất tiền mua license của AWS nữa.    
Bạn có thể run nhiều instances trên cái host đó. Các instance trong host sẽ có network performance cao.

EC2 - Dedicated Instance:  
Tạo Ec2 trên 1 con server vật lý, đảm bảo duy nhất cho bạn (tuân thủ về mặt compliance)

> Q. Bạn cần migrate Oracle 10g Release 2 và MySQL 5.6 lên AWS RDS read replica. Cần chú ý gì?

RDS ko support Oracle version dưới 12.1

> Q. Bạn dùng RDS MySQL. Thì ở `Maintenance Window` sẽ thực hiện những activities về RDS?

Update DB instance hardware,  
Update OS,  
Update DB engine version,  
Patching server.  

> Q. Cty đang dùng RDS MySQL, giờ đang gặp vấn đề về performance với read request, làm nào?  
có nên enable Multi-AZ ko? add Read Replica? tăng instance type của DB instance?

Add Read Replica (là scaling theo chiều ngang).   
Tăng instance type của DB instance (là scaling theo chiều dọc)  

Việc enable multi-AZ chỉ để làm cho RDS có HA (high-avalability) thôi  

> Q. Số lượng Read Replica của các loại DB: RDS, Aurora, DynamoDB?

RDS có thể có max 5 `Read Replica`,  
Aurora có thể có max 15 `Read Replica`.  
DynamoDB thì **ko** có khái niệm `Read Replica` (chỉ có global table: là 1 `Read/Write Replica`),  
DynamoDB DAX thì có max 9 `Read Replica`  

> Q. Team bạn setup ASG để launch ec2, nhưng ec2 ko launch nên bạn cần debug. Lý do có thể là gì?

_AZ ko còn support  
_instance type ko còn available  
_keypair của ec2 ko tồn tại  
_Security group (SG) ko tồn tại  
_ko tìm thấy ASG  
_bạn ko subcribed cái service đó  
_EBS ko support instance-store AMI  
_placement groups ko làm dc với ec2 m1.large  
_client error  

> Q. Cty bạn host 1 app trên ec2, app sau 1 ELB. Bạn cần config Route53 với company DNS ELB. Sử dụng loại record nào của R53?
A, MX, ALIAS, AAAA record?

Dùng ALIAS 

theo AWS documents thì ALIAS record để dùng cho các service sau:  
Cloudfront, Elastic Beanstalk, ELB, S3 bucket, another R53 record

còn các lựa chọn khác:  
■ A record dùng để point 1 resource qua Ipv4 record  
■ MX record dùng cho Mail Server record  
■ AAAA record dùng để point 1 resource qua Ipv6 record

> Q. 1 Cty có 1 critical app trên VPC. Giờ bạn cần 1 list các connection dc tạo ra trên SSH port. Làm nào để rẻ và tiện?

Dùng Athena query S3 bucket nơi chưa VPC flow logs đã save

cách 2 tốn công hơn là: Export VPC flow logs ra CSV format rồi filter port SSH

> Q. Cty muốn launch các ec2, chúng cần độ trễ thấp, và network performance cao thì làm nào?

tạo 1 placement group trong single AZ  
chọn instance type loại Enhanced Networking  

> Q. 1 cty dùng Aurora MySQL, họ cần dùng Read Replica để cải thiện read performance, nhưng họ muốn Read Replica ở trên 1 region khác (cross-region read replica) thì cần chú ý gì?

Chú ý là bạn có thể tạo 5 cross-region Read Replica (cả encrypted và unencrypted)

Aurora ko tự động tạo cross-region replica, bạn phải tạo manual

> Q. Cty bạn có 1 set các resource trên AWS. Giờ muốn là tất cả những thay đổi của resource đều cần monitor lại. Nên dùng service gì? Cloudwatch? cloudtrail? Config?

Cloudtrail và Config

không dùng Cloudwatch vì nó ko cung cấp detail về những config thay đổi

AWS config giúp bạn review những config thay đổi của resource

Cloudtrail thì cung cấp monitor các account activity trên Aws acocunt bạn

> Q. Cty bạn có infra trên aws. Giờ họ muốn share project data store vơi 1 công ty khác (A), user của công ty A làm việc trên linux và sẽ access vào data đó. Cách nào để most secure và khả thi nhất?

Dùng EFS Mount Target, với 1 Security Group mở inbound NFS port cho công ty A access qua AWS Direct Connect/hoặc VPN.

EFS MOunt Target chỉ dc access với điều kiện:  
■ EC2 trong AWS VPC,   
■ EC2 trong VPC perring with other VPC,  
■ On-premise server có AWS Direct Connect hoặc AWS VPN to VPC  
Chú ý là SG gắn vào Mount Target phải mở port NFS

> Q. Cty bạn deploy 1 web app trên US-east region. Có 1 ALB config để HA. Có dùng Cloudfront @edge. Bộ phận Security yêu cầu block 1 black list IP spam tại điểm farthest point from cloud infa. Làm nào?

Dùng AWS WAF, tạo 1 Web ACL để block IP ở Global Region, và apply tại edge level Cloudfront

AWS Documents có viết:  
WAF có thể dùng để block IP, pattern in HTTP header&body, SQL injection, URL String, cross-site scripting, geographical location.  
WAF có thể làm điều trên ở tầng Cloudfront edge at Global level, hoặc tầng Applicaion at regional level

**chú ý về ACL** WAF có khái niệm *Web ACL*, còn VPC có khái niệm *Network ACL*

> Q. Cty bạn đang dùng RDS Database. Bạn cần dự toán cost. Cái nào bạn cần consider về cost khi dùng RDS?

Số giờ DB running, loại DB instance type (small hay large...)

Storage mỗi tháng

số lượng I/O request mỗi tháng

số lượng data transfer khi sang Region khác (chứ trong cùng region thì data transfer là **free**)

> Q. Bạn có 1 set Ec2, yêu cầu là tất cả EBS volume (root/data) cần preserve khi instance bị terminate, làm nào?

set giá trị DeleteOnTerminationcủa volume = False

thì khi ec2 bị terminate thì volume sẽ ko bị xóa theo, còn nếu ko set, default là cái ổ root dc set là true nên khi terminate ec2 nó sẽ bị xóa theo.

> Q. Dev team đang làm 1 web intranet, data content từ s3. Bạn cần làm 1 access policy để cho least quyền vào s3 bucket. Sẽ cần những gì?

Dùng `StringLike` và `aws:Referer` để allow `s3:getObject`
 action, Deny all other actions từ site intranet đó.

Với `StringLike` và `aws:Referer`, chỉ những request dc khởi tạo từ website đó (intranet) mới có thể get object đc.

Nếu dùng cái `IPAddress` và `aws:SourceIp` thì những ip range đó vẫn có thể get object trực tiếp từ s3 bucket

```
{
  "Version":"2012-10-17",
  "Id":"http referer policy example",
  "Statement":[
    {
      "Sid":"Allow get requests originating from www.example.com and example.com.",
      "Effect":"Allow",
      "Principal":"*",
      "Action":"s3:GetObject",
      "Resource":"arn:aws:s3:::examplebucket/*",
      "Condition":{
        "StringLike":{"aws:Referer":["http://www.example.com/*","http://example.com/*"]}
      }
    }
  ]
}
```
Rồi phải ensure là browser bạn dùng có include http referer header ở trong request

> Q. App của bạn đang muốn dùng SQS, yêu cầu là cần có 1 queue riêng để keep những msg mà ko dc process success. Dùng feature gì?

Dead-letter queue (DLQ)

> Q. Cty bạn dùng 1 số EC2, yêu cầu là các file log từ ec2 cần ship lên s3 bucket để sau này analysis. Dùng service nào?

AWS DataPipeline

Service này giúp bạn automate quá trình movement và transform data. Ví dụ log từ ec2 -> S3 -> EMR để analisis

> Q. Cty bạn dùng S3 bucket lưu docs. Bạn cần tạo policy apply cho nhiều nhân viên để họ có quyền get/put/delete object trên folder cá nhân của họ trên s3, làm nào?

```
{ 
   "Version":"2012-10-17",
   "Statement":[ 
      { 
         "Effect":"Allow",
         "Action":[ 
            "s3:PutObject",
            "s3:GetObject",
            "s3:DeleteObject"
         ],
         "Resource":"arn:aws:s3:::test2019bucket/${aws:userid}*"
      }
   ]
}
```  

> Q. Công ty bạn đã setup 1 dual tunnel VPN connection từ On-premise đến AWS. Giờ cần làm 1 kết nối dự phòng (redundant connection) trong TH VPN bị fail. Thì làm nào?

Tạo thêm 1 secondary VPN connection

Mặc dù 1 VPN connection đã có 2 tunnel để đảm bảo connection trong TH 1 cái bị fail, thì bạn vẫn cần tạo thêm 1 secondary VPN connection thì mới đề phòng dc Trường hợp customer gateway bị fail

> Q. Bạn đang run 1 ec2 và giờ muốn tăng type của ec2, làm nào?

stop, change type, start

> Q. Bạn cần publish metric lên Cloudwatch, yêu cầu là interval của metric là 1s, làm nào, dùng CLI hay Console?

publish metric high resolution, via CLI (chứ đây là **custom metric** thì không thể publish qua Console dc, phải dùng CLI)

> Q. Tạo billing alarm từ đâu? Cloudwatch? Cost Explorer? 
Tạo billng alert thì sao?

Tạo billing alarm từ Cloudwatch

Tạo billing alert từ Account Preferences

> Q. Bạn tạo 1 SAML indentity provider, những attribute nào mà SAML cần cung cấp cho AWS STS?

Role, RoleSessionName, Audience, NameID

> Q. Cty bạn có 1 set CMK keys đc define trong KMS. Bạn muốn control quyền access các key đó trong KMS thì dùng cái gì?
KMS policies hay Key policies?

Key policies, bởi vì ko có khái niệm KMS policies

> Q. Bạn đang dùng Cloudtrail log. Bạn muốn ensure là các file log này ko bị gia mạo, làm nào?

Enable tính năng `log file integrity` cho log files

> Q. Công ty bạn có 1 vendor muốn access vào AWS account của cty bạn. Bạn tạo cho họ 1 IAM user, giờ muốn tạo 1 policy cho user đó thôi thì dùng policy nào? AWS Managed policy hay Inline policy?

Inline policy thôi, khi bạn tạo inline policy thì cái policy đó sẽ ko dc sử dụng cho user khác, và khi bạn xóa user thì cái policy đó cũng bị xóa theo

## **---P4---**

> Q. 1 cty có 1 set S3 bucket, và họ lo sợ data bị stolen hoặc bị virus ransomeware tấn công, làm nào? Nên dùng tính năng nào `enable s3 versioning`, hay `enable s3 encryption`?

enable s3 versioning

chứ cái s3 encryption thì ko giúp chặn virus ransomeware dc.

> Q. Bạn muốn bật enable MFA delete s3 bucket versioning thì cần làm gì?

Dùng root account credential và làm bằng CLI

chứ cái MFA delete này ko thể dùng IAM account và Console được

Những task cần dùng root credential: tạo Cloudfront keypair, S3 MFA delete, change aws support plan (có nhiều nhưng chỉ nêu 3 cái đặc biệt thế thôi)

> Q. Bạn upload khoảng 70 TB lên S3 Glacier nhưng khi upload thì file name bị thay đổi khi đưa lên Glacier, làm nào?

1_Dùng AWS Snowball upload lên s3 rồi từ s3 move sang Galicer dùng Lifecycle rule

2_Upload lên S3 IA rồi move sang Galicer dùng Lifecycle rule

Không nên up trực tiếp lên S3 Glacier  

Không nên dùng Snowball Edge vì tốn kém

> Q. Memory utilization có phải metric built-in của Cloudwatch ko?

Không, Memory là custom metric

> Q. Cty muốn tất cả những API call đến EC2 dc log lại, và nếu có cái Termination api dc call thì sẽ notify bạn, làm nào?

Tạo 1 trail trong Cloudtrail, trail sẽ deliver log vào s3 bucket

tạo 1 lambda dc trigger khi s3 có object dạng terminate dc put vào, dùng SNS để notify

> Q. Bạn dùng Cloudwatch metric `DiskReadBytes` cho EC2, nhưng sau vài ngày vào xem thấy chỉ hiển thị 0 bytes mặc dù app vẫn đọc data đều, vì sao?

■ Có những loại metric chỉ dùng cho `instance store volumes`, ko phải EBS-backed volumes: 

DiskReadOps

DiskWriteOps

DiskReadBytes

DiskWriteBytes

■ Có những loại metric chỉ có trong `Basic monitoring`:  

NetworkPacketsIn

NetworkPacketsOut

> Q. 1 Cty có service quản lý `asymmetric key`, muốn integrate với aws thì làm nào?

Dùng CloudHSM cho `asymmetric key` để integrate với on-premise service

Chứ KMS là dịch vụ `multi-tenant key storage` & chỉ support `symetric key` thôi.

trước đây từng viết:  
CloudHSM, bạn tự gen ra encryption key và quản lý key đó  
Ephemeral backup key (EBK) dùng để encrpyt data, Persistent backup key (PBK) để encrpyt EBK sau đó save to S3 in same region với CloudHSM.

> Q. Cy bạn sẽ tạo vài RDS instance, bạn muốn tạo alarm để notify nếu có 75% instance limit dc launch thì làm nào?

Enable Bussiness/Enterprise support plan và dùng Trust advisor để check limit rồi alarm cloudwatch

chú ý là Developer support plan ko thể làm dc

> Q. Cty bạn muốn lấy trung bình CPU Utilization của all EC2 của nhiều region, làm nào?

Ko thể tạo aggregate của cross region dc. Phải là từng region. 

Và muốn làm thì phải enable detailed monitoring 

> Q. Bạn chuẩn bị deploy 1 static web lên s3. Dùng Route53 bạn đã register domain và sub-domain rồi. Vậy s3 bucket có cần phải trùng tên với domain hay sub-domain ko?

Có, cả sub-domain và domain

> Q. Bạn bị DDos attack lớn, thì nên dùng cái gì để protect website?

AWS shield advanced

hoặc WAF nhưng cái này ko chống dc DDos lớn

> Q. Cty hiện đang setup Direct connect connection từ Onpremise data centre đến 1 VPC us-west. Giờ họ lại cần connect data centre đến 1 VPC trong us-east. Đảm bảo cost-effective thì dùng gì?
Dùng AWS Direct connect Gateway hay AWS Direct Connect?

Dùng AWS Direct connect Gateway (tuy nhiên ko support connect vpc trong account khác, ko support China, ko connect trực tiếp vpc với vpc)

AWS Direct Connect thì đắt hơn

> Q. Nếu phải lựa chọn CNAME và ALIAS record trong Route53?

Luôn chọn alias, Chọn Alias chứ ko chọn CNAME record vì Alias thì có thể tạo cho cả root domain và sub domain, trong khi CNAME thì chỉ có thể tạo cho sub domain.

> Q. Cty bạn có 1 app dùng để distribute patches. User sẽ download patches update về. Họ complain về respone chậm, làm nào? 
Dùng Cloudfront, ALB, CLB, Route53?

Cloudfront, nó sẽ speed up cái tốc độ respone

> Q. Bạn có 1 EC2 dùng volume General Purpose SSD, giờ muốn tăng IOPS của volume thì làm nào?

gp2 max IOPS chỉ 16000, io1 (provisioned IOPS thì max 32000)

hoặc là đặt volume trong RAID 0 Configuration (có thể stripe các volume lại tăng thêm IOPS)

> Q. Bạn dùng EC2 và nhận thấy đôi khi CPU credit bị go down = 0. Nên làm gì?

change instance type cao lên

hoặc dùng t2.unlimited, t3.unlimited

> Q. 1 ASG có các EC2, bạn nhận thấy các ec2 mới launch ko dc liệt kê là 1 phần của aggregated metric. Làm nào?

vì các instance mới launch vẫn còn trong giai đoạn warming, giai đoạn đó sẽ phải expired xong mới dc tính vào metric trung bình

> Q. Công ty bạn sắp dc audit thì cần cấp quyền access cho auditor như nào?

tạo IAM user có quyền read log tạo bởi Cloudtrail trong s3

> Q. Công ty bạn dev app mobile, user của app đó cần access vào resource trong aws. Dùng service nào? có dùng dc AWS Federated Access ko?

Cognito, IAM role

ko dùng AWS Federated Access

> Q. Khi bạn launch EC2 gặp các lỗi sau nghĩa là gì?
`InstanceLimitExceeded`, `InsufficientInstanceCapacity`, `Instance Terminates Immediately`  

AWS Document mô tả:  
■ `InsufficientInstanceCapacity`: khi launch/restart EC2 thì có thể do AWS đang ko đủ available On-demand capacity cho bạn  
Giải pháp: chờ vài phút, hoặc chuyển AZ khác, instance type khác, giảm lượng EC2 muốn start...

■ `InstanceLimitExceeded`: vượt quá limit số ec2 có thể run trong 1 region, cần request AWS

■ `Instance Terminates Immediately`:  
_EBS volume limit has been reached.  
_EBS snapshot của cái instance đó bị corrupt (hỏng).  
_EBS root volume bị encrypt và bạn ko có quyền access vào KMS để decrypt key.  
_AMI mà bạn dùng để launch instance bị thiếu file nào đó.

> Q. Bạn vừa tạo 1 RDS instance, app của bạn sẽ config để connect RDS. Nhưng từ app đang bị lỗi “Error connecting to database” Vì sao?

Sai port

Security groups sai

RDS vẫn đang tạo và chưa available (có thể phải chờ 20 phút)

> Q. Công ty bạn có EC2, S3, PostgreSQL, EFS, giờ muốn encrpyt data at rest, những cái nào có thể encrypt mà ko làm gián đoạn user dùng?

S3 thôi

Những cái còn lại đều phải encrpyt từ đầu khi tạo, giờ muốn thì phải tạo lại

> Q. EFS có khả năng scale lên peta byte ko?

có

> Q. Bạn có web server ở 2 region us-east-1 và us-west-1, config routing policy lần lượt là latency-based và weighted-based. Khi test failover thì nếu all ec2 ở us-west-1 bị down thì traffic ko shift sang us-east-1 vì sao?

Do thiếu config `Evaluate Target Health` check = yes

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/evaluate-target-health-check.jpg)

Hình trên nếu `Evaluate Target Health` check = NO thì Route53 sẽ ko thể quay lại cái chỗ branch cha để nó switch sang region khác được

> Q. Bạn có AWS env với EC2 cho web app, CLB, RDS, bạn thấy giá trị high-value `SpilloverCount` ở trong metric của Cloudwatch, bạn nên monitor cái gì để ko còn cái giá trị này ?

`SpilloverCount` là tổng số request bị reject do surge queue is full.

Giải thích về 4 loại metric của LB đây: 

`SurgeQueueLength`: tổng số request (HTTP listener) hoặc connection (TCP listener) đang pending. Max của queue là 1024. Nếu queue bị full thì request sẽ bị reject. Số request bị reject đó sẽ hiển thị ở metric `SpilloverCount`

`RequestCount`: là số request completed trong 1 khoảng time nhất định (1 or 5 phút)

`BackendConnectionErrors`: số lượng connection fail khi connect giữa LB và Instances

> Q. Phân biệt các loại ELB: CLB, NLB, ALB (cái nào cũng có tính scalability):

Classic Load Balancer: cung cấp (HTTP, HTTPS or TCP listeners) cho only 1 backend port. Chạy bên ngoài VPC. ( Nếu app của bạn chạy ngoài VPC). Ko thể handle đc hàng triệu request 1 giây như NLB 

Network Load Balancer: Layer 4, cung cấp only TCP. Dùng EIP/static IP. Nhiều ports. Dùng với những app mà chỉ cần sử dụng TCP. Và muốn quản lý bằng whilelist IP. Có thể scale để handle workload lên đến hàng triệu request 1 giây (millions of requests per second)

Application Load Balancer: Layer7, cung cấp cân bằng tải cho only HTTP/HTTPS. Nhiều ports. flexible hơn CLB. Nhiều ng dùng. Cung cấp tính năng nâng cao về routing đến target, dùng cho các app hiện đại, micro-services, containers. Ko thể handle đc hàng triệu request 1 giây như NLB 

> Q. Bạn cần tạo stack Cloudformation, và muốn chắc chắn bạn có thể sửa lỗi bằng manually nếu có thì làm nào?

Set giá trị `OnFailure = DO_NOTHING` khi create stack, để khi xảy ra lỗi stack ko tự động rollback

> Q. Bạn dùng cloudformation tạo stack gồm có các resource trong đó có RDS, bạn muốn RDS dc giữ lại nếu stack bị delete, làm nào?

Dùng `DeletionPolicy` attribute cho các resource trong stack ở trong file template (json/yml)

> Q. Bạn muốn hệ thống của bạn trên AWS khi mà có issue với hardware host AWS resource (những phần cứng host AWS resource của bạn) thì bạn dc notify, làm nào?

Personal Health Dashboard

> Q. Bạn đang dùng RDS, muốn encrpyt data in transit làm nào?

Dùng SSL certificate mà RDS cung cấp

Edit Parameter Group của RDS instance (rds.force_ssl = true)

cuối cùng phải Reboot RDS instance

Trong AWS Document viết: Có 2 cách dùng SSL để encrypt data in transit RDS là:

■ Force SSL cho all connection (Client sẽ ko cần làm gì)
Cái này sẽ cần sửa parameter group (rds.force_ssl = true)

■ Encrpyt những connection cụ thể (setup SSL trên client computer)

> Q. Bạn dùng S3, trước đó là Cloudfront, bạn gặp 1 số lỗi 4xx error, thì đó là vì sao? lỗi 5xx thì sao?

■ lỗi 4xx liên quan đến `client`

404-Not Found

405-Method Not Allowed

414-Request-URI Too Large

■ lỗi 5xx liên quan đến `server`

500-Internal Server Error

501-Not Implemented

502-Bad Gateway

503-Service Unavailable

504-Gateway Time-out

> Q. Bạn dùng AWS CloudHSM cho SSL/TLS processing. Có incident là có user xóa key của CloudHSM làm ảnh hưởng traffic, giờ bạn cần check log của CloudHSM để xác định user nào, làm sao?
check field nào trong các field sau: Time, Reboot Counter, Sequence No, Command Type, Opcode, Session Handle, Response, Log Type

Opcode (nó chỉ ra action của command như CN_CREATE_USER, CN_GENERATE_KEY, CN_DESTROY_OBJECT, CN_CHANGE_PSWD)

Những cái khác thì:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/cloudhsm-log-code.jpg)

`Time`: thời gian in UTC,  
`Reboot Counter`: chuỗi 32-bit,  
`Sequence No`: chuỗi 64-bit,  
`Command Type`: 2 category của command (CN_MGMT_CMD, CN_CERT_AUTH_CMD),  
`Opcode`: action của cmd,  
`Session Handle`: chuỗi kí tự,  
`Response`: SUCCESS hoặc ERROR,   
`Log Type`: 4 loại MINIMAL_LOG_ENTRY, MGMT_KEY_DETAILS_LOG, MGMT_USER_DETAILS_LOG, GENERIC_LOG

> Q. Khi bạn setup VPC peering giữa 2 vpc, thì việc config routing CIDR giữa 2 VPC dc làm thế nào? tự động route table update khi VPC connection dc accept, hay phải làm bằng tay?

Phải làm bằng tay (manually) chứ AWS ko tự động config route table cho bạn

> Q. Bạn đang dùng DynamoDB, giờ muốn giảm độ trễ của request gửi vào DynamoDB thì nên dùng gì? (Global table, secondary index, DAX,  dynamodb stream?)

Nên dùng DAX (có cache cho DynamoDB, HA)

ngoài ra những cái khác thì:

Global table (multi-region master db, cũng là 1 cách giảm độ trễ)

Secondary Indexes (tăng performance khi query) 

DynamoDB stream (get notify nếu có sự thay đổi trong DynamoDB table)

## **---P5---**

> Q. Cty bạn dự định move MySQL lên RDS. Họ muốn biết là việc dùng AWS RDS thì sẽ giúp giảm công tác quản lý như thế nào cho họ?

Tạo và maintain backup để bạn có thể restore về any point in time (max 35 ngày trước) vì RDS nó upload transaction log lên s3 mỗi 5 phút

Tự động install critical security patch (bản vá bảo mật cho db)

> Q. Về VPC peering qua Ipv6 thì cần chú ý gì?

VPC Peering qua IPv6 chỉ support intra-region (trong 1 region), chú ý là ko dc overlaping IPv4 (hoặc ko cần IPv4 chỉ có IPv6 thì ok)

VPC Peering qua IPv6 không support inter-region (còn gọi là cross-region)

> Q. Web app của bạn dùng EC2, SQS. Giờ Server trên on-premise cũng cần connect SQS. Mà bạn cần giải pháp để kết nối on-premise với AWS mà bandwitch lớn, traffic secure thì làm nào?

Tạo interface endpoint trong private subnet, dùng AWS Direct Connect để nối với On-premise server, rồi từ đó interface endpoint (`PrivateLink`) sẽ giúp connect với SQS 1 cách secure 

(vì interface endpoint sẽ giúp kết nối các resource trong AWS với nhau ko cần internet)

Chú ý là interface endpoint ko support AWS VPN (thế nên dùng AWS Direct Connect)

> Q. VPC A peering với VPC B & C, B và C thì có CIDR block giống nhau (10.0.0.0/16). EC2 trong VPC B send traffic qua pcx-aaabbb đến VPC A, VPC A trả về respone ko về EC2 trong VPC B, mà về 1 EC2 trùng IP trong VPC C, làm sao ngăn chặn việc này?  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/vpc-peering-scen-1.jpg)  

Sửa cái Route table trong VPC A, thêm cái routing đến cụ thể ip EC2 nào của VPC B (more specific routing):  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/vpc-peering-scen-1-fix-1.jpg)

hoặc fix thành:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/vpc-peering-scen-1-fix-2.jpg)

> Q. Cty muốn thực hiện backup các EBS volumes, vì trong đó chứa data quan trọng, nên tạo RAID 1 config of multi volume hay dùng regular EBS snapshot?

Dùng regular EBS snapshot 

Chứ RAID 1 Config chỉ có tác dụng mirroring data (dùng cho HA)

> Q. 1 Cty lưu document trong S3. Muốn add thêm 1 layer security khi mà User muốn delete document S3, làm nào? có enable MFA Delete trên S3 bucket dc ko?

Sửa bucket policy, dùng cái condition key `aws:MultiFactorAuthPresent`, để chỉ những user đã authen vào aws bằng MFA mới delete dc docs

ko thể enable MFA Delete S3 bucket dc, vì nó chỉ dành cho root account

> Q. Cty sẽ deploy 1 số ec2, workload của các ec2 ko đổi về CPU Utilization và thi thoảng sẽ burstable performance. Nên dùng loại ec2 type nào? giữa các loại T2 T3 M5 C5 R5

chọn T2, T3, T3a (Chúng cung cấp khả năng Burstable Performance)

T Unlimited thì cung cấp high CPU Performance

M5 C5 R5 thì cung cấp Fixed Performance

> Q. 1 Cty muốn tạo connection hybrid giữa On-premise và AWS, mà cost rẻ nhất và implement nhanh, thì nên chọn cái gì? AWS VPN hay Direct Connect, hay Direct Connect Gateway?

Dùng AWS VPN,

vì nó rẻ hơn Direct Connect

Direct Connect chỉ nên dùng khi muốn low latency và bạn giàu vl

> Q. Cty dùng AWS Organization để quản lý nhiều account. Muốn deny access vào S3 của root user, chỉ cho phép IAM user thôi thì làm nào?

Dùng SCP từ tầng Master account rồi deny access s3 của root user

> Q. Nếu `SCP` (Service control policy) của AWS Organizations cho phép User access EC2, S3. Nhưng `IAM Policy` cho phép User access EC2, S3, ELB thôi. Thì User sẽ dùng dc những service nào?

Thì user sẽ chỉ có quyền access service chung giữa 2 policy đó là EC2, S3

> Q. Bạn cần setup EC2, EC2 sẽ có nhiều read/write activity. Và metric cho volume cần update mỗi 2 phút.  
Vậy thì cần chọn volume Provisioned IOPS  
hay Enable Detailed Monitoring của EBS volume?

Chọn Provisioned IOPS là đủ, loại **io1** này sẽ tự động send metric 1 phút update đến cloudwatch mà ko cần enable Detailed monitoring

> Q. Bạn dùng VPN cho cty, bạn đã tạo VGW và Customer Gateway, routing attach vào VPC. Nhưng Tunnel vẫn đang bị down. Làm sao để active VPN tunnel giữa VGW và Customer Gateway?

muốn active Tunnel thì phải init traffic từ Customer side ở on-premise location tới server trong AWS VPC.

> Q. Bạn có 1 app setup trên ec2 ELB. Muốn ensure việc HA và traffic sẽ dc distribute across các backend node thì làm nào?

launch ec2 trên MultiAZ

enable cross zone load balancing cho ELB

AWS Document viết: Khi bạn enable 1 AZ cho ELB. ELB sẽ tạo 1 `load balancer node` trong AZ đó. Mặc định là mỗi `load balancer node` chỉ distribute traffic đến các target trong AZ của nó thôi.
Nếu bạn enable cross-zone load balancing thì mỗi `load balancer node` sẽ distribute traffic across các target trên tất cả AZ đã dc enable. 

> Q. Cty bạn thiết lập AWS VPN giữa on-premise network và VPC. Đã tạo Virtual Private Gateway, Customer Gateway, VPN connection. Đã config router ở phía Customer side, và connection ở Console đã show UP. Còn thiếu gì nữa?

config router ở phía Virtual Private Gateway

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/vpn-diagram.jpg)

> Q. Nếu RDS thực hiện patching OS thì report về process việc patching đó sẽ có ở đâu?

RDS Console

> Q. Bạn thấy có issue với ASG, khi Launch Configuration update, ASG sẽ làm vài node bị offline làm ảnh hưởng customer. Team dùng Cloudformation để update app bằng cách change parameter. Làm nào để hạn chế ảnh hưởng đến customer?

Trong CF template, add cái `AutoScalingRollingUpdate` trong `UpdatePolicy` attribute, enable `WaitOnResourceSignals`, append 1 cái healthcheck ở cuối user data script để signal cho ASG biết là việc update instance đã success. 

> Q. Bạn muốn Cloudformation template luôn lấy cái Windows AMI latest khi launch thì làm nào?

_Cách 1: subcribe Windows AMI noti cho SNS và trigger Lambda update template với new AMI

_Cách 2: trong Cf template thì chỗ Parameter AMI để chỉ định cái Parameter trong SSM Parameter Store (nơi chứa các public parameter dùng cho toàn bộ AWS resource).   
Trước đó thì phải tạo 1 Parameter trong SSM Parameter Store, value kiểu như sau: `/aws/service/ami-windows-latest/Windows_Server-2016-English-Core-Containers`

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/cf-ssm-param-1.jpg)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/cf-ssm-param-2.jpg)

> Q. Cty bạn có 1 bucket đã versioning enable. Giờ muốn xóa delete bucket thì làm nào?

Xóa bằng AWS SDK (như boto3)

Xóa bằng bucket lifecycle config

Xóa bằng Console

Còn các command này thì:  
`aws s3 rb s3://example-bucket-july --force`: cái này ko xóa dc bucket đã versioning

`aws s3 rm s3:// example-bucket-july --recursive`: cái này ko xóa dc bucket đã versioning

> Q. S3 có những file hiếm khi access sau 45 days. Cách nào để reduce cost mà có thể cung cấp access vào file cho user từ 1-5 phút?

Dùng Glacier Expedited Retrieval (1-5 min)

S3 IA đắt hơn Glacier nên ko chọn

> Q. Cty migrate 500 TB lên S3, đang concern về cost, time, performance. Dùng gì? Storage Gateway hay Snowball?

nên dùng Snowball  
Snowball: cost 1562 $   
Storage Gateway: 11500 $  

> Q. Bạn dùng AWS Opswork mà cần monitor log của app dc deploy trên instance của stack trong Opswork làm nào? có Opswork log ko?

Dùng Cloudwatch logs

ko có cái gọi là Opswork logs

> Q. Bạn cần delete Customer Master Key thì cần check những gì?

Check CMK permission trong KMS để xem ai hoặc cái gì đang dùng CMK đó

Check Cloudtrail logs, để xem lịch sử sử dụng CMK đó, xem cái CMK đó có cần thiết nữa ko

> Q. Bạn đang dùng Redshift thì có những loại log nào?

3 loại:  
■ `Connection log`: những log authen, connect, disconnect  

■ `User log`: log mà làm liên quan đến db user như: Create User, Drop User, Alter User

■ `User activity log`: Log những query trước khi nó run trên DB 

Tuy nhiên thì logging của Redshift default disable. Muốn logging thì phải enable lên. 

Chú ý cái `User activity log` muốn enable thì phải set `enable_user_activity_logging=True` nữa

ko có Transaction Logs nhé

> Q. Cty bạn dùng RDS MySQL, giờ muốn disable backup của RDS bằng cách set retention period=0 nhưng bị lỗi, vì sao?

Vì bạn đang setup Read Replica thì ko set retention period = 0 được

AWS Documents viết:

■ Nếu bạn lock yourself ở ngoài cái db_owner của SQL DB. Bạn có thể reset DB instance master password để lấy lại quyền

■ DB instance reboot và hỏi bạn có `Apply Immediately?` khi bạn:  
_thay đổi rentention period từ 0 hoặc tới 0,  
_change DB instance class.

■ DB instance reboot **ngay lập tức** khi bạn:  
_change storage type (SSD, Standard)

■ DB instance reboot theo kiểu bắt bạn tự làm manually khi:  
_change static param trong DB parameter group  
(chứ nếu change dynamic param thì ko cần reboot sẽ take effect ngay)

■ DB instance hết storage space, bạn cần modify tăng storage lên 

■ Nếu bị lỗi `InsufficientDBInstanceCapacity` khi tạo/sửa db, restore db từ snapsshot thì nên:  
_thử lại với db instance class khác  
_thử lại với AZ khác, hoặc thử lại mà ko chỉ định AZ  
_1 số DB instance cần ở trong VPC  

■ MySQL version < 5.6 có thể bị lỗi khi query: nên upgrade lên version MySQL > 5.6

■ PostgreSQL lỗi connection timeout thì nên:  
_check hostname là DB instance enpoint chưa  
_check port number đúng chưa  
_check SG đúng rule chưa

> Q. Cty đang dùng Kinesis muốn encrpyt data at rest thì nên dùng server-side hay client-side encryption?

Nên dùng server-side vì đỡ tốn effort hơn

## **---P:monitoring-reporting---**

> Q. Bạn đang setting AWS Config qua CLI, bạn đã tạo S3 bucket tên 12345. Bạn ko nhận dc thông báo về change configuration của bucket đó. Vì sao?

Cái s3 bucket policy attach vào bucket cần allow AWS Config quyền record lại những thay đổi 

Cái IAM Role assign cho AWS Config CLI cần có quyền AWSConfigRole

> Q. Cty bạn là global company. Bạn muốn check xem RDS DB instance nào trên khắp các region không dc enable multi-AZ, dùng cái gì?

AWS Config hoặc Trusted Advisor

> Q. Cty Bạn có 1 EC2 run app, bên audit yêu cầu xem report những cái config change liên quan đến con server đó. Làm nào?

Dùng AWS Config Periodic rule 1h, 3h, 6h, 12h, 24h

chú ý là ko có 4h

> Q. Cty bạn có infras trên nhiều regions. Và cũng có nhiều AWS account. Giờ muốn tổng hợp report về resource count và compliance của all account all regions thì làm dc ko?

Dùng AWS Config Aggregated view

> Q. AWS Config pricing như nào, trả tiền cho những cái gì?

Bạn trả tiền cho tổng số Config rule đang active, Số lượng Config items

> Q. Các member đang tạo 1 số lượng lớn EC2. Bạn muốn evaluate xem có bao nhiêu m4.large EC2 nên bạn đã tạo AWS Config custom rule + Lambda function. Rule tạo ok, nhưng ở section `Compliance` bạn thấy lỗi `No resources in scope` Vì sao?

Cần verify lại xem cái Custom rule bạn tạo có đang record EC2 hay ko, ko thì phải add thêm vào

Chứ nếu member tạo toàn t2.micro instance thì sẽ báo tổng số Non-compliance count chứ ko phải lỗi kia

> Q. S3 Glacier đã được support bởi AWS Config Managed Rule chưa? muốn record S3 Glacier vault làm nào?

Chưa, giải pháp là:  

1_Tạo 1 lambda function để evaluate S3 Glacier vault,

2_Rồi tạo 1 AWS Config Custom Rule và assign cái Lambda tạo bên trên cho rule này

> Q. Bạn có 1 S3 bucket cần monitoring và tự correct nếu có bất kỳ policy violation thì làm nào?

Enable AWS Config để monitor bucket ACL và policy violation

Nếu detect có violation thì sẽ trigger Cloudwatch Event, rồi trigger tiếp Lambda đi correct lại bucket ACL (hoặc set bucket ACL to private)

## **---P:storage-management---**

> Q. Bạn có 1 lượng lớn document trên s3 bucket dc upload từ khoảng 10 regions trên TG. Để analyse thì bạn dùng AWS Athena + Quicksight, nhưng sau 1 tháng thấy performance thấp, cost nhiều, giờ làm nào?

Khi CREATE TABLE, dùng PARTITIONED BY để partition base on time/date.
Bạn sẽ hạn chế dc lượng data dc scan bởi query và giảm cost.

Khi chọn storage format thì chọn Apache Parquet và ORC - đây là dạng columnar storage format (thay vì dùng JSON,CSV) để Athena retrieve data nhanh nhất

> Q. Cty cần analyse data nhanh và ko có budget để dựng server thì dùng gì?

Athena + QuickSight

> Q. Bạn muốn file dc encrpyt trước khi đưa lên s3, tìm 1 giải pháp full managed và cost-effective?

KMS client-side

Khi enable client-side encryption thì bạn cần cung cấp `CMK ID` cho KMS

Khi muốn upload 1 object to s3, bạn dùng `CMK ID` để request KMS trả về: `plain-text key` để encrypt object, và `cipher blob` để làm object metadata

> Q. 1 Cty cần 1 nơi lưu trữ key kiểu `single tenant key storage` và support `asymetric key integration`. Dùng gì? KMS hay AWS CloudHSM?

Dùng CloudHSM 

Chứ KMS là dịch vụ `multi-tenant key storage` & chỉ support `symetric key` thôi.

> Q. Bạn tạo 1 vault trong S3 Glacier để lưu data lâu dài, cần ensure là ko có thay đổi hoặc deletion xảy ra trong đó. Nhưng vẫn cần vào đọc nhiều lần. Dùng policy gì?

Vault Lock Policy

> Q. Bạn cần lưu document 1 chỗ khoảng 5 năm mà sẽ ko cho bất cứ ai sửa. Bạn dùng vault trong s3 glacier. Bạn cần setup Vault Lock thì cần chú ý gì?

Init Vault lock với Vault Lock policy rồi đi vào trạng thái `in-progress`

Phải hoàn thành Vault Lock trong vòng 24h sau khi Init

Sau khi vault đã locked thì ko thể unlock

Nếu ko hoàn thành Vault lock trong 24h thì vault lock policy sẽ bị remove và sẽ phải làm lại

> Q. Trong cái GET URL sau `s3.amazonaws.com/mybucket/photos/2014/08/puppy.jpg?x-user=johndoe` thì `x-user=johndoe` nghĩa là gì?

S3 sẽ ignore những query bắt đầu bằng `x-`, tuy nhiên sẽ lưu lại trong access log record.

> Q. Phân biệt aws gateway cached volume và aws gateway stored volume?

Aws gateway cached volume: lưu data trên s3, 1 cục cần access thường xuyên sẽ lưu locally. dễ scale, độ trễ thấp

Aws gateway stored volume: data sẽ lưu hoàn toàn ở locally, rồi snapshot sẽ dc async lên s3

## **---P1-udemy---**

> Q. Team member của bạn upload Django project lên Beanstalk. Nhưng gặp lỗi `The instance profile aws-elasticbeanstalk-ec2-role associated with the environment does not exist.` Vì sao?

Beanstalk CLI chưa thể tạo instance profile role nếu IAM role của nó ko có quyền tạo role 

Hoặc là instance profile role đã tạo nhưng bị insufficient hoặc outdate với những gì mà Beanstalk cần

> Q. Bạn cần dựng 1 web app mà web server cần connect to internet và Db server thì ko, vậy nên dựng ELB như nào?

internet-facing load balancer cho web server

internal load balancer cho db server

Nếu có thêm yêu cầu db server cần init Ipv4 traffic ra Internet và chặn việc nhận traffic từ internet thì mới cần NAT Gateway (or NAT instance),  
nhưng sẽ cần NAT ở trong `public subnet`

> Q. Cty bạn tạo 1 VPC với 1 subnet, sẽ có 20 instance bên trong thì CIDR block sẽ phải là 172.0.0.0/x, x sẽ là bao nhiêu 27 28 29 30?

cách tính là 2 step: Giả sử x = 27  
★ 32 - 27 = 5   
★ 2 mũ 5 = 32 (suy ra VPC của bạn có 32 ip available)   

★ Tuy nhiên trong AWS, 4 ip đầu tiên và 1 ip cuối cùng trong mỗi subnet bạn sẽ ko dùng dc:  
-> 32 - 4 - 1 = 27 (số ip bạn có thể assign cho instance)  

★ Chú ý nữa là block size dc cho phép chỉ là giữa /28 và /16 thôi  
Thế nên /29 và /30 là loại ngay

> Q. Bạn cần migrate data **80 TB** lên s3 thì nên dùng gì cho rẻ và nhanh? 
Snowball thường, Snowball Edge, Storage Gateway?

Snowball thường thì 1 cái appliance chỉ usable 72 TB data thôi, nghĩa là phải dùng 2 cái appliances -> thành ra giá đắt hơn Snowball Edge

Snowball Edge usable 80 TB data/100 TB nên đủ -> nên dùng

Storage Gateway thì mục đích chính của nó ko phải để migration, với lại nó sẽ dùng Internet để upload nên chậm

> Q. Bạn cần monitor dashboard cho EC2 và on-premise server thì cần làm gì?

IAM Role và User để dùng cho Cloudwatch Agent  

Install CW agent trên cả EC2 và On-premise server  

Tạo CW agent configure file

> Q. S3 bucket store data. Bạn cần generate 1 report trên replication và encryption status của object. Dùng gì?

S3 Inventory để gen ra report

> Q. Phân biệt về 2 policy: Latency routing và Geolocation routing của Route53?

`Latency` routing chỉ đảm bảo về term "latency" chứ ko đảm bảo traffic dc route đến resource gần nhất.

Thế nên 1 số trường hợp Ví dụ như bạn có 2 server ở UK, US,  
yêu cầu của Compliance là data của User ở UK cần đặt ở UK, data user ở US cần đặt ở US,  
thế thì phải dùng `Geolocation` để đảm bảo user ở đâu thì họ sẽ dc route đến server đặt data của họ ở đó

Ngoài ra thì nếu User ở 1 chỗ khác UK và US thì bạn cần tạo 1 record default chứ nếu ko R53 sẽ respone "no answer"  

Còn cái `Geoproximity` thì dùng khi bạn có 1 cái instance size rất lớn ở 1 region và muốn route user đến cái server đó

Ngoài ra:  

Multivalue answer routing policy: route traffic 1 cách ngẫu nhiên đến max là 8 record healthy.
 
Simple routing policy: Dùng 1 resource cho 1 domain.  

Latency routing policy: Nếu có nhiều resource thì sẽ route traffic đến location có best latency nhất.  

Weighted routing policy: route traffic đến nhiều resoure theo tỉ lệ bạn defined.  

Geoproximity routing policy: route traffic dựa trên location của resource của bạn.  

Geolocation routing policy: route traffic dựa trên location của user.  

Failover routing policy: dùng để configure Active/passive failover.  

> Q. Bạn cần terminate ec2 trong ASG mà không update size của ASG thì dùng command nào?

`terminate-instance-in-auto-scaling-group --instance-id <value> --no-should-decrement-desired-capacity`

nhớ là `--no-should-decrement-desired-capacity` chứ ko phải `--should-decrement-desired-capacity`

> Q. Bạn cần host Oracle DB trên Ec2 mà data cũng access ko thường xuyên lắm, chọn loại EBS nào cho cost-effective?

Cold HDD

Chứ General purpose SSD mục đích chính ko phải host db, tốn tiền hơn

Provisioned IOPS HDD để host db nhưng tốn tiền hơn

Throughput Optimized HDD thì cost cũng thấp nhưng ko thấp bằng Cold HDD, và data đó là cho access thường xuyên

> Q. Bạn cần setup Disaster Recovery infra, họ cần 1 giải pháp quick recovery và cost effective, so sánh warm standby, backup & restore, pilot light?

Dùng pilot light

So sánh:  

về giá thì `backup & restore` < `pilot light` < `warm standby`   
về recovery time thì càng đắt càng recovery nhanh 

pilot light thì chỉ những core element dc run all the time (db server replica chẳng hạn)

warm standby thì giống như hệ thống thật nhưng là version bị scale down và run all the time

https://tutorialsdojo.com/aws-cheat-sheet-backup-and-restore-vs-pilot-light-vs-warm-standby-vs-multi-site/

> Q. Bạn cần install và config app trên 1 ec2 mà bạn sẽ deploy bằng CF, sẽ dùng policy gì trong cái CF template? UpdatePolicy, UpdateReplacePolicy, CreationPolicy ?

Dùng `CreationPolicy`

chứ dùng UpdatePolicy khi bạn muốn update resource của stack

còn dùng UpdateReplacePolicy khi bạn muốn backup cái ec2 hiện tại khi nó sắp bị replace bởi update stack

> Q. Nếu khi launch EC2 bị lỗi `EC2 instance <instance ID> is in VPC. Updating load balancer configuration failed` nghĩa là sao?

LB đang thuộc loại EC2-Classic, ASG thì ở trong VPC

> Q. Kinesis và Redshift cơ bản là làm gì?

Kinesis là service để collect data real-time  
còn Redshift là service để storage peta-byte data cho OLAP app (online analysis processing)

> Q. So sánh Snowball và Snowmobile?

Snowmobile dùng cho dataset tầm 10 PB (petabyte) trở lên.  

Còn nhỏ hơn 10 PB thì dùng Snowball thường thôi

> Q. Cần 1 service để phân tích behavior của AWS resource từ đó xác định những issue về security tiềm tàng thì dùng gì?

AWS Inspector

> Q. AWS Trusted Advisor và AWS Performance Insights thì cái nào giúp bạn phân tích issue về Database?

AWS Performance Insights

> Q. Bạn có 1 volume Provisioned IOPS size là 10 GB, vậy thì max IOPS có thể set là bao nhiêu?

công thức là IOPS:VolumeSize = 50:1

=> 10 GB thì max IOPS = 500 (input/output per second)

> Q. Cty có 1 VPC cần connect với on-premise network, thì AWS resource cần cung cấp những gì?

Internet Gateway attach to VPC

Virtual Private Gateway

việc tạo EIP hay public IP, hay additional ENI (network interface) là ko cần thiết

> Q. Route53 có thể thực hiện bao nhiêu loại healhcheck?

3 loại:

healthcheck mà monitor 1 enpoint

healthcheck mà monitor những healthcheck khác

healthcheck mà monitor Cloudwatch alarm

> Q. Bạn cần investigate hệ thống nên cần suspend ASG scaling process tên là `Terminate`, khi đó thì nó sẽ ảnh hưởng như nào đến AZ rebalance process của ASG?

ASG sẽ có thể tăng lên max là thêm 10% so với maximum size

Còn nếu suspend `AZRebalance` process, khi đó nếu scale-out thì nó vẫn cố gắng rebalance AZ với bằng cách launch thêm 1 số ít nhất EC2

CÒn nếu suspend `Launch` process, AZRebalance sẽ ko xóa hay tạo thêm EC2

> Q. Bạn có 1 bucket S3 cần delete. Bucket đó đã dc enable versioning và MFA delete. Bạn cần làm gì để xóa?

Cách 1_Remove cái bucket policy mà yêu cầu MFA delete, Rồi dùng SDK để xóa bucket's markers và version, Rồi xóa lại bằng CLI command

Cách 2_Dùng root account để suspend MFA và versioning feature đi. Rồi Config Lifecycle để remove version, xóa object và markers, rồi delete bucket again

## **---P2-udemy---**

> Q. Để 1 EC2 có thể communicate ra Internet qua IPv6 thì VPC cần config như nào?

_associate /56 CIDR block cho VPC

_associate /64 CIDR block cho subnet

_tạo custom route table rồi associate cho subnet

Việc setup egress-only gateway chỉ để tác dụng là VPC ipv6 chặn connect từ internet vào trong

> Q. Bạn có 1 S3 bucket mà dạo này user complain là toàn lỗi 503. Vì sao?

Có object nào đó có hàng triệu version, khi đó s3 sẽ throttle các request đến bucket

Giải pháp là dùng S3 inventory tool để xác định object nào

> Q. Bạn có 3 VPC và muốn ensure là các ec2 trong đó có thể communicate với nhau thì làm nào?

Setup VPC Peering `full mesh` config cho cả 3 VPC (`full mesh` nghĩa là 3 cái VPC sẽ peering từng cặp với nhau)

Ensure là all route table của mỗi VPC dc setup

ENsure là VPC ko bị overlapping IPv4 CIDR block

> Q. Bạn dùng PostgreSQL run trên EC2, nó sẽ dc dùng bởi nhiều internal app trong VPC của bạn. Bạn muốn đơn giản việc naming convention bằng cách đặt 1 custom domain name cho cái DB server, làm nào?

setup private hosted zone trong Route53.  
Tạo A hoặc AAAA record,  
specify IP của DB server vào record đó

> Q. Bạn cần 1 tool để có thể coordinate nhiều AWS resources với nhau, vào 1 serverless workflow, dùng cái gì? SWF hay Step Function?

Dùng Step Functions

Chứ SWF là service để track state và task, nó cũng ko phải là serverless orchestration cho nhiều resource

> Q. Bạn muốn enable Cloudwatch Detailed monitoring cho Auto Scaling Group thì có được ko?

có, nhưng sẽ bị tính phí

Nếu Basic monitoring cho ASG thì ko tính thêm phí

Cloudwatch monitoring support cho hầu hết các AWS Services

> Q. Cty bạn có nhiều thiết bị đo nhiệt độ muốn gửi data custom metric lên AWS Cloudwatch để xem trên AWS 1 cách graph visually, thì có dc ko?

Dùng CLI or API để upload data metric lên Cloudwatch

> Q. Cty bạn dùng heavily used RDS, giờ muốn chắc chắn rằng ko có outage khi thực hiện snapshot cho DB thì làm nào? Multi-AZ hay Read replica?

Design DB kiểu Multi-AZ và Snapshot sẽ thực hiện trên con Standby

còn nếu Read Replica thì mặc dù cũng ko có outage nhưng mà do `replica lag` nên có thể có nhiều transaction chưa kịp đồng bộ từ con master sang con replica tại thời điểm đó (đây là heavily used RDS và ko quan tâm cost)

> Q. Bạn có 2 subnet trong VPC, EC2 trong 1 subnet ko ping dc EC2 còn lại vì sao?

Cần check lại config của SG  

và check Network ACL có cho phép ICMP traffic ko

> Q. Bạn thấy website của bạn có CPU usage trên EC2 instance 90% và CPU usage DB chỉ 20% nên làm gì để cải thiện respone time?

Đổi loại EC2 instance type khác,  

Config cho ASG của EC2 sẽ base trên CPU load để scale out

> Q. S3 bucket Access control list (ACL) có những loại quyền gì?

READ

WRITE

READ_ACP

WRITE_ACP

FULL_CONTROL

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/s3bucket-acl-permission.jpg)

> Q. Khi bạn cần apply cái s3 server side encryption cho bucket của bạn, và bạn sẽ sử dụng cái key của bạn thì trong header của reuqest cần có gì?

1_  `x-amz-server-side​-encryption​-customer-algorithm` (nếu dùng cái này thì value phải là AES256)  
2_  `x-amz-server-side​-encryption​-customer-key`  
3_  `x-amz-server-side​-encryption​-customer-key-MD5`  

> Q. `network packet sniffing` thuộc trách nhiệm của Customer hay AWS?

AWS chịu trách nhiệm protect người dùng khỏi việc đánh cắp các gói tin network

> Q. Cty bạn có 1 app host trên EC2 và ALB, Có 1 member thay đổi ALB dẫn đến app bị down, cần monitoring changes dc tạo ra trên ALB, thì cái ELB healthchecks có phải là service giúp monitor info của ELB ko?

ko, ELB healthchecks chỉ check info của EC2 có health hay ko thôi

> Q. Cloudfront có offer tính năng monitoring ko?

Có, monitor, report, access log để tracking activity

> Q. Bạn muốn S3 tự phân tích storage và khi mà lượng access vào content ít thì sẽ transit chúng vào S3-IA, sau đó tạo lifecycle policy để transit tiếp vào Glacier, dùng gì?

S3 analytics

> Q. Bạn có những RDS db instances, trong 1 VPC. Cần làm nào để make maximum security cho db và db connection? Có nên dùng Db security group ko?

tạo snapshot của db instance rồi start 1 db mới dc encrypted từ bản snapshot đó

dùng SSL cho RDS để encrypt traffic

tạo riêng VPC SG cho EC2 và VPC SG cho DB

*ko nên dùng DB SG vì đó là EC2-clasic platform, ko phải VPC platform

> Q. Auto Scaling Group ASG giúp bạn tự động scale các loại resource nào? có thể scaling ra 1 region khác ko?

EC2, 

EC2 spot fleet, 

ECS,  

DynamoDB,  

và **Aurora**

*ko thể làm với resource ở region khác

> Q. Sự khác biệt giữa HTTP, TCP?

★ Trước khi bạn dùng ELB, bạn cần config 1 or nhiều listener cho CLB của bạn, listener có nhiệm vụ check các request connection. Listener dc config với 1 protocol và port cho LB của front-end, 1 protocol và port cho LB của back-end

★ ng ta dùng SSL protocol để secure cho HTTP layer (khi đó gọi là HTTPS protocol)

★ cũng có thể dùng SSL protocol dùng để secure cho TCP layer

★ Nếu frontend dùng TCP hoặc SSL thì backend cũng có thể dùng TCP hoặc SSL

★ Nếu frontend dùng HTTP hoặc HTTPS thì backend cũng có thể dùng HTTP hoặc HTTPS

★ Khi dùng TCP (layer 4) cho cả frontend và backend thì: LB sẽ forward request đến backend mà **không** modify headers

★ Khi dùng HTTP (layer 7) cho cả frontend và backend thì: LB sẽ modify (hoặc gọi là parse) headers của request, rồi terminate connection, rồi mới forward request đến backend

> Q. Khách hàng đang sử dụng ELB, để enhance security nên bạn muốn config ELB với SSL dùng 1 policy được define trước quá trình negotiate SSL connection giữa ELB và client. Dùng cái gì để ensure là ELB sẽ quyết định cipher nào sẽ được dùng cho SSL connection, (chứ ko phải tuân theo thứ tự cipher từ phía client) ?

Server Order Preference

Default thì cái cipher đầu tiên trong client's list mà match với 1 cipher nào đó của ELB's list sẽ được chọn để dùng cho SSL connection.  
Nhưng nếu ELB được config với `Server Order Preference` thì cái cipher đầu tiên của ELB's list mà match với 1 cipher nào đó trong client's list sẽ được chọn để dùng cho SSL connection. Config này đảm bảo ELB sẽ được quyết định cipher nào dùng cho SSL

> Q. Bạn có thể tạo 1 ELB với những feature nào về security?
`SSL Server Certificates`, `SSL Negotiation`, `Back-End Server Authentication`, `Front-End Server Authentication`

ko thể có `Front-End Server Authentication`, chỉ còn 3 cái kia

> Q. Bạn muốn cho phép 1 admin vào setup EC2, EC2 đó cần quyền access vào DynamoDB. Những policy permission gì cần để đảm bảo security?
Cần trust policy tác dụng gì?  
IAM permission policy tác dụng gì?  

Trust policy cho phép EC2 Instance assume role  
IAM permission policy cho phép **User Pass role** to EC2  

Nói chung chỉ cần nhớ `User Pass Role` là được

> Q. Có thể lấy ở đâu cái Credential Report của List các AWS User gồm current status, access key age, MFA or not?

AWS IAM Console -> download Credential Report

> Q. Bạn có 1 VPC with a CIDR block of 10.0.0.0/16, trong đó có 1 subnet có CIDR giống với VPC. Bạn định tạo 1 subnet thứ 2 (CIDR 10.0.1.0/24) nhưng bị lỗi, làm thế nào? Có nên sửa cái CIDR của subnet thứ 1 ko?

Bạn phải associate 1 secondary IPv4 CIDR block vào VPC để tăng size cho VPC đó. Thì sau đó mới add thêm cái subnet thứ 2 dc

> Q. Bạn có 1 VPC với primary IPv4 CIDR block of 10.0.0.0/24, và 4 secondary IPv4 CIDR block nữa.
Gần hết các IP đã đc dùng và bạn phải tăng size để có thể add thêm EC2. Làm nào? lại add thêm secondary IPv4 CIDR block à?

Chỉ có thể tạo tối đa 4 secondary IPv4 CIDR block thôi.  
Thế nên phải xóa cái subnet nào ko sử dụng đi, để có thể tạo subnet mới

> Q. Bạn dùng API Gateway và Lambda, bạn muốn trace và analyze các user request gửi đến API Gateway thì dùng service nào của AWS? VPC Flow Log hay Cloudtrail hay X-Ray?

Dùng AWS X-Ray, nó cho bạn khả năng debug và analyze việc tracing user request để tim root cause về performances

Cloudtrail chỉ dùng cho API logging (chứ ko phải tracing),  
VPC Flow Log thì ko tốt bằng X-Ray

> Q. Bạn đang serve content từ S3 và dùng CloudFront để tăng tốc độ deliver content đến user toàn cầu. Bạn muốn improve service của bạn nên cần lấy report về hệ thống hiện tại từ CloudFront thì Cloudfront cung cấp những loại report như nào?  
`Cache Statistics Reports`, `Top Referrers Reports`, `Usage Reports`, `Popular Objects Report`, `Viewers Reports`?

`Top Referrers Reports`: List ra 25 website domain mà tạo ra HTTP/HTTPS request đến object của bạn

`Usage Reports`: Số lượng về các request HTTP/HTTPS mà Cloudfront phản hồi từ edge location 

`Popular Objects Report`: Những object nào được access thường xuyên nhất

`Viewers Reports`: Xem location của những user access vào xem content nhiều nhất, và họ đang dùng loại browser nào

`Cache Statistics Reports`: Get dữ liệu của các request được nhóm lại bởi HTTP status code

> Q. Bạn đang dùng RDS và muốn monitoring về CPU và Memory của các process chạy trong RDS Instance. Nên làm gì?

Enable Enhanced Monitoring trong RDS

chứ ko dùng Cloudwatch, vì Cloudwatch chỉ lấy metric về CPU utilization của DB Instance thôi, còn RDS Enhanced Monitoring thì lấy metric từ cái agent trong DB đó


## **---P3-udemy---**

> Q. Cty bạn có 1 website và có 2 môi trường UAT và dev. Bạn deploy app lên 1 EC2 m1.small. Khi test nhận thấy là performance giảm xuống khi tăng workload ở môi trường UAT. Làm nào? Có nên enable Enhanced Networking ko?

Dùng EC2 size to hơn m1.small, chứ Enhanced Networking ko support EC2 m1.small (chỉ support m4,m5,c5..etc thôi)

> Q. 1 cty đang dùng MongoDB và NGINX server. Họ muốn 1 service có thể cung cấp 200,000 IOPS trong 4000 random I/O Read cho Database. Thì nên dùng loại Volume nào? (io1? st1? sc1...)

Storage Optimized Instances 

`Storage Optimized Instances` được design cho workload lớn, đọc và ghi (Read write) liên tục vào Dataset cực lớn. Ví dụ i3.4xlarge có thể cung cấp 825,000 Random Read IOPS và 360,000 Write IOPS.  

chứ các instance như `Provisioned IOPS SSD (io1) EBS Volumes` max có 64k IOPS thôi

> Q. Bạn đang có 1 portal 20 EC2, chia 4 regions. 1 ALB dc setup trên mỗi region để distribute traffic. Làm nào để duy trì availability nếu 1 trong 4 regions bị disconnect?

Set Evaluate Target Health check = `true`  

và setup Latency Based Routing cho Route53, tạo record set mà sẽ resolve đến ALB trên mỗi regions

Ví dụ như này: Bạn có ELB ở `Oregon và Singapore`, bạn tạo 1 latency record cho mỗi ELB đó. Khi 1 user ở `London` truy cập vào domain của bạn thì:  
1-DNS route cái query đến R53  
2-R53 refer về độ trễ giữa London ⇔ Singapore và London ⇔ Oregon  
3-Nếu độ trễ giữa London ⇔ Oregon là thấp hơn, thì R53 sẽ reponse cái IP của ELB ở Oregon  

> Q. Bạn có vài S3 bucket giữ các thông tin quan trọng. Bạn có 1 app (ở private subnet) cần edit file trong S3 rồi tạo report gửi đến công ty partner  qua internet public. Bạn đã tạo S3 VPC Enpoint rồi cần làm gì nữa?

Update Route table của Private subnet để connect trực tiếp với S3 VPC enpoint còn send outbound traffic thì qua NAT Gateway

> Q. Những service nào sau đây cung cấp khả năng backup automatic và rotation backup mà user có thể config? S3, EC2, RDS, Redshift, EFS?

RDS và Redshift (Redshift default đã bật tính năng automated backup rồi, với 1 retention day. RDS thì vốn đã có)

S3 ko có backup policy, vốn nó đã rất durable và ko cần option backup

EC2 thì muốn backup thì cần làm tay (hoặc giờ đã có service AWS Backup gì đó, nhưng đang giả sử chưa có)

EFS thì vốn đã HA và durable rồi, ko có option backup

> Q. Về Route53 health check. Nếu >18% Health checker report là healthy thì R53 sẽ consider nó là healthy. Vậy những HTTP/HTTPS status codes nào trả về thì R53 sẽ nhận là healthy?

2XX, 3XX

> Q. 1 Cty về data analytics sắp mở 1 số service. Bạn cần tạo 1 Cloudformation template sẽ init 1 số service quan trọng trước, trong CF template đó cần tạo những gì?

EC2, Redshift, EMR configuration

(chú ý là công ty về data analytics nên cần Redshift, EMR...)

> Q. Bạn là Database engineer, đang cần setup storage cho EC2 Server. Mỗi server cần handle lượng lớn DB workload. Họ cũng cần phải secure và seprate để keep các file backup và logs. Nên dùng gì làm root volume, dùng gì làm file system để cost-effective?

Dùng `EBS-Provisioned IOPS SSD` volume để làm root volume (vì nó được optimized để high disk read/write performance)

Dùng `Cold HDD` volume để làm file system (vì nó rất rẻ và great cho data access ko thường xuyên infrequently)

Ko dùng `EFS` vì đắt, ko dùng `Throughput Optimized HDD` vì nó tập trung vào throughput hơn là IOPS nên có thể ảnh hưởng đến database performance

> Q. Bạn có subnet A có 2 EC2, giờ tạo thêm subnet B. Nếu xóa subnet A thì sao?

Sẽ ko xóa dc, vì phải xóa hết EC2 trong ấy đi đã. Còn việc xóa route của nó thì sẽ tự động bị xóa khi bạn xóa thành công subnet

> Q. 1 Cty đang có 1 platform host trên EC2 sau ASG, và 1 CLB với HTTPS listener. Họ yêu cầu thay thế cái certificate hiện tại trong load balancer bằng cái cert mới mà đã upload lên IAM. Và cần làm bằng CLI, làm nào?

1-`aws iam get-server-certificate` để get ARN of the certificate.  

2-`aws elb set-load-balancer-listener-ssl-certificate` để add cert mới vào LB

> Q. Bạn có 1 VPC với CIDR block 10.0.0.0/16. Bạn cần tạo connect từ VPC tới data center. Đã có 1 public subnet CIDR (10.0.0.0/24) và 1 VPN-only subnet (10.0.1.0/24) cùng với VPN Gateway (vgw-51898). Để cho phép traffic ra ngoài internet, bạn đã setup NAT instance (i-918273). Data center có CIDR 172.16.0.0/12. Vậy config của Main Route table và Custom Route table nên như nào?

`Custom Route table` associate với Public Subnet:  
| Destination | Target |   
|-------------|--------|  
| 10.0.0.0/16 | local  |  
| 0.0.0.0/0   | igw-id |  
 
`Main Route table` associate với VPN-only Subnet:  
| Destination | Target |    
|-------------|--------|  
| 10.0.0.0/16 | local  |  
| 0.0.0.0/0   | vgw-id |   

Chú ý Destination là CIDR của VPC chứ ko phải của Subnet

 ![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/diagram-vpc-with-vpn-only-subnet.jpg)

> Q. Về Cloudformation thì có những cái anatomy nào là bắt buộc, cái nào là optional?

Chỉ có Resource là bắt buộc phải có. Ngay cả Format Version như `AWSTemplateFormatVersion` cũng chỉ là optional

> Q. Phía AWS chịu trách nhiệm gì trong hệ thống infra của bạn?

Phía AWS chịu trách nhiệm:  

Quản lý Global infra cái run all your service  

Patch và update OS

Bảo vệ Network traffic **tầng abstract service** như S3, Dynamo

Còn phía bạn cần có trách nhiệm:  

Client side data encryption và data integrity authentication.  

Server side encryption (file system and data)

Bảo vệ Network traffic của bạn 

 ![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/aws-customer-responsibility.jpg)

> Q. 1 Cty có nhiều VPC trên nhiều regions. Để monitor hệ thống bạn cần lấy aggregate CPU Utilization của các EC2 running trên all VPC. Làm nào?

Setup Cloudwatch Dashboard, add 1 widget mỗi region, lấy aggregate CPU Utilization all EC2 trong mỗi regions. (Chứ ko thể setup all regions dc)  

Bật Detailed Monitoring cho các EC2 (Bắt buộc phải bật cái này vì Cloudwatch chỉ lấy aggregate dc của các EC2 đã bật cái này thôi)

> Q. 1 App muốn user của họ có thể send pic, videos lên. Login bằng Social media account và app sẽ lưu detail vào DynamoDB. Cần dùng những service gì?

Dùng `AWS Cognito` và `AWS IAM Roles`

Việc dùng `Federated Access` là sai

> Q. Bạn có 1 hệ thống ASG các EC2 chạy trên các AZ, và 1 CLB. Bạn nhận thấy có nhiều lỗi 4xx. Giờ nên enable VPC Flow Logs hay Load Balancer access log để lấy Client IP và request path?

Nên dùng enable access log của Load Balancer, chứ ko cần lấy IP address của toàn bộ traffic ra vào VPC

> Q. Nếu Instance bị lỗi `Insufficient Instance Capacity` thì có thể root cause là gì?

Do hiện tại AWS Ko có đủ available capacity về số lượng instance On-demands

> Q. Bạn có 1 S3 bucket lưu các thông tin của user. Bucket cần dc monitor để secure. Nhiệm vụ của bạn là `automate the assessment of your resource configurations and resource changes`, thì cần làm gì? Config bucket policy dùng IAM role? Hay dùng policy deny unauthored User? hay AWS Config?

Dùng AWS Config, vì yêu cầu là automate việc đánh giá/theo dõi resource thay đổi

> Q. Giữa AWS Shield Advanced và AWS WAF khác nhau như nào?

AWS Shield Advanced là cái đắt tiền tác dụng chống DDoS attacks

chứ WAF chỉ có thể chặn các common attack như SQL injection, cross-site scripting thôi, ko chống dc DDoS attack

> Q. Bạn được yêu cầu assess (theo dõi) behaivor của các resource như EC2, để xác định nhưng nguy hiểm về security. Bạn cần bản report về các activity diễn ra trong EC2 ví dụ như detail về sự giao tiếp với các service khác. Service nào sẽ giúp bạn làm điều này? Trusted Advisor hay Inspector?

AWS Inspector

Nói chung cứ Security Assessment, Network Assessment thì phải là Inspector

> Q. 1 website cung cấp livescore, tin tức, hình ảnh thể thao. Đang đc dựng trên hệ thống ASG multi-AZ, dùng ALB (Application Load Balancer). Gần đây vì Worldcup nên traffic tăng lên, người dùng báo cáo là load chậm. Giải pháp nào để scale và cải thiện load time của website?
`Cloudfront`? hay `NLB`? hay bật `Enhaced Networking`?

Dùng Cloudfront vì nó cung cấp khả năng deliver content đến user 1 cách low latency, tốc độ transfer cao.

Ko phải NLB vì nó chủ yếu dùng để load balancing cho TCP traffic, handle hàng triệu request mỗi giây với độ trễ cực thấp, tuy có thể tăng performance nhưng nó **ko phải** giải pháp để tăng thời gian load time của website trên toàn thế giới (respone time around globe)

Ko phải Enhanced Networking vì nó chủ yếu để cho phép high-performance networking đối với 1 số loại EC2 cụ thể mới support

> Q. So sánh 4 cái sau: `Cost Optimization Monitor`? `TCO calculator`? `Simple Monthly Calculator`? `AWS Pricing page`?

1-`Cost Optimization Monitor`: report cho về chi phí operation chi tiết. Generate report và cung cấp insight về service usage và cost

2-`TCO calculator`: dùng để compare cost của on-premise hoặc môi trường hosting truyền thống so với AWS

3-`Simple Monthly Calculator`: dùng để estimate billing hàng tháng. Nhưng ko generate report 1 cách chi tiết như cái `Cost Optimization Monitor`. Và nó cũng ko monitor cost hiện tại mình đang chịu

4-`AWS Pricing page`: chỉ show ra thôi, chứ ko gen ra report cho bạn.

> Q. Những task mà bạn có thể perform bằng sự tự động của System Manager cho EC2 của bạn?

Build Automation **workflow** để config và quản lý EC2

Tạo custom **workflow** hoặc sử dụng cái workflow mà AWS đã defined sẵn

Nhận noti về Automation **Workflow**/Task bằng Cloudwatch Event

Monitor quá trình **Automation** và chi tiết về quá trình execute

Nói chung có chữ Automation hoặc workflow thì là task của SSM

> Q. Bạn muốn monitor system infra. Bạn đã có 1 custom shell script để check memory ultilization của EC2 rồi. Giờ bạn muốn dc notified mỗi khi memory breach threshold thì làm nào?

Cài Cloudwatch agent trên EC2 nó sẽ đọc cái custom metric script mà bạn đã chuẩn bị

Setup 1 cái CW alarm base trên cái custom metric 

set SNS topic để nhận noti

> Q. CloudWatch alarms có thể có những trạng thái nào?

`OK`  
`ALARM`  (metric outside khỏi threshold đã defined)  
`INSUFFICIENT_DATA`  (alarm vừa start, hoặc metric not available, hoặc ko đủ data cho metric)    
ko có trạng thái Pending đâu nhé  

> Q. Về AWS Risk and Compliance Whitepaper?

Khách hàng dc tùy chọn data của họ ở trong region vật lý nào, AWS sẽ ko di chuyển mà ko thông báo với user, trừ khi có yêu cầu của chính quyền

AWS ngăn chặn việc xâm nhập vào host vật lý hoặc ảo hóa mà user ko có quyền sở hữu, ko dc assign

Khách hàng retain quyền và sự sở hữu về data của họ (AWS ko can thiệp)

Chú ý là AWS ko cho bên third-party nào deliver service của AWS đến KH

AWS ko cho phép các auditor làm 1 **tour** vào data center để validate hệ thống đâu nhé

AWS ko notify khi hệ thống của họ cần bring offline, bởi vì việc maintain và patch hệ thống sẽ ko ảnh hưởng đến KH

> Q. 1 cty đang host web app e-commerce và blog fetch data từ database. 1 số bài viết (static web page) có nhiều truy cập làm app hoạt động chậm. Phải làm sao để giảm load time như vậy? ElastiCache? hay S3? hay Read replica cho DB?

Dùng S3 để host các web pages

Việc dùng ElastiCache chỉ để caching content dc fetch thường xuyên từ DB

Read replica chỉ để scaling những web mà nặng về đọc

> Q. Bạn quản lý 1 hệ thống batch chạy trên EC2 và CLB. EC2 deploy trên 3 AZ us-west-2a, 2b, 2c. Bạn nhận thấy EC2 trong 2b thực hiện các request rất chậm. Cần monitor metric nào để biết dc tổng số request hoặc connection đang pending trước khi dc route tới 1 EC2 khỏe mạnh healthy?
`SurgeQueueLength` hay `RequestCount` hay `BackendConnectionErrors` hay `SpilloverCount` ?

dùng `SurgeQueueLength`: tổng số request (HTTP listener) hoặc connection (TCP listener) đang pending. Max của queue là 1024. Nếu queue bị full thì request sẽ bị reject. Số request bị reject đó sẽ hiển thị ở metric `SpilloverCount`

`RequestCount`: là số request completed trong 1 khoảng time nhất định (1 or 5 phút)

`BackendConnectionErrors`: số lượng connection fail khi connect giữa LB và Instances

> Q. Bạn ping 1 EC2 từ máy của bạn, nhưng ko nhận dc respone, bạn check VPC flow log thì như sau:  
`2 123456789010 eni-1235b8ca 110.237.99.166 172.31.17.140 0 0 1 4 336 1432917027 1432917142 ACCEPT OK`  
`2 123456789010 eni-1235b8ca 172.31.17.140 110.237.99.166 0 0 1 4 336 1432917094 1432917142 REJECT OK` 
Vì sao?

Vì Network ACL đang ko cho phép outbound ICMP traffic (vì NACL là stateless)

chứ còn nếu là SG thì bởi SG là stateful nên nếu inbound traffic dc cho phép thì outbound cũng sẽ được cho phép (ngay cả khi rule trong SG của bạn chặn outbound traffic) :joy:

## **---P4-udemy---**

> Q. App của bạn là app share ảnh, deploy trên 1 group các EC2. Team dev muốn nhanh chóng push 1 bản update cho app, và bản update đó sẽ được download bởi user trên global từ bên trong mobile app. Làm nào để ng dùng có trải nghiệm tốt.

Lưu file trên S3, Config sao cho Cloudfront sử dụng S3 bucket như là 1 Origin.

không thể upload thẳng file update đó lên Cloudfront

> Q. App của bạn có nhiều user, User tăng lên nên cần tăng Storage lên. Bản Backup cần để ở chỗ nào secure và durable. Bạn muốn dùng AWS vì nó unlimited. Tuy nhiên bạn vẫn muốn giữ dc sự access thường xuyên vào data. Làm nào?

Dùng Storage Gateway vì nó cho bạn trải nghiệm liền mạch (seamlessly) trong việc integrate app và AWS block object storage

> Q. Làm sao để dùng 1 Cloudformation Template để tạo stack trên nhiều AWS account?

Dùng Cloudformation StackSet

> Q. Khi bạn enable **MFA Delete** cho 1 S3 bucket, thì sẽ như nào?

`MFA Delete` cần enable cùng với `Bucket Versioning`  

Phải enable bằng CLI, bằng root account  

Feature này chỉ dành cho root account. Chỉ root account mới có thể xóa Object trong S3 bucket đó  

1 IAM User nếu có cung cấp MFA thì cũng ko thể xóa dc object trong bucket đó.  

https://www.cloudmantra.net/blog/how-to-enable-mfa-delete-for-s3-bucket/

> Q. Command nào để put custom metric lên Cloudwatch?

`put-metric-data` command CLI

> Q. Cái helper script nào của Cloudformation giúp bạn retrieve và interpret metadata, install package, tạo file, start service?

`cfn-init`

ko phải `cfn-signal` vì nó chỉ giúp báo WaitCondition chờ sync với các resource khác cảu stack khi app ready

ko phải `cfn-get-metadata` vì nó chỉ dùng để get metadata thôi

> Q. Bạn tạo 1 Chef Server trong AWS Opswork, với 3 node running. Bạn cần phải add nhiều hơn, nhưng thấy là mỗi lần add mất thời gian quá. Có cách nào tự động tạo EC2 Node vào Chef Server ko?

Có, dùng Chef Client Cookbook

> Q. Bạn muốn sử dụng Pupet Enterpise, AWS có service nào làm các nhiệm vụ như operation, backup, restore, upgrade software cho Pupet Enterprise ko?

Có, AWS Opswork

> Q. Bạn muốn secure cho data của mình, 1 service của AWS mà dùng FIPS 140-2 compliant, và **nằm trong VPC của bạn** thì dùng cái gì? CloudHSM hay KMS ?

CloudHSM vì nó nằm trong VPC của bạn, do bạn quản lý, bạn tự generate ra key và dùng key đó trong AWS  
chứ KMS là Service nằm ngoài VPC của bạn

> Q. Về RDS thì Cloudwatch có những metric như sau, chúng nó ý nghĩa gì? FreeStorageSpace, BinLogDiskUsage, FreeableMemory, DiskQueueDepth?

`FreeStorageSpace`: monitor số space còn thừa trong RDS instance,  

`BinLogDiskUsage`: monitor dung lượng đã dùng (chỉ apply cho MySQL read replicas),  

`FreeableMemory`: số RAM còn trống,  

`DiskQueueDepth`: số I/O (read/write) request đang chờ access vào disk

> Q. Bạn cần quick update RDS, launch thêm vài EC2, new ALB vào cái Cloudformation Stack hiện tại. Bạn muốn có thể preview những cái thay đổi trong stack mới, chắc chắn là new infra sẽ dc provision đúng thì làm nào?

**Cloudformation Change Sets** (nó sẽ list ra những thay đổi cho bạn review trước khi thực sự execute)

> Q. Bạn muốn tự động xóa những EBS snapshot khi đủ maximum snapshot thì làm nào?

Dùng Amazon Data Lifecycle Manager

> Q. Cross-zone Load balancing là như nào?

xem hình sau:  
Nếu disable `Cross-zone Load balancing` thì traffic từ client vào sẽ chia đều 2 LB, mỗi LB 50% (chia theo Route53 define), dẫn đến mỗi EC2 trong Zone A sẽ là 25%, còn mỗi EC2 trong Zone B là 50/8 (%) -> ko đều.  
Nếu enable `Cross-zone Load balancing` thì traffic sẽ chia đều cho các EC2, mỗi cái 10%

![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/cross-zone-load-balacing.jpg)

> Q. Bạn muốn mỗi khi snapshot đc tạo ra từ EC2, chúng sẽ dc copy qua region khác để đảm bảo durability, làm nào?

Cloudwatch Event cho EBS, rồi trigger Lambda để copy qua region khác

> Q. RDS Multi-AZ hoạt động như nào?

Con Primary Instance của bạn sẽ dc synchonize replicate data sang con DB Instance standby ở Zone khác. 2 con này chỉ sync về Data, còn infra của chúng độc lập với nhau.

> Q. Về Cloudfront, hệ thống của bạn cung cấp ảnh, tin tức. Có writer post 1 bức ảnh fake và đã bị cache lại trên Cloudfront, và cần phải đc xóa ngay lập tức (ko thể đợi cache expire, mà phải luôn và ngay), làm nào?

■ Cách 1: Invalidate file đó ở edge cache bằng CLI command `aws cloudfront create-invalidation`, thì từ lần sau viewer vào request, Cloudfront sẽ gửi đến origin để fetch file mới nhất

■ Cách 2: Dùng **file versioning** để serve 1 version khác của file đó

**Chú ý** cách invalidate file thì ko thể invalidate file media định dạng Microsoft Smooth Streaming, ko thể invalidate 1 file đã dc serve bởi RTMP (Real-Time Messaging Protocol)

> Q. Bạn có S3 bucket và muốn secure data. Chỉ những user có MFA thì mới đc vào access content bucket đó. Làm nào?

COnfig bucket policy chỉ cho phép access nếu User đã authen bằng MFA

Ensure MFA dc bật cho các User

> Q. 1 Cty dùng DynamoDB, bạn cần ensure là backup cần có sẵn available, làm nào?

Bật chức năng `On-demands backup for DynamoDB` tables (Nó cho phép bạn backup for long-term, bạn có thể backup và restore bất cứ lúc nào chỉ với vài click chuột, việc backup và restore sẽ ko ảnh hưởng đến perfomance hay tính availability của table)

> Q. 1 Cty muốn bạn manage hệ thống infa của họ trên cả cloud và on-premise. Họ muốn hệ thống backup và archive ổn định trên cả on-premise và cloud cho Document của họ. Những document phải luôn đc accessible ngay lập tức trong 6 tháng, và sau 6 tháng thì sẽ dc archive cho 10 năm. Dùng gì?

Storage Gateway với `File gateway` connect đến onpremise data center. Dùng lifecycle để move sang Glacier

Ko dùng `Tape gateway` vì nó lưu data trên **Glacier** nên ko thể retrive data ngay lập tức được như `File gateway`

AWS Storage Gateway cung cấp, File-based, Volume-based, Tape-based, thì:  
`File Gateway` chính là **File-based**,  
`Tape Gateway` chính là **Tape-based**. 

## **---P5-udemy---**

> Q. 1 Cty có nhiều AWS account trong 1 Org. Bạn cần ensure là các tag cần dc apply nhất quán khi tạo resource trong các account. Làm nào?

Dùng Cloudformation Resource Tags

Dùng AWS Service Catalogs

> Q. Cty  bạn quản lý nhiều AWS resource, giờ muốn optimize cost của các resource thì cần dùng cái gì? AWS Inspector? hay AWS Cost & Usage report?

Dùng AWS Cost & Usage report

Vì Inspector chỉ để check xem server có bị vulnerabilities hay ko thôi

> Q. Những limit của RDS encrpyted Database Instance là gì?

Chỉ có thể enable encryption ngay khi tạo DB, chứ ko thể sau khi DB đã được tạo

DB đã bật encryption thì ko thể disable đi được

Bạn ko thể có 1 bản Read Replica `unencrypted` của 1 DB `encrypted`  
Bạn ko thể có 1 bản Read Replica `encrypted` của 1 DB `unencrypted`  

Read Replica với DB gốc cần dc encrypt bằng cùng 1 key  

Bạn ko thể restore 1 bản backup/snapshot **unencrypted** vào 1 DB Instance đã được **encrypted**

Khi copy encrpyted snapshot từ 1 region sang regions khác, bạn cần chỉ định key KMS vì KMS ra specific cho mỗi region bạn tạo DB

> Q. 1 Cty có 1 app host trên EC2. Giờ cần 1 high throughput data storage cho quản lý content và có thể cung cấp parallel share access vào server của họ, thì sẽ dùng gì? EBS Volume Throughput Optimize hay EFS hay S3?

Dùng EFS

Vì EBS chủ yếu dùng cho local block level storage, mặc dù có thể cung cấp high throughput nhưng ko thể cung cấp khả năng parallel access vào multiple instances được

> Q. Cty bạn cần migrate app lên AWS. Cần infa có thể HA và chống dc cross-site scrpting, SQL injection, HTTP flood attacks. Thì dùng WAF hay Shield Advanced? dùng Network Load Balancer hay Application Load Balancer?

WAF và ALB (vì WAF là đủ để chống những cái trên rồi, bao giờ cần chống DDos thì mới cần Shield. **WAF thì nó ko thể integrate với NLB được**, nên mới chọn ALB)

> Q. Bạn có 1 số EC2 trong ASG và 1 vài hàm Lambda. Mỗi khi bạn release 1 version code mới, xảy ra sự ko ổn định vì bạn ko thể manually update all resource liên quan đúng cách. Vì số lượng lớn resource, bạn cần 1 cách để nhóm chúng lại và deploy new version của code 1 cách ổn định cho cái nhóm đó với downtime bé thôi. Làm nào?

Dùng deployment group trong AWS Code Deploy để automate việc deploy code

> Q. Cloudwatch agent có thể cung cấp thông tin về vulnerabilities và errors trong system của bạn ko?

KO, muốn cái đó thì dùng Inspector

> Q. Data Lifecycle Manager cung cấp 1 cách đơn giản, tự động để backup data trên EBS volume của bạn. Vậy nó có khả năng tạo snapshot rồi tự động copy sang region khác hay ko?

Không nhé. Bạn phải tự làm việc move sang region khác đó

> Q. App của bạn dùng ELB Clasic Load Balancer. Bạn muốn enable ticky session để CLB sẽ bind cái user session với 1 instance cụ thể. Khi đó tên của cookie mà CLB sẽ tạo để map với user session là gì?

AWSELB

Nếu App của bạn có session cookie sẵn rồi, bạn có thể config ELB để cái session cookie của ELB follow cái duration của App's session cookie.

Nếu App của bạn ko có session cookie, bạn có thể config ELB để nó tạo ra session cookie và chỉ định duration bạn muốn. Khi ELB tạo cookie sẽ có tên là **AWSELB** dùng để map cái session vào Instance

> Q. Khi bạn delete CMK (Customer Master Key) của KMS, thì cần chú ý gì? Có thể xóa ngay lập tức ko? thời gian default? 

Bạn không thể xóa CMK ngay lập tức, bạn phải lên schedule cho nó

Thời gian schedule để xóa CMK default là 30 ngày (30 days)

KMS sẽ ko thực hiện rotate với nhưng CMK đang trọng trạng thái pending deletion

1 CMK pending deletion ko thể sử dụng tron bất cứ hoạt động cryptographic nào

> Q. App của bạn dựng trên EC2-Clastic Instance và trong 1 public subnet. Giờ muốn list các IP truy cập vào EC2 nên làm nào?

Dùng VPC Flow log, nhưng trước hết phải migrate App sang EC2-VPC, chứ loại EC2-Clasic ko dùng VPC Flow log được

> Q. Cloudformation có cái `DeletionPolicy`, cái này có những option gì?

`Retain`: giữ lại resource khi Stack bị xóa  
`Delete`: delete all (default)  
`Snapshot`: tạo snapshot trước khi xóa  

> Q. Default khi tạo VPC thì qua CLI/Console/VPC Wizard, những cái sau dc set true hay false: `enableDnsHostnames` và `enableDnsSupport`?

Khi tạo bằng VPC Wizard: cả 2 set `true` 

Khi tạo bằng Console, CLI: chỉ có `enableDnsSupport=true`

> Q. Bạn cần setup 1 infra để có thể tự động provision ra hàng ngàn EC2 at any scale, dùng service gì?

EMR (Elastic MapReduce), nó giúp bạn dễ dàng tăng giảm số lượng ec2 có thể access và quản lý. 

> Q. Bạn có 1 bucket S3, muốn setting để chỉ có thể đọc và viết chứ ko thể xóa object thì làm nào? MFA Delete hay attach S3 bucket policy?

Attach 1 S3 bucket policy

ko chọn MFA delete vì nó dùng để chặn trường hợp xóa 1 cách vô ý thôi, nếu có quyền và MFA code vẫn có thể xóa dc

> Q. 1 Cty đang consider dùng RDS, khi dùng RDS thì những activities gì sẽ do AWS perform, ng dùng ko cần quan tâm?

■ create và maintain backup với point in time recovery 5 minutes

■ install các bản vá bảo mật (security patch)

Chứ còn những thư như config Multi-AZ tự động, tạo Read Replica tự động khi utilization cao thì AWS ko perform, mà phía người dùng phải config/enable

> Q. 1 Game online đang host trên 1 EC2. Họ chuẩn bị release 1 bản game mới, cần chắc chắn là website của họ đủ khả năng support cho new players. Cần làm gì?

Tạo 1 ASG từ cái EC2 đang chạy 

Có 2 kiểu tạo ASG Launch Configuration từ scratch, và tạo ASG Launch configuration từ exist EC2

> Q. Bạn cần report về tình trạng OS patching process của RDS, xem có cái gì vulnerability ko, thì có cần dùng AWS Inspector ko?

Không. Chỉ cần dùng RDS Console là đủ rồi

> Q. Bạn cần ensure là all object S3 bucket được encrypt at rest. Cần config S3 bucket để nó deny những request mà ko có header là gì?

`x-amz-server-side-encryption`

> Q. Bạn có 1 RDS database, giờ muốn chuyển sang DynamoDB, nên bạn cần disable backup của RDS vì ko dùng nữa. Bạn có thể set retention period xuống 1, nhưng khi set xuống 0 bị lỗi. Vì sao?

Vì RDS của bạn đang setting có Read Replica

> Q. Bạn migrate 1 online accounting app dùng TCP protocol lên AWS. Cần đảm bảo tính scalability và availability, đồng thời phải record dc IP của client để tracking nữa. Dùng cái gì 2 cách sau?  
1: ELB + 1 TCP Listener + enable Proxy Protocol  
2: ELB + 1 TCP Listener + enable Cross-Zone Load Balancing  

Dùng cách 1, vì enable Cross-Zone Load Balancing sẽ ko thể record dc IP của User dùng app

> Q. 1 Cty dùng Kinesis để liên tục collect data của user. Vì data nhạy cảm nên cần secure at rest. Nên config Kinesis sử dụng server-side encryption hay client-side encryption?

Dùng Kinesis `server-side encryption` (ko nên dùng client-side encrpytion vì khó setup hơn nhiều)  
Câu hỏi là secure at rest, nên dùng server-side nó sẽ encrpyt khi nó chưa ghi vào DB, và decrypt sau khi lấy ra từ DB  
Nếu cần secure in transit, thì nên dùng client-side, nó sẽ encrpyt khi nó đi ra khỏi client, và đến lúc vào DB thì nó đã dc encrypt rồi (quãng đường từ client đến server thì data đã dc encrpyt nên chính là in transit)

# Các câu hỏi được note lại trong quá trình thi

> Q. EFS encrpytion thì cần dùng cái gì? CloudHSM hay Server-side Encryption có sẵn của EFS

> Q. Khi tạo Billing alert thì dùng service nào? AWS budget? hay Trusted Advisor? hay Cost Explorer? hay Cost and Usage?

> Q. Account A tạo AWS Catalog portfolio rồi share cho Account B, vậy thì B có thể làm gì với portfolio đó? Create/Update/Delete được ko? hay chỉ tạo được ở local?

> Q. NAT Gateway nằm trong public subnet hay private subnet?

> Q. Cloudformation, sau khi chạy stack lỗi, bạn sửa lại template xong thì xóa tạo lại stack hay update stack đó? hay tạo ChangeSet?

> Q. Bạn đã issued 1 certificate, giờ muốn tạo key trong 1 secure environment, có thể làm các crpytographic operation thì dùng service nào? CloudHSM hay KMS

> Q. Cty bạn đã centralized tất cả log vào 1 log group. Cần phải xem cái log để notify cho các team liên quan. Thì có cách nào most effective? Có nên chia ra nhiều log group rồi subcribe mỗi team 1 log group?

> Q. Khi dùng AWS Aurora thì resposibility của bạn là gì, 
provisioning storage DB? 
hay Schedule patch, maintain, update OS? 
hay Excute patch, maintain, update OS? 

> Q. Lambda ở account A push object lên s3 bucket ở account B, nhưng B ko xóa dc object đó thì nên làm nào? 
Lambda cần put cả objectACl nữa, define owner có quyền full access

> Q. Cloudtrail có khái niệm `data event log` và `management event log` ko? hay có cái nào trong 2 cái đó?

> Q. AWS Orgnization của bạn muốn xem ai make request create new account thì xem ở đâu? 
`Cloudtrail log` hay `Organization access log`? 
Có cái gọi là `Orgnization access log` ko?

> Q. Khi tạo S3 bucket policy, có cái resource arn kiểu `...bucket/*` ko?

> Q. 1 VPC có 2 public subnet, 2 private subnet, 1 igw, 1 natgw, có potential nguy hiểm tiềm tàng gì? 
Single natgw ko redundant?, 
Single igw ko redundant?, 
VPC default route table chỉ associate dc với 1 AZ?

> Q. Về cloudtrail intergrity, để prevent modify/delete cái trail log, nên bật mfa delele cho bucket đó? Hay edit policy để  `DENY ALL`

> Q. Có 2 VPC, VPC 1 là chính ở 1 region, VPC 2 là cái dự phòng đang để ở region khác, giờ muốn sync data từ VPC 1 sang 2, mà traffic ko bị expose qua internet thì nên làm nào? tạo 1 inter-vpc peering à? hay tạo 1 EC2 dùng làm VPN?

Done!  

Chúc các bạn thành công, mình passed rồi :tada: :tada: :tada:


