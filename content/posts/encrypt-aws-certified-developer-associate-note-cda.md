---
title: "Aws Certified Developer Associate Note (CDA)"
date: 2019-07-23T09:09:48+09:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Notes]
tags: [AWS]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Những notes của bản thân trong quá trình ôn thi chứng chỉ AWS CDA"
---
# Các câu hỏi và câu trả lời được note lại trong quá trình học

---P1---

> Q. 1 app đang stores session state in memory. Nên lưu nó ở đâu?

Store session state in an ElastiCache cluster

> Q. 1 app cần phải monitor các event. cần capture số lượng user login, thời gian đỉnh điểm, period 10s. làm nào?

Create a high-resolution custom Amazon CloudWatch metric

high-resolution metric: can specify a high-resolution alarm with a period of 10 seconds or 30 seconds,
regular alarm with a period of any multiple of 60 seconds

> Q. dev ko có quyền edit the code build nhưng có quyên run build/ làm nào để override the build command?

Run the start-build command with buildspecOverride property

> Q. cty đang dùng ElastiCache cluster. yêu cầu là logic trong code sao cho cluster chỉ request data từ RDS khi cache miss.Dùng strategy nào?

có 3 loại strategy của elastiCache:
Lazy Loading (chỉ request data đc cache, nhưng data cache có thể cũ),
data trong cache sẽ chỉ dc update nếu request bị cache miss, còn nếu data DB dc update riêng thì sẽ ko update cache.

Write Through (tốn resource, nhưng data luôn mới),
data trong cache sẽ luôn dc update mỗi khi data trong DB dc update.

Adding TTL (chỉ định thời gian hết hạn cho key, hạn chế việc data quá cũ)

> Q. 1 dev đang build app access s3. 1 IAM role đã dc tạo để acecess vào s3, API nào mà dev cần dùng để code access dc vào s3?

STS:AssumeRole

> Q. 1 lambda function tính toán số Fibonacci dùng vòng lặp invoke lambda vài ngày sau thì the Lambda function bị throttled. Best practice?

Theo best practice thì nên: Avoid the use of recursion, nếu vô tình làm thì nên set the function concurrent execution limit to '0' (Zero) ngay, Rồi update code.

1 số best practice của dùng lambda:

tách các Lambda handler,

tận dụng môi trường execute context,

dùng AWS Lambda Environment Variables để truyền param,

giảm thiếu số lượng deployment package xuống,

đừng up cả sdk lên tránh dùng vòng lặp trong code test performance,

test load,

delete function cũ ko dùng,

tận dụng AWS Lambda Metrics and CloudWatch Alarms,

ko cho function vào VPC nếu ko cần thiết,

chắc chắn rằng có đủ elastic network interfaces (ENIs),

nếu ko thì phải tạo cái subnet lớn hơn,

tạo dedicated Lambda subnets in your VPC.

> Q. 1 function lambda sẽ run in multiple stages, such a dev, test and production. và nó phải call các endpoints khác nhau tùy theo stage. làm nào để dev chắc chắn sẽ call đúng endpoint khi chạy trong mỗi stage?

dùng Environment variables

> Q. Dùng AWS SAM để define Lambda function. Viết 1 new function và cách nào để shift traffic từ function cũ sang function mới nhanh nhất Canary10Percent5Minutes, Linear10PercentEvery10Minutes.

Canary10Percent5Minutes: traffic dc shift 2 vòng. vòng 1 là 10% traffic, và tất cả 90% còn lại sẽ dc shift sau 5p Linear10PercentEvery10Minutes: traffic dc shift 10% mỗi 10p, sau 100p thì mới dc 100%

> Q. 1 dev đang migrate to cloud 1 app dùng MS SQL, data dc encrypt bang Transparent Data Encryption nên dùng cái gì để phải code ít nhất?

Amazon RDS, vì nó support Transparent Data Encryption (TDE), MS SQL

> Q. 1 dev đang viết vài lambda function access vào RDS. họ cần share các connection string that contains the database credentials, which are a secret. Cty có policy yêu cầu tất cả secret phải encrypted.nên dùng cái gì để phải code ít nhất?

Use Systems Manager Parameter Store secure strings

> Q. A developer is using Amazon API Gateway as an HTTP proxy to a backend endpoint. có 3 moi trường: Development, Testing, Production and three corresponding stages in the API gateway. Làm nào để direct traffic đúng enpoint của stages mà ko cần tạo riêng API cho mỗi stage

Use stage variables

> Q. 1 cty đang deploy static website trên s3. dev cần phải làm thành dynamic sử dùng serverless solution (code mà ko cần cài đặt server). 2 cái nào để làm?

API Gateway and AWS Lambda are the best two choices to build this serverless application

> Q. 1 cty đang có custom CloudWatch metric cho mỗi khi có lỗi HTTP 504 xuất hiện trong logs. và có 1 CloudWatch Alarm cho cái metric kia. Nếu muốn alarm dc trigger chỉ khi >= 2 evaluation periods. thì sửa cái gì?

Data Points to Alarm should be set to 2 while creating this alarm

> Q. 1 dev đang dùng AWS Elastic Beanstalk env cho 1 web app. Hiện tại đang dùng t1.micro. Sao để change thành m4.large??

Create a new configuration file with the instance type as m4.large

> Q. 1 cty dùng Aurora RDS. việc tạo report mỗi giờ làm chậm hệ thống/. Cần làm j?

tạo read replica DB và point cái reporting application đến read replica đó

> Q. 1 cty using AWS Elastic Beanstalk for a web app, Dev cần config sao cho sẽ create new instances and deploy code to those instances method nào sẽ deploy code ONLY lên instance mới?

Immutable, Blue/green

Phân biệt các loại deploy method của Beanstalk:  
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/elastic-beanstalk-deployment-method.jpg)

**All in One**: deploy lên exist ec2, thời gian deploy nhanh nhưng hệ thống sẽ có downtime trong lúc deploy, nếu fail thì user phải chịu downtime vì system bị treo, dev phải manual redeploy

**Rolling**: deploy theo batch lên exist ec2, bạn phải define số lượng ec2 trong 1 batch. Ví dụ có 3 ec2, mỗi ec2 là 1 batch.  
deploy lên 1 batch trước, nếu batch fail thì quá trình deploy dừng lại, hệ thống vẫn chạy bình thường vì còn 2 ec2 khác đang chạy ko fail. Tuy nhiên trong quá trình deploy toàn bộ hệ thống sẽ ko full capacity (năng suất) bởi vì ec2 mà đang deploy sẽ ko serve traffic. Nếu fail thì user phải manual redeploy.

**Rolling with additional batch**: deploy theo batch, tạo thêm ec2 để deploy version mới lên đó.  
Ví dụ có 3 ec2, mỗi ec2 là 1 batch. tạo thêm 1 ec2 deploy lên đó. Nếu success hết thì sẽ terminate 1 ec2 để đảm bảo hệ thống chỉ có 3 ec2. Đảm bảo là lúc nào hệ thống cũng full capacity. Nếu fail thì cái batch fail sẽ bị terminate

**Immutable**: deploy toàn bộ lên các ec2 mới. Nếu fail thì sẽ terminate các ec2 mới đó. Deploy time cũng lâu hơn. Chỉ duplicate các ec2 thôi, ko duplicate Load Balancer nên ko thay đổi về DNS.

**Blue/green**: deploy toàn bộ lên các ec2 mới. Duplicate cả ec2 và Load Balancer. Deploy time lâu ngang Immutable. Sau khi success thì bạn cần swap URL để route traffic đến 1 DNS green. Nếu fail thì swap URL lại môi trường blue cũ thôi. Chú ý là dùng cái này ko nên để DB ở trong Beanstalk env. Vì DB bị duplicate sẽ ko dc sync.

tham khảo: https://blog.shikisoft.com/which_elastic_beanstalk_deployment_should_you_use/


> Q. 1 dev đang viết 1 app store data vào Dynamo DB, tỷ lệ đọc viết vào db là 1000 reads:1 writes. data dc access liên tục Dev cần enable cái gì trên DynamoDB để optimize cost và performance?

Amazon DynamoDB Accelerator (DAX)

> Q. 1 API dev đang dc yêu cầu dùng deploy bang API gateway, nếu là API frontend thì config cái j? nếu API backen thì cần config j?

API frontend thì config medthod respone và method request nếu API backend thì cần config integration request và intergration response

Q.bạn đang dùng lambda tương tác với DynamoDB, sau 1 time thì kết quả bị delay. cần DEBUG thì dùng cái j?

AWS X-Ray

> Q. 1 cty đang dùng AWS Code Pipeline for CICD, code lấy từ S3, cty yêu cầu all data phải encrypted và key dc customer quản lý. Cần enable những gì?

Serverside encryption ở S3 bucket, dùng AWS KMS for s3 encryption

> Q. 1 App đang dùng 1 DynamoDB table để store 1 số items. những items này chỉ dc access vài lần sau đó thì có thể xóa. Quản lý việc xóa item đó bang cách nào?

enable TTL cho DynamoDB, cho phép set timestamp để tự động xóa items. việc versioning với DynamoDB là ko thể

> Q. You are using AWS Envelope Encryption for encrypting all sensitive data. Data dc encrypt như thế nào với data key và master key

data dc encrypt bằng plain text data key, và data key đó thì lại dc encrpypt bang plain text Master key nữa.

> Q. team bạn đang deploy 1 micro service và 1 app lên aws. Yêu cầu là phải quản lý app kiểu orchestration. dùng service nào để giảm thiếu effort admin nhất?

Use the Elastic Container Service

> Q. bạn đang deploy 1 app với kiến trúc như sau; ec2 để process video, ASG, SQS, có 2 mức giá free và premium. SAo để user là premium luôn dc ưu tiên?

tạo 2 queue trong SQS. user có premium thì ở trong queue dc ưu tiên xử lý trc

> Q. 1 kiến trúc dc vẽ ra cho mobile app. User cần sign in bang google, facebook. User cần có chức năng quản lý profile. Nên dùng cái gì?

using User pools in AWS Cognito User pool cung cấp: Sign-up and sign-in services, Social sign-in with external identity, quản lý and user profiles, MFA, protect, phone,mail verfy user migration.

> Q. Cong ty bạn làm 1 app làm việc với DynamoDB. yêu cầu all data cần encrypt at rest. phải làm nào?

enable chức năng encryption khi tạo dynamoDB table, chứ tạo rồi thì ko encrypt dc nha

> Q. bạn đang deploy 1 app lên AWS Elastic Beanstalk. đây chỉ là môi trường dev. Cần phải tốn ít time nhất cho mỗi lần deploy. Cần dùng phương thức deploy nào?

All at once, tốn ít time deploy nhất.nhưng nếu deploy fail thì app sẽ bị downtime, nhưng vì môi trường dev nên ko ảnh hưởng lắm.

> Q. bạn đang dev 1 app trên aws theo kiểu micro service, các services đc tạo base trên lambda, vì sự phức tạp của flow các component nên cần 1 cách để quản lý flow của nhiều fcn lambda? dùng cái j?

AWS Step function

> Q. bạn có 1 app cần inject data từ nhiều thiết bị. Bạn cần đảm bảo data phải dc pre process trước khi đưa vào phân tích. dùng cái j?

dùng kinesis + lambda để define data cấu trúc như nào trước khi dc query.

> Q. bạn cần deploy 1 app lên ec2. data của app dc store ở 1 volume riêng. và cần dc encrypt at rest. Cần làm gì?

khi tạo volume cần enable encrpytion, và sử dụng KMS service

> Q. bạn dc yêu cầu customize content của app. Content này dc distribute to user thông qua Cloudfront. content origin ở S3 làm nào?

dùng lambda@edge, nó cho phép customize content mà Cloudfront deliver. Ví dụ: 1 web bán quần áo. bạn dùng cookie để điều hướng màu nào user đã chọn cho áo, bạn dùng lambda để change cái request chọn màu đó để cloudfront trả về hình ảnh của cái áo với màu đã chọn giảm độ trễ, tăng trải nghiệm ng dùng.

> Q. 1 tool để quản toàn bộ life cycle của dự án, project?

CodeStar

> Q. bạn đang dùng Route53 để point DNS name của cty đến web app. Bạn muốn deliver app lên 1 phần nhỏ người dùng để test. Làm nào?

Dùng Route53 weighted policy để chỉ định 1 phần nhỏ ng dùng

> Q. khi dùng Lambda với S3, best practice để pass parameter vào lambda là gì?

Dùng Lambda environment variables để truyền s3 bucket name

> Q. bạn có vài lambda function cần deploy bang Codeploy, làm nào để chắc chắn sẽ deploy đúng version của function

chỉ định rõ version sẽ dc deploy trong AppSpec file

> Q. bạn đang dev 1 app game dùng aws. làm nào để chắc chắn cái bang xếp hang của game luôn chính xác?

Dùng elastic cache Redis

> Q. bạn đang có 1 app dev trên ec2, app cần lấy private IP của instance 1 cách tự động trong code. Làm nào?

Query trong instance metadata. curl http://169.254.169.254/latest/meta-data

> Q. trong Lambda code, function dc call để lambda execute code là gì?

Handler

> Q. làm sao để S3 ko cho upload những file chưa dc encrypted

update policy cho S3, trong policy phải defined condition

> Q. bạn cần tìm chỗ lưu data. nhưng data ko phù hợp schema nào cả. data có thể đánh index. dùng loại nào?

DynamoDB

> Q. Eventual Consistency và Strong Consistency

Eventual Consistency=Weak Consistency, nhất quán yếu, sau khi 1 update vào DB, các read request sau đó ko đảm bảo data latest, có thể cũ, nhưng sau 1 time sync giữa các DB thì cuối cùng read request sẽ có dc data latest. 

Strong Consistency: sau khi 1 update vào DB, các read request sau đó đảm báo chắc chắn sẽ có dc data latest, nhưng mà nếu vẫn đang trong time sync giữa các DB thì read request đó sẽ bị delay (trạng thái bận) cho đến khi sync OK hết mới trả về KQ.

> Q. DynamoDB, item size 4KB cần 1 read request 
(Strongly Consistency): 1 read request ~ 1 read capacity UNIT (RCU) 

(Eventually consistency): 2 read request ~ 1 read capacity UNIT (RCU) cái read request nào đắt hơn?

-> 1 read request (Strongly Consistency) có giá gấp đôi 1 read request (Eventually consistency) (vì phải 2 read request (Eventually consistency) mới đổi ngang ra 1 RCU) 
vậy nên nếu file size = 8KB 

8KB -> bạn cần 2 read request -> bạn cần 2 RCU (Strongly Consistency) 

8KB -> bạn cần 2 read request -> bạn cần 2 chia 2 = 1 RCU (Eventually consistency)

> Q. DynamoDB, eventually read, 300 items/30s 10 items/s, 1 item = 6KB thì cần set table bao nhiêu RC (read capacity 1 giây)?

6KB -> cần 2 read request -> cần 20 request trong 1s vì là eventually read -> 20/2 = 10 RC trong 1s

> Q. có 1 app trên ec2, sau 1 ELB, bạn cần monitor các connection đến ELB, dùng cái j?

enable access log trên LB

> Q. Bạn cần dev 1 app mà yêu cầu là phải decoupled system. Nên dùng cái gì để xử lý message cho hệ thống decoupled (tách rời)?

SQS

> Q. 1 static web dc host trên s3 bucket. có 1 java script section muốn access vào data trên 1 s3 bucket khác. giờ cái web đó ko load dc trong browser. vì sao?

chưa enable CORS for bucket

> Q. app của bạn gen report của 10 user mất 4h. bạn cần 1 app có thể report at real time, always up to date, giải quyết dc số lượng request tang cao. dùng cái j?

post log data lên kinesis để nó analyze.

> Q. Bạn đang làm mobile app. Nếu cần chỗ lưu session data of user thì chọn db nào?

DynamoDB

> Q. App của bạn dùng DunamoDB, làm sao để chắc chắn rang mỗi khi 1 item dc update vào primary table thì 1 record khác cũng dc insert vào secondary table

dùng DynamoDB stream

> Q. 1 app dùng DynamoDB cho data backend. table size 20GB. Lhi scan table hay bị lỗi throttling. Làm sao để tránh lỗi.

Reduced Page size

> Q. Cty của bạn muốn tạo 1 môi trường mới trên aws. muốn sử dùng Chef đã có sẵn trên aws. Làm nào?

Dùng AWS Opswork. nó cung cấp các instance có chef, Puppet, tool để automate configure server

> Q. Bạn build 1 app lên ec2. rồi thực hiện test. bạn muốn capture log từ web server để phát hiện issue nếu có. Làm nào?

install cloudwatch agent lên ec2. configure để agent đó send log của server lên cloudwatch

> Q. App bạn đang dùng Cognito để quản lý user identity. Giờ muốn analyze data của user trên cognito. Dùng cái j?

Cognito Stream

> Q. Nếu Elastic Beanstalk ko có môi trường thỏa mãn nhu cầu?

Tạo custom platform trên Beanstalk, dùng packer.

> Q. App dùng DynamoDB, write 10 item trong 1s. mỗi item 15.5 KB. Vậy cần setting Write throughput bao nhiêu?

1KB = 1 write request-> 15.5KB = 16 write request. 

10 items -> 160 write request.

1 read request = 1 WCU -> 160 WCU/s

---P2---

> Q. Elastic Beanstalk đang chạy 1 app. muốn config môi trường thì cần đặt file config trong folder nào?

.ebextensions

> Q. Lambda default time out là mấy giây?

3s

> Q. Bạn cần setup restful api service trên aws, nên dùng kết hợp những service nào?

Host code api trên lambda, dùng API gateway để access vào api.

Host code api trên ec2 dùng ELB để path routing to api


> Q. bạn dev 1 app cần dùng service authen. nhưng có 1 số video cần cho phép access từ những unauthenticated identity. best practice?

AWS cognito và enable unauthenticated identity

> Q. 1 app cần process các message theo order ko bị dublicate, SQS có 2 loại gì?

FIFO và standard

> Q. CodeDeploy có process hook là gì?

App stop -before install - after install - app start

> Q. Làm sao để debug Lambda?

them code debug vào rồi lambda sẽ đẩy all log lên cloudwatch log

> Q. Dùng Lambda nhưng cần include các thư viện ngoài thì cần chú ý gì?

Chỉ them các thư viện cần thiết, tránh upload toàn bộ sdk, chỉ up những module mình cần cho lambda

> Q. team bạn có 1 Code Commit repository trong accout bạn. làm nào cho các account khác truy cập repo của bạn?

tạo cross account role, cho họ role arn để họ vào dc.

> Q. Bạn có 1 lambda chạy async (dc retry vài lần trước khi bị discard trong TH lỗi) Làm sao để debug issue nếu function fail?

Dùng DLQ Dead letter queue

> Q. bạn đang dùng kinesis stream cho app ở cty. Yêu cầu data at rest phải dc encrypt. Dùng cái j? server-side encrypt hay client-side encrypt?

enable Server-side encrypt cho kinesis stream, vì nó là feature của Kinesis, ko có feature Client side trong kinesis. ko nên dùng client side encrypt vì tốn nhiều thời gian

> Q. bạn đang dev 1 app dùng kinesis, để tang throughput, bạn dùng nhiều shard. Nhưng nhược điểm là j?

ko thể đảm bảo thứ tự order của data khi multi shard, bạn chỉ có thể order trong single shard thôi.

> Q. DynamoDB có mấy kiểu primary key?

kiểu 1: chỉ có partion key, là key unique

kiểu 2: partion key và sort key kết hợp thành bộ key unique nên chọn những key dc generate 1 cách auto ra key unique

> Q. S3 đang dùng. sau khi bật cái encryption data at rest bằng KMS thì performance giảm xuống vì sao?

mỗi lần bạn download or upload S3 nhưng object đã dc encrypt bằng KMS, S3 sẽ gửi request đến KMS để encrypt hoặc decrypt, Nếu vượt quá 5500 or 10000 thì KMS sẽ bị throttle. và giảm performance

> Q. Read replica có dùng cho DynamoDB và RDS ko?

dùng cho cả 2. (nhưng nếu DynamoDB thì phải nói rõ là DynamoDB Accelerator (DAX) thì có thể có đến 9 read replicas)

> Q. Nếu lambda ko push log lên cloudwatch log?

có thể do role chưa có quyền push log to cloudwatch

> Q. với 1 app được setting 5 RCU thì mỗi giây read dc bao nhiêu KB data

TH strongly consistent: 5x4=20KB read mỗi giây TH enventually consistent: 5x2x4=40 KB read mỗi giây

> Q. Bạn đang dùng DynamoDB, data cần đi qua vài region trên toàn TG. làm sao để giảm độ trễ?

enable global tables

> Q. Bạn đang dùng DynamoDB, app dc design để scan toàn bộ table. Làm sao để tang performance?

dùng scan song song (parallel scan) hoặc design app để dùng query thay vì dùng scan

> Q. bạn có 1 lượng lớn data cần dc stream trực tiếp lên S3. Nên dùng cái j?

Kinesis Firehose vì cái này lên S3 trực tiếp

> Q. Cty bạn đang dùng Kinesis Firehose để stream data to S3. Nhưng họ cần transform data trước khi lên S3 thì dùng cái j?

kinesis Firehose invoke lambda để transform data

> Q. bạn host static web trên S3. Code gần đây dc change ở chỗ java script để call đến 1 web page ở 1 bucket tương tự, nhưng browse block request. Làm sao?

enable CORS on bucket

> Q. S3 bucket mà đang bật encrypt data at rest thì khi request tới, S3 sẽ deny những request như nào?

những request ko có attribute sau trong header: x-amz-server-side-encryption

> Q. bạn đang enable server logging trên s3. bạn host 1 static web khoảng 1MB trên s3 bucket. sau 2 tuần thì bucket 50MB. vì sao?

server logging đã push log vào same bucket. cần có lifecle để delete log cũ

> Q. 1 cty đang có api viết trên lambda, họ cho phép KH access API của họ qua API gateway. hiện tại có khoảng 6 tháng để move từ api cũ sang api mới. cách nào?

tạo them 1 stage trong api gateway tên là v2, để KH có thể dùng cả 2 version api.

> Q. 1 cty đang dev app mobile .app cần cho user dăng nhâp bang facebook. cái gì để quẩn lý user?

cognito

> Q. cái template CF của bạn có nhiều resource thì có nên tack thành các stack riêng ko?

có, tạo nested stack

> Q. Bạn dc yêu cầu tạo 1 API gateway stage mà tương tác trực tiếp với DynamoDB. cái gì cần dùng?

cần tạo 1 Intergration request. để forward các incoming method request đen backend, nó sẽ bắt chọ DynamoDB action phù hợp nhớ là DAX chỉ để giảm độ trễ cho DynamoDB thôi

> Q. bạn có 1 lambda function là backend cho API gateway ec2. bạn cần đưa api gateway URL để user test. thì cần làm gì trước?

tạo 1 deployment trong api gateway, rồi associate 1 stage cho deployment đó. khi bạn update API, bạn có thể redeploy bang cách associate 1 stage mới với cái deployment cũ.

> Q. bạn có 1 app host trên ec2. app là 1 phần của web www.demo.com, app dc update sang call API gateway, Tuy nhiên browser ko render respone và Javascript bị lỗi, Cần làm j?

bật CORS cho API gateway

> Q. 1 app đang call RDS. lúc high load thì do toàn query DB nên thời gian repsone lớn, cần làm j?

bật read replica cho DB, hoặc đặt elastiCache trước DB ko thể dùng cloudfront trước DB

> Q. 1 Cty dùng cache cho app của họ. Nhưng việc recover data lost trong cache rất tốn tiền nên ko muốn phải recover data lost in cache. Làm nào?

Dùng elasticCache Redis vì nó có HA chứ Elasticache memcached ko có HA

> Q. Bạn dùng ECS để deploy các containers. Nhưng giữa các container ko dc access vào nhau, vì mỗi container là 1 khách hàng phải làm thế nào?

config SG của các ec2 chỉ allow các request nhất định. 

Nếu muốn dùng Role thì cái đó dùng cho level Task của ECS chứ ko phải level container. 

Ko nên dùng access key vì sẽ ko secure. 

Các level: 1 cluster gồm nhiều task hoặc service. 1 task gồm nhiều container

> Q. khi call API trên ec2 gặp lỗi: You are not authorized to perform this operation. Encoded authorization failure message: oGsbAaIV7wl... thì làm nào để đọc dc message đã bị encode đó

dùng command aws sts decode-authorization-message

> Q. Bạn vừa define vài custom policy trên aws, bạn cần test permission của các policy đó. làm nào bằng CLI?

đầu tiên get các context key sau đó dùng command: aws iam simulate-custom-policy

> Q. 1 cty dùng Codepipeline để làm CICD. vì lý do bảo mật, các resource để deploy nằm ở các account khác nhau. Phải làm nào?

define custom master key KMS add a across acount role

> Q. Bạn deploy app len ec2, Dùng DynamoDB. Bạn dùng X-Ray để debug nhưng ko xem log dc. vì sao?

X-ray daemon chưa install trên ec2 IAM role attach vào ec2 ko có permission upload to X-ray

> Q. App của bạn ở trên cloud. Giờ có yêu cầu all state của all request vào STS. làm nào?

xem log đó trong cloudtrail chứ STS ko có chức năng logging

> Q. bạn dùng CodeDeploy để deploy 1 app to aws. app này dùng AWS system manager parameter để store secure param, trước khi deploy cần làm j?

cấp permission cho CodeDeploy bằng IAM ROLE, dùng command aws ssm get-parameters --with-decrpytion để nó decrypt password rồi dùng trong app

> Q. DynamoDB của bạn đang chạy tốt. sau khi update thì performace của DynamoDB giảm xuống. vì các query đang ko dùng partition key? làm sao giờ?

add an index cho dynamodb Table sửa lại các query để nó query đúng partition key cũng dc nhưng tốn effort

> Q. bạn deploy 1 app lên ec2. để test app thì bạn dc cấp access key để có quyển write vào S3. sau khi test xong thì 1 IAM role dc attach vào ec2 Role này chỉ có quyền read s3. nhưng phát hiện ra ec2 vẫn có quyền write s3. Vì sao?

Biến môi trường trong CLI đang dc set cho accesskey và nó sẽ được ưu tiên hơn IAM Role

> Q. Bạn đang deploy 1 app lên Beanstalk worrker, worker này chạy định kỳ. Cần phải config định kỳ trong file nào?

cron.yaml

> Q. 1 app đang dùng KMS để encrypt data. quá trình encrpyt và decrypt diễn ra như nào?

dùng master key đến generate ra data key dùng data key để decrpyt data

> Q. Nếu 1 web đang enable CORS thì khi call API backend cần những header nào?

access-control-allow-headers access-control-allow-origin access-control-allow-method

> Q. bạn đang làm việc với 1 app làm với XML message. bạn cần đặt app sau API gateway để KH call api. Cần config gì?

cần mapping request và respone

> Q. bạn dùng Serverless Application Model để deploy app, thì cần dùng command gì?

SAM package command và SAM deploy command

> Q. app của bạn đang trỏ đến vài lambda fucntion, khi 1 thay đổi update lambda, bạn cần làm các step nào để traffic dc shift sang version function mới 1 cách từ từ?

tạo alias với routing-config param, update alias với routing-config param bạn có thể setting cho các traffic đến version mới là 2% còn 98% là đến version cũ, nói chung bằng cách setting atrribute AdditionalVersionWeights.

> Q. 1 app đang sử dụng DynamoDB, mỗi giây có hàng ngàn request. 1 app khác lấy những thay đổi của DynamoDB đó, với mục đích phân tích. VD: a new customer add data vào DynamoDB, event này invoke 1 app khác send welcome email cho customer Dùng service nào?

enable tính năng dynamoDB Stream các VD khác: 1 app modify DynamoDB, 1 app khác capture những modify đó để cung cấp 1 usage metric cho mobile app 1 app để tự động send noti cho all friend in group mỗi khi có 1 ai đó upload image lên group.

> Q. Bạn đang dev 1 app upload ảnh từ user. nên lưu ảnh ở đâu, thông tin user upload ở đâu?

ảnh s3, thông tin user ở dynamodb (object identifier)

> Q. lỗi HEALTH_CONSTRAINTS_INVALID của CodeDeploy là j?

cần giảm số lượng instance nhỏ nhất mà b yêu cầu xuống, hoặc tăng số lương instance trong deployment group lên

> Q. App của bạn cần write to SQS. có policy là credential phải luôn encrypt và rote 1 lần /1 tuần. làm sao ?

dùng IAM Role attach vào cái ec2 chứa app

---P3---

> Q. Làm sao để chắc chắn các custom software dc install khi lauch từ elastic beanstalk. phải define ở đâu?

viết thành file YAML or JSON và để vào folder .ebextensions

> Q. Có thể bật MFA cho resource trong s3 ko?

Có. setting trong policy

> Q. Codedeploy dc configure để tự động rollback khi build fail, tuy nhiên khi rollback nó ko retrieve dc những file cần cho previous version, làm sao giờ?

manually add file cần thiết vào instance hoặc tạo 1 new revision.

> Q. CORS có thể set cho Lambda function ko?

ko, S3, và API gateway

> Q. bạn có 1 vài lambda fucntion host trên API gateway. bạn cần control xem ai access vào APi của bạn đang host trên api gateway thì dùng cách nào?

Cognito user pool, hoặc lambda authorizer

> Q. bạn dùng kinesis Firehose để stream data to S3. nhưng cty yêu cầu data cần dc encrypt at rest, làm nào?

enable Encrpytion cho kinesis Firehose, chắc chắn rằng 'Kinesis data stream' dc dùng để transfer from producer
nếu bạn config Kinesic data stream là data source của Kinesis data Firehose delivery stream, thì 'Kinesis data Firehose' sẽ ko store data at rest. mà nó store ở Kinesic data stream VD: bạn send data từ producer đến data stream, 'Kinesic data stream' sẽ encrypt data bằng KMS, rồi store data at rest. Khi 'Kinesis data Firehose' vào đọc data, 'Kinesic data stream' sẽ decrypt data và gửi cho 'Kinesis data Firehose' 'Kinesis data Firehose' sẽ store data đã decrypt đó trong buffer memory rồi gửi đến destination luôn (chứ ko lưu data at rest)


> Q. bạn dùng kinesis Firehose để stream data ,nhưng cty yêu cầu data cần dc encrypt in transit, làm nào?

install SSL certificate trong Kinesis Firehose chắc chắn rằng all record đang dc transfer via SSL

> Q. best practice để giảm cost khi dùng SQS?

dùng long polling, để send, receive, delete message chỉ với 1 action, dùng SQS batch api actions

> Q. app của bạn send request đến dynamoDB. nhưng vì request tăng lên nên app của bạn bị lỗi throttled. làm nào?

tăng throughout của dynamoDB table dùng exponential backoff ở trong request của app để nó retry request theo lũy kế delay time. bình thường mọi ng hay dùng cách chờ 1 time nhất định (1s) để retry request. nếu 1000 request gửi đến bị error, sau 1s sẽ có 1000 request như thế gửi đến-> lại lỗi nếu dùng exponential backoff, thời gian retry của mỗi request là khác nhau -> khả năng ko bị lỗi cao hơn.

> Q. bạn phải deploy 1 app dùng cloudformation. instance này cần install nginx trước. làm nào để làm với CF? best practice là gì?

dùng cfn-init helper script và AWS::CloudFormation::Init để define các config hơn là chạy từng command trong user-data

> Q. App cảu bạn host trên beanstalk. Có 1 sự thay đổi, nhưng bạn cần minimized downtime của app và current env ko dc thay đổi. dùng cách deploy nào? All at Once? Rolling? Immutable? Rolling with Additional Batch?

immutable, vì Rolling with Additional Batch thì current env vẫn có thay đổi

> Q. Bạn đang deploy 1 app dùng lambda và APi gateway. bạn cần deploy version mới nhưng version mới sẽ cho 1 phần nhỏ user thôi, làm nào?

tạo canary release ở trong API gateway

> Q. bạn có 1 dynamoDB table dùng global secondary index. Cách nào để lấy result latest mà ko ảnh hưởng đến RCU?

query bằng evetual read.
dynamoDB with global secondary index thì ko support consistent read, chỉ support eventual read thôi. với lại dùng Scan thì sẽ ảnh hưởng performance toàn bộ table

> Q. bạn cần setup 1 restFUL API in aws mà sẽ dc gọi qua URL https://democompany.com/customers?ID=1 KH sẽ nhận dc thông tin detail khi cấp ID cho API làm nào?

tạo API gateway và 1 lambda fucntion để get thông tin detail của KH expose GET method ra cho API Gateway

> Q. các bc để encrypt/decrypt data locally (hay còn gọi là client side) in your app thoe best practice nếu bạn đã có customer master key?

step encrypt:

customer master key (CMK) -> (generate) plain text data key + encrypted data key

plain text data key -> (encrypt) data rồi thì xóa đi

encrypted data key -> giữ lại

step decrypt:

encrypted data key -> (decrypt) plain text data key -> (decrypt) data rồi thì xóa đi

chi tiết:

Dùng operation sau (GenerateDataKey) để generate từ 'customer master key' CMK ra 'data encryption key' (<-----đây là respone)

lấy cái 'plaintext data key' (ở trong field 'Plaintext' của respone) để encrypt data locally, rồi xóa luôn cái 'plaintext data key' đó

lưu lại cái 'encrypted data key' (ở trong field 'CiphertextBlob' của respone) ở bên cạnh data (locally/client side) đã encrypt để sau còn decrypt

Dùng operation sau (Decrypt) để decrypt cái 'encrypted data key' mà mình đã lưu, decrypt xong dc 'plaintext data key'

Dùng 'plaintext data key' để decrypt data locally, rồi xóa luôn cái 'plaintext data key' đó

> Q. muốn migrate source code từ SVN lên Code Commit? làm nào?

trước tiên phải từ SVN migrate lên Git trước rồi tiếp lên Code Commit

> Q. để sử dụng hiệu quả indexing để tăng performance cho dynamoDB làm nào?

số lượng index nên keep minimum, những cái index hiếm khi dùng chỉ làm tăng storage thôi

tránh việc đánh index cho các table phải Write data nhiều.

> Q. trong dynamoDB thì Projection expression, Condition Expressions, Update Expressions là gì?

Projection expression dùng để query table

Condition Expressions để chỉ định điều kiện modify item

Update Expressions để update item

> Q. DAX và dynamoDB xử lý với các request strongly read và eventually read như nào?

nếu 1 eventually read request đến, check xem DAX có cache ko, nếu ko thì pass tới dynamoDB, có kq thì cache lại trong DAX rồi mới pass cho user

nếu 1 strongly read request đến, pass luôn tới dynamoDB, có kq thì pass cho user luôn

> Q. bạn đang làm việc với dynamoDB để save các string vào đó. nhưng nếu > 400KB thì sẽ bị lỗi, làm nào?

lưu string lớn vào s3, dynamoDB chỉ lưu object identifier point to s3 thôi

con số 400 là fix cứng rồi ko thể thay đổi

có thể nén string để giảm size nhưng chỉ là giải pháp tam thời

> Q. bạn đang dùng lambda để access DB. Yêu cầu là all DB connection string cần encrpyt at rest? làm nào?

dùng environment variable để lưu db connection string

encrypt environment variable đó

> Q. Trong dynamoDB, phân biệt 1-Read Side Cache, 2-Read through Cache, 3-Write Through Cache, 4-Write Around Cache, 5-Write back/behind Cache?

Read Side Cache: 

app request read to cache (redis) nếu ko có trong cache thì mới read từ dynamoDB, rồi return to app, rồi write vào cache

useful for read-heavy workload, nhưng việc ghi vào cache là data ko consistence, ko durable

Read through Cache: 

app request read to cache DAX, nếu ko có trong cache thì read trong DynamoDB, result dc cache vào DAX, return to app

useful for read-heavy workload

Write Through Cache: 

app request write to DAX, DAX write vào dynamoDB, nếu thành công mới write vào DAX, rồi return to app

useful for read heavy workload, data consistence nhưng ko giúp gì nếu write-heavy workload

Write Around Cache: 

app request write trực tiếp dynamoDB, rồi mới write vào DAX, rồi return to app

useful for write lượng data lớn considerable

Write back/behind Cache: 

app request write to DAX, DAX return status luôn cho app, in background data write to DynamoDB, rồi write vào cache DAX

useful cho write-heavy workload nhưng có thể mất data

> Q. khi tạo table trong dynamoDB, nếu muốn encrypt data bạn có thể chọn 2 kiểu customer master key là j?

AWS owned CMK, key của dynamodb, ko mất phí thêm

AWS managed CMK, key của KMS, mất phí KMS

> Q. bạn dev 1 app dùng elastic beanstalk. làm cách nào để trace issue, debug dễ nhất khi có issue?

dùng AWS X-Ray

> Q. Bạn đang dev 1 app mà nó cần chức năng sign-up sign-in, bạn ko muốn code fucntion sign up in đó, muốn đảm bảo code sẽ dc excute tự động sau khi user sign in. làm nào?

Dùng cognito, tạo lambda fucntion và trigger function đó mỗi khi user-sign in

> Q. bạn dev 1 app trên on premise network của bạn. app cần tương tác với aws services. làm nào?

tạo iam user, generate ra Access key, sử dụng access key đó để tương tác với aws service

> Q. Bạn cần migrate 1 môi trường development có sẵn gồm các Docker container lên Aws. làm nào đỡ tốn effort?

tạo app và environment cho docker container ở trong Beanstalk vì nó hỗ trợ nhiều platform và language

> Q. Bạn cần quản lý blue/green deployment cho app. dùng cách nào giờ?

trong Beanstalk dùng swap URL

hoặc dùng Route53 với weighted routing policy, để kiểm soát traffic cho subdomain và domain

> Q. Bạn cần cho developers quyền làm việc với beanstalk enviroment nhưng họ ko dc vào console? làm nào?

cho họ làm việc qua EBeanstalk CLI

> Q. bạn deploy 1 lambda function dc invoke qua APi gateway. bạn muốn biết nếu có lỗi khi lambda được invoke thì làm nào?

dùng Cloudwatch Metrics for AWS Lambda

---P4---

> Q. Bạn có vài function lambda, cần gọi đúng version của function đó, làm nào?

tạo alias

> Q. Bạn đang cần test cac services bằng cách query bằng REST API, cần cái gì?

Access key

> Q. app đc xây dựng bới nhiều component phân tán. nhưng các thông tin quan trọng trao đổi giữa các component bị mất khi 1 cái component bị down. làm sao?

dùng SQS để quản lý message giữa các component

> Q. 1 cty có các aws ec2 và on-premise, muốn dùng aws codeDeploy thì cần những gì?

CodeDeploy agent phải dc install trên cả 2 server,

cả 2 server đều dc tagged,

on-premise instance ko cần IAM instance profile

> Q. đang dùng SQS, muốn sau khi message vào queue nó sẽ invisble trong vòng 5p làm nào?

setting delay queues (0 đến 15p)

sử dụng message timer cho individual message

> Q. parameter trong CF cho phép những kiểu dữ liệu nào?

String, number, list<nubmer>, commadelimited list, SSM param, aws type

> Q. bạn tạo nhiều s3 bucket, khi muốn xóa s3 bucket bằng DeletionPolicy trong Cloudformation thì cần chú ý gì?

Các object trong s3 bucket cần phải bị xóa hết trước

> Q. có thể kết hợp DynamoDB với lambda để mỗi khi có thay đổi trên dynamnoDB thì trigger lambda ko?ư

có. Enable dynamoDB stream để invoke lambda 

> Q. bạn làm việc với dynamoDB, bạn muốn biết consumed capacity cho mỗi query là bao nhiêu thì làm nào?

set ReturnConsumedCapacity in query to TOTAL

default nó set là NONE

> Q. bạn có 1 s3 bucket đã dc versioning và encrypted.nhận hàng ngàn PUT request mỗi ngày. sau 6 tháng thì có lỗi HTTP 503, làm nào?

dùng S3 inventory tool, khả năng là có những object lên hàng triệu version, dùng inventory để xác định object nào 

> Q. bạn làm việc với aws Step function, cần chú ý các recommend practice gì?

set timeout khi define các state, thường thì step functin chỉ dựa vào phản hồi của worker, nên nếu có lỗi mà ko set timeout sẽ bị stuck

với lượng payload lớn quá 32KB truyền giữa các state thì sẽ bị terminate, nên lưu trên s3 rồi truyền cái resource name thay vì raw data

> Q. Bạn tạo 1 lambda fucntion dùng Cloudformation. sao để route 5% các traffic to version mới 

set AdditionalVersionWeights = 0.05

> Q. Bạn dùng aws CodeCommit, tạo các repository. bạn cần share các repo đó cho developer team, làm nào?

vào IAM console, chọn user, chọn 'HTTPS Git credentials for AWS CodeCommit' để generate user/password 

cho phép dev connect qua htttps rồi gitclone từ codeCommit về

> Q. Move từ jenkins lên codePipeline thì cần dùng gì detect các change của pipeline?

Cloudwatch Events

> Q. dùng dynamoDB mà bị lỗi ProvisionedThroughputExceededException trong log thì cần làm j?

bởi vì dynamoDB tự động retry các request, nếu request quá lớn thì sẽ bị lỗi ProvisionedThroughputExceededException

consider việc dùng exponential backoff trong code

> Q. bạn dùng SQS để send message giữa các component, bạn cần gửi cả metadata cùng message thì làm nào?

dùng message attribute để gửi metadata cùng lúc với message body.

> Q. bạn cần dùng cloudformation để tạo ra stack ở 1 account aws khác, làm nào?

dùng chức năng Create StackSets

> Q. Aws Opswork support officially những tool nào?

Chef, Puppet

> Q. Bạn đang muốn deploy app lên ECS. muốn chắc chắn có thể dùng X-ray để trace deploy. làm nào?

tạo docker image với X-ray,
rồi deploy container to ECS

> Q. bạn dùng CodeBuild, code dc lưu ở S3, khi run build bị lỗi addressed using the specified endpoint, vì sao?

Bucket ko ở cùng region với CodeBuild project

> Q. bạn deploy 1 app lên Beanstalk, app cần RDS là 1 phần trong Beanstalk, nhưng muốn DB dc preserve ngay cả khi Environment down. làm nào?

chắc chắn rằng đã setting cái field Retention khi tạo DB = create snapshot

> Q. Mỗi khi upload hoặc deploy source lên Beanstalk, nó có giữ lại version app ko?

Có

> Q. dùng DynamoDB, Read capacity là 5 units, muốn đọc 5 item 1 giây, mỗi item 2KB, default consistency=eventually consistency
total size KB dc đọc 1s?

2KB -> làm tròn 4KB -> cần 1 read request

eventually consistency -> 1/2 = 0.5 RCU

số KB/s = 5 x 2 = 10 KB/s

eventually -> số KB/s = 10 x 2 = 20 KB/s

vì RCU = 0.5 -> 20 x 0.5 = 10 KB


> Q. cty bạn đang quản lý deployment env bằng CodeDeploy. Họ muốn tự động luôn cả việc deploy cái deployment env. làm nào?

dùng Cloudformation

> Q. Bạn quản lý nhiều DB với nhiêu passwword? làm sao để lưu pass cho DB secure?

dùng aws secret manager

bạn tạo db credential, lưu nó vào Aws secret manager

khi app cần access db, nó sẽ request Aws secret manager

Aws secret manager query, decrypt và trả về cho app qua HTTPS, TLS

app dùng credential đó access db

> Q. Bạn đang dev 1 mobile app. User đã authen bằng facebook. App cần get temporary access credential để làm việc với aws resource
dùng cái j?

AssumeRoleWithWebIdentity 

> Q. bạn có 1 s3 bucket, bucket đó cần phải dc access từ những aws account khác. làm thể nào để secure các account khác có thể access vào resource của bạn?

tạo cho họ 1 role có quyền assume role và cung cấp cho họ ARN role đó

họ cung cấp cho bạn externalID unique để bạn update trust policy trong role của họ.

> Q. Bạn đang có Beanstalk dùng java7 tomcat7. Bạn muốn dùng java 8 và tomcat 8.5
làm nào?

tạo môi trường mới

upload code, deploy, fix bug

Swap Environment Url (CNAME)

ok thì xóa môi trường cũ

> Q. bạn đang dùng APi gateway, sao để giảm độ trễ của các request to API gateway?

dùng API caching

> Q. dùng DynamoDB mà bị lỗi HTTP 400, là sao?

vượt quá throughput của table, hoặc thiếu required parameters

> Q. app của bạn dùng SQS, message sẽ xuất hiện trong queue trong khoảng 20-60s, nên dùng loại SQS nào?

long polling, SQS sẽ chờ cho đến khi message xuất hiện

> Q. AWS Athena để làm gì?

để perform SQL query in data S3

> Q. 1 app đang connect đến RDS. bạn có nhiệm vụ debug performance issue liên quan đến query, làm nào?

lấy cái log Slow query log của RDS

Error log: cung cấp log lỗi, 

General query log: cung cấp log query normal và client connect time,

Slow query log: cung cấp log mà query chạy chậm hơn bình thường

> Q. có thể biến 1 ec2 thành ECS ko?

Cài install ecs agent trên Amazon ec2

> Q. bạn có 1 app host bởi s3, sao để tính số get request to s3?

dùng cloudwatch

---P5---

> Q. bạn cần phương thức deploy lambda function dùng SAM, cần làm gì?

1, sam init app: tạo ra 1 file yaml define Lambda function và API gateway

2, test app trên local

3, sam package app: upload app lên s3, output ra 1 file YAML chứa s3 uri

4, sam deploy app bằng file YAML mới đó

> Q. trong Step Function bạn tạo lambda fucntion bị lỗi ServiceException, best practice là gì?

Retry. Dùng Retry Code với chỉ định ErrorEquals

ko thể dùng Catch code vì nó dc áp dụng khi retry 1 số lần

> Q. bạn đang dùng CodeBuild cho 1 app, app đó cần access resource trong private subnet, làm nào?

Default là Codebuild ko access dc vào resource trong VPC. Cần phải sửa configure của CodeBuild

thêm thông tin về VPC, subnet, SG mà CodeBuild cần access

> Q. S3 bucket cho phép bao nhiêu PUT GET request mỗi giây và nếu bạn tạo 3 prefix trong s3 nữa thì tăng lên bao nhiêu request?

3500 PUT POST DELETE/s, 5500 GET /s

nếu có 3 prefix thì x3

> Q. Bạn đang dùng X-ray, nó cung cấp những tính năng gì, cần trace all incoming http request to app của bạn dùng cái j?

interceptor để trace all incoming http request

client handler để trace sdk mà mình dùng để call đến aws resource

http client để trace internal và external web service

> Q. Data pipeline và các khái niệm, cái gì define source data và destination data?

Data Node: define location của input và output data dc store ở đâu

Activities: define work của pipeline

Resources: là những cái thực hiện việc mà activity chỉ định

Action: dc trigger khi activity thỏa mãn điều kiện

> Q. Load data s3 sang Readshift dùng command gì?

Copy

> Q. bạn dùng Cognito, yêu cầu là nếu user có compromised credential (ví dụ password dễ đoán) thì phải bắt user tạo mới passw, làm nào?

tick vào phần block-use trong Advance security section đối với những compromised credential 

tạo user pool trong Cognito

> Q. Bạn có nhiều data trên aws, cần 1 giải pháp nhanh để dựng visualization screens cho đống data đó, dùng j?

Quicksight

> Q. AWS Glue là gì?

để quản lý service ETL (extract, transform, load)

> Q. bạn có S3 bucket và lưu object size trên DynamoDB, yêu cầu là mỗi khi s3 có object dc upload thì sẽ trigger 1 record update trong DynamoDB, làm nào?

S3 event trigger trực tiếp Lambda , ko cần SQS

> Q. kinesis để tính số lượng shards cần công thức gì?

Incoming write bandwith, Outgoing read bandwidth

number_of_shards = max(incoming_write_bandwidth_in_KiB/1024, outgoing_read_bandwidth_in_KiB/2048)

> Q. bạn dev app dùng ECS, docker, thì sẽ lưu docker base image ở đâu?

ECR, Dockerhub

> Q. bạn tạo policy cho user access vào resource, sau đó bạn update policy thì user report ko vào dc resource nữa, có thể revert lại version policy cũ ko?

có, set version policy cũ thành default


> Q. bạn dùng CodeCommit, yêu cầu là mỗi khi có change lên repo thì phải notification cho bạn, làm nào? co dùng AWS Config ko?

Lambda hoặc SNS

ko dùng AWS Config dc vì nó là để monitor những thay đổi về mặt configuration chứ ko phải thay đổi trên repository

> Q. bạn định dùng AWS Batch service để chạy các job compute, tool nào để monitor progress của job?

Cloudwatch event

> Q. best practice khi define secondary index cho dynamodb là gì?

keep minimum index

tránh đánh index cho table phải ghi nhiều

> Q. bạn đang dùng RDS cho app, yêu cầu là các connection từ app tới DB cần encrypt thì dùng gì? SSL và KMS chọn nào?

SSL, chuyên dùng để encrypt connect to DB, data in transit

KMS chỉ để dùng encrpyt data at rest hoặc before transit thôi

> Q. bạn đang dùng lambda, và lambda của bạn cần nhiều thư viện thirdparty như xử lý ảnh, hay đồ họa, làm nào?

tạo lambda deployment package chứa cả lambda và thư viện thirdparty, uplên s3, rồi dùng cli

> Q. bạn đang dùng cloudfront với origin là s3 cho web distribution. bạn muốn control thời gian object dc lưu trong cache làm nào?

config cái origin phải có Expires header field mỗi object, hoặc add Cache control

config Cloudfront sử dụng chỉ định time trong TTL

> Q. bạn dùng 1 tool POSTMAN để send API request tới resource trong aws. bạn cần sign request để aws biết bạn là ai? thì dùng gi?
user+pass, private key file, KMS?

Dùng access key + secret key.

Chứ KMS để encrpyt data, user/pass dùng vào console, private key dùng để login ec2

> Q. đang dùng SNS, muốn chỉ nhận các loại message nhất định, ko muốn nhận hết message dc publish vào topic dc ko?

filter policy của topic

> Q. bạn đang có sẵn 1 redshift cluster, có nhiều data quan trọng, cần encrypt at rest làm nào?
có dùng SSL cert dc ko?

Cứ thế enable KMS encryptor thôi (cái này là feature mới, trước đây ko làm thế dc)

trước đây phải tạo 1 cluster mới và enable KMS encrypt lên, unload khỏi cluster cũ, reload lại tới cluster mới

SSL cert chỉ để encrpyt data in transit

> Q. bạn có app trên ec2, giờ muốn nếu primary app tạch thì sẽ route traffic đến 1 static web thứ 2, làm nào?
R53 hay LB?

dùng route53,
LB chỉ dùng để distribute traffic (phân phối), ko điều hướng traffic như R53 dc

> Q. Bạn đang dùng AWS Cognito Sync, nó cung cấp những feature gì?

sync app user data giữa nhiều device và web app,

web app có thể read write data lên cache ko cần quan tâm kết nối của mobile device, sau khi device kết nối thì sẽ sync data,

và có thể push notify các thiết bị khác khi có update 


> Q. app của bạn host trên ec2, dùng cloudfront để distribute content, sao để encrpyt traffic giữa orgin với cloudfront, và giữa cloudfront với viewer?

giữa origin với cloudfront: trên console, setting Origin Protocol policy, 

giữa cloudfront với viewer: trên console, setting Viewer Protocol policy


> Q. App bạn tương tác với s3, mà giờ s3 tự nhiên ko tồn tại, sao để biết nó bị xóa như nào?
có dùng Inspector dc ko?

dùng cloudtrail log để xem bucket delete api request,

Inspector chỉ để check server có bị vulnerable ko thôi

> Q. Best practice của lambda, làm sao tận dụng Execution Context là gì?

Execution Context là môi trường runtime tạm thời lambda tạo cho function chạy

lần đầu hoặc update function thì nó sẽ mất time để tạo môi trường Execution Context này

các lần sau nó dùng lại nên nhanh hơn

để lâu 20-45p thì nó tự xóa môi trường này

Execution Context lưu khoảng 500Mb cache các data required

khi chạy nên check xem nếu data required exist thì ko cần reuquest để chạy function cho nhanh

> Q. bạn đang xây dựng web stateful, thì cần cái gì lưu session data/ cái gì distribute traffic? ALB hay APIGateway?

DynamoDB lưu session data, ALB để distribute traffic

API Gateway ko phải để distribute traffic mà là quản lý API

> Q. app của bạn có ASG, cần dựa trên số lượng user concurrent để scale thì làm nào?

tạo 1 cloudwatch metric cho số lượng user concurrent để trigger ASG policy

> Q. Bạn đang dùng S3, app rất phổ biến nên có những object s3 đc access thường xuyên, sao để enhance các GET request/ PUT request?

Enhance của GET request là dùng cloudfront (vừa giảm độ trễ vừa tăng performance), hoặc tăng số lượng prefix trong s3 (nhưng cái này ko giảm độ trễ dc)
ví du: 
bucket/folder1/sub1/file 

bucket/folder1/sub2/file 
bucket/1/file 

bucket/2/file

Prefixes of the object 'file' would be: '/folder1/sub1/' , '/folder1/sub2/', '/1/', '/2/'.

Nếu có 4 prefix như hiện tại thì có thể tăng GET reuqest lên 4 lần

Enhance của PUT request là thêm random prefix (những chuỗi ngẫu nhiên) vào key name 

> Q. Bạn dùng SQS, app của bạn mất 60s để process message, SQS đang setting default thì cần setting gì nữa?

Change visible timeout tăng lên 60s, vì default visible timeout là 30s thôi,

visible timeout là thời gian message biến mất khỏi queue, sau đó xuất hiện lại,

app cần phải vào mà xóa message đi sau khi process xong

> Q. khi deploy code lên Beanstalk thì cần chú ý gì?

up file zip hoặc war,

ko quá 512MB,

ko ở trong folder,

nếu thực các task theo lịch thì cần có file cron.yaml

# Các câu hỏi được note lại trong quá trình thi (chưa add câu trả lời)

- Code pipepilne, CodeBuild, CodeCommit cái nào support parrallel branch, versionning, batch?
- Global secondary index thì dùng cho eventually read hay srongly read request?
- Xray mà muốn trả về thêm information thì cần phải thêm gì? annotation hay meta data?
- Deploy Serverless application model bằng Cloudformation thì cần define gì trong template?
- Api đc protect bởi Multifactor Authentication thì dev làm sao để call api đó? dùng cái gì trong những cái sau GetSessionToken hay GetFederationToken hay GetCallerIdentity?
- Api gateway bị timeout mặc dù lambda đã finish vì sao? 
- Dùng cli command bị timeout vì nhiều resource thì cần làm gì? Quoting, shorthand syntax..
- Deploy lambda vs 1 custom environment chứa library riêng làm thế nào? 
- Dùng Codedeploy, khi muốn update version source mới làm nào? Upldate file buildspec.js hay appspec.js?
- Để application có tính elastic và horizontal scale thì dùng elb + asg hay cloudfront vs asg?
- Cloudwatch có những metric nào dùng cho Apigateway vs lambda?  CacheMissHit, IntergrationLatency?
- Log app đang ở trên cloudwatch log, nhưng tạo metric để filter log thì ko có kết quả? Vì sao?
