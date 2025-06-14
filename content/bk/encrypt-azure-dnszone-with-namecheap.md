---
title: "Azure DNS Zone setup with Namecheap domain"
date: 2024-07-05T21:50:50+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Azure,Namecheap,DNS]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Mình có 1 Namecheap domain và muốn point nó vào các Azure DNS Zone"
---

Giả sử mình mua 1 domain `yourdomain.dev` trên Namecheap. Giờ muốn setup nó với Azure DNS Zone để trỏ các service từ Internet vào `az.yourdomain.dev` sẽ đi đến các Azure resource của mình. Trên AWS cũng có service tương tự là AWS Route53.

- Internet ->　`*.az.yourdomain.dev` -> Azure DNS Zone -> Azure web app/services/VM

- Internet ->　`*.aws.yourdomain.dev` -> AWS Route53 -> AWS web app/services/VM

## Setup Azure DNS Zone with Namecheap domain

**Chú ý**: Pricing của mỗi DNS Zone trên Azure là $0.5/month. Tương tự AWS Route53 cũng $0.5/month.

Sau khi mua 1 domain trên Namecheap, bạn sẽ có cái dashboard trong account Namecheap để xem như này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-dns-namecheap-acc-2.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-dns-namecheap-acc.jpg)

Lên Azure portal -> DNS Zone -> tạo 1 DNS Zone là `az.yourdomain.dev`, bạn sẽ được thông tin về nameserver như hinh này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-dns-namecheap-overview1.jpg)

Phần record set sẽ thấy có sẵn 2 records này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-dns-namecheap-overview1-recordset.jpg)

Giờ lên Namecheap tạo các CNAME record trỏ vào azure-dns name server:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-dns-namecheap-add-cname-record-on-registrar.jpg)


## Verify

dùng command `nslookup`:

```s
$ nslookup -type=SOA <YOUR_DOMAIN>.dev
Server:         172.20.128.1
Address:        172.20.128.1#53

Non-authoritative answer:
<YOUR_DOMAIN>.dev
        origin = dns1.registrar-servers.com
        mail addr = hostmaster.registrar-servers.com
        serial = XXX
        refresh = YYY
        retry = 3600
        expire = 604800
        minimum = 3601

Authoritative answers can be found from:


$ nslookup -type=SOA az.<YOUR_DOMAIN>.dev
Server:         172.20.128.1
Address:        172.20.128.1#53

Non-authoritative answer:
az.<YOUR_DOMAIN>.dev       canonical name = nsXXX.azure-dns.com.

Authoritative answers can be found from:
```

Mình nghĩ như này là ok rồi. Vì nó đã trỏ đúng đến Azure DNS Nameserver. 


## Troubleshoot

Về dấu chấm ở cuối nameserver, [trang của MS](https://learn.microsoft.com/en-us/azure/dns/dns-delegate-domain-azure-dns/) thì bảo cần copy cả dấu chấm đó:    
> When you copy each name server address, make sure you copy the trailing period at the end of the address. The trailing period indicates the end of a fully qualified domain name. Some registrars append the period if the NS name doesn't have it at the end. To be compliant with the DNS RFC, include the trailing period.

Còn trang blog [này](https://medium.com/@bruvajc/how-to-really-map-a-namecheap-url-to-your-static-azure-cloud-website-3aa9d42dba26) thì bảo khi setup Namecheap thì nhớ bỏ dấu chấm đi, Ko biết đường nào mà lần:    
> Note that, in the Microsoft info, you’ll see a “.” (period) add at the end of the nameservers. You’re warned that some registrars drop the period or ignore it. Not Namecheap.com, as of this writing. If you leave the period at the end of the nameserver, your website won’t work! Be sure to drop the period when adding to Namecheap.

## Sử dụng

Giờ nếu bạn có 1 azure webapp resource muốn expose ra Internet theo domain riêng của bạn (`service1.az.yourdomain.dev`), chỉ việc tạo thêm 1 CNAME record hoặc A record trong Azure DNS Zone thôi.

## REFERENCES

https://learn.microsoft.com/en-us/azure/dns/dns-delegate-domain-azure-dns/

https://medium.com/@bruvajc/how-to-really-map-a-namecheap-url-to-your-static-azure-cloud-website-3aa9d42dba26