---
title: "Azure Synapse ARM Template Output properties"
date: 2022-04-23T20:59:05+07:00
draft: false
authors: ["hoangmnsd"]
#categories: [Tech-Notes]
#tags: [Azure,Synapse]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Khi các bạn tạo Azure Synapse bằng ARM template. Bạn muốn output ra Workspace name, SQL endpoint, Synapse Studio URL,... nhưng ko biết làm sao?"
---

### Vấn đề
Khi các bạn tạo Azure Synapse bằng ARM template. Bạn muốn output ra Workspace name, SQL endpoint, Synapse Studio URL,... nhưng ko biết làm sao?  

### Hiện tượng
Có thể bạn sẽ gặp lỗi này:  

```
{"status":"Failed","error":{"code":"DeploymentOutputEvaluationFailed","message":"Unable to evaluate template outputs: 'synapseWorkspaceName'. Please see error details and deployment operations. Please see https://aka.ms/arm-debug for usage details.","details":[{"code":"DeploymentOutputEvaluationFailed","target":"synapseWorkspaceName","message":"The template output 'synapseWorkspaceName' is not valid: The language expression property 'name' doesn't exist, available properties are 'apiVersion, location, tags, identity, properties, condition, existing, isConditionTrue, subscriptionId, resourceGroupName, scope, resourceId, referenceApiVersion, isTemplateResource, isAction, provisioningOperation'.."}]}}
```

### Lý do  
Lỗi này xảy ra khi bạn đã tạo ra Synapse Workspace rồi, nhưng phần output thì bạn đang code là:
```json
outputs: {
synapseWorkspaceName: {
      "type": "string",
      "value": "[reference(resourceId('Microsoft.Synapse/workspaces', variables('synapseWorkspaceName')), '2021-06-01', 'Full').name]"
    }
}
```

Nhưng bạn ko biết làm sao để thấy dc các **available properties**?
Có thể bạn sẽ nghĩ đến chuyện dùng https://resources.azure.com/ để tìm available properties, nhưng chắc chắn sẽ ko tìm thấy với trường hợp Azure Synapse. (Đơn giản vì nó ko cung cấp)

### Giải pháp
Hãy sửa code thành:
```json
outputs: {
    "synapseWorkspaceName": {
      "type": "object",
      "value": "[reference(resourceId('Microsoft.Synapse/workspaces', variables('synapseWorkspaceName')), '2021-06-01', 'Full')]"
    }
}
```
Vậy là bạn sẽ in ra được 1 object chứa toàn **available properties** chỉ việc tìm cái nào là `connectivityEndpoints`, rồi sửa code lại để output nó ra thôi:
```json
outputs: {
    "synapseWorkspaceName": {
      "type": "string",
      "value": "[reference(resourceId('Microsoft.Synapse/workspaces', variables('synapseWorkspaceName')), '2021-06-01', 'Full').properties.connectivityEndpoints.sqlOnDemand]"
    }
}
```
🤡