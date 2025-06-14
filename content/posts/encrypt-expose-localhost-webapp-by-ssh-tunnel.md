---
title: "Expose your app running in private network via Putty SSH Tunnel"
date: 2023-07-18T14:20:21+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [SSH-Tunnel]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Notes về SSH tunnel bằng Putty.."
---

## 1. Tình huống

User có 1 app cvat run trên port 8080 trong 1 VM A AWS Private subnet. Có 1 VM làm Bastion Host trong Public Subnet.  
Giờ muốn SSH vào A từ máy laptop cá nhân rồi cài app lên port 8080, sau đó test để thử vào giao diện web app đó trên laptop cá nhân.

Kiến trúc như này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-private-subnet-tunnel.jpg)

## 2. Cách làm

Để có thể SSH từ laptop mình vào EC2 trong private subnet:  
[credit1](https://stackoverflow.com/questions/52816990/sshing-into-aws-ec2-instance-located-in-private-subnet-in-a-vpc)
[credit2](https://aws.amazon.com/blogs/security/securely-connect-to-linux-instances-running-in-a-private-amazon-vpc/)

- VPC của bạn đã config NAT và IGW  
- Private subnet đã dc gắn với NAT Gatewat Route  
- tạo Bastion trong public subnet  
- Setup SG của Bastion để allow IP của laptop cá nhân  
- tạo EC2 trong private subnet  
- Setup SG của EC2 trên để allow IP của Bastion có thể SSH vào.   

Trên laptop, bật "PageAnt" lên, add key dùng để SSH vào.   

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-private-subnet-tunnel-pagent-putty.jpg)

SSH vào Bastion cần tick vào ô sau (Allow Agent forwarding):  

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-private-subnet-tunnel-pagent-putty-allow-forwarding.jpg)

Sau đó SSH tiếp vào EC2 trong private subnet:

```sh
ssh user@<instance-IP-address or DNS-entry>
```

Về app cvat: https://github.com/opencv/cvat. Sau khi Cài web app cvat trong private subnet. Thì connect vào webapp đó kiểu gì từ laptop? 

Đầu tiên sau khi đã SSH vào dc bằng cách setting Pagent forwarding ở trên
thì cài đặt bình thường các app.

Sau đó setting SG của EC2 trong private subnet như sau:  
- mở port 8080 cho Bastion host
- mở port 22 cho Bastion host (cái này đã setting từ trước)

Setting Putty của cái Bastion thêm config như sau:  
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-private-subnet-tunnel-putty-tnl.jpg)

Sau khi SSH vào Bastion OK: Thì trên laptop vào browser, trỏ đến địa chỉ sau: "localhost:8080" sẽ vào dc app

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-private-subnet-tunnel-localhost.jpg)


## 3. Bonus 

Tương tự như vậy Nếu bạn có 1 public VM và cũng muốn dùng thử tính năng "open localhost trên remote" thì cũng sẽ tương tự:

Đầu tiên bạn cần SSH được vào VM đó đã. Rồi tạm thời thoát ra.

Mở Pagent Putty lên, add SSH Key vào. 
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-private-subnet-tunnel-pagent-putty.jpg)
Tick ô sau trong setting Putty.
![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-private-subnet-tunnel-pagent-putty-allow-forwarding.jpg)
Ví dụ mình có app đang run trên port 4000, giờ muốn forward cái port 4000 đó về máy laptop của mình:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/putty-tunnel-setting.jpg)

Sau khi mở SSH bằng Putty, sẽ được như này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/app-ytalexa-4000-run-via-tunnel.jpg)


## CREDIT

1 bài về setup AWS Bastion host:  
https://medium.com/faun/aws-setup-bastion-host-ssh-tunnel-f5ec5cf10524  

ngoài ra:  
https://stackoverflow.com/questions/18450762/how-to-connect-to-a-webserver-on-ec2-privately/18480977#18480977  
https://stackoverflow.com/questions/52223864/connect-to-a-web-application-in-private-through-bastion-host-for-my-local-machin  

Để có thể SSH từ laptop mình vào EC2 trong private subnet:  
https://stackoverflow.com/questions/52816990/sshing-into-aws-ec2-instance-located-in-private-subnet-in-a-vpc  
https://aws.amazon.com/blogs/security/securely-connect-to-linux-instances-running-in-a-private-amazon-vpc/  
  