---
title: "Azure ContentSafety Studio, Azure Foundry ContentSafety"
date: 2025-02-19T21:46:36+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Tutorials]
#tags: [Azure,ContentSafetyStudio]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Test tính năng của Azure Content Safety Studio"
---

Làm theo Labs này: https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Labs/02-content-safety.html

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-contentsafety-create.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-contentsafety-create-rv.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-contentsafety-created-rs.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-contentsafety-created-rs-overview.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-contentsafety-created-rs-iam.jpg)

Add role "Cognitive Services User" for user

Xong chỗ này vẫn ko xuất hiện:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-contentsafety-created-rs-iam-err.jpg)

Test thử Run simple test ko được vì lỗi bên trên chưa resolved:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-contentsafety-created-rs-iam-err-test.jpg)

Nhưng chuyển sang dùng giao diện mới (Preview) Azure AI Foundry thì có thể run Test được và chọn dc resource:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-contentsafety-foundry-svc.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-contentsafety-foundry-svc-test.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-contentsafety-foundry-svc-test-ok.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-contentsafety-foundry-svc-test-ok-2.jpg)

sample code:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-contentsafety-foundry-svc-test-code.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-contentsafety-foundry-svc-test-image.jpg)


