---
title: "Azure: Copy Snapshot to Storage Account"
date: 2022-01-14T18:03:03+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Notes]
#tags: [Azure]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Trong quá trình config cài cắm, có thể bạn sẽ muốn tạo snapshot/đóng image cho 1 VM nào đó. Sau này bạn chỉ cần tạo lại VM từ snapshot đó là xong. "
---

Trong quá trình config cài cắm, có thể bạn sẽ muốn tạo snapshot/đóng image cho 1 VM nào đó. Sau này bạn chỉ cần tạo lại VM từ snapshot đó là xong. 

Azure có tính năng `Capture - create an image`, nhưng Nếu capture bạn sẽ phải stop VM, và sẽ ko thể sử dụng VM được nữa. (quá trình Capture đòi hỏi generalise VM và xóa các thông tin về user)

Azure còn có chức năng `Snapshot`, bạn chỉ cần làm trên giao diện là có thể snapshot được 1 ổ disk bất kì. Việc này kiểu như bạn có 1 bản backup point-in-time của VM hiện có mà ko cần phải stop VM.

-> Thế nên trường hợp này mình sẽ sử dụng `Snapshot`.

Sau khi snapshot 1 VM, có thể bạn sẽ muốn copy snapshot đó lên storage account. Để tập trung 1 chỗ (nếu để snapshot có thể bị xóa do vô ý)

Quá trình copy này mình sẽ dùng az-cli: chạy trên az-cli 2.32.0 của WSL Ubuntu18.04 bị lỗi `Invalid return character or leading space in header: x-ms-copy-source`

Phải chuyển sang chạy trên 1 Azure VM, cài az-cli 2.37.0 rồi chạy thì ko bị lỗi nữa. Cách để cài az-cli 2.37.0 thì như sau:
```sh
apt-get update
apt-get install ca-certificates curl apt-transport-https lsb-release gnupg -y

curl -sL https://packages.microsoft.com/keys/microsoft.asc |
    gpg --dearmor |
    sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

AZ_REPO=$(lsb_release -cs)
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" |
    sudo tee /etc/apt/sources.list.d/azure-cli.list

apt-get update

apt-get install azure-cli=2.37.0-1~bionic
```

Rồi copy lên storage account (nhớ chuẩn bị storage account trước):

```sh
#Provide the subscription Id where snapshot is created
subscriptionId="YOUR SUBSCRPTION ID"

#Provide the name of your resource group where snapshot is created
resourceGroupName="YOUR RG NAME"

#Provide the snapshot name 
snapshotName="YOUR EXPECT SNAPSHOT NAME"

#Provide Shared Access Signature (SAS) expiry duration in seconds e.g. 3600.
#Know more about SAS here: https://docs.microsoft.com/en-us/azure/storage/storage-dotnet-shared-access-signature-part-1
sasExpiryDuration=3600

#Provide storage account name where you want to copy the snapshot. 
storageAccountName="YOUR STORAGE ACCOUNT"

#Name of the storage container where the downloaded snapshot will be stored
storageContainerName="YOUR CONTAINER INSIDE STORAGE ACCOUNT"

#Provide the key of the storage account where you want to copy snapshot. 
storageAccountKey="STORAGE ACCOUNT KEY"

#Provide the name of the VHD file to which snapshot will be copied.
destinationVHDFileName="YOUR EXPECTED DESTINATION FILE NAME".vhd

az account set --subscription $subscriptionId

sas=$(az snapshot grant-access --resource-group $resourceGroupName --name $snapshotName --duration-in-seconds $sasExpiryDuration --query [accessSas] -o tsv)

az storage blob copy start --destination-blob $destinationVHDFileName --destination-container $storageContainerName --account-name $storageAccountName --account-key $storageAccountKey --source-uri $sas
```

Sau khi có file VHD rồi, 1 lúc nào đó bạn muốn tạo ra VM từ file đó thì có thể tham khảo file ARM template sau:
```json
-SẼ ADD SAU-
```


# CREDIT

https://docs.microsoft.com/en-us/azure/virtual-machines/scripts/copy-snapshot-to-storage-account  

https://stackoverflow.com/questions/63340139/why-does-capturing-an-image-of-a-vm-in-azure-prevent-the-vm-from-being-used  