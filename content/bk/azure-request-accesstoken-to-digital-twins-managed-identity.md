---
title: "Azure: Request Access Token to Digital Twins use User-Assigned Identity"
date: 2021-10-15T20:57:39+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Notes]
#tags: [Azure]
comments: false
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Giống như IAM Role cho EC2 trên AWS, thì trên Azure cũng có feature tương tự đó là Managed identity (System assgined identity hoặc User assigned identity) "
---

Giống như IAM Role cho EC2 trên AWS, thì trên Azure cũng có feature tương tự đó là Managed identity (System assgined identity hoặc User assigned identity) 

# Prerequisites

Bạn đã tạo User-Assgined identity, VM đã enable identity.  

# Story

Theo [Azure official document](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-use-vm-token#get-a-token-using-curl), ví dụ để lấy access token dùng Azure Resource manager thì từ trong VM cần run command như này:  

```sh
response=$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F' -H Metadata:true -s)
access_token=$(echo $response | python -c 'import sys, json; print (json.load(sys.stdin)["access_token"])')
echo The managed identities for Azure resources access token is $access_token
```

Nhưng nếu muốn lấy access token dùng để truy cập "Azure Digital Twins", thì link cần thay đổi 1 chút (ko có `%2F` ở cuối url nữa -> mình đã mất 1 ngày để nhận ra điều này 😫 -> lý do viết bài này):
```sh
curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fdigitaltwins.azure.net' -H Metadata:true -s
response=$(curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fdigitaltwins.azure.net' -H Metadata:true -s)
access_token=$(echo $response | python -c 'import sys, json; print (json.load(sys.stdin)["access_token"])')
echo The managed identities for Azure resources access token is $access_token
```

**CREDIT:**  
https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/how-to-use-vm-token#get-a-token-using-curl