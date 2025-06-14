---
title: "Azure: Copy a blob from a tenant to another tenant account"
date: 2021-10-02T09:53:45+09:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [Azure]
comments: false
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Việc copy 1 file từ storage account này sang 1 storage acccount khác tenant không hẳn là khó khăn, nhưng cũng đòi hỏi 1 chút chú ý để tránh mất thời gian."
---

# 1. Giới thiệu

Việc copy 1 file từ storage account này sang 1 storage acccount khác tenant không hẳn là khó khăn, nhưng cũng đòi hỏi 1 chút chú ý để tránh mất thời gian 

# 2. Yêu cầu

- Dùng WSL
- Download AzCopy tool, refer: https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10

# 3. Cách làm

## 3.1. Copy a file from a tenant to another

Đầu tiên cần nắm được syntax: 

Copy a single blob to another blob by using a SAS token.

  - azcopy cp "https://[srcaccount].blob.core.windows.net/[container]/[path/to/blob]?[SAS]" "https://[destaccount].blob.core.windows.net/[container]/[path/to/blob]?[SAS]"

Copy a single blob to another blob by using a SAS token and an OAuth token. You have to use a SAS token at the end of the source account URL, but the destination account doesn't need one if you log into AzCopy by using the azcopy login command.

  - azcopy cp "https://[srcaccount].blob.core.windows.net/[container]/[path/to/blob]?[SAS]" "https://[destaccount].blob.core.windows.net/[container]/[path/to/blob]"

Như vậy, chúng ta đi theo hướng dùng syntax số 1, để ko phải login vào AzCopy tool:  
```sh
azcopy cp "https://[srcaccount].blob.core.windows.net/[container]/[path/to/blob]?[SAS]" "https://[destaccount].blob.core.windows.net/[container]/[path/to/blob]?[SAS]"
```

Đầu tiên là lấy SAS URL của Source Account file, bạn chỉ cần để quyền READ là đủ:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-azcopy-sas-sourceacc.jpg)

Thứ 2 là lấy SAS URL của Destination Account container, chỗ bạn sẽ paste file vào, thì cần cả quyền WRITE nữa (nhiều ng ko để ý thì khi copy sẽ bị lỗi):
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-azcopy-sas-destacc.jpg)

GIờ run command:
```sh
azcopy copy 'https://abcd12345678.blob.core.windows.net/container1/abcd123455666.zip?sp=r&st=2020-10-08T15:32:23Z&se=2020-10-09T23:32:23Z&spr=https&sv=2020-08-04&sr=b&sig=UP7bXNoIbXNoIbXNoIbXNoIbXNoIbXNoIbXNoIw%3D' 'https://abc1234.blob.core.windows.net/container2?sp=racwl&st=2020-10-09T16:11:19Z&se=2020-10-12T00:11:19Z&spr=https&sv=2020-08-04&sr=c&sig=idW348Um3AQ348Um3AQj348Um3AQj348Um3AQjjxe4%3D'
INFO: Scanning...
INFO: Failed to create one or more destination container(s). Your transfers may still succeed if the container already exists.
INFO: Any empty folders will not be processed, because source and/or destination doesn't have full folder support

Job e4304ef7-e5eb-b24e-5477-6a55642e9341 has started
Log file is located at: 

100.0 %, 0 Done, 0 Failed, 1 Pending, 0 Skipped, 1 Total,


Job q1234ef7-xxxxxxxxxxxxx-2e9842 summary
Elapsed Time (Minutes): 1.234
Number of File Transfers: 1
Number of Folder Property Transfers: 0
Total Number of Transfers: 1
Number of Transfers Completed: 1
Number of Transfers Failed: 0
Number of Transfers Skipped: 0
TotalBytesTransferred: 32213303808
Final Job Status: Completed
```
 
Command run xong nhưng job COPY vẫn đang chạy nha các bạn. 
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-azcopy-result-destacc.jpg)

Nếu nhìn thấy hình trên có nghĩa là vẫn chưa copy xong đâu. 

Hãy kiên nhẫn chờ bao giờ copy xong nó sẽ như thế này:
![](https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/azure-azcopy-result-destacc-ok.jpg)

## 3.2. Copy all content in a container to another

https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-blobs-copy

Run `azcopy --help` để xem format command copy 1 container từ bên này sang bên kia

Step 1: Tạo trước 1 container bên Destination Storage account (ko nhất thiết phải giống tên với source container).

Step 2: Lấy SAS token của container bên Source Storage account, cần quyền READ và LIST  

Step 3: Lấy SAS token của container bên Destination Storage account, cần quyền WRITE, ADD..

Step 4: run `az cp` command

Nếu bị lỗi này:  

```
failed to perform copy command due to error: cannot start job due to error: cannot list files due to reason -> github.com/Azure/azure-storage-blob-go/azblob.newStorageError, /home/vsts/go/pkg/mod/github.com/!azure/azure-storage-blob-go@v0.15.0/azblob/zc_storage_error.go:42
===== RESPONSE ERROR (ServiceCode=AuthorizationPermissionMismatch) =====
Description=This request is not authorized to perform this operation using this permission.
```
-> Nghĩa là Vì mình đang copy All content từ 1 container nên Source SAS cần quyền LIST, cần tạo lại SAS token

Chúc các bạn thành công!! ✌

# CREDITS

https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-blobs-copy?toc=/azure/storage/blobs/toc.json  
https://learn.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-blobs-copy  