---
title: "Aws Certified Solution Architect Associate Note (SAA)"
date: 2019-08-06T00:29:51+09:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Notes]
tags: [AWS]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Những notes của bản thân trong quá trình ôn thi chứng chỉ AWS SAA"
---
# Các câu hỏi và câu trả lời được note lại trong quá trình học

**---P1---**

> Q. 1 cty cần migrate 10TB data lên aws. Yêu cầu replica lag < 100 miliseconds, data có thể scale gấp 4? dùng cái RDS nào của amazon?

aurora, có thể scale 64TB và keep replica lag dưới 100 milisec

> Q. "IOPS” stands for input/output operations per second=số lần đọc/ghi max trong 1 giây, "throughput" là dung lượng traffic 1 giây

Các loại EBS:  
General Purpose SSD (gp2): bình thường, dùng cho môi trường Dev/test,
volume size (1gb-16TB), max IOPS=16k, max throughput/volume=250M/s

Provisioned IOPS SSD (io1): performance kinh nhất, dùng cho data quan hệ RDS,
volume size (4gb-64TB), max IOPS=64k, max throughput/volume=1000M/s

Throughput Optimized HDD (st1): giá rẻ, dùng cho Bigdata, streaming, access thường xuyên,
volume size (500gb-16TB), max IOPS=500, max throughput/volume=500M/s

Cold HDD (sc1): giá rẻ nhất, dùng cho Bigdata, access ko thường xuyên,
volume size (500gb-16TB), max IOPS=250, max throughput/volume=250M/s

> Q. 1 App run 150GB relational database on EC2 instance. App chạy ko thường xuyên và đôi khi có peak time.
đỡ tốn tiền nên chọn loại EBS nào?

sẽ dùng SSD (gp2),  
1- vì cái Hdd (st1, sc1) sẽ có minimum 500GB mà mình chỉ cần 150GB thôi  
2- vì là RDS nên ưu tiên IOPS -> ưu tiên SSD  
chứ nếu Big data, stream data thì ưu tiên Throughtput MB/s -> ưu tiên Hdd  

> Q. Though the images will be retrieved infrequently, they must be available for retrieval immediately.
Data dc truy xuất ko liên tục, nhưng phải available để lấy ngay lập tức

S3 IA

> Q. Về s3 glacier, khác biệt giữa các option Retrieval sau: expedited, standard, bulk?

Expedited data sẽ có thể access trong vòng 1-5 min,  
Standard data sẽ có thể access trong vòng 3-5 hour,  
Bulk rẻ nhất, data sẽ có thể access trong vòng 5-12 hour

> Q. 1 app trên aws cần pull data từ internet, SA cần thiết kế HA solution để access vào data mà ko cần đặt bandwidth constraints vào cái app của mình? thì sẽ làm gì?

gắn IGW và route 0.0.0.0/0,  

NATGW cũng HA nhưng chỉ dùng cho private subnet, và bandwidth chỉ cho scale up 45Gbps,  

NAT instance thì bandwidth phụ thuộc vào loại instance,  

VPC endpoint thì dùng để connect tới các service của aws thôi, ko dùng cho internet  

> Q. asG, bạn nhận ra app của bạn đang scale asG up and down nhiều lần, cần làm gì?

Sửa asg cool down timer, và check cái cloudwatch alarm đang trigger việc scale down asg.

> Q. asg cool down timer là gì?  

là thời gian sau khi scale activity của asg thực hiện, nó sẽ tạm suspend 1 tgian. (default là 300s)

> Q. recommend apply traffic cho ứng dụng web app, nên apply cho 2 tier web và db như nào?

web sg: allow port 443 https (SSL) hoặc 80 http from source: anywhere  

db sg: allow port 3306 (mysql) from source: "web sg"  

SG thì mình chỉ có thể set rule để allow ip, còn ACL thì có thể set rule để deny/allow ip nào đó.  

Set rule inbound cho SG thì outbound cũng apply (stateful), nhưng ACL thì phải set cả inbound và outbound (stateless)  

> Q. Các rule trong ACL đc apply ntn?
Nếu số 100 allow ip 1, số 101 deny ip 1 thì?

từ số bé trước rồi đến số lớn sau.  
Nếu số 100 allow ip 1, số 101 deny ip 1 thì kết quả là ip 1 vẫn dc allow vì nó dc apply trước

> Q. 1 website chạy trên ec2 sau 1 ALB, họ muốn tránh việc serving file của ec2 mỗi lần ng dùng request assest thì làm gì để cải thiện ux?

cache static content trên Cloudfront

> Q. 1 app cần encrypt data trc khi ghi vào disk, nên dùng service nào?

KMS, ko dùng Certificate manager vì awS cert manager dùng để gen ra certificate để encrypt traffic in transit

> Q. 1 cty export daily data vào S3. team data warehouse muốn lấy data từ s3 đó import vào Redshift, yêu cầu là data chỉ dc transport trong 1 vpc. làm gì cho secure?

bật Redshift Enhanced vpc Routing và create s3 vpc endpoint

> Q. 1 website cung cấp nhiều language, define theo htttp request:  
http://d11111f8.cloudfront.net/main.html?language=de;  
http://d11111f8.cloudfront.net/main.html?language=en  
Cloudfront cần configure như nào?

Base on query string parameters

> Q. 3 cách cache content trên cloudfront là?

base on query string parameter, base on cookie, base on request headers

> Q. ecs, các container ko dc access vao các container khác của customer khác. vậy phải dùng nào?

dùng IAM role for task (trong CDA thì có 1 câu như này nhưng bảo config security group hoặc IAM role for task -> có thể dùng 1 trong 2 cách)

> Q. 1 công ty đang generate 1 cục dataset hàng triệu row thành dạng cột, các tool khác sẽ build report daily từ các dataset đó. Nên dùng service gì?

Redshift, dùng với datawarehouse, để tạo insights cho công ty bạn

> Q. 1 cty cần 1 db trên aws phù hợp yêu cầu:  
khởi tạo 8TB, tăng trường 8GB 1 ngày, có 4 read replica  

Nên Dùng awS Aurora (limit 64TB và 15 read replica),  

không dùng dynamoDB vì phải viết rõ là DAX (DynamoDB Accelerator) mới có 9 Read Replicas, DynamoDB ko limit size của table  

aurora là Relational db, dynamoDB là noSQL  

> Q. 1 app cần 1 file system. cái nào để có thể access bởi ec2?

EFS, ko dùng S3 vì là object base storage thôi. (chú ý efs ko thể cài trên window ec2)

> Q. Hàng triệu ảnh cần up lên s3? làm gì để tăng performance?

dùng hexadecimal hash for prefix

> Q. Cần get IP address của các resource accessed in private subnet. Dùng cái nào?

VPC flow log

> Q. 1 app 2 tier cần db. DB sẽ yêu cầu multiple schema changes. durable, ACID. Dùng db nào?
ACID: Atomicity (nếu transaction liên quan >2 xử lý, thì hoặc all xử lý dc thực hiện, hoặc là ko cái nào dc thực hiện), Consistency (ko có transaction dở dang,nghĩa là hoặc mới hoặc rollback), isolation (các transaction luôn tách rời nhau, ko trộn lẫn), Durability (data never lost nếu ứng dụng bị crash)

Dùng Aurora.  
Vì DynamoDB ko support schema change, ko support ACID (chỉ C và D).  
Redshift cũng ko ACID (chỉ AID)  

> Q. Redshift cluster mà muốn recovery khi disaster đến 1 chỗ cách xa 600km thì cần làm gì?

Bật cross-region snapshot . Vì mỗi AZ cách nhau chỉ khoảng 100km nên ko thể bật cross-az snapshot đc (Mà nó cũng ko có khái niệm là "cross AZ" chỉ có khái niệm "multi AZ/multi region" nhưng lại ko dùng cho snapshot mà dùng chỉ cluster)

> Q. 1 cty đang có APi riêng với 1000 request per second ? để cost effective dùng gì?

API gateway + lambda

> Q. 1 app host trên ec2 đang có 1 campaign start trong 2 tuần. Muốn đảm bảo performance trong thời gian đó, cần config asG như nào?

Dynamic scaling + target tracking scaling policy

> Q. 1 app host trên aws sit sau 1 ELB. Notfy to admin nếu read request > 1000 req/min. Notify nếu latency > 10s. Bất ky API activity mà call đến sensitive data sẽ dc monitor

Cloudtrail và cloudwatch metric với setup alarm

> Q. 1 company muốn monitor all API activity và cần apply cho future regions. Cần làm gì?

Ensure 1 trail trong cloudtrail dc enable all region

> Q. Có yêu cầu cho thiết bị ISCSI device, và 1 app legacy cần local storage. Cần dùng service nào?
iscsi device là các thiết bị liên quan đến ip TCP/IP, truyền dữ liệu qua LAN, WAN

Dùng Aws Storage gateway stored volume  

Phân biệt aws gateway cached volume và aws gateway stored volume:  

Aws gateway cached volume: lưu data trên s3, 1 cục cần access thường xuyên sẽ lưu locally. dễ scale, độ trễ thấp  

Aws gateway stored volume: data sẽ lưu hoàn toàn ở locally, rồi snapshot sẽ dc async lên s3  

(giải pháp cho việc backup recover data cho local data center của mình hoặc trên aws)  

Gateway-virtual tape library (VTL): data lưu ở Glacier

> Q. Yêu cầu là EC2 trong private subnet cần access vào S3 bucket. Traffic ko dc qua internet. Dùng cái gì?

VPC Enpoint

> Q. Có 1 app chạy trên các EC2 và sit sau clasic ELB, 1 EC2 proxy dc dùng cho quản lý content và nhiều Ec2 dùng cho Backend, Vấn đề là app của họ scale ko đúng. Nên làm nào?

Dùng asg cho cả proxy server và backend instance

> Q. 1 web host trên aws có dc rất nhiều traffic. Làm sao để giảm thiểu rủi ro disruption của web này trong trường hợp disaster?

Dùng Route53 để Route to static website.  

Ko thể dùng ELB để chuyển traffic đến region khác vì ELB chỉ dùng để balance trong 1 region chứ ko multi region dc, kể cả trong 1 region thì việc backup cross AZ ko dùng để recovery  

Hầu hết cty cố gắng implement HA thay vì DR, trong case HA thì app sẽ host khác AZ chứ ko khác region, ko đảm bảo trong TH disaster toàn region. DR thì sẽ recovery từ 1 region khác (>250miles). DR implement mô hình Active/Passive, nghĩa là luôn luôn có 1 static site OR service nhỏ run ở 1 region khác.  

> Q. Bạn được yêu cầu host static web cho domain mycompany.com trên aws, yêu cầu traffic dc scale đúng cách, dùng services nào?

Route53 và static website trên s3,  
nhập NS record của R53 vào domain registrar để registrar quản lý cái domain đó, ko cho ng khác đăng ký lại domain của mình

> Q. Bạn được yêu cầu analyze behavior qua những cái gì customer click vào, cái nào để capture data và analyze?

Push những cái click của customer lên kinesis và analyze bằng kinesis worker

> Q. 1 công ty có 1 infra gồm các machine send log every 5 minutes, số lượng machine có thể hàng ngàn, data sẽ analyze ở stage khác, thì cần dùng gì?

Dùng kinesis firehose với s3 để take log, store nó trên s3 cho các process sau này  
Kinesis Firehose capture, transform, load stream data vào s3, redshift, elasticsearch

> Q. 1 app host trên aws cho phép user upload video to s3. 1 user phải có quyền để upload video lên s3 bucket trong 1 tuần base on profile, Làm thế nào?

Tạo pre-signed urL hết hạn trong 1 tuần cho mỗi user profile.

> Q. 1 cty host 5 web server trên aws. Họ muốn Route53 route user traffic to random web server. Policy nào của R53 thỏa mãn?

Multivalue answer routing policy: route traffic 1 cách ngẫu nhiên đến max là 8 record healthy.

Ngoài ra:  
Simple routing policy: Dùng 1 resource cho 1 domain.  

Latency routing policy: Nếu có nhiều resource thì sẽ route traffic đến location có best latency nhất.  

Weighted routing policy: route traffic đến nhiều resoure theo tỉ lệ bạn defined.  

Geoproximity routing policy: route traffic dựa trên location của resource của bạn.  

Geolocation routing policy: route traffic dựa trên location của user.  

Failover routing policy: dùng để configure Active/passive failover.  

> Q. Công ty cần 1 db có thể perform câu query underlying (truy vấn cơ bản) như JOIN thì dùng db nào? aurora? dynamodb? redshift? s3?

aurora (chứ dynamo ko dùng join dc )

**---P2---**

> Q. 1 customer muốn tạo EBS volume in AWS, data on volume cần encrypt at rest. Cần làm gì?

vì at rest nên dùng KMS để gen ra key rồi sử dung key đó encrypt data. Không dùng SSL vì SSL để encrypt data in transit

> Q. Cty bạn có 1 số EC2, cần monitor state của EC2 và record lại, làm nào?

Cloudwatch log để store state changes của EC2, Dùng cloudwatch Event để monitor changes of event đối với EC2

> Q. Bạn tạo 1 VPC và 3 public subnet, ở mỗi AZ 1 public subnet, mỗi subnet 1 ec2. Giờ muốn tạo ELB của 2 Az. bao nhiêu Private IP dc dùng khi khởi tạo ELB?

2 AZ -> 2 subnet -> 2 ec2 -> 2 private IP

> Q. Amazon RDS backup process là gì? default là gì?

default RDS sẽ thực hiện backup cái storage volume của DB Instance, nghĩa là toàn bộ DB instance chứ ko riêng rẽ DB.  
Điều này làm mỗi ngày 1 lần. Cùng với capture transaction log every 5min và lưu s3  

Còn Database Snapshot thì RDS ko tự làm, là do User làm, có thể làm bất ký lúc nào.

> Q. 1 app lưu thông tin quan trọng trên s3. thông tin có thể access qua internet, công ty lo rằng connect đến s3 có thể là risk về security, làm nào?

access data thông qua VPC enpoint cho S3.

> Q. Bạn đang có 1 NAT Gateway cho các ec2 private. Bạn muốn NAT Gateway cũng phải HA, làm nào?

Tạo thêm NAT Gateway ở 1 Az khác, Về document của AWS có nói, muốn tạo 1 hệ thống ko phu thuộc Az thì mỗi Az 1 NAT Gateway và ensure rằng các resource sử dung NAT đó thì ở cùng 1 Az.  
Chứ ko thể dung ASG cho NAT Gateway  

> Q. 1 cty muốn có 1 fully managed data store trên Aws, compatible với MySQL, database engine nào có thể sử dung?
AWS Aurora hay AWS RDS

Chọn Aurora vì RDS ko phải là database engine, RDS là 1 service support 6 database engines.  
Aurora là 1 DB engines nhưng nó chỉ support 2 DB engines khác là MySQL và PostgresSQL  

> Q.  1 cty muốn chỉ những khách hang xác định có thể upload ảnh to s3 trong 1 giai đoạn nhất định. Nên làm nào?

tạo Pre-signed URL để upload images, thêm điều kiện expired time.

> Q. Phân biệt các loại ELB: CLB, NLB, ALB (cái nào cũng có tính scalability):

Classic Load Balancer: cung cấp (HTTP, HTTPS or TCP listeners) cho only 1 backend port. Chạy bên ngoài VPC. ( Nếu app của bạn chạy ngoài VPC). Ko thể handle đc hàng triệu request 1 giây như NLB 

Network Load Balancer: Layer 4, cung cấp only TCP. Dùng EIP/static IP. Nhiều ports. Dùng với những app mà chỉ cần sử dụng TCP. Và muốn quản lý bằng whilelist IP. Có thể scale để handle workload lên đến hàng triệu request 1 giây (millions of requests per second)

Application Load Balancer: Layer7, cung cấp cân bằng tải cho only HTTP/HTTPS. Nhiều ports. flexible hơn CLB. Nhiều ng dùng. Cung cấp tính năng nâng cao về routing đến target, dùng cho các app hiện đại, micro-services, containers. Ko thể handle đc hàng triệu request 1 giây như NLB 

> Q. Third-party sign-in (Federation) co dc dùng để authorize service ko?

ko, Federation is used to authenticate users, not to authorize services

> Q. Bạn có 1 vài ec2 trong asG, nhưng có vẻ ec2 ko dc scale out đúng lúc. Cần check lại gì?

check lại xem có đúng metric dc dùng để trigger việc scale out ko?

> Q. Cty bạn thiết kế 1 app tương tác với dynamodb, và các user của app thì sign-in sử dụng GG, FB. Cần cái gì để app có thể get temporary access to dynamodb?

1 cái role để app có thể access vào dynamodb, user sẽ phải assume cái role đó

> Q. Muốn all traffic ra/vào Redshift ko đi ra internet, làm nào?

Enable Redshift Enhanced VPC routing

> Q. 1 cty đang có 1 set HyperV machines and VMware virtual machine. Muốn migrate to cloud. Cần dùng cái gì?

aWS server Migration service

> Q. Trust advisor để làm gì?

là tool để cung cấp real time guidance to provison resource theo best practice

> Q. 1 cty có nhiều data trên on premise. Hết storage, cty muốn 1 giải pháp aws để dễ dàng extension data to aws.
Nói chung giải pháp để migrate hoặc transfer data on-premise to s3.

Chọn aws gateway cached volumes  

Phân biệt aws gateway cached volume và aws gateway stored volume:  

Aws gateway cached volume: lưu data trên s3, 1 cục cần access thường xuyên sẽ lưu locally. dễ scale, độ trễ thấp  

Aws gateway stored volume: data sẽ lưu hoàn toàn ở locally, rồi snapshot sẽ dc async lên s3  

(giải pháp cho việc backup recover data cho local data center của mình hoặc trên aws)  

Gateway-virtual tape library (VTL): data lưu ở Glacier

> Q. 1 Cty muốn lưu document và đề phòng trường hợp bị xóa. Dùng gì?

S3, enable versioning

> Q. 1 cty có 1 app deliver object từ s3 đến user. user phản hồi là respone time chậm. Phải làm sao để giảm respone time và tiết kiệm chi phí?

để s3 bucket sau CloudFront distribution. Nếu workload chủ yếu là GET request, thì sử dụng Cloudfront sẽ cache request lại, giảm request tới S3, reduce cost.

Không nên dùng S3 replication cross regions vì tốn tiền hơn.  

S3 Transfer Acceleration cũng tốn tiền hơn.  

Không dùng ELB với s3 dc vì chỉ để balance traffic cho ec2.  

> Q. Để đảm bảo thứ tự message và dublicated message ko dc gửi thì nên dung?

SQS FIFO, ko nên dùng SNS vì SNS có thể gửi message duplicated

> Q. 1 cty có 1 vài ec2 để quản lý 1 web app. Cần giải pháp để fault tolerant?

Ensure các Ec2 ở các Az riêng rẽ. Dùng ELB để distribute traffic, attach ELB vào ASG

> Q. 1 cty store log trên s3, có yêu cầu là cần search ở trong đống data trong s3 đấy. Làm nào?

AWS Athena để query trên s3 bucket, Load data vào Amazon Elasticsearch để search

> Q. Cty bạn dung KMS quản lý key để nó encrypt decrypt data, giờ bạn muốn secure hơn nên bạn enable chức năng rotate key.
thì sao?

KMS sẽ rotate key hàng năm và sử dung 1 key phù hợp để encrypt/decrypt data (KMS keep các key cũ)

> Q. RDS MySQL size và Aurora Size?

RDS MySQL up to 16TB  
Aurora 10GB to 64TB

> Q. Cognito có thể tạo thêm identity provider dc ko?

có

> Q. Để allow SSH cho 1 ec2, cần config SG và NACL như nào?

SG: Inbound (allow), Outbound (deny)  
NACL: Inbound (allow), Outbound (allow)  

vì SG là stateful, những request incoming nếu dc granted thì outgoing request cũng dc granted  
còn NACL stateless, nếu config cho grant những incoming request thì cũng phải config grant cho những outgoing request nữa  

> Q. 1 cty đang có 1 web distribution và dung Cloudfront. IT confirm là cái web này đang thuộc scope PCI compliance.
Cần làm gì?

Enable Cloudfront access log, Capture những requests mà dc gửi tới CloudFront API  

Vì đang run PCI or HIPAA-compliant workloads based on the AWS Shared Responsibility Model, AWS recommend bạn log lại CloudFront usage data của 365 ngày gần nhất để audit trong tương lai, để log usage data thì cần:  
Enable Cloudfront access log, Capture những requests mà dc gửi tới CloudFront API

> Q. VPC Flow log làm gì?

capture thông tin IP traffic đi ra đi vào Network interface trong VPC thôi, ko có Cloudfront

**---P3---**

> Q. 1 cty dùng RDS, muốn encrypt data at rest, làm nào?

Enable tính năng encryption ngay từ lúc tạo DB ( chứ tạo rồi ko enable dc nữa).  
Chọn đúng loại instance class support việc encrypt vì ko phải loại nào cũng support (ví dụ General purpose db.m1.small/medium/large/xlarge ko thể encrypt).  

có 1 trick để encrypt db có sẵn là: Ban đầu bạn có 1 db chưa encrypt, tạo bản snapshot của nó, encrypt bản snapshot đó, restore lại từ snapshot ra DB instance -> vậy là đã có DB instance dc encrypt.  
DB đã bật encryption thì ko thể disable encryption dc.  
Muốn encrypt read replicas thì phải dùng cùng 1 key với DB instance.  
RDS encryption cũng not available cho những DB instance chạy SQL Server express.  

> Q. DynamoDB có HA ko?

có, tự động replicated in multi AZ. Nếu muốn ở level region thì bật tính năng global table.

> Q. 1 DB host trên aws đang bị vượt quá số lượng write và ko thể handle load. Sao để chắc chắn số lượng write ko bị mất trong bất cứ trường hợp nào?

Dùng SQS FIFO để query db writes,

Hoặc add thêm IOPS vào existing volume dùng cho DB (Tuy nhiên IOPS có giới hạn 40k thôi, trong khi SQS có thể handle 120k message in flight)

> Q. Bạn đang host data trên Aurora. Muốn những data này available in another region in case disaster thì làm nào?

Create read replica of Aurora in cross regions.  
Cả RDS và Aurora đều có thể tạo read replica cross regions  

> Q. Bạn quản lý những user của tổ chức lớn, họ đang move nhiều service to AWS, bạn muốn các user có thể nhanh chóng login và sử dụng cloud service, Bạn định dùng AWS Managed Microsoft AD, cần làm gì?

Bạn cần setup VPN hoặc Direct Connect để sau đó AWS MS AD có thể sử dụng dc cho cả Cloud và Onpremise

> Q. Cty bạn dùng Route53 as DNS Provider, Cần trỏ DNS của cty tới CloudFront thì làm nào?

Tạo Alias record point tới CloudFront. Chọn Alias chứ ko chọn CNAME record vì Alias thì có thể tạo cho cả root domain và sub domain, trong khi CNAME thì chỉ có thể tạo cho sub domain.

> Q. 1 cty đang có các app dùng Docker containers. Cần move lên aws, setup những Docker containers đó trên các môi trường riêng biệt, làm nào?

Dùng Elastic Beanstalk, hoặc Dùng ECS (Nhưng Beanstalk có ưu điểm nếu 1 Docker container đang running bị crash or killed, Beanstalk sẽ tự động restart)

> Q. 1 cty có 1 workflow là send video từ on-premise sang AWS để transcoding. Họ dùng ec2 pull job from SQS. Vì sao dùng SQS?

Để giúp việc scaling theo chiều ngang của các task. Đó là mục đích chính, ngoài ra thì nó SQS cũng đảm bảo thứ tự message (SQS FIFO)

> Q. 1 cty muốn extend onpremise to cloud. Họ muốn communication giữa 2 môi trường possible over internet. Làm nào?

Tạo VPN connection giữa 2 onpremise và AWS  
Ko thể dùng AWS Direct connect vì Direct connect ko dùng internet  

> Q. 1 Cloudfront dùng để distribute content from S3. Yêu cầu là chỉ cho 1 số user trả phí vào xem nội dung content thôi, làm nào?

Tạo Cloudfront signed URLs và distribute nó cho User

> Q. Bạn có 1 cty nhỏ, chỉ cẩn chuyển resource to cloud như AWS workspace, AWS Workmail. Cần solution để user management và set policy. Dùng AWS Directory Service nào?

Simple AD là đủ (support cả WIndow workload và Linux workload)  

KO cần dùng AD Connector vì bạn ko có on premise app.  

Ko cần Cognito, AWS Managed Microsoft AD vì 2 cái ấy nhiều hơn những gì bạn cần.  

> Q. Các data trong S3 muốn avalablity in another regions làm nào?

Enable cross region cho S3 bucket

> Q. 1 Cty đang có yêu cầu 1 model Stack-based cho resource trên AWS.
Cần có những stack khác nhau cho Dev và Prod. Dùng gì?

AWS Opswork. Nó sẽ giúp bạn manage app trên AWS và Onpremise. Tạo các stack bao gồm các Layer (layer LB, DB, App).  

1 Stack basic cho web server thì gồm: 1 set instance cho application server (quản lý incoming traffic), 1 LB instance (distribute traffic to apllication server), 1 DB instance (backend)  

1 Common practice là nhiều stack cho các môi trường: Dev stack để develop, add feature, fix bug...Staging stack để verify update, hotfix. Production stack để publish và handle request of customer.  

> Q. Bạn có 1 app đang deploy trên 2 Az, dùng 1 LB và ASG. Muốn lúc nào cũng available 100% nếu 1 Az godown thì nên làm nào?

Deploy trên 3 Az với ASG minimum set 50% load per zone.
-> Nếu set là 33% mỗi zone thì khi 1 Az go down thì max chỉ có 66% load dc handle, còn 34% ko handle dc (ko thể đủ 100%)

> Q. 1 app đang host trên ec2 và đang chọn EBS type, data trên volume này dc access khoảng 1 tuần rồi sau đó dc move to infrequent access storage. Dùng loại EBS nào để cost efficiency?

Chỉ access khoảng 1 tuần -> ko access thường xuyên -> EBS Cold HDD

> Q. 1 KH muốn import virtual machine có sẵn lên cloud. Dùng cái gì?

VM import/export

Không dùng AWS Import/Export vì đấy là service để transport data to Cloud.  

Không dùng AWS Storage Gateway vì đấy là service connect an on-premise to cloud-based, cung cấp access vào s3 object như là file.  

Không dùng DB Migration Service vì đấy là service để migrate data từ hoặc đến các cở sở DB thương mại hoặc open.  

> Q. Bạn có 1 app mà application user sẽ initiate TCP request to server, server respone các request đó. Hệ thống gồm các VPC ở các Az khác nhau trong 1 region. Giờ cần thiết lập connection giữa các VPC để có 1 solution high scalable, and secure. Dùng cái gì?

AWS PrivateLink và Network LB.  
Ko dùng IGW vì ko secure.  
Ko dùng VPC peering vì nó sẽ cho all resource của VPC này access vào resource VPC khác, trong khi app mình chỉ cần user initiate request tới server thôi.  
Ko dùng VPN vì ko thể scalable.  

> Q. Bạn cần host static web trên aws. Nên dùng cái gì? Có nên dùng RDS và EC2 để store/host data ko?

S3 và DynamoDB

> Q. Bạn đang lưu data trên s3, giờ cần all data phải encrypt at rest. Làm sao?

Enable serverside encryption on s3.

> Q. 1 KH có 3TB data on-premise, tăng 500GB 1 năm. Khách đang ngày càng bị hạn chế bởi dung lượng data local tăng lên. Muốn backup 1 phần data nhưng vẫn duy trì độ trễ thấp với những data access thường xuyên. Nên dùng AwS storage Gateway nào?

Gateway-cached volume + schedule snapshot to s3 (lưu data trên s3, 1 cục access thường xuyên thì để local)  
ko nên dùng Gateway storage volume vì loại này lưu toàn bộ data locally (trong khi KH ngày càng bị hạn chế bởi dung lượng data local)

> Q. Cần deploy app to aws. Cần monitor web app log để phát hiện nguy hiểm. Dùng gì?

Cloudwatch log và Cloudtrail  
Cloudtrail mục đích chính là : who did what on AWS? (trace log của aws account activity trên console, cli, sdk)  
Cloudwatch mục đích chính là: what happening on AWS? by logging all event của service or app  

> Q. Yêu cầu những ng chịu trách nhiệm cho Development instances thì ko dc quyền access vào Production instance. Làm nào?

Define tag cho 2 Prod và Dev, add condition vào IAM Policy chỉ cho phép những tag cụ thể

**---P4---**

> Q. 1 cty host DB trên RDS, có Read replica, các bản report của app dc gen trên Read replica, Nhưng đôi lúc report show data cũ. Vì sao?

Do replication lag, độ trễ khi async giữa origin với replica

> Q. Bạn setup Cloudtrail cho cty, yêu cầu là log này cần dc encrypt, làm sao?

Chẳng cần làm gì, vì log của Cloudtrail default dc encypted rồi (nó dùng Server side encrypt SSE)  
Có thể dùng KMS, hoặc store trên S3  

> Q. 1 cty dùng S3 là tầng Data layer, có các request đến s3 để read/write/update object, User phản ánh là sometime các update ko dc phản ánh. Vì sao?

Vì Update object s3 là Eventual consistency model (yếu), có 1 khoảng time delay, cứ F5 là cuối cùng sẽ thấy update thôi

> Q. Bạn bật CORS cho S3 bucket rồi, bạn đã nhập 3 domains là origin để allow rồi. Nhưng khi test thấy 2 method OPTION và CONNECT ko work, trong khi các method khác đều work, vì sao?

Bởi vì CORS S3 bucket chỉ support 5 method là GET POST PUT DELETE HEAD thôi

> Q. 1 cty có 1 contest cho user up ảnh thi. Cuộc thi dài 2 tuần, ảnh sẽ dùng để phân tích trong 3 tháng. Các file sẽ dc access 1 lần rồi xóa. Dùng Cái gì cho kinh tế, có thể scale?

S3 IA

> Q. 1 cty host nhiều data trên on premise, và giờ muốn backup this data lên AWS, làm nào?

Dùng Storage Gateway Stored volumes (data vẫn ở local và dc async to s3)

> Q. 1 cty muốn move Postgres SQL to AWS, họ muốn có các replicas và auto backup, Dùng cái nào? Aurora PostgresSQL hay RDS PostgresSQL?

Aurora (cũng đáp ứng dc nhu cầu như RDS nhưng Aurora có performance gấp 3 lần RDS)

> Q. User trong cty cần nơi lưu documents, mỗi user cần có 1 location riêng, và các user khác ko dc view documents của nhau. Dễ dang retrive docs của mình, làm nào?

S3 (có thể restrict user đến từng folder file trên s3)

> Q. 1 cty dùng Glacier để archive data. Muốn time để retrieved data trong khoảng 3-5h thì dùng cái feature nào của Glacier?

Standard retrieval (3-5h)  
Bulk retrieval (5-12h)  
Expedited retrieval (1-5min)  

> Q. Muốn repicate current resource AWS to another region làm nào?

Cloudformation

> Q. Bạn có các IIS Server chạy trên EC2. Giờ muốn collect và process logs file dc gen từ EC2 ra, làm nào?

Store logs trên S3 và Dùng AWS EMR để process log file

ko nên dùng DynamoDB để lưu log files

> Q. Bạn muốn dùng AWS host website, www.example.com. Cần deploy quickly và ko cần server-side script. Cái gì nào?

Đăng ký 1 domain bằng Route53 và verify trước rằng S3 bucketname match với domain sẽ đăng ký trên R53

> Q. Bạn là SA, quản lý 1 web server, dùng Cloudtrail và store all cloud trail event log files vào S3 bucket. Auditor của AWS nói rằng ko đảm bảo tính xác thực của những file log lưu trên s3 bucket đó, ko có gì đảm bảo những file Cloudtrail log đấy ko bị chỉnh sửa. Làm nào?

Enable tính năng Cloudtrail log file integrity validation.

Khi bật lên thì nó sẽ tạo 1 hash file (digest file) cho mỗi Cloudtrail log file dc sinh ra. Nó dc save ở 1 folder khác cùng bucket. Mỗi file có 1 public key và private key. Nó đảm bảo rằng tất cả các những chỉnh sửa đối với Cloudtrail log file đều dc record lại.

Dùng SSE (serverside-encryption) là sai vì nó là mặc định của cloudtrail log rồi, nhưng ko đảm bảo dc tính authenticity của log files.

KMS cũng vậy, ko đảm bảo dc tính authenticity (xác thực).

> Q. Bạn cần ensure là data trên s3 dc encryted nhưng ko muốn quản lý encryption key. Dùng cái gì?

SSE-S3, vì S3 sẽ quản lý cả data key và master key.  

ko dùng SSE-KMS vì KMS thì nó quản lý data key bạn phải quản lý master key.

> Q. 1 Cty đang có Redshift cluster trên aws. Cần monitor performance và ensure đấy là performance hiệu quả nhất có thể thì dùng gì?

Cloudwatch và AWS trusted advisor

> Q. Web của bạn dùng s3 và cloudfront để cache. Bạn tạo 1 cloudtrail ở mỗi region và các event log file dc lưu vào s3 bucket ở us-west-1. Có 1 thay đổi của cloudfront làm all traffic route to origin, tăng độ trễ cho user. Phát hiện ra là vì có những event log bị doublicate ở Cloudfront. Làm sao?

Dùng AWS CLI để để disable global service event đang deliver log file to all region ngoại trừ us-west-1

Cái này ko thể dùng AWS Console dc.

> Q. Cloudfront Query string forwarding cần chú ý gì?

Chỉ support web distribution (ko support RMTP distribution - Real Time Message Protocol).  

Phân cách giữa các query string parameter phải là ký tự `&`.  

Param name và Param value là case-sensitive (phân biệt hoa thường).  

> Q. 1 IOT sensor để đếm số bag ở sân bay. Data gửi tới kinesis với default setting. Mỗi alternate-day (48h) data dc send to S3 để processs. Nhận ra là S3 ko nhận all data từ kinesis stream, vì sao?

Vì kinesis default chỉ lưu data 24h (có thể setting 168h)

> Q. Cơ chế làm việc của AWS CloudHSM là gì?

Ephemeral backup key (EBK) dùng để encrpyt data, Persistent backup key (PBK) để encrpyt EBK sau đó save to S3 in same region với CloudHSM.  
Dịch vụ CloudHSM này gần giống với KMS nhưng dùng khái niệm key khác nhau thôi.  

> Q. Bạn quản lý app trên AWS. Gồm ec2, route53, CLB, ASG. Cần dùng blue-green deployment thì cần dùng policy nào của R53?

Weighted Policy

> Q. (from Airbus documents) AWS Direct Connect có encrypt data ko?

ko. Vì nó sử dụng mạng riêng và private hoàn toàn. Muốn encrypt data in transit thì dùng thêm VPN

> Q. Bạn dev 1 app dùng AWS Polly (text to speech), bạn muốn test như sau,chữ S3 đầu tiên thì đọc là "Simple Storage Service", còn những chữ S3 sau đó thì đọc là "S3" thôi. Cái case này cần test ở 2 region us-east và us-west. Làm nào?

Dùng nhiều Lexicons, tạo các alias khác nhau cho từ "S3", và apply theo thứ tự khác nhau. Rồi upload Lexicons đó lên cả 2 regions us-east và us-west

> Q. AWS polly mà bạn dùng cho web app của bạn bị user phản hồi là đọc quá nhanh và liên tục. Làm sao?

Convert dấu phẩy trong content thành period.  

Add a pause bằng cách sử dụng `<break>` tag giữa các đoạn phù hợp.  

Add `<emphasis>` tag với value = `Strong` với từ phù hợp để nhấn mạnh.  

> Q. Bạn có 1 web server cung cấp docs lưu s3, có dùng Cloudfront, nhưng ko muốn user có thể access trực tiếp vào s3. Làm nào?

Tạo OAI (origin access identity) cho Cloudfront và grant access vào obbject trong s3 cho CFront.  

Làm điều này thì User chỉ có thể access vào s3 object bằng cách đi từ Cloudfront, chứ ko thể đi trực tiếp đến s3.  

Bạn tạo Cfront signned URL/cookie để access vào S3 bucket, sau đó tạo 1 Cloudfront User đặc biệt gọi là OAI. Rồi config để Cfront để nó dùng OAI access và serve file trên S3 (trên S3 bucket cần config permission để chỉ OAI có quyền access vào các object). Những user thông thường sẽ ko thể sử dụng S3 URL để access S3 nữa.

> Q. App của bạn đang làm Load test. DB bạn dùng RDS MySQL. App ko phản hồi khi CPU 100%. App thì là loại read-heavy. Làm nào?

Add Read replicas.  
Add Elasticache to RDS.  
Shard your data set among nhiều RDS DB instances (Sharding là 1 concept split data thành nhiều table trong 1 database).  
Ko thể dùng ASG với RDS dc.  

**---P5---**

> Q. Muốn mỗi file up lên s3 phải dc lưu file name vào DynamodB làm nào?

S3 trigger trực tiếp event cho Lambda. (ko cần qua Cloudwatch)

> Q. 1 app cần DB trên aws. Read/write on DB chỉ cần số nhỏ thôi. Thì nên chọn cái nào?
EBS General Purpose SSD hay EBS Throughput Optimized HDD?

dùng EBS General Purpose SSD.  

EBS Throughput Optimized HDD (max throughput/volume=500M/s)  

EBS General Purpose SSD (max throughput/volume=250M/s)  

> Q. Bạn có 1 web dùng Network LB save log vào S3. User phàn nàn về delay? Làm nào để tìm những Client IP có thời gian delay khi access (TLS handshake time)?

AWS Athena.  
ko cần dùng Quicksight vì đấy chỉ cần trong TH muốn visualization/tạo report thôi.

> Q. 1 cty upload 1 lượng lớn data to S3 và liên tục từ nhiều nơi trên TG. Dùng Athena để query data đó và Quicksight để tạo report daily. Nhưng thi thoảng bị lỗi exception từ s3. Cost cũng mất nhiều tiền, Làm sao đây?

Partition data based on date và location.  
Tạo 1 workgroup riêng base on user group.

Vì giá tiền Athena base trên số query và lượng data scan dc mỗi query. Nên cần chia data ra mà query.

> Q. 1 Cty cần store 10TB file đã scan. Yêu cầu 1 search application để search các file đó, làm nào?

Store ở S3 standard redundancy, và dùng CloudSearch để query, Beanstalk để host webssite multiAZ.  
Amazon CloudSearch: Bạn tạo 1 domain và upload data lên đó để search.

> Q. 1 Cty dùng AWS Glue và Athena để analyze data, có upload data 1 lượng lớn lên S3 daily và liên tục. Để giảm thời gian scan data thì cần ensure là chỉ scan các changes in dataset thôi. Làm sao?

Enable Job Bookmark in AWS Glue.  

Nếu Reset Job Bookmark sẽ reprocess all data.  

Nếu Disable Job Bookmark sẽ process all data each time.  

Nếu Pause Job Bookmark thì mỗi lần scan nó sẽ scan từ lần cuối Bookmark dc enable.  

> Q. 1 Cty sợ dev có thể xóa Ec2 resource trong môi trường Production, làm sao?

Tag production resource và deny quyền xóa resource có tag Prod.  

Tạo riêng 1 AWS Account và move developers vào account đó.  

> Q. Bạn đang Dùng AWS X-ray để tracing, setting gì để cost in limit?

Sampling at low rate

> Q. 1 cty lo ngại về tính redundancy của EBS Volume mà họ dùng, làm nào?
redundancy: là phương pháp lưu 1 thông tin ở nhiều ổ, khi có sự cố thì có thể nhanh chóng lấy lại

Default là EBS đã dc replicated trong Az rồi để có HA và Durability (nên ko cần lo ngại về tính redundancy)

> Q. Muốn xây dựng hệ thống decoubled nên dùng service nào?

SQS và SNS.  
ko phải ELB hay ASG.

> Q. 1 Cty dùng AWS WorkDocs để share document vs third party. Bị leak thông tin nhạy cảm nên giờ team security cần phân quyền lại như nào?

chỉ cho quyền cho Power users có khả năng invite ng mới.  
Chỉ cho Power user có khả năng share publicly.

> Q. Bạn đang dùng SQS, đôi khi bị lỗi client get price trước khi login vào site, nên bạn chuyển sang dùng SQS FIFO, cần làm trước gì để việc migrate sang SQS FIFO dễ dàng?

Mỗi FIFO Queue cần có Message group ID bất kể khi nào.  

Với những message bodies mà "giống hệt nhau" (identical): hãy dùng `unique deduplication ID`  

Với những message bodies mà "unique": hãy dùng `content-based deduplication ID`. (khi đó SQS dùng SHA-256 generate ra deduplication ID)  

> Q. 1 cty muốn dùng 1 phương thức deployment tự động như tạo LAMP stack, download latest PHP từ s3, setup ELB. Dùng cái gì?
Beanstalk hay Cloudformation?

Beanstalk. Vì Beanstalk để deploy app còn CF để tạo resource

> Q. Bạn Dùng EMR để run big data framwork, muốn giảm cost thì làm gì?

Dùng Spot instance for underlying node

> Q. 1 application cho traders in market, có thể có multiple trading của client. Bạn có nhiều ec2 để process các trading này song song. Và mỗi trade phải stateful và xử lý độc lập. Dùng SQS với setting gì?

SQS FIFO Queue sử dụng Message Group ID

Message Group ID: chỉ định cho 1 group các messages, những msg thuộc cùng group sẽ luôn process lần lượt. Để xen kẽ các message group trong 1 single FIFO queue (Ví dụ session data của nhiều user), trong scenario đó nhiều user có thể process queue nhưng session data của mỗi user vẫn dc process theo FIFO manner.

Receive Request Attempt ID: dùng để retry same request nhận được trong TH SDK thực hiện bị lỗi

Deduplication ID: Nếu 1 msg dc gửi thành công, các msg sau với cùng Deduplication ID sẽ đc nhận nhưng ko dc deliver trong vòng 5 minutes.

> Q. Phòng IT yêu câu all IP traffic in out của 1 EC2 cần monitor, dùng cái gì?

VPC Flow log. Sẽ monitor all IP traffic đến và ra khỏi ENI của VPC bạn. 

ko dùng CloudTrail vì nó để: ai made API call? khi nào, call cái gì?

- Bạn có RDS PostgreSQL. Bạn cần backup DB và dc asynchronous copy. Dùng cái gì?

Enable Read Replicas for DB. Khi đó bạn phải chỉ định DB, rồi AWS sẽ tạo snapshot của DB instance, rồi tạo read-only instance từ snapshot. Rồi nó dùng Async để update Replicas.

Ko dùng Enable Multi-AZ vì nó sẽ dùng synchronous chứ ko phải asynchronous.

> Q. Bạn dùng AWS Batch Job, data lưu trong S3, trigger Lambda, submit AWS Batch Job in a queue. Queue sử dụng EC2 và ECS để compute. Job của bạn bị stuck ở trạng thái RUNNABLE, Vì sao?

Các khả năng có thể xảy ra với việc stuck ở RUNNABLE:

awslogs log driver chưa dc configure trong EC2/ECS.  
insufficient resources: job của bạn define 4GB memory nhưng ec2 ko có đủ.  
no internet access với EC2/ECS.  
số lượng EC2 đến limit.  

Các trạng thái (state) của Job:  
SUBMIITED: 1 job vừa dc submit vào queue, chưa dc evaluated,  
PENDING: job các chờ các dependencies với job khác hoặc resource khác,  
RUNNABLE: job có thể chạy nhưng maybe stuck vì những lý do trên,   
STARTING: container image dc pull về và running,  
RUNNING: job đang chạy,  
SUCCEEDED: job exit with code 0,  
FAILED: job exit failed  

> Q. Có 1 lượng lớn data onpremise cần lên S3, DÙng gì để transfer?

Direct Connect, Snowball

> Q. Bạn vừa tạo 1 Redshift cluster, đang muốn dùng SQL client from EC2 connect đến Redshift cluster nhưng ko dc. Làm nào?

Sửa VPC SG (Security Group)

> Q. 1 cty cần block level storage lưu 800GB data. Cần encrypt data, nên dùng cái gì? EBS? Glacier? EFS? S3?

EBS

Glacier và S3: object level storage  
EFS: file level storage  

> Q. Bạn dùng AWS Batch Job. 1 số job thì cần làm nhanh vì quan trọng, 1 số job thì ko quan trọng lắm. Nên setting Job queue cho đỡ tốn tiền như nào?

Nhiều jobs, 1 job thì có EC2 ondemand instance, high priority, 1 job thì dung Spot instance với low priority

> Q. EC2 bị restart liên tục, giờ cần check log và analyze system log. Dùng cái gì?

AWS Cloudwatch Logs

ko dùng Cloudtrail dc.

> Q. Bạn dùng RDS MySQL làm DB layer, giờ muốn tăng connection tới DB thì làm nào?

tạo 1 DB parameter group, sửa cái max connection theo ý mình, rồi attach cái DB parameter mới đó vào DB instance

DB parameter group default thì ko thể sửa dc, phải tạo cái mới, rồi sửa, rồi attach vào DB

> Q. Bạn có 1 Redis cluster deploy in VPC ở us-east-1. Cần secure các access to Redis từ EC2 ở 1 VPC khác cùng region thì làm nào?

Enable Redis AUTH with in-transit encryption cho Cluster  
VPC peering

Không nên dùng VPC transit vì đó là giải pháp cho TH 2 VPC ở khác region.

Không dùng VPN Connection vì cái đó là giải pháp cho on-premise Server.

> Q. Bạn dùng Cloudfront cho 1 web distribute media content. Dc user truy cập thường xuyên. Giờ muốn tăng performance làm nào?

Tăng thời gian cache expiration lên.

> Q. Disaster Recovery solution mà cost phải minimum thì dùng DR mechanism nào?
  Backup and Restore, Pilot Light, Warm standby, Multi-Site ?

Backup & Restore

> Q. 1 cty có 1 số EC2 sau 1 ELB, giờ muốn dc notification mỗi khi latency vượt quá 10s. Làm nào?

Enable log on ELB với Latency alarm sẽ send mail và phân tích log bất cứ khi nào có issue

> Q. 1 cty muốn integrate data on premise lên AWS storage. Yêu cầu là all data vẫn phải keep low latency. Nên làm nào?

Storage Gateway Stored Volume (all data vẫn ở local, rồi async backup snapshot lên s3)

Ko dùng Storage Gateway Cached Volume vì yêu cầu `all` data vẫn phải low latency

> Q. 1 cty có 1 web infrastructure trên aws, (EC2,ELB,RDS) muốn hệ thống dc self-healing thì cần gì?

self-healing = HA  
Bật Multi-AZ feature của RDS lên.  
Dùng Cloudwatch metric check utilization của web layer, rồi theo đó mà điều chỉnh ASG

> Q. Những cái AWS Config có thể làm?

-Evaluate aws resource configuration  
-Lấy snapshot của config hiện tại của các resource nhất định  
-Retrieve configuration của resource    
-Retrieve history config của resource  
-Nhận noti khi resource dc tạo, sửa, xóa  
-Xem mối quan hệ giữa các resource  

**---P6---**

> Q. Bạn muốn tạo 1 instance mới ở 1 Az khác, EBS volume của instance mới cần lấy từ volume của 1 instance cũ, làm nào?

tạo snapshot của EBS cũ rồi tạo volume mới từ snapshot đó

Để có thể tạo 1 volume available trong 1 AZ mới thì cần tạo snapshot của cái cũ rồi từ snapshot đó tạo volume mới.  
Ko thể detach volume cũ rồi gắn vào cái instance mới dc vì *Khác AZ*

> Q. 1 Cty muốn move container-based app lên AWS. Cần 1 service mà họ ko phải quản lý infra cho orchestration service. Dùng gì? ECS fargate hay Beanstalk?

ECS Fargate, vì Beanstalk ko cung cấp service quản lý orchestration

> Q. 1 cty vừa develop 1 app mới, họ dùng Codepipeline giờ source stage thì chọn serice nào? và deploy stage nên chọn service nào?

source stage: CodeCommit  
deploy stage: Beanstalk  

deploy stage ko dùng CodeDeploy vì ko có exist infrastructure, mà các resource cần dc deploy mới, vì vậy dùng Beanstalk

CodeDeploy chỉ deploy app lên 1 EC2/onpremise server đã có sẵn (nó ko provision ra các resource mới)  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/aws-development-lifecycle-per-service.jpg)

> Q. 1 cty dùng CodePipeline, source code lưu S3, thay đổi trên s3 sẽ trigger CodepiPeline dùng Beanstalk để provision resource, Cần config gì để trigger CodePipeline nhanh hơn?

Để trigger Pipeline auto khi có thay đổi S3 thì cần Disable periodic checks của Pipeline  
và tạo Cloudwatch event rule, tạo Cloudtrail trail để detect thay đổi.

Cơ chế như sau:  
Mỗi khi S3 có thay đổi, event dc filter trong Cloudtrail rồi Cloudwatch event sẽ trigger start Pipeline. Nhớ là CodePipeline phải disable cái Periodic check để nó dùng event-based trigger

Có nhiều cách để start 1 Pipeline của AWS Codepipeline (bên trên là khi dùng S3 làm source):  
Nếu dùng CodeCommit làm source: Cần dùng Cloudwatch Event rule detect thay đổi, disable periodic check

Nếu dùng Github làm source: Cần dùng Webhook để detect thay đổi, cũng disable periodic check

Nếu dùng ECR làm source: Cần dùng Cloudwatch Event Rule để detect thay đổi, periodic mặc định ko thể enable được.


> Q. 1 cty có các phòng ban, mỗi phòng ban 1 AWS account, cần cách để security policy dc đảm bảo theo level account, dùng cái gì?

AWS Organizations và Service control policies

AWS Organizations giúp quản lý nhiều account 1 cách centrally. Service control policies sẽ cho phép bạn define những AWS API nào có thể/ko thể call bởi IAM thuộc Acount trong Organization. SCPs dc tạo bởi master account, là account dùng để tạo ra Organization

> Q. Bạn muốn reboot instance nếu status check FAILED , làm nào?

Dùng Cloudwatch alarm action

> Q. Công ty bạn lưu data trên EFS. Cần ensure là all client access vào EFS phải dc encrypt bằng TLS 1.2. Cách nào để seccure data in transit khi access vào EFS?

Dùng EFS mount helper để encrypt data in transit (cách này tiện và dễ hơn cách 2)

Dùng EFS mà muốn encrypt data in transit bằng TLS thì có 2 cách:  
cách 1 là Mount EFS với mount helper  
    `sudo mount -t efs  -o tls fs-12345678:/ /mnt/efs`  

cách 2 là ko dùng mount helper, thì sẽ phải download và install stunnel, run stunnel on port 2049, dùng NFS mount localport vào port của application.

> Q. Khi tạo VPC Peering cần chú ý gì?

Các VPC ko bị overlapping CIDR block  
Ko có yêu cầu gì về onpremise communication

> Q. Bạn cần tạo connection site-to-site VPN từ on premise network lên 1 AWS VPC. Cần chú ý gì?

Virtual private gateway attach vào VPC

Trong Customer Gateway có public IP của on-premise network

> Q. Công ty bạn muốn encrypt data at rest và muốn toàn quyền quản lý key và lifecycle của key, thì dùng service gì?

CloudHSM, bạn tự gen ra encryption key và quản lý key đó

ko dùng SSE S3, KMS vì những cái đó ko cho bạn toàn quyển quản lý key (SSE S3 thì nó full managed key, KMS thì nó manage data key và lifecycle của key còn bạn manage master key)

> Q. Bạn có các bản snapshot của EBS volume, nên giữ những bản nào?
original snapshot và latest snapshot hay cả 2?

Chỉ cần giữ 1 latest snapshot vì nó vừa là incremental và complete snapshot rồi

> Q. Bạn đang có 1 EC2 m1.small 300Gb EBS General purpose volume host 1 relational DB. Muốn tăng throughput của DB thì làm nào?

Dùng loại volume Provisioned IOPS volumes hoặc Dùng 1 EC2 lớn hơn m1.small

> Q. Cty bạn dùng RDS instances, bạn cần disable automate backup để save cost. Nếu disable thì cần chú ý gì?

Bạn đang disable tính năng point-in-time recovery

RDS default là tự động tạo bản storage volume snapshot của toàn bộ DB instance 1 ngày 1 lần. Retention cũng là 1 ngày. (có thể sửa thành 0-35 days)

Nếu disable tính năng tự động này thì: Khi disable rồi re-enable lại, bạn chỉ có thể restore từ thời điểm re-enable tính năng thôi, ko thể restore thời điểm **trước khi disable** nữa

> Q. 1 cty có 1 web app. Cần user across world access vào site vào xem các pages của site với độ trễ thấp nhất, dùng gì? Route53 với latency routing hay Cloudfront?

đặt Cloudfront làm distribution trc web app

ko dùng R53 với latency-based routing vì cái đấy dùng cho multi site và latency based sẽ routing giữa các sites.  
**ko hiểu giải thích của câu này**

> Q. 1 Cty có 1 web app, dùng Route53 để quản lý DNS. Configure R53 thế nào để ensure là custom domain point to LB?

Ensure là hosted zone dc tạo  

Tạo 1 alias record for a CNAME record to Load balancer DNS Name

> Q. 1 Cty đang có 1 workflow là gửi các video từ on premise lên aws để ec2 thực hiện transcoding bằng cách pull from SQS. SQS dc sử dụng để có vai trò gì trong hệ thống đó?
Đảm bảo thứ tự của msg à? hay để scaling các task encoding theo chiều ngang?

để scaling các task encoding theo chiều ngang

vì việc đảm bảo order ko đề cập đến trong câu hỏi

> Q. 1 Cty cần deploy 1 app lên 1 số ec2, yêu cầu low latency giữa các ec2 này? làm nào?

Cluster Placement Group

> Q. Bạn design 1 web app host trên ec2 sau 1 ELB. Cần consider cái gì để xây dựng web đó?

Cần xác định I/O operations 

Xác định minimum memory cần cho app

Chứ còn peak usage cho client thì ko cần vì ELB sẽ take care cái đó

> Q. Network Load balancer có support custom security policies ko?
default security policy của nó là gì?

NLB ko support custom security policies

default security policy của NLB là kết hợp Protocols & Ciphers

> Q. Bạn là AWS consultant cho shop online. 2 tier web app, web server trên AWS, data thì on premise data centre. DÙng NLB, all traffic giữa client và server dc encrypted. Để giảm load vào backend server,  họ tìm 1 solution để terminate TLS connection của NLB. Họ muốn 1 solution để quản lý certificate sử dụng khi terminate TLS connection của NLB.

Dùng 1 single certificate cho mỗi TLS listener (cung cấp bởi AWS Certificate Manager)

Doc của AWS viết, Bạn cần chỉ định chính xác 1 server certificate cho mỗi TLS Listener. LB sẽ dùng cert đó dể terminate connection và decrypt request của client trước khi gửi request đó đi. 

ELB sử dụng security policy là "TLS" để negotiate connection giữa client và LB. 1 security policy này bao gồm Protocols và Ciphers. 

Protocol dùng để thiết lập connection giữa client và server, đảm bảo data giữa client và LB dc private. 

1 Cipher là 1 thuật toán encrypt để tạo nhưng message dc mã hóa. 

Protocol sử dụng cipher để encrypt data.

Quá trình negotiate connection, Bên Client và bên LB sẽ đưa ra các list cipher và protocols mà mỗi bên support, cái cipher đầu tiên của bên Server match với bên Client sẽ dc chọn là kết nối an toàn (secure connection)

NLB chỉ support only single certificate per TLS Listener thôi.

NLB ko support những certificate lớn hơn 2048 bits

AWS Certificate Manager sẽ quản lý certificate cho bạn, tự động renew khi cert hết hạn

> Q. AWS Managed Blockchain, giữa các member thì 1 member có format resource enpoint là gì?

ResourceID.MemberID.NetworkID.managedblockchain.us-east-1.amazonaws.com:PortNumber

Các khái niệm: 

mỗi member trong network blockchain lưu 1 bản copy của sổ cái (ledger) ở local

việc add member vào blockchain network cần thông qua proposal và quá trình vote.
1 member trong network tạo proposal để invite 1 account vào mạng, những member khác vote, nếu proposal dc approve thì sẽ gửi invitation đi tới account kia.

việc remove member cũng vậy. Tuy nhiên Principal (quyền to) của network có thể remove member ko cần tạo proposal và voting 

mỗi member phải trả tiền membership khi vào network, và cả tiền peer node họ tạo ra, storage và lượng data dc write vào network

blockchain network chỉ bị delete khi mà member cuối cùng tự xóa khỏi mạng

khi 1 member join network, việc đầu tiên phải làm là tạo peer node (mỗi peer node lưu 1 local copy của sổ cái ledger)

> Q. Khi 1 ec2 từ Running -> hibernate (stop) -> Running thì các loại IP thay đổi như nào? Private IPv4 & IPv6, Public IPv4?

Private IPv4 & IPv6 sẽ retain, còn Public IPv4 thì release rồi renew

> Q. Khi 1 EC2 vào trạng thái hibernate (stop theo kiểu hibernate chỉ có trên các **dòng** EC2 M3, M4, M5, C3, C4, C5, R3, R4, R5, với **OS** Amazon Linux 1, và **type** On demand và Reserved) thì sẽ tính tiền những cái gì?

Tính tiền EIP (Nếu có) và storage space of EBS volume

**ko** tính tiền compute capacity (công suất tính toán)

**---P7---**

> Q. Muốn EC2 khi mình terminate vẫn giữ lại EBS volume thì làm nào?

chọn cái DeleteOnTermination for EBS = False

> Q. Bạn dùng RDS MySQL, Cần chắc chắn là hoạt động backup DB sẽ ko gây độ trễ cho những I/O operation bình thường lên DB. Nên làm sao?

ensure đã enable Multi-AZ cho RDS

Quá trình automate backup của DB sẽ làm I/O activity treo 1 thời gian ngắn khoảng vài giây. Với MariaDB, MySQL, Oracle, and PostgreSQL thì ko suspend primary db vì nó backup trên DB standby, not primary.

Với SQL server thì sẽ bị suspended 1 time ngắn

Automate Backup chỉ thực hiện với DB instance ở trạng thái ACTIVE

Khi xóa DB instance nếu bạn chọn "Retain automated backups" thì nó sẽ giữ lại backup, còn nếu ko chọn thì nó xóa hết và ko thể recover


> Q. 1 app dc xây dựng như sau: 1 nhóm ec2 accept video upload from users, 1 nhóm ec2 process videos đó. Làm gì để kiến trúc đó trở thành excellent?

tạo SQS queue để lưu thông tin video uploads. Các ec2 process video gắn vào ASG. Việc scale ASG dựa trên size của queue.

Doc của AWS viết:   
1 ASG quản lý các EC2 process message from sqs   
1 custom metric gửi đến Cloudwatch số lượng msg trong queue per ec2  
1 policy của ASG, scale dựa trên custom metric, cloudwatch alarm invoke scaling policy đó

cái policy cần có 1 value để dựa trên value đó scale ASG, thì cách tính như sau:  
Giả sử hiện tại SQS có ApproximateNumberOfMessages = 1500 msg, capacity (số lượng ec2 process) = 10 instances.  
Nếu thời gian trung bình xử lý 1 msg = 0.1s, và độ trễ lớn nhất có thể chấp nhận (longest acceptable latency) = 10s, thì **acceptable backlog per instance** = 10/0.1 = 100.  
100 sẽ là target value cho cái policy của bạn.  
Nhưng hiện tại **backlog per instance** = 1500/10 = 150.  
Suy ra cần giảm **backlog per instance** xuống 100, muốn vậy thì phải scale out thành 1500/100 = 15 instances. 15-10 = 5 instances sẽ dc ASG tạo thêm.  

> Q. 1 cty sắp host 1 app trên aws. Họ muốn load balance traffic dựa trên which route user choose. 2 route của app là /customer và /orders. Nên dùng loại ELB nào?

Dùng loại có path-based routing, đó là ALB

> Q. App của bạn tương tác với DynamoDB, đang có Read capacity là 10. Gần đây phát hiện hay bị throttling ở DynamoDB, làm sao?

Enable Autoscaling cho DynamoDB

Điều này sẽ khiến khi traffic tăng lên, nó sẽ provision read/write capacity để handle traffic mà ko bị throttling. 

Nếu bạn chỉ đơn giản tăng Read Capacity của table lên 20 thì chỉ là giải pháp tạm thời.

> Q. Bạn lưu data documents trên S3, ko truy cập thường xuyên, nhưng khi truy cập thì muốn access đc trong khoảng 20p, cần dùng loại gì cho tiết kiệm?

S3 IA

ko dùng Glacier Bulk retrieval (5-12h), Glacier Standard retrieval (3-5h)

> Q. Bạn có 1 app chạy trên các ec2 trong private subnet, giờ muốn access vào Kinessis stream mà ko đi qua internet, làm nào?

Tạo VPC Interface Endpoint cho phép Kinesis Streams

ko dùng VPC Gateway Endpoint vì cái đó dùng cho S3 và DynamoDB

VPC Interface Endpoint dc cung cấp bởi AWS PrivateLink, nó ko yêu cầu IGW, NAT device, VPN, Direct Connect, nó cung cấp khả năng comunicate giữa các AWS service

> Q. Cần monitor API activity cho mục đích audit thì cần dùng service nào?
Cloudtrail? AWS Config? AWS Inspector?

Cloudtrail thôi

> Q. 1 architecture như sau:  
1 set EC2 là web layer đứng sau 1 CLB  
1 set EC2 là proxy server  
1 set EC2 là backend server  

cần làm gì để có khả năng scalability?

ASG cho proxy server  
ASG cho backend server  
**ko** cần thay CLB bằng ALB (Application LB) vì Clasic Load Balancer vốn đã có khả năng scalability rồi

> Q. 1 cty cần host 1 app trên ec2. Có yêu cầu là bạn cần có quyền control số lượng core dành cho application. Dùng loại EC2 nào?

Dùng EC2 - Dedicated Host

AWS cho bạn toàn quyền trên 1 con server vật lý luôn, ko chia sẻ với ai, cho bạn toàn quyền control số lượng core, socket…, cho bạn quyền sử dụng licence có sẵn, ko mất tiền mua license của AWS nữa. Bạn có thể run nhiều instances trên cái host đó

nhớ phân biệt với Dedicated Instance:  
EC2 - Dedicated Instance:  
Tạo Ec2 trên 1 con server vật lý, đảm bảo duy nhất cho bạn (tuân thủ về mặt compliance)

> Q. Cty bạn lưu docs trên s3, muốn ensure là object s3 dc encrypt at rest, làm nào?
có thể làm trong phần bucket policy và bucket ACL ko?

ko.  
Có 3 cách encrypt data s3 là:  
SSE with S3 managed key  
SSE with KMS managed key  
SSE with Customer-provided key  

> Q. 1 cty host 1 active-active site. 1 site trên AWS, 1 site ở Onpremise. Cần các traffic dc distributed phù hợp trên cả 2 site. Dùng cái gì của Route53?
Simple / Failover / Latency / Weighted Routing ?

ở đây bạn có 2 resource.  
chọn Weighted Routing - cho phép bạn associate multiple resource với 1 single domain name, chọn bao nhiêu traffic sẽ dc route đến mỗi resource 

ko chọn mấy cái còn lại:  
Vì Simple chỉ dùng khi bạn muốn configure đơn giản, 1 resource cho 1 domain, standard DNS record

Failover dùng khi bạn muốn route traffic đến 1 resource khi resource còn lại unhealthy

Latency dùng khi bạn muốn improve performance của user theo region để giảm độ trễ

> Q. Giữa các VPC ở các regions khác nhau, muốn connect và ko pass ra internet? làm nào?

VPC peering và AWS Direct Connect

> Q. App của bạn có web tier và db tier trên ec2. Đang dùng General purpose SSD cho volume type. Đang gặp vấn đề về read write to DB. Làm nào?

vấn đề về read write to DB -> liên quan đến volume type, ko phải instance type như t2, m5 etc...

cần change to Provisioned IOPS SSD

> Q. App của cty bạn có ec2 với ALB. Cty muốn bảo vệ app khỏi application level attack. DÙng gì? Cloudfront/ WAF?

WAF

Chứ Cloudfront chỉ là service phục vụ CDN Content delivery

> Q. Cty đang setup app như sau: 1 set EC2 host web app, ELB, User access vào app qua ELB, app connect to backend db, NAT gateway. Nên setup các server và ELB ở các subnet như nào để HA và đúng architect?

2 public subnet cho ELB, 2 private subnet cho web server, 2 private subnet cho db

chú ý web server ko cần phải ở ngoài public subnet, như vậy secure hơn

> Q. 1 app gồm các componnents, 2 primary component cần chạy 3h mỗi ngày. Các components khác chạy 6-8h mỗi ngày. Nên dùng cái type instance nào cho tiết kiệm?

On-demand instance cho primary components, Reserved Instance cho còn lại

Primary component chỉ run 3h/day thì ko cần dùng Reserved

Ko dùng Spot instance vì ko biết loại workload (data analysis, batch jobs, background processing, and optional tasks?) để quyết định sử dụng spot

Reserved sẽ dc discount và rẻ hơn On-demand

# Các câu hỏi được note lại trong quá trình thi (chưa add câu trả lời)

> Q. 1 cty muốn encrypt data at rest, nhưng muốn encryption key dc managed ở on-premise. Dùng cái nào? S3 SSE-C (Server side encryption with customer provided key)? Hay CloudHSM?


> Q. 1 app có private subnet và public subnet, giờ private subnet cần ra ngoài internet, thì cần làm gì?  
Gắn IGW và update private subnet route table?  
Hay gắn NatGW vào public subnet và update private route table?


> Q. NAT Gatway sẽ add vào public subnet hay private subnet?


> Q. Giải pháp cho web static content, chọn `S3 static website` hay `cloudfront + s3 bucket as origin`?


> Q. 1 App ghi vào s3, user phản ánh hiển thị data cũ vì sao?   
Vì app đang read parallel request?   
Hay vì app đang read theo range of header?   
Hay vì app đang write kiểu ghi đè lên object có sẵn? 


> Q. App trên Ec2 memory intensive, cần config policy base trên cloudwatch metric như nào?   
Tạo custom metric from app?   
Hay tạo high resolution alarm?


> Q. App dùng Cloudfront, nhưng user phản ánh là họ đang thấy các data cũ, cần làm gì?   
Perform cloudfront refresh?   
Hay change TTL của cache trên cloudfront? 


> Q. App ghi vào db bị throttle thì nên làm gì?   
Dùng elastic cache và lazy loading?   
Hay elasticsearch và write-through db?   
Hay gắn ASG cho db?


> Q. App có 10 micro service mỗi cái 1 Clasic Load Balancer, Muốn giảm cost thì nên làm j?   
Thay hết CLBs bằng 1 single ALB?   
Hay change ASG desired?


> Q. Đang migrate on-premise proxy server lên aws, quyết định dùng ALB, cần secure communication, thì dùng cái gì?  
Dùng Third party để quản lý certificate manager?  
Hay tạo 1 SNI certificate và up lên ALB?  
Hay tạo 1 wildcard certificate và up lên ALB?  
Hay tạo 1 second proxy server để terminate SSL traffic?


> Q. SG cần allow trafic từ ALB, thì làm nào?  
Gắn ALB ip vào sg?, Hay gắn subnet ip vào sg?, Hay gắn vpc cidr vào sg?


> Q. 1 app dự đoán tuần sau sẽ phải x2 công suất thì asg config như nào?  
Dùng Scheduled scaling policy?  
Hay Dynamic Scaling policy?


> Q. 1 app dùng EC2 24/7 trong 1 năm, nên chọn type EC2 nào?   
Convertible Reserved EC2?  
Standard Reserved EC2?  
Scheduled Reserved EC2?


> Q. Khái niệm RTO RPO trong Disaster Recovery?