---
title: "RAG with knowledge base"
date: 2025-01-27T23:01:48+09:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Notes]
#tags: [RAG,OpenwebUI,AI]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "RAG with knowledge base"
---

Bài này nói về cách để dùng OpenWebUI API với RAG collection knowledge base đã upload từ trước:
https://docs.openwebui.com/getting-started/api-endpoints/

Có lẽ sẽ thích hợp cho use-case kiểu tích hợp chatbot để trả lời FAQ cho 1 website

Đầu tiên nên chọn setting 1 model để dùng cho Embedding model:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/openwebui-document-embedding-models.jpg)

upload RAG knowledge base lên Openweb UI, upload phải ra được trạng thái như này mới OK:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/openwebui-document-upload-ok.jpg)

Khi hỏi thì thêm dấu # để mention các document đang tìm:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/openwebui-document-use.jpg)

# Calling API với RAG đã upload

Vào đây lấy API Key của user:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/openwebui-api-keys.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/openwebui-api-keys-enables.jpg)

Lấy collection_id bằng cách F12:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/openwebui-get-collection-id.jpg)

Call đến Api bằng tài liệu: https://docs.openwebui.com/getting-started/api-endpoints/

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/openwebui-call-api-rag.jpg)

# Hạn chế chung của tính năng RAG này

Nhiều câu hỏi nó ko tìm được trong file RAG đã upload

Ngay cả khi upload bạn dùng model (text-embedding-3-large) đắt tiền nhất của OpenAI

Ví dụ: Với câu hỏi: Đi xe máy vượt đèn đỏ bị phạt bao nhiêu? 

TH1: dùng gpt-4o-mini, mention đến File (chứ ko phải Collection) -> trả lời sai

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/openwebui-rag-limit-1.jpg)

TH2: dùng gpt-4o-mini, mention đến Collection -> trả lời sai

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/openwebui-rag-limit-2.jpg)

TH3: dùng gpt-4o, mention đến Collection -> trả lời sai

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/openwebui-rag-limit-3.jpg)

TH4: dùng gpt-4o, mention đến File (chứ ko phải Collection) -> trả lời sai

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/openwebui-rag-limit-4.jpg)

Trong khi câu trả lời có thể dễ dàng tìm trên internet:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/openwebui-rag-limit-5.jpg)

Khi giữ set Top K=3 và score set trên 65, thì cũng ko khả quan, ko tìm được câu trả lời nên GPT dùng các thông tin cũ:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/openwebui-rag-limit-6.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/openwebui-rag-limit-7.jpg)

Nếu set Top K=5, minimum score=50, vẫn sai:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/openwebui-rag-limit-8.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/openwebui-rag-limit-9.jpg)

Nói chung ko thể làm sao để trả về đúng kết quả (4tr-6tr)


