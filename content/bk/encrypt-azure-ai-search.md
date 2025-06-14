---
title: "Azure AI Search service"
date: 2025-02-27T23:01:48+09:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Notes]
#tags: [Azure,AISearch]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Trải nghiệm tính năng của Azure AI Search service"
---

https://microsoftlearning.github.io/mslearn-ai-fundamentals/Instructions/Labs/11-ai-search.html

Lab này sẽ có 3 resoucre cần tạo:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-rs-created.jpg)

Tạo Azure AI Search:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-rs-created-1.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-rs-created-overview.jpg)

Tạo Azure AI service để sau này attach vào Search service:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-create-ai-svc.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-create-ai-svc-basic.jpg)

Tạo storage account:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-create-storageacc.jpg)

Download file review về https://aka.ms/mslearn-coffee-reviews

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-data-test.jpg)

Upload lên container của storage account:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-data-test-uploaded.jpg)

Click import data:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-import-data.jpg)

Connect đến storage account:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-connect-to-sa.jpg)

Chọn cái mình đã tạo:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-attach-ai-svc.jpg)

Select theo hướng dẫn:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-import-data-create-searchable-fields.jpg)

Tiếp mở tab tiếp theo, có thể sẽ cần tạo container mới trong SA, knowledge-store

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-import-data-knowledge-store.jpg)

Tab Customize target index sửa như sau:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-import-data-customize-target-index.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-import-data-customize-target-index-2.jpg)

Tab tiếp theo, create indexer:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-import-data-create-indexer.jpg)

Quá trình create indexer xong khi hiện như này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-import-data-create-indexer-wip.jpg)

Dùng chức năng Search Explorer:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-explorer.jpg)

Khi search all sẽ trả về kết quả như này, chuỗi json với nhiều element đã được phân tích:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-explorer-result.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-explorer-result-2.jpg)

Search theo sentiment negative, chỉ ra 1 kết quả:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-explorer-result-3.jpg)

Tuy nhiên khi vào container này thì ko có data: 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-container-knowledge-store.jpg)

là do khi setting mình đã chọn thiếu 1 cái. Nếu làm đúng mình sẽ thấy được content như này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-container-knowledge-store-ok.jpg)

Nội dung bên trong knowledge-store:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-container-knowledge-store-content.jpg)

Ngoài ra có container mới được tạo, chứa image của data source:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-container-image.jpg)

Nội dung image trong container:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-container-image-content.jpg)

Vào "Azure Ai Foundry | Azure Open AI Service", Chọn Add your data, chọn "Azure AI Search" **(chỗ này cần phải Azure Ai Search có pricing tier từ Basic trở lên, nếu Free sẽ bị lỗi ko add được vào)**

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-openai-ds-select.jpg)

Có thể chọn Semantic hoặc Keyword làm Search type, **nhưng chọn Semantic thì index cần phải được config theo kiểu dánh cho semantic search.**

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-openai-ds-select-search-type.jpg)

Chỗ này có thể lựa chọn API key hoặc System managed identity:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-openai-ds-connection.jpg)

Có thể gặp 2 lỗi này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-openai-ds-connection-error.jpg)

Fix bằng cách sau:
- Vào Azure AI Search -> Setting (Identity) -> enable System assigned status -> ON
- Vào Azure OpenAI Service -> Setting (Identity) -> enable System assigned status -> ON
- Vào Azure AI Search -> Setting (Keys) -> enable `Both` API access control
- Vào Azure AI Search -> IAM, add 2 roles cho cái system managed role của azure OpenAI service

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-openai-ds-connection-error-fix.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-openai-ds-connection-error-fix2.jpg)

Như này là OK hết lỗi:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-openai-ds-connection-ok.jpg)

Có thể gặp lỗi này, Nguyên nhân có lẽ do index của mình tạo ra chưa được config để sử dụng `Sematic` Search Type:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-openai-chat-error-semantic.jpg)

Add lại Data source sử dụng Search type là `Keyword` là OK.

Kết quả chat OK:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-openai-chat-ok.jpg)

Test chức năng `deploy as a Webapp` của Foundry:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-openai-deployment-as-webapp.jpg)

Nếu enable chat history sẽ tốn thêm tiền CosmosDB:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-openai-deployment-as-webapp-ifenable-history.jpg)

Có thể gặp lỗi ko deploy được:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-openai-deployment-as-webapp-error.jpg)

Chọn lại sang region khác (East US 2) là deploy OK:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-openai-deployment-as-webapp-error-fix.jpg)

Đợi deploy xong như này là OK:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-openai-deployment-as-webapp-succeeded.jpg)

Quay trở lại sẽ thấy 2 resource mới được tạo trong RG:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-openai-deployment-as-webapp-succeeded-rg.jpg)

Ấn vào nút Browse để truy cập webapp:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-openai-deployment-as-webapp-succeeded-overview.jpg)

Có thể sẽ đến màn hình này, Chọn accept:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-openai-deployment-as-webapp-accept.jpg)

Ví dụ về webapp giao diện:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-openai-deployment-as-webapp-ui1.jpg)

ko trả lời bằng image được:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-openai-deployment-as-webapp-ui2.jpg)

Hỏi 1 câu thông thường, nhưng ko trả lời được, có vẻ cần dùng semantic search type??:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-openai-deployment-as-webapp-ui3.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-ai-search-openai-deployment-as-webapp-ui4.jpg)



