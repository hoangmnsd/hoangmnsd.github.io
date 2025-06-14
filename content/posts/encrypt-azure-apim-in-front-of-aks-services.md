---
title: "Setup Azure APIM in front of AKS services"
date: 2024-07-04T21:50:50+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [Azure,Kubernetes,AKS,APIM]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Lâu lâu mới đụng đễn APIM, vẫn khó và phức tạp như hồi mới dùng =))"
---

# 1. Giới thiệu

Bài này note lại cách APIM và AKS setup mà mình đã trải qua. (chủ yếu về APIM)

Azure APIM là 1 dịch vụ quản lý API của Azure. Tương tự như AWS API Gateway.

APIM có giá khá cao với nhiều tier khác nhau:
https://azure.microsoft.com/en-us/pricing/details/api-management/

# 2. Sơ qua về AKS

Mình setup AKS cluster trong 1 Vnet. (đã enable Azure CNI overlay)

# 3. Kiến trúc

Về kiến trúc nói chung, APIM có thể được đặt trong Vnet (phải có riêng 1 subnet cho APIM) hoặc đặt ngoài Vnet.

## 3.1. APIM trong Vnet

Nếu đặt APIM trong Vnet, bạn sẽ cần chọn mode cho APIM (internal hoặc external)

- Kiểu A: APIM trong Vnet - Mode internal sẽ ko có public IP. Giống hình này: ![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-apim-in-vnet-internal.jpg)

- Kiểu B: APIM trong Vnet - Mode external sẽ có public IP. Giống hình này: ![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-apim-in-vnet-external.jpg)

## 3.2. APIM ngoài Vnet

Nếu đặt APIM ngoài Vnet sẽ có 2 kiểu:

- Kiểu C: Các AKS services sẽ được expose ra Internet qua public IP của LoadBalancer để kết nối với APIM: ![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-apim-via-lb.jpg)

- Kiểu D: Các AKS services sẽ được expose ra Internet qua Ingress controller (Nginx, Traefik) để kết nối với APIM: ![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-apim-ingress.jpg)


## 3.3. Lựa chọn của tôi

Vì dự án của mình có 1 số điểm chú ý:
- AKS Backend svc cần được public ra Internet (Kiểu gì cũng phải public). APIM cũng cần được public ra Internet.
  => loại trừ Kiểu A.

- AKS cần phải có 1 Ingress Controller để expose 1 IP duy nhất ra Internet.
  => loại trừ Kiểu C.
Đến đây mình phân vân ko biết nên đặt APIM trong Vnet hay ngoài Vnet (kiểu B hoặc kiểu D).

- Nếu đặt APIM trong Vnet (mode external) - Kiểu B, bạn sẽ phải trỏ APIM đến private IP của AKS svc. Nhưng 1 Ingress Controller lại chỉ có 1 public IP cho External LB mà thôi. Nó sẽ ko có Private IP. Nếu muốn thì bạn phải tạo thêm 1 Ingress COntroller nữa để có Private IP cho Internal LoadBalancer. Mà như vậy thì lại phải quản lý 2 Ingress Controller.
  => Loại trừ kiểu B.

- Vậy là mình quyết định chọn Kiểu D. APIM đặt ngoài Vnet, APIM trỏ đến public IP của AKS svc Ingress Controller.

# 4. Rủi ro

Vì chúng ta expose AKS service ra Internet và giao tiếp APIM và AKS service ko qua mạng nội bộ Vnet, mà qua Internet. Thế nên rủi ro bảo mật rất dễ xảy ra.

Để hạn chế điều này thì cần quản lý chặt phần NSG của APIM cũng như của AKS.

Vì APIM mình đặt ngoài Vnet nên ko có NSG, chỉ có 1 public IP. Vì vậy NSG của AKS cần phải allow APIM public IP. Hãy set 1 rule:

Allow_APIM_to_Traefik / Source: <APIM_Public_IP> / Destination: <Traefik_Public_IP>

Để test xem connection works chưa, Hãy vào APIM để test thử các API.

Ngoài ra, Trong TH của mình 1 số VM cần connect trực tiếp đến AKS nên mình cũng phải allow trong NSG:

Allow_VM_to_Traefik / Source: <VM_Public_IP> / Destination: <Traefik_Public_IP>

Chú ý mặc dù VM và AKS trong cùng 1 Vnet nhưng ko thể connect trực tiếp đến nhau qua private IP, phải thông qua Public IP. Điều này cũng là 1 điều mình ko thích lắm, nhưng vì tính chất gấp rút của dự án nên làm vậy.


# REFERENCES

https://learn.microsoft.com/en-us/azure/api-management/api-management-kubernetes#deploy-api-management-in-front-of-aks

https://azure.microsoft.com/en-us/pricing/details/api-management/

Deploy APIM to Vnet - external mode:

https://learn.microsoft.com/en-us/azure/api-management/api-management-using-with-vnet?tabs=stv2

Deploy APIM to Vnet - internal mode:

https://learn.microsoft.com/en-us/azure/api-management/api-management-using-with-internal-vnet?tabs=stv2