---
title: "Azure Logic Apps and Log Analytics"
date: 2025-01-20T12:52:01+07:00
draft: false
authors: ["hoangmnsd"]
categories: [Tech-Tutorials]
tags: [Azure,Serverless,LogicApps,LogAnalytics]
comments: true
toc: true
# below props are for the404blog theme
authorImg: "https://raw.githubusercontent.com/hoangmnsd/images-bucket/master/static/images/hoangmsnd-avatar001.jpg"
description: "Run Azure Logic Apps"
---

# Story

Bài Toán sẽ là mình cần làm 1 LogicApp thực hiện tác vụ DataMapping

khi gửi request đến LogicApp với json body là:
```json
{
    "orderId": "ORD1234",
    "orderDate": "2025-01-01: 12:12:12",
    "customerId": "CUST1234",
    "paymentMethod": "Credit Card"
}
```

LogicApp sẽ phải return 1 json được convert thành:
```json
{
    "orderNumber": "ORD1234",
    "orderDate": "2025-01-01: 12:12:12",
    "customerNumber": "CUST1234",
    "payment": {
      "paymentMethodCode": "1"
    }
}
```

# Create 1 Logic App service

Vào Logic app designer để kéo thả flow:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-datamap-designer.jpg)

Phần quan trọng nhất trong workflow này là:

Setting của action "Initialize variables" để define Data Map

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-datamap-designer-init-var-settings.jpg)

Setting của Compose action, để define việc refer đến các variables

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-datamap-designer-compose-settings.jpg)

Kết quả khi trigger LogicApp workflow từ Postman:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-datamap-designer-postman.jpg)

Phần Run history có thể xem log của các từng action, steps

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-datamap-designer-run-history.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-datamap-designer-run-history-2.jpg)

# Deploy from Bicep template code 

Deploy bicep file để automate

Export template từ đây, sửa đi cho đẹp là OK:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-export-template.jpg)

File `dataMap.json` có thể đc load và sử dụng trong bicep code

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-export-template-bicep.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-export-template-bicep-2.jpg)

Deploy bằng command:

```sh
az deployment group create --resource-group "RG-az-logic-apps" --template-file "./logicapp.bicep"
```

Code file `logicapp.bicep`:
```sh
param logic_app_name string = 'logicapp-dev-0x02'
param location string = resourceGroup().location

var dataMap = loadJsonContent('datamap.json')

resource workflows_logicapp_dev_0x01_name_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  name: logic_app_name
  location: location
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        When_a_HTTP_request_is_received: {
          correlation: {
            clientTrackingId: '@triggerBody()?[\'customerId\']'
          }
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              type: 'object'
              properties: {
                orderId: {
                  type: 'string'
                }
                orderDate: {
                  type: 'string'
                }
                customerId: {
                  type: 'string'
                }
                paymentMethod: {
                  type: 'string'
                }
              }
              required: [
                'orderId'
                'orderDate'
                'customerId'
                'paymentMethod'
              ]
            }
          }
          operationOptions: 'EnableSchemaValidation'
        }
      }
      actions: {
        'Compose_(OutputOrder)': {
          runAfter: {
            'Initialize_variables_(DataMap)': [
              'Succeeded'
            ]
          }
          trackedProperties: {
            ComposeResponse: '@actionOutputs(\'Compose_(OutputOrder)\')'
          }
          type: 'Compose'
          inputs: {
            orderNumber: '@{triggerBody()?[\'orderId\']}'
            orderDate: '@triggerBody()?[\'orderDate\']'
            customerNumber: '@triggerBody()?[\'customerId\']'
            payment: {
              paymentMethodCode: '@variables(\'dataMap\')[\'paymentMethod\'][triggerBody()?[\'paymentMethod\']]'
            }
          }
        }
        'Initialize_variables_(DataMap)': {
          runAfter: {}
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'dataMap'
                type: 'object'
                value: dataMap
              }
            ]
          }
        }
        Response_200: {
          runAfter: {
            'Compose_(OutputOrder)': [
              'Succeeded'
            ]
          }
          type: 'Response'
          kind: 'Http'
          inputs: {
            statusCode: 200
            body: '@outputs(\'Compose_(OutputOrder)\')'
          }
        }
        Response_400: {
          runAfter: {
            'Compose_(OutputOrder)': [
              'Failed'
            ]
          }
          type: 'Response'
          kind: 'Http'
          inputs: {
            statusCode: 400
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {}
      }
    }
  }
}
```

# Monitoring with Log Analytics

Đây là architect chung:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-monitoring-architect.jpg)

Vào Dashboard Hub tạo Private Dashboard:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-monitoring-architect-private-dashboard.jpg)

Log Analitics Workspace:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-monitoring-log-analytics-ws.jpg)

Tạo 1 LogcApp Management Solution, trỏ đến Log Analytics Wspace đã exist:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-monitoring-log-analytics-management-solution.jpg)

Sẽ thấy có Log Analytics WS và Solution đc tạo ra:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-monitoring-log-analytics-management-solution-2.jpg)

Vào cái LogicAppManagement Solution sẽ thấy nó đang connect đến Log Analytics WS

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-monitoring-log-analytics-management-solution-3.jpg)

Vào LogicApp để connect nó với Log Analytics WS

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-monitoring-log-analytics-connect.jpg)

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-monitoring-log-analytics-connect-2.jpg)

Giờ quay lại LogicAppsManagement Solution:

xem trong View Summary button

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-monitoring-log-analytics-management-solution-view-sum.jpg)

Sẽ thấy có dashboard có thông tin, ta sẽ pin nó vào Dashboard hub:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-monitoring-log-analytics-management-solution-view-sum-2.jpg)

Khi truy cập Dashboard Hub, xem cái Dashboard chúng ta mới tạo, sẽ thấy đã pin:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-monitoring-log-analytics-private-dashboard-pinned.jpg)

Có thể ấn vào Dashboard để xem chi tiết:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-monitoring-log-analytics-private-dashboard-pinned-detailed.jpg)

Ấn vào từng LogicApp để xem Run history 

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-monitoring-log-analytics-private-dashboard-pinned-run-history.jpg)

Chú ý cột Tracking ID như này là do mình setting ở LogicApp designer

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-monitoring-log-analytics-logicapp-settings.jpg)

Trong Code bicep thì nó ở đây:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-monitoring-log-analytics-logicapp-settings-in-code.jpg)

Chú ý cái Tracking Properties ở đây:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-monitoring-log-analytics-view-tracking-properties.jpg)

Ấn vào View sẽ thấy 1 cái dialog nhỏ:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-monitoring-log-analytics-view-tracking-properties-detailed.jpg)

Đây là do settings trong LogicApp designer:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-monitoring-log-analytics-logicapp-designer-setting-tracking-properties.jpg)

Trong code Bicep nó là đoạn này:

![](https://d32yh8fbac5ivo.cloudfront.net/static/images/azure-logicapp-monitoring-log-analytics-logicapp-bicep-code-setting-tracking-properties.jpg)


# REFERENCES

Clip 1 về logic app demo flow data mapping: 
https://www.youtube.com/watch?v=OYINqLo48aI


Rồi clip thứ 2 nói về dùng az log analytics: 
https://www.youtube.com/watch?v=Jxl8TZGszEc