---
title: "Azure ACI notes"
date: 2022-04-29T00:07:17+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Notes]
tags: [ACI,Azure]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "My Notes about Azure ACI"
---

# 1. Gán Role cho Identity = ARM

Bạn có 1 ACI container, đã enable System assigned identity  
Bạn muốn gán Role READER cho identity trên bằng ARM    
Quan trọng là bạn phải biết cách lấy dc `principalId` của cái System assigned identity.  
Ví dụ sau:  

```json
// add Role to SystemAssigned identity of ACI
    {
      "type": "Microsoft.Authorization/roleAssignments",
      "apiVersion": "2018-09-01-preview",
      "name": "[variables('aciRoleDefinitionName')]",
      "dependsOn": [
        "[variables('aciContainerGroupName')]"
      ],
      "properties": {
        "roleDefinitionId": "[variables('aciRoleDefinitionId')]",
        "principalId": "[reference(resourceId('Microsoft.ContainerInstance/containerGroups', variables('aciContainerGroupName')), '2021-09-01', 'Full').Identity.principalId]",
        "scope": "[resourceGroup().id]",
        "principalType": "ServicePrincipal"
      }
    }
```

# 2. ACI bị terminated ngay sau khi start (ko có log lỗi)

ACI bị terminated ngay từ đầu, ko có log lỗi, cứ start lại container ACI lại bị terminated ngay  

-> Solution:  
xóa toàn bộ untagged images trên ACR, dùng Notepad++ format file Dockerfile và entry.sh thành UNIX file. (Notepad++ -> Edit -> EOL Conversion -> Unix LF -> save)
Build lại Docker image, push lên ACR.  

# 3. Khác nhau về limitation giữa các region

Chú ý về ACI in VNET trong `francecentral`. ACI in VNET tạo từ ARM bị lỗi:  
```
message:"The requested resource is not available in the location 'francecentral' at this moment. Please retry with a different resource request or in another location. Resource requested: '1' CPU '4' GB memory 'Linux' OS virtual network"}
```
mặc dù Documents ghi rõ có support 4CPU-16GB trên `francencentral`:  
https://docs.microsoft.com/en-us/azure/container-instances/container-instances-region-availability  
Nhưng bạn vẫn sẽ gặp lỗi trên khi deploy từ ARM.  

Lý do bên MS đưa ra là Do limitation: Ko thể sử dụng managed-identity trong 1 ACI deploy trong VNET:   
https://docs.microsoft.com/en-us/azure/container-instances/container-instances-managed-identity#limitations  

Mặc dù documents ghi là limit như vậy, nhưng bạn vẫn có thể tạo được ở region `westeurope`. Nhưng sẽ lỗi ở `francecentral` 🤣  

Trường hợp này có vài cách:  
- sửa lại thành public ACI (ko đặt trong VNET nữa). Mặc dù điều này có thể khiến bạn cần thay đồi architect, AKS phải đưa ra public theo (ko secure)   
- ko cho user deploy trên francecentral  
- ticket cho MS Support (ko nhiều hy vọng)  
