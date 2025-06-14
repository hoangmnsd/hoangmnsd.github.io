---
title: "Azure Bot Service experiment"
date: 2025-02-17T21:46:36+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [Azure,AzureBot,AzureAppService]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Deploy Azure Bot Service and test few channel"
---


# 1. Local Development, run Bot locally và test dùng Emulator

source sample của Azure: https://github.com/microsoft/BotBuilder-Samples/tree/main/samples/python/02.echo-bot

Download app Emulator cài đặt trên windows

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-emulator-1.jpg)

Chạy app trên WSL (có thể sẽ bị lỗi về sau):

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-run-local.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-emulator-1-open.jpg)

chạy trên WSL mình sẽ bị lỗi như này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-emulator-1-open-error.jpg)

Chuyển sang chạy trên Windows python GitBash sẽ ok:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-run-local-gitbash.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-emulator-1-open-ok.jpg)


# 2. Provision Azure Bot Service 

https://learn.microsoft.com/en-us/azure/bot-service/abs-quickstart?view=azure-bot-service-4.0&wt.mc_id=searchAPI_azureportal_inproduct_rmskilling&sessionId=23113e4166814aa9a96aaf685a50e38b&tabs=userassigned

Tạo 1 App registration từ Entra AD:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-app-reg-1.jpg)

Tạo và chọn Plan:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-create-1-plan.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-create-2-rev.jpg)

Sau khi tạo:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-created.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-created-tab-profile.jpg)

chỗ Message Endpoint này chưa có gì vì sau này cần provision AppService, rồi lấy URL paste vào Message Endpoint ở đây

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-created-tab-config.jpg)

Support nhiều channel Telgram, Alexa, Line...

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-created-tab-channel.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-created-tab-test.jpg)

# 3. Deploy bot to Azure App Service (web app)

https://learn.microsoft.com/en-us/azure/bot-service/provision-and-publish-a-bot?view=azure-bot-service-4.0&tabs=userassigned%2Ccsharp#publish-your-bot-to-azure

Có sẵn ARM code trong folder samples echo2-bot, Copy:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-app-svc-arm.jpg)

Click vào bút chì:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-app-svc-arm-ui.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-app-svc-arm-ui-2.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-app-svc-arm-ui-3.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-app-svc-arm-ui-3-error.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-app-svc-arm-ui-3-error-fix.jpg)

Như này là OK:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-app-svc-arm-deployed.jpg)

Vào RG sẽ thấy 2 resouce dc tạo ra:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-rg.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-rg-env.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-rg-config.jpg)

Đây là chỗ có URL của App service:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-rg-webapp.jpg)

Để deploy lên cần:

zip folder source

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-rg-webapp-deploy-zip.jpg)

Run command để deploy file zip lên App Service:
```sh
az webapp deploy --resource-group az-bot-rg --name AAABBBCCCappsvc --src-path ./AAABBBCCC-echobot.zip --type zip
```

Deploy như này là OK:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-rg-webapp-deploy-ok.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-rg-webapp-deploy-ok-2.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-rg-config-endpoint.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-rg-config-test.jpg)

# 4. Connect to Telegram channel

Trên Telegram tạo 1 Bot (bằng cách chat vơi BotFather)

Sau đó lấy Api Token của Telegram Bot, paste vào phần Access Token này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-rg-config-channel-telegram.jpg)

Chỉ thế thôi, là bạn đã có thể chat với Bot Telegram, và nhận message từ Azure Bot service của bạn

Ngoài ra Azure Bot service support nhiều Channel:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-created-tab-channel-2.jpg)

# 5. Use Azure Function instead of App Service

Nếu làm theo cách trên, thì sẽ cần phải chọn Azure WebApp và Azure app service plan: hiện đang chọn F1 free (60min/day), nhưng hoàn toàn có thể phải chọn plan đắt hơn nếu scale, giá từ 12-50$ cho basic.

Mình ko thích kiểu pricing theo Plan(phải subscription và trả trước như vậy). 

Thêm nữa là phải study về AzureBotFramework samples.

Trong khi nếu Sử dụng Azure Function thì mình sẽ tính tiền theo memory consumtion và theo requests per second. Và được free 400 GB memory comsumtion và 1 triệu request mỗi tháng. https://azure.microsoft.com/en-us/pricing/details/functions/#pricing

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-azfunction-price.jpg)

Kết hợp Giữa Azure Bot Service với Azure Function để tiết kiệm chi phí (dùng Azure function plan Consumption)

Khi tạo Azure Function sẽ có các resource sau được tạo:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-azfunction-resource.jpg)

Dùng func command để tạo azure function ở local

Code 1 function như này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-azfunction-vscode.jpg)

Sau khi deploy Azure Function lên (dùng command `func azure functionapp publish <FunctionName>`)

Chú ý phải có dòng màu xanh như này mới là OK

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-azfunction-vscode-deploy.jpg)

Deploy OK sẽ thấy function hiển thị như này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-azfunction-running-app.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-update-endpoint.jpg)

Rồi liên kết Telegram bằng acess token:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-update-endpoint-telegram-ok.jpg)

Giờ bạn đã có thể handle các request gửi qua Telegram bằng Azure function rồi:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-bot-azfunction-log.jpg)

Cách này có thể nói là đơn giản hơn việc phải học thêm AzureBotFramework nữa, mà lại khá tiết kiệm

Như vậy bằng cách này ta có thể integrate rất nhiều channel khác nhau 1 cách nhanh chóng

Mở rộng hơn cũng có thể dùng cách này để integrate giữa Azure Bot service với AWS Lambda function

**Nhược điểm của Azure Function App**: 

Rất hay bị lỗi sau khi thay đổi endpoint (ví dụ như sendMessage thành sendMessage12345678) mất rất lâu để môi trường reload endpoint mới



