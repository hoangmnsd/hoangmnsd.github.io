---
title: "AWS IAM SSO with Identity Center"
date: 2025-03-28T21:54:05+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [AWS,IAM,IdentityCenter]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "AWS: IAM SSO with Identity Center"
---

Bài này playaround với AWS IAM Identity Center, 1 service khá hay được recommend để đảm bảo security.

Mình thấy tính năng quan trọng nhất là có thể set duration timeout(session) cho từng cặp Access Key (ví dụ 1h, 8h)

Enable service:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-iam-sso-enable.jpg)

Add user:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-iam-sso-add-user.jpg)

Login với user vừa tạo, dùng link mà step trước có được:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-iam-sso-add-user-login.jpg)

Sẽ cần enable MFA:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-iam-sso-add-user-login-mfa-enable.jpg)

Bởi vì chưa đc set Permission nên sẽ ko thấy gì ở Access Portal này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-iam-sso-add-user-login-nothing.jpg)

Quay lại IAM identity Center, create permission set:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-iam-sso-add-user-login-create-per-set.jpg)

Chúng ta sẽ tạo 1 Custom Permission để hạn chế vừa đủ quyền để dùng:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-iam-sso-add-user-login-create-per-set-custom.jpg)

Chỗ inline Policy này paste json policy giống như bên IAM Role/Policy:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-iam-sso-add-user-login-create-per-set-custom-inline-policy.jpg)

Điền description:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-iam-sso-add-user-login-create-per-set-custom-inline-policy-2.jpg)

Set permission set ok:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-iam-sso-add-user-login-create-per-set-ok.jpg)

Vào AWS Account tab để link account với user vừa tạo:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-iam-sso-link-account.jpg)

Chọn user, có thể chọn group:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-iam-sso-link-account-select-user.jpg)

Assign Permission set, **bước này quan trọng vì nó thể hiện sự linh hoạt trong việc set các Permission khác nhau cho từng SSO User**:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-iam-sso-link-account-select-perm-set.jpg)

Xuất hiện permission set đã được assigned:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-iam-sso-link-account-select-perm-set-2.jpg)

Login bằng account đã tạo, vào access portal, sẽ chỉ nhìn thấy Permission Set được assign `SamDeployLambda`:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-iam-sso-access-portal-login.jpg)

Ấn Vào `SamDeployLambda` sẽ ra giao diện Console sẽ chỉ thấy như này, 1 số service ko xem được vì ko có permission:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-iam-sso-access-portal-login-console.jpg)

Nếu có quyền xem all Lambda thì sẽ thấy được hết các functions như này. Đó là lý do nên set quyền thật chặt để đảm bảo security:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-iam-sso-access-portal-login-console-lambda.jpg)

Ấn vào Access keys sẽ ra giao diện để lấy key tạm thời dùng cho CLI:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/aws-iam-sso-access-portal-login-access-key.jpg)


# REFERENCES

https://www.youtube.com/watch?v=_KhrGFV_Npw

