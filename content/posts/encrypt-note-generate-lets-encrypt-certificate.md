---
title: "Generate Lets Encrypt Certificate"
date: 2022-12-17T22:17:57+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Notes]
tags: [Letsecrypt]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Về cơ bản để tạo LetsEncrypt certificate sẽ có 2 cách, 1 là DNS 2 là HTTP"
---

# DNS and HTTP

Về cơ bản để tạo LetsEncrypt certificate sẽ có 2 cách, 1 là DNS 2 là HTTP

- DNS: Trên Server đó bật terminal, run command `certbot` gen cert, sẽ nhận được 1 token, lấy token đó tạo 1 record TXT trên DNS provider. Quay lại màn hình terminal, tiếp tục enter để LetsEncrypt verify rằng bạn là người sở hữu domain.  

- HTTP: Trên Server đó bật terminal, run command `certbot` gen cert. LetsEncrypt sẽ yêu cầu bạn tạo 1 file trên Server đó, expose file đó ra port 80 qua http domain. Quay lại terminal để LetsEncrypt có thể truy cập được qua http domain, và verify rằng bạn là người sở hữu server và domain.  
(Chú ý để expose file đó ra port 80 qua http domain, thì bạn cũng cần có quyền vòa DNS provider tạo A reccord trỏ về public IP của Server nữa)

Install certbot:  

```sh
sudo apt update
sudo apt install snapd
sudo snap install core
sudo snap refresh core

sudo apt remove certbot
sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot
```

References:  
https://www.linode.com/docs/guides/enabling-https-using-certbot-with-nginx-on-ubuntu/  

https://www.nginx.com/blog/using-free-ssltls-certificates-from-lets-encrypt-with-nginx/  


# Gen Letsencrypt cert mà ko cần SSH vào Server?

Thường theo các guide trên mạng là phải SSH vào server, rồi run certbot để gen cert,  
tất nhiên phải có quyền tạo record trên DNS provider, config DNS record trỏ vào public IP của Server. 

Tuy nhiên, Mình đang tìm cách để gen cert mà ko cần SSH vào server

Thi bài này nói rằng có thể generate cert mà ko SSH vào server:  
https://laracasts.com/discuss/channels/general-discussion/lets-encrypt-is-it-possible-to-generate-a-certificate-without-beeing-on-the-server

https://ongkhaiwei.medium.com/generate-lets-encrypt-certificate-with-dns-challenge-and-namecheap-e5999a040708

Về cơ bản thì mình có thể làm thế, đầu tiên là mở terminal:  
```sh
sudo certbot certonly --manual --preferred-challenges dns -d "*.DOMAIN"
```

Sau đó nó sẽ trả về 1 token, copy token đó, lên DNS provider, tạo TXT record, value là token vừa nhận.  
Quay lại terminal, enter để certbot thực hiện verification process.

# Gen Letsencrypt cert mà chỉ có Server, ko có quyền tạo record trên DNS Provider?

TH muốn generate cert nhưng chưa có server, cũng chưa có quyền vào DNS để tạo records.  

> Có thể bạn nghĩ đến 1 cách tạo 1 temporary server, tạo cert trên Server đó rồi Sau này mang cert đó sang Server thật để install?

Trả lời:  
```
If you generate a LetsEncrypt cert on a “temporary server“ and you are choosing HTTP method, then at first you need to expose that server to internet so Letsencrypt can request it via HTTP url. (to do that, you need to create an A record on DNS entries, pointing to temporary server’s public IP. But you don’t managed DNS)

If you generate a LetsEncrypt cert on a “temporary server“ and you are choosing DNS method, then you need to create a TXT record on DNS entries with token given by LetEnscrypt. But you don’t managed DNS)

In both cases, you need at least the ability to manage DNS records.
```
