---
title: "Vulerability scan with Qualys"
date: 2023-11-29T13:09:35+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Qualys]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "What is Qualys and how to use it?"
---

Gần đây mình có cơ hội được làm việc với Qualys. Qua 1 thời gian tìm hiểu thì mình đúc rút ra được 1 số kinh nghiệm nên cần phải hệ thống lại ngay. 

# 1. Qualys là gì? Các tính năng của Qualys

Qualys là 1 Cloud Platform để scan vulnerability. Ko phải như Sonarqube để làm code quality review.  
Bạn mua license của Qualys để:  
- Add các endpoint của bạn vào, qualys sẽ scan các endpoint đó (1 lần hoặc thường xuyên tùy bạn).  
- Bạn cài Qualys agent lên machine, agent đó sẽ run thường xuyên để scan vulnerability.  
- Bạn cài Qualys sensor container bên cạnh các contaner khác, Qualys container sensor sẽ scan các container, docker image để phát hiện vulnerability.  

Các tính năng chính mà Qualys cung cấp:  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-get-start-screen.jpg)

- VMDR = vulnerability management, detection and response. (gọi tắt là VM)
  => Dùng để scan vulnerability tầng OS.  

- WAS = Web Application Scanning.
  => Dùng để scan vulnerability tầng WebApp.  

- PC SCA = Policy Compliance & Security Configuration Assesment.  
  => Dùng để scan configuration của bạn đối với nhiều chuẩn phổ biến: PCI, HIPPA, and SOX.  

- CERT = CertView.
  => Chưa dùng.  

- PCI DSS: The Payment Card Industry (PCI) Data Security Standard (DSS) details security requirements for members, merchants, and service providers that store, process or transmit cardholder data.  
  => Chưa dùng. Chủ yếu dùng với hệ thống có lưu trữ các thông tin về thẻ tín dụng của User, thông tin bla bla...

- Container Security.  
  => Dùng để scan Docker container, Docker image vulnerability.  

Khi bạn xổ menu cột trái thì sẽ thấy còn nhiều tính năng mà Qualys cung cấp khác:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vertical-menu1.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vertical-menu2.jpg)

Các tính năng mình đã sử dụng qua là: VMDR, Policy Compliance, Web Application Scanning, Cloud Agent, Container Security.

Khác nhau giữa PC và SCA:  
- SCA là module addon của VMDR, so sánh config của bạn với CIS best practices.  
- Còn PC là 1 module standalone (độc lập), so sánh config của bạn đối với nhiều chuẩn như: PCI, HIPPA, and SOX.  
https://success.qualys.com/discussions/s/question/0D52L00004TnxAYSAZ/difference-between-sca-and-pc

Khác nhau giữa WAS và VMDR Scan:  
- VMDR scanning will look at the operating system and any software installed on the server and report back a list of vulnerabilities.  
- Web Application Scanning (WAS) is going to look specifically at the web applications and looking for any issues that allow SQL injection or Cross Site Scripting attacks to be injected into the application.  

# 2. Các plan mà Qualys cung cấp

Nếu bạn đăng ký free trial thì bạn sẽ có 30 days dùng thử free hầu hết các tính năng quan trọng.

Còn nếu bạn dùng bản Community Edition thì bạn sẽ có 1 năm dùng free 1 số tính năng. Có 1 số hạn chế (hạn chế lớn nhất là không thể call API được mà phải dùng Portal, không call API được thì sẽ ko thể integrate nó vào Pipeline tự động được.)

Bản free Community Edition sẽ:  
- Chỉ có 2 module được enable: VM và WAS.  
- Monitor 16 assets with Cloud Agent => (Nghĩa là sẽ tạo đc 16 con Cloud Agent).  
- Scan 16 internal IP, 3 external IP with Vulnerability Management.  
- Scan 1 URL with WAS.  
- Deploy 1 Virtual Scanner Appliance.   

# 3. Thao tác trên Qualys Portal

## 3.1. Add Qualys Azure Virtual Scanner

Qualys cung cấp scanner dưới dạng vật lý và ảo. Nếu bạn có các máy tính/server vật lý để quản lý, bạn sẽ cần mua 1 thiết bị (appliance) của Qualys dạng vật lý, bạn sẽ cắm nó vào máy tính để nó scan.

Nhưng nếu bạn có các VM/máy ảo, thì bạn sẽ cần setup Qualys Virtual Scanner để nó scan. (Giờ mọi người có vẻ sử dụng phương án này nhiều hơn cho cả vật lý lẫn VM)

Trên Azure, bạn sẽ cần tạo 1 VM riêng để chạy scanner. 

Vào Portal của nó, Add new virtual scanner

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-create-v-scanner.jpg)

Nhận được personalize code:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-create-v-scanner-perscode.jpg)

Lên Azure Marketplace tạo Qualys scanner VM:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-create-v-scanner-azure-vm.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-create-v-scanner-azure.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-create-v-scanner-azure-disk.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-create-v-scanner-azure-vnet.jpg)

Deploy xong:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-create-v-scanner-azure-deploymentok.jpg)

Quay lại màn hình Add new virtual scanner lúc nãy, Verify:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-create-v-scanner-azure-verify.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-create-v-scanner-azure-verify-ok.jpg)

Đã tạo Appliance:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-create-v-scanner-ok.jpg)

## 3.2. Run VMDR scan (Vulnerability scan)

Scan thử, có thể chọn Target VM là internal IP, nhưng mình chọn là external IP 40.68.169.170 là 1 VM đang có sẵn, ko mở NSG ra bên ngoài, nên chắc Qualys Scanner sẽ ko connect đến được đâu..

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-scan01.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-scan01-launch.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-scan01-wait.jpg)

Đúng là ko connect được nó sẽ mail về báo No Host Alive:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-scan01-nohostalive.jpg)

Để Virtual Scanner reach được Target VM thì bản thân Target VM phải sửa NSG để allow traffic từ Virtual Scanner.

Đoạn này mình vào Azure -> Target VM -> sửa NSG để allow traffic từ Virtual Scanner IP (ko có ảnh) 

Ngoài ra còn cần làm các bước sau:

Phải vào đây tạo Authentication method (Là cách để scanner có thể SSH vào Target VM)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-authentication-method.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-authentication-method-config.jpg)

Nhập SSH key:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-authentication-method-key.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-authentication-method-ip.jpg)

Tạo xong ra đây sẽ thấy có Authentication record:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-authentication-method-record.jpg)

Giờ tạo 1 Option Profile mới, dùng cái Authentication record vừa tạo:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-option-profile-edit.jpg)

Save As để duplicate cái có sẵn:  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-option-profile-save-as.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-option-profile-save-as-auth.jpg)

Edit cái Profile vừa tạo:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-option-profile-edit2.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-option-profile-edit-scan.jpg)

Phải tick vào đây:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-option-profile-edit-auth.jpg)

Scan lại lần 2 sử dụng cái Option Profile mới tạo:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-scan02.jpg)

Đang Running, chỉ cần chờ thôi:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-scan01-running.jpg)

Scan xong có mail báo về:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-scan02-result.jpg)

Lên Portal xem Summary và Report:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-scan02-done.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-scan02-sumary.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-scan02-result02.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-scan02-detail01.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-scan02-detail02.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-scan02-detail03.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-scan02-detail04.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-scan02-detail05.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-scan02-detail06.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-vmdr-scan02-severity-legend.jpg)

## 3.3. Run Qualys Cloud Agent

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cloud-agent-menu.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cloud-agent-menu-start.jpg)

Tạo activation Key:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cloud-agent-key.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cloud-agent-key-created.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cloud-agent-key-docs-ubuntu.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cloud-agent-key-download-deb.jpg)

Download .deb xong scp để cho nó vào VM cần scan.

Run command trên VM cần scan

Quay lại Portal sẽ thấy Agent có thông tin ở đây:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cloud-agent-key-activated.jpg)

Vào xem detail:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cloud-agent-key-activated-detail.jpg)

Có nhiều thông tin được collect bởi Agent:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cloud-agent-key-activated-detail-ports.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cloud-agent-key-activated-detail-sw.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cloud-agent-key-activated-detail-vuls.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cloud-agent-key-activated-detail-info.jpg)

Bản Community Edition khả năng sẽ ko xem được Container Security vì chưa dc enable:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cloud-agent-key-activated-detail-docker.jpg)

Xem được real-time các Vulnerabilities luôn:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cloud-agent-key-activated-detail-vuls-list.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cloud-agent-key-vuls-view-detail.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cloud-agent-key-vuls-view-detail-spring.jpg)

Trỏ đến từng file jar luôn:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cloud-agent-key-vuls-view-detail-spring2.jpg)

## 3.4. Run WAS (Web Application Scan)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-menu.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-no-web.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-new-webapp.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-new-webapp-details.jpg)

Ở dưới mình chọn External scan để scan từ ngoài vào. Nhưng vẫn có thể scan internal bằng Virtual appliance scanner, chỉ cần chọn Individual là được:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-new-webapp-scan-settings.jpg)

Có thể cho cả selenium scripts vào:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-new-webapp-crawl-settings.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-new-webapp-authen.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-new-webapp-exclusions.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-new-webapp-advanced.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-new-webapp-monitor.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-new-webapp-review.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-new-webapp-new-scan.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-scan-step1.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-scan-step2.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-scan-step3.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-view-scan.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-view-scan-running.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-scan-mail.jpg)

Vì No Web Service nên cần check lại

Lên Portal xem report, có vẻ do ko mở ra Internet nên Cái WAS này nó ko connect được?

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-scan-no-web-sv.jpg)

Vào đây tim IP của WAS xem có thể sửa NSG để allow chỉ IP của WAS ko:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-external-ip.jpg)

Scan lại bằng thử Discovery Scan thì OK, có thể scan được, ko có lỗi No Web Service nữa.

Hình dưới là Discovery scan cung cấp:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-discovery-scan-ok.jpg)

Thử Scan Again cái Vulnerability Scan:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-vul-scan-again.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-vul-scan-mail.jpg)

Status: Finished OK là được

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-vul-scan-mail-2.jpg)

Trong email báo có 1 Vulnerability Severity 2 (Medium) nhưng tìm trong Portal report thì ko có

Phải vào tab Detection mới thấy:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-was-vul-scan-detection-list.jpg)

Chú ý nữa là nếu bạn xóa cái Web Application trong Qualys portal đi thì scan của nó cũng sẽ biến mất làm bạn ko thể xem detail result cũ được. Cần chú ý, nếu có thể thì run report luôn. Tab Report sẽ ko bị xóa khi Web Application bị xóa.

## 3.5. Run Qualys Container security

Vào dashboard của service, để sử dụng cần download sensor:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cs-download-sensor.jpg)

Mình chọn mode mình sẽ cài sensor. Trước tiên cần cài đặt Qualys Container Sensor (là 1 container) để nó scan. Có 3 mode của Sensor:  
- General Host Sensor: Sẽ scan any image/container có trên Host  
- Registry Sensor: scan các image từ 1 reigstry nào đó (public, private). Chú ý nó ko tự động pull image về nhé.  
- Build sensor: Scan image được build trong pipeline (Gitlab, github, jenkins...)  

Việc scan sẽ được sensor làm tự động khi nó phát hiện có image mới với tag: `qualys_scan_target`, container mới.

Ở đây mình chọn Mode: Build sensor.  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cs-sensor-mode.jpg)

Copy y nguyên command rồi paste vào môi trường sẽ cài sensor:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cs-command.jpg)

Vào tab Configuration sẽ thấy sensor đã deploy:  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cs-sensor-ok.jpg)

Deploy 1 image để test, file `Dockerfile`:  

```
FROM alpine:3.4

RUN apk update && \
    apk add curl && \
    apk add vim && \
    apk add git
```

Run command để build image với 2 tags, trong đó có 1 tag là `qualys_scan_target`:  

```sh
docker build -t qualys_scan_target:test-app-0.0.3 -t test-app:0.0.2 .
```

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cs-image-built.jpg)

Lên giao diện sẽ thấy image được scan tự động:  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cs-images-scan.jpg)

List lại image sẽ ko thấy tag `qualys_scan_target` nữa vì đã scan nên nó sẽ remove cái tag đó:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cs-images-scanned.jpg)

Ấn vào để xem chi tiết các vulnerability:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/qualys-cs-vuls.jpg)


# 4. Các link về documents của Qualys

Public Github repository: https://github.com/Qualys-Public/CloudSecurity/blob/master/README.md  

Public Github repository cho community: https://github.com/Qualys/community  

Forum Qualys:  
https://success.qualys.com/discussions/s/#start-a-discussion   
https://old.reddit.com/r/qualys/   
https://www.reddit.com/r/qualys/   

Qualys Docs API: https://cdn2.qualys.com/docs/qualys-api-quick-reference.pdf  

Doc về install Azure Virtual Scanner: https://success.qualys.com/discussions/s/article/000005844

Nhưng mình làm theo youtube trực quan hơn: https://www.youtube.com/watch?v=CySe4vQubQY&ab_channel=NetSec

File này có 1 đoạn code call Qualys API để tạo virtual scanner + lấy activation code, có thể hữu dụng về sau: https://github.com/mkhanal1/AWS_Scanner_CloudFormation/blob/master/ScannerCF.yml

File này là code Ansible để install Qualys Cloud Agent: https://github.com/mkhanal1/Cloud_Agent_Ansible/blob/master/InstallQCA.yml

File này là install Qualys Cloud Agent bằng ARM Extension script: https://github.com/Qualys-Public/CloudAgent-Azure-ARMTemplate/blob/master/LinuxVm.json

Bài này nói về cách integrate Qualys để package AWS Image AMI:
https://aws.amazon.com/blogs/apn/creating-a-golden-ami-pipeline-integrated-with-qualys-for-vulnerability-assessments/

Clip hướng dẫn khá đầy đủ về Community Edition Qualys: Tạo Virtual Scanner Azure VM:
https://www.youtube.com/watch?v=CySe4vQubQY&ab_channel=NetSec

Clip trên có hướng dẫn các loại scan: 
Vulerability Management scan internal/external thường mất 1-8 tiếng.
Hướng dẫn scan với chọn các Profile khác nhau.
HƯớng dẫn install cloud agent (trong Dashboard Cloud Agent).
Hướng dẫn dùng Web App Scan (có thể mất dưới < 30m).

Tip & trick:  
https://blog.51sec.org/2018/09/qualys-guard-tips-and-tricks.html

Về Qualys Container security:  
https://cdn2.qualys.com/docs/qualys-container-security-user-guide.pdf

Tài liệu đầy đủ về cách deploy Sensor (docker-compose, helm chart...):  
https://cdn2.qualys.com/docs/qualys-container-sensor-deployment-guide.pdf

Việc của mình là call API để lấy kết quả scan:  
https://docs.qualys.com/en/cs/api/#t=get_started%2Fget_started.htm


# 5. Call Qualys API

Call Qualys API chỉ khả dụng đối với account có license (trial license cũng được). Chứ bản Community ko được enable chức năng call API.  

Docs dành cho VMDR, PC module:  
https://cdn2.qualys.com/docs/qualys-api-vmpc-user-guide.pdf

Prepare environment variables:  

```sh
QUALYS_USER= # user name
QUALYS_PASSWORD= # account password
QUALYS_WAS_WEBAPP_ID= # ID of WAS web application
QUALYS_WAS_PROFILE_ID= # ID of WAS profile 
IP_ADDRESS= # IP address of your virtual machine
QUALYS_VUL_OPT_ID= # VMDR Option Profile ID
QUALYS_PC_OPT_ID= # Policy Compliance Option Profile ID
QUALYS_SCANNER_NAME= # Virtual scanner name
SCAN_TITLE_PREFIX= # Scan title prefix
QUALYS_BASE_URL=qualysapi.qg4.apps.qualys.com
```

Launch scan:  

```sh
curl -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" -X "POST" \
-d "action=launch&scan_title=$SCAN_TITLE_PREFIX&ip=$IP_ADDRESS&option_id=$OPTION_PROFILE_ID&iscanner_name=$SCANNER_NAME" \
https://$QUALYS_BASE_URL/api/2.0/fo/scan/
```

Response:  

```
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE SIMPLE_RETURN SYSTEM "https://qualysapi.qg4.apps.qualys.com/api/2.0/fo/scan/dtd/launch_output.dtd">
<SIMPLE_RETURN>
  <RESPONSE>
    <DATETIME>2023-11-29T08:38:54Z</DATETIME>
    <TEXT>New vm scan launched</TEXT>
    <ITEM_LIST>
      <ITEM>
        <KEY>ID</KEY>
        <VALUE>1781123</VALUE>
      </ITEM>
      <ITEM>
        <KEY>REFERENCE</KEY>
        <VALUE>scan/1701237133.81259</VALUE>
      </ITEM>
    </ITEM_LIST>
  </RESPONSE>
</SIMPLE_RETURN>
```

Launch scan đồng thời lấy scan_ref:

```sh
SCAN_REF=$(curl -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
-d "action=launch&scan_title=$SCAN_TITLE$DATE&ip=$IP_ADDRESS&option_id=$QUALYS_OPT_ID&iscanner_name=$QUALYS_SCANNER_NAME" \
https://$$QUALYS_BASE_URL/api/2.0/fo/scan/ | \
xmlstarlet fo -D | \
xmlstarlet sel -t -v "SIMPLE_RETURN/RESPONSE/ITEM_LIST/ITEM[2]/VALUE")
```

List all scan:

```sh
curl -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
https://$QUALYS_BASE_URL/api/2.0/fo/scan/?action=list&echo_request=1&show_ags=1&show_op=1
```

List only 1 scan by scan_ref:

```sh
curl -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
https://$QUALYS_BASE_URL/api/2.0/fo/scan/?action=list&echo_request=0&show_ags=0&show_op=0&scan_ref=scan/1701247133.81259 
```

Dùng xmlstarlet để Get only scan status: (credit: https://stackoverflow.com/a/45310101)
```sh
curl -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
https://$QUALYS_BASE_URL/api/2.0/fo/scan/?action=list&echo_request=0&show_ags=0&show_op=0&scan_ref=scan/1701247133.81259 | \
xmlstarlet fo -D | \
xmlstarlet sel -t -v "SCAN_LIST_OUTPUT/RESPONSE/SCAN_LIST/SCAN/STATUS/STATE"
```

Download scan result dưới dạng json:  

```sh
curl -s -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
'https://$QUALYS_BASE_URL/api/2.0/fo/scan/' \
--form 'action="fetch"' \
--form 'scan_ref="scan/1701327348.83629"' \
--form "ips="$IP_ADDRESS"" \
--form 'mode="extended"' \
--form 'output_format="json"' > result.json
```

Lauch a Policy Compliance scan và lấy scan_ref, sau đó lấy status:

```sh
PC_SCAN_REF=$(curl -s -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
-d "action=launch&scan_title=$PC_SCAN_TITLE&ip=$IP_ADDRESS&option_id=$QUALYS_PC_OPT_ID&iscanner_name=$QUALYS_SCANNER_NAME" \
https://$QUALYS_BASE_URL/api/2.0/fo/scan/compliance/ | \
xmlstarlet fo -D | \
xmlstarlet sel -t -v "SIMPLE_RETURN/RESPONSE/ITEM_LIST/ITEM[2]/VALUE")

STATUS=$(curl -s -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
https://$QUALYS_BASE_URL/api/2.0/fo/scan/compliance/?action=list&echo_request=0&show_ags=0&show_op=0&scan_ref=$PC_SCAN_REF | \
xmlstarlet fo -D | \
xmlstarlet sel -t -v "SCAN_LIST_OUTPUT/RESPONSE/SCAN_LIST/SCAN/STATUS/STATE")
```

Docs API scan WAS: https://cdn2.qualys.com/docs/qualys-was-api-user-guide.pdf

```sh
# List all WAS scan
curl -u "$QUALYS_USER:$QUALYS_PASSWORD" \
https://$QUALYS_BASE_URL/qps/rest/3.0/count/was/wasscan

# Launch new WAS scan
curl --location --request POST "https://$QUALYS_BASE_URL/qps/rest/3.0/launch/was/wasscan" \
 -u "$QUALYS_USER:$QUALYS_PASSWORD" \
 --header 'Content-Type: text/xml' \
 --header 'X-Requested-With: Curl' \
 --data-raw "
 <ServiceRequest>
    <data>
        <WasScan>
            <name>New WAS Discovery Scan launched from API</name>
            <type>DISCOVERY</type>
            <target>
            <webApp>
                <id>$QUALYS_WAS_WEBAPP_ID</id>
            </webApp>
            <webAppAuthRecord>
                <isDefault>true</isDefault>
            </webAppAuthRecord>
            <scannerAppliance>
                <type>EXTERNAL</type>
            </scannerAppliance>
            </target>
            <profile>
                <id>$QUALYS_WAS_PROFILE_ID</id>
            </profile>
        </WasScan>
    </data>
</ServiceRequest>"
```

Download VMDR scan result: (Chỉ có dạng CSV, JSON thôi)

```sh
curl -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
 -d "action=fetch&output_format=json&scan_ref=scan/1701660504.93255" \
 "https://$QUALYS_BASE_URL/api/2.0/fo/scan/" > scan-result.json
```

Không thể download trực tiếp Scan result dưới dạng PDF:  
https://success.qualys.com/discussions/s/question/0D52L00004TnxzrSAB/is-it-possible-to-download-the-reports-from-the-vm-scans

Mà cần launch 1 cái job để generate report, để từ đó download file report dạng pdf về.

List all report:  

```sh
curl -s -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
 -d "action=list" \
 "https://$QUALYS_BASE_URL/api/2.0/fo/report/"
```

Muốn có VMDR report dạng PDF thì cần launch report. Trước tiên cần có template_id.

Lên tab Report xem template_id là gì, mình thử dùng `Technical Report template (Host Based)`: 947025 => Sẽ bị lỗi Internal Error CODE 999.

Tự Tạo `Qualys Support Template (Scan Based)`: 953147 => sẽ OK

Launch report:

```sh
REPORT_TEMPLATE_ID=953147
REPORT_TITLE=TestReportAPI
curl -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
-d "action=launch&template_id=$REPORT_TEMPLATE_ID&report_title=$TestReportAPI&output_format=pdf&report_type=Scan&report_refs=scan/1701660504.93255" \
"https://$QUALYS_BASE_URL/api/2.0/fo/report/"
```

Response:
```
<SIMPLE_RETURN>
  <RESPONSE>
    <DATETIME>2023-12-04T05:38:31Z</DATETIME>
    <TEXT>New report launched</TEXT>
    <ITEM_LIST>
      <ITEM>
        <KEY>ID</KEY>
        <VALUE>1212972</VALUE>
      </ITEM>
    </ITEM_LIST>
  </RESPONSE>
</SIMPLE_RETURN>
```

Get report status:
```sh
curl -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
-d "action=list&id=1212972" \
https://$QUALYS_BASE_URL/api/2.0/fo/report/
```

Download report PDF:
```sh
curl -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
-d "action=fetch&id=1212972" \
"https://$QUALYS_BASE_URL/api/2.0/fo/report/" > TestReportAPI.pdf
```

Upload report to Azure storage account:  

```sh
SAS_TOKEN="sp=XXX"
VUL_SCAN_TITLE=TestReportAPI
STORAGE_ACCOUNT=abc
az storage blob upload \
  --account-name "$STORAGE_ACCOUNT" \
  --sas-token $SAS_TOKEN \
  --container-name system/folder/ \
  --file $VUL_SCAN_TITLE.pdf
```

Chú ý: Vì mình ko muốn cài az-cli azure tool lên server, nên mình sẽ dùng curl command thôi:

```sh
# Upload blob to storage account use curl
STORAGE_ACCOUNT=abc
SAS_TOKEN="sp=XXX"
curl -i -X PUT -H "x-ms-version: 2019-12-12" -H "x-ms-blob-type: BlockBlob" --upload-file $VUL_SCAN_TITLE.pdf "https://$STORAGE_ACCOUNT.blob.core.windows.net/system/folder/test.pdf?$SAS_TOKEN"
```

Về PC Report (Policy Compliance):
Người ta bảo cách tốt nhất là scan without policy, rồi gen report ra theo từng policy
https://success.qualys.com/discussions/s/question/0D52L00004Tnyc2SAB/scan-based-compliance-report


Launch Policy Compliance Report:

```sh
PC_REPORT_TEMPLATE_ID=947037 # Policy Report Template
PC_REPORT_TEMPLATE_ID=947038 # Compliance Scorecard Report
PC_POLICY_ID=516625 # Cái này phải tự tạo "Create from Scratch"
PC_POLICY_ID=516626 # Tự tạo từ host đã scan "Create from Host"
PC_REPORT_TITLE=ABC
IP_ADDRESS=10.18.1.4

# Launch a Policy Report:
curl -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
-d "action=launch&template_id=$PC_REPORT_TEMPLATE_ID&report_title=$PCC_REPORT_TITLE&output_format=pdf&report_type=Policy&policy_id=$PC_POLICY_ID&ips=$IP_ADDRESS" \
"https://$QUALYS_BASE_URL/api/2.0/fo/report/"

# => sẽ OK

# Launch Authnetication report:
curl -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
-d "action=launch&template_id=$PC_REPORT_TEMPLATE_ID&report_title=$PC_REPORT_TITLE&output_format=pdf&report_type=Compliance&ips=$IP_ADDRESS" \
"https://$QUALYS_BASE_URL/api/2.0/fo/report/"

# => sẽ LỖI, ko làm được, nó đòi template_id phải chuẩn, nhưng mình ko lấy được template_id. (ko tồn tại trên Portal -> Report), nhưng khi manual run Authentication report thì lại có.

# Nếu List report template id cũng ko tìm thấy Authentication Report template_id:
curl -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
https://$QUALYS_BASE_URL/msp/report_template_list.php

# Có 1 cách workaround trong link này: https://success.qualys.com/discussions/s/question/0D52L00004TnvcuSAB/report-api-authentication-report

# Đó là: Đầu tiên tạo 1 schedule report dạng Authentication report trên Portal bằng tay trước. Lấy được Schedule ID của nó. Ví dụ: 1576667
QUALYS_PC_SCHEDULE_AUTHEN_REPORT_ID=1576667

# Rồi dùng action=launch_now để tạo report, rồi download report đó về là xem được cái Authentication Report.

REPORT_ID=$(curl -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" -X "POST" \
-d "action=launch_now&id=$QUALYS_PC_SCHEDULE_AUTHEN_REPORT_ID" \
https://$QUALYS_BASE_URL/api/2.0/fo/schedule/report/ | \
xmlstarlet fo -D | \
xmlstarlet sel -t -v "SIMPLE_RETURN/RESPONSE/ITEM_LIST/ITEM/VALUE") 

# Get status of REPORT_ID trên:  
STATUS=$(curl -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
-d "action=list&id=$REPORT_ID" \
https://$QUALYS_BASE_URL/api/2.0/fo/report/| \
xmlstarlet fo -D | \
xmlstarlet sel -t -v "REPORT_LIST_OUTPUT/RESPONSE/REPORT_LIST/REPORT/STATUS/STATE")

# Download report REPORT_ID:  
curl -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
-d "action=fetch&id=$REPORT_ID" \
https://$QUALYS_BASE_URL/api/2.0/fo/report/ > AuthenticationReportAPI.pdf
```

WAS Scan Report:

```sh
WAS_SCAN_ID=2295436
QUALYS_WAS_REPORT_TEMPLATE_ID=237852 # Type: Scan Report
WAS_REPORT_ID=$(curl -s -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
  --location --request POST "https://$QUALYS_BASE_URL/qps/rest/3.0/create/was/report" \
  --header 'Content-Type: text/xml' \
  --data-raw "
<ServiceRequest>
<data>
    <Report>
    <name>Scan Report for Servers by API 2</name>
    <format>PDF</format>
    <template>
        <id>$QUALYS_WAS_REPORT_TEMPLATE_ID</id>
    </template>
    <config>
        <scanReport>
        <target>
            <scans>
            <WasScan>
                <id>$WAS_SCAN_ID</id>
            </WasScan>
            </scans>
        </target>
        </scanReport>
    </config>
    </Report>
</data>
</ServiceRequest>" | \
  xmlstarlet fo -D | \
  xmlstarlet sel -t -v "ServiceResponse/data/Report/id")

```

```sh
# Get WAS REPORT status:
STATUS=$(curl -s -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
  "https://$QUALYS_BASE_URL/qps/rest/3.0/status/was/report/460197" | \
  xmlstarlet fo -D | \
  xmlstarlet sel -t -v "ServiceResponse/data/Report/status")

# Download WAS REPORT:
curl -s -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
  "https://$QUALYS_BASE_URL/qps/rest/3.0/download/was/report/460197" > WAS_REPORT.pdf

```

Create WAS WebApp:

```sh
QUALYS_WAS_WEBAPP_ID=$(curl -s -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
 --location --request POST "https://$QUALYS_BASE_URL/qps/rest/3.0/create/was/webapp/" \
 --header 'Content-Type: text/xml' \
  --data-raw "
<ServiceRequest>
  <data>
    <WebApp>
      <name>[Temporary] WebApp</name>
      <url>http://$IP_ADDRESS</url>
    </WebApp>
  </data>
</ServiceRequest>" | \
  xmlstarlet fo -D | \
  xmlstarlet sel -t -v "ServiceResponse/data/WebApp/id")
```

Delete the WAS WebApp:

```sh
curl -s -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
 --location --request POST "https://$QUALYS_BASE_URL/qps/rest/3.0/delete/was/webapp/$QUALYS_WAS_WEBAPP_ID"
```

Create Qualys Cloud Agent để lấy Activation key:

```sh
curl -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
 --location --request POST "https://$QUALYS_BASE_URL/qps/rest/1.0/create/ca/agentactkey/" \
 --header 'Content-Type: text/xml' \
  --data-raw "
<ServiceRequest>
  <data>
    <AgentActKey>
      <title>Example key create from api</title>
      <type>UNLIMITED</type>
      <modules>
        <list>
          <ActivationKeyModule>
            <license>VM_LICENSE</license>
          </ActivationKeyModule>
          <ActivationKeyModule>
            <license>FIM</license>
          </ActivationKeyModule>
          <ActivationKeyModule>
            <license>EDR</license>
          </ActivationKeyModule>
          <ActivationKeyModule>
            <license>SWCA</license>
          </ActivationKeyModule>
          <ActivationKeyModule>
            <license>CAPS</license>
          </ActivationKeyModule>
        </list>
      </modules>
    </AgentActKey>
  </data>
</ServiceRequest>"
```

Response:

```
<ServiceResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://qualysapi.qg4.apps.qualys.com/qps/xsd/1.0/ca/agentactkey.xsd">
  <responseCode>SUCCESS</responseCode>
  <count>1</count>
  <data>
    <AgentActKey>
      <id>2322387</id>
      <activationKey>XXXXXX-XXXX-AAAA-BBBB-YYYYYYY</activationKey>
      <status>ACTIVE</status>
      <countPurchased>0</countPurchased>
      <countUsed>0</countUsed>
      <datePurchased>2023-12-07T08:00:32Z</datePurchased>
      <type>UNLIMITED</type>
      <title>Example key create from api</title>
      <networkId>0</networkId>
      <isDisabled>false</isDisabled>
      <applyOnAgents>false</applyOnAgents>
      <modules>
        <list>
          <ActivationKeyModule>
            <license>VM_LICENSE</license>
          </ActivationKeyModule>
        </list>
      </modules>
      <suspendSelfPatch>false</suspendSelfPatch>
    </AgentActKey>
  </data>
</ServiceResponse>
```

Response nếu bị duplicated key:  

```
<ServiceResponse xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="https://qualysapi.qg4.apps.qualys.com/qps/xsd/1.0/ca/agentactkey.xsd">
  <responseCode>CA_1001_DUPLICATE_KEY</responseCode>
  <responseErrorDetails>
    <errorMessage>Activation key already exists with title AAA</errorMessage>
    <errorResolution>Activation key already exists. Try another activation key.</errorResolution>
  </responseErrorDetails>
</ServiceResponse>
```

Download QualysCloudAgent binary bằng API:  

```sh
curl -H "X-Requested-With: Curl" -u "$QUALYS_USER:$QUALYS_PASSWORD" \
  --location --request POST "https://$QUALYS_BASE_URL/qps/rest/1.0/download/ca/downloadbinary/" \
  --header 'Content-Type: text/xml' \
  --data-raw "
<ServiceRequest>
  <data>
    <DownloadBinary>
      <platform>LINUX_UBUNTU</platform>
      <architecture>X_64</architecture>
    </DownloadBinary>
  </data>
</ServiceRequest>" > QCA-binary.deb
```

Sau khi cài đặt file binary, để activate key từ trong máy cài QualysCloudAgent thì cần CustomerId, nhưng ko biết lấy kiểu gì? ko lấy được bằng API nên harcode luôn trong script:

```sh
sudo /usr/local/qualys/cloud-agent/bin/qualys-cloud-agent.sh \
  ActivationId=XXXXXX-XXXX-AAAA-BBBB-YYYYYYY \
  CustomerId=QQQQQ-EEEE-RRRRR-TTTTT-ZZZZZ \
  ServerUri=https://qagpublic.qg4.apps.qualys.com/CloudAgent/
```


Để tương tác với [API của Qualys Container Security](https://docs.qualys.com/en/cs/api/#t=get_started%2Fget_started.htm), trước tiên cần authen để lấy bearer token:   

```sh
QUALYS_USER=AAA
QUALYS_PASSWORD='BBB'
QUALYS_BEARER_TOKEN=$(curl -X POST "https://gateway.qg4.apps.qualys.com/auth" -d "username=$QUALYS_USER&password=$QUALYS_PASSWORD&token=true" -H "Content-Type: application/x-www-form-urlencoded")

# list all images
curl -H 'accept: application/json' -H "Authorization: Bearer $QUALYS_BEARER_TOKEN" \
  -X GET 'https://gateway.qg4.apps.qualys.com/csapi/v1.3/images?pageNumber=1&pageSize=50&sort=created%3Adesc'

# count vulnerability for a image
IMAGE_ID=a3c86302cbad098cdc5ff49be5bf44a0ab32e5061deca2ba26416f0f3aa3f926
để lấy được IMAGE_ID thì bạn có thể docker inspect [IMAGE_NAME:TAG] để lấy `Id`

curl -H 'accept: application/json' -H "Authorization: Bearer $QUALYS_BEARER_TOKEN" \
-X GET "https://gateway.qg4.apps.qualys.com/csapi/v1.3/images/$IMAGE_ID/vuln/count"
```

Trả về nếu Sensor đã scan finished:

```
{"severity5Count":1,"severity3Count":1,"severity4Count":2,"severity1Count":0,"severity2Count":0}
```

Trả về nếu sensor chưa scan:

```
{"errorCode":"CMS-2002","message":"Data not available for given Image Id.","timestamp":1702376869566}
```

Trả về nếu đang scan:

```
{"severity5Count":null,"severity3Count":null,"severity4Count":null,"severity1Count":null,"severity2Count":null}
```

# 6. Fix 1 số Qualys vulnerable phổ biến

## 6.1. Fix Qualys Vulnerability QID-650035 and QID-105936 (OpenSSH version)

Upgrade OpenSSH version to resolve: https://www.tecmint.com/install-openssh-server-from-source-in-linux/

```sh
$ sudo apt update 
$ sudo apt install build-essential zlib1g-dev libssl-dev 
$ sudo mkdir /var/lib/sshd
$ sudo chmod -R 700 /var/lib/sshd/
$ sudo chown -R root:sys /var/lib/sshd/
$ sudo useradd -r -U -d /var/lib/sshd/ -c "sshd privsep" -s /bin/false sshd
$ wget -c https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-9.3p1.tar.gz
$ tar -xzf openssh-9.3p1.tar.gz
$ cd openssh-9.3p1/
$ sudo apt install libpam0g-dev libselinux1-dev
$ ./configure --with-md5-passwords --with-pam --with-selinux --with-privsep-path=/var/lib/sshd/ --sysconfdir=/etc/ssh 
$ make
$ sudo make install 

# Confirm OpenSSH changed:
$ ssh -V
OpenSSH_9.3p1, OpenSSL 1.1.1f  31 Mar 2020
```

## 6.2. Fix Qualys Vulnerability QID-38909 (SHA1 deprecated setting)

https://unix.stackexchange.com/questions/734243/how-to-disable-weak-hmac-algorithms-not-found-in-ssh-config-or-sshd-config-file

Sửa lại file `/etc/sshd/ssh_config`:

Add mấy dòng này vào cuối:

```
macs umac-64-etm@openssh.com,umac-128-etm@openssh.com,hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com,umac-64@openssh.com,umac-128@openssh.com,hmac-sha2-256,hmac-sha2-512
hostkey /etc/ssh/ssh_host_ecdsa_key
hostkey /etc/ssh/ssh_host_ed25519_key
```

Check lại bằng command:
```
sshd -T
ssh -Q mac
```

# 7. Một số tool thay thế cho Qualys

1 số scan tool dc recommended trên Reddit:  
https://www.reddit.com/r/cybersecurity/comments/16p0iec/what_vendors_are_actually_good/  
https://www.reddit.com/r/devops/comments/14r1okk/which_vulnerability_scanner_do_you_recommend/  

> Tenable.io (Nessus)

> Take a look at Seemplicity.io instead. Time Warner took 2 years to implement Brinqa because it's such a heavy lift.

> have you looked at a Kenna or Brinqa to help distill your vuln lists down?

> I've used qualys in the past and use nexpose as a backup testing tool. If you are in the cloud. Skip to wiz.io and thank me later. Wiz.io, Brinqa, ArmorCode, all money

> Seemplicity.io is way easier to implement than Brinqa. Armorcode is just for appsec and not as robust.

> ArmorCode certainly isn't just for AppSec.. Check out Vulcan too, them and ArmorCode I think are doing the best job. 

> So i mostly use Qualys for external scans and Greenbone internally.

> I have used nexpose and Nessus. I prefer nexpose. You should check out the product made by HD Moore. VERY good scanner if not better and way more affordable

> I used to work at Rapid7 but as a pentester. I used Nexpose for all the low hanging fruit. I know a few ppl that have gone to Rumble now but I have not really checked out what they do

> OpenVAS is an open source vulnerability scanner. OpenVAS is horrible lol! Its good for kids scanning their local lab but for those of us who are scanning 100K+ endpoints.

> Using Snyk today. It’s fantastic . Integrates well with GitHub. We use the automatic jira ticket creation for our high/critical vulnerabilities. I now added a step to get scans in our pipelines for some faster feedback.

> Anchore Grype. It also ties in with Gitlab very nicely.

Bài so sánh Qualys vs Nessus trên Reddit: https://www.reddit.com/r/cybersecurity/comments/y1ztuh/qualys_vs_nessus/

> We use Qualys but only as it allows pay per scan on unlimited IPs and a portable hardware appliance for driving it around to various data centres to plug it in. Which is what i use it for. If we just needed a vulnerability scanner on out own network, we'd probably go with Nessus.

> Microsoft Defender has Qualys vulnerability scanning built in but you have to manage your vulnerability reporting in their portal: https://learn.microsoft.com/en-us/azure/defender-for-cloud/deploy-vulnerability-assessment-tvm

> Qualys is CVE driven. Wiz is contextual. They are not the same. I managed a VM program for a fortune 500 and we were working to drop Qualys for Wiz. Its cutting edge.

